local DIFF = "CASUAL"
local function V(key, default)
    return HORDE.DiffCfg(DIFF, key, default)
end

HORDE:RegisterDifficulty({
    Name  = DIFF,
    Index = 1,

    DamageMult   = V("DamageMult", 1.0),
    HealthMult   = V("HealthMult", 1.0),

    RewardMult      = V("RewardMult", 1.0),
    StartMoneyMult  = V("StartMoneyMult", 1.0),

    EnemyCountMult          = V("EnemyCountMult", 1.0),
    SpawnRadiusMult         = V("SpawnRadiusMult", 1.0),
    MaxEnemiesScaleFactor   = V("MaxEnemiesScaleFactor", 1.0),
    AdditionalPack          = V("AdditionalPack", 0),
    AdditionalAmmoboxes     = V("AdditionalAmmoboxes", 2),
    MaxEnemiesAliveBase      = V("MaxEnemiesAliveBase", 20),
    MaxEnemiesAlivePerPlayer = V("MaxEnemiesAlivePerPlayer", 5),
    MaxEnemiesAliveCap       = V("MaxEnemiesAliveCap", 50),

    StatusDurationBonus      = V("StatusDurationBonus", 0),
    BreakHealthLeft          = V("BreakHealthLeft", 0.20),
    ShockDamageIncrease      = V("ShockDamageIncrease", 0.15),
    FrostbiteSlow            = V("FrostbiteSlow", 0.40),
    PoisonHeadcrabDamage     = V("PoisonHeadcrabDamage", 50),

    EliteHealthScaleAdd         = V("EliteHealthScaleAdd", 0.025),
    EliteHealthScaleMultiplier  = V("EliteHealthScaleMultiplier", 1.0),
    MutationProbability         = V("MutationProbability", 0),
    EliteMutationProbability    = V("EliteMutationProbability", 0),

    MaxWaves = 5,
    VictorySkulls = 1,
    DefeatSkulls  = 0,
})
