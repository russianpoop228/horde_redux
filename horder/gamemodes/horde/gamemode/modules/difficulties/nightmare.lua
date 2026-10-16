local DIFF = "NIGHTMARE"
local function V(key, default)
    return HORDE.DiffCfg(DIFF, key, default)
end

HORDE:RegisterDifficulty({
    Name  = DIFF,
    Index = 2,

    DamageMult   = V("DamageMult", 1.7),
    HealthMult   = V("HealthMult", 1.5),

    RewardMult      = V("RewardMult", 0.5),
    StartMoneyMult  = V("StartMoneyMult", 0.75),

    EnemyCountMult          = V("EnemyCountMult", 1.6),
    SpawnRadiusMult         = V("SpawnRadiusMult", 0.5),
    MaxEnemiesScaleFactor   = V("MaxEnemiesScaleFactor", 1.25),
    AdditionalPack          = V("AdditionalPack", 2),
    AdditionalAmmoboxes     = V("AdditionalAmmoboxes", 0),
    MaxEnemiesAliveBase      = V("MaxEnemiesAliveBase", 20),
    MaxEnemiesAlivePerPlayer = V("MaxEnemiesAlivePerPlayer", 5),
    MaxEnemiesAliveCap       = V("MaxEnemiesAliveCap", 50),

    StatusDurationBonus      = V("StatusDurationBonus", 3),
    BreakHealthLeft          = V("BreakHealthLeft", 0.10),
    ShockDamageIncrease      = V("ShockDamageIncrease", 0.25),
    FrostbiteSlow            = V("FrostbiteSlow", 0.50),
    PoisonHeadcrabDamage     = V("PoisonHeadcrabDamage", 75),

    EliteHealthScaleAdd         = V("EliteHealthScaleAdd", 0.100),
    EliteHealthScaleMultiplier  = V("EliteHealthScaleMultiplier", 1.1),
    MutationProbability         = V("MutationProbability", 0.20),
    EliteMutationProbability    = V("EliteMutationProbability", 0.30),
})
