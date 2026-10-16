-- =============================================================
-- ПРИМЕР: Подкласс из внешнего аддона
-- Путь: addons/my_addon/lua/horde/modules/subclasses/ranger.lua
-- =============================================================

SUBCLASS = {}

SUBCLASS.PrintName    = "Ranger"           -- или HORDE.Class_... если есть
SUBCLASS.Description  = [[
Long-range specialist. Bonus damage with rifles at distance.
]]
SUBCLASS.ParentClass  = "Ghost"            -- базовый класс, если применимо
SUBCLASS.Icon         = "Ranger.png"
SUBCLASS.BasePerk     = "ranger_base"

-- Магический подкласс (использует Кузню Заклинаний / заклинания)?
-- Достаточно объявить флаг — ядро править не нужно:
--   SUBCLASS.IsSpellcaster = true
-- Это учитывается в HORDE:IsSpellcasterClass (магазин показывает раздел
-- заклинаний) и в HORDE:IsPlayerSpellcaster (владелец считается магом).

SUBCLASS.Perks = {
    -- [1] = { title = "Tier 1", choices = { "ranger_perk_a", "ranger_perk_b" } },
}
