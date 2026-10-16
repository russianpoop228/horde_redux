if not SERVER then return end

HORDE = HORDE or {}
local DB = HORDE.DB

local OLD_DIR          = "horde"
local RANKS_DIR        = OLD_DIR .. "/ranks"
local TOKENS_DIR       = OLD_DIR .. "/tokens"
local UNLOCKS_DIR      = OLD_DIR .. "/subclass_unlocks"

local HEADER_RANK      = "Horde_Rank"
local HEADER_TOKENS    = "Horde_Skull_Tokens"

local dev = GetConVar("developer")
local function log(msg)
    MsgC(Color(255, 200, 100), "[Horde Migration] " .. msg .. "\n")
end
local function logDev(msg)
    if dev and dev:GetBool() then log(msg) end
end

local function ClassNameFromOrder(order)
    return HORDE.order_to_class_name and HORDE.order_to_class_name[order] or nil
end

local function SubclassNameFromCRC(crc)
    if not HORDE.order_to_subclass_name then return nil end
    return HORDE.order_to_subclass_name[crc] or HORDE.order_to_subclass_name[tostring(crc)]
end

local function ParentOf(subclass_key)
    local sc = HORDE.subclasses and HORDE.subclasses[subclass_key]
    if sc and sc.ParentClass then return sc.ParentClass end
    return subclass_key
end

local function ParseRankFile(path)
    if not file.Exists(path, "DATA") then return nil, "file missing: " .. path end
    local data = file.Read(path, "DATA")
    if not data then return nil, "could not read: " .. path end
    if data:sub(1, #HEADER_RANK) ~= HEADER_RANK then
        logDev("Rank file has unexpected header, skipping: " .. path)
        return nil, "invalid rank header: " .. path
    end

    local body = data:sub(#HEADER_RANK + 1)
    local body_len = #body
    if body_len == 0 then
        return nil, "truncated rank file: " .. path
    end

    local function read_uint_le(off, size)
        if off + size > body_len then return nil end
        local sum, mul = 0, 1
        for i = 1, size do
            sum = sum + string.byte(body, off + i) * mul
            mul = mul * 256
        end
        return sum
    end

    local function to_signed(v)
        if v and v > 2147483647 then return v - 4294967296 end
        return v
    end

    local max_level = HORDE.max_level or 100
    local function Plausible(level, exp)
        return level <= max_level and to_signed(exp) >= 0
    end

    local function parse_alignment(k)
        local off = 0
        local result = {}
        local unknown = {}
        local score = 0
        for _ = 1, k do
            local order = read_uint_le(off, 2)
            local exp   = read_uint_le(off + 2, 4)
            local level = read_uint_le(off + 6, 2)
            if not order or not exp or not level then return nil end
            local name = ClassNameFromOrder(order)
            if name and not Plausible(level, exp) then return nil end
            if name then
                result[name] = { level = level, exp = to_signed(exp) }
                score = score + 1
            end
            off = off + 8
        end
        while off < body_len do
            local crc   = read_uint_le(off, 4)
            local exp   = read_uint_le(off + 4, 4)
            local level = read_uint_le(off + 8, 2)
            if not crc or not exp or not level then return nil end
            local name = SubclassNameFromCRC(crc) or SubclassNameFromCRC(to_signed(crc))
            if name and not Plausible(level, exp) then return nil end
            if name then
                result[name] = { level = level, exp = to_signed(exp) }
                score = score + 1
            elseif not name and (level > 0 or to_signed(exp) > 0) then
                unknown[#unknown + 1] = crc .. " (level " .. level .. ")"
            end
            off = off + 10
        end
        return result, score, unknown
    end

    local current_count = table.Count(HORDE.classes or {})
    local function search()
        local max_k = math.min(math.floor(body_len / 8), current_count + 32)
        local best, best_score, best_diff, best_unknown
        for k = 0, max_k do
            if (body_len - k * 8) % 10 == 0 then
                local result, score, unknown = parse_alignment(k)
                if result then
                    local diff = math.abs(k - current_count)
                    if not best
                        or score > best_score
                        or (score == best_score and diff < best_diff) then
                        best, best_score, best_diff, best_unknown = result, score, diff, unknown
                    end
                end
            end
        end
        return best, best_unknown, best_score
    end

    local best, best_unknown, best_score = search()
    if body:find("\r\n", 1, true) then
        local raw = body
        body = raw:gsub("\r\n", "\n")
        body_len = #body
        local fixed, fixed_unknown, fixed_score = search()
        if fixed and (not best or fixed_score > best_score) then
            best, best_unknown = fixed, fixed_unknown
            log("NOTE: repaired CRLF-corrupted rank file " .. path)
        end
    end
    if not best then
        return nil, "truncated or malformed rank file: " .. path
    end
    if #best_unknown > 0 then
        log("WARNING: " .. path .. ": unknown subclass CRC skipped: " .. table.concat(best_unknown, ", "))
    end
    return best
end

local function ParseTokenFile(path)
    if not file.Exists(path, "DATA") then return nil, "file missing: " .. path end
    local data = file.Read(path, "DATA")
    if not data then return nil, "could not read: " .. path end
    if data:sub(1, #HEADER_TOKENS) ~= HEADER_TOKENS then return nil, "invalid token header: " .. path end

    local body = data:sub(#HEADER_TOKENS + 1)
    if #body > 4 then body = body:gsub("\r\n", "\n") end
    if #body ~= 4 then return nil, "invalid or truncated token file: " .. path end

    local b1, b2, b3, b4 = string.byte(body, 1, 4)
    local tokens = b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
    if tokens > 2147483647 then tokens = tokens - 4294967296 end
    return tokens
end

local function DecodeUnlocks(data)
    if #data % 5 ~= 0 then return nil end
    local result, unknown, score = {}, {}, 0
    for i = 1, #data, 5 do
        local a, b, c, d, status = string.byte(data, i, i + 4)
        if status > 1 then return nil end
        local crc = a + b * 256 + c * 65536 + d * 16777216
        local name = SubclassNameFromCRC(crc)
        if name then
            score = score + 1
            result[name] = status == 1
        elseif not name and status == 1 then
            unknown[#unknown + 1] = crc
        end
    end
    return result, unknown, score
end

local function ParseUnlockFile(path)
    if not file.Exists(path, "DATA") then return nil, "file missing: " .. path end
    local data = file.Read(path, "DATA")
    if not data then return nil, "could not read: " .. path end

    local result, unknown, score = DecodeUnlocks(data)
    if data:find("\r\n", 1, true) then
        local fixed, fixed_unknown, fixed_score = DecodeUnlocks((data:gsub("\r\n", "\n")))
        if fixed and (not result or fixed_score > score) then
            result, unknown = fixed, fixed_unknown
            log("NOTE: repaired CRLF-corrupted unlock file " .. path)
        end
    end
    if not result then return nil, "truncated unlock file: " .. path end

    if #unknown > 0 then
        log("WARNING: " .. path .. ": unknown unlocked subclass CRC skipped: " .. table.concat(unknown, ", "))
    end
    return result
end

local MIGRATED = 1
local META_KEY = "legacy_migration"

local function WriteMigrationData(steamid, ranks, tokens, unlocks)
    return DB.Transaction(function(exec)
        for subclass_key, data in pairs(ranks or {}) do
            local _, err = exec(DB.Prepare([[
                INSERT INTO horde_redux_ranks (steamid, subclass_key, parent_class, level, exp)
                VALUES (?, ?, ?, ?, ?)
                ON CONFLICT(steamid, subclass_key) DO UPDATE SET level = excluded.level, exp = excluded.exp
                WHERE excluded.level > horde_redux_ranks.level
                   OR (excluded.level = horde_redux_ranks.level AND excluded.exp > horde_redux_ranks.exp);
            ]], steamid, subclass_key, ParentOf(subclass_key), data.level or 0, data.exp or 0))
            if err then return false end
        end
        if tokens ~= nil then
            local _, err = exec(DB.Prepare([[
                INSERT INTO horde_redux_tokens (steamid, tokens) VALUES (?, ?)
                ON CONFLICT(steamid) DO UPDATE SET tokens = horde_redux_tokens.tokens + excluded.tokens;
            ]], steamid, tokens))
            if err then return false end
        end
        for subclass_key, status in pairs(unlocks or {}) do
            local _, err = exec(DB.Prepare([[
                INSERT INTO horde_redux_unlocks (steamid, subclass_key, unlocked)
                VALUES (?, ?, ?)
                ON CONFLICT(steamid, subclass_key) DO UPDATE SET unlocked = MAX(horde_redux_unlocks.unlocked, excluded.unlocked);
            ]], steamid, subclass_key, status and 1 or 0))
            if err then return false end
        end
        local now = os.time()
        local _, err = exec(DB.Prepare([[
            INSERT INTO horde_redux_players (steamid, migrated, first_seen, last_seen)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(steamid) DO UPDATE SET migrated = excluded.migrated;
        ]], steamid, MIGRATED, now, now))
        return not err
    end)
end

local function HasData(path)
    return file.Exists(path, "DATA") and (file.Size(path, "DATA") or 0) > 0
end

local function LegacyPath(dir, scrubbed)
    local path = dir .. "/" .. scrubbed .. ".txt"
    if file.Exists(path, "DATA") then return path end
end

local function GetMigrationState(steamid)
    local v, err = DB.QueryValue(
        DB.Prepare("SELECT migrated FROM horde_redux_players WHERE steamid = ?;", steamid)
    )
    if err then return nil, true end
    return tonumber(v) or 0
end

local function MigrateScrubbed(scrubbed, steamid)
    local rank_path   = LegacyPath(RANKS_DIR,   scrubbed)
    local token_path  = LegacyPath(TOKENS_DIR,  scrubbed)
    local unlock_path = LegacyPath(UNLOCKS_DIR, scrubbed)
    if not rank_path and not token_path and not unlock_path then return false end

    local ranks, tokens, unlocks = {}, nil, {}
    local parse_error
    if rank_path and HasData(rank_path) then
        ranks, parse_error = ParseRankFile(rank_path)
        if not ranks then return false, parse_error end
    end
    if token_path and HasData(token_path) then
        tokens, parse_error = ParseTokenFile(token_path)
        if tokens == nil then return false, parse_error end
    end
    if unlock_path and HasData(unlock_path) then
        unlocks, parse_error = ParseUnlockFile(unlock_path)
        if not unlocks then return false, parse_error end
    end

    local ok, err = WriteMigrationData(steamid, ranks, tokens, unlocks)
    if not ok then return false, "database migration failed: " .. tostring(err) end

    log("Migrated progress for " .. steamid)
    return true
end

local function UnscrubSteamID(scrubbed)
    if not isstring(scrubbed) then return nil end
    local universe, account, id = string.match(string.lower(scrubbed), "^steam_(%d+)_(%d+)_(%d+)$")
    if not universe then return nil end
    return "STEAM_" .. universe .. ":" .. account .. ":" .. id
end

function HORDE:TryMigratePlayer(ply)
    if not IsValid(ply) then return end
    if not DB.IsReady() then return end

    local steamid = ply:SteamID()
    local scrubbed = string.lower((steamid:gsub(":", "_")))
    if not LegacyPath(RANKS_DIR, scrubbed)
       and not LegacyPath(TOKENS_DIR, scrubbed)
       and not LegacyPath(UNLOCKS_DIR, scrubbed) then
        return true
    end

    local state, query_error = GetMigrationState(steamid)
    if query_error then return false, "could not query migration status" end
    if state >= MIGRATED then return true end

    local ok, err = MigrateScrubbed(scrubbed, steamid)
    if ok then
        ply.Horde_Just_Migrated = true
    elseif err then
        log("ERROR: lazy migration failed for " .. steamid .. ": " .. tostring(err))
        if not ply.Horde_Migration_Failed then
            ply.Horde_Migration_Failed = true
            HORDE:SendNotification(
                "Old save migration failed; original files are kept untouched. Please contact an admin.",
                1, ply)
        end
    end
    return true
end

function HORDE:RunBatchMigration(force)
    if not DB.IsReady() then return end
    if not force then
        local done = DB.QueryValue(DB.Prepare("SELECT value FROM horde_redux_meta WHERE key = ?;", META_KEY))
        if tonumber(done) == MIGRATED then return end
    end

    local seen = {}
    local function collect(dir)
        local files = file.Find(dir .. "/*.txt", "DATA")
        if not files then return end
        for _, fname in ipairs(files) do
            seen[string.lower(string.StripExtension(fname))] = true
        end
    end
    collect(RANKS_DIR)
    collect(TOKENS_DIR)
    collect(UNLOCKS_DIR)

    local count, failed = 0, 0
    for scrubbed in pairs(seen) do
        local steamid = UnscrubSteamID(scrubbed)
        if not steamid then
            log("WARNING: ignoring malformed legacy filename " .. scrubbed)
        else
            local state, query_error = GetMigrationState(steamid)
            if query_error then
                log("ERROR: could not query migration status for " .. steamid)
                failed = failed + 1
            elseif state < MIGRATED then
                local ok, err = MigrateScrubbed(scrubbed, steamid)
                if ok then
                    count = count + 1
                elseif err then
                    log("ERROR: migration failed for " .. steamid .. ": " .. tostring(err))
                    failed = failed + 1
                end
            end
        end
    end

    if failed == 0 then
        DB.Query(DB.Prepare([[
            INSERT INTO horde_redux_meta (key, value) VALUES (?, ?)
            ON CONFLICT(key) DO UPDATE SET value = excluded.value;
        ]], META_KEY, MIGRATED))
    end

    log("Batch migration complete: " .. count .. " player(s) migrated, " .. failed .. " failed.")
end

hook.Add("Horde_AllModulesLoaded", "Horde_Redux_BatchMigration", function()
    timer.Simple(1, function()
        HORDE:RunBatchMigration()
    end)
end)
