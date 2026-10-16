HORDE.BuilderSystems = HORDE.BuilderSystems or {}

function HORDE:Horde_RegisterBuilderSystem(id, def)
    HORDE.BuilderSystems[id] = def
end

local function GetSystemByWeapon(wpn_class)
    for id, def in pairs(HORDE.BuilderSystems) do
        if def.WeaponClass == wpn_class then return def end
    end
    return nil
end

function HORDE:Horde_GetBuilderSystemForBuildable(class)
    for id, def in pairs(HORDE.BuilderSystems) do
        if def.IsBuildable and def.IsBuildable(class) then return def end
    end
    return nil
end

function HORDE:GetPlayerBuildableClasses()
    local classes = {}
    local function Collect(tbl)
        if type(tbl) ~= "table" then return end
        for class in pairs(tbl) do classes[class] = true end
    end
    Collect(HORDE.EngineerBuildables)
    Collect(HORDE.EngineerBuildableCustom)
    Collect(HORDE.WardenBuildables)
    Collect(HORDE.WardenBuildableCustom)
    classes["horde_engiconstruction"]   = true
    classes["horde_wardenconstruction"] = true
    return classes
end

function HORDE:IsPlayerBuildable(ent)
    if not IsValid(ent) then return false end
    local class = ent:GetClass()
    if class == "horde_engiconstruction" or class == "horde_wardenconstruction" then return true end
    return (HORDE.EngineerBuildables and HORDE.EngineerBuildables[class] ~= nil)
        or (HORDE.EngineerBuildableCustom and HORDE.EngineerBuildableCustom[class] ~= nil)
        or (HORDE.WardenBuildables and HORDE.WardenBuildables[class] ~= nil)
        or (HORDE.WardenBuildableCustom and HORDE.WardenBuildableCustom[class] ~= nil)
end

if SERVER then

local function SpendCurrency(def, ply, amount, kind)
    local ok
    if HORDE:Horde_BuilderCurrencyFor(def, kind) == "metal" then
        ok = ply:Horde_TrySpendMetal(amount)
        if ok and ply.Horde_SyncEconomy then ply:Horde_SyncEconomy() end
    else
        ok = ply:Horde_TrySpendMoney(amount)
    end
    return ok
end

function HORDE:Horde_BuilderCurrencyFor(def, kind)
    if not def then return "money" end
    if kind == "build"    and def.BuildCurrency    then return def.BuildCurrency end
    if kind == "upgrade"  and def.UpgradeCurrency  then return def.UpgradeCurrency end
    if kind == "infusion" and def.InfusionCurrency then return def.InfusionCurrency end
    return def.Currency or "metal"
end

function HORDE:Horde_BuilderSpendCurrency(def, ply, amount, kind)
    return SpendCurrency(def, ply, amount, kind)
end

function HORDE:Horde_BuilderCurrencyName(def, kind)
    return HORDE:Horde_BuilderCurrencyFor(def, kind) == "metal" and "Metal" or "Money"
end

local function AddCurrency(def, ply, amount, kind)
    if HORDE:Horde_BuilderCurrencyFor(def, kind) == "metal" then
        ply:Horde_AddMetal(amount)
    else
        ply:Horde_AddMoney(amount)
    end
    if IsValid(ply) and ply.Horde_SyncEconomy then
        ply:Horde_SyncEconomy()
    end
end

local function CurrencyName(def, kind)
    return HORDE:Horde_BuilderCurrencyName(def, kind)
end

local function FormatAmount(def, amount, kind)
    return HORDE:Horde_BuilderCurrencyFor(def, kind) == "metal" and tostring(amount) or ("$" .. amount)
end

local function BuilderGuard(ply, key, interval)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not ply:Alive() or not ply.Horde_Init_Complete then return false end
    return HORDE:AllowNetRequest(ply, key, interval)
end

util.AddNetworkString("Horde_BuilderRequestBuild")
util.AddNetworkString("Horde_BuilderDestroy")
util.AddNetworkString("Horde_BuilderBuyUpgrade")

net.Receive("Horde_BuilderRequestBuild", function(len, ply)
    if not BuilderGuard(ply, "builder_build", 0.25) then return end
    local class = net.ReadString()
    local wpn = ply:GetActiveWeapon()
    if not IsValid(wpn) then return end
    local def = GetSystemByWeapon(wpn:GetClass())
    if not def then return end
    if wpn:GetReadytoBuild() then return end
    if not def.IsBuildable(class) then return end
    if not ply:Horde_GetPerk(def.Perk) then return end

    local min_level = def.GetMinLevel(class)
    if ply:Horde_GetLevel(def.SubclassClass) < min_level then
        HORDE:SendNotification("Your level is too low for this unit.", 1, ply)
        return
    end

    local limit = def.GetLimit(class)
    local drop_entities = ply:Horde_GetDropEntities() or {}
    if (drop_entities[class] or 0) >= limit then
        HORDE:SendNotification("Build limit reached for this unit.", 1, ply)
        return
    end

    local cost = def.GetCostFor(ply, class)
    if not SpendCurrency(def, ply, cost, "build") then
        HORDE:SendNotification("Not enough " .. CurrencyName(def, "build") .. ".", 1, ply)
        return
    end

    wpn.Horde_BuilderPaidCost = cost
    wpn.Horde_BuilderCurrency = HORDE:Horde_BuilderCurrencyFor(def, "build")

    wpn:Horde_StartPlacement(class)
end)

net.Receive("Horde_BuilderDestroy", function(len, ply)
    if not BuilderGuard(ply, "builder_destroy", 0.25) then return end
    local class = net.ReadString()
    local wpn = ply:GetActiveWeapon()
    if not IsValid(wpn) then return end
    local def = GetSystemByWeapon(wpn:GetClass())
    if not def then return end
    if not def.IsBuildable(class) then return end
    if not ply:Horde_GetPerk(def.Perk) then return end

    local refs = HORDE.player_drop_entities[ply:SteamID()]
    local oldest, oldest_id
    if refs then
        for id, ent in pairs(refs) do
            if IsValid(ent) and ent:GetClass() == class then
                if not oldest_id or id < oldest_id then
                    oldest, oldest_id = ent, id
                end
            end
        end
    end

    if not IsValid(oldest) then
        HORDE:SendNotification("You have none of these built.", 1, ply)
        return
    end

    local refund = math.floor(def.GetCostFor(ply, class) * 0.25)
    oldest.Horde_Minion_Respawn = nil
    timer.Remove("Horde_ManhackRespawn" .. oldest:GetCreationID())
    oldest:Remove()
    AddCurrency(def, ply, refund, "build")
    HORDE:SendNotification("Construction destroyed. Refunded " .. FormatAmount(def, refund, "build") .. ".", 0, ply)
end)

net.Receive("Horde_BuilderBuyUpgrade", function(len, ply)
    if not BuilderGuard(ply, "builder_upgrade", 0.25) then return end
    local class = net.ReadString()
    local wpn = ply:GetActiveWeapon()
    if not IsValid(wpn) then return end
    local def = GetSystemByWeapon(wpn:GetClass())
    if not def then return end
    if not def.IsBuildable(class) then return end
    if not ply:Horde_GetPerk(def.Perk) then return end

    local level = ply:Horde_GetUpgrade(class)
    if level >= def.MaxUpgradeLevel then
        HORDE:SendNotification("This unit is already at max level.", 1, ply)
        return
    end

    local price = def.GetUpgradePrice(class, level, ply)
    if not SpendCurrency(def, ply, price, "upgrade") then
        HORDE:SendNotification("Not enough " .. CurrencyName(def, "upgrade") .. " (need " .. FormatAmount(def, price, "upgrade") .. ").", 1, ply)
        return
    end

    ply:Horde_SetUpgrade(class, level + 1)
    HORDE:SendNotification("Upgraded " .. def.GetPrintName(class) .. " to level " .. (level + 1) .. ".", 0, ply)

    local refs = HORDE.player_drop_entities[ply:SteamID()]
    if refs then
        for _, ent in pairs(refs) do
            if IsValid(ent) and ent:GetClass() == class then
                def.ApplyUpgradeBonus(ent, class, level + 1)
            end
        end
    end
end)

hook.Add("PlayerDeath", "Horde_BuilderCleanupOnDeath", function(ply)
    local wpn = ply:GetActiveWeapon()
    if not IsValid(wpn) then return end
    if GetSystemByWeapon(wpn:GetClass()) and wpn.Horde_StopPlacement then
        wpn:Horde_StopPlacement()
    end
end)

end
