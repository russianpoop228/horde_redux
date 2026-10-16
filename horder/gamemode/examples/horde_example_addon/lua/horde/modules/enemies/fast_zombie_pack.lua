ENEMY = {}

ENEMY.Name        = "Fast Zombie Pack"
ENEMY.Class       = "npc_fastzombie"
ENEMY.Weight      = 0.5
ENEMY.Waves       = {
    [2] = { Weight = 0.25 },
    [3] = {},
    [4] = {},
    [7] = { Weight = 0.15, SpawnMin = 1 },
}
ENEMY.IsElite     = false
ENEMY.HealthScale = 1
ENEMY.DamageScale = 1
ENEMY.RewardScale = 1
ENEMY.ModelScale  = 1
