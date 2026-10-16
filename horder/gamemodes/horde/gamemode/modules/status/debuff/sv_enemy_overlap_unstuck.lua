if CLIENT then return end

HORDE = HORDE or {}

local cv_enable  = CreateConVar("horde_unstuck_enable", "1", { FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE },
    "NPC stuck inside each other: separate them smoothly, teleport to an enemy spawn after the timeout.")
local cv_timeout = CreateConVar("horde_unstuck_timeout", "10", { FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE },
    "Seconds to free an overlapped NPC before it is teleported to info_horde_enemy_spawn.")
local cv_debug   = CreateConVar("horde_unstuck_debug", "0", { FCVAR_SERVER_CAN_EXECUTE },
    "Print unstuck events to the server console.")

local abs, min, max, floor, sqrt = math.abs, math.min, math.max, math.floor, math.sqrt
local cos, sin, atan2, pi = math.cos, math.sin, math.atan2, math.pi

local TICK            = 0.1
local IDLE_DIV        = 2
local DETECT_TIME     = 1.0
local ENTER_DEPTH     = 0.50
local RELEASE_DEPTH   = 0.15
local TELEPORT_DEPTH  = 0.30
local CLEAR_MARGIN    = 3
local CLEAR_HOLD      = 0.4
local SEARCH_PAD      = 20
local MAX_SESSIONS    = 24
local MAX_PARTNERS    = 8

local SPEED_MIN       = 45
local SPEED_MAX       = 120
local RAMP_TIME       = 1.5
local HELPER_SPEED    = 60
local RELAX           = 0.6
local MIN_IMPROVE     = 0.5

local ESCALATE_BLOCKED = 4
local ESCALATE_AFTER   = 3.0
local MAX_NUDGES       = 4
local NUDGE_SCALE      = 0.5
local BLOCK_BACKOFF    = 0.2

local HULL_LIFT        = 4
local STEP_DOWN        = 40
local MIN_GROUND_NZ    = 0.7
local Z_OVERLAP_FRAC   = 0.5

local CELL, CELL_KEY   = 160, 100003
local HALF_MIN, HALF_MAX = 8, 64
local BOUNDS_TTL       = 2.0

local TP_RETRY         = 2.0
local TP_ATTACK_WAIT   = 3.0
local TP_RESERVE_TIME  = 4.0
local TP_RESERVE_RADIUS= 90
local MAX_SPAWN_TRACES = 16

local tracked   = {}
local nodes     = {}
local pending   = {}
local sessions  = {}
local session_count = 0
local recent_tp = {}
local dirty     = {}
local queue, queue_n = {}, 0
local tick_id, suspended_until, err_count = 0, 0, 0
local was_enabled = true

local list, list_n = {}, 0
local cells = {}

local function Dbg(fmt, ...)
    if cv_debug:GetBool() then
        MsgC(Color(255, 200, 80), "[Horde Unstuck] ", string.format(fmt, ...), "\n")
    end
end

local function IsBoss(ent)
    if ent.GetVar and ent:GetVar("is_boss") == true then return true end
    local props = ent.Horde_GetBossProperties and ent:Horde_GetBossProperties()
    return props ~= nil and props ~= false and props.is_boss == true
end

local function IsMovableGround(ent)
    if ent:IsNextBot() then return true end
    if VJ_MOVETYPE_GROUND ~= nil and ent.MovementType ~= nil then
        return ent.MovementType == VJ_MOVETYPE_GROUND
    end
    local mt = ent:GetMoveType()
    return mt == MOVETYPE_STEP or mt == MOVETYPE_WALK
end

local function IsCandidate(ent)
    if not IsValid(ent) then return false end
    if ent:Health() <= 0 or ent.Dead then return false end
    if IsValid(ent:GetParent()) then return false end
    if HORDE.IsEnemy then return HORDE:IsEnemy(ent) end
    return (ent:IsNPC() or ent:IsNextBot()) and true or false
end

hook.Add("Horde_ShouldCollide", "Horde_Unstuck_PairGhost", function(a, b)
    local g = a.Horde_UG
    if g and g[b] then return false end
    g = b.Horde_UG
    if g and g[a] then return false end
end)

local function MarkDirty(e) dirty[e] = true end

local function FlushDirty()
    for e in pairs(dirty) do
        dirty[e] = nil
        if IsValid(e) then e:CollisionRulesChanged() end
    end
end

local function Ghost(a, b)
    local ga = a.Horde_UG
    if ga and ga[b] then return end
    if (a.Horde_UGN or 0) >= MAX_PARTNERS or (b.Horde_UGN or 0) >= MAX_PARTNERS then return end
    if not ga then ga = {}; a.Horde_UG = ga end
    local gb = b.Horde_UG
    if not gb then gb = {}; b.Horde_UG = gb end
    ga[b] = 0; gb[a] = 0
    a.Horde_UGN = (a.Horde_UGN or 0) + 1
    b.Horde_UGN = (b.Horde_UGN or 0) + 1
    a:SetCustomCollisionCheck(true)
    b:SetCustomCollisionCheck(true)
    MarkDirty(a); MarkDirty(b)
end

local function Unghost(a, b)
    local ga, gb = a.Horde_UG, b.Horde_UG
    if ga and ga[b] then
        ga[b] = nil
        a.Horde_UGN = (a.Horde_UGN or 1) - 1
        if a.Horde_UGN <= 0 then a.Horde_UG = nil; a.Horde_UGN = nil end
    end
    if gb and gb[a] then
        gb[a] = nil
        b.Horde_UGN = (b.Horde_UGN or 1) - 1
        if b.Horde_UGN <= 0 then b.Horde_UG = nil; b.Horde_UGN = nil end
    end
    MarkDirty(a); MarkDirty(b)
end

local scratch_keys = {}
local function UnghostAll(ent)
    local g = ent.Horde_UG
    if not g then return end
    local n = 0
    for other in pairs(g) do n = n + 1; scratch_keys[n] = other end
    for i = 1, n do
        Unghost(ent, scratch_keys[i])
        scratch_keys[i] = nil
    end
    ent.Horde_UG = nil; ent.Horde_UGN = nil
end

local function StartSession(ent, helper)
    if sessions[ent] or session_count >= MAX_SESSIONS then return nil end
    local now = CurTime()
    local s = {
        ent = ent, idx = ent:EntIndex(), t0 = now, last_t = now - TICK,
        clear_since = nil, blocked = 0, retry_at = 0, tp_retry_at = 0,
        helper = helper or false, escalated = false, deepest = 0,
    }
    sessions[ent] = s
    session_count = session_count + 1
    pending[ent] = nil
    Dbg("session start #%d (%s)%s", s.idx, tostring(ent:GetClass()), helper and " [helper]" or "")
    return s
end

local function EndSession(ent, why)
    local s = sessions[ent]
    if s then
        sessions[ent] = nil
        session_count = session_count - 1
        Dbg("session end #%d: %s (%.1fs)", s.idx, why, CurTime() - s.t0)
    end
    pending[ent] = nil
    if IsValid(ent) then UnghostAll(ent) end
end

local function Forget(ent)
    tracked[ent] = nil
    nodes[ent] = nil
    pending[ent] = nil
    if sessions[ent] then sessions[ent] = nil; session_count = session_count - 1 end
    local g = ent.Horde_UG
    if g then
        for other in pairs(g) do
            local og = other.Horde_UG
            if og then
                og[ent] = nil
                other.Horde_UGN = (other.Horde_UGN or 1) - 1
                if other.Horde_UGN <= 0 then other.Horde_UG = nil; other.Horde_UGN = nil end
            end
        end
        ent.Horde_UG = nil; ent.Horde_UGN = nil
    end
end

local function ResetAll()
    for ent in pairs(sessions) do EndSession(ent, "reset") end
    for ent in pairs(tracked) do
        if IsValid(ent) and ent.Horde_UG then UnghostAll(ent) end
    end
    FlushDirty()
end

local function RefreshBounds(n, ent, now)
    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
    local hx = math.Clamp((maxs.x - mins.x) * 0.5, HALF_MIN, HALF_MAX)
    local hy = math.Clamp((maxs.y - mins.y) * 0.5, HALF_MIN, HALF_MAX)
    n.hx, n.hy = hx, hy
    n.ox, n.oy = (maxs.x + mins.x) * 0.5, (maxs.y + mins.y) * 0.5
    n.zmin, n.zmax = mins.z, maxs.z
    n.h = max(1, maxs.z - mins.z)
    n.w = max(1, min(hx, hy) * 2)
    n.mass = hx * hy
    n.mins, n.maxs = mins, maxs
    n.boss = IsBoss(ent)
    n.eligible = (not n.boss) and IsMovableGround(ent)
    n.bounds_t = now + BOUNDS_TTL
end

local function BuildSnapshot(now)
    cells = {}
    list_n = 0
    for ent in pairs(tracked) do
        if not IsValid(ent) then
            Forget(ent)
        elseif IsCandidate(ent) then
            local n = nodes[ent]
            if not n then n = { ent = ent, idx = ent:EntIndex() }; nodes[ent] = n end
            if (n.bounds_t or 0) <= now then RefreshBounds(n, ent, now) end
            local pos = ent:GetPos()
            n.px, n.py, n.pz = pos.x, pos.y, pos.z
            n.x, n.y = pos.x + n.ox, pos.y + n.oy
            n.z0, n.z1 = pos.z + n.zmin, pos.z + n.zmax
            n.stamp = tick_id
            local cx, cy = floor(n.x / CELL), floor(n.y / CELL)
            n.cx, n.cy = cx, cy
            local key = cx * CELL_KEY + cy
            local c = cells[key]
            if c then c[#c + 1] = n else cells[key] = { n } end
            list_n = list_n + 1
            list[list_n] = n
        else
            nodes[ent] = nil
        end
    end
end

local nbN, nbD, nbT = {}, {}, {}
local function Neighbors(a, search_pad, margin)
    local n = 0
    for ix = a.cx - 1, a.cx + 1 do
        for iy = a.cy - 1, a.cy + 1 do
            local c = cells[ix * CELL_KEY + iy]
            if c then
                for i = 1, #c do
                    local b = c[i]
                    if b ~= a then
                        local adx, ady = abs(a.x - b.x), abs(a.y - b.y)
                        local Hx, Hy = a.hx + b.hx, a.hy + b.hy
                        if Hx + search_pad - adx > 0 and Hy + search_pad - ady > 0
                            and min(a.z1, b.z1) - max(a.z0, b.z0) >= Z_OVERLAP_FRAC * min(a.h, b.h) then
                            n = n + 1
                            nbN[n] = b
                            local ox, oy = Hx - adx, Hy - ady
                            nbD[n] = (ox > 0 and oy > 0) and (min(ox, oy) / min(a.w, b.w)) or 0
                            nbT[n] = (Hx + margin - adx > 0) and (Hy + margin - ady > 0)
                        end
                    end
                end
            end
        end
    end
    return n
end

local function AwayDir(a, b, dx, dy)
    local len = sqrt(dx * dx + dy * dy)
    if len > 0.5 then return dx / len, dy / len end
    local lo, hi, sign = a.idx, b.idx, 1
    if lo > hi then lo, hi, sign = hi, lo, -1 end
    local ang = ((lo * 53 + hi * 97) % 360) * (pi / 180)
    return cos(ang) * sign, sin(ang) * sign
end

local function SepDistance(a, b, ux, uy, dx, dy, pad)
    local Hx, Hy = a.hx + b.hx + pad, a.hy + b.hy + pad
    local t = 1e9
    local ax, ay = abs(ux), abs(uy)
    if ax > 1e-4 then t = min(t, (Hx - abs(dx)) / ax) end
    if ay > 1e-4 then t = min(t, (Hy - abs(dy)) / ay) end
    return t
end

local function OverlapArea(ax, ay, a, b, pad)
    local ox = a.hx + b.hx + pad - abs(ax - b.x)
    if ox <= 0 then return 0 end
    local oy = a.hy + b.hy + pad - abs(ay - b.y)
    if oy <= 0 then return 0 end
    return ox * oy
end

local function Share(a, b_movable, b)
    if not b_movable then return 1 end
    return b.mass / (a.mass + b.mass)
end

local trace_self
local function IgnoreNPCs(e)
    if e == trace_self then return false end
    if e:IsNPC() or e:IsNextBot() then return false end
    return true
end
local trace_in = { mask = MASK_NPCSOLID, filter = IgnoreNPCs }

local function WorldStep(ent, n, vx, vy)
    trace_self = ent
    local s = Vector(n.px, n.py, n.pz + HULL_LIFT)
    local e = Vector(n.px + vx, n.py + vy, n.pz + HULL_LIFT)
    trace_in.start, trace_in.endpos, trace_in.mins, trace_in.maxs = s, e, n.mins, n.maxs
    local tr = util.TraceHull(trace_in)
    if tr.StartSolid or tr.Hit then return nil end

    trace_in.start = e
    trace_in.endpos = Vector(e.x, e.y, e.z - HULL_LIFT - STEP_DOWN)
    tr = util.TraceHull(trace_in)
    if tr.StartSolid or not tr.Hit then return nil end
    if tr.HitNormal.z < MIN_GROUND_NZ then return nil end
    return tr.HitPos
end

local ANG_RAD = {}
for i, deg in ipairs({ 0, 40, -40, 80, -80, 125, -125 }) do ANG_RAD[i] = deg * pi / 180 end
local cand_cx, cand_cy, cand_score, cand_done = {}, {}, {}, {}

local function TryMove(ent, n, dx, dy, cnt)
    local len = sqrt(dx * dx + dy * dy)
    if len < 0.05 then return false end

    local before = 0
    for i = 1, cnt do before = before + OverlapArea(n.x, n.y, n, nbN[i], CLEAR_MARGIN) end

    local base = atan2(dy, dx)
    local K = #ANG_RAD
    for k = 1, K do
        local a = base + ANG_RAD[k]
        local cx, cy = cos(a), sin(a)
        local after = 0
        for i = 1, cnt do
            after = after + OverlapArea(n.x + cx * len, n.y + cy * len, n, nbN[i], CLEAR_MARGIN)
        end
        cand_cx[k], cand_cy[k], cand_score[k], cand_done[k] = cx, cy, before - after, false
    end

    for _ = 1, 4 do
        local best, bs = nil, MIN_IMPROVE
        for k = 1, K do
            if (not cand_done[k]) and cand_score[k] > bs then best, bs = k, cand_score[k] end
        end
        if not best then return false end
        cand_done[best] = true
        local np = WorldStep(ent, n, cand_cx[best] * len, cand_cy[best] * len)
        if np then
            ent:SetPos(np)
            n.px, n.py, n.pz = np.x, np.y, np.z
            n.x, n.y = np.x + n.ox, np.y + n.oy
            n.z0, n.z1 = np.z + n.zmin, np.z + n.zmax
            return true
        end
    end
    return false
end

local spawn_pts = {}
local function CollectSpawnPoints()
    local n = 0
    local src = HORDE.ai_nodes
    if src then
        for i = 1, #src do
            local p = src[i] and src[i].pos
            if p and (not src[i].ent or not src[i].ent.Disabled) then n = n + 1; spawn_pts[n] = p end
        end
    end
    if n == 0 then
        for _, e in ipairs(ents.FindByClass("info_horde_enemy_spawn")) do
            if not e.Disabled then n = n + 1; spawn_pts[n] = e:GetPos() end
        end
    end
    return spawn_pts, n
end

local function IsReserved(pos, now)
    for i = #recent_tp, 1, -1 do
        local r = recent_tp[i]
        if r.t <= now then
            table.remove(recent_tp, i)
        elseif (r.pos.x - pos.x) ^ 2 + (r.pos.y - pos.y) ^ 2 < TP_RESERVE_RADIUS ^ 2 then
            return true
        end
    end
    return false
end

local function NpcNear(pos, ent)
    local r2 = (HORDE.spawn_radius or 75) ^ 2
    for i = 1, list_n do
        local o = list[i]
        if o.ent ~= ent and abs(o.pz - pos.z) < 100
            and (o.px - pos.x) ^ 2 + (o.py - pos.y) ^ 2 < r2 then
            return true
        end
    end
    return false
end

local function HullFree(pos, ent, n)
    if not util.IsInWorld(pos) then return false end
    local p = pos + Vector(0, 0, HULL_LIFT)
    local tr = util.TraceHull({
        start = p, endpos = p, mins = n.mins, maxs = n.maxs, filter = ent, mask = MASK_NPCSOLID,
    })
    return not (tr.Hit or tr.StartSolid)
end

local function PickSafeSpawn(ent, n, now)
    local pts, total = CollectSpawnPoints()
    if total == 0 then return nil end

    local plys = {}
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() then plys[#plys + 1] = p:GetPos() end
    end
    local min_d = HORDE.min_spawn_distance or 400
    local max_d = HORDE.max_spawn_distance or 2000
    local cvz = GetConVar("horde_max_spawn_z_distance")
    local max_z = cvz and cvz:GetFloat() or 512

    local function DistanceOK(pos, pass)
        if #plys == 0 then return true end
        local best_d, best_z = math.huge, 0
        for i = 1, #plys do
            local d = sqrt((plys[i].x - pos.x) ^ 2 + (plys[i].y - pos.y) ^ 2 + (plys[i].z - pos.z) ^ 2)
            if d < best_d then best_d, best_z = d, abs(plys[i].z - pos.z) end
        end
        if pass == 1 then return best_d >= min_d and best_d <= max_d and best_z <= max_z end
        if pass == 2 then return best_d >= min_d end
        return best_d >= 150
    end

    for pass = 1, 3 do
        local start, traces = math.random(total), 0
        for k = 0, total - 1 do
            local pos = pts[((start + k - 1) % total) + 1]
            if DistanceOK(pos, pass) and not IsReserved(pos, now) and not NpcNear(pos, ent) then
                traces = traces + 1
                if HullFree(pos, ent, n) then return pos end
                if traces >= MAX_SPAWN_TRACES then break end
            end
        end
    end
    return nil
end

local function IsAttacking(ent)
    local started = (VJ and VJ.ATTACK_STATE_STARTED) or 2
    if ent.AttackState and ent.AttackState >= started then return true end
    local fire = (VJ and VJ.WEP_ATTACK_STATE_FIRE) or 10
    if ent.WeaponAttackState and ent.WeaponAttackState >= fire then return true end
    local act = ent.GetActivity and ent:GetActivity()
    return act and act >= ACT_RANGE_ATTACK1 and act <= ACT_SPECIAL_ATTACK2 or false
end

local function TeleportToSafeSpawn(ent, n, now)
    local pos = PickSafeSpawn(ent, n, now)
    if not pos then return false end

    recent_tp[#recent_tp + 1] = { pos = pos, t = now + TP_RESERVE_TIME }
    ent:EmitSound("ambient/machines/teleport4.wav", 75, 100)
    ent:SetPos(pos + Vector(0, 0, HORDE.enemy_spawn_z or 0))
    ent:SetLocalVelocity(vector_origin)
    ent.Horde_Stunned = nil

    local ply, bd
    for _, p in ipairs(player.GetAll()) do
        if p:Alive() then
            local d = p:GetPos():DistToSqr(pos)
            if not bd or d < bd then ply, bd = p, d end
        end
    end
    if ply then
        if ent.SetLastPosition then ent:SetLastPosition(ply:GetPos()) end
        if ent.SetTarget then ent:SetTarget(ply) end
        if ent.SetSchedule then ent:SetSchedule(SCHED_TARGET_CHASE) end
    end
    return true
end

local tp_best
local nudge_x, nudge_y, nudge_list = {}, {}, {}

local function ReleaseClearedPairs(ent, n, now)
    local g = ent.Horde_UG
    if not g then return end
    local cnt = 0
    for other, since in pairs(g) do
        local on = nodes[other]
        local touching = false
        if on and on.stamp == tick_id then
            local adx, ady = abs(n.x - on.x), abs(n.y - on.y)
            touching = (n.hx + on.hx - adx > 0) and (n.hy + on.hy - ady > 0)
                and (min(n.z1, on.z1) - max(n.z0, on.z0) >= Z_OVERLAP_FRAC * min(n.h, on.h))
        end
        if touching then
            g[other] = 0
        elseif since == 0 then
            g[other] = now
        elseif now - since >= CLEAR_HOLD then
            cnt = cnt + 1; scratch_keys[cnt] = other
        end
    end
    for i = 1, cnt do
        Unghost(ent, scratch_keys[i])
        scratch_keys[i] = nil
    end
end

local function ProcessSession(s, now)
    local ent = s.ent
    local n = nodes[ent]
    if (not n) or n.stamp ~= tick_id or not n.eligible then EndSession(ent, "gone"); return end

    local dt = math.Clamp(now - s.last_t, 0.05, 0.3)
    s.last_t = now
    local cnt = Neighbors(n, SEARCH_PAD, CLEAR_MARGIN)

    local deepest, touching = 0, 0
    for i = 1, cnt do
        if nbT[i] then touching = touching + 1; Ghost(ent, nbN[i].ent) end
        if nbD[i] > deepest then deepest = nbD[i] end
    end
    s.deepest = deepest

    ReleaseClearedPairs(ent, n, now)

    if deepest < RELEASE_DEPTH then
        s.clear_since = s.clear_since or now
        if now - s.clear_since >= CLEAR_HOLD then EndSession(ent, "freed"); return end
    else
        s.clear_since = nil
    end

    local age = now - s.t0
    if age >= cv_timeout:GetFloat() and deepest >= TELEPORT_DEPTH and now >= s.tp_retry_at then
        if (not IsAttacking(ent)) or age >= cv_timeout:GetFloat() + TP_ATTACK_WAIT then
            if (not tp_best) or s.t0 < tp_best.t0 or (s.t0 == tp_best.t0 and s.idx < tp_best.idx) then
                tp_best = s
            end
        end
    end

    if touching == 0 or now < s.retry_at then return end

    if (not s.helper) and (not s.escalated)
        and (s.blocked >= ESCALATE_BLOCKED or (age >= ESCALATE_AFTER and deepest >= ENTER_DEPTH)) then
        s.escalated = true
        Dbg("escalate #%d (blocked=%d, age=%.1f)", s.idx, s.blocked, age)
    end

    local Dx, Dy = 0, 0
    for i = 1, cnt do
        if nbT[i] then
            local b = nbN[i]
            local dx, dy = n.x - b.x, n.y - b.y
            local ux, uy = AwayDir(n, b, dx, dy)
            local t = SepDistance(n, b, ux, uy, dx, dy, CLEAR_MARGIN)
            if t > 0 then
                local bs = sessions[b.ent]
                local b_movable = (bs ~= nil and bs.blocked == 0) or (bs == nil and s.escalated and b.eligible)
                local share = Share(n, b_movable, b)
                Dx = Dx + ux * t * share * RELAX
                Dy = Dy + uy * t * share * RELAX
                if bs == nil and s.escalated and b.eligible and share < 1 then
                    if not nudge_x[b] then nudge_x[b] = 0; nudge_y[b] = 0; nudge_list[#nudge_list + 1] = b end
                    nudge_x[b] = nudge_x[b] - ux * t * (1 - share) * RELAX * NUDGE_SCALE
                    nudge_y[b] = nudge_y[b] - uy * t * (1 - share) * RELAX * NUDGE_SCALE
                end
            end
        end
    end

    local len = sqrt(Dx * Dx + Dy * Dy)
    if len < 0.25 then
        local ang = ((s.idx * 53) % 360) * (pi / 180)
        Dx, Dy, len = cos(ang) * 2, sin(ang) * 2, 2
    end

    local cap
    if s.helper then
        cap = HELPER_SPEED * dt
    else
        local r = min(1, age / RAMP_TIME)
        cap = (SPEED_MIN + (SPEED_MAX - SPEED_MIN) * (r * r * (3 - 2 * r))) * dt
    end
    if len > cap then Dx, Dy = Dx * cap / len, Dy * cap / len end

    if TryMove(ent, n, Dx, Dy, cnt) then
        s.blocked = 0
    else
        s.blocked = s.blocked + 1
        s.retry_at = now + BLOCK_BACKOFF
    end
end

local function ApplyNudges(now)
    local m = #nudge_list
    if m == 0 then return end
    table.sort(nudge_list, function(a, b) return a.idx < b.idx end)
    local applied = 0
    for i = 1, m do
        local b = nudge_list[i]
        if applied < MAX_NUDGES and b.stamp == tick_id then
            local hs = sessions[b.ent] or StartSession(b.ent, true)
            if hs then
                local vx, vy = nudge_x[b], nudge_y[b]
                local len = sqrt(vx * vx + vy * vy)
                local cap = HELPER_SPEED * TICK
                if len > cap then vx, vy = vx * cap / len, vy * cap / len end
                local cnt = Neighbors(b, SEARCH_PAD, CLEAR_MARGIN)
                if TryMove(b.ent, b, vx, vy, cnt) then applied = applied + 1 end
            end
        end
        nudge_x[b], nudge_y[b], nudge_list[i] = nil, nil, nil
    end
end

local function Detect(now)
    for i = 1, list_n do
        local a = list[i]
        if a.eligible and not sessions[a.ent] then
            local cnt = Neighbors(a, 0, 0)
            local deep = false
            for j = 1, cnt do
                if nbD[j] >= ENTER_DEPTH then deep = true; break end
            end
            if deep then
                local t0 = pending[a.ent]
                if not t0 then
                    pending[a.ent] = now
                elseif now - t0 >= DETECT_TIME then
                    StartSession(a.ent, false)
                end
            else
                pending[a.ent] = nil
            end
        end
    end
end

local order = {}
local function BySessionIdx(a, b) return a.idx < b.idx end

local function Tick()
    local now = CurTime()
    tick_id = tick_id + 1

    if queue_n > 0 then
        for i = 1, queue_n do
            local e = queue[i]
            queue[i] = nil
            if IsValid(e) and (e:IsNPC() or e:IsNextBot()) then tracked[e] = true end
        end
        queue_n = 0
    end

    if now < suspended_until then return end

    local enabled = cv_enable:GetBool()
    if not enabled then
        if was_enabled then ResetAll(); was_enabled = false end
        return
    end
    was_enabled = true

    if session_count == 0 and (tick_id % IDLE_DIV) ~= 0 then return end

    BuildSnapshot(now)
    if list_n < 2 and session_count == 0 then return end

    Detect(now)
    if session_count == 0 then return end

    local m = 0
    for _, s in pairs(sessions) do m = m + 1; order[m] = s end
    for i = m + 1, #order do order[i] = nil end
    table.sort(order, BySessionIdx)

    tp_best = nil
    for i = 1, m do
        local s = order[i]
        if sessions[s.ent] == s then ProcessSession(s, now) end
    end
    ApplyNudges(now)

    if tp_best and sessions[tp_best.ent] == tp_best then
        local ent = tp_best.ent
        local n = nodes[ent]
        if n and TeleportToSafeSpawn(ent, n, now) then
            Dbg("TELEPORT #%d (%s) after %.1fs", tp_best.idx, tostring(ent:GetClass()), now - tp_best.t0)
            EndSession(ent, "teleported")
        else
            tp_best.tp_retry_at = now + TP_RETRY
            Dbg("teleport #%d: no safe spawn point, retry in %.0fs", tp_best.idx, TP_RETRY)
        end
    end

    FlushDirty()
end

local function SafeTick()
    local ok, err = pcall(Tick)
    if ok then err_count = 0; return end
    err_count = err_count + 1
    ErrorNoHalt("[Horde Unstuck] " .. tostring(err) .. "\n")
    pcall(ResetAll)
    if err_count >= 5 then
        suspended_until = CurTime() + 30
        err_count = 0
    end
end

hook.Add("OnEntityCreated", "Horde_Unstuck_Track", function(ent)
    queue_n = queue_n + 1
    queue[queue_n] = ent
end)

hook.Add("EntityRemoved", "Horde_Unstuck_Cleanup", function(ent)
    Forget(ent)
end)

hook.Add("PostCleanupMap", "Horde_Unstuck_Reset", function()
    ResetAll()
    tracked, nodes, pending, sessions, session_count, recent_tp = {}, {}, {}, {}, 0, {}
end)

timer.Create("Horde_EnemyOverlapUnstuck", TICK, 0, SafeTick)

if ents and ents.GetAll then
    for _, e in ipairs(ents.GetAll()) do
        queue_n = queue_n + 1
        queue[queue_n] = e
    end
end

concommand.Add("horde_unstuck_status", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local out = string.format("[Horde Unstuck] enabled=%s sessions=%d tracked=%d suspended=%s",
        tostring(cv_enable:GetBool()), session_count, table.Count(tracked), tostring(CurTime() < suspended_until))
    print(out)
    for ent, s in pairs(sessions) do
        print(string.format("  #%d %s age=%.1fs depth=%.2f blocked=%d%s%s partners=%d",
            s.idx, tostring(ent:GetClass()), CurTime() - s.t0, s.deepest, s.blocked,
            s.helper and " helper" or "", s.escalated and " escalated" or "", ent.Horde_UGN or 0))
    end
end)
