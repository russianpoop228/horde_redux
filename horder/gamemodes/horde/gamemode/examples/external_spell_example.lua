-- =============================================================
-- ПРИМЕР: Заклинание из внешнего аддона
-- Путь: addons/my_addon/lua/horde/modules/spells/my_frost_bolt.lua
-- =============================================================

SPELL = {}

SPELL.PrintName   = "Frost Bolt"
SPELL.ClassName   = "frost_bolt"
SPELL.Description = [[
Launch a frost bolt that deals {1} cold damage and slows the target.
]]
SPELL.Icon        = "items/spells/frost_bolt.png"
SPELL.ChargeTime  = { 0.5, 1.0 }
SPELL.Cooldown    = 3
SPELL.Slot        = HORDE.Spell_Slot_LMB  -- если константа есть; иначе число слота

SPELL.Params = {
    [1] = { value = 50 },
}

SPELL.Hooks = {}

-- SPELL.Hooks.Horde_UseSpell = function(ply, spell) ... end
