SPELL.PrintName       = "Raise Fire God"
SPELL.Weapon          = {"horde_solar_seal"}
SPELL.Mind            = {40}
SPELL.ChargeTime      = {1}
SPELL.Cooldown        = 8
SPELL.Slot            = HORDE.Spell_Slot_Reload
SPELL.DamageType      = {HORDE.DMG_FIRE}
SPELL.Type            = {HORDE.Spell_Type_Minion}
SPELL.Icon            = "spells/raise_scorcher_spectre.png"
SPELL.Description    = [[Raises the Fire God — a scorcher spectre woven from solar fire.
It bites in melee and breathes a cone of flame that ignites the enemies in front of it.
Fixed 1024 HP and no upgrades. You can have at most 2 Fire Gods alive, and they do not take up the Spectre limit.]]
SPELL.Fire            = function (ply, wpn, charge_stage)
    return HORDE:RaiseSpectre(ply, {scorcher_spectre = true})
end
SPELL.Price                      = 1200
