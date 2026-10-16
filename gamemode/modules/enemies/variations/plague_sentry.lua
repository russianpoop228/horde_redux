local BASE_CHANCE       = 0.10
local BOOSTED_CHANCE    = 0.20
local BOOSTED_FROM_WAVE = 10

HORDE:RegisterEnemyVariation({
    ParentEntity = "npc_vj_horde_plague_elite",
    Name         = "Plague Sentry",
    Class        = "npc_vj_horde_plague_sentry",
    Chance       = HORDE:MakeDifficultyChance({
        base                 = BASE_CHANCE,
        boosted              = BOOSTED_CHANCE,
        boosted_from_wave    = BOOSTED_FROM_WAVE,
        boosted_difficulties = { HUNDRED = true, UNARMED = true, WAVE_666 = true },
    }),
})
