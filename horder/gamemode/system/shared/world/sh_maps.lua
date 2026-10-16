if SERVER then
util.AddNetworkString("Horde_SetMapsWhitelistData")
util.AddNetworkString("Horde_SetMapsBlacklistData")
util.AddNetworkString("Horde_SyncMaps")
end

HORDE.map_whitelist = {}
HORDE.map_blacklist = {}

function HORDE:GetInstalledMaps()
    local maps = {}
    for _, f in ipairs(file.Find("maps/*.bsp", "GAME")) do
        maps[#maps + 1] = f:sub(1, -5)
    end
    table.sort(maps)
    return maps
end

local function NormalizeMapList(t)
    local set = {}
    if not istable(t) then return set end
    for k, v in pairs(t) do
        local name = (isstring(v) and v ~= "" and v) or (isstring(k) and k) or nil
        if name then set[string.lower(name)] = name end
    end
    return set
end

function HORDE:GetNextMaps()
    local installed = {}
    for _, name in ipairs(HORDE:GetInstalledMaps()) do
        installed[string.lower(name)] = name
    end

    HORDE:GetMapWhitelist()
    HORDE:GetMapBlacklist()

    local whitelist = NormalizeMapList(HORDE.map_whitelist)
    local blacklist = NormalizeMapList(HORDE.map_blacklist)

    local source
    if not table.IsEmpty(whitelist) then
        source = {}
        for lower_name, _ in pairs(whitelist) do
            if installed[lower_name] then source[lower_name] = installed[lower_name] end
        end
    end
    if not source or table.IsEmpty(source) then
        source = {}
        for lower_name, name in pairs(installed) do source[lower_name] = name end
    end

    local map_list = {}
    for lower_name, name in pairs(source) do
        if not blacklist[lower_name] then map_list[#map_list + 1] = name end
    end

    if #map_list == 0 then
        for _, name in pairs(source) do map_list[#map_list + 1] = name end
    end

    table.sort(map_list)
    return map_list
end

function HORDE:SetMapWhitelist()
    if not file.IsDir("horde", "DATA") then
        file.CreateDir("horde")
    end

    file.Write("horde/map_whitelist.txt", util.TableToJSON(HORDE.map_whitelist))
end

function HORDE:SetMapBlacklist()
    if not file.IsDir("horde", "DATA") then
        file.CreateDir("horde")
    end

    file.Write("horde/map_blacklist.txt", util.TableToJSON(HORDE.map_blacklist))
end

function HORDE:GetMapWhitelist()
    if not file.IsDir("horde", "DATA") then
        file.CreateDir("horde")
        return
    end

    if file.Read("horde/map_whitelist.txt", "DATA") then
        local t = util.JSONToTable(file.Read("horde/map_whitelist.txt", "DATA"))
        HORDE.map_whitelist = t or {}
        print("[HORDE] - Loaded map whitelist.")
    end
end

function HORDE:GetMapBlacklist()
    if not file.IsDir("horde", "DATA") then
        file.CreateDir("horde")
        return
    end

    if file.Read("horde/map_blacklist.txt", "DATA") then
        local t = util.JSONToTable(file.Read("horde/map_blacklist.txt", "DATA"))
        HORDE.map_blacklist = t or {}
        print("[HORDE] - Loaded map blacklist.")
    end
end

function HORDE:SyncMapsTo(ply)
    net.Start("Horde_SyncMaps")
        net.WriteTable(HORDE.map_whitelist)
        net.WriteTable(HORDE.map_blacklist)
        net.WriteTable(HORDE:GetInstalledMaps())
    net.Send(ply)
end

if SERVER then
    HORDE:GetMapWhitelist()
    HORDE:GetMapBlacklist()

    net.Receive("Horde_SetMapsWhitelistData", function(len, ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        local tbl = HORDE:ReadTableSafe(len)
        if not tbl then return end
        HORDE.map_whitelist = tbl
        HORDE:SetMapWhitelist()
        HORDE:SyncMapsTo(ply)
    end)

    net.Receive("Horde_SetMapsBlacklistData", function(len, ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        local tbl = HORDE:ReadTableSafe(len)
        if not tbl then return end
        HORDE.map_blacklist = tbl
        HORDE:SetMapBlacklist()
        HORDE:SyncMapsTo(ply)
    end)
end
