-- =============================================================
-- ПРИМЕР: Враг из внешнего аддона
-- Путь: addons/my_addon/lua/horde/modules/enemies/my_enemy.lua
-- =============================================================
-- Форматы волны (любой один):
--   ENEMY.Wave  = 3                        -- одна волна
--   ENEMY.Waves = { 2, 3, 4, 5 }           -- несколько волн, общие статы
--   ENEMY.Waves = {                        -- per-wave overrides
--       [1] = { Weight = 0.25 },
--       [7] = { Weight = 0.15, SpawnMin = 1 },
--   }
-- =============================================================

ENEMY = {}

ENEMY.Name         = "Fast Zombie"
ENEMY.Class        = "npc_fastzombie"
ENEMY.Weight       = 0.5
ENEMY.Waves        = { 2, 3, 4, 5 }   -- вместо отдельного файла на каждую волну
ENEMY.IsElite      = false
ENEMY.HealthScale  = 1.0
ENEMY.DamageScale  = 1.0
ENEMY.RewardScale  = 1.0
ENEMY.ModelScale   = 1.0
ENEMY.SpawnLimit   = 0
ENEMY.SpawnMin     = 0
-- ENEMY.Weapon       = ""
-- ENEMY.Mutation     = nil
-- ENEMY.BossProperties = { is_boss = false }
-- ENEMY.GadgetDrop  = { gadget = "gadget_elixir", drop_rate = 0.1 }
