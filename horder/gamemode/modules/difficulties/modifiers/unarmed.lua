local DIFF = "UNARMED"
local function V(key, default)
    return HORDE.DiffCfg(DIFF, key, default)
end

HORDE:RegisterDifficulty({
    Name    = DIFF,
    Index   = 6,
    IsModifier = true,

    IsUnarmed    = true,
    MaxWaves     = 15,

    SpawnInterval            = V("SpawnInterval", 1),
    SpawnIntervalWaveStep    = V("SpawnIntervalWaveStep", 5),
    SpawnIntervalWaveAmount  = V("SpawnIntervalWaveAmount", 0.25),
    SpawnIntervalWaveCap     = V("SpawnIntervalWaveCap", 0.25),
})
