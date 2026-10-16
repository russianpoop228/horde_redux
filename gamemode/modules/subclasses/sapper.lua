SUBCLASS.PrintName = "Sapper"
SUBCLASS.Category = 1
SUBCLASS.UnlockCost = 100
SUBCLASS.ParentClass = HORDE.Class_Demolition
SUBCLASS.Icon = "subclasses/sapper.png"
SUBCLASS.Description = [[
Explosive munition expert class.
Uses only mine and trap related weapons.]]
SUBCLASS.BasePerk = "sapper_base"
SUBCLASS.Perks = {
    [1] = {title = "Symbiosis", choices = {"sapper_mortal_fear", "sapper_taming"}},
    [2] = {title = "Potency", choices = {"sapper_sulfur_armor","sapper_evolution"}},
    [3] = {title = "Trigger", choices = {"sapper_sharp_pain","sapper_kinship"}},
    [4] = {title = "Metamorphosis", choices = {"sapper_pyromaniac","sapper_mutation"}},
}
