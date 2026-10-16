local DIFF = "BUDGET"
local function V(key, default)
    return HORDE.DiffCfg(DIFF, key, default)
end

HORDE:RegisterDifficulty({
    Name    = DIFF,
    Index   = 10,
    IsModifier = true,

    IsBudget = true,

    BudgetMoneyPerDrop = V("BudgetMoneyPerDrop", 150),
    BudgetSkullChance  = V("BudgetSkullChance", 0.2),
    BudgetSkullAmount  = V("BudgetSkullAmount", 1),
    BudgetDropLifetime = V("BudgetDropLifetime", 45),
    BudgetDropModel    = V("BudgetDropModel", "models/props_c17/oildrum001.mdl"),
    BudgetBossMoneyMin = V("BudgetBossMoneyMin", 1000),
    BudgetBossMoneyMax = V("BudgetBossMoneyMax", 1500),
})
