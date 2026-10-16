if not SERVER then return end

HORDE = HORDE or {}
local DB = HORDE.DB

HORDE.prestige_level_threshold = HORDE.prestige_level_threshold or 30

local dev = GetConVar("developer")
local function logDev(msg)
    if dev and dev:GetBool() then
        MsgC(Color(120, 200, 255), "[Horde Persistence] " .. msg .. "\n")
    end
end

local function SteamKey(ply)
    if not IsValid(ply) then return nil end
    if ply:IsBot() then return nil end
    return ply:SteamID()
end

local function ForEachSubclass(fn)
    for print_name, subclass in pairs(HORDE.subclasses or {}) do
        local parent = subclass.ParentClass or print_name
        fn(print_name, parent, subclass)
    end
end

function HORDE:SaveRank(ply)
    if GetConVar("horde_enable_rank"):GetInt() == 0 then return end
    if not IsValid(ply) then return end
    if not ply.Horde_Rank_Loaded then return end
    if not DB.IsReady() then return end

    local steamid = SteamKey(ply)
    if not steamid then return end

    local dirty = ply.Horde_Rank_Dirty or {}
    if table.IsEmpty(dirty) then return true end
    local ok, err = DB.Transaction(function(exec)
        local now = os.time()
        local _, touch_error = exec(DB.Prepare([[
            INSERT INTO horde_redux_players (steamid, first_seen, last_seen)
            VALUES (?, ?, ?)
            ON CONFLICT(steamid) DO UPDATE SET last_seen = excluded.last_seen;
        ]], steamid, now, now))
        if touch_error then return false end
        for subclass_key in pairs(dirty) do
            local subclass = HORDE.subclasses[subclass_key]
            if not subclass then continue end
            local _, query_error = exec(DB.Prepare([[
                INSERT INTO horde_redux_ranks (steamid, subclass_key, parent_class, level, exp)
                VALUES (?, ?, ?, ?, ?)
                ON CONFLICT(steamid, subclass_key)
                DO UPDATE SET level = excluded.level,
                              exp   = excluded.exp,
                              parent_class = excluded.parent_class;
            ]], steamid, subclass_key, subclass.ParentClass or subclass_key,
                ply:Horde_GetLevel(subclass_key) or 0, ply:Horde_GetExp(subclass_key) or 0))
            if query_error then return false end
        end
        return true
    end)
    if not ok then
        logDev("Rank save failed for " .. steamid .. ": " .. tostring(err))
        return false
    end
    ply.Horde_Rank_Dirty = {}

    logDev("Saved ranks for " .. steamid)
    return true
end

function HORDE:LoadRank(ply)
    if not IsValid(ply) then return end
    if GetConVar("horde_enable_rank"):GetInt() == 0 then ply.Horde_Rank_Loaded = true; return true end
    if not DB.IsReady() then return false, "database is not ready" end
    ply.Horde_Rank_Loaded = false

    local steamid = SteamKey(ply)
    if not steamid then return end

    local migration_ok, migration_error = HORDE:TryMigratePlayer(ply)
    if migration_ok == false then return false, migration_error or "legacy migration failed" end

    local rows, query_error = DB.QueryP(
        "SELECT subclass_key, level, exp FROM horde_redux_ranks WHERE steamid = ?;",
        steamid
    )
    if query_error then return false, "rank query failed" end

    local loaded = {}
    ply.Horde_Rank_Dirty = {}
    if rows then
        for _, row in ipairs(rows) do
            local key   = row.subclass_key
            local level = tonumber(row.level) or 0
            local exp   = tonumber(row.exp) or 0
            ply:Horde_SetLevel(key, level)
            if not ply.Horde_Exps then ply.Horde_Exps = {} end
            ply.Horde_Exps[key] = exp
            loaded[key] = true
        end
    end

    ForEachSubclass(function(subclass_key)
        if not loaded[subclass_key] then
            ply:Horde_SetLevel(subclass_key, 0)
            if not ply.Horde_Exps then ply.Horde_Exps = {} end
            ply.Horde_Exps[subclass_key] = 0
        end
    end)

    if not HORDE:LoadPrestige(ply) then return false, "prestige query failed" end

    ply.Horde_Rank_Loaded = true
    logDev("Loaded ranks for " .. steamid)
    return true
end

local prestige_meta = FindMetaTable("Player")

function prestige_meta:Horde_GetPrestige(subclass_key)
    if not self.Horde_Prestige then self.Horde_Prestige = {} end
    return self.Horde_Prestige[subclass_key] or 0
end

function prestige_meta:Horde_SetPrestige(subclass_key, value)
    if not IsValid(self) then return end
    if not subclass_key then return end
    if not self.Horde_Prestige then self.Horde_Prestige = {} end
    self.Horde_Prestige[subclass_key] = math.max(0, math.floor(value or 0))
end

function HORDE:SavePrestige(ply)
    if not IsValid(ply) then return end
    if not DB.IsReady() then return end
    local steamid = SteamKey(ply)
    if not steamid then return end

    local ok, err = DB.Transaction(function(exec)
        for subclass_key in pairs(HORDE.subclasses or {}) do
            local _, query_error = exec(DB.Prepare([[
                INSERT INTO horde_redux_prestige (steamid, subclass_key, prestige)
                VALUES (?, ?, ?)
                ON CONFLICT(steamid, subclass_key)
                DO UPDATE SET prestige = excluded.prestige;
            ]], steamid, subclass_key, ply:Horde_GetPrestige(subclass_key) or 0))
            if query_error then return false end
        end
        return true
    end)
    if not ok then
        logDev("Prestige save failed for " .. steamid .. ": " .. tostring(err))
        return false
    end
    logDev("Saved prestige for " .. steamid)
    return true
end

function HORDE:LoadPrestige(ply)
    if not IsValid(ply) then return end
    if not DB.IsReady() then return false end
    local steamid = SteamKey(ply)
    if not steamid then return end

    local rows, query_error = DB.QueryP(
        "SELECT subclass_key, prestige FROM horde_redux_prestige WHERE steamid = ?;",
        steamid
    )
    if query_error then return false end
    ply.Horde_Prestige = {}
    if rows then
        for _, row in ipairs(rows) do
            ply:Horde_SetPrestige(row.subclass_key, tonumber(row.prestige) or 0)
        end
    end

    HORDE:SyncPrestige(ply)
    return true
end

util.AddNetworkString("Horde_SyncPrestige")
function HORDE:SyncPrestige(ply, target)
    if not IsValid(ply) then return end
    net.Start("Horde_SyncPrestige")
        net.WriteEntity(ply)
        net.WriteTable(ply.Horde_Prestige or {})
    if target and IsValid(target) then
        net.Send(target)
    else
        net.Broadcast()
    end
end

function HORDE:DoPrestige(ply, subclass_key)
    if not IsValid(ply) then return false end
    if ply:Horde_GetLevel(subclass_key) < HORDE.prestige_level_threshold then
        return false
    end

    ply:Horde_SetPrestige(subclass_key, ply:Horde_GetPrestige(subclass_key) + 1)
    ply:Horde_SetLevel(subclass_key, 0)
    ply:Horde_SetExp(subclass_key, 0)

    HORDE:SaveRank(ply)
    HORDE:SavePrestige(ply)
    HORDE:SyncPrestige(ply)
    return true
end

concommand.Add("horde_migrate_saves", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    if HORDE.RunBatchMigration then
        HORDE:RunBatchMigration(true)
        if IsValid(ply) then
            HORDE:SendNotification("Legacy save migration finished. Check server console.", 0, ply)
        end
    end
end)

concommand.Add("horde_grant_prestige", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    if not IsValid(ply) then return end
    local subclass_key = args[1] or ply:Horde_GetCurrentSubclass()
    if HORDE:DoPrestige(ply, subclass_key) then
        HORDE:SendNotification("Prestiged " .. subclass_key .. "!", 0, ply)
    else
        HORDE:SendNotification("Cannot prestige " .. subclass_key ..
            " (need level " .. HORDE.prestige_level_threshold .. ").", 1, ply)
    end
end)

function HORDE:SaveSkullTokens(ply)
    if GetConVar("horde_enable_sandbox"):GetInt() == 1 then return end
    if not IsValid(ply) then return end
    if not ply.Horde_Skull_Tokens_Loaded then return end
    if not DB.IsReady() then return end

    local steamid = SteamKey(ply)
    if not steamid then return end

    DB.Query(DB.Prepare([[
        INSERT INTO horde_redux_tokens (steamid, tokens)
        VALUES (?, ?)
        ON CONFLICT(steamid) DO UPDATE SET tokens = excluded.tokens;
    ]], steamid, ply:Horde_GetSkullTokens() or 0))
end

function HORDE:LoadSkullTokens(ply)
    if not IsValid(ply) then return end
    if not DB.IsReady() then return false, "database is not ready" end

    local migration_ok, migration_error = HORDE:TryMigratePlayer(ply)
    if migration_ok == false then return false, migration_error or "legacy migration failed" end

    local steamid = SteamKey(ply)
    local tokens, query_error = DB.QueryValue(
        DB.Prepare("SELECT tokens FROM horde_redux_tokens WHERE steamid = ?;", steamid)
    )
    if query_error then return false, "token query failed" end
    ply:Horde_SetSkullTokens(tonumber(tokens) or 0)
    ply.Horde_Skull_Tokens_Loaded = true
    return true
end

function HORDE:SaveSubclassUnlocks(ply)
    if GetConVar("horde_enable_sandbox"):GetInt() == 1 then return end
    if not IsValid(ply) then return end
    if not ply.Horde_subclasses_unlocked then return end
    if not DB.IsReady() then return end

    local steamid = SteamKey(ply)
    if not steamid then return end

    local ok, err = DB.Transaction(function(exec)
        for subclass_key, status in pairs(ply.Horde_subclasses_unlocked) do
            local _, query_error = exec(DB.Prepare([[
                INSERT INTO horde_redux_unlocks (steamid, subclass_key, unlocked)
                VALUES (?, ?, ?)
                ON CONFLICT(steamid, subclass_key)
                DO UPDATE SET unlocked = excluded.unlocked;
            ]], steamid, subclass_key, status and 1 or 0))
            if query_error then return false end
        end
        return true
    end)
    if not ok then
        logDev("Unlock save failed for " .. steamid .. ": " .. tostring(err))
        return false
    end
    return true
end

function HORDE:LoadSubclassUnlocks(ply)
    if not IsValid(ply) then return end

    if not DB.IsReady() then return false, "database is not ready" end
    local unlocks = {}

    for subclass_name in pairs(HORDE.subclasses or {}) do
        unlocks[subclass_name] = false
    end

    local migration_ok, migration_error = HORDE:TryMigratePlayer(ply)
    if migration_ok == false then return false, migration_error or "legacy migration failed" end
    local steamid = SteamKey(ply)
    local rows, query_error = DB.QueryP(
        "SELECT subclass_key, unlocked FROM horde_redux_unlocks WHERE steamid = ?;",
        steamid
    )
    if query_error then return false, "unlock query failed" end
    if rows then
        for _, row in ipairs(rows) do
            unlocks[row.subclass_key] = (tonumber(row.unlocked) == 1)
        end
    end

    ply.Horde_subclasses_unlocked = unlocks

    net.Start("Horde_SyncSubclassUnlocks")
    net.WriteTable(ply.Horde_subclasses_unlocked)
    net.Send(ply)
    return true
end

function HORDE:TouchPlayer(ply, in_transaction)
    if not DB.IsReady() then return end
    local steamid = SteamKey(ply)
    if not steamid then return end
    local now = os.time()

    DB.Query(DB.Prepare([[
        INSERT INTO horde_redux_players (steamid, first_seen, last_seen)
        VALUES (?, ?, ?)
        ON CONFLICT(steamid) DO UPDATE SET last_seen = excluded.last_seen;
    ]], steamid, now, now))
end

timer.Create("Horde_RankPeriodicSave", 30, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.Horde_Rank_Loaded
            and not table.IsEmpty(ply.Horde_Rank_Dirty or {}) then
            HORDE:SaveRank(ply)
        end
    end
end)

hook.Add("PlayerDisconnected", "Horde_SaveDirtyRankOnDisconnect", function(ply)
    if IsValid(ply) then HORDE:SaveRank(ply) end
end)

hook.Add("ShutDown", "Horde_FlushSavesOnShutdown", function()
    if not DB.IsReady() then return end
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            if ply.Horde_Rank_Loaded and not table.IsEmpty(ply.Horde_Rank_Dirty or {}) then
                HORDE:SaveRank(ply)
            end
            if ply.Horde_Prestige then HORDE:SavePrestige(ply) end
            if ply.Horde_Skull_Tokens_Loaded then HORDE:SaveSkullTokens(ply) end
            if ply.Horde_subclasses_unlocked then HORDE:SaveSubclassUnlocks(ply) end
        end
    end
end)
