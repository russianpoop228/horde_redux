if not SERVER then return end

HORDE = HORDE or {}

local SW = HORDE.SpecialWaves
if not SW then
    ErrorNoHalt("[Horde SpecialWaves] sh_specialwaves.lua не загружен — модуль отключён.\n")
    return
end

local CONFIG_FILE = "horde/specialwaves.txt"
local NET_WAVE   = "Horde_SpecialWave"
local NET_NORMAL = "Horde_SpecialWaveNormal"
local NET_SYNC   = "Horde_SyncSpecialWaves"
local NET_TOGGLE = "Horde_ToggleSpecialWaves"
local NET_SAVE   = "Horde_SetSpecialWaves"

util.AddNetworkString(NET_WAVE)
util.AddNetworkString(NET_NORMAL)
util.AddNetworkString(NET_SYNC)
util.AddNetworkString(NET_TOGGLE)
util.AddNetworkString(NET_SAVE)

local state = {
    presets = {},
    active  = nil,
    used    = 0,
    excluded_waves = { [1] = true },
    exclude_boss_waves = true,
}

local function ReadWaveRules(decoded)
    local missing = decoded.excluded_waves == nil or decoded.exclude_boss_waves == nil
    state.excluded_waves = {}
    if istable(decoded.excluded_waves) then
        for _, w in pairs(decoded.excluded_waves) do
            w = math.floor(tonumber(w) or 0)
            if w > 0 then state.excluded_waves[w] = true end
        end
    elseif decoded.excluded_waves == nil then
        state.excluded_waves[1] = true
    end
    if decoded.exclude_boss_waves == nil then
        state.exclude_boss_waves = true
    else
        state.exclude_boss_waves = decoded.exclude_boss_waves == true
    end
    return missing
end

local function WaveRulesList()
    local list = {}
    for w in pairs(state.excluded_waves) do list[#list + 1] = w end
    table.sort(list)
    return list
end

function SW.LoadPresets()
    local raw = file.Read(CONFIG_FILE, "DATA")
    if raw and raw ~= "" then
        local decoded = util.JSONToTable(raw)
        if istable(decoded) and istable(decoded.presets) then
            state.presets = SW.SanitizeList(decoded.presets)
            if ReadWaveRules(decoded) then SW.SavePresets() end
            print("[Horde] Special Waves: загружено пресетов — " .. #state.presets)
            return
        end
        print("[Horde] Special Waves: конфиг повреждён, файл оставлен как есть (в памяти дефолты).")
        state.presets = SW.DefaultPresets()
        return
    end

    state.presets = SW.DefaultPresets()
    SW.SavePresets()
    print("[Horde] Special Waves: файла не было — записаны дефолтные пресеты.")
end

function SW.SavePresets()
    if not file.IsDir("horde", "DATA") then file.CreateDir("horde") end
    file.Write(CONFIG_FILE, util.TableToJSON({
        excluded_waves = WaveRulesList(),
        exclude_boss_waves = state.exclude_boss_waves,
        presets = state.presets,
    }, true))
end

function SW.GetPresets() return state.presets end

function SW.SyncTo(ply)
    net.Start(NET_SYNC)
        net.WriteTable({ presets = state.presets })
    if IsValid(ply) then net.Send(ply) else net.Broadcast() end
end

function HORDE:SpecialWavesConfig(ply)
    if not IsValid(ply) then return end
    if not ply:IsSuperAdmin() then
        HORDE:SendNotificationDenyAccess(ply)
        return
    end
    SW.SyncTo(ply)
    net.Start(NET_TOGGLE)
    net.Send(ply)
end

concommand.Add("horde_specialwaves_config", function(ply)
    HORDE:SpecialWavesConfig(ply)
end)

net.Receive(NET_SAVE, function(len, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    if not HORDE:AllowNetRequest(ply, "special_waves", 0.5) then return end

    local raw, err = HORDE:ReadTableSafe(len)
    if not raw then
        HORDE:SendNotification("Special Waves config rejected: " .. tostring(err), 1, ply)
        return
    end

    state.presets = SW.SanitizeList(raw.presets)
    SW.SavePresets()
    SW.SyncTo(ply)
    HORDE:SendNotification("Special Waves config saved.", 0, ply)
    print("[Horde] Special Waves: конфиг сохранён (" .. ply:Nick() .. "), пресетов — " .. #state.presets)
end)

local function ApplyMods(entry, mods)
    if not istable(entry) or not istable(mods) then return end

    if mods.health_scale and mods.health_scale ~= 1 then
        entry.health_scale = (tonumber(entry.health_scale) or 1) * mods.health_scale
    end
    if mods.damage_scale and mods.damage_scale ~= 1 then
        entry.damage_scale = (tonumber(entry.damage_scale) or 1) * mods.damage_scale
    end
    if mods.reward_scale and mods.reward_scale ~= 1 then
        entry.reward_scale = (tonumber(entry.reward_scale) or 1) * mods.reward_scale
    end
    if mods.model_scale and mods.model_scale ~= 1 then
        entry.model_scale = (tonumber(entry.model_scale) or 1) * mods.model_scale
    end
    if tonumber(mods.skin) and tonumber(mods.skin) >= 0 then
        entry.skin = math.floor(mods.skin)
    end
    if mods.use_color then
        entry.color = Color(mods.color_r or 255, mods.color_g or 255, mods.color_b or 255)
    end
    if isstring(mods.material) and mods.material ~= "" then
        entry.material = mods.material
    end
end

local function FindEnemyTemplate(name, waveIdx)
    local store = HORDE.enemies
    if not istable(store) then return nil end
    local direct = store[name .. tostring(waveIdx)]
    if istable(direct) then return direct end
    for _, e in pairs(store) do
        if istable(e) and e.name == name then return e end
    end
    return nil
end

local function BuildTempEntry(name, waveIdx, mods)
    local tmpl = FindEnemyTemplate(name, waveIdx)
    local entry

    if tmpl then
        entry = table.Copy(tmpl)
        entry.wave        = waveIdx
        entry.weight      = 1
        entry.spawn_min   = 0
        entry.spawn_limit = 0
        if istable(entry.boss_properties) then
            entry.boss_properties = table.Copy(entry.boss_properties)
            entry.boss_properties.is_boss = false
        end
    else
        entry = {
            name = name, class = name, wave = waveIdx, weight = 1,
            health_scale = 1, damage_scale = 1, reward_scale = 1, model_scale = 1,
            is_elite = false, spawn_min = 0, spawn_limit = 0,
            boss_properties = { is_boss = false },
        }
    end

    ApplyMods(entry, mods)
    return entry
end

local function ClearActive()
    local a = state.active
    if not a then return end
    state.active = nil

    local store = a.store
    if istable(store) then
        if istable(a.saved) then
            for key, entry in pairs(a.saved) do store[key] = entry end
        end
        if istable(a.temp) then
            for _, key in ipairs(a.temp) do store[key] = nil end
        end
    end
end

local function TryInject(enemies, waveIdx)
    ClearActive()

    if not istable(enemies) or table.IsEmpty(enemies) then return false end

    local cur = tonumber(HORDE.current_wave) or 0
    if cur <= 1 then state.used = 0 end
    if state.excluded_waves[cur] then return false end
    if state.exclude_boss_waves then
        local bosses = HORDE.bosses_normalized and HORDE.bosses_normalized[waveIdx]
        if (bosses and next(bosses) ~= nil) or HORDE.wave666_mode then return false end
    end

    local diffname = (HORDE.difficulty_text or {})[HORDE.difficulty]
    local max_count, chance = HORDE:GetSpecialWaveSettings(diffname)
    if max_count <= 0 or chance <= 0 then return false end
    if state.used >= max_count then return false end
    if HORDE:Random() > chance then return false end

    local pool = {}
    for _, p in ipairs(state.presets) do
        if (tonumber(p.min_wave) or 1) <= cur then pool[#pool + 1] = p end
    end
    if #pool == 0 then return false end
    local preset = pool[HORDE:Random(#pool)]
    local mods = istable(preset.mods) and preset.mods or {}

    local chosen, seen = {}, {}

    if preset.enemy_source == "custom" then
        for _, name in ipairs(preset.custom_enemies or {}) do
            if not seen[name] then
                seen[name] = true
                chosen[#chosen + 1] = { name = name, weight = 1 }
            end
        end
    else
        local poolw = {}
        for name, w in pairs(enemies) do poolw[name] = w end
        local keys = table.GetKeys(poolw)
        if not keys or #keys == 0 then return false end

        local want = math.min(math.max(1, tonumber(preset.pick_count) or 1), #keys)
        for _ = 1, want do
            local total = 0
            for _, w in pairs(poolw) do total = total + w end
            if total <= 0 then break end

            local roll = HORDE:Random() * total
            local cum, pick = 0, nil
            for name, w in pairs(poolw) do
                cum = cum + w
                if roll <= cum then pick = name break end
            end
            if not pick then for name in pairs(poolw) do pick = name break end end
            if pick then
                chosen[#chosen + 1] = { name = pick, weight = poolw[pick] }
                poolw[pick] = nil
            end
        end
    end

    if #chosen == 0 then return false end

    local store = HORDE.enemies
    if not istable(store) then return false end

    local saved, temp = {}, {}
    for _, c in ipairs(chosen) do
        local key = c.name .. tostring(waveIdx)
        local existing = store[key]
        if existing then
            saved[key] = table.Copy(existing)
            ApplyMods(existing, mods)
        else
            temp[#temp + 1] = key
            store[key] = BuildTempEntry(c.name, waveIdx, mods)
        end
    end

    local total = 0
    for _, c in ipairs(chosen) do total = total + (tonumber(c.weight) or 1) end
    for k in pairs(enemies) do enemies[k] = nil end

    local enemySet, names = {}, {}
    for _, c in ipairs(chosen) do
        local weight = (total > 0) and ((tonumber(c.weight) or 1) / total) or (1 / #chosen)
        enemies[c.name] = weight
        enemySet[c.name] = true
        names[#names + 1] = c.name
    end

    local mutations = {}
    for _, mut in ipairs(mods.mutations or {}) do
        if isstring(mut) and mut ~= "" then mutations[#mutations + 1] = mut end
    end

    state.active = {
        preset    = preset,
        store     = store,
        saved     = saved,
        temp      = temp,
        enemySet  = enemySet,
        mutations = mutations,
        waveIdx   = waveIdx,
    }
    state.used = state.used + 1

    local banner = istable(preset.banner) and preset.banner or SW.DEFAULT_BANNER
    net.Start(NET_WAVE)
        net.WriteTable({
            name    = preset.name,
            enemies = table.concat(names, ", "),
            color   = { r = banner.r, g = banner.g, b = banner.b },
        })
    net.Broadcast()

    print(string.format("[Horde] Special Wave: '%s' (%s) — %s | волна %d, спец. %d/%d",
        preset.name, tostring(diffname), table.concat(names, ", "), cur, state.used, max_count))
    return true
end

local function InstallHooks()
    if isfunction(HORDE.GetForcedEnemiesOnWave) and not HORDE._sw_forced_patched then
        HORDE._sw_forced_patched = true
        local orig = HORDE.GetForcedEnemiesOnWave

        function HORDE:GetForcedEnemiesOnWave(enemies, enemy_wave, total_enemies)
            local injected = false
            if #state.presets > 0 then
                injected = TryInject(enemies, enemy_wave)
            else
                ClearActive()
            end
            if not injected then
                net.Start(NET_NORMAL)
                net.Broadcast()
            end
            return orig(self, enemies, enemy_wave, total_enemies)
        end
    end

    if isfunction(HORDE.SpawnEnemy) and not HORDE._sw_spawn_patched then
        HORDE._sw_spawn_patched = true
        local orig = HORDE.SpawnEnemy

        function HORDE:SpawnEnemy(enemy, pos)
            local a = state.active
            if a and #a.mutations > 0 and istable(enemy) and enemy.name
                and a.enemySet[enemy.name] then
                local saved = enemy.mutation
                enemy.mutation = a.mutations[math.random(#a.mutations)]
                local result = orig(self, enemy, pos)
                timer.Simple(0.25, function()
                    if istable(enemy) then enemy.mutation = saved end
                end)
                return result
            end
            return orig(self, enemy, pos)
        end
    end
end

hook.Add("HordeWaveEnd", "Horde_SpecialWaves_End", function()
    ClearActive()
end)

hook.Add("Horde_AllModulesLoaded", "Horde_SpecialWaves_Init", function()
    SW.LoadPresets()
    InstallHooks()
end)
