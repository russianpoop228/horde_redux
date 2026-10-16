HORDE = HORDE or {}
HORDE.DB = HORDE.DB or {}

local DB = HORDE.DB

DB.SCHEMA_VERSION = 1

if CLIENT then
    function DB.Query() return nil end
    function DB.QueryRow() return nil end
    function DB.QueryValue() return nil end
    function DB.Escape(v) return tostring(v) end
    function DB.Begin() end
    function DB.Commit() end
    function DB.Transaction(fn) return false end
    function DB.IsReady() return false end
    return
end

local dev = GetConVar("developer")

local function log(msg)
    MsgC(Color(120, 200, 255), "[Horde DB] " .. msg .. "\n")
end

local function logErr(msg)
    MsgC(Color(255, 100, 100), "[Horde DB] ERROR: " .. msg .. "\n")
end

function DB.Escape(v)
    if isnumber(v) then
        return tostring(v)
    elseif isbool(v) then
        return v and "1" or "0"
    elseif v == nil then
        return "NULL"
    end
    return sql.SQLStr(tostring(v))
end

function DB.Prepare(query, ...)
    local args = { ... }
    local i = 0
    return (query:gsub("%?", function()
        i = i + 1
        return DB.Escape(args[i])
    end))
end

function DB.Query(query)
    local res = sql.Query(query)
    if res == false then
        logErr(sql.LastError() .. "\n  Query: " .. query)
        return nil, true
    end
    return res, false
end

function DB.QueryP(query, ...)
    return DB.Query(DB.Prepare(query, ...))
end

function DB.QueryRow(query, ...)
    local q = select("#", ...) > 0 and DB.Prepare(query, ...) or query
    local rows, err = DB.Query(q)
    if err then return nil, true end
    return rows and rows[1] or nil, false
end

function DB.QueryValue(query, ...)
    local row, err = DB.QueryRow(query, ...)
    if err then return nil, true end
    if not row then return nil, false end
    local _, value = next(row)
    return value, false
end

function DB.Begin()
    sql.Begin()
end

function DB.Commit()
    sql.Commit()
end

function DB.Transaction(callback)
    if not isfunction(callback) then return false, "invalid transaction callback" end
    local began, begin_error = DB.Query("BEGIN;")
    if begin_error then return false, "could not begin transaction" end

    local failed = false
    local function execute(query)
        if failed then return nil, true end
        local result, err = DB.Query(query)
        if err then failed = true end
        return result, err
    end

    local ok, result = pcall(callback, execute)
    if not ok or result ~= true or failed then
        DB.Query("ROLLBACK;")
        if not ok then return false, tostring(result) end
        return false, "transaction statement failed or callback aborted"
    end

    local committed, commit_error = DB.Query("COMMIT;")
    if commit_error then
        DB.Query("ROLLBACK;")
        return false, "could not commit transaction"
    end
    return true
end

function DB.IsReady()
    return DB._ready == true
end

local SCHEMA = {
    [[
    CREATE TABLE IF NOT EXISTS horde_redux_players (
        steamid     TEXT PRIMARY KEY,
        migrated    INTEGER DEFAULT 0,
        first_seen  INTEGER,
        last_seen   INTEGER
    );]],

    [[
    CREATE TABLE IF NOT EXISTS horde_redux_ranks (
        steamid       TEXT NOT NULL,
        subclass_key  TEXT NOT NULL,
        parent_class  TEXT,
        level         INTEGER DEFAULT 0,
        exp           INTEGER DEFAULT 0,
        PRIMARY KEY (steamid, subclass_key)
    );]],

    [[
    CREATE TABLE IF NOT EXISTS horde_redux_prestige (
        steamid       TEXT NOT NULL,
        subclass_key  TEXT NOT NULL,
        prestige      INTEGER DEFAULT 0,
        PRIMARY KEY (steamid, subclass_key)
    );]],

    [[
    CREATE TABLE IF NOT EXISTS horde_redux_unlocks (
        steamid       TEXT NOT NULL,
        subclass_key  TEXT NOT NULL,
        unlocked      INTEGER DEFAULT 0,
        PRIMARY KEY (steamid, subclass_key)
    );]],

    [[
    CREATE TABLE IF NOT EXISTS horde_redux_tokens (
        steamid  TEXT PRIMARY KEY,
        tokens   INTEGER DEFAULT 0
    );]],

    [[
    CREATE TABLE IF NOT EXISTS horde_redux_meta (
        key    TEXT PRIMARY KEY,
        value  TEXT
    );]],
}

local function InitSchema()
    DB._ready = false
    local ok, err = DB.Transaction(function(exec)
        for _, stmt in ipairs(SCHEMA) do
            local _, query_error = exec(stmt)
            if query_error then return false end
        end
        for _, stmt in ipairs({
            "CREATE INDEX IF NOT EXISTS idx_redux_ranks_steamid ON horde_redux_ranks(steamid);",
            "CREATE INDEX IF NOT EXISTS idx_redux_prestige_steamid ON horde_redux_prestige(steamid);",
            "CREATE INDEX IF NOT EXISTS idx_redux_unlocks_steamid ON horde_redux_unlocks(steamid);",
        }) do
            local _, query_error = exec(stmt)
            if query_error then return false end
        end
        local rows, query_error = exec("SELECT value FROM horde_redux_meta WHERE key = 'schema_version';")
        if query_error then return false end
        if not rows or not rows[1] then
            local _, insert_error = exec(DB.Prepare(
                "INSERT INTO horde_redux_meta (key, value) VALUES ('schema_version', ?);",
                tostring(DB.SCHEMA_VERSION)
            ))
            if insert_error then return false end
        end
        return true
    end)

    if not ok then
        logErr("SQLite schema initialization failed; persistence remains disabled: " .. tostring(err))
        return
    end
    DB._ready = true
    log("SQLite schema ready (version " .. DB.SCHEMA_VERSION .. ").")
end

InitSchema()
