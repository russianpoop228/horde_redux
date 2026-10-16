SPELL.PrintName       = "Raise Lightning God"
SPELL.Weapon          = {"horde_solar_seal"}
SPELL.Mind            = {40}
SPELL.ChargeTime      = {1}
SPELL.Cooldown        = 8
SPELL.Slot            = HORDE.Spell_Slot_Reload
SPELL.DamageType      = {HORDE.DMG_LIGHTNING}
SPELL.Type            = {HORDE.Spell_Type_Minion}
SPELL.Icon            = "spells/raise_screecher_spectre.png"
SPELL.Description    = [[Raises the Lightning God — a screecher spectre charged with solar lightning.
It has no melee attack: instead it discharges a shock blast around itself, damaging nearby enemies and building up Shock on them.
Fixed 2048 HP and no upgrades. You can have at most 1 Lightning God alive, and it does not take up the Spectre limit.]]
SPELL.Fire            = function (ply, wpn, charge_stage)
    return HORDE:RaiseSpectre(ply, {screecher_spectre = true})
end
SPELL.Price                      = 1200
