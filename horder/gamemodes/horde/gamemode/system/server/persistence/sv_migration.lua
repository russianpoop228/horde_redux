if not SERVER then return end

HORDE = HORDE or {}
local DB = HORDE.DB

local OLD_DIR          = "horde"
local RANKS_DIR        = OLD_DIR .. "/ranks"
local TOKENS_DIR       = OLD_DIR .. "/tokens"
local UNLOCKS_DIR      = OLD_DIR .. "/subclass_unlocks"
local BACKUP_DIR       = OLD_DIR .. "/_migrated_backup"

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

local function IsIgnoredMigrationClass(name)
    if not name then return false end
    local ignored = {
        [HORDE.Class_Engineer] = true,
        [HORDE.Class_Warden]   = true,
    }
    return ignored[name] or false
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
            if name and not IsIgnoredMigrationClass(name) then
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
            if name and not IsIgnoredMigrationClass(name) then
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

local function ParseUnlockFile(path)
    local result = {}
    if not file.Exists(path, "DATA") then return nil, "file missing: " .. path end
    local size = file.Size(path, "DATA")
    if not size or size % 5 ~= 0 then return nil, "truncated unlock file: " .. path end
    local strm = file.Open(path, "rb", "DATA")
    if not strm then return nil, "could not open: " .. path end

    while not strm:EndOfFile() do
        local crc    = strm:ReadULong()
        if crc == nil then break end
        local status = strm:ReadBool()
        if status == nil then
            strm:Close()
            return nil, "truncated unlock record: " .. path
        end
        local name = SubclassNameFromCRC(crc)
        if name and not IsIgnoredMigrationClass(name) then
            result[name] = status and true or false
        elseif not name and status then
            log("WARNING: " .. path .. ": unknown unlocked subclass CRC skipped: " .. crc)
        end
    end
    strm:Close()
    return result
end

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
            VALUES (?, 1, ?, ?)
            ON CONFLICT(steamid) DO UPDATE SET migrated = 1, last_seen = excluded.last_seen;
        ]], steamid, now, now))
        return not err
    end)
end

local function EnsureBackupDirs()
    if not file.IsDir(BACKUP_DIR, "DATA") then file.CreateDir(BACKUP_DIR) end
    if not file.IsDir(BACKUP_DIR .. "/ranks", "DATA") then file.CreateDir(BACKUP_DIR .. "/ranks") end
    if not file.IsDir(BACKUP_DIR .. "/tokens", "DATA") then file.CreateDir(BACKUP_DIR .. "/tokens") end
    if not file.IsDir(BACKUP_DIR .. "/subclass_unlocks", "DATA") then file.CreateDir(BACKUP_DIR .. "/subclass_unlocks") end
end

local function ArchiveFile(src, sub)
    if not file.Exists(src, "DATA") then return true end
    if (file.Size(src, "DATA") or 0) == 0 then return true end
    local data = file.Read(src, "DATA")
    if data == nil then return false, "could not read " .. src end
    local fname = string.GetFileFromFilename(src)
    local backup = BACKUP_DIR .. "/" .. sub .. "/" .. fname
    file.Write(backup, data)
    if file.Read(backup, "DATA") ~= data then return false, "backup verification failed " .. backup end
    return true
end

local function HasData(path)
    return file.Exists(path, "DATA") and (file.Size(path, "DATA") or 0) > 0
end

local function MigrateScrubbed(scrubbed, steamid)
    if not DB.IsReady() then return false end

    local rank_path   = RANKS_DIR    .. "/" .. scrubbed .. ".txt"
    local token_path  = TOKENS_DIR   .. "/" .. scrubbed .. ".txt"
    local unlock_path = UNLOCKS_DIR  .. "/" .. scrubbed .. ".txt"

    local has_any = file.Exists(rank_path, "DATA")
                 or file.Exists(token_path, "DATA")
                 or file.Exists(unlock_path, "DATA")
    if not has_any then return false end

    logDev("Migrating " .. scrubbed .. " ...")

    local ranks, tokens, unlocks = {}, nil, {}
    local parse_error
    if HasData(rank_path) then
        ranks, parse_error = ParseRankFile(rank_path)
        if not ranks then return false, parse_error end
    end
    if HasData(token_path) then
        tokens, parse_error = ParseTokenFile(token_path)
        if tokens == nil then return false, parse_error end
    end
    if HasData(unlock_path) then
        unlocks, parse_error = ParseUnlockFile(unlock_path)
        if not unlocks then return false, parse_error end
    end

    EnsureBackupDirs()
    for _, entry in ipairs({{rank_path, "ranks"}, {token_path, "tokens"}, {unlock_path, "subclass_unlocks"}}) do
        local ok, err = ArchiveFile(entry[1], entry[2])
        if not ok then return false, err end
    end

    local ok, err = WriteMigrationData(steamid, ranks, tokens, unlocks)
    if not ok then return false, "database migration failed: " .. tostring(err) end

    for _, path in ipairs({rank_path, token_path, unlock_path}) do
        if file.Exists(path, "DATA") then
            file.Delete(path)
            if file.Exists(path, "DATA") then
                log("WARNING: migrated " .. steamid .. " but could not remove original " .. path .. "; verified backup and DB rows are retained.")
            end
        end
    end

    log("Migrated progress for " .. steamid)
    return true
end

local function UnscrubSteamID(scrubbed)
    if not isstring(scrubbed) then return nil end
    local universe, account, id = string.match(string.lower(scrubbed), "^steam_(%d+)_(%d+)_(%d+)$")
    if not universe then return nil end
    return "STEAM_" .. universe .. ":" .. account .. ":" .. id
end

local function IsMigrated(steamid)
    if not DB.IsReady() then return nil, true end
    local v, err = DB.QueryValue(
        DB.Prepare("SELECT migrated FROM horde_redux_players WHERE steamid = ?;", steamid)
    )
    return tonumber(v) == 1, err
end

local LEGACY_DIRS = {
    { RANKS_DIR,   "ranks" },
    { TOKENS_DIR,  "tokens" },
    { UNLOCKS_DIR, "subclass_unlocks" },
}

local function NeedsMigration(scrubbed, steamid)
    local fname = scrubbed .. ".txt"
    local any, unarchived = false, false
    for _, d in ipairs(LEGACY_DIRS) do
        if file.Exists(d[1] .. "/" .. fname, "DATA") then
            any = true
            if not file.Exists(BACKUP_DIR .. "/" .. d[2] .. "/" .. fname, "DATA") then
                unarchived = true
            end
        end
    end
    if not any then return false end
    local migrated, err = IsMigrated(steamid)
    if err then return nil, err end
    return (not migrated) or unarchived
end

function HORDE:TryMigratePlayer(ply)
    if not IsValid(ply) then return end
    if not DB.IsReady() then return end

    local steamid = ply:SteamID()
    local scrubbed = string.lower((steamid:gsub(":", "_")))
    local need, query_error = NeedsMigration(scrubbed, steamid)
    if query_error then return false, "could not query migration status" end
    if not need then return true end

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

function HORDE:RunBatchMigration()
    if not DB.IsReady() then return end
    if not file.IsDir(RANKS_DIR, "DATA")
       and not file.IsDir(TOKENS_DIR, "DATA")
       and not file.IsDir(UNLOCKS_DIR, "DATA") then
        logDev("No legacy data/horde save folders found — nothing to migrate.")
        return
    end

    local seen = {}
    local function collect(dir)
        local files = file.Find(dir .. "/*.txt", "DATA")
        if not files then return end
        for _, fname in ipairs(files) do
            local scrubbed = string.lower(string.StripExtension(fname))
            seen[scrubbed] = true
        end
    end
    collect(RANKS_DIR)
    collect(TOKENS_DIR)
    collect(UNLOCKS_DIR)

    local count = 0
    for scrubbed in pairs(seen) do
        local steamid = UnscrubSteamID(scrubbed)
        if not steamid then
            log("ERROR: ignoring malformed legacy filename " .. scrubbed .. "; original is untouched.")
        else
            local need, query_error = NeedsMigration(scrubbed, steamid)
            if query_error then
                log("ERROR: could not query migration status for " .. steamid .. "; originals are untouched.")
            elseif need then
                local ok, err = MigrateScrubbed(scrubbed, steamid)
                if ok then
                    count = count + 1
                elseif err then
                    log("ERROR: migration failed for " .. steamid .. ": " .. tostring(err))
                end
            end
        end
    end

    if count > 0 then
        log("Batch migration complete: " .. count .. " player(s) migrated to SQLite.")
    else
        logDev("Batch migration: nothing new to migrate.")
    end
end

hook.Add("Horde_AllModulesLoaded", "Horde_Redux_BatchMigration", function()
    timer.Simple(1, function()
        HORDE:RunBatchMigration()
    end)
end)
