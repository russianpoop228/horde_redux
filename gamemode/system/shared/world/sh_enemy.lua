HORDE.enemies = HORDE.enemies or {}
HORDE.enemies_all = HORDE.enemies_all or {}
HORDE.bosses = HORDE.bosses or {}
HORDE.enemies_normalized = {}
HORDE.bosses_normalized = {}

HORDE.boss_slots = HORDE.boss_slots or {}
HORDE.enemy_pool_slots = HORDE.enemy_pool_slots or {}

HORDE.enemies_defaults = HORDE.enemies_defaults or {}
HORDE.EnemiesCustom = HORDE.EnemiesCustom or {}
HORDE.EnemiesRemoved = HORDE.EnemiesRemoved or {}
HORDE.EnemyOverrides = HORDE.EnemyOverrides or {}

HORDE._enemy_defs = HORDE._enemy_defs or {}

local function dev()
    local cv = GetConVar("developer")
    return cv and cv:GetBool()
end

local function CanonKey(k)
    local s = string.lower(tostring(k))
    s = string.gsub(s, "_", "")
    return s
end

local RESERVED = { difficulties = true, bydifficulty = true, waves = true, wave = true, appearwave = true }

local function MergeOver(base, over)
    local out = {}
    for k, v in pairs(base) do out[k] = v end
    if not istable(over) then return out end
    for k, v in pairs(over) do
        local ck = CanonKey(k)
        if not RESERVED[ck] then
            for bk in pairs(out) do
                if CanonKey(bk) == ck then out[bk] = nil end
            end
            out[k] = v
        end
    end
    return out
end

local function pick(src, ...)
    for i = 1, select("#", ...) do
        local v = src[select(i, ...)]
        if v ~= nil then return v end
    end
    return nil
end

local function CopyIfTable(v)
    if istable(v) then return table.Copy(v) end
    return v
end

local function RegisteredDifficulties()
    local by_index = {}
    for idx, name in pairs(HORDE.difficulty_text or {}) do
        if isnumber(idx) and isstring(name) and name ~= "" then
            by_index[idx] = { index = idx, name = name }
        end
    end
    for idx, def in pairs(HORDE._difficulties or {}) do
        if istable(def) and def.Name then
            by_index[idx] = { index = idx, name = def.Name, def = def }
        end
    end
    local list = {}
    for _, d in pairs(by_index) do list[#list + 1] = d end
    table.sort(list, function(a, b) return a.index < b.index end)
    return list
end

function HORDE:GetEnemyDifficultyNames()
    local names = {}
    for _, d in ipairs(RegisteredDifficulties()) do names[#names + 1] = d.name end
    return names
end

function HORDE:IsWave666DifficultyName(name)
    for _, d in ipairs(RegisteredDifficulties()) do
        if d.name == name then return d.def ~= nil and d.def.IsWave666 == true end
    end
    return false
end

function HORDE:ResolveDifficultyName(v)
    if v == nil then return nil end
    local list = RegisteredDifficulties()
    if isnumber(v) then
        for _, d in ipairs(list) do if d.index == v then return d.name end end
        return nil
    end
    if isstring(v) then
        local up = string.upper(v)
        for _, d in ipairs(list) do
            if string.upper(d.name) == up then return d.name end
        end
    end
    return nil
end

function HORDE:GetActiveDifficultyName()
    local idx = HORDE.difficulty
    if not idx then return nil end
    local def = HORDE._difficulties and HORDE._difficulties[idx]
    if def and def.Name then return def.Name end
    return HORDE.difficulty_text and HORDE.difficulty_text[idx] or nil
end

local function LookupByDifficulty(by, D)
    if not istable(by) then return nil end
    for k, v in pairs(by) do
        if HORDE:ResolveDifficultyName(k) == D then return v end
    end
    return nil
end

local function TargetDifficulties(tbl, ov, wave, only)
    local spec = pick(ov, "Difficulties", "DIFFICULTIES", "difficulties")
    if spec == nil then spec = pick(tbl, "Difficulties", "DIFFICULTIES", "difficulties") end

    local out, seen = {}, {}
    local function add(n)
        if n and not seen[n] and (not only or n == only) then
            seen[n] = true
            out[#out + 1] = n
        end
    end

    if spec ~= nil then
        if istable(spec) then
            for _, v in pairs(spec) do add(HORDE:ResolveDifficultyName(v)) end
        else
            add(HORDE:ResolveDifficultyName(spec))
        end
    else
        local w666 = HORDE.WAVE666_ENEMY_WAVE or 666
        for _, d in ipairs(RegisteredDifficulties()) do
            if wave ~= w666 or (d.def and d.def.IsWave666) then add(d.name) end
        end
    end
    return out
end

local function RegisterEnemySingle(self, tbl, wave, ov, D)
    ov = ov or {}

    local src = MergeOver(tbl, LookupByDifficulty(pick(tbl, "ByDifficulty", "by_difficulty", "bydifficulty"), D))
    src = MergeOver(src, ov)
    src = MergeOver(src, LookupByDifficulty(pick(ov, "ByDifficulty", "by_difficulty", "bydifficulty"), D))

    local name = pick(src, "name", "Name", "PrintName")
    local class = pick(src, "class", "Class", "ClassName")

    if name == nil or class == nil or wave == nil or wave <= 0 or name == "" or class == "" then
        ErrorNoHaltWithStack("[Horde Enemies] RegisterEnemy: missing name/class/wave\n")
        return
    end

    local enemy = {}
    enemy.name = name
    enemy.class = class
    enemy.weight = math.max(0, pick(src, "weight", "Weight") or 0)
    enemy.wave = math.max(1, wave)
    enemy.health_scale = pick(src, "health_scale", "HealthScale") or 1
    enemy.damage_scale = pick(src, "damage_scale", "DamageScale") or 1
    enemy.reward_scale = pick(src, "reward_scale", "RewardScale") or 1
    enemy.model_scale = pick(src, "model_scale", "ModelScale") or 1
    enemy.color = CopyIfTable(pick(src, "color", "Color"))
    enemy.weapon = pick(src, "weapon", "Weapon")
    enemy.spawn_limit = pick(src, "spawn_limit", "SpawnLimit") or 0
    local elite = pick(src, "is_elite", "IsElite")
    enemy.is_elite = elite == true
    enemy.boss_properties = CopyIfTable(pick(src, "boss_properties", "BossProperties")) or {}
    enemy.spawn_min = pick(src, "spawn_min", "SpawnMin") or 0

    if enemy.boss_properties then
        if enemy.boss_properties.unlimited_enemies_spawn and (not enemy.boss_properties.end_wave) then
            enemy.boss_properties.end_wave = true
        end
    end
    enemy.mutation = pick(src, "mutation", "Mutation")
    local skin = pick(src, "skin", "Skin")
    if skin and skin ~= "" then
        enemy.skin = skin
    end
    enemy.gadget_drop = CopyIfTable(pick(src, "gadget_drop", "GadgetDrop"))
    local model = pick(src, "model", "Model")
    if model and model ~= "" then enemy.model = model end

    local key = name .. tostring(enemy.wave)

    local store = HORDE._enemy_store_override
    if not store then
        HORDE.enemies_all[D] = HORDE.enemies_all[D] or {}
        store = HORDE.enemies_all[D]
    end

    if store[key] and dev() and not HORDE._enemy_store_override then
        MsgC(Color(255, 255, 0), "[Horde Enemies] Enemy overridden: " .. D .. " / " .. key .. "\n")
    end
    store[key] = enemy

    if HORDE._registering_default_enemies and not HORDE._enemy_store_override then
        HORDE.enemies_defaults[D] = HORDE.enemies_defaults[D] or {}
        HORDE.enemies_defaults[D][key] = enemy
    end

    if not HORDE._enemy_store_override and D == HORDE:GetActiveDifficultyName() then
        HORDE.enemies = store
    end

    hook.Run("Horde_OnEnemyRegistered", enemy, D)
end

function HORDE:RegisterEnemy(tbl, only_difficulty)
    if not tbl or type(tbl) ~= "table" then
        ErrorNoHaltWithStack("[Horde Enemies] RegisterEnemy: expected table\n")
        return
    end

    local name = tbl.name or tbl.Name or tbl.PrintName
    local class = tbl.class or tbl.Class or tbl.ClassName
    if name == nil or class == nil or name == "" or class == "" then
        ErrorNoHaltWithStack("[Horde Enemies] RegisterEnemy: missing name/class\n")
        return
    end

    if not only_difficulty and not HORDE._enemy_store_override then
        table.insert(HORDE._enemy_defs, tbl)
    end

    local waves_spec = tbl.waves or tbl.Waves or tbl.AppearWave or tbl.appear_wave
    local entries = {}

    if waves_spec ~= nil then
        if type(waves_spec) == "number" then
            entries[#entries + 1] = { wave = waves_spec, ov = {} }
        elseif type(waves_spec) == "table" then
            local has_table_value = false
            for _, v in pairs(waves_spec) do
                if type(v) == "table" then
                    has_table_value = true
                    break
                end
            end

            if has_table_value then
                for wave, ov in pairs(waves_spec) do
                    if type(wave) == "number" and type(ov) == "table" then
                        entries[#entries + 1] = { wave = wave, ov = ov }
                    end
                end
                table.sort(entries, function(a, b) return a.wave < b.wave end)
            else
                for _, wave in ipairs(waves_spec) do
                    if type(wave) == "number" then
                        entries[#entries + 1] = { wave = wave, ov = {} }
                    end
                end
            end
        end
    else
        local wave = tbl.wave or tbl.Wave
        if wave ~= nil then
            entries[#entries + 1] = { wave = wave, ov = {} }
        end
    end

    if #entries == 0 then
        ErrorNoHaltWithStack("[Horde Enemies] RegisterEnemy: missing Wave/Waves for '" .. tostring(name) .. "'\n")
        return
    end

    for _, entry in ipairs(entries) do
        for _, D in ipairs(TargetDifficulties(tbl, entry.ov, entry.wave, only_difficulty)) do
            RegisterEnemySingle(self, tbl, entry.wave, entry.ov, D)
        end
    end
end

function HORDE:CreateEnemy(name, class, weight, wave, is_elite, health_scale, damage_scale, reward_scale, model_scale, color, weapon, spawn_limit, boss_properties, mutation, skin, model, spawn_min, gadget_drop)
    return self:RegisterEnemy({
        name = name,
        class = class,
        weight = weight,
        wave = wave,
        is_elite = is_elite,
        health_scale = health_scale,
        damage_scale = damage_scale,
        reward_scale = reward_scale,
        model_scale = model_scale,
        color = color,
        weapon = weapon,
        spawn_limit = spawn_limit,
        boss_properties = boss_properties,
        mutation = mutation,
        skin = skin,
        model = model,
        spawn_min = spawn_min,
        gadget_drop = gadget_drop,
    })
end

hook.Add("Horde_OnDifficultyRegistered", "Horde_ReplayEnemiesForNewDifficulty", function(def)
    if not istable(def) or not def.Name then return end
    if HORDE.configs and HORDE.configs[def.Name] then
        HORDE:ApplyConfig(def.Name)
        return
    end
    if #HORDE._enemy_defs == 0 then return end
    local store = HORDE.enemies_all[def.Name]
    if store and next(store) ~= nil then return end
    for _, tbl in ipairs(HORDE._enemy_defs) do
        HORDE:RegisterEnemy(tbl, def.Name)
    end
end)

function HORDE:BuildGenericDefaultEnemies(D)
    local temp = {}
    HORDE._enemy_store_override = temp
    for _, tbl in ipairs(HORDE._enemy_defs) do
        HORDE:RegisterEnemy(tbl, D)
    end
    HORDE._enemy_store_override = nil
    return temp
end

function HORDE:BuildDefaultEnemies(D)
    if HORDE.configs and HORDE.configs[D] then
        return HORDE:BuildConfigEnemies(D)
    end
    return HORDE:BuildGenericDefaultEnemies(D)
end

function HORDE:NormalizeEnemiesWeightOnWave(enemies)
    local total_weight = 0
    for name, weight in pairs(enemies) do
        total_weight = total_weight + weight
    end
    for name, weight in pairs(enemies) do
        enemies[name] = weight / total_weight
    end
end

function HORDE:GetForcedEnemiesOnWave(enemies, enemy_wave, total_enemies)
    local forced = {}
    for name, _ in pairs(enemies) do
        local enemy = HORDE.enemies[name .. tostring(enemy_wave)]
        if not enemy then goto cont_forced end
        if enemy.spawn_min and enemy.spawn_min > 0 then
            forced[name] = {}
            for i = 1, enemy.spawn_min do
                table.insert(forced[name], math.random(1, total_enemies))
            end
        end
        ::cont_forced::
    end
    return forced
end

local function IsBossEnemy(enemy)
    return enemy.boss_properties and enemy.boss_properties.is_boss == true
end

function HORDE:NormalizeEnemiesWeight()
    local w666 = HORDE.WAVE666_ENEMY_WAVE or 666
    local enemies = HORDE.enemies or {}

    HORDE.enemies_normalized = {}
    HORDE.bosses_normalized = {}
    HORDE.boss_slots = {}
    HORDE.enemy_pool_slots = {}

    local now = {}
    for _, enemy in pairs(enemies) do
        if IsBossEnemy(enemy) then now[enemy.name .. enemy.wave] = enemy end
    end
    for key in pairs(HORDE._config_boss_keys or {}) do
        if not now[key] then HORDE.bosses[key] = nil end
    end
    HORDE._config_boss_keys = {}
    for key, enemy in pairs(now) do
        HORDE.bosses[key] = enemy
        HORDE._config_boss_keys[key] = true
    end

    if table.IsEmpty(enemies) then return end

    local slot_set = {}
    for wave = 1, HORDE.max_max_waves do slot_set[wave] = true end
    slot_set[w666] = true
    for _, enemy in pairs(enemies) do slot_set[enemy.wave] = true end
    for _, enemy in pairs(HORDE.bosses) do
        if istable(enemy) and enemy.wave then slot_set[enemy.wave] = true end
    end

    local slots = {}
    for wave in pairs(slot_set) do slots[#slots + 1] = wave end
    table.sort(slots)

    local totals = {}
    for _, wave in ipairs(slots) do
        HORDE.enemies_normalized[wave] = {}
        totals[wave] = 0
    end
    for _, enemy in pairs(enemies) do
        if not IsBossEnemy(enemy) then
            totals[enemy.wave] = (totals[enemy.wave] or 0) + enemy.weight
        end
    end
    for _, enemy in pairs(enemies) do
        if not IsBossEnemy(enemy) then
            local total = totals[enemy.wave] or 0
            HORDE.enemies_normalized[enemy.wave][enemy.name] = (total > 0) and (enemy.weight / total) or 0
        end
    end

    local btotals = {}
    for _, wave in ipairs(slots) do
        HORDE.bosses_normalized[wave] = {}
        btotals[wave] = 0
    end
    for _, enemy in pairs(HORDE.bosses) do
        if istable(enemy) and enemy.wave and enemy.weight then
            btotals[enemy.wave] = (btotals[enemy.wave] or 0) + enemy.weight
        end
    end
    for _, enemy in pairs(HORDE.bosses) do
        if istable(enemy) and enemy.wave and enemy.weight then
            local total = btotals[enemy.wave] or 0
            HORDE.bosses_normalized[enemy.wave][enemy.name] = (total > 0) and (enemy.weight / total) or 0
        end
    end

    for _, wave in ipairs(slots) do
        if wave ~= w666 then
            if wave % 5 == 0 then
                if next(HORDE.bosses_normalized[wave]) ~= nil then
                    HORDE.boss_slots[#HORDE.boss_slots + 1] = wave
                end
            elseif wave >= 6 and next(HORDE.enemies_normalized[wave]) ~= nil then
                HORDE.enemy_pool_slots[#HORDE.enemy_pool_slots + 1] = wave
            end
        end
    end
end

HORDE.InvalidateHordeEnemyCache = 1
HORDE.CachedHordeEnemies = nil
HORDE.GetCachedHordeEnemies = function()
    if HORDE.InvalidateHordeEnemyCache == 1 then
        local tab = util.TableToJSON(HORDE.enemies)
        local str = util.Compress(tab)
        HORDE.CachedHordeEnemies = str
        HORDE.InvalidateHordeEnemyCache = 0
    end
    return HORDE.CachedHordeEnemies
end

function HORDE:SyncEnemiesTo(ply)
    local str = HORDE.GetCachedHordeEnemies()
    net.Start("Horde_SyncEnemies")
        net.WriteUInt(string.len(str), 32)
        net.WriteData(str, string.len(str))
    net.Send(ply)
end

function HORDE:SyncMutationsTo(ply)
    net.Start("Horde_SyncMutations")
        local muts = {}
        for mut_name, mut in pairs(HORDE.mutations) do
            muts[mut_name] = mut.Description
        end
        net.WriteTable(muts)
    net.Send(ply)
end

local function ExternalEnemiesLocked()
    return HORDE._external_enemies == true
end

function HORDE:RefreshActiveEnemies()
    if ExternalEnemiesLocked() then
        HORDE:NormalizeEnemiesWeight()
        HORDE.InvalidateHordeEnemyCache = 1
        return
    end

    local D = HORDE:GetActiveDifficultyName()
    if not D or HORDE:ResolveDifficultyName(D) == nil then
        D = HORDE:GetEnemyDifficultyNames()[1]
    end
    if not D then return end

    HORDE.enemies_all[D] = HORDE.enemies_all[D] or {}
    HORDE.enemies = HORDE.enemies_all[D]
    HORDE:NormalizeEnemiesWeight()
    HORDE.InvalidateHordeEnemyCache = 1
end

function HORDE:SetEnemiesData()
    if SERVER then
        HORDE:NormalizeEnemiesWeight()

        if GetConVarNumber("horde_default_enemy_config") == 1 then return end
        if ExternalEnemiesLocked() then return end
        if not file.IsDir("horde", "DATA") then
            file.CreateDir("horde")
        end

        file.Write("horde/enemies.txt", util.TableToJSON({
            version = 2,
            difficulties = HORDE.enemies_all,
        }))
    end
end

local function EnemyIsValid(enemy)
    return istable(enemy) and isstring(enemy.name) and enemy.name ~= ""
        and isstring(enemy.class) and enemy.class ~= ""
        and enemy.weight ~= nil and enemy.wave ~= nil
end

local function GetEnemiesData()
    if not SERVER then return end
    if not file.IsDir("horde", "DATA") then
        file.CreateDir("horde")
    end

    local raw = file.Read("horde/enemies.txt", "DATA")
    if not raw then
        HORDE:RefreshActiveEnemies()
        return
    end

    local t = util.JSONToTable(raw)
    if not istable(t) then
        HORDE:RefreshActiveEnemies()
        return
    end

    local per_diff, migrated = nil, false
    if t.version == 2 and istable(t.difficulties) then
        per_diff = t.difficulties
    else
        if not file.Exists("horde/enemies_v1_backup.txt", "DATA") then
            file.Write("horde/enemies_v1_backup.txt", raw)
        end
        local w666 = HORDE.WAVE666_ENEMY_WAVE or 666
        per_diff = {}
        for _, D in ipairs(HORDE:GetEnemyDifficultyNames()) do
            local copy = {}
            local is666 = HORDE:IsWave666DifficultyName(D)
            for key, enemy in pairs(t) do
                if istable(enemy) and (enemy.wave ~= w666 or is666) then
                    copy[key] = table.Copy(enemy)
                end
            end
            per_diff[D] = copy
        end
        migrated = true
    end

    for D, tbl in pairs(per_diff) do
        for _, enemy in pairs(tbl) do
            local valid_ok, valid_err = EnemyIsValid(enemy), nil
            if valid_ok then valid_ok, valid_err = HORDE.Validate.Enemy(tostring(enemy.name), enemy) end
            if not valid_ok then
                if valid_err then print("[HORDE] - Enemy config file validation failed: " .. tostring(valid_err)) end
                HORDE:SendNotification("Enemy config file validation failed! Please update your file or delete it.", 0)
                HORDE:RefreshActiveEnemies()
                return
            end
            if not enemy.weapon then
                enemy.weapon = ""
            end
        end
    end

    for D, tbl in pairs(per_diff) do
        local name = HORDE:ResolveDifficultyName(D) or D
        HORDE.enemies_all[name] = HORDE.enemies_all[name] or {}
        for key, enemy in pairs(tbl) do
            HORDE.enemies_all[name][key] = enemy
        end
    end

    HORDE:RefreshActiveEnemies()
    if migrated then
        HORDE:SetEnemiesData()
        print("[HORDE] - Enemy config migrated to per-difficulty format (backup: data/horde/enemies_v1_backup.txt).")
    end
    print("[HORDE] - Loaded custom enemy config (merged with defaults).")
end

function HORDE:GetDefaultEnemiesData()
    HORDE:RefreshActiveEnemies()
    if table.IsEmpty(HORDE.enemies) then
        ErrorNoHalt("[HORDE] GetDefaultEnemiesData: no enemies registered — check gamemode/modules/enemies/\n")
    end
    print("[HORDE] - Loaded default enemy config (" .. table.Count(HORDE.enemies) .. " entries).")
end

HORDE.configs = HORDE.configs or {}

local function FindEnemyDef(name)
    for _, t in ipairs(HORDE._enemy_defs or {}) do
        if istable(t) and (t.Name or t.name or t.PrintName) == name then
            return t
        end
    end
    return nil
end

function HORDE:RegisterConfigBosses(bosses, D)
    if not istable(bosses) then return end
    for wave, spec in pairs(bosses) do
        if isnumber(wave) and wave > 0 then
            local names = istable(spec) and spec or { spec }
            for _, boss_name in ipairs(names) do
                local def = FindEnemyDef(boss_name)
                if not def then
                    ErrorNoHaltWithStack("[Horde Config] " .. tostring(D) .. ": unknown boss '" ..
                        tostring(boss_name) .. "' (wave " .. wave .. ")\n")
                else
                    local entry = table.Copy(def)
                    entry.Waves = nil; entry.wave = nil
                    entry.AppearWave = nil; entry.appear_wave = nil
                    entry.Difficulties = nil; entry.difficulties = nil; entry.DIFFICULTIES = nil
                    entry.ByDifficulty = nil; entry.by_difficulty = nil
                    entry.Name = boss_name
                    entry.Class = def.Class or def.class or def.ClassName
                    entry.IsElite = true
                    entry.BossProperties = table.Copy(def.BossProperties or def.boss_properties or {})
                    entry.BossProperties.is_boss = true
                    entry.BossProperties.end_wave = true
                    entry.Wave = wave
                    HORDE:RegisterEnemy(entry, D)
                end
            end
        end
    end
end

function HORDE:BuildConfigEnemies(D)
    local cfg = HORDE.configs and HORDE.configs[D]
    if not istable(cfg) then return nil end

    local store
    if cfg.BaseDefault == false then
        store = {}
    else
        store = HORDE:BuildGenericDefaultEnemies(D)
    end

    if istable(cfg.Bosses) and next(cfg.Bosses) ~= nil then
        for k, e in pairs(store) do
            if istable(e) and e.boss_properties and e.boss_properties.is_boss then
                store[k] = nil
            end
        end
    end

    HORDE._enemy_store_override = store
    for _, e in ipairs(cfg.Enemies or {}) do
        HORDE:RegisterEnemy(e, D)
    end
    HORDE:RegisterConfigBosses(cfg.Bosses, D)
    HORDE._enemy_store_override = nil
    return store
end

function HORDE:ApplyConfig(D)
    if ExternalEnemiesLocked() then return end
    local store = HORDE:BuildConfigEnemies(D)
    if not store then return end
    HORDE.enemies_all[D] = store
    HORDE.enemies_defaults[D] = table.Copy(store)
    if HORDE:GetActiveDifficultyName() == D then
        HORDE:RefreshActiveEnemies()
    end
    HORDE.InvalidateHordeEnemyCache = 1
    hook.Run("Horde_OnConfigRegistered", D, HORDE.configs[D])
end

function HORDE:RegisterConfig(tbl)
    if not istable(tbl) then return end
    local D = HORDE:ResolveDifficultyName(tbl.Difficulty or tbl.Name)
    if not D then
        HORDE._pending_configs = HORDE._pending_configs or {}
        HORDE._pending_configs[#HORDE._pending_configs + 1] = tbl
        return
    end
    HORDE.configs = HORDE.configs or {}
    HORDE.configs[D] = tbl
    HORDE:ApplyConfig(D)
end

hook.Add("Horde_OnDifficultyRegistered", "Horde_ApplyPendingConfigsForDifficulty", function(def)
    if not istable(def) or not def.Name then return end
    local pending = HORDE._pending_configs
    if not pending or #pending == 0 then return end
    local left = {}
    for _, tbl in ipairs(pending) do
        if HORDE:ResolveDifficultyName(tbl.Difficulty or tbl.Name) == def.Name then
            HORDE.configs = HORDE.configs or {}
            HORDE.configs[def.Name] = tbl
            HORDE:ApplyConfig(def.Name)
        else
            left[#left + 1] = tbl
        end
    end
    HORDE._pending_configs = left
end)

if SERVER then
    util.AddNetworkString("Horde_SetEnemiesData")
    util.AddNetworkString("Horde_RequestEnemyConfig")
    util.AddNetworkString("Horde_EnemyConfigDefault")
    util.AddNetworkString("Horde_SyncEnemyConfigMeta")
    util.AddNetworkString("Horde_SyncEnemyConfig")

    hook.Add("Horde_AllModulesLoaded", "Horde_InitEnemies", function()
        if GetConVar("horde_external_lua_config"):GetString() ~= "" then
            return
        end
        if GetConVarNumber("horde_default_enemy_config") == 1 then
            HORDE:GetDefaultEnemiesData()
        else
            GetEnemiesData()
        end
        HORDE.InvalidateHordeEnemyCache = 1
    end)

    hook.Add("PlayerInitialSpawn", "Horde_SyncEnemiesOnJoin", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) and HORDE.SyncEnemiesTo then
                HORDE:SyncEnemiesTo(ply)
            end
        end)
    end)

    local function SyncActiveToAll()
        HORDE.InvalidateHordeEnemyCache = 1
        for _, p in ipairs(player.GetAll()) do HORDE:SyncEnemiesTo(p) end
    end

    local function SendDifficultyConfig(ply, D)
        local str = util.Compress(util.TableToJSON(HORDE.enemies_all[D] or {}))
        if string.len(str) > 65000 then
            ErrorNoHalt("[HORDE] Enemy config of " .. D .. " is too large to sync (" .. string.len(str) .. " bytes)\n")
            return
        end
        net.Start("Horde_SyncEnemyConfig")
            net.WriteString(D)
            net.WriteUInt(string.len(str), 32)
            net.WriteData(str, string.len(str))
        net.Send(ply)
    end

    net.Receive("Horde_RequestEnemyConfig", function(len, ply)
        if not ply:IsSuperAdmin() then return end
        local names = HORDE:GetEnemyDifficultyNames()
        local active = HORDE:GetActiveDifficultyName()
        for _, D in ipairs(names) do
            HORDE.enemies_all[D] = HORDE.enemies_all[D] or {}
        end
        local wave666 = {}
        for _, D in ipairs(names) do
            if HORDE:IsWave666DifficultyName(D) then wave666[D] = true end
        end
        net.Start("Horde_SyncEnemyConfigMeta")
            net.WriteTable({
                names = names,
                active = active,
                wave666 = wave666,
                difficulty_basics = HORDE.difficulty_basics_overrides or {},
                difficulty_defaults = HORDE._difficulty_file_defaults or {},
            })
        net.Send(ply)
        for _, D in ipairs(names) do
            SendDifficultyConfig(ply, D)
        end
    end)

    net.Receive("Horde_SetEnemiesData", function(len, ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        if not HORDE:AllowNetRequest(ply, "set_enemies_data", 2) then return end
        local D = HORDE:ResolveDifficultyName(net.ReadString())
        if not D then return end
        local tbl, err = HORDE:ReadCompressedJSON()
        if not tbl then
            HORDE:SendNotification("Enemy config rejected: " .. tostring(err), 1, ply)
            return
        end
        local ok, verr = HORDE.Validate.Enemies(tbl)
        if not ok then
            HORDE:SendNotification("Enemy config rejected: " .. tostring(verr), 1, ply)
            return
        end

        for _, enemy in pairs(tbl) do
            if not enemy.weapon then enemy.weapon = "" end
        end

        local cv = GetConVar("horde_default_enemy_config")
        if cv and cv:GetInt() ~= 0 then
            cv:SetInt(0)
        end

        HORDE.enemies_all[D] = tbl
        HORDE:SetEnemiesData()
        local deferred = HORDE:QueueConfigApply("enemies:" .. D, function()
            if ExternalEnemiesLocked() then return end
            if HORDE:ResolveDifficultyName(HORDE:GetActiveDifficultyName()) == D then
                HORDE:RefreshActiveEnemies()
                SyncActiveToAll()
            end
        end)
        HORDE:SendNotification(deferred and "Enemy config saved. It will apply on the next wave."
            or "Enemy config applied.", 0, ply)
    end)

    net.Receive("Horde_EnemyConfigDefault", function(len, ply)
        if not ply:IsSuperAdmin() then return end
        local D = HORDE:ResolveDifficultyName(net.ReadString())
        if not D then return end
        local overwrite = net.ReadBool()

        local defaults = HORDE:BuildDefaultEnemies(D)
        local newtbl
        if overwrite then
            newtbl = defaults
        else
            newtbl = table.Copy(HORDE.enemies_all[D] or {})
            for key, enemy in pairs(defaults) do
                newtbl[key] = enemy
            end
        end
        HORDE.enemies_all[D] = newtbl

        local cv = GetConVar("horde_default_enemy_config")
        if cv and cv:GetInt() ~= 0 then
            cv:SetInt(0)
        end

        HORDE:SetEnemiesData()
        local deferred = HORDE:QueueConfigApply("enemies:" .. D, function()
            if ExternalEnemiesLocked() then return end
            if HORDE:ResolveDifficultyName(HORDE:GetActiveDifficultyName()) == D then
                HORDE:RefreshActiveEnemies()
                SyncActiveToAll()
            end
        end)
        SendDifficultyConfig(ply, D)
        HORDE:SendNotification(deferred and "Enemy config saved. It will apply on the next wave."
            or "Enemy config applied.", 0, ply)
    end)
end
