HORDE.WardenBuildables = {

    horde_watchtower = {
        PrintName   = "Ammo Watchtower",
        Category    = "support",
        Model       = "models/props_combine/combine_light001a.mdl",
        Icon        = "items/horde_watchtower.png",
        Description = "A watchtower that provides resupply.\nGenerates 1 ammobox every 30 seconds.",
        Cost        = 800,
        Limit       = 2,
        DeployTime  = 15,
        ConsumableType   = "lifetime",
        Lifetime         = 300,
        IsMinion    = false,
    },
    horde_watchtower_mk2 = {
        PrintName   = "Medical Watchtower",
        Category    = "support",
        Model       = "models/props_combine/combine_light001a.mdl",
        Icon        = "items/horde_watchtower.png",
        Description = "A watchtower that provides resupply.\nGenerates 1 health vial every 30 seconds.",
        Cost        = 1000,
        Limit       = 2,
        DeployTime  = 15,
        ConsumableType   = "lifetime",
        Lifetime         = 300,
        IsMinion    = false,
    },
    horde_watchtower_guardian = {
        PrintName   = "Guardian Watchtower",
        Category    = "support",
        Model       = "models/props_combine/combine_light001a.mdl",
        Icon        = "items/horde_watchtower.png",
        Description = "A watchtower that provides armor regeneration in an area.\nArmor regeneration does not stack with itself.",
        Cost        = 2000,
        Limit       = 1,
        DeployTime  = 20,
        ConsumableType   = "lifetime",
        Lifetime         = 360,
        IsMinion    = false,
    },
    horde_watchtower_beacon = {
        PrintName   = "Beacon Watchtower",
        Category    = "support",
        Model       = "models/props_combine/combine_light001b.mdl",
        Icon        = "items/horde_watchtower.png",
        Description = "Personal respawn point for the owner only.\nRespawns the owner on death, then destroys itself.",
        Cost        = 3000,
        Limit       = 1,
        DeployTime  = 30,
        ConsumableType   = "wave_limited",
        IsMinion    = false,
    },
    horde_watchtower_mk9 = {
        PrintName   = "Vitality Watchtower",
        Category    = "support",
        Model       = "models/props_combine/combine_light001a.mdl",
        Icon        = "items/horde_watchtower.png",
        Description = "A watchtower that periodically heals the nearest injured ally.\nHeals 20 HP per pulse.",
        Cost        = 1800,
        Limit       = 1,
        DeployTime  = 20,
        ConsumableType   = "lifetime",
        Lifetime         = 300,
        IsMinion    = false,
    },
    horde_watchtower_mk10 = {
        PrintName   = "Aegis Watchtower",
        Category    = "support",
        Model       = "models/props_combine/combine_light001a.mdl",
        Icon        = "items/horde_watchtower.png",
        Description = "A watchtower that continuously regenerates armor for the nearest ally.\n+1 Armor every 0.125s.",
        Cost        = 1800,
        Limit       = 1,
        DeployTime  = 20,
        ConsumableType   = "lifetime",
        Lifetime         = 300,
        IsMinion    = false,
    },
    horde_watchtower_mk11 = {
        PrintName   = "Cleansing Watchtower",
        Category    = "support",
        Model       = "models/props_combine/combine_light001a.mdl",
        Icon        = "items/horde_watchtower.png",
        Description = "A watchtower that heals the nearest injured ally and cleanses their debuffs.\nHeals 10 HP per pulse.",
        Cost        = 2200,
        Limit       = 1,
        DeployTime  = 25,
        ConsumableType   = "lifetime",
        Lifetime         = 300,
        IsMinion    = false,
    },

    horde_watchtower_mk3 = {
        PrintName   = "Watchtower MKIII",
        Category    = "defense",
        Model       = "models/props_combine/combine_light001a.mdl",
        Icon        = "items/horde_watchtower.png",
        Description = "A watchtower that deters enemies.\nShocks 1 nearby enemy every 1 second.",
        Cost        = 1500,
        Limit       = 2,
        DeployTime  = 30,
        ConsumableType   = "damage_charges",
        DamageCharges    = 60,
        Damage      = 100,
        FireRate    = 1,
        DamageType  = "SHOCK",
        IsMinion    = false,
    },
    horde_watchtower_interceptor = {
        PrintName   = "Interceptor Watchtower",
        Category    = "defense",
        Model       = "models/props_combine/combine_light001a.mdl",
        Icon        = "items/horde_watchtower.png",
        Description = "Fires laser beams to nearby watchtowers.\nEach linked tower grants 1 free charge per volley.\n1200 charges (2600 at max upgrade).",
        Cost        = 2000,
        Limit       = 1,
        DeployTime  = 30,
        ConsumableType   = "damage_charges",
        DamageCharges    = 1200,
        Bonus_DamageCharges = 140,
        Damage      = 5,
        FireRate    = 10,
        DamageType  = "BLAST",
        IsMinion    = false,
    },
    horde_watchtower_mk4 = {
        PrintName   = "Detonator Watchtower",
        Category    = "defense",
        Model       = "models/props_combine/combine_light001a.mdl",
        Icon        = "items/horde_watchtower.png",
        Description = "An unstable watchtower that periodically detonates, dealing Shock damage in an area.",
        Cost        = 1600,
        Limit       = 1,
        DeployTime  = 30,
        ConsumableType   = "damage_charges",
        DamageCharges    = 40,
        Damage      = 50,
        FireRate    = 0.5,
        DamageType  = "SHOCK",
        IsMinion    = false,
    },
    horde_watchtower_mk5 = {
        PrintName   = "Incinerator Watchtower",
        Category    = "defense",
        Model       = "models/props_combine/combine_light001a.mdl",
        Icon        = "items/horde_watchtower.png",
        Description = "A watchtower that periodically erupts in flame, dealing Burn damage in an area.",
        Cost        = 1700,
        Limit       = 1,
        DeployTime  = 30,
        ConsumableType   = "damage_charges",
        DamageCharges    = 40,
        Damage      = 80,
        FireRate    = 0.5,
        DamageType  = "BURN",
        IsMinion    = false,
    },
    horde_watchtower_mk6 = {
        PrintName   = "Toxin Watchtower",
        Category    = "defense",
        Model       = "models/props_combine/combine_light001a.mdl",
        Icon        = "items/horde_watchtower.png",
        Description = "A watchtower that periodically releases a corrosive gas cloud, dealing Nerve damage in an area.",
        Cost        = 1400,
        Limit       = 2,
        DeployTime  = 25,
        ConsumableType   = "damage_charges",
        DamageCharges    = 100,
        Damage      = 20,
        FireRate    = 2,
        DamageType  = "NERVEGAS",
        IsMinion    = false,
    },
    horde_watchtower_mk7 = {
        PrintName   = "Cryo Watchtower",
        Category    = "defense",
        Model       = "models/props_combine/combine_light001a.mdl",
        Icon        = "items/horde_watchtower.png",
        Description = "A watchtower that periodically fires a freezing beam at the nearest enemy.",
        Cost        = 2200,
        Limit       = 1,
        DeployTime  = 35,
        ConsumableType   = "damage_charges",
        DamageCharges    = 30,
        Damage      = 250,
        FireRate    = 0.5,
        DamageType  = "COLD",
        IsMinion    = false,
    },
    horde_watchtower_mk8 = {
        PrintName   = "Artillery Watchtower",
        Category    = "defense",
        Model       = "models/props_combine/combine_light001a.mdl",
        Icon        = "items/horde_watchtower.png",
        Description = "A watchtower that periodically fires a heavy explosive shell, dealing massive Blast damage in an area.",
        Cost        = 2800,
        Limit       = 1,
        DeployTime  = 40,
        ConsumableType   = "damage_charges",
        DamageCharges    = 20,
        Damage      = 350,
        FireRate    = 0.25,
        DamageType  = "BLAST",
        IsMinion    = false,
    },
    horde_watchtower_prototype = {
        PrintName   = "Prototype Watchtower",
        Category    = "defense",
        Model       = "models/props_combine/combine_light001a.mdl",
        Icon        = "items/horde_watchtower.png",
        Description = "An experimental watchtower armed with an automated rifle, firing at nearby enemies.",
        Cost        = 1200,
        Limit       = 2,
        DeployTime  = 20,
        ConsumableType   = "damage_charges",
        DamageCharges    = 200,
        Damage      = 25,
        FireRate    = 5,
        DamageType  = "BALLISTIC",
        IsMinion    = false,
    }
}

HORDE.WardenBuildableOverrides = HORDE.WardenBuildableOverrides or {}
HORDE.WardenBuildableCustom    = HORDE.WardenBuildableCustom or {}
HORDE.WardenBuildableRemoved   = HORDE.WardenBuildableRemoved or {}

local function GetBaseEntry(class)
    return HORDE.WardenBuildables[class] or HORDE.WardenBuildableCustom[class]
end

local function GetField(class, field, fallback)
    local base = GetBaseEntry(class)
    if not base then return fallback end
    local override = HORDE.WardenBuildableOverrides[class]
    if override and override[field] ~= nil then return override[field] end
    if base[field] ~= nil then return base[field] end
    return fallback
end

function HORDE:Horde_GetWardenBuildableData(class)
    return GetBaseEntry(class)
end

function HORDE:Horde_IsWardenBuildable(class)
    return GetBaseEntry(class) ~= nil and not HORDE.WardenBuildableRemoved[class]
end

function HORDE:Horde_GetWardenBuildablePrintName(class)
    return GetField(class, "PrintName", class)
end

function HORDE:Horde_GetWardenBuildableCost(class)
    return GetField(class, "Cost", 0)
end

function HORDE:Horde_GetWardenBuildableCostFor(ply, class)
    local cost = self:Horde_GetWardenBuildableCost(class)
    return math.floor(cost)
end

function HORDE:Horde_GetWardenBuildableLimit(class)
    return GetField(class, "Limit", 1)
end

function HORDE:Horde_GetWardenBuildableDeployTime(class)
    return GetField(class, "DeployTime", 30)
end

function HORDE:Horde_GetWardenBuildableMinLevel(class)
    return 0
end

function HORDE:Horde_GetWardenBuildableDamage(class)
    return GetField(class, "Damage", "N/A")
end

function HORDE:Horde_GetWardenBuildableCurrentDamage(class, ply)
    local base = self:Horde_GetWardenBuildableDamage(class)
    if not isnumber(base) then return base end
    if not IsValid(ply) or not ply.Horde_GetUpgrade then return base end

    local level = ply:Horde_GetUpgrade(class)
    local bonus = self:Horde_GetWardenBuildableBonusAtLevel(class, "Bonus_Damage", level)
    return math.floor(base + bonus)
end

function HORDE:Horde_GetWardenBuildableFireRate(class)
    return GetField(class, "FireRate", "N/A")
end

function HORDE:Horde_GetWardenBuildableCurrentFireRate(class, ply)
    local base = self:Horde_GetWardenBuildableFireRate(class)
    if not isnumber(base) then return base end
    if not IsValid(ply) or not ply.Horde_GetUpgrade then return base end

    local level = ply:Horde_GetUpgrade(class)
    local bonus = self:Horde_GetWardenBuildableBonusAtLevel(class, "Bonus_FireRate", level)
    return base + bonus
end

function HORDE:Horde_GetWardenBuildableCurrentAttackDelay(class, ply)
    local rate = self:Horde_GetWardenBuildableCurrentFireRate(class, ply)
    if not isnumber(rate) or rate <= 0 then return nil end
    return 1 / rate
end

function HORDE:Horde_GetWardenBuildableDamageType(class)
    return GetField(class, "DamageType", "N/A")
end

function HORDE:Horde_GetWardenBuildableDescription(class)
    return GetField(class, "Description", "")
end

function HORDE:Horde_GetWardenBuildableConsumableType(class)
    return GetField(class, "ConsumableType", "lifetime")
end

function HORDE:Horde_GetWardenBuildableLifetime(class)
    return GetField(class, "Lifetime", 300)
end

function HORDE:Horde_GetWardenBuildableDamageCharges(class)
    return GetField(class, "DamageCharges", 50)
end

function HORDE:Horde_GetWardenBuildablesByCategory(category)
    local list = {}
    local function Collect(tbl)
        for class, data in pairs(tbl) do
            if not HORDE.WardenBuildableRemoved[class] then
                local effective_category = GetField(class, "Category", data.Category)
                if effective_category == category then
                    local entry = table.Copy(data)
                    entry.ClassName = class
                    entry.PrintName = self:Horde_GetWardenBuildablePrintName(class)
                    entry.Description = self:Horde_GetWardenBuildableDescription(class)
                    table.insert(list, entry)
                end
            end
        end
    end
    Collect(HORDE.WardenBuildables)
    Collect(HORDE.WardenBuildableCustom)
    table.sort(list, function(a, b)
        local ca = HORDE:Horde_GetWardenBuildableCost(a.ClassName) or a.Cost or 0
        local cb = HORDE:Horde_GetWardenBuildableCost(b.ClassName) or b.Cost or 0
        if ca == cb then
            return (a.PrintName or "") < (b.PrintName or "")
        end
        return ca < cb
    end)
    return list
end

HORDE.Warden_MaxUpgradeLevel = 10

HORDE.WardenGhostRender = {
    material_path = "models/wireframe",
    blend         = 0.25,
    color_default = { 1, 1, 1 },
    color_ghost   = { 0.4, 0.6, 1 },
}

HORDE.WardenBuildableColors = {
    horde_watchtower_beacon      = Color(0, 255, 0),
    horde_watchtower_guardian    = Color(0, 150, 255),
    horde_watchtower_interceptor = Color(255, 150, 0),
    horde_watchtower_mk3         = Color(0, 150, 255),
    horde_watchtower_mk4         = Color(180, 100, 255),
    horde_watchtower_mk5         = Color(125, 50, 50),
    horde_watchtower_mk6         = Color(164, 0, 164),
    horde_watchtower_mk7         = Color(68, 85, 90),
    horde_watchtower_mk8         = Color(128, 64, 0),
    horde_watchtower_mk9         = Color(0, 100, 0),
    horde_watchtower_mk10        = Color(0, 80, 181),
    horde_watchtower_mk11        = Color(255, 0, 0),
    horde_watchtower_prototype   = Color(0, 0, 0),
}

function HORDE:Horde_GetWardenBuildablePreviewColor(class)
    local c = HORDE.WardenBuildableColors and HORDE.WardenBuildableColors[class]
    if c then
        return { c.r / 255, c.g / 255, c.b / 255 }
    end
    local cfg = HORDE.WardenGhostRender
    return (cfg and cfg.color_default) or { 1, 1, 1 }
end

function HORDE:Horde_GetWardenBuildableUpgradePricePercent(class)
    return GetField(class, "UpgradePricePercent", 0.10)
end

function HORDE:Horde_GetWardenBuildableUpgradePrice(class, level, ply)
    local pct = HORDE:Horde_GetWardenBuildableUpgradePricePercent(class)
    local money = 0
    if IsValid(ply) then
        money = ply:Horde_GetMoney() or 0
    elseif CLIENT and IsValid(MySelf) then
        money = MySelf:Horde_GetMoney() or 0
    end
    return math.max(1, math.floor(money * pct))
end

HORDE.Warden_UpgradeDamagePercentPerLevel = 0.05
HORDE.Warden_UpgradeFireRatePercentPerLevel = 0.05

local function DefaultBonusPerLevel(class, field)
    if field == "Bonus_Lifetime" then
        return math.floor(HORDE:Horde_GetWardenBuildableLifetime(class) * 0.08)
    elseif field == "Bonus_DamageCharges" then
        return math.floor(HORDE:Horde_GetWardenBuildableDamageCharges(class) * 0.08)
    elseif field == "Bonus_Damage" then
        local base_dmg = HORDE:Horde_GetWardenBuildableDamage(class)
        if not isnumber(base_dmg) then return 0 end
        return base_dmg * HORDE.Warden_UpgradeDamagePercentPerLevel
    elseif field == "Bonus_FireRate" then
        local base_rate = HORDE:Horde_GetWardenBuildableFireRate(class)
        if not isnumber(base_rate) then return 0 end
        return base_rate * HORDE.Warden_UpgradeFireRatePercentPerLevel
    end
    return 0
end

function HORDE:Horde_GetWardenBuildableBonusAtLevel(class, field, level)
    level = math.Clamp(tonumber(level) or 0, 0, HORDE.Warden_MaxUpgradeLevel or 10)
    if level <= 0 then return 0 end

    local override = HORDE.WardenBuildableOverrides[class] or {}
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
    if per == nil then
        local base = GetBaseEntry(class)
        if base and base[field] ~= nil then
            per = base[field]
        end
    end
    if per == nil then per = DefaultBonusPerLevel(class, field) end
    return (tonumber(per) or 0) * level
end

function HORDE:Horde_ApplyWardenBuildableUpgradeBonus(ent, class, level)
    if not SERVER then return end
    if not IsValid(ent) then return end
    level = level or 0

    local ctype = self:Horde_GetWardenBuildableConsumableType(class)
    if ctype == "lifetime" then
        local base_life = self:Horde_GetWardenBuildableLifetime(class)
        local bonus_life = self:Horde_GetWardenBuildableBonusAtLevel(class, "Bonus_Lifetime", level)
        local new_max = math.max(1, math.floor(base_life + bonus_life))

        ent.Horde_ConsumableMax = new_max
        ent.Horde_ConsumableRemaining = new_max
        ent.Horde_ConsumableSpawnTime = CurTime()
    elseif ctype == "damage_charges" then
        local base_charges = self:Horde_GetWardenBuildableDamageCharges(class)
        local bonus_charges = self:Horde_GetWardenBuildableBonusAtLevel(class, "Bonus_DamageCharges", level)
        local new_max = math.max(1, math.floor(base_charges + bonus_charges))

        ent.Horde_ConsumableMax = new_max
        ent.Horde_ConsumableRemaining = new_max
    end

    if ent.Horde_SyncConsumableToClients then
        ent:Horde_SyncConsumableToClients()
    end
end

function HORDE:Horde_GetWardenAllowedInfusions(class)
    local override = HORDE.WardenBuildableOverrides[class]
    if override and override.InfusionPool and #override.InfusionPool > 0 then
        return override.InfusionPool
    end
    return nil
end

function HORDE:Horde_IsWardenInfusionAllowed(class, infusion)
    local pool = self:Horde_GetWardenAllowedInfusions(class)
    if not pool then return true end
    return table.HasValue(pool, infusion)
end

if SERVER then

local entmeta = FindMetaTable("Entity")

function entmeta:Horde_SyncConsumableToClients()
    if not IsValid(self) then return end
    self:SetNWString("Horde_ConsumableType", self.Horde_ConsumableType or "")
    self:SetNWFloat("Horde_ConsumableMax", self.Horde_ConsumableMax or 0)
    self:SetNWFloat("Horde_ConsumableRemaining", self.Horde_ConsumableRemaining or 0)
    self:SetNWFloat("Horde_ConsumableSpawnTime", self.Horde_ConsumableSpawnTime or 0)
end

function HORDE:Horde_IsWatchtowerConsumableTicking()
    if not HORDE.start_game then return false end
    if (HORDE.current_break_time or 0) > 0 then return false end
    if SERVER and HORDE.InBreak and HORDE:InBreak() then return false end
    return true
end

function entmeta:Horde_AttachConsumableLifecycle(class, carry_ratio)
    if not IsValid(self) then return end
    self.Horde_BuiltClass = class
    self.Horde_WatchTower = true

    local ctype = HORDE:Horde_GetWardenBuildableConsumableType(class)
    self.Horde_ConsumableType = ctype

    local ply = self.Horde_Owner
    local level = (IsValid(ply) and ply:IsPlayer()) and ply:Horde_GetUpgrade(class) or 0

    carry_ratio = tonumber(carry_ratio)
    if carry_ratio then carry_ratio = math.Clamp(carry_ratio, 0, 1) end

    if ctype == "lifetime" then
        local base_life = HORDE:Horde_GetWardenBuildableLifetime(class)
        local bonus = HORDE:Horde_GetWardenBuildableBonusAtLevel(class, "Bonus_Lifetime", level)
        self.Horde_ConsumableMax = math.max(1, math.floor(base_life + bonus))
        if carry_ratio then
            self.Horde_ConsumableRemaining = math.max(1, math.floor(self.Horde_ConsumableMax * carry_ratio))
        else
            self.Horde_ConsumableRemaining = self.Horde_ConsumableMax
        end
        self.Horde_ConsumableSpawnTime = CurTime()

        local id = "Horde_WardenLifetime_" .. self:EntIndex()
        timer.Create(id, 1, 0, function()
            if not IsValid(self) then
                if timer.Exists(id) then timer.Remove(id) end
                return
            end
            if self.Horde_Expiring then return end
            if not HORDE:Horde_IsWatchtowerConsumableTicking() then return end

            self.Horde_ConsumableRemaining = math.max(0, (self.Horde_ConsumableRemaining or 0) - 1)
            self:SetNWFloat("Horde_ConsumableRemaining", self.Horde_ConsumableRemaining)
            if self.Horde_ConsumableRemaining <= 0 then
                self:Horde_ExpireConsumable()
            end
        end)
        self:CallOnRemove("Horde_WardenLifetimeCleanup", function()
            if timer.Exists(id) then timer.Remove(id) end
        end)

    elseif ctype == "damage_charges" then
        local base_charges = HORDE:Horde_GetWardenBuildableDamageCharges(class)
        local bonus = HORDE:Horde_GetWardenBuildableBonusAtLevel(class, "Bonus_DamageCharges", level)
        self.Horde_ConsumableMax = math.max(1, math.floor(base_charges + bonus))
        self.Horde_ConsumableRemaining = carry_ratio
            and math.max(1, math.floor(self.Horde_ConsumableMax * carry_ratio))
            or self.Horde_ConsumableMax

        if not self.Horde_ConsumableThinkWrapped then
            self.Horde_ConsumableThinkWrapped = true
            local oldThink = self.Think
            local id = "Horde_WardenChargeThink_" .. self:EntIndex()
            timer.Create(id, 0.1, 0, function()
                if not IsValid(self) then
                    if timer.Exists(id) then timer.Remove(id) end
                    return
                end
                if self.Horde_Expiring then return end
                if not HORDE:Horde_IsWatchtowerConsumableTicking() then return end
                if oldThink then
                    oldThink(self)
                end
            end)
            self:CallOnRemove("Horde_WardenChargeThinkCleanup", function()
                if timer.Exists(id) then timer.Remove(id) end
            end)
            self.Think = function(s)
                if IsValid(s) then s:NextThink(CurTime() + 1) end
                return true
            end
            self:NextThink(CurTime() + 1)
        end

    elseif ctype == "wave_limited" then
        self.Horde_ConsumableMax = 1
        self.Horde_ConsumableRemaining = 1
        self.Horde_BuiltOnWave = HORDE.current_wave or 0

        local hook_id = "Horde_WardenWaveLimited_" .. self:EntIndex()
        hook.Add("HordeWaveStart", hook_id, function(wave)
            if not IsValid(self) then
                hook.Remove("HordeWaveStart", hook_id)
                return
            end
            if wave ~= self.Horde_BuiltOnWave then
                self:Horde_ExpireConsumable()
            end
        end)
        self:CallOnRemove("Horde_WardenWaveLimitedCleanup", function()
            hook.Remove("HordeWaveStart", hook_id)
        end)
    end

    self:Horde_SyncConsumableToClients()
end

function entmeta:Horde_ConsumeCharge(amount)
    if not IsValid(self) then return end
    if self.Horde_ConsumableType ~= "damage_charges" then return end
    if self.Horde_ConsumableRemaining == nil then return end
    if self.Horde_Expiring then return end
    if not HORDE:Horde_IsWatchtowerConsumableTicking() then return end

    amount = tonumber(amount) or 1
    if amount <= 0 then return end

    self.Horde_ConsumableRemaining = math.max(0, (self.Horde_ConsumableRemaining or 0) - amount)
    self:SetNWFloat("Horde_ConsumableRemaining", self.Horde_ConsumableRemaining)
    self._Horde_ChargeDebounce = CurTime()
    if self.Horde_ConsumableRemaining <= 0 then
        self:Horde_ExpireConsumable()
    end
end

hook.Add("PostEntityTakeDamage", "Horde_WardenChargeOnDamage", function(target, dmginfo, took)
    if not took then return end
    if not HORDE:Horde_IsWatchtowerConsumableTicking() then return end
    if not IsValid(target) or not target:IsNPC() then return end
    if HORDE.IsPlayerMinion and HORDE:IsPlayerMinion(target) then return end

    local inf = dmginfo:GetInflictor()
    if not IsValid(inf) then
        inf = dmginfo:GetAttacker()
    end
    if not IsValid(inf) then return end
    if inf.Horde_ConsumableType ~= "damage_charges" then return end
    local cls = inf:GetClass() or ""
    if not string.StartWith(cls, "horde_watchtower") then return end

    local now = CurTime()
    if inf._Horde_ChargeDebounce and (now - inf._Horde_ChargeDebounce) < 0.2 then
        return
    end
    inf._Horde_ChargeDebounce = now
    if inf.Horde_ConsumeCharge then
        inf:Horde_ConsumeCharge(1)
    end
end)

function entmeta:Horde_ExpireConsumable()
    if not IsValid(self) then return end
    if self.Horde_Expiring then return end
    self.Horde_Expiring = true

    local pos = self:WorldSpaceCenter()

    local ed = EffectData()
    ed:SetOrigin(self:GetPos())
    ed:SetEntity(self)
    util.Effect("entity_remove", ed, true, true)

    local smoke = EffectData()
    smoke:SetOrigin(pos)
    smoke:SetScale(0.6)
    util.Effect("horde_warden_expire_smoke", smoke, true, true)

    sound.Play("weapons/streamer/dry.wav", self:GetPos(), 70, 100)
    sound.Play("ambient/steam/steam_hiss1.wav", self:GetPos(), 65, 130)

    self:Remove()
end

function entmeta:Horde_GetConsumableRatio()
    if not IsValid(self) or not self.Horde_ConsumableMax or self.Horde_ConsumableMax <= 0 then return 1 end
    return math.Clamp((self.Horde_ConsumableRemaining or 0) / self.Horde_ConsumableMax, 0, 1)
end

end

if SERVER then
    util.AddNetworkString("Horde_ToggleWardenConfig")
    util.AddNetworkString("Horde_SetWardenConfigData")
    util.AddNetworkString("Horde_SyncWardenConfigData")
    util.AddNetworkString("Horde_AddWardenBuildable")
    util.AddNetworkString("Horde_RemoveWardenBuildable")
end

function HORDE:Horde_SaveWardenConfig()
    if not SERVER then return end
    if not file.IsDir("horde", "DATA") then
        file.CreateDir("horde")
    end
    local payload = {
        Overrides = HORDE.WardenBuildableOverrides,
        Custom    = HORDE.WardenBuildableCustom,
        Removed   = HORDE.WardenBuildableRemoved,
    }
    file.Write("horde/warden_buildables.txt", util.TableToJSON(payload))
end

function HORDE:Horde_LoadWardenConfig()
    if not SERVER then return end
    if not file.IsDir("horde", "DATA") then
        file.CreateDir("horde")
        return
    end
    local raw = file.Read("horde/warden_buildables.txt", "DATA")
    if not raw then return end
    local t = util.JSONToTable(raw)
    if not istable(t) then return end

    if istable(t.Custom) then
        for class, data in pairs(t.Custom) do
            HORDE.WardenBuildableCustom[class] = data
        end
    end
    if istable(t.Removed) then
        for class, v in pairs(t.Removed) do
            if v then HORDE.WardenBuildableRemoved[class] = true end
        end
    end
    if istable(t.Overrides) then
        for class, override in pairs(t.Overrides) do
            if HORDE.WardenBuildables[class] or HORDE.WardenBuildableCustom[class] then
                HORDE.WardenBuildableOverrides[class] = override
            end
        end
    end
end

function HORDE:Horde_SyncWardenConfigTo(ply)
    net.Start("Horde_SyncWardenConfigData")
        net.WriteTable(HORDE.WardenBuildableOverrides)
        net.WriteTable(HORDE.WardenBuildableCustom)
        net.WriteTable(HORDE.WardenBuildableRemoved)
    if IsValid(ply) then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

if SERVER then
    HORDE:Horde_LoadWardenConfig()

    hook.Add("PlayerInitialSpawn", "Horde_SyncWardenConfigOnJoin", function(ply)
        HORDE:Horde_SyncWardenConfigTo(ply)
    end)

    net.Receive("Horde_SetWardenConfigData", function(len, ply)
        if not ply:IsSuperAdmin() then return end
        if not IsValid(ply) then return end
        local class = net.ReadString()
        local override = HORDE:ReadTableSafe(len)
        if not override then return end
        if not HORDE:Horde_IsWardenBuildable(class) then return end

        HORDE.WardenBuildableOverrides[class] = override
        HORDE:Horde_SaveWardenConfig()
        HORDE:Horde_SyncWardenConfigTo(nil)
        HORDE:SendNotification("Warden config for " .. HORDE:Horde_GetWardenBuildablePrintName(class) .. " saved.", 0, ply)
    end)

    net.Receive("Horde_AddWardenBuildable", function(len, ply)
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
        if HORDE.WardenBuildables[class] or HORDE.WardenBuildableCustom[class] then
            HORDE:SendNotification("A buildable with this class name already exists.", 1, ply)
            return
        end

        local category = data.Category
        if category ~= "defense" and category ~= "support" then
            category = "support"
        end

        local ctype = data.ConsumableType
        if ctype ~= "lifetime" and ctype ~= "damage_charges" and ctype ~= "wave_limited" then
            ctype = category == "defense" and "damage_charges" or "lifetime"
        end

        HORDE.WardenBuildableCustom[class] = {
            PrintName   = (isstring(data.PrintName) and data.PrintName ~= "") and data.PrintName or class,
            Category    = category,
            Model       = (isstring(data.Model) and data.Model ~= "") and data.Model or "models/props_combine/combine_light001a.mdl",
            Icon        = (isstring(data.Icon) and data.Icon ~= "") and data.Icon or "items/horde_watchtower.png",
            Description = "",
            Cost        = math.max(0, tonumber(data.Cost) or 1000),
            Limit       = math.max(1, math.floor(tonumber(data.Limit) or 1)),
            DeployTime  = math.max(1, tonumber(data.DeployTime) or 20),
            ConsumableType   = ctype,
            Lifetime         = math.max(1, math.floor(tonumber(data.Lifetime) or 300)),
            DamageCharges    = math.max(1, math.floor(tonumber(data.DamageCharges) or 50)),
            Damage      = category == "defense" and (tonumber(data.Damage) or 50) or "N/A",
            FireRate    = category == "defense" and (tonumber(data.FireRate) or 1) or "N/A",
            DamageType  = category == "defense" and ((isstring(data.DamageType) and data.DamageType ~= "") and data.DamageType or "BULLET") or "N/A",
            IsMinion    = false,
        }
        HORDE.WardenBuildableRemoved[class] = nil

        HORDE:Horde_SaveWardenConfig()
        HORDE:Horde_SyncWardenConfigTo(nil)
        HORDE:SendNotification("Added new Warden buildable: " .. class, 0, ply)
    end)

    net.Receive("Horde_RemoveWardenBuildable", function(len, ply)
        if not ply:IsSuperAdmin() then return end
        local class = net.ReadString()
        if not HORDE:Horde_IsWardenBuildable(class) then return end

        local name = HORDE:Horde_GetWardenBuildablePrintName(class)
        HORDE.WardenBuildableRemoved[class] = true

        HORDE:Horde_SaveWardenConfig()
        HORDE:Horde_SyncWardenConfigTo(nil)
        HORDE:SendNotification("Removed Warden buildable: " .. name, 0, ply)
    end)
end

if CLIENT then
    net.Receive("Horde_SyncWardenConfigData", function()
        HORDE.WardenBuildableOverrides = net.ReadTable() or {}
        HORDE.WardenBuildableCustom    = net.ReadTable() or {}
        HORDE.WardenBuildableRemoved   = net.ReadTable() or {}
    end)
end

function HORDE:Horde_GetWardenBuildableBonus(class, field)
    local override = HORDE.WardenBuildableOverrides[class]
    if override and override[field] ~= nil then return override[field] end
    return DefaultBonusPerLevel(class, field)
end

if SERVER then
    util.AddNetworkString("Horde_RequestWardenBuildableSource")
    util.AddNetworkString("Horde_SyncWardenBuildableSource")
end

function HORDE:Horde_ReadWardenBuildableSource(class)
    if not HORDE:Horde_IsWardenBuildable(class) then return nil, "Unknown buildable class." end

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
    net.Receive("Horde_RequestWardenBuildableSource", function(len, ply)
        if not ply:IsSuperAdmin() then return end
        local class = net.ReadString()
        local content, path_or_err = HORDE:Horde_ReadWardenBuildableSource(class)

        net.Start("Horde_SyncWardenBuildableSource")
            net.WriteString(class)
            net.WriteBool(content ~= nil)
            net.WriteString(content or path_or_err)
            net.WriteString(content and path_or_err or "")
        net.Send(ply)
    end)
end

if SERVER then
    HORDE:Horde_RegisterBuilderSystem("warden", {
        WeaponClass     = "horde_wardenstaff",
        Perk            = "warden_base",
        SubclassClass   = HORDE.Class_Warden,
        Currency        = "money",
        MaxUpgradeLevel = HORDE.Warden_MaxUpgradeLevel,
        IsBuildable         = function(class) return HORDE:Horde_IsWardenBuildable(class) end,
        GetPrintName        = function(class) return HORDE:Horde_GetWardenBuildablePrintName(class) end,
        GetCostFor          = function(ply, class) return HORDE:Horde_GetWardenBuildableCostFor(ply, class) end,
        GetLimit            = function(class) return HORDE:Horde_GetWardenBuildableLimit(class) end,
        GetMinLevel         = function(class) return HORDE:Horde_GetWardenBuildableMinLevel(class) end,
        GetUpgradePrice     = function(class, level, ply) return HORDE:Horde_GetWardenBuildableUpgradePrice(class, level, ply) end,
        ApplyUpgradeBonus   = function(ent, class, level) HORDE:Horde_ApplyWardenBuildableUpgradeBonus(ent, class, level) end,
        GetInfusionPrice    = function(class) return math.floor(100 + HORDE:Horde_GetWardenBuildableCost(class) / 5) end,
        IsInfusionAllowed   = function(class, infusion) return HORDE:Horde_IsWardenInfusionAllowed(class, infusion) end,
    })
end
