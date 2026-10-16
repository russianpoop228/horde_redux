if not HORDE then return end

local HAMMER_ENTITY_DEFS = {

    info_horde_enemy_spawn = {
        kind = "point", category = "spawn",
        desc = "Точка спавна обычных врагов. Включение/выключение работает и во время игры.",
        keys   = { "disabled", "weight", "wave", "lastwave", "max", "cooldown", "zoffset" },
        inputs = { "Enable", "Disable", "Toggle" },
    },
    info_horde_boss_spawn = {
        kind = "point", category = "spawn",
        desc = "Точка спавна боссов. Босс гарантированно появляется на активной босс-точке.",
        keys   = { "disabled", "boss", "wave", "lastwave", "zoffset" },
        inputs = { "Enable", "Disable", "Toggle" },
    },
    info_horde_ammobox_spawn = {
        kind = "point", category = "spawn",
        desc = "Точка спавна ящиков с патронами.",
        keys   = { "disabled" },
        inputs = { "Enable", "Disable", "Toggle" },
    },
    info_horde_spawn_distribution_uniform = {
        kind = "point", category = "spawn",
        desc = "Распределение спавна: равномерно по всем точкам карты.",
        keys   = {},
        inputs = {},
    },
    info_horde_spawn_distribution_proximity = {
        kind = "point", category = "spawn",
        desc = "Распределение спавна: по близости к игрокам (по умолчанию).",
        keys   = {},
        inputs = {},
    },
    info_horde_spawn_distribution_proximity_noisy = {
        kind = "point", category = "spawn",
        desc = "Распределение спавна: по близости к игрокам + шум (иногда далёкие точки).",
        keys   = {},
        inputs = {},
    },

    info_horde_buildable = {
        kind = "point", category = "spawn",
        desc = "Спавнит вечную постройку Инженера/Надзирателя без владельца.",
        keys   = { "buildable", "health", "ammo", "infinite_ammo", "level", "relationship", "spawn_on_start" },
        inputs = { "Spawn", "Kill", "SetHealth", "SetAmmo", "SetRelationship" },
    },
    info_horde_difficulty = {
        kind = "point", category = "difficulty",
        desc = "Задаёт сложность и/или модификатор и ЛЮБЫЕ их параметры: при старте карты и через Input'ы (можно создавать свои сложности).",
        keys   = { "difficulty", "modifier", "base", "enabled", "custom", "name", "index",
                   "damagemult", "healthmult", "rewardmult", "startmoneymult",
                   "enemycountmult", "spawnradiusmult", "maxenemiesscalefactor",
                   "additionalpack", "additionalammoboxes", "additionalenemiesperspawn",
                   "enemiesperspawnwavestep", "enemiesperspawnwaveamount", "enemiesperspawnwavecap",
                   "spawnspeedmult", "spawninterval",
                   "spawnintervalwavestep", "spawnintervalwaveamount", "spawnintervalwavecap",
                   "maxenemiesalivebase", "maxenemiesaliveperplayer", "maxenemiesalivecap",
                   "statusdurationbonus", "breakhealthleft", "shockdamageincrease",
                   "frostbiteslow", "poisonheadcrabdamage",
                   "elitehealthscaleadd", "elitehealthscalemultiplier",
                   "mutationprobability", "elitemutationprobability" },
        inputs = { "SetDifficulty", "SetModifier", "ClearModifier", "SetBase", "SetParameter",
                   "ResetParameters", "CreateCustom", "Apply" },
    },
    info_horde_token_spawn = {
        kind = "point", category = "token",
        desc = "Спавнит деньги, черепа или металл. Управляется через Input Spawn.",
        keys   = { "token", "amount", "lifetime", "spawn_on_start" },
        inputs = { "Spawn", "Kill", "SetAmount" },
    },

    logic_horde_waves = {
        kind = "point", category = "logic",
        desc = "Ручное управление волнами (AdvanceWave / EndWave / SetWave).",
        keys   = { "wave" },
        inputs = { "AdvanceWave", "EndWave", "SetWave", "SetWaves", "SetWaveStart" },
    },
    logic_horde_economy = {
        kind = "point", category = "logic",
        desc = "Переопределение стартовых денег и наград карты.",
        keys   = { "startingmoney", "killrewardbase", "roundbonusbase" },
        inputs = { "SetStartingMoney", "SetKillRewardBase", "SetRoundBonusBase" },
    },
    logic_horde_achievement = {
        kind = "point", category = "logic",
        desc = "Выдаёт достижение игроку по Input'у.",
        keys   = { "achievement", "description" },
        inputs = { "ActivateAchievement" },
    },

    trigger_horde_holdzone = {
        kind = "brush", category = "objective",
        desc = "Зона удержания. Группа зон — одно независимое задание со своей полосой; " ..
               "зона может ездить на родителе (SetParent), быть цилиндром (shape 1) и " ..
               "совмещаться с доставкой груза через общий link.",
        keys   = { "wave", "group", "label", "combine", "link", "shape", "radius", "height", "parent", "fixedorientation", "disabled" },
        inputs = { "Enable", "Disable", "Toggle", "SetParent", "SetGroup", "SetLink", "SetShape", "SetRadius", "SetFixedOrientation" },
    },
    trigger_horde_payload_destination = {
        kind = "brush", category = "objective",
        desc = "Точка доставки груза. combine — все триггеры группы активны вместе.",
        keys   = { "wave", "group", "combine", "disabled" },
        inputs = { "Enable", "Disable", "Toggle" },
    },
    info_horde_payload_spawn = {
        kind = "point", category = "objective",
        desc = "Точка появления груза. link связывает груз с зоной удержания в одно задание " ..
               "(удержание + доставка), combine — все грузы группы работают вместе.",
        keys   = { "wave", "group", "label", "model", "icon", "mass", "combine", "link", "disabled" },
        inputs = { "Enable", "Disable", "Toggle", "SetGroup", "SetLink" },
    },
    trigger_horde_escapezone = {
        kind = "brush", category = "objective",
        desc = "Зона эвакуации: вход в неё завершает забег победой.",
        keys   = { "group", "disabled" },
        inputs = { "Enable", "Disable", "Toggle" },
    },
    trigger_horde_buyzone = {
        kind = "brush", category = "objective",
        desc = "Зона покупки: в ней открыт магазин.",
        keys   = {},
        inputs = {},
    },
}

HORDE.HammerEntityDefs = HORDE.HammerEntityDefs or {}

for class, def in pairs(HAMMER_ENTITY_DEFS) do
    def.class = class
    HORDE.HammerEntityDefs[class] = def
end

function HORDE:GetHammerEntities()
    local list = {}
    for _, def in pairs(HORDE.HammerEntityDefs) do
        list[#list + 1] = def
    end
    table.sort(list, function(a, b)
        if a.category ~= b.category then return tostring(a.category) < tostring(b.category) end
        return tostring(a.class) < tostring(b.class)
    end)
    return list
end

function HORDE:IsHammerEntity(class)
    return (HORDE.HammerEntityDefs[class] ~= nil)
end

function HORDE:GetHammerEntity(class)
    return HORDE.HammerEntityDefs[class]
end

function HORDE:Horde_KeyNumber(value, default)
    if value == nil then return default end
    local n = tonumber(value)
    if n == nil then return default end
    return n
end

function HORDE:Horde_KeyBool(value, default)
    if value == nil or value == "" then return default end
    if isbool(value) then return value end
    local s = string.lower(tostring(value))
    if s == "1" or s == "true" or s == "yes" or s == "on" then return true end
    if s == "0" or s == "false" or s == "no" or s == "off" then return false end
    return default
end

function HORDE:Horde_KeyUpper(value)
    if value == nil then return nil end
    local s = tostring(value)
    if s == "" then return nil end
    return string.upper(s)
end

HORDE.HammerRelation = HORDE.HammerRelation or {
    FRIENDLY = 0,
    NEUTRAL  = 1,
    ENEMY    = 2,
}

HORDE.HammerRelationNames = HORDE.HammerRelationNames or {
    [0] = "Friendly",
    [1] = "Neutral",
    [2] = "Enemy",
}

function HORDE:Horde_ParseHammerRelation(value, default)
    if value == nil or value == "" then return default end
    local n = tonumber(value)
    if n ~= nil then
        return math.Clamp(math.floor(n), 0, 2)
    end
    local s = string.lower(tostring(value))
    if s == "friendly" or s == "ally" or s == "player" then return 0 end
    if s == "neutral" or s == "none" then return 1 end
    if s == "enemy" or s == "hostile" then return 2 end
    return default
end

function HORDE:Horde_GetHammerRelationName(relation)
    return HORDE.HammerRelationNames[relation] or "Unknown"
end

HORDE.HammerToken = HORDE.HammerToken or {
    MONEY = "money",
    SKULL = "skull",
    METAL = "metal",
}

HORDE.HammerTokenOrder = HORDE.HammerTokenOrder or { "money", "skull", "metal" }

function HORDE:Horde_ParseHammerToken(value, default)
    if value == nil or value == "" then return default end
    local n = tonumber(value)
    if n ~= nil then
        return HORDE.HammerTokenOrder[math.floor(n) + 1] or default
    end
    local s = string.lower(tostring(value))
    if s == "money" or s == "cash" or s == "dosh" then return HORDE.HammerToken.MONEY end
    if s == "skull" or s == "skulls" or s == "skull_token" then return HORDE.HammerToken.SKULL end
    if s == "metal" or s == "scrap" then return HORDE.HammerToken.METAL end
    return default
end

function HORDE:IsMapBuildable(ent)
    if not IsValid(ent) then return false end
    if ent.Horde_MapBuildable == true then return true end
    if ent.GetNWBool and ent:GetNWBool("Horde_MapBuildable", false) then return true end
    return false
end

function HORDE:Horde_MarkMapBuildable(ent, on)
    if not IsValid(ent) then return end
    ent.Horde_MapBuildable = (on ~= false) and true or nil
    ent:SetNWBool("Horde_MapBuildable", on ~= false)
end

function HORDE:Horde_FindDifficultyIndex(name)
    if not isstring(name) or name == "" then return nil end
    local needle = string.upper(name)
    for idx, def in pairs(HORDE._difficulties or {}) do
        if istable(def) and isstring(def.Name) and string.upper(def.Name) == needle then
            return idx
        end
    end
    return nil
end

function HORDE:Horde_IsDifficultyModifier(name)
    if HORDE.FindRegisteredDifficulty then
        local def = HORDE:FindRegisteredDifficulty(name)
        if istable(def) and HORDE.IsModifier then
            return HORDE:IsModifier(def) == true
        end
    end
    return false
end

function HORDE:Horde_GetBaseDifficultyNames()
    local list = {}
    for _, def in pairs(HORDE._difficulties or {}) do
        if istable(def) and isstring(def.Name) and not HORDE:Horde_IsDifficultyModifier(def.Name) then
            list[#list + 1] = def.Name
        end
    end
    table.sort(list)
    return list
end

function HORDE:Horde_GetModifierNames()
    local list = {}
    for _, def in pairs(HORDE._difficulties or {}) do
        if istable(def) and isstring(def.Name) and HORDE:Horde_IsDifficultyModifier(def.Name) then
            list[#list + 1] = def.Name
        end
    end
    table.sort(list)
    return list
end
