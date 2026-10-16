local DIFF = "APOCALYPSE"
local function V(key, default)
    return HORDE.DiffCfg(DIFF, key, default)
end

HORDE:RegisterDifficulty({
    Name  = DIFF,
    Index = 3,

    DamageMult   = V("DamageMult", 1.9),
    HealthMult   = V("HealthMult", 1.5),

    RewardMult      = V("RewardMult", 0.4),
    StartMoneyMult  = V("StartMoneyMult", 0.6),

    EnemyCountMult          = V("EnemyCountMult", 1.7),
    SpawnRadiusMult         = V("SpawnRadiusMult", 0.4),
    MaxEnemiesScaleFactor   = V("MaxEnemiesScaleFactor", 1.3),
    AdditionalPack          = V("AdditionalPack", 3),
    AdditionalAmmoboxes     = V("AdditionalAmmoboxes", 0),
    MaxEnemiesAliveBase      = V("MaxEnemiesAliveBase", 20),
    MaxEnemiesAlivePerPlayer = V("MaxEnemiesAlivePerPlayer", 5),
    MaxEnemiesAliveCap       = V("MaxEnemiesAliveCap", 50),

    StatusDurationBonus      = V("StatusDurationBonus", 4),
    BreakHealthLeft          = V("BreakHealthLeft", 0.05),
    ShockDamageIncrease      = V("ShockDamageIncrease", 0.30),
    FrostbiteSlow            = V("FrostbiteSlow", 0.55),
    PoisonHeadcrabDamage     = V("PoisonHeadcrabDamage", 75),

    EliteHealthScaleAdd         = V("EliteHealthScaleAdd", 0.125),
    EliteHealthScaleMultiplier  = V("EliteHealthScaleMultiplier", 1.2),
    MutationProbability         = V("MutationProbability", 0.30),
    EliteMutationProbability    = V("EliteMutationProbability", 0.40),
})
