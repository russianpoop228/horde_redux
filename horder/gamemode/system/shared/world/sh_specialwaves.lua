HORDE = HORDE or {}
HORDE.SpecialWaves = HORDE.SpecialWaves or {}

local SW = HORDE.SpecialWaves

SW.MAX_PRESETS        = 64
SW.MAX_CUSTOM_ENEMIES = 64
SW.MAX_MUTATIONS      = 8
SW.NAME_MAX           = 64
SW.MATERIAL_MAX       = 256
SW.ENEMY_NAME_MAX     = 128

SW.DEFAULT_BANNER = { r = 220, g = 30, b = 56 }

local function ClampNum(v, def, lo, hi)
    v = tonumber(v)
    if v == nil or v ~= v or v == math.huge or v == -math.huge then v = def end
    if lo ~= nil and v < lo then v = lo end
    if hi ~= nil and v > hi then v = hi end
    return v
end

local function ClampInt(v, def, lo, hi)
    return math.floor(ClampNum(v, def, lo, hi))
end

local function CleanStr(v, maxlen)
    if not isstring(v) then return nil end
    v = string.Trim(v)
    if v == "" then return nil end
    if maxlen and #v > maxlen then v = string.sub(v, 1, maxlen) end
    return v
end

local function CleanList(v, maxlen, maxcount)
    local out, seen = {}, {}
    if not istable(v) then return out end
    for _, item in ipairs(v) do
        local s = CleanStr(item, maxlen)
        if s then
            local key = string.lower(s)
            if not seen[key] then
                seen[key] = true
                out[#out + 1] = s
                if maxcount and #out >= maxcount then break end
            end
        end
    end
    return out
end

function SW.NormalizePreset(p)
    if not istable(p) then return nil end

    p.id   = CleanStr(p.id, 64) or ("preset_" .. tostring(math.random(100000, 999999)))
    p.name = CleanStr(p.name, SW.NAME_MAX) or "Unnamed"

    p.min_wave = ClampInt(p.min_wave, 1, 1, 9999)

    p.enemy_source = (p.enemy_source == "custom") and "custom" or "config"
    p.pick_count   = ClampInt(p.pick_count, 1, 1, 64)
    p.custom_enemies = CleanList(p.custom_enemies, SW.ENEMY_NAME_MAX, SW.MAX_CUSTOM_ENEMIES)

    local m = istable(p.mods) and p.mods or {}
    p.mods = m
    m.health_scale = ClampNum(m.health_scale, 1, 0.01, 1000)
    m.damage_scale = ClampNum(m.damage_scale, 1, 0.01, 1000)
    m.reward_scale = ClampNum(m.reward_scale, 1, 0.01, 1000)
    m.model_scale  = ClampNum(m.model_scale,  1, 0.01, 1000)
    m.skin         = ClampInt(m.skin, -1, -1, 999)
    m.mutations    = CleanList(m.mutations, SW.NAME_MAX, SW.MAX_MUTATIONS)
    m.use_color    = (m.use_color == true)
    m.color_r      = ClampInt(m.color_r, 255, 0, 255)
    m.color_g      = ClampInt(m.color_g, 255, 0, 255)
    m.color_b      = ClampInt(m.color_b, 255, 0, 255)
    m.material     = CleanStr(m.material, SW.MATERIAL_MAX) or ""

    local b = istable(p.banner) and p.banner or {}
    p.banner = b
    b.r = ClampInt(b.r, SW.DEFAULT_BANNER.r, 0, 255)
    b.g = ClampInt(b.g, SW.DEFAULT_BANNER.g, 0, 255)
    b.b = ClampInt(b.b, SW.DEFAULT_BANNER.b, 0, 255)

    return p
end

function SW.NewPreset(name)
    return SW.NormalizePreset({
        name     = name or "New Preset",
        min_wave = 1,
        enemy_source = "config",
        pick_count = 2,
        mods = {
            health_scale = 1, damage_scale = 1, reward_scale = 1, model_scale = 1,
            skin = -1, mutations = {}, use_color = false,
            color_r = 255, color_g = 255, color_b = 255, material = "",
        },
        banner = { r = SW.DEFAULT_BANNER.r, g = SW.DEFAULT_BANNER.g, b = SW.DEFAULT_BANNER.b },
    })
end

function SW.SanitizeList(raw)
    local out = {}
    if not istable(raw) then return out end
    for _, p in ipairs(raw) do
        local n = SW.NormalizePreset(p)
        if n then
            out[#out + 1] = n
            if #out >= SW.MAX_PRESETS then break end
        end
    end
    return out
end

function SW.DefaultPresets()
    return SW.SanitizeList({
        {
            id = "preset_clones", name = "CLONES",
            min_wave = 1, enemy_source = "config", pick_count = 1,
            mods = {
                health_scale = 1, damage_scale = 1, reward_scale = 1, model_scale = 1,
                skin = -1, mutations = {}, use_color = true,
                color_r = 80, color_g = 210, color_b = 255, material = "",
            },
            banner = { r = 80, g = 210, b = 255 },
        },
        {
            id = "preset_double_trouble", name = "DOUBLE TROUBLE",
            min_wave = 1, enemy_source = "config", pick_count = 2,
            mods = {
                health_scale = 1, damage_scale = 1, reward_scale = 1, model_scale = 1,
                skin = -1, mutations = {}, use_color = true,
                color_r = 255, color_g = 140, color_b = 30, material = "",
            },
            banner = { r = 255, g = 140, b = 30 },
        },
    })
end
