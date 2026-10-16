HORDE_CONFIG = {
    Difficulty  = "MY_MODE",
    BaseDefault = true,

    Enemies = {
        { Name = "Elite Walker", Class = "npc_vj_horde_walker", Wave = 3, Weight = 0.5, HealthScale = 2, IsElite = true },
    },

    Bosses = {
        [5]  = "Hunter",
        [10] = { "Hell Knight", "Mutated Hulk" },
        [15] = "Subject: Wallace Breen",
    },
}
