MUTATION.PrintName   = "Voidwalker"
MUTATION.Description = "Teleports to the nearest player periodically.\nUnstable form: loses HP over time until it perishes."
MUTATION.Wave        = 6

MUTATION.Hooks = {}

local TP_INTERVAL_MIN   = 15
local TP_INTERVAL_MAX   = 30
local TP_NODE_DIST_MIN  = 100
local TP_NODE_DIST_MAX  = 600
local TP_NODE_TRIES     = 12
local TP_FALLBACK_TRIES = 8
local TP_FALLBACK_MIN   = 100
local TP_FALLBACK_MAX   = 250
local DECAY_INTERVAL    = 5
local DECAY_AMOUNT      = 5
local DECAY_KILL_THRESH = 5

local NODE_DIST_MIN_SQ = TP_NODE_DIST_MIN * TP_NODE_DIST_MIN
local NODE_DIST_MAX_SQ = TP_NODE_DIST_MAX * TP_NODE_DIST_MAX

local function CreatePurpleSmoke(pos)
    local smoke = ents.Create("env_smoketrail")
    if not IsValid(smoke) then return end

    smoke:SetPos(pos)
    smoke:SetKeyValue("startsize",   "40")
    smoke:SetKeyValue("endsize",     "10")
    smoke:SetKeyValue("spawnradius", "10")
    smoke:SetKeyValue("minspeed",    "10")
    smoke:SetKeyValue("maxspeed",    "20")
    smoke:SetKeyValue("startcolor",  "150 0 255")
    smoke:SetKeyValue("endcolor",    "100 0 200")
    smoke:SetKeyValue("opacity",     "0.8")
    smoke:SetKeyValue("spawnrate",   "20")
    smoke:SetKeyValue("lifetime",    "1.5")
    smoke:Spawn()
    smoke:Activate()

    smoke:Fire("TurnOn",  "", 0)
    smoke:Fire("TurnOff", "", 2)
    smoke:Fire("Kill",    "", 3)
end

local function IsNodePassable(ent, targetPlayer, pos)
    local mins = ent:OBBMins()
    local maxs = ent:OBBMaxs()

    local trHull = util.TraceHull({
        start  = pos + Vector(0, 0, 5),
        endpos = pos,
        mins   = mins,
        maxs   = maxs,
        filter = { ent, targetPlayer },
        mask   = MASK_NPCSOLID,
    })
    if trHull.Hit then return false end

    local trFloor = util.TraceLine({
        start  = pos,
        endpos = pos - Vector(0, 0, 72),
        mask   = MASK_NPCSOLID,
    })
    return trFloor.Hit
end

local function FindPosByNodes(ent, targetPlayer)
    local nodes = HORDE and HORDE.ai_nodes
    if not nodes or #nodes == 0 then return nil end

    local playerPos = targetPlayer:GetPos()

    local candidates = {}
    for _, node in ipairs(nodes) do
        local dSq = playerPos:DistToSqr(node.pos)
        if dSq >= NODE_DIST_MIN_SQ and dSq <= NODE_DIST_MAX_SQ then
            candidates[#candidates + 1] = node.pos
        end
    end

    if #candidates == 0 then return nil end

    for i = #candidates, 2, -1 do
        local j = math.random(i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end

    local limit = math.min(TP_NODE_TRIES, #candidates)
    for i = 1, limit do
        local pos = candidates[i]
        if IsNodePassable(ent, targetPlayer, pos) then
            return pos + Vector(0, 0, 5)
        end
    end

    return nil
end

local function FindPosByGeometry(ent, targetPlayer)
    local center = targetPlayer:GetPos()

    for _ = 1, TP_FALLBACK_TRIES do
        local angle  = math.Rand(0, 360)
        local dist   = math.Rand(TP_FALLBACK_MIN, TP_FALLBACK_MAX)
        local dest   = center + Vector(math.cos(angle) * dist, math.sin(angle) * dist, 10)

        if IsNodePassable(ent, targetPlayer, dest) then
            return dest + Vector(0, 0, 5)
        end
    end

    return nil
end

local function FindSafeTeleportPos(ent, targetPlayer)
    return FindPosByNodes(ent, targetPlayer)
        or FindPosByGeometry(ent, targetPlayer)
end

MUTATION.Hooks.Horde_OnSetMutation = function(ent, mutation)
    if mutation ~= "voidwalker" then return end
    if not SERVER then return end
    if not IsValid(ent) then return end

    ent:SetColor(Color(150, 0, 255))
    ent:SetRenderMode(RENDERMODE_NORMAL)

    local id       = ent:EntIndex()
    local tpTimer  = "Horde_VoidTP_"    .. id
    local decTimer = "Horde_VoidDecay_" .. id

    timer.Create(tpTimer, math.random(TP_INTERVAL_MIN, TP_INTERVAL_MAX), 0, function()
        if not IsValid(ent) then
            timer.Remove(tpTimer)
            return
        end

        local closestPly, minDistSq = nil, math.huge
        for _, ply in ipairs(player.GetAll()) do
            if not IsValid(ply) or not ply:Alive() then continue end
            local d = ent:GetPos():DistToSqr(ply:GetPos())
            if d < minDistSq then
                minDistSq = d
                closestPly = ply
            end
        end

        if IsValid(closestPly) then
            local newPos = FindSafeTeleportPos(ent, closestPly)
            if newPos then
                CreatePurpleSmoke(ent:GetPos())
                ent:SetPos(newPos)

                local phys = ent:GetPhysicsObject()
                if IsValid(phys) then
                    phys:SetVelocity(Vector(0, 0, 0))
                end

                CreatePurpleSmoke(newPos)
                ent:EmitSound("ambient/machines/teleport4.wav", 75, 100)
            end
        end

        timer.Adjust(tpTimer, math.random(TP_INTERVAL_MIN, TP_INTERVAL_MAX))
    end)

    timer.Create(decTimer, DECAY_INTERVAL, 0, function()
        if not IsValid(ent) then
            timer.Remove(decTimer)
            return
        end

        local hp = ent:Health()

        if hp > DECAY_KILL_THRESH then
            ent:SetHealth(hp - DECAY_AMOUNT)
        else
            local ef = EffectData()
            ef:SetOrigin(ent:GetPos())
            ef:SetEntity(ent)
            util.Effect("cball_explode", ef)

            ent:SetHealth(0)
            ent:Kill()

            timer.Remove(decTimer)
        end
    end)
end

MUTATION.Hooks.Horde_OnUnsetMutation = function(ent, mutation)
    if mutation ~= "voidwalker" then return end
    if not SERVER then return end

    local id = ent:EntIndex()
    timer.Remove("Horde_VoidTP_"    .. id)
    timer.Remove("Horde_VoidDecay_" .. id)

    if IsValid(ent) then
        ent:SetColor(Color(255, 255, 255))
    end
end

MUTATION.Hooks.Horde_OnEnemyKilled = function(ent, attacker, inflictor)
    if not SERVER then return end
    if not IsValid(ent) then return end
    if not ent:Horde_HasMutation("voidwalker") then return end

    local id = ent:EntIndex()
    timer.Remove("Horde_VoidTP_"    .. id)
    timer.Remove("Horde_VoidDecay_" .. id)
end
