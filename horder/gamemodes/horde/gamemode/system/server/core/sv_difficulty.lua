HORDE.difficulty = 1
HORDE.additional_pack = 0

local DEFAULTS = {
    [1] = { Name="CASUAL",     DamageMult=1.0,   HealthMult=1.0,   RewardMult=1.0,  EnemyCountMult=1.0,   StartMoneyMult=1.0,  SpawnRadiusMult=1.0,  MaxEnemiesScaleFactor=1.0,   PoisonHeadcrabDamage=50, StatusDurationBonus=0, BreakHealthLeft=0.20, ShockDamageIncrease=0.15, FrostbiteSlow=0.40, EliteHealthScaleAdd=0.025, EliteHealthScaleMultiplier=1.0, AdditionalPack=0, AdditionalAmmoboxes=2, MutationProbability=0,    EliteMutationProbability=0    },
    [2] = { Name="NIGHTMARE",  DamageMult=1.7,   HealthMult=1.5,   RewardMult=0.5,  EnemyCountMult=1.6,   StartMoneyMult=0.75, SpawnRadiusMult=0.5,  MaxEnemiesScaleFactor=1.25,  PoisonHeadcrabDamage=75, StatusDurationBonus=3, BreakHealthLeft=0.10, ShockDamageIncrease=0.25, FrostbiteSlow=0.50, EliteHealthScaleAdd=0.100, EliteHealthScaleMultiplier=1.1, AdditionalPack=2, AdditionalAmmoboxes=0, MutationProbability=0.20, EliteMutationProbability=0.30 },
    [3] = { Name="APOCALYPSE", DamageMult=1.9,   HealthMult=1.5,   RewardMult=0.4,  EnemyCountMult=1.7,   StartMoneyMult=0.6,  SpawnRadiusMult=0.4,  MaxEnemiesScaleFactor=1.3,   PoisonHeadcrabDamage=75, StatusDurationBonus=4, BreakHealthLeft=0.05, ShockDamageIncrease=0.30, FrostbiteSlow=0.55, EliteHealthScaleAdd=0.125, EliteHealthScaleMultiplier=1.2, AdditionalPack=3, AdditionalAmmoboxes=0, MutationProbability=0.30, EliteMutationProbability=0.40 },
    [4] = { Name="CHAOS",      DamageMult=2.185, HealthMult=1.725, RewardMult=0.348, EnemyCountMult=1.955, StartMoneyMult=0.522, SpawnRadiusMult=0.6, MaxEnemiesScaleFactor=1.495, PoisonHeadcrabDamage=90, StatusDurationBonus=5, BreakHealthLeft=0.04, ShockDamageIncrease=0.35, FrostbiteSlow=0.60, EliteHealthScaleAdd=0.145, EliteHealthScaleMultiplier=1.38, AdditionalPack=4, AdditionalAmmoboxes=0, MutationProbability=0.45, EliteMutationProbability=0.55 },
    [5] = { Name="BOSS_RUSH", IsModifier=true,  DamageMult=2.185, HealthMult=1.725, RewardMult=0.46, EnemyCountMult=1.955, StartMoneyMult=0.69, SpawnRadiusMult=0.46, MaxEnemiesScaleFactor=1.495, PoisonHeadcrabDamage=90, StatusDurationBonus=5, BreakHealthLeft=0.04, ShockDamageIncrease=0.35, FrostbiteSlow=0.60, EliteHealthScaleAdd=0.145, EliteHealthScaleMultiplier=1.38, AdditionalPack=4, AdditionalAmmoboxes=0, MutationProbability=0.45, EliteMutationProbability=0.55 },
    [6] = { Name="UNARMED", IsModifier=true,    DamageMult=2.185, HealthMult=1.725, RewardMult=0.348, EnemyCountMult=1.955, StartMoneyMult=0.522, SpawnRadiusMult=0.6, MaxEnemiesScaleFactor=1.495, PoisonHeadcrabDamage=90, StatusDurationBonus=5, BreakHealthLeft=0.04, ShockDamageIncrease=0.35, FrostbiteSlow=0.60, EliteHealthScaleAdd=0.145, EliteHealthScaleMultiplier=1.38, AdditionalPack=4, AdditionalAmmoboxes=0, MutationProbability=0.45, EliteMutationProbability=0.55, IsUnarmed=true, MaxWaves=15, ScalePerWave=0.5/15 },
    [7] = { Name="HUNDRED", IsModifier=true,    DamageMult=1.9,   HealthMult=1.5,   RewardMult=0.4,  EnemyCountMult=1.7,   StartMoneyMult=0.6,  SpawnRadiusMult=0.4,  MaxEnemiesScaleFactor=1.3,   PoisonHeadcrabDamage=75, StatusDurationBonus=4, BreakHealthLeft=0.05, ShockDamageIncrease=0.30, FrostbiteSlow=0.55, EliteHealthScaleAdd=0.125, EliteHealthScaleMultiplier=1.2, AdditionalPack=3, AdditionalAmmoboxes=0, MutationProbability=0.30, EliteMutationProbability=0.40, IsHundred=true, MaxWaves=100, ScalePerWave=0.10 },
    [8] = { Name="PURISM", IsModifier=true,     DamageMult=2.185, HealthMult=1.725, RewardMult=0.348, EnemyCountMult=1.955, StartMoneyMult=0.522, SpawnRadiusMult=0.6, MaxEnemiesScaleFactor=1.495, PoisonHeadcrabDamage=90, StatusDurationBonus=5, BreakHealthLeft=0.04, ShockDamageIncrease=0.35, FrostbiteSlow=0.60, EliteHealthScaleAdd=0.145, EliteHealthScaleMultiplier=1.38, AdditionalPack=4, AdditionalAmmoboxes=0, MutationProbability=0.45, EliteMutationProbability=0.55, IsPurism=true, MaxWaves=10 },
}

local function ResolveDifficultyIndex()
    local idx = GetConVar("horde_difficulty"):GetInt() + 1
    if (HORDE._difficulties and HORDE._difficulties[idx]) or DEFAULTS[idx] then return idx end
    return math.Clamp(idx, 1, #DEFAULTS)
end

HORDE.difficulty = ResolveDifficultyIndex()

local function GetDiffData(index)
    local base = (HORDE._difficulties and HORDE._difficulties[index])
        or DEFAULTS[index]
        or DEFAULTS[1]
    if not istable(base) then return base end

    local ov = HORDE.difficulty_basics_overrides and base.Name
        and HORDE.difficulty_basics_overrides[base.Name]
    if not istable(ov) then return base end

    local merged = {}
    for k, v in pairs(base) do merged[k] = v end
    for k, v in pairs(ov) do
        if k ~= "Name" and k ~= "Index" and k ~= "Hooks" then
            local n = tonumber(v)
            if n == nil then
                merged[k] = v
            elseif n == n and n ~= math.huge and n ~= -math.huge then
                merged[k] = n
            end
        end
    end
    return merged
end

HORDE.difficulty_health_multiplier             = {}
HORDE.difficulty_reward_base_multiplier        = {}
HORDE.difficulty_status_duration_bonus         = {}
HORDE.difficulty_break_health_left             = {}
HORDE.difficulty_shock_damage_increase         = {}
HORDE.difficulty_frostbite_slow                = {}
HORDE.difficulty_elite_health_scale_add        = {}
HORDE.difficulty_elite_health_scale_multiplier = {}
HORDE.difficulty_additional_pack               = {}
HORDE.difficulty_additional_ammoboxes          = {}
HORDE.difficulty_additional_enemies_per_spawn  = {}
HORDE.difficulty_spawn_speed_mult              = {}
HORDE.difficulty_spawn_interval                = {}
HORDE.difficulty_mutation_probability          = {}
HORDE.difficulty_elite_mutation_probability    = {}
HORDE.difficulty_text                          = {}

for i, d in pairs(DEFAULTS) do
    HORDE.difficulty_health_multiplier[i]              = d.HealthMult
    HORDE.difficulty_reward_base_multiplier[i]         = d.RewardMult
    HORDE.difficulty_status_duration_bonus[i]          = d.StatusDurationBonus
    HORDE.difficulty_break_health_left[i]              = d.BreakHealthLeft
    HORDE.difficulty_shock_damage_increase[i]          = d.ShockDamageIncrease
    HORDE.difficulty_frostbite_slow[i]                 = d.FrostbiteSlow
    HORDE.difficulty_elite_health_scale_add[i]         = d.EliteHealthScaleAdd
    HORDE.difficulty_elite_health_scale_multiplier[i]  = d.EliteHealthScaleMultiplier
    HORDE.difficulty_additional_pack[i]                = d.AdditionalPack
    HORDE.difficulty_additional_ammoboxes[i]           = d.AdditionalAmmoboxes
    HORDE.difficulty_additional_enemies_per_spawn[i]   = d.AdditionalEnemiesPerSpawn or 0
    HORDE.difficulty_spawn_speed_mult[i]               = d.SpawnSpeedMult or 1
    HORDE.difficulty_spawn_interval[i]                 = d.SpawnInterval
    HORDE.difficulty_mutation_probability[i]           = d.MutationProbability
    HORDE.difficulty_elite_mutation_probability[i]     = d.EliteMutationProbability
    HORDE.difficulty_text[i]                           = d.Name
end

function HORDE:IsExtendedWave()
    return HORDE.extended_waves == true and HORDE.current_wave > HORDE.max_max_waves
end

local cv_include_base = CreateConVar(
    "horde_difficulty_include_base",
    "",
    { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED },
    "Base difficulty name used as Include for the active modifier (set by map vote)."
)

function HORDE:GetVotedDifficultyIncludeBase()
    local s = cv_include_base:GetString()
    if not isstring(s) or s == "" then return nil end
    return string.upper(s)
end

function HORDE:SetVotedDifficultyIncludeBase(name)
    if isstring(name) and name ~= "" then
        cv_include_base:SetString(string.upper(name))
    else
        cv_include_base:SetString("")
    end
end

function HORDE:ResolveDifficultyBase(def)
    if not istable(def) then return nil end

    if HORDE.IsModifier and not HORDE:IsModifier(def) then return nil end

    local override = HORDE.GetDifficultyOverride and HORDE:GetDifficultyOverride(def)
    if override ~= nil then return override, "override" end

    local voted = HORDE:GetVotedDifficultyIncludeBase()
    if voted then return voted, "vote" end

    local file_include = HORDE._difficulty_file_include
        and HORDE._difficulty_file_include[def.Name]
    if file_include ~= nil then return file_include, "include" end

    if HORDE.IsModifier and HORDE:IsModifier(def) then
        return HORDE.DEFAULT_MODIFIER_BASE, "default"
    end
    return nil
end

function HORDE:ApplyVotedDifficultyInclude()
    local idx = HORDE.difficulty
    local def = HORDE._difficulties and HORDE._difficulties[idx]
    if not istable(def) or not isstring(def.Name) then return false end

    local ref, source = HORDE:ResolveDifficultyBase(def)
    if ref == nil then return false end

    local base = HORDE.FindRegisteredDifficulty and HORDE:FindRegisteredDifficulty(ref)
    if not istable(base) or base == def then
        print("[Horde Difficulty] Base '" .. tostring(ref) .. "' (" .. source .. ") for "
            .. def.Name .. " not found")
        local file_include = (source ~= "include") and HORDE._difficulty_file_include
            and HORDE._difficulty_file_include[def.Name] or nil
        base = file_include ~= nil and HORDE:FindRegisteredDifficulty(file_include) or nil
        if not istable(base) or base == def then
            base = HORDE:FindRegisteredDifficulty(HORDE.DEFAULT_MODIFIER_BASE)
        end
        source = "fallback"
    end
    if not istable(base) or base == def then return false end

    if not HORDE.RebaseDifficultyInclude then return false end

    local ok = HORDE:RebaseDifficultyInclude(def.Name, base.Name)
    if ok then
        print(string.format("[Horde Difficulty] %s Include → %s (%s)", def.Name, base.Name, source))
    end
    return ok
end

local function ApplyDifficulty()
    local idx = HORDE.difficulty

    if HORDE.ResolvePendingDifficultyIncludes then
        HORDE:ResolvePendingDifficultyIncludes()
    end

    if HORDE.ApplyVotedDifficultyInclude then
        HORDE:ApplyVotedDifficultyInclude()
    end

    HORDE.difficulty_base_name = nil
    do
        local def = HORDE._difficulties and HORDE._difficulties[idx]
        if istable(def) and HORDE.GetDifficultyInclude then
            local inc = HORDE:GetDifficultyInclude(def)
            local base = inc ~= nil and HORDE.FindRegisteredDifficulty and HORDE:FindRegisteredDifficulty(inc)
            if istable(base) and base ~= def then HORDE.difficulty_base_name = base.Name end
        end
    end

    local index_set = {}
    for i in pairs(HORDE._difficulties or {}) do index_set[i] = true end
    for i in pairs(DEFAULTS) do index_set[i] = true end
    index_set[idx] = true

    for i in pairs(index_set) do
        local di = GetDiffData(i)
        HORDE.difficulty_health_multiplier[i]              = di.HealthMult
        HORDE.difficulty_reward_base_multiplier[i]         = di.RewardMult
        HORDE.difficulty_status_duration_bonus[i]          = di.StatusDurationBonus
        HORDE.difficulty_break_health_left[i]              = di.BreakHealthLeft
        HORDE.difficulty_shock_damage_increase[i]          = di.ShockDamageIncrease
        HORDE.difficulty_frostbite_slow[i]                 = di.FrostbiteSlow
        HORDE.difficulty_elite_health_scale_add[i]         = di.EliteHealthScaleAdd
        HORDE.difficulty_elite_health_scale_multiplier[i]  = di.EliteHealthScaleMultiplier
        HORDE.difficulty_additional_pack[i]                = di.AdditionalPack
        HORDE.difficulty_additional_ammoboxes[i]           = di.AdditionalAmmoboxes
        HORDE.difficulty_additional_enemies_per_spawn[i]   = di.AdditionalEnemiesPerSpawn or 0
        HORDE.difficulty_spawn_speed_mult[i]               = di.SpawnSpeedMult or 1
        HORDE.difficulty_spawn_interval[i]                 = di.SpawnInterval
        HORDE.difficulty_mutation_probability[i]           = di.MutationProbability
        HORDE.difficulty_elite_mutation_probability[i]     = di.EliteMutationProbability
        HORDE.difficulty_text[i]                           = di.Name
    end

    local d = GetDiffData(idx)

    HORDE.difficulty_health_multiplier[idx]              = d.HealthMult
    HORDE.difficulty_reward_base_multiplier[idx]         = d.RewardMult
    HORDE.difficulty_status_duration_bonus[idx]          = d.StatusDurationBonus
    HORDE.difficulty_break_health_left[idx]              = d.BreakHealthLeft
    HORDE.difficulty_shock_damage_increase[idx]          = d.ShockDamageIncrease
    HORDE.difficulty_frostbite_slow[idx]                 = d.FrostbiteSlow
    HORDE.difficulty_elite_health_scale_add[idx]         = d.EliteHealthScaleAdd
    HORDE.difficulty_elite_health_scale_multiplier[idx]  = d.EliteHealthScaleMultiplier
    HORDE.difficulty_additional_pack[idx]                = d.AdditionalPack
    HORDE.difficulty_additional_ammoboxes[idx]           = d.AdditionalAmmoboxes
    HORDE.difficulty_additional_enemies_per_spawn[idx]   = d.AdditionalEnemiesPerSpawn or 0
    HORDE.difficulty_spawn_speed_mult[idx]               = d.SpawnSpeedMult or 1
    HORDE.difficulty_spawn_interval[idx]                 = d.SpawnInterval
    HORDE.difficulty_mutation_probability[idx]           = d.MutationProbability
    HORDE.difficulty_elite_mutation_probability[idx]     = d.EliteMutationProbability
    HORDE.difficulty_text[idx]                           = d.Name

    HORDE._orig_total_enemies_per_wave = HORDE._orig_total_enemies_per_wave or {}
    if #HORDE._orig_total_enemies_per_wave == 0 then
        for i, v in ipairs(HORDE.total_enemies_per_wave) do
            HORDE._orig_total_enemies_per_wave[i] = v
        end
    end
    HORDE._orig_kill_reward_base  = HORDE._orig_kill_reward_base  or HORDE.kill_reward_base
    HORDE._orig_round_bonus_base  = HORDE._orig_round_bonus_base  or HORDE.round_bonus_base
    HORDE._orig_start_money       = HORDE._orig_start_money       or HORDE.start_money
    HORDE._orig_spawn_radius      = HORDE._orig_spawn_radius      or HORDE.spawn_radius

    for i, v in ipairs(HORDE._orig_total_enemies_per_wave) do
        HORDE.total_enemies_per_wave[i] = math.floor(v * d.EnemyCountMult)
    end
    HORDE.kill_reward_base  = math.floor(HORDE._orig_kill_reward_base * d.RewardMult)
    HORDE.round_bonus_base  = math.floor(HORDE._orig_round_bonus_base * d.RewardMult)
    HORDE.start_money       = math.floor(HORDE._orig_start_money      * d.StartMoneyMult)
    HORDE.spawn_radius      = math.floor(HORDE._orig_spawn_radius     * d.SpawnRadiusMult)
    HORDE.difficulty_max_enemies_alive_scale_factor = d.MaxEnemiesScaleFactor

    HORDE.hundred_mode = false
    HORDE.unarmed_mode = false
    HORDE.wave666_mode = false
    HORDE.purism_mode = false
    HORDE.budget_mode = false
    HORDE.hundred_scale_per_wave = 0
    HORDE.victory_skulls = nil
    HORDE.defeat_skulls  = nil

    if d.IsBudget then
        HORDE.budget_mode           = true
        HORDE.budget_money_per_drop = d.BudgetMoneyPerDrop or 150
        HORDE.budget_skull_chance   = d.BudgetSkullChance or 0.2
        HORDE.budget_skull_amount   = d.BudgetSkullAmount or 1
        HORDE.budget_drop_lifetime  = d.BudgetDropLifetime or 45
        HORDE.budget_drop_model     = d.BudgetDropModel
        HORDE.budget_boss_money_min = d.BudgetBossMoneyMin or 1000
        HORDE.budget_boss_money_max = d.BudgetBossMoneyMax or 1500
    end

    if d.IsHundred then
        HORDE.max_waves = d.MaxWaves or 100
        HORDE.hundred_scale_per_wave = d.ScalePerWave or 0.10
        HORDE.hundred_mode = true
    elseif d.IsUnarmed then
        HORDE.max_waves = d.MaxWaves or 15
        HORDE.hundred_scale_per_wave = d.ScalePerWave or (0.5 / 15)
        HORDE.unarmed_mode = true
    elseif d.IsPurism then
        HORDE.max_waves = d.MaxWaves or 10
        HORDE.purism_mode = true
    elseif d.IsWave666 then
        HORDE.max_waves = d.MaxWaves or 1
        HORDE.wave666_mode = true
        HORDE.wave666_kills_base       = d.Wave666KillsBase or 1024
        HORDE.wave666_kills_per_player = d.Wave666KillsPerPlayer or 256
        HORDE.wave666_start_money      = d.Wave666StartMoney or 7500
        HORDE.wave666_money_per_player = d.Wave666MoneyPerPlayer or 500
        HORDE.wave666_engineer_metal   = d.Wave666EngineerMetal or 10000
        HORDE.wave666_skulls           = d.Wave666Skulls or 66
        HORDE.wave666_exp              = d.Wave666Exp or 7500
        HORDE.start_money = HORDE.wave666_start_money
    else
        HORDE.max_waves = math.min(HORDE.max_max_waves, math.max(1, GetConVarNumber("horde_max_wave")))
        if d.MaxWaves and d.MaxWaves > 0 then
            HORDE.max_waves = d.MaxWaves
            HORDE.hundred_scale_per_wave = d.ScalePerWave or 0
        end
    end

    local victory_skulls = tonumber(d.VictorySkulls)
    if victory_skulls ~= nil then
        HORDE.victory_skulls = math.max(0, math.floor(victory_skulls))
    end
    local defeat_skulls = tonumber(d.DefeatSkulls)
    if defeat_skulls ~= nil then
        HORDE.defeat_skulls = math.max(0, math.floor(defeat_skulls))
    end

    if not HORDE.purism_mode and string.upper(tostring(d.Name)) == "PURISM" then
        HORDE.max_waves = d.MaxWaves or 10
        HORDE.purism_mode = true
    end

    HORDE.extended_waves = HORDE.max_waves > HORDE.max_max_waves
    HORDE._hundred_mutation_bonus = 0

    local include_note = ""
    if HORDE.GetDifficultyInclude and istable(HORDE._difficulties and HORDE._difficulties[idx]) then
        local inc = HORDE:GetDifficultyInclude(HORDE._difficulties[idx])
        if inc then include_note = " include=" .. tostring(inc) end
    end
    print(string.format("[Horde Difficulty] %s (idx %d)%s | dmg×%.2f hp×%.2f reward×%.2f enemies×%.2f",
        d.Name, idx, include_note, d.DamageMult, d.HealthMult, d.RewardMult, d.EnemyCountMult))

    if HORDE.GetDirectorInterval and timer.Exists("Horde_Main") then
        timer.Adjust("Horde_Main", HORDE:GetDirectorInterval(), nil, nil)
    end
end

hook.Add("Horde_AllModulesLoaded", "Horde_ApplyDifficulty", function()
    if HORDE.LoadDifficultyBasicsFromDB then
        HORDE:LoadDifficultyBasicsFromDB()
    end
    HORDE.difficulty = ResolveDifficultyIndex()
    ApplyDifficulty()
    if HORDE.ApplySettingsModifier then HORDE:ApplySettingsModifier() end
    if HORDE.RefreshActiveEnemies then HORDE:RefreshActiveEnemies() end
end)

local cv_settings_applied = CreateConVar("horde_settings_difficulty_applied", 0, FCVAR_DONTRECORD,
    "Internal: difficulty from horde.txt has already been applied this server session.")

function HORDE:GetModifierList()
    local list = {}
    for _, def in pairs(HORDE._difficulties or {}) do
        if istable(def) and HORDE:IsModifier(def) then list[#list + 1] = def end
    end
    table.sort(list, function(a, b) return (a.Index or 0) < (b.Index or 0) end)
    return list
end

function HORDE:ApplySettingsModifier()
    if cv_settings_applied:GetInt() == 1 then return false end
    cv_settings_applied:SetInt(1)

    local wanted = GetConVar("horde_modifier"):GetInt()
    if not wanted or wanted <= 0 then return false end

    local mod = HORDE:GetModifierList()[wanted]
    if not mod then
        print("[Horde Difficulty] horde_modifier=" .. tostring(wanted) .. ": modifier not found (only "
            .. tostring(#HORDE:GetModifierList()) .. " registered)")
        return false
    end

    local base_name = HORDE.difficulty_text and HORDE.difficulty_text[GetConVar("horde_difficulty"):GetInt() + 1]
    if not base_name or HORDE:IsModifier(base_name) then
        base_name = HORDE:GetDifficultyOverride(mod) or HORDE.DEFAULT_MODIFIER_BASE
    end
    if HORDE:IsModifier(base_name) then base_name = HORDE.DEFAULT_MODIFIER_BASE end

    HORDE:SetVotedDifficultyIncludeBase(base_name)
    GetConVar("horde_difficulty"):SetInt(mod.Index - 1)
    HORDE:ReapplyDifficulty()
    HORDE:BroadcastDifficulty()

    print(string.format("[Horde Difficulty] horde.txt settings: %s + %s", tostring(base_name), mod.Name))
    return true
end

function HORDE:ReapplyDifficulty()
    HORDE.difficulty = ResolveDifficultyIndex()
    ApplyDifficulty()
    if HORDE.RefreshActiveEnemies then HORDE:RefreshActiveEnemies() end
    return HORDE.difficulty
end

function HORDE:BroadcastDifficulty()
    for _, ply in ipairs(player.GetAll()) do
        net.Start("Horde_SyncDifficulty")
            net.WriteUInt(HORDE.difficulty, 16)
            net.WriteString(HORDE.difficulty_base_name or "")
        net.Send(ply)

        net.Start("Horde_SyncDifficultyText")
            net.WriteTable(HORDE.difficulty_text)
        net.Send(ply)
    end
end

function VJ_DestroyCombineTurret() end

hook.Add("EntityTakeDamage", "Horde_EntityTakeDamage", function(target, dmg)
    if not target:IsValid() then return end
    local diff = GetDiffData(HORDE.difficulty)

    if target:IsPlayer() then
        if dmg:GetAttacker():IsNPC() then
            if HORDE:IsMinion(dmg:GetAttacker()) then return true end
            if dmg:IsDamageType(DMG_CRUSH) then
                dmg:SetDamage(math.min(dmg:GetDamage(), 20))
            end
            local hundred_dmg = HORDE:IsExtendedWave()
                and (1 + HORDE.hundred_scale_per_wave * (HORDE.current_wave - HORDE.max_max_waves)) or 1
            local scale = diff.DamageMult * hundred_dmg
            dmg:ScaleDamage(scale)
            if dmg:GetAttacker():GetVar("damage_scale") then
                dmg:ScaleDamage(dmg:GetAttacker():GetVar("damage_scale"))
            end
        elseif dmg:GetAttacker():IsPlayer() and dmg:GetAttacker() ~= target then
            return true
        elseif dmg:IsDamageType(DMG_CRUSH) then
            dmg:SetDamage(math.min(dmg:GetDamage(), 20))
        end

    elseif HORDE:IsPlayerMinion(target) then
        if dmg:GetAttacker():IsPlayer() or HORDE:IsPlayerMinion(dmg:GetAttacker()) then
            return true
        else
            if dmg:GetAttacker():GetClass() == "npc_headcrab_poison" then
                dmg:SetDamage(math.min(dmg:GetDamage(), diff.PoisonHeadcrabDamage))
            end
            if target:GetClass() == "npc_turret_floor" then
                dmg:SetDamageForce(Vector(0, 0, 0))
                target:SetHealth(target:Health() - dmg:GetDamage())
                if target:Health() <= 0 then target:Fire("selfdestruct") end
            end
            local hundred_dmg = HORDE:IsExtendedWave()
                and (1 + HORDE.hundred_scale_per_wave * (HORDE.current_wave - HORDE.max_max_waves)) or 1
            local scale = diff.DamageMult * hundred_dmg
            dmg:ScaleDamage(scale)
            if dmg:GetAttacker():GetVar("damage_scale") then
                dmg:ScaleDamage(dmg:GetAttacker():GetVar("damage_scale"))
            end
        end

    elseif target:IsNPC() then
        if not dmg:GetAttacker():IsNPC() then return end
        if target:GetClass() == dmg:GetAttacker() and dmg:GetAttacker() == dmg:GetInflictor() then return true end
        if dmg:IsDamageType(DMG_POISON) and dmg:GetAttacker():GetClass() == "npc_headcrab_poison" then
            dmg:SetDamage(0)
        elseif dmg:IsDamageType(DMG_SHOCK) or dmg:IsDamageType(DMG_REMOVENORAGDOLL) then
            local c = dmg:GetAttacker():GetClass()
            if c == "npc_vj_horde_screecher" or c == "npc_vj_horde_weeper" then dmg:SetDamage(0) end
        end
    end
end)

hook.Add("GetFallDamage", "RealisticDamage", function(ply, speed)
    local bonus = { less = 1 }
    local dmg   = 0
    local idx   = HORDE.difficulty

    if idx == 1 then
        dmg = 10
    elseif idx == 2 then
        dmg = math.max(0, math.ceil(0.2418 * speed - 141.75)) / 2
    else
        dmg = math.max(0, math.ceil(0.2418 * speed - 141.75))
    end

    hook.Run("Horde_GetFallDamage", ply, speed, bonus)
    return dmg * bonus.less
end)

util.AddNetworkString("Horde_ApplyDifficultyBasics")
util.AddNetworkString("Horde_ResetDifficultyBasics")
util.AddNetworkString("Horde_SyncDifficultyBasics")

HORDE.difficulty_basics_overrides = HORDE.difficulty_basics_overrides or {}

local DIFF_BASIC_KEYS = {
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

local DIFF_BASIC_CONVAR_FALLBACK = {
    "MaxEnemiesAliveBase", "MaxEnemiesAlivePerPlayer", "MaxEnemiesAliveCap",
}

local function FindDiffByName(name)
    for i, dd in pairs(HORDE._difficulties or {}) do
        if istable(dd) and dd.Name == name then
            return dd, i
        end
    end
    return nil, nil
end

function HORDE:ApplyDifficultyBasicsValues(name, values, reapply_active)
    local d, idx = FindDiffByName(name)
    if not d or not idx then return nil end

    values = values or {}
    for _, k in ipairs(DIFF_BASIC_KEYS) do
        if values[k] ~= nil then
            local num = tonumber(values[k])
            if num ~= nil and num == num and num ~= math.huge and num ~= -math.huge then d[k] = num end
        end
    end

    if HORDE.difficulty_health_multiplier then
        HORDE.difficulty_health_multiplier[idx] = d.HealthMult
    end
    if HORDE.difficulty_reward_base_multiplier then
        HORDE.difficulty_reward_base_multiplier[idx] = d.RewardMult
    end
    if HORDE.difficulty_status_duration_bonus then
        HORDE.difficulty_status_duration_bonus[idx] = d.StatusDurationBonus
    end
    if HORDE.difficulty_break_health_left then
        HORDE.difficulty_break_health_left[idx] = d.BreakHealthLeft
    end
    if HORDE.difficulty_shock_damage_increase then
        HORDE.difficulty_shock_damage_increase[idx] = d.ShockDamageIncrease
    end
    if HORDE.difficulty_frostbite_slow then
        HORDE.difficulty_frostbite_slow[idx] = d.FrostbiteSlow
    end
    if HORDE.difficulty_elite_health_scale_add then
        HORDE.difficulty_elite_health_scale_add[idx] = d.EliteHealthScaleAdd
    end
    if HORDE.difficulty_elite_health_scale_multiplier then
        HORDE.difficulty_elite_health_scale_multiplier[idx] = d.EliteHealthScaleMultiplier
    end
    if HORDE.difficulty_additional_pack then
        HORDE.difficulty_additional_pack[idx] = d.AdditionalPack
    end
    if HORDE.difficulty_additional_ammoboxes then
        HORDE.difficulty_additional_ammoboxes[idx] = d.AdditionalAmmoboxes
    end
    if HORDE.difficulty_additional_enemies_per_spawn then
        HORDE.difficulty_additional_enemies_per_spawn[idx] = d.AdditionalEnemiesPerSpawn or 0
    end
    if HORDE.difficulty_spawn_speed_mult then
        HORDE.difficulty_spawn_speed_mult[idx] = d.SpawnSpeedMult or 1
    end
    if HORDE.difficulty_spawn_interval then
        HORDE.difficulty_spawn_interval[idx] = d.SpawnInterval
    end
    if HORDE.difficulty_mutation_probability then
        HORDE.difficulty_mutation_probability[idx] = d.MutationProbability
    end
    if HORDE.difficulty_elite_mutation_probability then
        HORDE.difficulty_elite_mutation_probability[idx] = d.EliteMutationProbability
    end

    HORDE._diff_damage_mult = HORDE._diff_damage_mult or {}
    HORDE._diff_damage_mult[idx] = d.DamageMult or 1
    HORDE._diff_enemy_count_mult = HORDE._diff_enemy_count_mult or {}
    HORDE._diff_enemy_count_mult[idx] = d.EnemyCountMult or 1
    HORDE._diff_start_money_mult = HORDE._diff_start_money_mult or {}
    HORDE._diff_start_money_mult[idx] = d.StartMoneyMult or 1
    HORDE._diff_spawn_radius_mult = HORDE._diff_spawn_radius_mult or {}
    HORDE._diff_spawn_radius_mult[idx] = d.SpawnRadiusMult or 1
    HORDE._diff_max_enemies_scale = HORDE._diff_max_enemies_scale or {}
    HORDE._diff_max_enemies_scale[idx] = d.MaxEnemiesScaleFactor or 1
    HORDE._diff_poison_headcrab_dmg = HORDE._diff_poison_headcrab_dmg or {}
    HORDE._diff_poison_headcrab_dmg[idx] = d.PoisonHeadcrabDamage or 50

    if reapply_active and HORDE.difficulty == idx then
        HORDE._orig_total_enemies_per_wave = HORDE._orig_total_enemies_per_wave or {}
        if #HORDE._orig_total_enemies_per_wave == 0 and HORDE.total_enemies_per_wave then
            for i, v in ipairs(HORDE.total_enemies_per_wave) do
                HORDE._orig_total_enemies_per_wave[i] = v
            end
        end
        if HORDE._orig_total_enemies_per_wave and HORDE.total_enemies_per_wave then
            for i, v in ipairs(HORDE._orig_total_enemies_per_wave) do
                HORDE.total_enemies_per_wave[i] = math.floor(v * (d.EnemyCountMult or 1))
            end
        end
        HORDE._orig_kill_reward_base = HORDE._orig_kill_reward_base or HORDE.kill_reward_base
        HORDE._orig_round_bonus_base = HORDE._orig_round_bonus_base or HORDE.round_bonus_base
        HORDE._orig_start_money      = HORDE._orig_start_money      or HORDE.start_money
        HORDE._orig_spawn_radius     = HORDE._orig_spawn_radius     or HORDE.spawn_radius
        if HORDE._orig_kill_reward_base then
            HORDE.kill_reward_base = math.floor(HORDE._orig_kill_reward_base * (d.RewardMult or 1))
        end
        if HORDE._orig_round_bonus_base then
            HORDE.round_bonus_base = math.floor(HORDE._orig_round_bonus_base * (d.RewardMult or 1))
        end
        if HORDE._orig_start_money then
            HORDE.start_money = math.floor(HORDE._orig_start_money * (d.StartMoneyMult or 1))
        end
        if HORDE._orig_spawn_radius then
            HORDE.spawn_radius = math.floor(HORDE._orig_spawn_radius * (d.SpawnRadiusMult or 1))
        end
        HORDE.difficulty_max_enemies_alive_scale_factor = d.MaxEnemiesScaleFactor
    end

    return idx
end

function HORDE:SaveDifficultyBasicsToDB(overrides)
    local DB = HORDE.DB
    if not DB or not DB.IsReady or not DB.IsReady() then
        print("[HORDE] SaveDifficultyBasicsToDB: DB not ready")
        return false
    end
    local payload = util.TableToJSON(overrides or HORDE.difficulty_basics_overrides or {}) or "{}"
    local _, err = DB.QueryP(
        "INSERT OR REPLACE INTO horde_redux_meta (key, value) VALUES ('difficulty_basics', ?);",
        payload
    )
    if err then
        print("[HORDE] SaveDifficultyBasicsToDB failed: " .. tostring(err))
        return false
    end
    print("[HORDE] Difficulty Basics saved to DB ("
        .. table.Count(overrides or HORDE.difficulty_basics_overrides or {}) .. " difficulties)")
    return true
end

function HORDE:LoadDifficultyBasicsFromDB()
    local DB = HORDE.DB
    if not DB or not DB.IsReady or not DB.IsReady() then return false end

    local row = DB.QueryRow("SELECT value FROM horde_redux_meta WHERE key = 'difficulty_basics';")
    if not row or not row.value or row.value == "" then
        HORDE.difficulty_basics_overrides = {}
        return false
    end

    local t = util.JSONToTable(row.value)
    if not istable(t) then
        print("[HORDE] LoadDifficultyBasicsFromDB: invalid JSON")
        return false
    end

    HORDE.difficulty_basics_overrides = t
    local n = 0
    for name, values in pairs(t) do
        if isstring(name) and istable(values) then
            if HORDE:ApplyDifficultyBasicsValues(name, values, false) then
                n = n + 1
            end
        end
    end
    print("[HORDE] Difficulty Basics loaded from DB (" .. n .. " overrides applied)")
    return true
end

function HORDE:SyncDifficultyBasicsTo(ply)
    net.Start("Horde_SyncDifficultyBasics")
        net.WriteTable({
            overrides = HORDE.difficulty_basics_overrides or {},
            defaults  = HORDE._difficulty_file_defaults or {},
        })
    if IsValid(ply) then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

net.Receive("Horde_ApplyDifficultyBasics", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local name   = net.ReadString()
    local _idx   = net.ReadUInt(16)
    local values = HORDE:ReadTableSafe(len)
    if not values then return end

    local clean = {}
    for _, k in ipairs(DIFF_BASIC_KEYS) do
        if values[k] ~= nil then
            local num = tonumber(values[k])
            if num ~= nil and num == num and num ~= math.huge and num ~= -math.huge then clean[k] = num end
        end
    end

    local exists = false
    for _, dd in pairs(HORDE._difficulties or {}) do
        if istable(dd) and dd.Name == name then exists = true break end
    end
    if not exists then
        print("[HORDE] ApplyDifficultyBasics: unknown difficulty " .. tostring(name))
        return
    end

    local persisted = {}
    for k, v in pairs(HORDE.difficulty_basics_overrides or {}) do persisted[k] = v end
    persisted[name] = clean
    HORDE:SaveDifficultyBasicsToDB(persisted)

    local deferred = HORDE:QueueConfigApply("difficulty_basics:" .. name, function()
        HORDE.difficulty_basics_overrides = HORDE.difficulty_basics_overrides or {}
        HORDE.difficulty_basics_overrides[name] = clean
        HORDE:ApplyDifficultyBasicsValues(name, clean, true)
        HORDE:SyncDifficultyBasicsTo()
    end)
    HORDE:SendNotification(deferred and "Difficulty config saved. It will apply on the next wave."
        or "Difficulty config applied.", 0, ply)

    print(string.format("[HORDE] %s %s Difficulty Basics for %s",
        ply:Nick(), deferred and "queued" or "applied", tostring(name)))
end)

net.Receive("Horde_ResetDifficultyBasics", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local name = net.ReadString()
    local defaults = HORDE._difficulty_file_defaults and HORDE._difficulty_file_defaults[name]
    if not istable(defaults) then
        print("[HORDE] ResetDifficultyBasics: no file defaults for " .. tostring(name))
        return
    end

    local persisted = {}
    for k, v in pairs(HORDE.difficulty_basics_overrides or {}) do persisted[k] = v end
    persisted[name] = nil
    HORDE:SaveDifficultyBasicsToDB(persisted)

    local deferred = HORDE:QueueConfigApply("difficulty_basics:" .. name, function()
        HORDE.difficulty_basics_overrides = HORDE.difficulty_basics_overrides or {}
        HORDE.difficulty_basics_overrides[name] = nil
        HORDE:ApplyDifficultyBasicsValues(name, defaults, true)
        local dd, dd_idx = FindDiffByName(name)
        if istable(dd) then
            for _, k in ipairs(DIFF_BASIC_CONVAR_FALLBACK) do dd[k] = nil end
            if defaults.SpawnInterval == nil and dd.SpawnInterval ~= nil then
                dd.SpawnInterval = nil
                if HORDE.difficulty_spawn_interval then
                    HORDE.difficulty_spawn_interval[dd_idx] = nil
                end
            end
        end
        HORDE:SyncDifficultyBasicsTo()
    end)
    HORDE:SendNotification(deferred and "Difficulty config reset. It will apply on the next wave."
        or "Difficulty config reset.", 0, ply)

    print(string.format("[HORDE] %s %s Difficulty Basics reset for %s",
        ply:Nick(), deferred and "queued" or "applied", tostring(name)))
end)
