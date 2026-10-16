SUBCLASS.PrintName = "Warlock"
SUBCLASS.Category = 4
SUBCLASS.SortOrder = 4
SUBCLASS.UnlockCost = 100
SUBCLASS.ParentClass = HORDE.Class_Demolition
SUBCLASS.Icon = "subclasses/warlock.png"
SUBCLASS.Description = [[
Offensive charge based AoE spell caster.
Casts destructive spells dealing damage in 
a massive area depending on charge level.]]
SUBCLASS.BasePerk = "warlock_base"
SUBCLASS.IsSpellcaster = true
SUBCLASS.Perks = {
    [1] = {title = "Transfigure", choices = {"warlock_meditate", "warlock_quickcast"}},
    [2] = {title = "Channelling", choices = {"warlock_sigil_of_courage", "warlock_sigil_of_malediction"}},
    [3] = {title = "Vectorize", choices = {"warlock_arcane_supremacy", "warlock_negative_burst"}},
    [4] = {title = "Annihilation", choices = {"warlock_shaper_of_destruction", "warlock_sigil_mastery"}},
}
