SUBCLASS.PrintName = "SpecOps"
SUBCLASS.Category = 2
SUBCLASS.SortOrder = 2
SUBCLASS.UnlockCost = 100
SUBCLASS.ParentClass = HORDE.Class_Assault
SUBCLASS.Icon = "subclasses/specops.png"
SUBCLASS.Description = [[
Slow defensive based firearms class.
Utilizes Tactical Mode and special grenades
to methodically take down enemies.]]
SUBCLASS.BasePerk = "specops_base"
SUBCLASS.Perks = {
    [1] = {title = "Utility", choices = {"specops_smokescreen", "specops_flare"}},
    [2] = {title = "Engage", choices = {"specops_tactical_visor", "specops_neuron_stabilizer"}},
    [3] = {title = "Protection", choices = {"specops_biotic_mask", "specops_adaptive_coating"}},
    [4] = {title = "Sunset", choices = {"specops_night_stalker", "specops_peace_walker"}},
}
