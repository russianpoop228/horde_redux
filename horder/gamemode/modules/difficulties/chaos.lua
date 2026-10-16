local DIFF = "CHAOS"
local function V(key, default)
    return HORDE.DiffCfg(DIFF, key, default)
end

HORDE:RegisterDifficulty({
    Name  = DIFF,
    Index = 4,

    DamageMult   = V("DamageMult", 2.185),
    HealthMult   = V("HealthMult", 1.725),

    RewardMult      = V("RewardMult", 0.348),
    StartMoneyMult  = V("StartMoneyMult", 0.522),

    EnemyCountMult          = V("EnemyCountMult", 1.955),
    SpawnRadiusMult         = V("SpawnRadiusMult", 0.6),
    MaxEnemiesScaleFactor   = V("MaxEnemiesScaleFactor", 1.495),
    AdditionalPack          = V("AdditionalPack", 4),
    AdditionalAmmoboxes     = V("AdditionalAmmoboxes", 0),
    AdditionalEnemiesPerSpawn = V("AdditionalEnemiesPerSpawn", 2),
    MaxEnemiesAliveBase      = V("MaxEnemiesAliveBase", 20),
    MaxEnemiesAlivePerPlayer = V("MaxEnemiesAlivePerPlayer", 5),
    MaxEnemiesAliveCap       = V("MaxEnemiesAliveCap", 100),

    StatusDurationBonus      = V("StatusDurationBonus", 5),
    BreakHealthLeft          = V("BreakHealthLeft", 0.04),
    ShockDamageIncrease      = V("ShockDamageIncrease", 0.35),
    FrostbiteSlow            = V("FrostbiteSlow", 0.60),
    PoisonHeadcrabDamage     = V("PoisonHeadcrabDamage", 90),

    EliteHealthScaleAdd         = V("EliteHealthScaleAdd", 0.145),
    EliteHealthScaleMultiplier  = V("EliteHealthScaleMultiplier", 1.38),
    MutationProbability         = V("MutationProbability", 0.45),
    EliteMutationProbability    = V("EliteMutationProbability", 0.55),
})
