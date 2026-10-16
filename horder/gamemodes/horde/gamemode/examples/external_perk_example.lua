-- =============================================================
-- ПРИМЕР: Добавление нового перка из внешнего аддона
-- =============================================================
-- Путь файла:
--   addons/my_horde_addon/lua/horde/modules/perks/assault/assault_fury.lua
--
-- Этот файл будет автоматически обнаружен загрузчиком Horde
-- и зарегистрирован без каких-либо изменений в ядре.
-- =============================================================

-- ─── ВАРИАНТ А: Старый стиль (по-прежнему работает) ─────────
-- Просто объявить PERK = {} — загрузчик его прочитает и зарегистрирует.

PERK = {}

PERK.PrintName = "Assault Fury"
PERK.ClassName = "assault_fury"  -- уникальное имя, строчными буквами

PERK.Description = [[
An Assault perk for Tier 2, Slot 2.
When you have full Adrenaline stacks, deal {1} bonus damage.
Duration: {2} seconds.
]]

PERK.Icon = "items/perks/assault_fury.png"

-- Для какого класса/подкласса
PERK.ClassName = "assault_fury"

-- Таблица параметров (подставляются в Description вместо {1}, {2}, ...)
PERK.Params = {
    [1] = { value = 0.20, percent = true },
    [2] = { value = 5 },
}

-- Хуки — вся логика перка здесь
PERK.Hooks = {}

PERK.Hooks.Horde_OnPlayerDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    if not ply:Horde_GetPerk("assault_fury") then return end
    -- Проверяем максимальный стак адреналина
    if ply:Horde_GetAdrenalineStack() >= ply:Horde_GetMaxAdrenalineStack() then
        bonus.increase = bonus.increase + 0.20
    end
end

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if SERVER and perk == "assault_fury" then
        -- Дополнительная инициализация при выборе перка
    end
end

-- Загрузчик автоматически вызовет HORDE:RegisterPerk(PERK) после include()
-- Поэтому НИЧЕГО БОЛЬШЕ НЕ НУЖНО.

-- ─── ВАРИАНТ Б: Новый явный стиль ────────────────────────────
-- Если хочешь явно контролировать регистрацию:
--[[
HORDE:RegisterPerk({
    ClassName   = "assault_fury",
    PrintName   = "Assault Fury",
    Description = "...",
    Icon        = "items/perks/assault_fury.png",
    Params      = { [1] = { value = 0.20, percent = true } },
    Hooks = {
        Horde_OnPlayerDamage = function(ply, npc, bonus, hitgroup, dmginfo)
            if not ply:Horde_GetPerk("assault_fury") then return end
            bonus.increase = bonus.increase + 0.20
        end
    }
})
]]

-- ─── ВАРИАНТ В: Переопределить существующий перк ─────────────
-- Чтобы изменить встроенный перк из внешнего аддона:
--[[
-- Этот файл грузится ПОСЛЕ встроенных (external modules последние)
-- поэтому просто зарегистрируй под тем же именем:

HORDE:RegisterPerk({
    ClassName = "assault_charge",  -- имя СУЩЕСТВУЮЩЕГО перка
    PrintName = "Charge (Buffed)",
    -- ... новые параметры
    -- Старые хуки будут удалены, новые добавлены
})
]]
