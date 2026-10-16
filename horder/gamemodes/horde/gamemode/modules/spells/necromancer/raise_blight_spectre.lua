SPELL.PrintName       = "Raise Blight Spectre"
SPELL.Weapon          = {"horde_void_projector"}
SPELL.Mind            = {50}
SPELL.ChargeTime      = {1}
SPELL.Cooldown        = 8
SPELL.Slot            = HORDE.Spell_Slot_Reload
SPELL.DamageType      = {HORDE.DMG_PHYSICAL}
SPELL.Type            = {HORDE.Spell_Type_Minion}
SPELL.Icon            = "spells/raise_shadow_blight.png"
SPELL.Description    = [[Raises a blight spectre created using dark matter.
Every hit it takes releases a cloud of blight that frostbites nearby enemies instead of spreading necrosis.
You can have at most 2 Blight Spectres alive. 
They count towards your Spectre limit (perks can increase it).]]
SPELL.Fire            = function (ply, wpn, charge_stage)
    return HORDE:RaiseSpectre(ply, {blight_spectre=true})
end
SPELL.Price                      = 1200
SPELL.Upgrades                   = 3
SPELL.Upgrade_Description        = "Increases minion health and damage."
SPELL.Upgrade_Prices             = function (upgrade_level)
    return 800 + 100 * upgrade_level
end

local UPGRADE_MAX = SPELL.Upgrades or 0
SPELL.Upgrade_Stats              = function (level)
    local nextl = math.min(level + 1, UPGRADE_MAX)
    local function hp(l) return HORDE:GetSpectreHealth("blight", l) end
    local function dmg(l) return math.floor(1.5 * (30 + 6 * l)) end
    return string.format("HP %d -> %d | DMG %d -> %d | ATK 1s", hp(level), hp(nextl), dmg(level), dmg(nextl))
end
