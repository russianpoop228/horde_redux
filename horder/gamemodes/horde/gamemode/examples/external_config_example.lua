-- =============================================================
-- ПРИМЕР: своя сложность + свой пер-сложностный конфиг (внешний аддон)
-- =============================================================
-- Пер-сложностные конфиги — это файловая альтернатива Enemy Config: файл
-- становится СТАНДАРТНЫМ дефолтом врагов/боссов сложности (игровое меню
-- Enemy Config по-прежнему накатывается поверх и сохраняется).
--
-- Чтобы добавить свою сложность вместе с её конфигом из внешнего аддона:
--
--   1) Сложность (обычным способом):
--        addons/my_horde/lua/horde/modules/difficulties/my_mode.lua
--      HORDE:RegisterDifficulty({ Name = "MY_MODE", Index = 20, Include = "APOCALYPSE" })
--
--   2) Конфиг этой сложности (этот файл — только пример!):
--        addons/my_horde/lua/horde/modules/configs/my_mode.lua
--      Встроенные конфиги лежат в gamemode/modules/configs/ (например boss_rush.lua).
--
-- Полное описание полей — в шапке секции CONFIG в
-- system/shared/world/sh_enemy.lua.
-- =============================================================

HORDE_CONFIG = {
    Difficulty = "MY_MODE",

    -- true → взять общий пул обычных врагов (modules/enemies/*) и наложить
    -- Enemies/Bosses поверх; false → у сложности только то, что задано здесь.
    BaseDefault = true,

    -- Дополнительные/переопределённые обычные враги (формат ENEMY):
    Enemies = {
        -- { Name = "Elite Zombie", Class = "npc_vj_horde_zombie", Wave = 3,
        --   Weight = 0.5, HealthScale = 2, IsElite = true },
    },

    -- Босс(ы) по волнам (регистрируются только в MY_MODE). Значение — имя
    -- (ENEMY.Name из modules/enemies/bosses/*) или список имён (случайный).
    Bosses = {
        [1]  = "Hunter",
        [5]  = { "Hell Knight", "Mutated Hulk" },
        [10] = "Subject: Wallace Breen",
    },
}

-- ── Вариант: полностью свой набор (без общего пула) ────────────
--[[
HORDE_CONFIG = {
    Difficulty  = "MY_MODE",
    BaseDefault = false,
    Enemies = {
        { Name = "Zombie",      Class = "npc_vj_horde_zombie",      Wave = 1, Weight = 1 },
        { Name = "Fast Zombie", Class = "npc_vj_horde_fast_zombie", Wave = 2, Weight = 1 },
    },
    Bosses = { [3] = "Hunter" },
}
]]
