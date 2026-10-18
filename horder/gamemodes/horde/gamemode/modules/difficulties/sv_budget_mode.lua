if not SERVER then return end
if not HORDE then return end

local DROP_CLASS = "horde_budget_drop"

local plymeta = FindMetaTable("Player")
local base_GetMoney, base_SetMoney, base_AddMoney =
    plymeta.Horde_GetMoney, plymeta.Horde_SetMoney, plymeta.Horde_AddMoney

function HORDE:Budget_GetBank()
    if HORDE.budget_bank == nil then
        for _, ply in pairs(player.GetAll()) do
            if IsValid(ply) and ply.Horde_money ~= nil then
                HORDE.budget_bank = math.max(0, math.floor(ply.Horde_money))
                break
            end
        end
    end
    return HORDE.budget_bank or 0
end

function HORDE:Budget_SyncBank()
    local bank = HORDE:Budget_GetBank()
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) then
            ply.Horde_money = bank
            ply:Horde_SyncEconomy()
        end
    end
end

function HORDE:Budget_AddToBank(amount)
    local delta = math.floor(tonumber(amount) or 0)
    if delta == 0 then return end
    HORDE.budget_bank = math.max(0, HORDE:Budget_GetBank() + delta)
    HORDE:Budget_SyncBank()
end

function plymeta:Horde_GetMoney()
    if HORDE.budget_mode then return HORDE:Budget_GetBank() end
    return base_GetMoney(self)
end

function plymeta:Horde_SetMoney(money)
    if HORDE.budget_mode then
        if HORDE.budget_bank == nil then
            HORDE.budget_bank = math.max(0, math.floor(tonumber(money) or 0))
        end
        HORDE:Budget_SyncBank()
        return
    end
    return base_SetMoney(self, money)
end

function plymeta:Horde_AddMoney(money)
    if HORDE.budget_mode then
        HORDE:Budget_AddToBank(money)
        return
    end
    return base_AddMoney(self, money)
end

function HORDE:Budget_GrantSkulls(amount)
    local count = math.max(0, math.floor(tonumber(amount) or 0))
    if count <= 0 then return end
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) and not ply:IsBot() then
            ply:Horde_AddSkullTokens(count)
        end
    end
end

function HORDE:GetBudgetBossReward()
    local min_money = math.max(0, math.floor(tonumber(HORDE.budget_boss_money_min) or 1000))
    local max_money = math.max(min_money, math.floor(tonumber(HORDE.budget_boss_money_max) or 1500))
    return math.random(min_money, max_money)
end

function HORDE:Budget_SpawnDrop(victim)
    if not IsValid(victim) then return end

    local drop = ents.Create(DROP_CLASS)
    if not IsValid(drop) then return end

    local chance = tonumber(HORDE.budget_skull_chance) or 0.2
    local skulls = 0
    if math.random() < chance then
        skulls = math.max(1, math.floor(tonumber(HORDE.budget_skull_amount) or 1))
    end

    drop.Horde_BudgetMoney  = math.max(0, math.floor(tonumber(HORDE.budget_money_per_drop) or 150))
    drop.Horde_BudgetSkulls = skulls
    drop.Horde_Lifetime     = tonumber(HORDE.budget_drop_lifetime) or 45
    drop.Horde_Model        = HORDE.budget_drop_model

    drop:SetPos(victim:GetPos())
    drop:Spawn()
    return drop
end

local drops_this_wave = 0

hook.Add("HordeWaveStart", "Horde_Budget_ResetDrops", function()
    drops_this_wave = 0
end)

hook.Add("Horde_OnEnemyKilled", "Horde_Budget_Drop", function(victim)
    if not HORDE.budget_mode then return end
    if not IsValid(victim) or not victim:IsNPC() then return end
    if (HORDE.current_wave or 0) <= 0 or GetConVar("sv_cheats"):GetInt() == 1 then return end
    if victim.Horde_NoReward then return end
    if (HORDE.current_break_time or 0) > 0 then return end

    local cap = tonumber(HORDE.total_enemies_this_wave_fixed) or 0
    if cap > 0 and drops_this_wave >= cap then return end
    drops_this_wave = drops_this_wave + 1

    HORDE:Budget_SpawnDrop(victim)
end)

hook.Add("Horde_PlayerDropMoney", "Horde_Budget_NoDropMoney", function(ply)
    if not HORDE.budget_mode then return end
    HORDE:SendNotification("You can't drop money in Budget mode.", 1, ply)
    return true
end)

local pending_money, pending_drops = 0, 0
local function FlushBudgetNotice()
    if pending_money <= 0 then return end
    HORDE:SendNotification(string.format("Team budget: +$%d (%d)", pending_money, pending_drops), 0)
    pending_money, pending_drops = 0, 0
end

function HORDE:Budget_Collect(ply, drop)
    if not IsValid(drop) then return end

    local money  = math.max(0, math.floor(tonumber(drop.Horde_BudgetMoney) or 0))
    local skulls = math.max(0, math.floor(tonumber(drop.Horde_BudgetSkulls) or 0))

    if IsValid(ply) then
        ply:EmitSound("horde/dosh/dosh_" .. math.random(1, 4) .. ".ogg", 70, 100, 0.5)
    end

    if money > 0 then
        HORDE:Budget_AddToBank(money)
        pending_money = pending_money + money
        pending_drops = pending_drops + 1
        if not timer.Exists("Horde_BudgetNotice") then
            timer.Create("Horde_BudgetNotice", 3, 1, FlushBudgetNotice)
        end
    end
    if skulls > 0 and IsValid(ply) and not ply:IsBot() then
        ply:Horde_AddSkullTokens(skulls)
        HORDE:SendNotification(string.format("Skull tokens: +%d", skulls), 0, ply)
    end
end
