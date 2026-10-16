ENEMY = {}

ENEMY.Name = "Poison Zombie"
ENEMY.Class = "npc_poisonzombie"
ENEMY.IsElite = false
ENEMY.HealthScale = 1
ENEMY.ModelScale = 1
ENEMY.Waves = {
    [3] = { Weight = 0.20, DamageScale = 1, RewardScale = 1.1 },
    [4] = { Weight = 0.20, DamageScale = 1, RewardScale = 1 },
    [5] = { Weight = 0.20, DamageScale = 1.1, RewardScale = 1 },
    [6] = { Weight = 0.20, DamageScale = 1, RewardScale = 1.1 },
    [7] = { Weight = 0.15, DamageScale = 1, RewardScale = 1.1 },
    [8] = { Weight = 0.15, DamageScale = 1, RewardScale = 1.1 },
    [9] = { Weight = 0.15, DamageScale = 1, RewardScale = 1 },
    [666] = { Weight = 0.35, DamageScale = 1.5, RewardScale = 1, HealthScale = 2, ModelScale = 1.15 },
}
