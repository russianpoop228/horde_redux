if not CLIENT then return end

HORDE = HORDE or {}
HORDE.Prefs = HORDE.Prefs or {}

sql.Query([[
    CREATE TABLE IF NOT EXISTS horde_redux_client_prefs (
        key   TEXT PRIMARY KEY,
        value TEXT
    );
]])

function HORDE.Prefs.Set(key, value)
    if value == nil then return end
    sql.Query(string.format(
        "INSERT OR REPLACE INTO horde_redux_client_prefs (key, value) VALUES (%s, %s);",
        sql.SQLStr(key), sql.SQLStr(tostring(value))
    ))
end

function HORDE.Prefs.Get(key)
    local v = sql.QueryValue(string.format(
        "SELECT value FROM horde_redux_client_prefs WHERE key = %s;", sql.SQLStr(key)
    ))
    if v == false then return nil end
    return v
end

function HORDE.Prefs.SetTable(key, tbl)
    HORDE.Prefs.Set(key, util.TableToJSON(tbl or {}))
end

function HORDE.Prefs.GetTable(key)
    local v = HORDE.Prefs.Get(key)
    if not v then return nil end
    return util.JSONToTable(v)
end

local function MigrateLegacyPrefs()
    if HORDE.Prefs.Get("_migrated") == "1" then return end

    local cc = file.Read("horde/class_choices.txt", "DATA")
    if cc then HORDE.Prefs.Set("class_choice", cc) end

    local pc = file.Read("horde/perk_choices.txt", "DATA")
    if pc then HORDE.Prefs.Set("perk_choices", pc) end

    HORDE.Prefs.Set("_migrated", "1")
end
MigrateLegacyPrefs()
