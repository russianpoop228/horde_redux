ENEMY = {}

ENEMY.Name = "Fast Zombie"
ENEMY.Class = "npc_fastzombie"
ENEMY.IsElite = false
ENEMY.HealthScale = 0.75
ENEMY.DamageScale = 1
ENEMY.RewardScale = 1
ENEMY.ModelScale = 1
ENEMY.Waves = {
    [2] = { Weight = 0.20 },
    [3] = { Weight = 0.20 },
    [4] = { Weight = 0.20 },
    [5] = { Weight = 0.20 },
    [6] = { Weight = 0.20 },
    [7] = { Weight = 0.20 },
    [8] = { Weight = 0.20 },
    [9] = { Weight = 0.20 },
    [666] = { Weight = 0.45, DamageScale = 1.5, RewardScale = 1, HealthScale = 2, ModelScale = 1.15}
}
