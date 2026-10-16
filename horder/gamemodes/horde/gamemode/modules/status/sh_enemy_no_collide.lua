CreateConVar("horde_enable_enemy_push", 1, { FCVAR_SERVER_CAN_EXECUTE },
    "Enemies do not collide, but softly push each other away.")

local PUSH_RADIUS    = 52
local MAX_PUSH_SPEED = 90
local PUSH_FORCE     = 45
local PUSH_INTERVAL  = 0.08

local function Horde_IsWaveEnemy(ent)
    if not IsValid(ent) then return false end
    if not (ent:IsNPC() or ent:IsNextBot()) then return false end
    if not HORDE or not HORDE.spawned_enemies then return false end
    return HORDE.spawned_enemies[ent:EntIndex()] == true
end

local function GetSafeDirection(posA, posB, entA, entB)
    local dir = posA - posB
    dir.z = 0
    local dist = dir:Length()
    if dist < 1 then
        local ia, ib = entA:EntIndex(), entB:EntIndex()
        local ang = ((ia * 53 + ib * 97) % 360) * (math.pi / 180)
        return Vector(math.cos(ang), math.sin(ang), 0), 1
    end
    return dir / dist, dist
end

local function PushEnemiesApart()
    if not HORDE or not HORDE.spawned_enemies then return end

    local enemies = {}
    for idx in pairs(HORDE.spawned_enemies) do
        local ent = Entity(idx)
        if IsValid(ent) and ent:Health() > 0 then
            table.insert(enemies, ent)
        end
    end

    local count = #enemies
    if count < 2 then return end

    for i = 1, count do
        local ent = enemies[i]
        local pos = ent:GetPos()
        local push = Vector(0, 0, 0)
        local neighbors = 0

        for _, other in ipairs(ents.FindInSphere(pos, PUSH_RADIUS)) do
            if other ~= ent and Horde_IsWaveEnemy(other) and other:Health() > 0 then
                local dir, dist = GetSafeDirection(pos, other:GetPos(), ent, other)
                if dist < PUSH_RADIUS then
                    local weight = 1 - (dist / PUSH_RADIUS)
                    push:Add(dir * weight)
                    neighbors = neighbors + 1
                end
            end
        end

        if neighbors > 0 then
            local push_len = push:Length()
            if push_len > 0.001 then
                local push_dir = push / push_len
                local strength = math.min(push_len, 1.0)

                local cur_vel = ent:GetVelocity()
                local cur_h = Vector(cur_vel.x, cur_vel.y, 0)
                local current_push_speed = cur_h:Dot(push_dir)

                if current_push_speed < MAX_PUSH_SPEED then
                    local add = math.Clamp(MAX_PUSH_SPEED - current_push_speed, 0, PUSH_FORCE * strength)
                    ent:SetVelocity(push_dir * add)
                end
            end
        end
    end
end

if SERVER then
    timer.Create("Horde_EnemyPush", PUSH_INTERVAL, 0, function()
        if GetConVar("horde_enable_enemy_push"):GetInt() == 0 then return end
        PushEnemiesApart()
    end)
end

hook.Add("Horde_ShouldCollide", "Horde_EnemyNoCollide", function(ent1, ent2)
    if Horde_IsWaveEnemy(ent1) and Horde_IsWaveEnemy(ent2) then
        return false
    end
end)
