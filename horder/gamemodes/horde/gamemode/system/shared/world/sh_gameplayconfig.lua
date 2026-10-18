if SERVER then
    util.AddNetworkString("Horde_ToggleGameplayConfig")
    util.AddNetworkString("Horde_SyncGameplayConfig")
    util.AddNetworkString("Horde_SetGameplayConfig")
end

HORDE = HORDE or {}

local CONFIG_FILE = "horde/gameplay_config.txt"

HORDE.GameplayControlDefs = {
    { id = "attack",         label = "Primary Attack:",      cmd = "+attack",                    key = "MOUSE1" },
    { id = "attack2",        label = "Secondary Attack:",    cmd = "+attack2",                   key = "MOUSE2" },
    { id = "spell_f",        label = "Cast Utility Spell:",  cmd = "+horde_utility_spell",         key = "F" },
    { id = "spell_r",        label = "Cast Ultimate Spell:", cmd = "+reload",                    key = "R" },
    { id = "reload",         label = "Reload:",              cmd = "+reload",                    key = "R" },
    { id = "perk",           label = "Use perk skill:",      cmd = "horde_use_perk_skill",       key = "SHIFT+E" },
    { id = "gadget",         label = "Use gadget:",          cmd = "horde_use_gadget",           key = "T" },
    { id = "kick",           label = "Use kick:",            cmd = "",                           key = "" },
    { id = "drop",           label = "Drop item:",           cmd = "horde_drop",                 key = "" },
    { id = "money",          label = "Throw money:",         cmd = "horde_drop_money",           key = "V" },
    { id = "secondary_ammo", label = "Secondary ammo:",      cmd = "horde_arccw_secondary_ammo", key = "" },
    { id = "grenade",        label = "Throw grenade:",       cmd = "horde_use_quick_grenade",    key = "G" },
    { id = "stats",          label = "Stats:",               cmd = "horde_stats",                key = "F1" },
    { id = "control_menu",   label = "Control menu:",        cmd = "horde_config_menu",          key = "F2" },
    { id = "shop",           label = "Shop:",                cmd = "horde_shop",                 key = "F3" },
    { id = "ready",          label = "Get Ready:",           cmd = "horde_ready",                key = "F4" },
    { id = "ping",           label = "Ping:",                cmd = "contextual_ping_all",        key = "Q", additive = true, ignore_ui = true },
}

function HORDE:IsGameplayControlAdditive(def)
    if not istable(def) then return false end
    return def.additive == true or string.sub(def.cmd or "", 1, 1) == "+"
end

local DEF_BY_ID = {}
for _, def in ipairs(HORDE.GameplayControlDefs) do DEF_BY_ID[def.id] = def end

HORDE.gameplay_config = HORDE.gameplay_config or { hidden_difficulties = {}, controls = {}, special_waves = {} }
HORDE.gameplay_config_version = HORDE.gameplay_config_version or 0

function HORDE:IsDifficultyHidden(name)
    local cfg = HORDE.gameplay_config
    return istable(cfg) and istable(cfg.hidden_difficulties) and cfg.hidden_difficulties[name] == true
end

function HORDE:GetGameplayControl(id)
    local def = DEF_BY_ID[id]
    if not def then return "", "" end
    local cfg = HORDE.gameplay_config
    local ov = istable(cfg) and istable(cfg.controls) and cfg.controls[id]
    if istable(ov) then return ov.cmd or "", ov.key or "" end
    return def.cmd, def.key
end

function HORDE:GetEffectiveGameplayControl(id)
    local cmd, key = HORDE:GetGameplayControl(id)
    local pc = HORDE.PlayerControls
    if istable(pc) and pc[id] ~= nil then
        key = pc[id]
    end
    return cmd, key
end

function HORDE:GetSpecialWaveSettings(diffname)
    local cfg = HORDE.gameplay_config
    local entry = istable(cfg) and istable(cfg.special_waves) and cfg.special_waves[diffname]
    if istable(entry) then
        return math.max(0, math.floor(tonumber(entry.count) or 0)),
               math.Clamp(tonumber(entry.chance) or 0, 0, 1)
    end
    return 0, 0
end

local CMD_DENY = {
    quit = true, exit = true, disconnect = true, connect = true, retry = true,
    bind = true, unbind = true, unbindall = true, alias = true, exec = true,
    rcon = true, sv_cheats = true, lua_run_cl = true, lua_openscript_cl = true,
}

function HORDE:NormalizeGameplayCommand(cmd)
    if cmd == nil then return "" end
    if not isstring(cmd) then return nil, "not a string" end
    cmd = string.lower(string.Trim(cmd))
    if cmd == "" then return "" end
    if #cmd > 64 then return nil, "too long" end
    if not string.match(cmd, "^%+?[%a_][%w_]*$") then
        return nil, "expected a single command without arguments"
    end
    local base = string.gsub(cmd, "^%+", "")
    if CMD_DENY[base] then return nil, "command is not allowed" end
    return cmd
end

function HORDE:NormalizeGameplayKey(key)
    if key == nil then return "" end
    if not isstring(key) then return nil, "not a string" end
    key = string.upper(string.Trim(key))
    if key == "" then return "" end
    if #key > 64 then return nil, "too long" end
    for _, part in ipairs(string.Explode("+", key)) do
        if not string.match(part, "^[%w_]+$") then return nil, "invalid key name" end
    end
    return key
end

local function PlainLabel(def)
    return (string.gsub(def.label, ":%s*$", ""))
end

function HORDE:SanitizeGameplayConfig(raw, strict)
    if not istable(raw) then return nil, "invalid data" end

    local known, known_count = {}, 0
    if strict then
        for _, name in pairs(HORDE.difficulty_text or {}) do
            if isstring(name) then known[name] = true; known_count = known_count + 1 end
        end
    end

    local hidden, hidden_count = {}, 0
    if istable(raw.hidden_difficulties) then
        for name, flag in pairs(raw.hidden_difficulties) do
            if isstring(name) and flag == true and #name <= 64 and string.match(name, "^[%w_%- ]+$") then
                if not strict or known[name] then
                    hidden[name] = true
                    hidden_count = hidden_count + 1
                end
            end
        end
    end
    if strict and known_count > 0 and hidden_count >= known_count then
        return nil, "at least one difficulty must stay visible"
    end

    local controls = {}
    local src = istable(raw.controls) and raw.controls or {}
    for _, def in ipairs(HORDE.GameplayControlDefs) do
        local entry = src[def.id]
        if istable(entry) then
            local cmd, err_c = HORDE:NormalizeGameplayCommand(entry.cmd)
            if cmd == nil then return nil, PlainLabel(def) .. " - command: " .. tostring(err_c) end
            local key, err_k = HORDE:NormalizeGameplayKey(entry.key)
            if key == nil then return nil, PlainLabel(def) .. " - key: " .. tostring(err_k) end
            if cmd ~= def.cmd or key ~= def.key then
                controls[def.id] = { cmd = cmd, key = key }
            end
        end
    end

    local special_waves = {}
    local sw_src = istable(raw.special_waves) and raw.special_waves or {}
    for name, entry in pairs(sw_src) do
        if isstring(name) and #name <= 64 and string.match(name, "^[%w_%- ]+$")
            and istable(entry) and (not strict or known[name]) then
            local count  = math.Clamp(math.floor(tonumber(entry.count) or 0), 0, 999)
            local chance = math.Clamp(tonumber(entry.chance) or 0, 0, 1)
            if count > 0 and chance > 0 then
                special_waves[name] = { count = count, chance = chance }
            end
        end
    end

    return { hidden_difficulties = hidden, controls = controls, special_waves = special_waves }
end

if SERVER then
    function HORDE:SaveGameplayConfig()
        if not file.IsDir("horde", "DATA") then
            file.CreateDir("horde")
        end
        file.Write(CONFIG_FILE, util.TableToJSON(HORDE.gameplay_config))
    end

    function HORDE:LoadGameplayConfig()
        local raw = file.Read(CONFIG_FILE, "DATA")
        if not raw then return end
        local t = util.JSONToTable(raw)
        local cfg = t and HORDE:SanitizeGameplayConfig(t, false)
        if cfg then
            HORDE.gameplay_config = cfg
            print("[HORDE] - Loaded gameplay config.")
        end
    end

    function HORDE:SyncGameplayConfigTo(ply)
        net.Start("Horde_SyncGameplayConfig")
            net.WriteTable(HORDE.gameplay_config)
        if IsValid(ply) then net.Send(ply) else net.Broadcast() end
    end

    function HORDE:GameplayConfig(ply)
        if not IsValid(ply) then return end
        if ply:IsSuperAdmin() then
            HORDE:SyncGameplayConfigTo(ply)
            net.Start("Horde_ToggleGameplayConfig")
            net.Send(ply)
        else
            HORDE:SendNotificationDenyAccess(ply)
        end
    end

    concommand.Add("horde_gameplay_config", function(ply, cmd, args)
        HORDE:GameplayConfig(ply)
    end)

    concommand.Add("horde_config_menu", function(ply, cmd, args)
        if IsValid(ply) then HORDE:ConfigMenu(ply) end
    end)

    net.Receive("Horde_SetGameplayConfig", function(len, ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        if not HORDE:AllowNetRequest(ply, "gameplay_config", 0.5) then return end

        local raw = HORDE:ReadTableSafe(len)
        if not raw then
            HORDE:SendNotification("Gameplay config rejected: invalid data.", 1, ply)
            return
        end

        local cfg, err = HORDE:SanitizeGameplayConfig(raw, true)
        if not cfg then
            HORDE:SendNotification("Gameplay config rejected: " .. tostring(err), 1, ply)
            return
        end

        HORDE.gameplay_config = cfg
        HORDE:SaveGameplayConfig()
        HORDE:SyncGameplayConfigTo(nil)
        HORDE:SendNotification("Gameplay config saved.", 0, ply)
    end)

    local cv_reset = CreateConVar("horde_game_reset_controls", "0", FCVAR_ARCHIVE,
        "Set to 1 to reset the Gameplay Config default controls to their defaults.")

    function HORDE:ResetGameplayControls()
        local cfg = HORDE.gameplay_config
        if not istable(cfg) then cfg = {} end
        cfg.controls = {}
        cfg.special_waves = {}
        if not istable(cfg.hidden_difficulties) then cfg.hidden_difficulties = {} end
        HORDE.gameplay_config = cfg

        HORDE:SaveGameplayConfig()
        HORDE:SyncGameplayConfigTo(nil)
        HORDE:SendNotification("Gameplay controls reset to defaults.", 0, nil)
    end

    cvars.AddChangeCallback("horde_game_reset_controls", function(_, _, new)
        if (tonumber(new) or 0) > 0 then
            HORDE:ResetGameplayControls()
            cv_reset:SetInt(0)
        end
    end, "Horde_GameplayResetControls")

    HORDE:LoadGameplayConfig()
end

if CLIENT then
    net.Receive("Horde_SyncGameplayConfig", function()
        local cfg = net.ReadTable()
        if not istable(cfg) then return end
        if not istable(cfg.hidden_difficulties) then cfg.hidden_difficulties = {} end
        if not istable(cfg.controls) then cfg.controls = {} end
        if not istable(cfg.special_waves) then cfg.special_waves = {} end
        HORDE.gameplay_config = cfg
        HORDE.gameplay_config_version = (HORDE.gameplay_config_version or 0) + 1
        hook.Run("Horde_GameplayConfigSynced")
    end)
end
