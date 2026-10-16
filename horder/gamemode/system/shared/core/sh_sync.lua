if SERVER then
util.AddNetworkString("Horde_SyncToLocal")
util.AddNetworkString("Horde_SyncToServer")
end

if CLIENT then
concommand.Add("horde_sync_to_local", function ()
	HORDE:SyncToLocal()
end)
end

net.Receive("Horde_SyncClientExps", function ()
	HORDE:SyncToLocal()
end)

if CLIENT then
    sql.Query([[
        CREATE TABLE IF NOT EXISTS horde_redux_client_cache (
            subclass_key TEXT PRIMARY KEY,
            level INTEGER DEFAULT 0,
            exp   INTEGER DEFAULT 0
        );
    ]])
end

function HORDE:SyncToLocal()
    if SERVER then return end
    local ply = MySelf
    if not ply:IsValid() then return end

    sql.Begin()
    local function cache(name)
        local level = ply:Horde_GetLevel(name) or 0
        local exp   = ply:Horde_GetExp(name) or 0
        sql.Query(string.format(
            "INSERT OR REPLACE INTO horde_redux_client_cache (subclass_key, level, exp) VALUES (%s, %d, %d);",
            sql.SQLStr(name), level, exp
        ))
    end

    for name in pairs(HORDE.classes or {}) do
        cache(name)
    end
    for name, class in pairs(HORDE.subclasses or {}) do
        if class.ParentClass then
            cache(name)
        end
    end
    sql.Commit()

    HORDE:PlayNotification("Sucessfully synced local data from server.")
end

function HORDE:SyncToServer(ply)
end
