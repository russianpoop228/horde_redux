HORDE = HORDE or {}

local _deferred = {}
local function defer(fn, ...)
    local args = {...}
    table.insert(_deferred, function() fn(table.unpack(args)) end)
end

function HORDE:FlushDeferredRegistrations()
    local q = _deferred
    _deferred = {}
    for _, fn in ipairs(q) do
        local ok, err = pcall(fn)
        if not ok then
            ErrorNoHaltWithStack("[Horde Registry] Deferred registration failed: " .. tostring(err) .. "\n")
        end
    end
end

hook.Add("Horde_AllModulesLoaded", "Horde_FlushDeferred", function()
    if HORDE and HORDE.FlushDeferredRegistrations then
        HORDE:FlushDeferredRegistrations()
    end
end)

function HORDE:RegisterPerk(tbl)
    if not tbl or type(tbl) ~= "table" then return end
    if tbl.Ignore then return end
    if not HORDE.perks then defer(self.RegisterPerk, self, tbl); return end

    local name = string.lower(tbl.ClassName or "")
    if name == "" then ErrorNoHaltWithStack("[Horde Registry] RegisterPerk: empty ClassName\n"); return end

    tbl.ClassName = name
    tbl.SortOrder = tbl.SortOrder or 0

    hook.Run("Horde_OnLoadPerk", tbl)

    if HORDE.perks[name] then
        for k in pairs(HORDE.perks[name].Hooks or {}) do
            hook.Remove(k, "horde_perk_" .. name)
        end
        MsgC(Color(255, 255, 0), "[Horde Registry] Perk overridden: " .. name .. "\n")
    end

    HORDE.perks[name] = tbl

    for event, fn in pairs(tbl.Hooks or {}) do
        hook.Add(event, "horde_perk_" .. name, fn)
    end
end

function HORDE:RegisterGadget(tbl)
    if not tbl then return end
    if not HORDE.gadgets then defer(self.RegisterGadget, self, tbl); return end

    local name = string.lower(tbl.ClassName or "")
    if name == "" then ErrorNoHaltWithStack("[Horde Registry] RegisterGadget: empty ClassName\n"); return end

    tbl.ClassName = name

    if HORDE.gadgets[name] then
        for k in pairs(HORDE.gadgets[name].Hooks or {}) do
            hook.Remove(k, "horde_gadget_" .. name)
        end
        MsgC(Color(255, 255, 0), "[Horde Registry] Gadget overridden: " .. name .. "\n")
    end

    HORDE.gadgets[name] = tbl

    for event, fn in pairs(tbl.Hooks or {}) do
        hook.Add(event, "horde_gadget_" .. name, fn)
    end
end

function HORDE:RegisterSpell(tbl)
    if not tbl then return end
    if not HORDE.spells then defer(self.RegisterSpell, self, tbl); return end

    local name = string.lower(tbl.ClassName or "")
    if name == "" then ErrorNoHaltWithStack("[Horde Registry] RegisterSpell: empty ClassName\n"); return end

    if HORDE.spells[name] then
        MsgC(Color(255, 255, 0), "[Horde Registry] Spell overridden: " .. name .. "\n")
    end
    HORDE.spells[name] = tbl
end

function HORDE:RegisterMutation(tbl)
    if not tbl then return end
    if not HORDE.mutations then defer(self.RegisterMutation, self, tbl); return end

    local name = string.lower(tbl.ClassName or "")
    if name == "" then ErrorNoHaltWithStack("[Horde Registry] RegisterMutation: empty ClassName\n"); return end

    if HORDE.mutations[name] then
        for k in pairs(HORDE.mutations[name].Hooks or {}) do
            hook.Remove(k, "horde_mutation_" .. name)
        end
        MsgC(Color(255, 255, 0), "[Horde Registry] Mutation overridden: " .. name .. "\n")
    end

    HORDE.mutations[name] = tbl

    if not tbl.NoRand then
        HORDE.mutations_rand = HORDE.mutations_rand or {}
        HORDE.mutations_rand[name] = tbl
    end

    for event, fn in pairs(tbl.Hooks or {}) do
        hook.Add(event, "horde_mutation_" .. name, fn)
    end
end

function HORDE:RegisterClass(tbl)
    if not tbl then return end
    if not HORDE.classes then defer(self.RegisterClass, self, tbl); return end

    HORDE:CreateClass(tbl)

    local class = HORDE.classes[tbl.name]
    if not class then return end

    HORDE.classes_to_order = HORDE.classes_to_order or {}
    HORDE.classes_to_order[class.name] = class.order

    HORDE.classes_to_subclasses = HORDE.classes_to_subclasses or {}
    local list = HORDE.classes_to_subclasses[class.name] or {}
    HORDE.classes_to_subclasses[class.name] = list
    for _, sub in ipairs(class.subclasses) do
        if not table.HasValue(list, sub) then list[#list + 1] = sub end
    end
    for sub, parent in pairs(HORDE.subclasses_to_classes or {}) do
        if parent == class.name and not table.HasValue(list, sub) then list[#list + 1] = sub end
    end
end

function HORDE:RegisterSubclass(tbl)
    if not tbl then return end
    if not HORDE.subclasses then defer(self.RegisterSubclass, self, tbl); return end

    local name = tbl.ClassName or tbl.PrintName
    if not name then ErrorNoHaltWithStack("[Horde Registry] RegisterSubclass: no name\n"); return end

    if HORDE.subclasses[name] then
        MsgC(Color(255, 255, 0), "[Horde Registry] Subclass overridden: " .. name .. "\n")
    end
    HORDE.subclasses[name] = tbl
end

HORDE._shop_tabs = HORDE._shop_tabs or {}

function HORDE:RegisterShopTab(tbl)
    if not tbl or not tbl.Name then
        ErrorNoHaltWithStack("[Horde Registry] RegisterShopTab: Name required\n")
        return
    end
    for _, existing in ipairs(HORDE._shop_tabs) do
        if existing.Name == tbl.Name then
            MsgC(Color(255, 255, 0), "[Horde Registry] ShopTab overridden: " .. tbl.Name .. "\n")
            existing.Order = tbl.Order or existing.Order
            for k, v in pairs(tbl) do existing[k] = v end
            table.sort(HORDE._shop_tabs, function(a, b) return (a.Order or 99) < (b.Order or 99) end)
            hook.Run("Horde_OnShopTabRegistered", existing)
            return
        end
    end
    tbl.Order = tbl.Order or 99
    table.insert(HORDE._shop_tabs, tbl)
    table.sort(HORDE._shop_tabs, function(a, b) return (a.Order or 99) < (b.Order or 99) end)
    hook.Run("Horde_OnShopTabRegistered", tbl)
end

function HORDE.DiffCfg(diffName, key, fallback)
    local ov = HORDE.difficulty_basics_overrides
    if istable(ov) and isstring(diffName) and istable(ov[diffName]) then
        local v = ov[diffName][key]
        if v ~= nil then
            local n = tonumber(v)
            if n ~= nil then return n end
            return v
        end
    end
    return fallback
end

HORDE._difficulties = HORDE._difficulties or {}

local DIFF_INCLUDE_ALIASES = { "Include", "Inherit", "Base", "Extends", "Parent" }

local DIFF_DEFAULT_KEYS = {
    "DamageMult", "HealthMult", "RewardMult", "StartMoneyMult",
    "EnemyCountMult", "SpawnRadiusMult", "MaxEnemiesScaleFactor",
    "AdditionalPack", "AdditionalAmmoboxes",
    "AdditionalEnemiesPerSpawn", "SpawnSpeedMult", "SpawnInterval",
    "SpawnIntervalWaveStep", "SpawnIntervalWaveAmount", "SpawnIntervalWaveCap",
    "EnemiesPerSpawnWaveStep", "EnemiesPerSpawnWaveAmount", "EnemiesPerSpawnWaveCap",
    "MaxEnemiesAliveBase", "MaxEnemiesAlivePerPlayer", "MaxEnemiesAliveCap",
    "StatusDurationBonus", "BreakHealthLeft", "ShockDamageIncrease",
    "FrostbiteSlow", "PoisonHeadcrabDamage",
    "EliteHealthScaleAdd", "EliteHealthScaleMultiplier",
    "MutationProbability", "EliteMutationProbability",
}

local DIFF_NON_INHERITED = { Name = true, Index = true, Hooks = true, Override = true }
for _, k in ipairs({ "IsModifier", "IsHundred", "IsUnarmed", "IsPurism", "IsWave666", "IsBudget" }) do
    DIFF_NON_INHERITED[k] = true
end
for _, k in ipairs(DIFF_INCLUDE_ALIASES) do DIFF_NON_INHERITED[k] = true end

function HORDE:GetDifficultyInclude(tbl)
    if not istable(tbl) then return nil end
    for _, k in ipairs(DIFF_INCLUDE_ALIASES) do
        if tbl[k] ~= nil then return tbl[k], k end
    end
    return nil
end

function HORDE:GetDifficultyOverride(tbl)
    if not istable(tbl) then return nil end
    return tbl.Override
end

HORDE.DEFAULT_MODIFIER_BASE = "APOCALYPSE"

function HORDE:IsModifier(name_or_tbl)
    local def = name_or_tbl
    if isstring(name_or_tbl) then
        def = HORDE:FindRegisteredDifficulty(name_or_tbl)
    end
    if not istable(def) then return false end
    if def.IsModifier ~= nil then return def.IsModifier == true end
    if HORDE:GetDifficultyOverride(def) ~= nil then return true end
    return HORDE:GetDifficultyInclude(def) ~= nil
end

function HORDE:GetDifficultyNameList()
    local list = {}
    for idx, name in pairs(HORDE.difficulty_text or {}) do
        if isnumber(idx) and isstring(name) and name ~= "" then
            list[#list + 1] = { index = idx, name = name }
        end
    end
    table.sort(list, function(a, b) return a.index < b.index end)
    return list
end

function HORDE:FindRegisteredDifficulty(ref)
    if ref == nil then return nil end
    local by_index = isnumber(ref)
    local needle = isstring(ref) and string.upper(ref) or nil
    for i, dd in pairs(HORDE._difficulties or {}) do
        if istable(dd) then
            if by_index then
                if i == ref then return dd end
            elseif isstring(dd.Name) and string.upper(dd.Name) == needle then
                return dd
            end
        end
    end
    return nil
end

function HORDE:ApplyDifficultyInclude(tbl)
    local ref = HORDE:GetDifficultyInclude(tbl)
    if ref == nil then return true end

    local base = HORDE:FindRegisteredDifficulty(ref)
    if not base or base == tbl then return false end
    local pending = HORDE._pending_difficulty_include_set
    if pending and pending[base] then return false end

    for k, v in pairs(base) do
        if tbl[k] == nil and not DIFF_NON_INHERITED[k] then
            if istable(v) then
                local copy = {}
                for k2, v2 in pairs(v) do copy[k2] = v2 end
                tbl[k] = copy
            else
                tbl[k] = v
            end
        end
    end
    hook.Run("Horde_OnDifficultyInclude", tbl, base)
    return true
end

local function SnapshotDifficultyFileDefaults(tbl, force)
    local store = HORDE._difficulty_file_defaults
    if not store then store = {}; HORDE._difficulty_file_defaults = store end
    if store[tbl.Name] and not force then return end
    local ov = HORDE.difficulty_basics_overrides
    if istable(ov) and istable(ov[tbl.Name]) then return end
    local snap = {}
    for _, k in ipairs(DIFF_DEFAULT_KEYS) do
        if tbl[k] ~= nil then snap[k] = tbl[k] end
    end
    store[tbl.Name] = snap
end

function HORDE:ResolvePendingDifficultyIncludes()
    local list = HORDE._pending_difficulty_includes
    if not istable(list) or #list == 0 then return end
    HORDE._pending_difficulty_include_set = HORDE._pending_difficulty_include_set or {}
    HORDE._pending_include_warned = HORDE._pending_include_warned or {}
    local set = HORDE._pending_difficulty_include_set

    local remaining = list
    local progress = true
    while progress and #remaining > 0 do
        progress = false
        local left = {}
        for _, tbl in ipairs(remaining) do
            if HORDE:ApplyDifficultyInclude(tbl) then
                set[tbl] = nil
                HORDE:ApplyDifficultyDefinition(tbl, true)
                HORDE._pending_include_warned[tbl] = nil
                progress = true
            else
                table.insert(left, tbl)
            end
        end
        remaining = left
    end
    HORDE._pending_difficulty_includes = remaining

    for _, tbl in ipairs(remaining) do
        if not HORDE._pending_include_warned[tbl] then
            HORDE._pending_include_warned[tbl] = true
            print("[Horde Registry] Difficulty " .. tostring(tbl.Name) .. ": Include '"
                .. tostring(HORDE:GetDifficultyInclude(tbl)) .. "' not found — characteristics not inherited")
        end
    end
end

hook.Add("Horde_AllModulesLoaded", "Horde_ResolveDifficultyIncludes", function()
    if HORDE and HORDE.ResolvePendingDifficultyIncludes then
        HORDE:ResolvePendingDifficultyIncludes()
    end
end)

function HORDE:RegisterDifficulty(tbl)
    if not tbl or not tbl.Name or not tbl.Index then
        error("[Horde Registry] RegisterDifficulty: Name and Index required", 2)
        return
    end
    if tbl.IsModifier == nil then
        tbl.IsModifier = (HORDE:GetDifficultyInclude(tbl) ~= nil) or (tbl.Override ~= nil)
    end

    local own = {}
    for k, v in pairs(tbl) do
        if not DIFF_NON_INHERITED[k] then
            if istable(v) then
                local copy = {}
                for k2, v2 in pairs(v) do copy[k2] = v2 end
                own[k] = copy
            else
                own[k] = v
            end
        end
    end
    HORDE._difficulty_own_fields = HORDE._difficulty_own_fields or {}
    HORDE._difficulty_own_fields[tbl.Name] = own

    HORDE._difficulty_file_include = HORDE._difficulty_file_include or {}
    HORDE._difficulty_file_include[tbl.Name] = HORDE:GetDifficultyInclude(tbl)

    if HORDE:GetDifficultyInclude(tbl) ~= nil and not HORDE:ApplyDifficultyInclude(tbl) then
        HORDE._pending_difficulty_includes = HORDE._pending_difficulty_includes or {}
        HORDE._pending_difficulty_include_set = HORDE._pending_difficulty_include_set or {}
        table.insert(HORDE._pending_difficulty_includes, tbl)
        HORDE._pending_difficulty_include_set[tbl] = true
    end

    HORDE:ApplyDifficultyDefinition(tbl)
end

function HORDE:RebaseDifficultyInclude(modName, baseName)
    if not isstring(modName) or not isstring(baseName) then return false end
    local mod = HORDE:FindRegisteredDifficulty(modName)
    if not mod then return false end
    local base = HORDE:FindRegisteredDifficulty(baseName)
    if not base then return false end

    if HORDE:IsModifier(base) then
        local seen = { [mod] = true }
        local next_base = base
        while istable(next_base) and HORDE:IsModifier(next_base) and not seen[next_base] do
            seen[next_base] = true
            local ref = HORDE:GetDifficultyOverride(next_base) or HORDE:GetDifficultyInclude(next_base)
            next_base = ref ~= nil and HORDE:FindRegisteredDifficulty(ref) or nil
        end
        if not istable(next_base) or HORDE:IsModifier(next_base) then
            next_base = HORDE:FindRegisteredDifficulty(HORDE.DEFAULT_MODIFIER_BASE)
        end
        if not istable(next_base) then return false end
        print(string.format("[Horde Registry] %s: base '%s' is a modifier - using '%s'",
            mod.Name, base.Name, next_base.Name))
        base = next_base
    end

    local own = (HORDE._difficulty_own_fields and HORDE._difficulty_own_fields[mod.Name]) or {}

    local to_clear = {}
    for k in pairs(mod) do
        if not DIFF_NON_INHERITED[k] and own[k] == nil then
            to_clear[#to_clear + 1] = k
        end
    end
    for _, k in ipairs(to_clear) do mod[k] = nil end

    for k, v in pairs(own) do
        if istable(v) then
            local copy = {}
            for k2, v2 in pairs(v) do copy[k2] = v2 end
            mod[k] = copy
        else
            mod[k] = v
        end
    end

    mod.Include = base.Name
    if not HORDE:ApplyDifficultyInclude(mod) then return false end
    HORDE:ApplyDifficultyDefinition(mod, true)
    return true
end

function HORDE:ApplyDifficultyDefinition(tbl, force_defaults)
    local i = tbl.Index

    SnapshotDifficultyFileDefaults(tbl, force_defaults)

    HORDE.difficulty_text = HORDE.difficulty_text or {}
    HORDE.difficulty_text[i] = tbl.Name

    if HORDE.difficulty_health_multiplier then
        HORDE.difficulty_health_multiplier[i] = tbl.HealthMult or 1
    end
    if HORDE.difficulty_reward_base_multiplier then
        HORDE.difficulty_reward_base_multiplier[i] = tbl.RewardMult or 1
    end

    if HORDE.difficulty_status_duration_bonus then
        HORDE.difficulty_status_duration_bonus[i] = tbl.StatusDurationBonus or 0
    end
    if HORDE.difficulty_break_health_left then
        HORDE.difficulty_break_health_left[i] = tbl.BreakHealthLeft or 0.20
    end
    if HORDE.difficulty_shock_damage_increase then
        HORDE.difficulty_shock_damage_increase[i] = tbl.ShockDamageIncrease or 0.15
    end
    if HORDE.difficulty_frostbite_slow then
        HORDE.difficulty_frostbite_slow[i] = tbl.FrostbiteSlow or 0.40
    end

    if HORDE.difficulty_elite_health_scale_add then
        HORDE.difficulty_elite_health_scale_add[i] = tbl.EliteHealthScaleAdd or 0.025
    end
    if HORDE.difficulty_elite_health_scale_multiplier then
        HORDE.difficulty_elite_health_scale_multiplier[i] = tbl.EliteHealthScaleMultiplier or 1.0
    end
    if HORDE.difficulty_additional_pack then
        HORDE.difficulty_additional_pack[i] = tbl.AdditionalPack or 0
    end
    if HORDE.difficulty_additional_ammoboxes then
        HORDE.difficulty_additional_ammoboxes[i] = tbl.AdditionalAmmoboxes or 0
    end
    if HORDE.difficulty_additional_enemies_per_spawn then
        HORDE.difficulty_additional_enemies_per_spawn[i] = tbl.AdditionalEnemiesPerSpawn or 0
    end
    if HORDE.difficulty_spawn_speed_mult then
        HORDE.difficulty_spawn_speed_mult[i] = tbl.SpawnSpeedMult or 1
    end
    if HORDE.difficulty_spawn_interval then
        HORDE.difficulty_spawn_interval[i] = tbl.SpawnInterval
    end

    if HORDE.difficulty_mutation_probability then
        HORDE.difficulty_mutation_probability[i] = tbl.MutationProbability or 0
    end
    if HORDE.difficulty_elite_mutation_probability then
        HORDE.difficulty_elite_mutation_probability[i] = tbl.EliteMutationProbability or 0
    end

    HORDE._difficulties[i] = tbl

    if isstring(tbl.Name) and string.match(tbl.Name, "^[%a_][%w_]*$") and rawget(_G, tbl.Name) == nil then
        _G[tbl.Name] = tbl.Name
    end

    HORDE._diff_damage_mult = HORDE._diff_damage_mult or {}
    HORDE._diff_damage_mult[i] = tbl.DamageMult or 1

    HORDE._diff_enemy_count_mult = HORDE._diff_enemy_count_mult or {}
    HORDE._diff_enemy_count_mult[i] = tbl.EnemyCountMult or 1

    HORDE._diff_start_money_mult = HORDE._diff_start_money_mult or {}
    HORDE._diff_start_money_mult[i] = tbl.StartMoneyMult or 1

    HORDE._diff_spawn_radius_mult = HORDE._diff_spawn_radius_mult or {}
    HORDE._diff_spawn_radius_mult[i] = tbl.SpawnRadiusMult or 1

    HORDE._diff_max_enemies_scale = HORDE._diff_max_enemies_scale or {}
    HORDE._diff_max_enemies_scale[i] = tbl.MaxEnemiesScaleFactor or 1

    HORDE._diff_poison_headcrab_dmg = HORDE._diff_poison_headcrab_dmg or {}
    HORDE._diff_poison_headcrab_dmg[i] = tbl.PoisonHeadcrabDamage or 50

    hook.Run("Horde_OnDifficultyRegistered", tbl)

    if SERVER then
        for event, fn in pairs(tbl.Hooks or {}) do
            hook.Add(event, "horde_difficulty_" .. tbl.Name .. "_" .. event, fn)
        end
    end

    if GetConVar("developer"):GetBool() then
        print("[Horde Registry] Difficulty " .. i .. ": " .. tbl.Name)
    end
end

HORDE._registered_systems = HORDE._registered_systems or {}

function HORDE:RegisterSystem(tbl)
    if not tbl or not tbl.Name then return end

    if tbl.Dependencies then
        for _, dep in ipairs(tbl.Dependencies) do
            if not HORDE._registered_systems[dep] then
                MsgC(Color(255, 100, 100),
                    "[Horde Registry] WARNING: System '" .. tbl.Name ..
                    "' requires '" .. dep .. "' which is not yet registered!\n")
            end
        end
    end

    HORDE._registered_systems[tbl.Name] = tbl

    if tbl.OnInit then
        local ok, err = pcall(tbl.OnInit)
        if not ok then
            ErrorNoHaltWithStack("[Horde Registry] System '" .. tbl.Name .. "' OnInit failed: " .. err .. "\n")
        end
    end

    print("[Horde Registry] System: " .. tbl.Name .. " v" .. (tbl.Version or "?"))
end

HORDE.AddPerk     = function(self, tbl) return self:RegisterPerk(tbl) end
HORDE.AddGadget   = function(self, tbl) return self:RegisterGadget(tbl) end
HORDE.AddSpell    = function(self, tbl) return self:RegisterSpell(tbl) end
HORDE.AddMutation = function(self, tbl) return self:RegisterMutation(tbl) end

function HORDE:ListRegistered()
    print("\n=== HORDE Registered Content ===")
    print("Perks:      " .. table.Count(HORDE.perks or {}))
    print("Gadgets:    " .. table.Count(HORDE.gadgets or {}))
    print("Spells:     " .. table.Count(HORDE.spells or {}))
    print("Mutations:  " .. table.Count(HORDE.mutations or {}))
    print("Classes:    " .. table.Count(HORDE.classes or {}))
    print("Subclasses: " .. table.Count(HORDE.subclasses or {}))
    print("Systems:    " .. table.Count(HORDE._registered_systems or {}))
    print("================================\n")
end

if SERVER then
    concommand.Add("horde_list_registered", function(ply)
        if IsValid(ply) and not ply:IsAdmin() then return end
        HORDE:ListRegistered()
    end)
end
