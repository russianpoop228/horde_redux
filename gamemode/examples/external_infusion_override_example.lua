-- =============================================================
-- ПРИМЕР: Переопределение встроенной инфузии (например Quality)
-- Путь: addons/my_addon/lua/horde/modules/infusions/07_quality_override.lua
--
-- Тот же Id=7, Key=Quality — RegisterInfusion обновит Name/Icon/OnDamage.
-- Файлы аддона грузятся после встроенных modules/infusions/.
-- =============================================================

INFUSION = {}

INFUSION.Id   = 7
INFUSION.Key  = "Quality"
INFUSION.Name = "Quality (Enhanced)"
INFUSION.Icon = "star.png"
INFUSION.Color = color_white
INFUSION.Description = [[
30% increased weapon damage.

Weapon damage is no longer affected by perks or gadgets.
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    bonus.increase = 0.30
    bonus.more = 1
    bonus.damage_add = 0
    return true
end
