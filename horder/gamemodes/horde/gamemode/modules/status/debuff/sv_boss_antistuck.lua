if CLIENT then return end

local CHECK_INTERVAL   = 1.0
local STUCK_TIME       = 3.0
local STUCK_DIST_SQR   = 40 * 40
local CROWD_RADIUS     = 120
local CROWD_MIN        = 3
local KNOCK_RADIUS     = 300
local KNOCK_NORMAL     = 1500
local KNOCK_ELITE      = 500
local KNOCK_UP         = 200
local KNOCK_COOLDOWN   = 4.0
local TELEPORT_AFTER   = 20.0
local TELEPORT_COOLDOWN = 10.0

local last_pos = {}
local stuck_since = {}
local last_knock = {}
local last_teleport = {}

local function IsBoss(ent)
    return IsValid(ent) and ent:GetVar("is_boss") == true
end

local function IsAttacking(ent)
    if not IsValid(ent) then return false end

    local started = (VJ and VJ.ATTACK_STATE_STARTED) or 2
    if ent.AttackState and ent.AttackState >= started then return true end
    local fire = (VJ and VJ.WEP_ATTACK_STATE_FIRE) or 10
    if ent.WeaponAttackState and ent.WeaponAttackState >= fire then return true end

    local act = ent.GetActivity and ent:GetActivity()
    if act and act >= ACT_RANGE_ATTACK1 and act <= ACT_SPECIAL_ATTACK2 then return true end

    return false
end

local function BossKnockback(boss)
    if not IsValid(boss) then return end
    local now = CurTime()
    if last_knock[boss] and (now - last_knock[boss]) < KNOCK_COOLDOWN then return end
    last_knock[boss] = now

    local origin = boss:GetPos()
    boss:EmitSound("physics/flesh/flesh_strider_impact_bullet1.wav", 70, 100, 0.8)

    if effects and effects.BeamRingPoint then
        local effect_origin = origin + Vector(0, 0, 16)
        effects.BeamRingPoint(effect_origin, 0.3, 2, KNOCK_RADIUS * 1.3, 16, 0, Color(188, 220, 255), { material = "sprites/vj_bms_shockwave", framerate = 20 })
        effects.BeamRingPoint(effect_origin, 0.3, 2, KNOCK_RADIUS * 0.7, 16, 0, Color(188, 220, 255), { material = "sprites/vj_bms_shockwave", framerate = 20 })
    end

    for _, ent in ipairs(ents.FindInSphere(origin, KNOCK_RADIUS)) do
        if not IsValid(ent) or ent == boss then continue end

        if HORDE:IsPlayerBuildable(ent) then continue end

        local is_ply = ent:IsPlayer() and ent:Alive()
        local is_npc = ent:IsNPC() and ent:Health() > 0
        if not is_ply and not is_npc then continue end

        if is_npc then
            if ent:GetVar("is_boss") then continue end
            local owner = ent:GetNWEntity("HordeOwner")
            if not IsValid(owner) and not (ent.Horde_IsPlayerMinion or HORDE:IsPlayerMinion(ent)) then
                continue
            end
        end

        local direction = (ent:GetPos() - origin):GetNormalized()
        local force = KNOCK_NORMAL
        if is_npc and ent.Horde_IsElite then
            force = KNOCK_ELITE
        end
        ent:SetVelocity(direction * force + Vector(0, 0, KNOCK_UP))
    end

    local ang = math.rad(math.random(0, 359))
    local jump_dir = Vector(math.cos(ang), math.sin(ang), 0)
    local boss_force = 600
    if boss:IsOnGround() then
        boss:SetVelocity(jump_dir * boss_force + Vector(0, 0, 350))
    else
        boss:SetVelocity(jump_dir * boss_force + Vector(0, 0, 150))
    end
    local try_pos = origin + jump_dir * 80 + Vector(0, 0, 8)
    local tr = util.TraceHull({
        start = origin + Vector(0, 0, 16),
        endpos = try_pos,
        mins = Vector(-16, -16, 0),
        maxs = Vector(16, 16, 32),
        filter = boss,
        mask = MASK_NPCSOLID,
    })
    if not tr.Hit then
        boss:SetPos(try_pos)
    elseif tr.Fraction > 0.3 then
        boss:SetPos(tr.HitPos + Vector(0, 0, 4))
    end

    if boss.SetSchedule then
        boss:SetSchedule(SCHED_IDLE_WANDER)
    end
    if boss.SetCondition then
        boss:SetCondition(68)
    end
    boss.Horde_Stunned = nil
end

local function CountBlockingCrowd(boss)
    local origin = boss:GetPos()
    local n = 0
    for _, ent in ipairs(ents.FindInSphere(origin, CROWD_RADIUS)) do
        if not IsValid(ent) or ent == boss then continue end
        if HORDE:IsPlayerBuildable(ent) then continue end
        if ent:IsPlayer() and ent:Alive() then
            n = n + 1
        elseif ent:IsNPC() and ent:Health() > 0 then
            local owner = ent:GetNWEntity("HordeOwner")
            if IsValid(owner) or (HORDE and HORDE.IsPlayerMinion and HORDE:IsPlayerMinion(ent)) then
                n = n + 1
            end
        end
    end
    return n
end

timer.Create("Horde_BossAntiStuck", CHECK_INTERVAL, 0, function()
    for _, ent in ipairs(ents.GetAll()) do
        if not IsBoss(ent) then continue end
        if ent:Health() <= 0 then continue end

        local pos = ent:GetPos()
        local prev = last_pos[ent]
        last_pos[ent] = pos

        local crowded = CountBlockingCrowd(ent) >= CROWD_MIN

        local moved = true
        if prev then
            moved = prev:DistToSqr(pos) > STUCK_DIST_SQR
        end

        if not moved then
            stuck_since[ent] = stuck_since[ent] or CurTime()
        else
            stuck_since[ent] = nil
        end

        local stuck_for = stuck_since[ent] and (CurTime() - stuck_since[ent]) or 0

        if not IsAttacking(ent) then
            if stuck_for >= TELEPORT_AFTER then
                local can_teleport = HORDE.RepositionBoss
                    and ((not last_teleport[ent]) or (CurTime() - last_teleport[ent]) >= TELEPORT_COOLDOWN)
                if can_teleport and HORDE:RepositionBoss() then
                    last_teleport[ent] = CurTime()
                    print("[HORDE] Boss is stuck. Teleporting to a free node...")
                    stuck_since[ent] = nil
                else
                    BossKnockback(ent)
                end
            elseif crowded or stuck_for >= STUCK_TIME then
                BossKnockback(ent)
            end
        end
    end
end)

hook.Add("EntityRemoved", "Horde_BossAntiStuckCleanup", function(ent)
    last_pos[ent] = nil
    stuck_since[ent] = nil
    last_knock[ent] = nil
    last_teleport[ent] = nil
end)
