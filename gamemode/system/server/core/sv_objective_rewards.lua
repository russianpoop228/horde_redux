if not SERVER then return end

local cv_radius = CreateConVar("horde_objective_reward_radius", 256,
    { FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE },
    "Радиус (в юнитах) вокруг игрока, в котором убийство врага даёт полную награду, пока активно задание.")

local function InPayloadObjectiveRadius(ply)
    local spawns = HORDE.horde_active_payload_spawns
    if not spawns then return false end

    local pos = ply:GetPos()
    for _, spawn in pairs(spawns) do
        local payload_pos = HORDE:GetPayloadPosition(spawn)
        local radius = HORDE:GetPayloadDeliveryDistance(spawn)
        if payload_pos and radius and pos:DistToSqr(payload_pos) <= radius * radius then
            return true
        end
    end
    return false
end

function HORDE:IsPlayerOnObjective(ply)
    if not IsValid(ply) then return false end

    if ply.Horde_HasPayload and ply:Horde_HasPayload() then return true end
    if InPayloadObjectiveRadius(ply) then return true end

    local steamid = ply:SteamID()
    local function InAnyZone(list)
        if not list then return false end
        for _, zone in pairs(list) do
            if IsValid(zone) and zone.Horde_Players_In_Zone and zone.Horde_Players_In_Zone[steamid] then
                return true
            end
        end
        return false
    end

    return InAnyZone(HORDE.horde_active_holdzones) or InAnyZone(HORDE.horde_active_escapezones)
end

function HORDE:IsKillRewardAllowed(ply, victim)
    if not HORDE.horde_has_active_objective then return true end
    if not IsValid(ply) or not IsValid(victim) then return false end
    if not HORDE:IsPlayerOnObjective(ply) then return false end

    local radius = cv_radius:GetFloat()
    if radius <= 0 then return true end
    return victim:GetPos():DistToSqr(ply:GetPos()) <= radius * radius
end
