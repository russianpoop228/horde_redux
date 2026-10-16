HORDE:RegisterClass({
    name        = "Scout",
    description = "Fast skirmisher. Builds Overcharge on kills.",
    max_hp      = 90,
    movespd     = 200,
    sprintspd   = 260,
    base_perk   = "scout_base",
    perks       = {
        [1] = { title = "Instinct", choices = { "scout_fury", "scout_dash" } },
    },
    order       = 20,
    icon        = "Ghost.png",
    subclasses  = { "Scout" },
})
