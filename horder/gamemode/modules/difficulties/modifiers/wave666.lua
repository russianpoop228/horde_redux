local DIFF = "WAVE_666"
local function V(key, default)
    return HORDE.DiffCfg(DIFF, key, default)
end

HORDE:RegisterDifficulty({
    Name    = DIFF,
    Index   = 666,
    Override = "CHAOS",
    IsModifier = true,

    HealthMult                = V("HealthMult", 4),
    AdditionalEnemiesPerSpawn = V("AdditionalEnemiesPerSpawn", 4),

    IsWave666             = true,
    MaxWaves              = 1,
    Wave666KillsBase      = 1024,
    Wave666KillsPerPlayer = 256,
    Wave666StartMoney     = 7500,
    Wave666MoneyPerPlayer = 500,
    Wave666EngineerMetal  = 10000,
    Wave666Skulls         = 66,
    Wave666Exp            = 7500,
})
