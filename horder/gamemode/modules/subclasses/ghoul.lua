SUBCLASS.PrintName = "Ghoul"
SUBCLASS.Category = 4
SUBCLASS.SortOrder = 6
SUBCLASS.UnlockCost = 125
SUBCLASS.ParentClass = HORDE.Class_Survivor
SUBCLASS.Icon = "subclasses/ghoul.png"
SUBCLASS.Description = [[
Constantly loses health.
Deals damage to survive.
Pretty fast.]]
SUBCLASS.BasePerk = "ghoul_base"
SUBCLASS.Perks = {
    [1] = {title = "Patience", choices = {"ghoul_unhealthy_taste", "ghoul_glass_cannon"}},
    [2] = {title = "Balance", choices = {"ghoul_insatiable_thirst","ghoul_light_speed"}},
    [3] = {title = "Truth", choices = {"ghoul_cornered_beast", "ghoul_quickest_of_all"}},
    [4] = {title = "Purpose", choices = {"ghoul_humanity", "ghoul_putrid_odor"}},
}
