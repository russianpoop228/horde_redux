if not SERVER then return end
if not HORDE then return end

local pending = {}

HORDE.DifficultyFields = HORDE.DifficultyFields or {
    DamageMult                = { type = "number", desc = "Множитель урона врагов." },
    HealthMult                = { type = "number", desc = "Множитель здоровья врагов." },
    RewardMult                = { type = "number", desc = "Множитель награды за убийство." },
    StartMoneyMult            = { type = "number", desc = "Множитель стартовых денег." },
    EnemyCountMult            = { type = "number", desc = "Множитель числа врагов на волне." },
    SpawnRadiusMult           = { type = "number", desc = "Множитель радиуса спавна." },
    MaxEnemiesScaleFactor     = { type = "number", desc = "Множитель лимита живых врагов." },
    AdditionalPack            = { type = "int",    desc = "Дополнительные враги в паке." },
    AdditionalAmmoboxes       = { type = "int",    desc = "Дополнительные ящики с патронами." },
    AdditionalEnemiesPerSpawn = { type = "int",    desc = "Доп. враги из каждой точки спавна." },
    EnemiesPerSpawnWaveStep   = { type = "int",    desc = "Каждые N волн добавляется врагов из точки." },
    EnemiesPerSpawnWaveAmount = { type = "int",    desc = "Сколько врагов добавляет шаг разгона." },
    EnemiesPerSpawnWaveCap    = { type = "int",    desc = "Потолок разгона врагов из точки." },
    SpawnSpeedMult            = { type = "number", desc = "Множитель скорости спавна (>1 — быстрее)." },
    SpawnInterval             = { type = "number", desc = "Интервал спавна волны в секундах (0 — конвар)." },
    SpawnIntervalWaveStep     = { type = "int",    desc = "Каждые N волн интервал уменьшается." },
    SpawnIntervalWaveAmount   = { type = "number", desc = "На сколько секунд уменьшается интервал." },
    SpawnIntervalWaveCap      = { type = "number", desc = "Минимальный интервал спавна." },
    MaxEnemiesAliveBase       = { type = "int",    desc = "База лимита одновременно живых врагов." },
    MaxEnemiesAlivePerPlayer  = { type = "int",    desc = "Сколько слотов добавляет каждый игрок." },
    MaxEnemiesAliveCap        = { type = "int",    desc = "Потолок лимита живых врагов." },
    StatusDurationBonus       = { type = "number", desc = "Прибавка к длительности статусов." },
    BreakHealthLeft           = { type = "number", desc = "Доля здоровья при «переломе»." },
    ShockDamageIncrease       = { type = "number", desc = "Прибавка урона от шока." },
    FrostbiteSlow             = { type = "number", desc = "Замедление от обморожения." },
    PoisonHeadcrabDamage      = { type = "number", desc = "Урон ядовитого хедкраба." },
    EliteHealthScaleAdd        = { type = "number", desc = "Прибавка здоровья элиты." },
    EliteHealthScaleMultiplier = { type = "number", desc = "Множитель здоровья элиты." },
    MutationProbability        = { type = "number", desc = "Шанс мутации обычного врага." },
    EliteMutationProbability   = { type = "number", desc = "Шанс мутации элитного врага." },
}

function HORDE:GetDifficultyFieldNames()
    local list = {}
    for name in pairs(HORDE.DifficultyFields or {}) do list[#list + 1] = name end
    table.sort(list)
    return list
end

function HORDE:Horde_ResolveDifficultyField(name)
    if not isstring(name) or name == "" then return nil end
    local fields = HORDE.DifficultyFields or {}
    if fields[name] then return name end
    local needle = string.lower(name)
    for field in pairs(fields) do
        if string.lower(field) == needle then return field end
    end
    return nil
end

function HORDE:ParseDifficultyFieldValue(field, value)
    field = HORDE:Horde_ResolveDifficultyField(field)
    local def = field and (HORDE.DifficultyFields or {})[field]
    if not def then return nil end
    local n = tonumber(value)
    if not n or n ~= n then return nil end
    if def.type == "int" then n = math.floor(n) end
    return n
end

function HORDE:Horde_ApplyDifficultyFields(name, fields)
    if not istable(fields) then return false, "no fields" end
    local def = HORDE:FindRegisteredDifficulty(name)
    if not def then return false, "unknown difficulty: " .. tostring(name) end

    local parsed, applied = {}, 0
    for field, value in pairs(fields) do
        local canon = HORDE:Horde_ResolveDifficultyField(field)
        local n = canon and HORDE:ParseDifficultyFieldValue(canon, value)
        if n == nil then
            return false, "unknown or invalid field: " .. tostring(field) .. " = " .. tostring(value)
        end
        parsed[canon] = n
        applied = applied + 1
    end
    if applied == 0 then return false, "no fields" end
    for field, n in pairs(parsed) do def[field] = n end

    HORDE:ApplyDifficultyDefinition(def, true)
    HORDE:ReapplyDifficulty()
    HORDE:BroadcastDifficulty()
    if GetConVar("developer"):GetBool() then
        print(string.format("[HORDE] info_horde_difficulty: %s -> %d field(s) changed",
            tostring(def.Name), applied))
    end
    return true
end

function HORDE:Horde_ResetDifficultyFields(name)
    local def = HORDE:FindRegisteredDifficulty(name)
    if not def then return false, "unknown difficulty: " .. tostring(name) end
    local snapshot = (HORDE._difficulty_file_defaults or {})[def.Name]
    if not snapshot then return false, "no file defaults for: " .. tostring(def.Name) end
    for field, value in pairs(snapshot) do
        def[field] = value
    end
    HORDE:ApplyDifficultyDefinition(def, true)
    HORDE:ReapplyDifficulty()
    HORDE:BroadcastDifficulty()
    return true
end

function HORDE:Horde_CreateCustomDifficulty(name, index, base, fields)
    if not isstring(name) or not string.match(string.upper(name), "^[%a_][%w_]*$") then
        return false, nil, "invalid name: " .. tostring(name)
    end
    name = string.upper(name)

    local existing = HORDE:FindRegisteredDifficulty(name)
    if existing then
        if fields and next(fields) then
            local ok, err = HORDE:Horde_ApplyDifficultyFields(name, fields)
            if not ok then return false, existing.Index, err end
        end
        return true, existing.Index
    end

    if index == nil then
        local max_index = 0
        for i in pairs(HORDE._difficulties or {}) do
            if isnumber(i) and i > max_index then max_index = i end
        end
        index = max_index + 1
    else
        index = math.max(1, math.floor(index))
        if HORDE:FindRegisteredDifficulty(index) then
            return false, nil, "index " .. index .. " is already taken"
        end
    end

    local tbl = { Name = name, Index = index }
    if base and base ~= "" then tbl.Include = string.upper(base) end
    for field, value in pairs(fields or {}) do
        local n = HORDE:ParseDifficultyFieldValue(field, value)
        if n == nil then
            return false, nil, "unknown or invalid field: " .. tostring(field) .. " = " .. tostring(value)
        end
        tbl[field] = n
    end

    HORDE:RegisterDifficulty(tbl)
    print(string.format("[HORDE] info_horde_difficulty: custom difficulty %s (index %d) created",
        name, index))
    return true, index
end

function HORDE:ParseDifficultyFieldArg(arg)
    local field, value = string.match(arg or "", "^%s*([%a_][%w_]*)%s+([%-%d%.]+)%s*$")
    if not field then return nil, nil end
    return HORDE:Horde_ResolveDifficultyField(field) or field, tonumber(value)
end

function HORDE:Horde_ReadDifficultyConfig(ent)
    local cfg = ent.Horde_DiffCfg or {}
    return {
        difficulty = cfg.difficulty,
        modifier   = cfg.modifier,
        base       = cfg.base,
        enabled    = cfg.enabled,
        fields     = cfg.fields,
        name       = cfg.name,
        index      = cfg.index,
        custom     = cfg.custom,
    }
end

function HORDE:Horde_GetConfigTargetName(cfg)
    local name = cfg and (cfg.modifier or cfg.difficulty)
    if name then return name end
    local active = HORDE._difficulties and HORDE._difficulties[HORDE.difficulty]
    return istable(active) and active.Name or nil
end

function HORDE:Horde_ApplyMapDifficulty(cfg)
    cfg = cfg or {}

    local modifier = HORDE:Horde_KeyUpper(cfg.modifier)
    local difficulty = HORDE:Horde_KeyUpper(cfg.difficulty)
    local base = HORDE:Horde_KeyUpper(cfg.base)

    local target = modifier or difficulty
    if not target then
        return false, "neither difficulty nor modifier is set"
    end

    local idx = HORDE:Horde_FindDifficultyIndex(target)
    if not idx then
        return false, "unknown difficulty: " .. tostring(target)
    end

    if base and HORDE.SetVotedDifficultyIncludeBase then
        if modifier then
            HORDE:SetVotedDifficultyIncludeBase(base)
        else
            HORDE:SetVotedDifficultyIncludeBase(nil)
        end
    end

    GetConVar("horde_difficulty"):SetInt(idx - 1)
    HORDE:ReapplyDifficulty()
    HORDE:BroadcastDifficulty()

    local name = (HORDE.difficulty_text or {})[HORDE.difficulty] or target
    print(string.format("[HORDE] Map difficulty applied: %s%s (idx %d)",
        tostring(name),
        modifier and (" modifier=" .. tostring(modifier)) or "",
        HORDE.difficulty))
    return true
end

function HORDE:Horde_SetDifficultyKeyValue(ent, key, value)
    ent.Horde_DiffCfg = ent.Horde_DiffCfg or {}
    local cfg = ent.Horde_DiffCfg

    if key == "difficulty" then
        cfg.difficulty = HORDE:Horde_KeyUpper(value)
    elseif key == "modifier" or key == "mode" then
        cfg.modifier = HORDE:Horde_KeyUpper(value)
    elseif key == "base" or key == "include" then
        cfg.base = HORDE:Horde_KeyUpper(value)
    elseif key == "enabled" or key == "active" then
        cfg.enabled = HORDE:Horde_KeyBool(value, true)
    elseif key == "disabled" then
        cfg.enabled = not HORDE:Horde_KeyBool(value, false)
    elseif key == "name" or key == "customname" then
        cfg.name = value
    elseif key == "index" then
        local n = tonumber(value)
        cfg.index = (n and n >= 1) and math.floor(n) or nil
    elseif key == "custom" or key == "createcustom" then
        cfg.custom = HORDE:Horde_KeyBool(value, false)
    else
        local field = HORDE:Horde_ResolveDifficultyField(key)
        if field then
            if value == nil or string.Trim(tostring(value)) == "" then return end
            local n = HORDE:ParseDifficultyFieldValue(field, value)
            if n == nil then
                print("[HORDE] info_horde_difficulty: invalid value for '" .. key .. "': "
                    .. tostring(value) .. " (number expected) - ignored")
                return
            end
            cfg.fields = cfg.fields or {}
            cfg.fields[field] = n
        end
    end
end

function HORDE:Horde_RegisterDifficultyEntity(ent)
    if not IsValid(ent) then return end
    pending[ent:EntIndex()] = ent
    ent:CallOnRemove("Horde_Hammer_DiffEntityRemoved", function()
        pending[ent:EntIndex()] = nil
    end)
end

function HORDE:Horde_ApplyConfigCustomDifficulty(cfg)
    if not (cfg and cfg.custom and cfg.name and cfg.name ~= "") then return true end

    local ok, index, err = HORDE:Horde_CreateCustomDifficulty(cfg.name, cfg.index, cfg.base, cfg.fields)
    if not ok then
        print("[HORDE] info_horde_difficulty: " .. tostring(err))
        return false, cfg
    end

    cfg.difficulty = string.upper(cfg.name)
    cfg.index = index
    cfg.fields = nil
    cfg.base = nil
    return true, cfg
end

function HORDE:Horde_ApplyConfig(cfg, source)
    local tag = "[HORDE] info_horde_difficulty" .. (source and (" (" .. tostring(source) .. ")") or "") .. ": "

    HORDE:Horde_ApplyConfigCustomDifficulty(cfg)

    if cfg.modifier or cfg.difficulty then
        local ok, err = HORDE:Horde_ApplyMapDifficulty(cfg)
        if not ok then
            print(tag .. tostring(err))
            return false
        end
    end

    if cfg.fields and next(cfg.fields) then
        local target = HORDE:Horde_GetConfigTargetName(cfg)
        local fok, ferr = HORDE:Horde_ApplyDifficultyFields(target, cfg.fields)
        if not fok then
            print(tag .. tostring(ferr))
            return false
        end
    end
    return true
end

local function ApplyPending()
    local list = {}
    for eid, ent in pairs(pending) do
        if IsValid(ent) then
            list[#list + 1] = ent
        else
            pending[eid] = nil
        end
    end
    table.sort(list, function(a, b)
        local ca, cb = HORDE:Horde_ReadDifficultyConfig(a), HORDE:Horde_ReadDifficultyConfig(b)
        local ma = ca.modifier and 1 or 0
        local mb = cb.modifier and 1 or 0
        if ma ~= mb then return ma < mb end
        return a:EntIndex() < b:EntIndex()
    end)

    for _, ent in ipairs(list) do
        local cfg = HORDE:Horde_ReadDifficultyConfig(ent)
        if cfg.enabled == false then
            print("[HORDE] info_horde_difficulty disabled — skipping")
        else
            HORDE:Horde_ApplyConfig(cfg, "map start")
        end
    end
end

hook.Add("Horde_AllModulesLoaded", "Horde_Hammer_DifficultyApply", ApplyPending)

function HORDE:Horde_DifficultyInput(ent, name, args)
    local cfg = HORDE:Horde_ReadDifficultyConfig(ent)
    ent.Horde_DiffCfg = ent.Horde_DiffCfg or {}

    if name == "setdifficulty" then
        cfg.difficulty = HORDE:Horde_KeyUpper(args)
        ent.Horde_DiffCfg.difficulty = cfg.difficulty
    elseif name == "setmodifier" then
        cfg.modifier = HORDE:Horde_KeyUpper(args)
        ent.Horde_DiffCfg.modifier = cfg.modifier
    elseif name == "clearmodifier" then
        cfg.modifier = nil
        ent.Horde_DiffCfg.modifier = nil
    elseif name == "setbase" then
        cfg.base = HORDE:Horde_KeyUpper(args)
        ent.Horde_DiffCfg.base = cfg.base
    elseif name == "createcustom" then
        local cname, cindex, cbase = string.match(args or "", "^(%S+)%s*(%S*)%s*(%S*)$")
        if not cname then
            print("[HORDE] info_horde_difficulty input 'createcustom': usage \"<Name> [Index] [Base]\"")
            return true
        end
        local ok, made_index, err = HORDE:Horde_CreateCustomDifficulty(
            cname, tonumber(cindex), (cbase ~= "" and cbase) or nil, nil)
        if not ok then
            print("[HORDE] info_horde_difficulty input 'createcustom': " .. tostring(err))
            return true
        end
        ent.Horde_DiffCfg.name = string.upper(cname)
        ent.Horde_DiffCfg.index = made_index
        ent.Horde_DiffCfg.difficulty = string.upper(cname)
        return true
    elseif name == "setparameter" or name == "setfield" then
        local field, value = HORDE:ParseDifficultyFieldArg(args)
        if not field or value == nil then
            print("[HORDE] info_horde_difficulty input 'setparameter': usage \"<Field> <Value>\"")
            return true
        end
        ent.Horde_DiffCfg.fields = ent.Horde_DiffCfg.fields or {}
        ent.Horde_DiffCfg.fields[field] = value
        local target = HORDE:Horde_GetConfigTargetName(cfg)
        local ok, err = HORDE:Horde_ApplyDifficultyFields(target, { [field] = value })
        if not ok then
            print("[HORDE] info_horde_difficulty input 'setparameter': " .. tostring(err))
        end
        return true
    elseif name == "resetparameters" or name == "resetfields" then
        local target = HORDE:Horde_GetConfigTargetName(cfg)
        local ok, err = HORDE:Horde_ResetDifficultyFields(target)
        if not ok then
            print("[HORDE] info_horde_difficulty input 'resetparameters': " .. tostring(err))
        end
        ent.Horde_DiffCfg.fields = nil
        return true
    elseif name == "enable" or name == "unhide" then
        cfg.enabled = true
        ent.Horde_DiffCfg.enabled = true
    elseif name == "disable" or name == "hide" then
        cfg.enabled = false
        ent.Horde_DiffCfg.enabled = false
        return true
    elseif name == "toggle" then
        cfg.enabled = not (cfg.enabled ~= false)
        ent.Horde_DiffCfg.enabled = cfg.enabled
        if not cfg.enabled then return true end
    elseif name == "apply" then
    else
        return false
    end

    HORDE:Horde_ApplyConfig(cfg, "input " .. name)
    return true
end
