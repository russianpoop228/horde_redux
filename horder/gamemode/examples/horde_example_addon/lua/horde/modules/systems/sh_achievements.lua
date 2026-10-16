HORDE.PlayerAchievements:Register({
    id     = "example_elite_hunter",
    name   = { en = "Elite Hunter", ru = "Охотник на элиту" },
    desc   = { en = "Kill 50 elite enemies.", ru = "Убейте 50 элитных врагов." },
    icon   = "materials/gui/bolt.png",
    goal   = 50,
    event  = "kill",
    filter = function(ply, ctx) return ctx.elite end,
    reward = { skulls = 1, exp = 300 },
})
