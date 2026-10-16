local DIFF = "HUNDRED"
local function V(key, default)
    return HORDE.DiffCfg(DIFF, key, default)
end

HORDE:RegisterDifficulty({
    Name    = DIFF,
    Index   = 7,
    IsModifier = true,

    IsHundred    = true,
    MaxWaves     = 100,
    ScalePerWave = 0.025,

    SpawnInterval            = V("SpawnInterval", 1),
    SpawnIntervalWaveStep    = V("SpawnIntervalWaveStep", 5),
    SpawnIntervalWaveAmount  = V("SpawnIntervalWaveAmount", 0.075),
    SpawnIntervalWaveCap     = V("SpawnIntervalWaveCap", 0.25),

    AdditionalEnemiesPerSpawn = V("AdditionalEnemiesPerSpawn", 0),
    EnemiesPerSpawnWaveStep   = V("EnemiesPerSpawnWaveStep", 10),
    EnemiesPerSpawnWaveAmount = V("EnemiesPerSpawnWaveAmount", 1),
    EnemiesPerSpawnWaveCap    = V("EnemiesPerSpawnWaveCap", 4),

})
