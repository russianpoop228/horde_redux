local BASE_CHANCE         = 0.20
local CHANCE_PER_ENGINEER = 0.05
local MAX_CHANCE          = 0.33

local function CountBaseEngineers()
    local count = 0
    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) and ply:Alive() and ply:Horde_GetClass()
            and ply:Horde_GetClass().name == HORDE.Class_Engineer
            and ply:Horde_GetCurrentSubclass() == HORDE.Class_Engineer then
            count = count + 1
        end
    end
    return count
end

local function HasBaseEngineer()
    return CountBaseEngineers() > 0
end

local function BuildBusterChance()
    local engineers = CountBaseEngineers()
    if engineers < 1 then return 0 end
    return math.min(BASE_CHANCE + CHANCE_PER_ENGINEER * (engineers - 1), MAX_CHANCE)
end

HORDE:RegisterEnemyVariation({
    ParentEntity = "npc_vj_horde_lesion",
    Name         = "Build Buster",
    Class        = "npc_vj_horde_build_buster",
    Chance       = BuildBusterChance,
    Condition    = HasBaseEngineer,
})
