HORDE:RegisterEnemyVariation({
    ParentEntity = "npc_vj_horde_plague_elite",
    Name         = "Plague Watchtower",
    Class        = "npc_vj_horde_plague_watchtower",
    Chance       = HORDE:MakeDifficultyChance({
        base                 = 0.10,
        boosted              = 0.20,
        boosted_from_wave    = 10,
        boosted_difficulties = { HUNDRED = true, UNARMED = true, WAVE_666 = true },
    }),
    Overrides    = {
        health_scale = 1.25,
    },
})
