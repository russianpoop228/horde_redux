if not SERVER then return end

util.AddNetworkString("Horde_SyncTopTen")
util.AddNetworkString("Horde_RequestLeaderboard")
util.AddNetworkString("Horde_SyncLeaderBoard")

HORDE.LEADERBOARD_LIMIT = HORDE.LEADERBOARD_LIMIT or 25

local DB = HORDE.DB
local FLUSH_INTERVAL   = 30
local CACHE_TTL        = 5
local REQUEST_COOLDOWN = 5

HORDE.top_tens = {}
function HORDE:TryAddTopTen() return true end

local function RankEnabled()
    local cv = GetConVar("horde_enable_rank")
    return cv == nil or cv:GetInt() == 1
end

local function Key(ply)
    if not IsValid(ply) or ply:IsBot() then return nil end
    local sid = ply:SteamID()
    if not sid or sid == "" then return nil end
    return sid
end

local function InitSchema()
    if not (DB and DB.IsReady and DB.IsReady()) then return end
    DB.Query([[
        CREATE TABLE IF NOT EXISTS horde_redux_stats (
            steamid      TEXT PRIMARY KEY,
            name         TEXT,
            total_kills  INTEGER DEFAULT 0,
            total_mvps   INTEGER DEFAULT 0
        );]])
end
InitSchema()

function HORDE:Leaderboard_AddKill(ply)
    if not Key(ply) then return end
    ply.Horde_LB_Kills = (ply.Horde_LB_Kills or 0) + 1
end

local function IsDirty(ply)
    return (ply.Horde_LB_Kills or 0) > 0 or (ply.Horde_LB_MVPs or 0) > 0 or not ply.Horde_LB_Seen
end

function HORDE:Leaderboard_Flush(players)
    if not (DB and DB.IsReady and DB.IsReady()) then return false end
    if not RankEnabled() then return false end

    local batch = {}
    for _, ply in ipairs(players or player.GetHumans()) do
        local sid = Key(ply)
        if sid then
            batch[#batch + 1] = {
                ply = ply, sid = sid, name = ply:Nick(),
                kills = ply.Horde_LB_Kills or 0,
                mvps  = ply.Horde_LB_MVPs or 0,
            }
        end
    end
    if #batch == 0 then return true end

    local now = os.time()
    local ok = DB.Transaction(function(exec)
        for _, b in ipairs(batch) do
            local _, e1 = exec(DB.Prepare([[
                INSERT INTO horde_redux_stats (steamid, name, total_kills, total_mvps)
                VALUES (?, ?, ?, ?)
                ON CONFLICT(steamid) DO UPDATE SET
                    name        = excluded.name,
                    total_kills = total_kills + excluded.total_kills,
                    total_mvps  = total_mvps  + excluded.total_mvps;
            ]], b.sid, b.name, b.kills, b.mvps))
            if e1 then return false end

            local _, e2 = exec(DB.Prepare([[
                INSERT INTO horde_redux_players (steamid, first_seen, last_seen)
                VALUES (?, ?, ?)
                ON CONFLICT(steamid) DO UPDATE SET last_seen = excluded.last_seen;
            ]], b.sid, now, now))
            if e2 then return false end
        end
        return true
    end)
    if not ok then return false end

    for _, b in ipairs(batch) do
        if IsValid(b.ply) then
            b.ply.Horde_LB_Kills = math.max(0, (b.ply.Horde_LB_Kills or 0) - b.kills)
            b.ply.Horde_LB_MVPs  = math.max(0, (b.ply.Horde_LB_MVPs or 0) - b.mvps)
            b.ply.Horde_LB_Seen  = true
        end
    end
    return true
end

timer.Create("Horde_LeaderboardFlush", FLUSH_INTERVAL, 0, function()
    local dirty = {}
    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) and IsDirty(ply) then dirty[#dirty + 1] = ply end
    end
    if #dirty > 0 then HORDE:Leaderboard_Flush(dirty) end
end)

hook.Add("PlayerDisconnected", "Horde_LeaderboardFlushOnDisconnect", function(ply)
    if IsValid(ply) then HORDE:Leaderboard_Flush({ ply }) end
end)

hook.Add("ShutDown", "Horde_LeaderboardFlushOnShutdown", function()
    HORDE:Leaderboard_Flush()
end)

local TOP_QUERY = [[
    SELECT r.steamid                        AS steamid,
           r.subclass_key                   AS class,
           r.level                          AS level,
           r.exp                            AS exp,
           COALESCE(p.last_seen, 0)         AS last_seen,
           COALESCE(s.name, '')             AS name,
           COALESCE(s.total_kills, 0)       AS kills,
           COALESCE(s.total_mvps, 0)        AS mvps
    FROM horde_redux_ranks r
    LEFT JOIN horde_redux_players p ON p.steamid = r.steamid
    LEFT JOIN horde_redux_stats   s ON s.steamid = r.steamid
    WHERE r.level > 0
      AND r.rowid = (
            SELECT r2.rowid FROM horde_redux_ranks r2
            WHERE r2.steamid = r.steamid
            ORDER BY r2.level DESC, r2.exp DESC, r2.subclass_key ASC
            LIMIT 1)
    ORDER BY r.level DESC, r.exp DESC, kills DESC
    LIMIT %d;
]]

local cache, cache_time = nil, 0

function HORDE:Leaderboard_GetRows(force)
    if not force and cache and (CurTime() - cache_time) < CACHE_TTL then return cache end

    local rows = {}
    if DB and DB.IsReady and DB.IsReady() then
        local res = DB.Query(string.format(TOP_QUERY, math.floor(HORDE.LEADERBOARD_LIMIT)))
        for _, r in ipairs(res or {}) do
            local ply = player.GetBySteamID(r.steamid)
            local online = IsValid(ply)
            local name = online and ply:Nick() or r.name
            local last_seen = tonumber(r.last_seen) or 0
            rows[#rows + 1] = {
                steamid   = util.SteamIDTo64(r.steamid),
                name      = (name and name ~= "" and name ~= "NULL") and name or nil,
                class     = r.class,
                level     = tonumber(r.level) or 0,
                kills     = tonumber(r.kills) or 0,
                mvps      = tonumber(r.mvps) or 0,
                last_seen = last_seen > 0 and last_seen or nil,
                online    = online or nil,
            }
        end
    end
    cache, cache_time = rows, CurTime()
    return rows
end

function HORDE:Leaderboard_Send(target, force)
    local rows = HORDE:Leaderboard_GetRows(force)
    net.Start("Horde_SyncTopTen")
        net.WriteString(util.TableToJSON(rows))
    if target then net.Send(target) else net.Broadcast() end
end

net.Receive("Horde_RequestLeaderboard", function(_, ply)
    if not IsValid(ply) then return end
    if (ply.Horde_LB_NextRequest or 0) > CurTime() then return end
    ply.Horde_LB_NextRequest = CurTime() + REQUEST_COOLDOWN
    HORDE:Leaderboard_Send(ply)
end)

local RANKED_OUTCOMES = {
    VICTORY = true,
    DEFEAT  = true,
}

function HORDE:Leaderboard_OnGameEnd(mvp_player, status)
    if HORDE.leaderboard_game_recorded then return end
    HORDE.leaderboard_game_recorded = true
    if not RankEnabled() then return end

    if HORDE.SaveRank then
        for _, ply in ipairs(player.GetHumans()) do
            if IsValid(ply) then pcall(HORDE.SaveRank, HORDE, ply) end
        end
    end

    if RANKED_OUTCOMES[status] and Key(mvp_player) then
        mvp_player.Horde_LB_MVPs = (mvp_player.Horde_LB_MVPs or 0) + 1
    end
    HORDE:Leaderboard_Flush()
    HORDE:Leaderboard_Send(nil, true)
end
