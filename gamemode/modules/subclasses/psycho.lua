SUBCLASS.PrintName = "Psycho"
SUBCLASS.Category = 4
SUBCLASS.SortOrder = 2
SUBCLASS.UnlockCost = 100
SUBCLASS.ParentClass = HORDE.Class_Survivor
SUBCLASS.Icon = "subclasses/psycho.png"
SUBCLASS.Description = [[
Hybrid melee and ranged offensive class.
Focuses on dealing critical hits to deal 
large amounts of damage with any weapon.]]
SUBCLASS.BasePerk = "psycho_base"
SUBCLASS.Perks = {
    [1] = {title = "Sadism", choices = {"psycho_bloodbath", "psycho_savor"}},
    [2] = {title = "Violence", choices = {"psycho_ferocity", "psycho_disembowel"}},
    [3] = {title = "Fatality", choices = {"psycho_skewering", "psycho_brutality"}},
    [4] = {title = "Psychosis", choices = {"psycho_grudge", "psycho_bestial_wrath"}},
}
