ENEMY = {}

ENEMY.Name = "Zombine"
ENEMY.Class = "npc_vj_horde_zombine"
ENEMY.IsElite = false
ENEMY.HealthScale = 1
ENEMY.ModelScale = 1
ENEMY.Waves = {
    [5] = { Weight = 0.15, DamageScale = 1.1, RewardScale = 1 },
    [6] = { Weight = 0.10, DamageScale = 1, RewardScale = 1.1, SpawnMin = 1 },
    [7] = { Weight = 0.08, DamageScale = 1, RewardScale = 1.1 },
    [8] = { Weight = 0.08, DamageScale = 1, RewardScale = 1.1 },
    [9] = { Weight = 0.08, DamageScale = 1, RewardScale = 1 },
    [666] = { Weight = 0.4, DamageScale = 1.5, RewardScale = 1, HealthScale = 2, ModelScale = 1.15}
}
