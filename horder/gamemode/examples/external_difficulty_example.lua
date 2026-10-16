-- =============================================================
-- ПРИМЕР: Новая сложность
-- Путь: addons/my_addon/lua/horde/modules/difficulties/my_nightmare.lua
-- (или вызов RegisterDifficulty после загрузки core)
-- =============================================================

hook.Add("Horde_AllModulesLoaded", "MyAddon_RegisterDifficulty", function()
    HORDE:RegisterDifficulty({
        Name       = "My Nightmare",
        Index      = 6,          -- 1-based индекс в массивах сложности
        HealthMult = 1.75,
        -- DamageMult, RewardMult и др. поля — см. core/registry.lua
    })
end)

-- =============================================================
-- Include: сложность «на базе» другой, без копирования характеристик
-- =============================================================
-- Если режим отличается от существующего лишь парой значений — не нужно
-- переписывать все поля и не нужно копировать файл. Достаточно указать базу:
-- все её характеристики применятся, а свои поля переопределят нужное.
--
--   HORDE:RegisterDifficulty({
--       Name    = "MY_HARD_CHAOS",
--       Index   = 12,
--       Include = "CHAOS",              -- алиасы: Inherit / Base / Extends / Parent
--       HealthMult = 3,                 -- переопределяем только это
--       MaxWaves   = 50,
--   })
--
-- База задаётся именем сложности (регистр не важен) или её индексом (число).
--
-- ПРИОРИТЕТ: любое поле, заданное в самой сложности, ВСЕГДА важнее поля базы.
-- Просто вписывайте свои строки поверх основы — никаких ignore-списков не нужно:
--
--   HORDE:RegisterDifficulty({
--       Name    = "MY_HARD_HUNDRED",
--       Index   = 33,
--       Include = "HUNDRED",                        -- берём как основу
--       HealthMult = 3,                             -- своё важнее базы
--       MaxWaves   = 150,
--       EnemyCountMult          = V("EnemyCountMult", 1.955),
--       SpawnRadiusMult         = V("SpawnRadiusMult", 0.6),
--       MaxEnemiesScaleFactor   = V("MaxEnemiesScaleFactor", 1.495),
--       AdditionalPack          = V("AdditionalPack", 4),
--       AdditionalAmmoboxes     = V("AdditionalAmmoboxes", 0),
--       AdditionalEnemiesPerSpawn = V("AdditionalEnemiesPerSpawn", 2),
--       SpawnInterval           = V("SpawnInterval", 1),   -- интервал спавна волны, сек
--   })
--
-- Интервал спавна зомби задаётся полями:
--   * SpawnInterval  — абсолютный интервал волнового директора в секундах
--                      (nil/0 → конвар horde_director_interval, по умолчанию 9 с;
--                      например, 1 — новая пачка врагов раз в секунду);
--   * SpawnSpeedMult — множитель поверх интервала (>1 ускоряет спавн);
--   * SpawnIntervalWaveStep / SpawnIntervalWaveAmount / SpawnIntervalWaveCap —
--                      разгон: каждые Step волн интервал уменьшается на Amount,
--                      но не ниже Cap.
-- Итог = max(мин. интервал, SpawnInterval / SpawnSpeedMult).
-- Все поля редактируются и в Enemy Config → Difficulty Basics.
--
-- Длина забега и награда черепами (необязательные поля):
--   * MaxWaves      — сколько волн в забеге (по умолчанию 10; CASUAL = 5,
--                     UNARMED = 15, HUNDRED = 100, WAVE 666 = 1). Значение > 10
--                     включает расширенные волны: пул конфигов и босс-волна
--                     каждые 5 волн; ScalePerWave — рост HP/урона за волну
--                     сверх 10 (без него награды не меняются).
--   * VictorySkulls — фиксированные черепа за победу (CASUAL = 1). Без поля
--                     действует формула floor(волна/2) + (индекс сложности − 1).
--   * DefeatSkulls  — фиксированные черепа за поражение (CASUAL = 0). Без поля
--                     действует формула floor(волна/2).
--
-- Поле Hooks НЕ наследуется — хуки привязаны к логике конкретного режима;
-- если они нужны, добавьте их в новую сложность вручную.
--
-- «Цепочка» наследования тоже работает: A включается в B, B — в C.
-- Если файл базы грузится позже (файлы сложностей грузятся по алфавиту),
-- наследование применится автоматически после загрузки всех модулей, так что
-- порядок файлов не важен.
--
-- Узнать об успешном наследовании можно по хуку:
--
--   hook.Add("Horde_OnDifficultyInclude", "MyAddon_Log", function(tbl, base)
--       print("[MyAddon] " .. tbl.Name .. " унаследовал " .. base.Name)
--   end)
