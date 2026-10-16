HORDE = HORDE or {}
HORDE.enemy_variations = HORDE.enemy_variations or {}

local function lower(s)
    return isstring(s) and string.lower(s) or s
end

function HORDE:RegisterEnemyVariation(tbl)
    if not istable(tbl) then return end
    local parent = tbl.ParentEntity or tbl.parent_entity
    local class  = tbl.Class or tbl.class
    if not isstring(parent) or parent == "" or not isstring(class) or class == "" then
        ErrorNoHaltWithStack("[Horde Enemy Variations] ParentEntity and Class are required\n")
        return
    end
    tbl.ParentEntity = parent
    tbl.Class        = class
    if not isfunction(tbl.Chance) then
        tbl.Chance = tonumber(tbl.Chance or tbl.chance) or 0
    end

    for _, existing in ipairs(HORDE.enemy_variations) do
        if lower(existing.ParentEntity) == lower(parent) and lower(existing.Class) == lower(class) then
            return existing
        end
    end

    HORDE.enemy_variations[#HORDE.enemy_variations + 1] = tbl
    hook.Run("Horde_OnEnemyVariationRegistered", tbl)
    return tbl
end

function HORDE:BuildVariantEnemy(enemy, variation)
    local variant = table.Copy(enemy)
    local overrides = variation.Overrides
    if istable(overrides) then
        for k, v in pairs(overrides) do
            variant[k] = istable(v) and table.Copy(v) or v
        end
    end
    variant.class      = variation.Class
    variant.name       = variation.Name or enemy.name
    variant.variant_of = enemy.class
    variant._variation = variation
    return variant
end

function HORDE:GetVariationChance(variation, enemy)
    local chance = variation.Chance
    if isfunction(chance) then
        local ok, result = pcall(chance, enemy)
        chance = ok and tonumber(result) or nil
    end
    return tonumber(chance) or 0
end

local function CurrentDifficultyName()
    if HORDE.ResolveDifficultyName then
        local name = HORDE:ResolveDifficultyName(HORDE.difficulty)
        if name then return name end
    end
    local name = HORDE.difficulty_text and HORDE.difficulty_text[HORDE.difficulty]
    if not name then
        local data = HORDE._difficulties and HORDE._difficulties[HORDE.difficulty]
        name = istable(data) and data.Name or nil
    end
    return isstring(name) and string.upper(name) or nil
end

local function DifficultyInclude(ref)
    if not HORDE.FindRegisteredDifficulty then return nil end
    local data = HORDE:FindRegisteredDifficulty(ref)
    if not istable(data) then return nil end
    local override = HORDE.GetDifficultyOverride and HORDE:GetDifficultyOverride(data)
    if override ~= nil then return override end
    if HORDE.GetDifficultyInclude then return HORDE:GetDifficultyInclude(data) end
    return nil
end

local function IsDifficultyBasedOn(name, base, depth)
    if not isstring(name) or not isstring(base) then return false end
    name, base = string.upper(name), string.upper(base)
    if name == base then return true end
    if (depth or 0) >= 8 then return false end

    local include = DifficultyInclude(name)
    if isnumber(include) then
        local data = HORDE:FindRegisteredDifficulty(include)
        include = istable(data) and data.Name or nil
    end
    if not isstring(include) then return false end
    return IsDifficultyBasedOn(include, base, (depth or 0) + 1)
end

function HORDE:GetVariationMinWave(variation)
    local appearance = variation and variation.Appearance
    if not istable(appearance) then return 0 end

    local name = CurrentDifficultyName()
    if not name then return nil end

    local exact = appearance.Difficulties
    if istable(exact) then
        local since_wave = exact[HORDE.difficulty]
        if since_wave == nil then
            for key, value in pairs(exact) do
                if isstring(key) and string.upper(key) == name then
                    since_wave = value
                    break
                end
            end
        end
        if since_wave ~= nil then
            if since_wave == false then return nil end
            if since_wave == true then return 0 end
            return math.max(0, tonumber(since_wave) or 0)
        end
    end

    local bases = appearance.BasedOn
    if isstring(bases) then bases = { bases } end
    if istable(bases) then
        for _, base in ipairs(bases) do
            if IsDifficultyBasedOn(name, base) then
                return math.max(0, tonumber(appearance.SinceWave) or 0)
            end
        end
    end
    return nil
end

function HORDE:IsVariationAllowed(variation)
    local min_wave = HORDE:GetVariationMinWave(variation)
    if min_wave == nil then return false end
    return (tonumber(HORDE.current_wave) or 0) >= min_wave
end

function HORDE:MakeDifficultyChance(cfg)
    cfg = istable(cfg) and cfg or {}
    local base = tonumber(cfg.base) or 0
    local boosted = tonumber(cfg.boosted) or base
    local from_wave = tonumber(cfg.boosted_from_wave) or 0
    local difficulties = istable(cfg.boosted_difficulties) and cfg.boosted_difficulties or {}

    return function()
        local name = CurrentDifficultyName()
        if not name then return base end
        if difficulties[name] then
            if (HORDE.IsWave666DifficultyName and HORDE:IsWave666DifficultyName(name))
                or (tonumber(HORDE.current_wave) or 0) >= from_wave then
                return boosted
            end
        end
        return base
    end
end

function HORDE:ResolveEnemyVariant(enemy)
    if not istable(enemy) or not isstring(enemy.class) then return nil end
    local list = HORDE.enemy_variations
    if not list or #list == 0 then return nil end

    local class = lower(enemy.class)

    local applicable = {}
    local total = 0
    for _, variation in ipairs(list) do
        if lower(variation.ParentEntity) == class then
            local chance = math.Clamp(HORDE:GetVariationChance(variation, enemy), 0, 1)
            if chance > 0 and HORDE:IsVariationAllowed(variation) then
                local passes = true
                if variation.Condition then
                    local ok, result = pcall(variation.Condition, enemy)
                    passes = ok and (result ~= false)
                end
                if passes then
                    applicable[#applicable + 1] = { variation = variation, chance = chance }
                    total = total + chance
                end
            end
        end
    end
    if total <= 0 then return nil end

    local scale = total > 1 and (1 / total) or 1
    local roll = math.random()
    local cumulative = 0
    for _, entry in ipairs(applicable) do
        cumulative = cumulative + entry.chance * scale
        if roll <= cumulative then
            return HORDE:BuildVariantEnemy(enemy, entry.variation)
        end
    end
    return nil
end

if SERVER and not HORDE._EnemyVariationWrapped then
    HORDE._EnemyVariationWrapped = true
    local base_spawn = HORDE.SpawnEnemy
    if isfunction(base_spawn) then
        function HORDE:SpawnEnemy(enemy, pos)
            local variant = HORDE:ResolveEnemyVariant(enemy)
            return base_spawn(self, variant or enemy, pos)
        end
    else
        ErrorNoHaltWithStack("[Horde Enemy Variations] HORDE.SpawnEnemy not found; variations disabled\n")
    end
end
