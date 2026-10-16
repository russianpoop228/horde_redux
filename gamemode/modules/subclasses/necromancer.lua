SUBCLASS.PrintName = "Necromancer"
SUBCLASS.Category = 3
SUBCLASS.SortOrder = 3
SUBCLASS.UnlockCost = 100
SUBCLASS.ParentClass = HORDE.Class_Engineer
SUBCLASS.Icon = "subclasses/necromancer.png"
SUBCLASS.Description = [[
Summons minions and casts cold spells.
Focuses on chilling enemies to slow them 
while using spectre minions to stall enemies.]]
SUBCLASS.BasePerk = "necromancer_base"
SUBCLASS.IsSpellcaster = true
SUBCLASS.Perks = {
    [1] = {title = "Domination", choices = {"necromancer_withering_prescence", "necromancer_hollow_essence"}},
    [2] = {title = "Recovery", choices = {"necromancer_energy_siphon", "necromancer_eldritch_protection"}},
    [3] = {title = "Occultism", choices = {"necromancer_occult_armor", "necromancer_abyssal_might"}},
    [4] = {title = "Apex", choices = {"necromancer_beacon_of_void", "necromancer_necromastery"}},
}
