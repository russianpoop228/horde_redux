HORDE.EngineerBuildables = {
    npc_vj_horde_rebel_turret = {
        PrintName   = "Rebel Turret",
        Category    = "distant",
        Model       = "models/combine_turrets/floor_turret.mdl",
        Icon        = "items/npc_turret_floor.png",
        Description = "Combine Overwatch turret, repainted by the resistance. Used to guard choke points and vital areas.",
        Cost        = 250,
        Limit       = 2,
        DeployTime  = 15,
        Health      = 400,
        Damage      = 10,
        FireRate    = 0.4,
        AmmoMax     = 400,
        DamageType  = "BALLISTIC",
        IsMinion    = false,
        AmmoTracked = true,
    },
    npc_vj_horde_shotgun_turret = {
        PrintName   = "Shotgun Turret",
        Category    = "distant",
        Model       = "models/combine_turrets/floor_turret.mdl",
        Icon        = "items/shotgun_turret.png",
        Description = "Combine shotgun turret. Fires a heavy slug in a wide spread.",
        Cost        = 1250,
        Limit       = 2,
        DeployTime  = 30,
        Health      = 400,
        Damage      = 20,
        FireRate    = 1.33,
        AmmoMax     = 1200,
        DamageType  = "BALLISTIC",
        IsMinion    = false,
        AmmoTracked = true,
    },
    npc_vj_horde_rocket_turret = {
        PrintName   = "Rocket Turret",
        Category    = "distant",
        Model       = "models/horde/rocket_turret/rocket_turret.mdl",
        Icon        = "items/rocket_turret.png",
        Description = "Aperture Science rocket turret. Shoots mini-missiles that deal splash damage.",
        Cost        = 1500,
        Limit       = 2,
        DeployTime  = 35,
        Health      = 400,
        Damage      = 100,
        FireRate    = 1,
        AmmoMax     = 200,
        DamageType  = "BLAST",
        IsMinion    = false,
        AmmoTracked = true,
    },
    npc_vj_horde_laser_turret = {
        PrintName   = "Laser Turret",
        Category    = "distant",
        Model       = "models/horde/rocket_turret/rocket_turret.mdl",
        Icon        = "items/laser_turret.png",
        Description = "Aperture Science laser turret. Fires a tracing beam at the enemy.",
        Cost        = 2500,
        Limit       = 2,
        DeployTime  = 35,
        Health      = 400,
        Damage      = 9,
        FireRate    = 1,
        AmmoMax     = 1500,
        DamageType  = "BLAST",
        IsMinion    = false,
        AmmoTracked = true,
    },
    npc_vj_horde_sniper_turret = {
        PrintName   = "Sniper Turret",
        Category    = "distant",
        Model       = "models/combine_turrets/ground_turret.mdl",
        Icon        = "items/sniper_turret.png",
        Description = "Combine heavy sniper turret. Long range, aims for the head if possible.",
        Cost        = 2750,
        Limit       = 2,
        DeployTime  = 35,
        Health      = 400,
        Damage      = 160,
        FireRate    = 1.11,
        AmmoMax     = 450,
        DamageType  = "BALLISTIC",
        IsMinion    = false,
        AmmoTracked = true,
    },
    npc_vj_horde_tank_turret = {
        PrintName   = "Tank Sentry",
        Category    = "distant",
        Model       = "models/hordeshg/TankSentry.mdl",
        Icon        = "items/horde_tank_sentry.png",
        Description = "Fires heavy rounds, emits a shockwave that stuns nearby enemies, and slowly regenerates.",
        Cost        = 3750,
        Limit       = 1,
        DeployTime  = 45,
        Health      = 800,
        Damage      = 150,
        FireRate    = 0.5,
        AmmoMax     = 50,
        DamageType  = "BALLISTIC",
        IsMinion    = false,
        AmmoTracked = true,
    },
    npc_manhack = {
        PrintName   = "Manhack",
        Category    = "minions",
        Model       = "models/manhack.mdl",
        Icon        = "items/npc_manhack.png",
        Description = "Manhack that rebuilds itself 30 seconds after death. Deals its own damage on impact. Upgrades trade health for damage.",
        Cost        = 900,
        Limit       = 3,
        DeployTime  = 3,
        Health      = 100,
        Damage      = 100,
        FireRate    = "Suicide",
        AmmoMax     = 1,
        DamageType  = "SLASH",
        IsMinion    = true,
        AmmoTracked = false,
        Bonus_Health = -5,
        Bonus_Damage = 20,
    },
    npc_vj_horde_vortigaunt = {
        PrintName   = "Vortigaunt",
        Category    = "minions",
        Model       = "models/vortigaunt.mdl",
        Icon        = "items/npc_vortigaunt.png",
        Description = "Xen Vortigaunt. Conjures concentrated shock energy blasts with splash damage.",
        Cost        = 2750,
        Limit       = 1,
        DeployTime  = 20,
        Health      = 550,
        Damage      = 175,
        FireRate    = 0.57,
        AmmoMax     = 1200,
        DamageType  = "SHOCK",
        IsMinion    = true,
        AmmoTracked = false,
    },
    npc_vj_horde_combat_bot = {
        PrintName   = "Combat Bot",
        Category    = "minions",
        Model       = "models/dog.mdl",
        Icon        = "items/npc_combat_bot.png",
        Description = "Resilient humanoid robot. Engages enemies head-on with powerful melee strikes.",
        Cost        = 3500,
        Limit       = 1,
        DeployTime  = 40,
        Health      = 1400,
        Damage      = 197,
        FireRate    = "Melee",
        AmmoMax     = 6000,
        DamageType  = "CLUB",
        IsMinion    = true,
        AmmoTracked = false,
    },
    horde_engi_dispenser = {
        PrintName   = "Metal Dispenser",
        Category    = "nearby",
        Model       = "models/items/ammocrate_rockets.mdl",
        Icon        = "items/metal_dispenser.png",
        Description = "Passive structure. Periodically resupplies ammo to you and your nearby buildings.",
        Cost        = 500,
        Limit       = 1,
        DeployTime  = 15,
        Health      = 250,
        Damage      = "N/A",
        FireRate    = "Passive",
        AmmoMax     = "N/A",
        DamageType  = "N/A",
        IsMinion    = false,
        AmmoTracked = false,
    },
    horde_aegis_wall = {
        PrintName   = "Aegis Wall",
        Category    = "nearby",
        Model       = "models/hunter/plates/plate2.mdl",
        Icon        = "items/metal_dispenser.png",
        Description = "Passive defensive wall. High health barrier that absorbs damage and blocks the path.",
        Cost        = 1000,
        Limit       = 2,
        DeployTime  = 20,
        Health      = 1500,
        Damage      = "N/A",
        FireRate    = "Passive",
        AmmoMax     = "N/A",
        DamageType  = "N/A",
        IsMinion    = false,
        AmmoTracked = false,
    },
    horde_engi_healing_tower = {
        PrintName   = "Healing Tower",
        Category    = "nearby",
        Model       = "models/props_trainstation/trainstation_ornament002.mdl",
        Icon        = "items/metal_dispenser.png",
        Description = "Passive structure. Every 15s heals nearby constructions by 50 HP and players by 5 HP. Does not heal itself.",
        Cost        = 600,
        Limit       = 1,
        DeployTime  = 15,
        Health      = 300,
        Damage      = "N/A",
        FireRate    = "Passive",
        AmmoMax     = "N/A",
        DamageType  = "N/A",
        IsMinion    = false,
        AmmoTracked = false,
    },
}

HORDE.EngineerBuildableOverrides = HORDE.EngineerBuildableOverrides or {}

HORDE.EngineerBuildableCustom = HORDE.EngineerBuildableCustom or {}

HORDE.EngineerBuildableRemoved = HORDE.EngineerBuildableRemoved or {}

local function GetBaseEntry(class)
    return HORDE.EngineerBuildables[class] or HORDE.EngineerBuildableCustom[class]
end

local function GetField(class, field, fallback)
    local base = GetBaseEntry(class)
    if not base then return fallback end
    local override = HORDE.EngineerBuildableOverrides[class]
    if override and override[field] ~= nil then return override[field] end
    if base[field] ~= nil then return base[field] end
    return fallback
end

function HORDE:Horde_GetBuildableData(class)
    return GetBaseEntry(class)
end

function HORDE:Horde_IsBuildable(class)
    return GetBaseEntry(class) ~= nil and not HORDE.EngineerBuildableRemoved[class]
end

function HORDE:Horde_GetBuildablePrintName(class)
    return GetField(class, "PrintName", class)
end

function HORDE:Horde_GetBuildableCost(class)
    return GetField(class, "Cost", 0)
end

function HORDE:Horde_GetBuildableCostFor(ply, class)
    local cost = self:Horde_GetBuildableCost(class)
    if IsValid(ply) and ply:Horde_GetPerk("engineer_pioneer") then
        local perk = HORDE.perks and HORDE.perks["engineer_pioneer"]
        local discount = (perk and perk.Params and perk.Params[2] and perk.Params[2].value) or 0.02
        cost = cost * (1 - discount)
    end
    return math.floor(cost)
end

function HORDE:Horde_GetBuildableLimit(class)
    return GetField(class, "Limit", 1)
end

function HORDE:Horde_GetBuildableDeployTime(class)
    return GetField(class, "DeployTime", 30)
end

function HORDE:Horde_GetBuildableHealth(class)
    return GetField(class, "Health", 150)
end

function HORDE:Horde_GetBuildableMinLevel(class)
    return GetField(class, "MinLevel", 0)
end

function HORDE:Horde_GetBuildableDamage(class)
    return GetField(class, "Damage", 0)
end

function HORDE:Horde_GetBuildableFireRate(class)
    return GetField(class, "FireRate", 0)
end

function HORDE:Horde_GetBuildableAmmoMax(class)
    return GetField(class, "AmmoMax", 0)
end

function HORDE:Horde_GetBuildableDamageType(class)
    return GetField(class, "DamageType", "?")
end

function HORDE:Horde_GetBuildableDescription(class)
    return GetField(class, "Description", "")
end

HORDE.Turret_EmptySound = "weapons/shotgun/shotgun_empty.wav"

function HORDE:Horde_IsAmmoTrackedBuildable(class)
    return GetField(class, "AmmoTracked", false) == true
end

if SERVER then
    hook.Add("EntityFireBullets", "Horde_TurretAmmoGate", function(ent, bulletdata)
        if not IsValid(ent) then return end
        if not HORDE:Horde_IsAmmoTrackedBuildable(ent:GetClass()) then return end

        local ammo = ent:GetNWInt("Horde_AmmoCurrent", -1)
        if ammo < 0 then return end

        if ammo <= 0 then
            ent:EmitSound(HORDE.Turret_EmptySound, 75, 100)
            return false
        end

        ent:SetNWInt("Horde_AmmoCurrent", math.max(0, ammo - (bulletdata.Num or 1)))
    end)
end

HORDE.Metal_MaxUpgradeLevel = 10

function HORDE:Horde_GetBuildableUpgradePricePercent(class)
    return GetField(class, "UpgradePricePercent", 0.10)
end

function HORDE:Horde_GetBuildableUpgradePriceMoney(class)
    return GetField(class, "UpgradePriceMoney", 250)
end

function HORDE:Horde_GetBuildableUpgradePriceBase(class)
    local cost = HORDE:Horde_GetBuildableCost(class)
    return GetField(class, "UpgradePriceBase", math.max(50, math.floor(cost * 0.05)))
end

function HORDE:Horde_GetBuildableUpgradePriceStep(class)
    local cost = HORDE:Horde_GetBuildableCost(class)
    return GetField(class, "UpgradePriceStep", math.max(5, math.floor(cost * 0.01)))
end

function HORDE:Horde_GetBuildableUpgradePrice(class, level, ply)
    local pct = HORDE:Horde_GetBuildableUpgradePricePercent(class)
    local money = 0
    if IsValid(ply) then
        money = ply:Horde_GetMoney() or 0
    elseif CLIENT and IsValid(MySelf) then
        money = MySelf:Horde_GetMoney() or 0
    end
    return math.max(1, HORDE:Horde_GetBuildableUpgradePriceMoney(class) + math.floor(money * pct))
end

local function DefaultBonusPerLevel(class, field)
    local base = GetBaseEntry(class)
    if base and base[field] ~= nil then
        return tonumber(base[field]) or 0
    end
    if field == "Bonus_Health" then
        return math.floor(HORDE:Horde_GetBuildableHealth(class) * 0.08)
    elseif field == "Bonus_AmmoMax" then
        local ammo = HORDE:Horde_GetBuildableAmmoMax(class)
        return isnumber(ammo) and math.floor(ammo * 0.05) or 0
    elseif field == "Bonus_Damage" then
        local dmg = HORDE:Horde_GetBuildableDamage(class)
        return isnumber(dmg) and math.floor(dmg * 0.1 * 10) / 10 or 0
    elseif field == "Bonus_FireRate" then
        local fr = HORDE:Horde_GetBuildableFireRate(class)
        return isnumber(fr) and math.floor(fr * 0.1 * 100) / 100 or 0
    end
    return 0
end

function HORDE:Horde_GetBuildableBonusAtLevel(class, field, level)
    level = math.Clamp(tonumber(level) or 0, 0, HORDE.Metal_MaxUpgradeLevel or 10)
    if level <= 0 then return 0 end

    local override = HORDE.EngineerBuildableOverrides[class] or {}
    local key5  = "Lvl5_"  .. field
    local key10 = "Lvl10_" .. field

    local has_keyframes = (override[key5] ~= nil) or (override[key10] ~= nil)
    if has_keyframes then
        local v0  = 0
        local v5  = tonumber(override[key5])  or (DefaultBonusPerLevel(class, field) * 5)
        local v10 = tonumber(override[key10]) or (DefaultBonusPerLevel(class, field) * 10)
        if level <= 5 then
            return v0 + (v5 - v0) * (level / 5)
        else
            return v5 + (v10 - v5) * ((level - 5) / 5)
        end
    end

    local per = override[field]
    if per == nil then per = DefaultBonusPerLevel(class, field) end
    return (tonumber(per) or 0) * level
end

function HORDE:Horde_GetBuildableBonus(class, field)
    local override = HORDE.EngineerBuildableOverrides[class]
    if override and override[field] ~= nil then return override[field] end
    return DefaultBonusPerLevel(class, field)
end

function HORDE:Horde_ApplyBuildableUpgradeBonus(ent, class, level)
    if not IsValid(ent) then return end
    level = level or 0

    local base_hp = HORDE:Horde_GetBuildableHealth(class)
    local bonus_hp = self:Horde_GetBuildableBonusAtLevel(class, "Bonus_Health", level)
    local new_max = math.max(1, math.floor(base_hp + bonus_hp))
    local ratio = math.Clamp(ent:Health() / math.max(1, ent:GetMaxHealth()), 0, 1)
    ent:SetMaxHealth(new_max)
    ent:SetHealth(math.max(1, math.floor(new_max * ratio)))

    if self:Horde_IsAmmoTrackedBuildable(class) then
        local base_ammo = HORDE:Horde_GetBuildableAmmoMax(class)
        if isnumber(base_ammo) then
            local bonus_ammo = self:Horde_GetBuildableBonusAtLevel(class, "Bonus_AmmoMax", level)
            local new_ammo_max = math.max(1, math.floor(base_ammo + bonus_ammo))
            ent:SetNWInt("Horde_AmmoMax", new_ammo_max)
        end
    end

    local base_dmg = HORDE:Horde_GetBuildableDamage(class)
    if isnumber(base_dmg) then
        local bonus_dmg = self:Horde_GetBuildableBonus(class, "Bonus_Damage") * level
        ent:SetNWFloat("Horde_UpgradeDamage", base_dmg + bonus_dmg)
    end
end

function HORDE:Horde_GetAllowedInfusions(class)
    local override = HORDE.EngineerBuildableOverrides[class]
    if override and override.InfusionPool and #override.InfusionPool > 0 then
        return override.InfusionPool
    end
    return nil
end

function HORDE:Horde_IsInfusionAllowed(class, infusion)
    local pool = self:Horde_GetAllowedInfusions(class)
    if not pool then return true end
    return table.HasValue(pool, infusion)
end

if SERVER then
    util.AddNetworkString("Horde_RequestBuildableSource")
    util.AddNetworkString("Horde_SyncBuildableSource")
end

function HORDE:Horde_ReadBuildableSource(class)
    if not HORDE:Horde_IsBuildable(class) then return nil, "Unknown buildable class." end

    local folder_path = "gamemodes/horde/entities/entities/" .. class .. "/"
    for _, fname in ipairs({ "init.lua", "shared.lua" }) do
        local content = file.Read(folder_path .. fname, "GAME")
        if content then
            return content, folder_path .. fname
        end
    end

    for _, dir in ipairs({ "entities/entities/", "entities/weapons/" }) do
        local path = "gamemodes/horde/" .. dir .. class .. ".lua"
        local content = file.Read(path, "GAME")
        if content then return content, path end
    end

    return nil, class .. " is a native engine entity — it has no Lua source file of its own."
end

if SERVER then
    net.Receive("Horde_RequestBuildableSource", function(len, ply)
        if not ply:IsSuperAdmin() then return end
        local class = net.ReadString()
        local content, path_or_err = HORDE:Horde_ReadBuildableSource(class)

        net.Start("Horde_SyncBuildableSource")
            net.WriteString(class)
            net.WriteBool(content ~= nil)
            net.WriteString(content or path_or_err)
            net.WriteString(content and path_or_err or "")
        net.Send(ply)
    end)
end

function HORDE:Horde_GetBuildablesByCategory(category)
    local list = {}
    local function Collect(tbl)
        for class, data in pairs(tbl) do
            if not HORDE.EngineerBuildableRemoved[class] then
                local effective_category = GetField(class, "Category", data.Category)
                if effective_category == category then
                    local entry = table.Copy(data)
                    entry.ClassName = class
                    entry.PrintName = self:Horde_GetBuildablePrintName(class)
                    entry.Description = self:Horde_GetBuildableDescription(class)
                    table.insert(list, entry)
                end
            end
        end
    end
    Collect(HORDE.EngineerBuildables)
    Collect(HORDE.EngineerBuildableCustom)
    table.sort(list, function(a, b)
        local ca = HORDE:Horde_GetBuildableCost(a.ClassName) or a.Cost or 0
        local cb = HORDE:Horde_GetBuildableCost(b.ClassName) or b.Cost or 0
        if ca == cb then
            return (a.PrintName or "") < (b.PrintName or "")
        end
        return ca < cb
    end)
    return list
end

if SERVER then
    util.AddNetworkString("Horde_ToggleBuilderConfig")
    util.AddNetworkString("Horde_SetBuilderConfigData")
    util.AddNetworkString("Horde_SyncBuilderConfigData")
    util.AddNetworkString("Horde_AddEngineerBuildable")
    util.AddNetworkString("Horde_RemoveEngineerBuildable")
end

function HORDE:Horde_SaveBuilderConfig()
    if not SERVER then return end
    if not file.IsDir("horde", "DATA") then
        file.CreateDir("horde")
    end
    local payload = {
        Overrides = HORDE.EngineerBuildableOverrides,
        Custom    = HORDE.EngineerBuildableCustom,
        Removed   = HORDE.EngineerBuildableRemoved,
    }
    file.Write("horde/engineer_buildables.txt", util.TableToJSON(payload))
end

function HORDE:Horde_LoadBuilderConfig()
    if not SERVER then return end
    if not file.IsDir("horde", "DATA") then
        file.CreateDir("horde")
        return
    end
    local raw = file.Read("horde/engineer_buildables.txt", "DATA")
    if not raw then return end
    local t = util.JSONToTable(raw)
    if not istable(t) then return end

    if t.Overrides == nil and t.Custom == nil and t.Removed == nil then
        for class, override in pairs(t) do
            if HORDE.EngineerBuildables[class] then
                HORDE.EngineerBuildableOverrides[class] = override
            end
        end
        return
    end

    if istable(t.Custom) then
        for class, data in pairs(t.Custom) do
            HORDE.EngineerBuildableCustom[class] = data
        end
    end
    if istable(t.Removed) then
        for class, v in pairs(t.Removed) do
            if v then HORDE.EngineerBuildableRemoved[class] = true end
        end
    end
    if istable(t.Overrides) then
        for class, override in pairs(t.Overrides) do
            if HORDE.EngineerBuildables[class] or HORDE.EngineerBuildableCustom[class] then
                HORDE.EngineerBuildableOverrides[class] = override
            end
        end
    end
end

function HORDE:Horde_SyncBuilderConfigTo(ply)
    net.Start("Horde_SyncBuilderConfigData")
        net.WriteTable(HORDE.EngineerBuildableOverrides)
        net.WriteTable(HORDE.EngineerBuildableCustom)
        net.WriteTable(HORDE.EngineerBuildableRemoved)
    if IsValid(ply) then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

if SERVER then
    HORDE:Horde_LoadBuilderConfig()

    hook.Add("PlayerInitialSpawn", "Horde_SyncBuilderConfigOnJoin", function(ply)
        HORDE:Horde_SyncBuilderConfigTo(ply)
    end)

    net.Receive("Horde_SetBuilderConfigData", function(len, ply)
        if not ply:IsSuperAdmin() then return end
        if not IsValid(ply) then return end
        local class = net.ReadString()
        local override = HORDE:ReadTableSafe(len)
        if not override then return end
        if not HORDE:Horde_IsBuildable(class) then return end

        HORDE.EngineerBuildableOverrides[class] = override
        HORDE:Horde_SaveBuilderConfig()
        HORDE:Horde_SyncBuilderConfigTo(nil)
        HORDE:SendNotification("Builder config for " .. HORDE:Horde_GetBuildablePrintName(class) .. " saved.", 0, ply)
    end)

    net.Receive("Horde_AddEngineerBuildable", function(len, ply)
        if not ply:IsSuperAdmin() then return end
        if not IsValid(ply) then return end
        local class = net.ReadString()
        local data = HORDE:ReadTableSafe(len)
        if not data then
            HORDE:SendNotification("Buildable rejected: invalid data.", 1, ply)
            return
        end

        class = string.Trim(class or "")
        if class == "" or not string.match(class, "^[%a_][%w_]*$") then
            HORDE:SendNotification("Invalid class name.", 1, ply)
            return
        end
        if HORDE.EngineerBuildables[class] or HORDE.EngineerBuildableCustom[class] then
            HORDE:SendNotification("A buildable with this class name already exists.", 1, ply)
            return
        end

        local category = data.Category
        if category ~= "distant" and category ~= "nearby" and category ~= "minions" then
            category = "distant"
        end

        HORDE.EngineerBuildableCustom[class] = {
            PrintName   = (isstring(data.PrintName) and data.PrintName ~= "") and data.PrintName or class,
            Category    = category,
            Model       = (isstring(data.Model) and data.Model ~= "") and data.Model or "models/combine_turrets/floor_turret.mdl",
            Icon        = (isstring(data.Icon) and data.Icon ~= "") and data.Icon or "items/metal_dispenser.png",
            Description = "",
            Cost        = math.max(0, tonumber(data.Cost) or 500),
            Limit       = math.max(1, math.floor(tonumber(data.Limit) or 1)),
            DeployTime  = math.max(1, tonumber(data.DeployTime) or 15),
            Health      = math.max(1, math.floor(tonumber(data.Health) or 200)),
            Damage      = "N/A",
            FireRate    = "N/A",
            AmmoMax     = "N/A",
            DamageType  = "N/A",
            IsMinion    = category == "minions",
            AmmoTracked = false,
        }
        HORDE.EngineerBuildableRemoved[class] = nil

        HORDE:Horde_SaveBuilderConfig()
        HORDE:Horde_SyncBuilderConfigTo(nil)
        HORDE:SendNotification("Added new buildable: " .. class, 0, ply)
    end)

    net.Receive("Horde_RemoveEngineerBuildable", function(len, ply)
        if not ply:IsSuperAdmin() then return end
        local class = net.ReadString()
        if not HORDE:Horde_IsBuildable(class) then return end

        local name = HORDE:Horde_GetBuildablePrintName(class)
        HORDE.EngineerBuildableRemoved[class] = true

        HORDE:Horde_SaveBuilderConfig()
        HORDE:Horde_SyncBuilderConfigTo(nil)
        HORDE:SendNotification("Removed buildable: " .. name, 0, ply)
    end)
end

if CLIENT then
    net.Receive("Horde_SyncBuilderConfigData", function()
        HORDE.EngineerBuildableOverrides = net.ReadTable() or {}
        HORDE.EngineerBuildableCustom    = net.ReadTable() or {}
        HORDE.EngineerBuildableRemoved   = net.ReadTable() or {}
    end)
end

if SERVER then
    HORDE:Horde_RegisterBuilderSystem("engineer", {
        WeaponClass     = "horde_engiwrench",
        Perk            = "engineer_base",
        SubclassClass   = HORDE.Class_Engineer,
        Currency        = "metal",
        UpgradeCurrency = "money",
        InfusionCurrency = "money",
        MaxUpgradeLevel = HORDE.Metal_MaxUpgradeLevel,
        IsBuildable         = function(class) return HORDE:Horde_IsBuildable(class) end,
        GetPrintName        = function(class) return HORDE:Horde_GetBuildablePrintName(class) end,
        GetCostFor          = function(ply, class) return HORDE:Horde_GetBuildableCostFor(ply, class) end,
        GetLimit            = function(class) return HORDE:Horde_GetBuildableLimit(class) end,
        GetMinLevel         = function(class) return HORDE:Horde_GetBuildableMinLevel(class) end,
        GetUpgradePrice     = function(class, level, ply) return HORDE:Horde_GetBuildableUpgradePrice(class, level, ply) end,
        ApplyUpgradeBonus   = function(ent, class, level) HORDE:Horde_ApplyBuildableUpgradeBonus(ent, class, level) end,
        GetInfusionPrice    = function(class) return math.floor(100 + HORDE:Horde_GetBuildableCost(class) / 5) end,
        IsInfusionAllowed   = function(class, infusion) return HORDE:Horde_IsInfusionAllowed(class, infusion) end,
    })
end
