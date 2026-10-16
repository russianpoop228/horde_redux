HORDE:RegisterEnemyVariation({
    ParentEntity = "npc_vj_horde_walker",
    Name         = "Walker Sprinter",
    Class        = "npc_vj_horde_sprinter",
    Chance       = 0.10,
    Condition    = function(enemy)
        return HORDE:CountClassPlayers("Scout") > 0
    end,
    Appearance   = {
        BasedOn      = "CHAOS",
        SinceWave    = 3,
        Difficulties = { HUNDRED = 20 },
    },
    Overrides    = { RewardScale = 1.5 },
})
