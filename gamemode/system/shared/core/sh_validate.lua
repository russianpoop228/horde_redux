HORDE = HORDE or {}

HORDE.Limits = HORDE.Limits or {}
local L = HORDE.Limits

L.MaxCompressedBytes   = 65535
L.MaxDecompressedBytes = 8 * 1024 * 1024
L.MaxTableMessageBits  = 8 * 65535
L.MaxDepth     = 8
L.MaxNodes     = 200000
L.MaxStringLen = 8192
L.MaxPrice     = 1e9
L.MaxWeight    = 1e4
L.MaxWave      = 1000
L.MaxScale     = 1e3
L.MaxItems     = 20000
L.MaxEnemies   = 20000

local isnumber, isstring, istable, isbool = isnumber, isstring, istable, isbool

local function finite(n)
    return isnumber(n) and n == n and n ~= math.huge and n ~= -math.huge
end

function HORDE:SanityCheck(tbl, limits)
    if not istable(tbl) then return false, "not a table" end
    limits = limits or L
    local max_depth  = limits.MaxDepth     or L.MaxDepth
    local max_nodes  = limits.MaxNodes     or L.MaxNodes
    local max_strlen = limits.MaxStringLen or L.MaxStringLen

    local nodes = 0
    local stack = { { tbl, 1 } }
    local seen = { [tbl] = true }
    while #stack > 0 do
        local top = table.remove(stack)
        local t, depth = top[1], top[2]
        if depth > max_depth then return false, "table nested too deep" end
        for k, v in pairs(t) do
            nodes = nodes + 1
            if nodes > max_nodes then return false, "table too large" end

            local kt = type(k)
            if kt == "string" then
                if #k > max_strlen then return false, "key too long" end
            elseif kt ~= "number" then
                return false, "unsupported key type: " .. kt
            elseif not finite(k) then
                return false, "invalid numeric key"
            end

            local vt = type(v)
            if vt == "string" then
                if #v > max_strlen then return false, "string value too long" end
            elseif vt == "number" then
                if not finite(v) then return false, "non-finite number" end
            elseif vt == "table" then
                if seen[v] then return false, "circular or shared table reference" end
                seen[v] = true
                stack[#stack + 1] = { v, depth + 1 }
            elseif vt ~= "boolean" and vt ~= "Vector" and vt ~= "Angle" then
                return false, "unsupported value type: " .. vt
            end
        end
    end
    return true
end

function HORDE:DecodeCompressedJSON(data, limits)
    limits = limits or L
    if not isstring(data) or #data == 0 then return nil, "empty data" end
    if #data > (limits.MaxCompressedBytes or L.MaxCompressedBytes) then
        return nil, "payload too large"
    end
    local str = util.Decompress(data, limits.MaxDecompressedBytes or L.MaxDecompressedBytes)
    if not str then return nil, "decompression failed or limit exceeded" end
    local tbl = util.JSONToTable(str)
    if not istable(tbl) then return nil, "invalid JSON" end
    local ok, err = self:SanityCheck(tbl, limits)
    if not ok then return nil, err end
    return tbl
end

function HORDE:ReadCompressedJSON(limits)
    limits = limits or L
    local len = net.ReadUInt(32)
    if len == 0 or len > (limits.MaxCompressedBytes or L.MaxCompressedBytes) then
        return nil, "invalid payload length"
    end
    local left = net.BytesLeft and net.BytesLeft() or nil
    if left and len > left then return nil, "payload length exceeds message" end
    local data = net.ReadData(len)
    return self:DecodeCompressedJSON(data, limits)
end

function HORDE:TableMessageAllowed(len_bits)
    return isnumber(len_bits) and len_bits > 0 and len_bits <= L.MaxTableMessageBits
end

function HORDE:ReadTableSafe(len_bits, limits)
    if not self:TableMessageAllowed(len_bits) then return nil, "message too large" end
    local tbl = net.ReadTable()
    if not istable(tbl) then return nil, "invalid table" end
    local ok, err = self:SanityCheck(tbl, limits)
    if not ok then return nil, err end
    return tbl
end

HORDE.Validate = HORDE.Validate or {}
local V = HORDE.Validate

local function opt_string(t, f, maxlen)
    local v = t[f]
    if v == nil then return true end
    if not isstring(v) then return false, f .. " must be a string" end
    if #v > (maxlen or 256) then return false, f .. " too long" end
    return true
end

local function req_string(t, f, maxlen)
    local v = t[f]
    if not isstring(v) or v == "" then return false, f .. " must be a non-empty string" end
    if #v > (maxlen or 256) then return false, f .. " too long" end
    return true
end

local function num_range(t, f, lo, hi, required)
    local v = t[f]
    if v == nil then
        if required then return false, f .. " is required" end
        return true
    end
    if not finite(v) then return false, f .. " must be a finite number" end
    if v < lo or v > hi then return false, f .. " out of range [" .. lo .. ", " .. hi .. "]" end
    return true
end

local function opt_bool(t, f)
    local v = t[f]
    if v == nil or isbool(v) then return true end
    return false, f .. " must be a boolean"
end

local function opt_table(t, f)
    local v = t[f]
    if v == nil or istable(v) then return true end
    return false, f .. " must be a table"
end

local function opt_bool_legacy(t, f)
    local v = t[f]
    if v == nil or isbool(v) or v == 0 or v == 1 then return true end
    return false, f .. " must be a boolean"
end

local function opt_gadget_drop(t, f)
    local v = t[f]
    if v == nil then return true end
    if isstring(v) then
         if #v > 128 then return false, f .. " too long" end
         return true
    end
    if not istable(v) then return false, f .. " must be a table or string" end
    local g = v.gadget
    if g ~= nil and (not isstring(g) or #g > 128) then return false, f .. ".gadget must be a string" end
    local r = v.drop_rate
    if r ~= nil and (not finite(r) or r < 0 or r > 1) then return false, f .. ".drop_rate must be in [0, 1]" end
    return true
end

local function run(checks)
    for i = 1, #checks do
        local ok, err = checks[i]()
        if not ok then return false, err end
    end
    return true
end

local function string_bool_map(t, f)
    local v = t[f]
    if v == nil then return true end
    if not istable(v) then return false, f .. " must be a table" end
    for k, x in pairs(v) do
        if not isstring(k) or not isbool(x) then return false, f .. " must map strings to booleans" end
    end
    return true
end

local function string_number_map(t, f)
    local v = t[f]
    if v == nil then return true end
    if not istable(v) then return false, f .. " must be a table" end
    for k, x in pairs(v) do
        if not isstring(k) or not finite(x) then return false, f .. " must map strings to numbers" end
    end
    return true
end

local function scalar_array(t, f, want)
    local v = t[f]
    if v == nil then return true end
    if not istable(v) then return false, f .. " must be a table" end
    for k, x in pairs(v) do
        if not isnumber(k) then return false, f .. " must be an array" end
        if want == "string" and not isstring(x) then return false, f .. " must contain strings" end
        if want == "number" and not finite(x) then return false, f .. " must contain numbers" end
    end
    return true
end

function V.Item(key, item)
    if not isstring(key) or key == "" or #key > 128 then return false, "invalid item key" end
    if not istable(item) then return false, "item '" .. key .. "' is not a table" end

    if item.class ~= key then item.class = key end

    local ok, err = run({
        function() return req_string(item, "name", 128) end,
        function() return req_string(item, "category", 64) end,
        function() return num_range(item, "price", -1, L.MaxPrice, true) end,
        function() return num_range(item, "weight", 0, L.MaxWeight, true) end,
        function() return num_range(item, "ammo_price", -1, L.MaxPrice, true) end,
        function() return num_range(item, "secondary_ammo_price", -1, L.MaxPrice, true) end,
        function() return num_range(item, "skull_tokens", 0, L.MaxPrice) end,
        function() return opt_string(item, "description", 4096) end,
        function() return opt_string(item, "shop_icon", 260) end,
        function() return opt_bool(item, "hidden") end,
        function() return opt_bool(item, "price_manual") end,
        function()
            local q = item.quality
            if q == nil then return true end
            if not isstring(q) then return false, "quality must be a string" end
            if not (HORDE.Quality and HORDE.Quality[q]) then
                return false, "unknown quality '" .. q .. "'"
            end
            return true
        end,
        function() return string_bool_map(item, "whitelist") end,
        function() return string_number_map(item, "levels") end,
        function() return scalar_array(item, "starter_classes", "string") end,
        function() return scalar_array(item, "infusions", "number") end,
        function() return opt_table(item, "entity_properties") end,
    })
    if not ok then return false, "item '" .. key .. "': " .. err end

    local ep = item.entity_properties
    if ep then
        local ok2, err2 = run({
            function() return num_range(ep, "type", 0, 64) end,
            function() return num_range(ep, "x", -1e5, 1e5) end,
            function() return num_range(ep, "z", -1e5, 1e5) end,
            function() return num_range(ep, "yaw", -3600, 3600) end,
            function() return num_range(ep, "limit", 0, 1e4) end,
            function() return opt_bool(ep, "is_arccw_attachment") end,
            function() return opt_string(ep, "arccw_attachment_type", 128) end,
        })
        if not ok2 then return false, "item '" .. key .. "' entity_properties: " .. err2 end
    end
    return true
end

function V.Items(tbl)
    if not istable(tbl) then return false, "items must be a table" end
    local count = 0
    for key, item in pairs(tbl) do
        count = count + 1
        if count > L.MaxItems then return false, "too many items" end
        local ok, err = V.Item(key, item)
        if not ok then return false, err end
    end
    return true
end

function V.Enemy(key, enemy)
    if not isstring(key) or key == "" or #key > 256 then return false, "invalid enemy key" end
    if not istable(enemy) then return false, "enemy '" .. key .. "' is not a table" end
    local ok, err = run({
        function() return req_string(enemy, "name", 128) end,
        function() return req_string(enemy, "class", 128) end,
        function() return num_range(enemy, "weight", 0, 1e6, true) end,
        function() return num_range(enemy, "wave", 0, L.MaxWave, true) end,
        function() return num_range(enemy, "health_scale", 0, L.MaxScale) end,
        function() return num_range(enemy, "damage_scale", 0, L.MaxScale) end,
        function() return num_range(enemy, "reward_scale", 0, L.MaxScale) end,
        function() return num_range(enemy, "model_scale", 0, L.MaxScale) end,
        function() return num_range(enemy, "spawn_limit", 0, 1e5) end,
        function() return num_range(enemy, "spawn_min", 0, 1e5) end,
        function() return num_range(enemy, "skin", 0, 1e3) end,
        function() return opt_bool_legacy(enemy, "is_elite") end,
        function() return opt_string(enemy, "weapon", 128) end,
        function() return opt_string(enemy, "mutation", 128) end,
        function() return opt_string(enemy, "model", 260) end,
        function() return opt_gadget_drop(enemy, "gadget_drop") end,
        function() return opt_table(enemy, "boss_properties") end,
    })
    if not ok then return false, "enemy '" .. key .. "': " .. err end
    return true
end

function V.Enemies(tbl)
    if not istable(tbl) then return false, "enemies must be a table" end
    local count = 0
    for key, enemy in pairs(tbl) do
        count = count + 1
        if count > L.MaxEnemies then return false, "too many enemies" end
        local ok, err = V.Enemy(key, enemy)
        if not ok then return false, err end
    end
    return true
end

function V.Attachments(tbl)
    if not istable(tbl) then return false, "attachments must be a table" end
    local ok, err = HORDE:SanityCheck(tbl, { MaxDepth = 4, MaxNodes = 20000, MaxStringLen = 256 })
    if not ok then return false, err end
    return true
end
