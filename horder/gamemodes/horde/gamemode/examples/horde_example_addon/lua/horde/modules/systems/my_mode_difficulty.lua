local DIFF = "MY_MODE"
local function V(key, default)
    return HORDE.DiffCfg(DIFF, key, default)
end

HORDE:RegisterDifficulty({
    Name    = DIFF,
    Index   = 20,
    Include = "CHAOS",

    HealthMult    = V("HealthMult", 3),
    MaxWaves      = 15,
    SpawnInterval = V("SpawnInterval", 4),
    VictorySkulls = 5,
})
