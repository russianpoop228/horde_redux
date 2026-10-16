if not SERVER then return end

HORDE = HORDE or {}
local A  = HORDE.PlayerAchievements
local DB = HORDE.DB

local SAVE_INTERVAL   = 30
local GLOBAL_INTERVAL = 60
local MAX_PROGRESS    = 4294967295

local tables_ready = false
local function EnsureTables()
    if tables_ready then return true end
    if not (DB and DB.IsReady and DB.IsReady()) then return false end
    local ok = DB.Transaction(function(exec)
        for _, stmt in ipairs({
            [[CREATE TABLE IF NOT EXISTS horde_redux_achievements (
                steamid      TEXT NOT NULL,
                ach_id       TEXT NOT NULL,
                progress     INTEGER DEFAULT 0,
                unlocked_at  INTEGER DEFAULT 0,
                PRIMARY KEY (steamid, ach_id)
            );]],
            [[CREATE TABLE IF NOT EXISTS horde_redux_ach_players (
                steamid     TEXT PRIMARY KEY,
                first_seen  INTEGER
            );]],
            "CREATE INDEX IF NOT EXISTS idx_redux_ach_id ON horde_redux_achievements(ach_id);",
        }) do
            local _, err = exec(stmt)
            if err then return false end
        end
        return true
    end)
    tables_ready = ok and true or false
    return tables_ready
end

local function SteamKey(ply)
    if not IsValid(ply) or ply:IsBot() then return nil end
    return ply:SteamID()
end

local function Data(ply)
    if not ply.Horde_Ach then
        ply.Horde_Ach = { progress = {}, unlocked = {}, dirty = {}, loaded = false }
    end
    return ply.Horde_Ach
end

local global_owned = {}

local function RefreshGlobal()
    if not EnsureTables() then return end
    local total = tonumber((DB.QueryValue("SELECT COUNT(*) FROM horde_redux_ach_players;"))) or 0
    if total <= 0 then global_owned = {}; return end
    local rows = DB.Query("SELECT ach_id, COUNT(*) AS c FROM horde_redux_achievements WHERE unlocked_at > 0 GROUP BY ach_id;")
    local res = {}
    for _, r in ipairs(rows or {}) do
        res[r.ach_id] = math.Round(math.min(100, (tonumber(r.c) or 0) / total * 100), 2)
    end
    global_owned = res
end

function A:Load(ply)
    local d = Data(ply)
    d.loaded = true
    local sid = SteamKey(ply)
    if not sid or not EnsureTables() then return end

    DB.Query(DB.Prepare("INSERT OR IGNORE INTO horde_redux_ach_players (steamid, first_seen) VALUES (?, ?);", sid, os.time()))
    local rows = DB.QueryP("SELECT ach_id, progress, unlocked_at FROM horde_redux_achievements WHERE steamid = ?;", sid)
    for _, r in ipairs(rows or {}) do
        d.progress[r.ach_id] = tonumber(r.progress) or 0
        if (tonumber(r.unlocked_at) or 0) > 0 then d.unlocked[r.ach_id] = tonumber(r.unlocked_at) end
    end
end

function A:Save(ply)
    local d = IsValid(ply) and ply.Horde_Ach
    local sid = SteamKey(ply)
    if not d or not d.loaded or not sid or table.IsEmpty(d.dirty) or not EnsureTables() then return end
    local ok = DB.Transaction(function(exec)
        for id in pairs(d.dirty) do
            local _, err = exec(DB.Prepare([[
                INSERT INTO horde_redux_achievements (steamid, ach_id, progress, unlocked_at)
                VALUES (?, ?, ?, ?)
                ON CONFLICT(steamid, ach_id)
                DO UPDATE SET progress = excluded.progress, unlocked_at = excluded.unlocked_at;
            ]], sid, id, d.progress[id] or 0, d.unlocked[id] or 0))
            if err then return false end
        end
        return true
    end)
    if ok then d.dirty = {} end
end

function A:Sync(ply)
    if not IsValid(ply) or ply:IsBot() then return end
    local d = Data(ply)
    local list = {}
    for _, def in ipairs(self:List()) do
        if not (def.hidden and not d.unlocked[def.id]) then list[#list + 1] = def end
    end
    net.Start("Horde_Ach_Sync")
    net.WriteUInt(#list, 12)
    for _, def in ipairs(list) do
        net.WriteString(def.id)
        net.WriteUInt(math.min(MAX_PROGRESS, math.floor(d.progress[def.id] or 0)), 32)
        net.WriteBool(d.unlocked[def.id] ~= nil)
        net.WriteFloat(global_owned[def.id] or -1)
    end
    net.Send(ply)
end

local function GiveReward(ply, def)
    local rw = def.reward
    if not istable(rw) then return end
    if (tonumber(rw.skulls) or 0) > 0 and ply.Horde_AddSkullTokens then
        ply:Horde_AddSkullTokens(math.floor(rw.skulls))
    end
    if (tonumber(rw.exp) or 0) > 0 and GetConVar("horde_enable_rank"):GetInt() == 1 and ply.Horde_GetCurrentSubclass then
        local class_name = ply:Horde_GetCurrentSubclass()
        if class_name and ply:Horde_GetLevel(class_name) < HORDE.max_level then
            ply:Horde_SetExp(class_name, ply:Horde_GetExp(class_name) + math.floor(rw.exp))
        end
    end
    if isfunction(rw.func) then pcall(rw.func, ply, def) end
end

function A:Unlock(ply, id)
    local def = self.defs[id]
    if not def or not IsValid(ply) then return false end
    local d = Data(ply)
    if d.unlocked[id] then return false end

    d.unlocked[id] = os.time()
    d.progress[id] = def.goal
    d.dirty[id] = true
    self:Save(ply)

    if global_owned[id] == nil then global_owned[id] = 0 end
    GiveReward(ply, def)

    if not ply:IsBot() then
        net.Start("Horde_Ach_Unlocked")
        net.WriteString(id)
        net.Send(ply)
    end
    hook.Run("Horde_AchievementUnlocked", ply, def)
    timer.Simple(0.5, RefreshGlobal)
    return true
end

function A:SetProgress(ply, id, value)
    local def = self.defs[id]
    if not def or not IsValid(ply) then return end
    local d = Data(ply)
    if d.unlocked[id] then return end
    value = math.min(MAX_PROGRESS, math.max(0, math.floor(tonumber(value) or 0)))
    if d.progress[id] == value then return end
    d.progress[id] = value
    d.dirty[id] = true
    if value >= def.goal then self:Unlock(ply, id) end
end

function A:AddProgress(ply, id, amount)
    local def = self.defs[id]
    if not def or not IsValid(ply) then return end
    local d = Data(ply)
    if d.unlocked[id] then return end
    if def.mode == "max" then
        self:SetProgress(ply, id, math.max(d.progress[id] or 0, amount))
    else
        self:SetProgress(ply, id, (d.progress[id] or 0) + amount)
    end
end

function A:Fire(ply, event, ctx)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    ctx = ctx or {}
    local d = Data(ply)
    if not d.loaded then return end
    for _, id in ipairs(self.order) do
        local def = self.defs[id]
        if def and def.event == event and not d.unlocked[id] then
            local ok, pass = true, true
            if def.filter then ok, pass = pcall(def.filter, ply, ctx) end
            if ok and pass then
                local amount = 1
                if def.mode == "max" then
                    amount = tonumber(ctx.value) or 0
                elseif isfunction(def.amount) then
                    local aok, res = pcall(def.amount, ply, ctx)
                    amount = aok and tonumber(res) or 0
                end
                if amount > 0 then self:AddProgress(ply, id, amount) end
            end
        end
    end
end

hook.Add("PlayerInitialSpawn", "Horde_Ach_Load", function(ply)
    Data(ply)
    timer.Simple(3, function()
        if not IsValid(ply) then return end
        A:Load(ply)
        A:Sync(ply)
    end)
end)

hook.Add("PlayerDisconnected", "Horde_Ach_Save", function(ply)
    A:Save(ply)
end)

hook.Add("ShutDown", "Horde_Ach_SaveAll", function()
    for _, ply in ipairs(player.GetAll()) do A:Save(ply) end
end)

timer.Create("Horde_Ach_Autosave", SAVE_INTERVAL, 0, function()
    for _, ply in ipairs(player.GetAll()) do A:Save(ply) end
end)

timer.Create("Horde_Ach_Global", GLOBAL_INTERVAL, 0, RefreshGlobal)
timer.Simple(5, RefreshGlobal)

hook.Add("Horde_OnEnemyKilled", "Horde_Ach_Kill", function(victim, killer, wpn)
    if not IsValid(killer) or not killer:IsPlayer() then return end
    if (HORDE.current_wave or 0) <= 0 or GetConVar("sv_cheats"):GetInt() == 1 then return end
    if victim.Horde_NoReward then return end
    A:Fire(killer, "kill", {
        victim = victim,
        class  = victim:GetClass(),
        elite  = victim.Horde_IsElite and victim:Horde_IsElite() or false,
        weapon = wpn,
    })
end)

local last_req = {}
net.Receive("Horde_Ach_Request", function(_, ply)
    if not IsValid(ply) then return end
    local now = CurTime()
    if last_req[ply] and now - last_req[ply] < 0.8 then return end
    last_req[ply] = now
    local d = Data(ply)
    if not d.loaded then return end
    A:Sync(ply)
end)

hook.Add("PlayerDisconnected", "Horde_Ach_ReqCleanup", function(ply) last_req[ply] = nil end)
