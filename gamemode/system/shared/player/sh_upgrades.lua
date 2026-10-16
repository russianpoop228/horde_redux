HORDE.UpgradeSystems = HORDE.UpgradeSystems or {}
HORDE.UpgradeSystemOrder = HORDE.UpgradeSystemOrder or {}

HORDE.Item_MaxUpgradeLevel = HORDE.Item_MaxUpgradeLevel or 10

function HORDE:RegisterUpgradeSystem(def)
    if not istable(def) then return end
    local name = def.name
    if not isstring(name) or name == "" then
        ErrorNoHalt("[Horde Upgrades] Система без поля name не зарегистрирована\n")
        return
    end
    for _, field in ipairs({ "Get", "Set", "MaxLevel" }) do
        if not isfunction(def[field]) then
            ErrorNoHalt("[Horde Upgrades] Система '" .. name .. "': поле '" .. field .. "' должно быть функцией\n")
            return
        end
    end

    def.AutoMax = def.AutoMax ~= false
    if not HORDE.UpgradeSystems[name] then
        table.insert(HORDE.UpgradeSystemOrder, name)
        if GetConVar and GetConVar("developer") and GetConVar("developer"):GetBool() then
            MsgC(Color(100, 200, 255), "[Horde Upgrades] Система '" .. name .. "' зарегистрирована\n")
        end
    end
    HORDE.UpgradeSystems[name] = def
    return def
end

function HORDE:GetUpgradeSystem(name)
    return HORDE.UpgradeSystems[name or "item"]
end

function HORDE:GetUpgrade(ply, key, system)
    local def = HORDE:GetUpgradeSystem(system)
    if not def or not IsValid(ply) or key == nil then return 0 end
    return def.Get(ply, key) or 0
end

function HORDE:GetUpgradeMax(ply, key, system)
    local def = HORDE:GetUpgradeSystem(system)
    if not def or key == nil then return nil end
    local max_level = tonumber(def.MaxLevel(ply, key))
    if not max_level or max_level <= 0 then return nil end
    return max_level
end

function HORDE:SetUpgrade(ply, key, level, system)
    local def = HORDE:GetUpgradeSystem(system)
    if not def or not IsValid(ply) or key == nil then return end
    level = math.floor(tonumber(level) or 0)
    local max_level = HORDE:GetUpgradeMax(ply, key, system)
    if max_level then
        level = math.Clamp(level, 0, max_level)
    else
        level = math.max(0, level)
    end
    def.Set(ply, key, level)
    return level
end

function HORDE:MaxUpgrade(ply, key, system)
    if not IsValid(ply) or key == nil then return false end
    local def = HORDE:GetUpgradeSystem(system)
    if not def then return false end
    local max_level = HORDE:GetUpgradeMax(ply, key, system)
    if not max_level then return false end
    if (def.Get(ply, key) or 0) < max_level then
        def.Set(ply, key, max_level)
    end
    if def.OnMax then def.OnMax(ply, key) end
    return true
end

function HORDE:MaxUpgradeSystem(ply, system)
    local def = HORDE:GetUpgradeSystem(system)
    if not def or not IsValid(ply) or not def.Keys then return false end
    for key in pairs(def.Keys(ply) or {}) do
        HORDE:MaxUpgrade(ply, key, system)
    end
    if def.AfterMax then def.AfterMax(ply) end
    return true
end

function HORDE:MaxAllUpgrades(ply)
    if not IsValid(ply) then return false end
    for _, name in ipairs(HORDE.UpgradeSystemOrder) do
        local def = HORDE.UpgradeSystems[name]
        if def and def.AutoMax then
            HORDE:MaxUpgradeSystem(ply, name)
        end
    end
    return true
end

local function ItemMaxLevel(ply, class)
    local builder = HORDE.Horde_GetBuilderSystemForBuildable
        and HORDE:Horde_GetBuilderSystemForBuildable(class)
    if builder and builder.MaxUpgradeLevel then return builder.MaxUpgradeLevel end
    if HORDE.relic_no_upgrade and HORDE.relic_no_upgrade[class] then return nil end
    return HORDE.Item_MaxUpgradeLevel
end

local function ItemKeys(ply)
    local keys = {}

    if HORDE.GetPlayerBuildableClasses then
        for class in pairs(HORDE:GetPlayerBuildableClasses()) do
            if class ~= "horde_engiconstruction" and class ~= "horde_wardenconstruction" then
                keys[class] = true
            end
        end
    end

    local subclass = ply.Horde_GetCurrentSubclass and ply:Horde_GetCurrentSubclass()
    if subclass and HORDE.relic_weapon_subclass then
        for relic_class, relic_subclass in pairs(HORDE.relic_weapon_subclass) do
            if relic_subclass == subclass then keys[relic_class] = true end
        end
    end
    if subclass == "Gunslinger" then
        for class, item in pairs(HORDE.items or {}) do
            if istable(item) and item.category == "Pistol" then keys[class] = true end
        end
    end

    return keys
end

HORDE:RegisterUpgradeSystem({
    name = "item",
    Title = "Weapon/buildable upgrades",
    AutoMax = true,

    Get = function(ply, key) return ply:Horde_GetUpgrade(key) end,
    Set = function(ply, key, level) ply:Horde_SetUpgrade(key, level) end,
    MaxLevel = ItemMaxLevel,
    Keys = ItemKeys,

    OnMax = function(ply, key)
        if not ply:HasWeapon(key) then return end
        local item = HORDE.items and HORDE.items[key]
        if istable(item) and item.OnUpgrade then
            item.OnUpgrade(ply, item)
        elseif key == "horde_pheropod" then
            local wep = ply:GetWeapon("horde_pheropod")
            if IsValid(wep) and wep.UpgradeReset then wep:UpgradeReset() end
        end
    end,

    AfterMax = function(ply)
        if not SERVER then return end
        local drops = HORDE.player_drop_entities and HORDE.player_drop_entities[ply:SteamID()]
        if not drops then return end
        for _, ent in pairs(drops) do
            if IsValid(ent) and HORDE:IsPlayerBuildable(ent) then
                local class = ent:GetClass()
                local builder = HORDE:Horde_GetBuilderSystemForBuildable(class)
                if builder and builder.ApplyUpgradeBonus then
                    builder.ApplyUpgradeBonus(ent, class, HORDE:GetUpgradeMax(ply, class, "item"))
                end
            end
        end
    end,
})

HORDE:RegisterUpgradeSystem({
    name = "spell",
    Title = "Spell upgrades",
    AutoMax = true,

    Get = function(ply, key) return ply:Horde_GetSpellUpgrade(key) end,
    Set = function(ply, key, level) ply:Horde_SetSpellUpgrade(key, level) end,
    MaxLevel = function(ply, key)
        local spell = HORDE.spells and HORDE.spells[key]
        if not spell then return nil end
        local max_level = tonumber(spell.Upgrades)
        if not max_level or max_level <= 0 then return nil end
        return max_level
    end,
    Keys = function() return HORDE.spells or {} end,
})
