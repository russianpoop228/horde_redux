if not CLIENT then return end

local RED      = Color(220, 30, 56)
local RED_H    = Color(240, 50, 76)
local RED_TXT  = Color(232, 39, 73)
local RED_DIM  = Color(74, 19, 27)
local WIN      = Color(31, 31, 31)
local CARD     = Color(60, 64, 70)
local CARD_H   = Color(72, 77, 84)
local TILE     = Color(38, 39, 43)
local TRACK    = Color(24, 25, 28)
local WH       = Color(255, 255, 255)
local DIM      = Color(150, 152, 158)
local GREEN    = Color(0, 230, 118)

local EMPTY_BG  = Color(36, 37, 42)
local STRIPE_L  = Color(255, 255, 255, 10)
local STRIPE_D  = Color(0, 0, 0, 89)
local PILL_HOV  = Color(40, 41, 43)
local TXT_FADED = Color(255, 255, 255, 105)
local TAB_HOVER = Color(255, 255, 255, 205)
local BAR_BG    = Color(21, 22, 25, 230)
local BAR_LINE  = Color(220, 30, 56, 153)
local BADGE_BG  = Color(0, 0, 0, 217)
local BADGE_OUTLINE = Color(0, 0, 0, 255)

local WINDOW_SCALE  = 1.5
local MAP_SLOTS      = 9
local MAP_COLS       = 3
local MAX_BADGES     = 15
local BADGES_PER_ROW = 5
local MARQUEE_SEC    = 6

local K = 1

local function S(v) return math.floor(v * K + 0.5) end
local function SB(v) return math.max(1, S(v)) end

local fonts_made = {}
local function Font(px, bold, mono)
    local size = math.max(9, S(px))
    local key = (mono and "M" or (bold and "B" or "R")) .. size
    local name = "HordeSummary_" .. key
    if not fonts_made[key] then
        local fscale = tonumber(translate.Get("Default_Font_Scale")) or 1
        local family
        if mono then
            family = "Courier New"
        else
            family = bold and translate.GetBoldFont() or translate.GetFont()
        end
        surface.CreateFont(name, {
            font = family,
            size = math.floor(size * fscale),
            weight = (bold or mono) and 700 or 500,
            extended = true,
        })
        fonts_made[key] = true
    end
    return name
end

local STR = {
    en = {
        Statistics = "Statistics", MapVoting = "Map Vote", Leaderboard = "Leaderboard",
        LbPlayer = "Player", LbKills = "Total Kills", LbMvps = "Total MVPs", LbLevel = "Level", LbLastSeen = "Last seen",
        LbOnline = "Online", LbEmpty = "No players yet", LbLoading = "Loading...",
        Difficulty = "Difficulty", Maps = "Maps", Modifiers = "Modifiers",
        Default = "Default", EmptySlot = "[Empty Slot]",
        Player = "Player", Class = "Class", Money = "Money",
        Kills = "Kills", Deaths = "Deaths", Ping = "Ping",
    },
    ru = {
        Statistics = "Статистика", MapVoting = "Голосование", Leaderboard = "Лидеры",
        LbPlayer = "Игрок", LbKills = "Всего убийств", LbMvps = "Всего MVP", LbLevel = "Уровень", LbLastSeen = "Был в сети",
        LbOnline = "В сети", LbEmpty = "Пока нет игроков", LbLoading = "Загрузка...",
        Difficulty = "Сложность", Maps = "Карты", Modifiers = "Модификаторы",
        Default = "Обычный", EmptySlot = "[Пустой слот]",
        Player = "Игрок", Class = "Класс", Money = "Деньги",
        Kills = "Убийства", Deaths = "Смерти", Ping = "Пинг",
    },
}

local function T(key)
    local v = translate.Get("Summary_" .. key)
    if v and v ~= "" then return v end
    local cv = GetConVar("gmod_language")
    local lang = cv and string.sub(string.lower(cv:GetString() or ""), 1, 2) or "en"
    local set = STR[lang] or STR.en
    return set[key] or STR.en[key] or key
end

local function TR(key, fallback)
    local v = translate.Get(key)
    if v and v ~= "" then return v end
    return fallback or key
end

local function IsLowerCP(cp) return (cp >= 0x61 and cp <= 0x7A) or (cp >= 0x430 and cp <= 0x45F) end
local function IsUpperCP(cp) return (cp >= 0x41 and cp <= 0x5A) or (cp >= 0x400 and cp <= 0x42F) end
local function LowerCP(cp)
    if cp >= 0x41 and cp <= 0x5A then return cp + 32 end
    if cp >= 0x410 and cp <= 0x42F then return cp + 32 end
    if cp >= 0x400 and cp <= 0x40F then return cp + 80 end
    return cp
end

local function TitleCase(s)
    s = tostring(s or "")
    local ok, res = pcall(function()
        local cps = {}
        for _, cp in utf8.codes(s) do
            if IsLowerCP(cp) then return s end
            cps[#cps + 1] = cp
        end
        local out, start = {}, true
        for _, cp in ipairs(cps) do
            if cp == 0x20 or cp == 0x5F or cp == 0x2D then
                start = true
                out[#out + 1] = utf8.char(cp == 0x5F and 0x20 or cp)
            else
                if IsUpperCP(cp) and not start then cp = LowerCP(cp) end
                start = false
                out[#out + 1] = utf8.char(cp)
            end
        end
        return table.concat(out)
    end)
    return ok and res or s
end

local function DiffLabel(name)
    return TitleCase(translate.Get("Game_Difficulty_" .. name) or name)
end

local function FitText(text, font, maxw)
    text = tostring(text or "")
    surface.SetFont(font)
    if (surface.GetTextSize(text)) <= maxw then return text end
    local len = utf8.len(text) or #text
    for n = len - 1, 1, -1 do
        local pos = utf8.offset(text, n + 1) or (#text + 1)
        local cut = string.sub(text, 1, pos - 1) .. "..."
        if (surface.GetTextSize(cut)) <= maxw then return cut end
    end
    return "..."
end

local function SndHover() surface.PlaySound("UI/buttonrollover.wav") end
local function SndClick() surface.PlaySound("UI/buttonclick.wav") end

local ARC_SEG = 6
local function DrawCornerMask(cx, cy, r, sx, sy, col)
    if r < 1 then return end
    local pts = { { x = cx, y = cy } }
    for i = 0, ARC_SEG do
        local a = math.rad(270 - 90 * i / ARC_SEG)
        pts[#pts + 1] = {
            x = cx + sx * (r + r * math.cos(a)),
            y = cy + sy * (r + r * math.sin(a)),
        }
    end
    if sx * sy < 0 then
        local rev = {}
        for i = #pts, 1, -1 do rev[#rev + 1] = pts[i] end
        pts = rev
    end
    draw.NoTexture()
    surface.SetDrawColor(col)
    surface.DrawPoly(pts)
end

local function ClipPoly(poly, x0, y0, x1, y1)
    local function clip(p, inside, cut)
        local out, n = {}, #p
        for i = 1, n do
            local a, b = p[i], p[i % n + 1]
            local ia, ib = inside(a), inside(b)
            if ia then out[#out + 1] = a end
            if ia ~= ib then out[#out + 1] = cut(a, b) end
        end
        return out
    end
    local function cutx(xv) return function(a, b)
        local t = (xv - a.x) / (b.x - a.x)
        return { x = xv, y = a.y + t * (b.y - a.y) }
    end end
    local function cuty(yv) return function(a, b)
        local t = (yv - a.y) / (b.y - a.y)
        return { x = a.x + t * (b.x - a.x), y = yv }
    end end
    local p = poly
    p = clip(p, function(q) return q.x >= x0 end, cutx(x0)); if #p < 3 then return {} end
    p = clip(p, function(q) return q.x <= x1 end, cutx(x1)); if #p < 3 then return {} end
    p = clip(p, function(q) return q.y >= y0 end, cuty(y0)); if #p < 3 then return {} end
    p = clip(p, function(q) return q.y <= y1 end, cuty(y1))
    return p
end

local function BuildStripes(ox, oy, w, h)
    local polys = {}
    local band = 10 * K * 1.41421
    local total, L = w + h, w + h
    local c, i = 0, 0
    while c < total do
        local c2 = c + band
        local quad = {
            { x = c / 2 - L,  y = c / 2 + L },
            { x = c / 2 + L,  y = c / 2 - L },
            { x = c2 / 2 + L, y = c2 / 2 - L },
            { x = c2 / 2 - L, y = c2 / 2 + L },
        }
        local p = ClipPoly(quad, 0, 0, w, h)
        if #p >= 3 then
            for _, v in ipairs(p) do v.x = v.x + ox; v.y = v.y + oy end
            polys[#polys + 1] = { poly = p, col = (i % 2 == 0) and STRIPE_L or STRIPE_D }
        end
        c = c2
        i = i + 1
    end
    return polys
end

local dims_cache = setmetatable({}, { __mode = "k" })
local function MatDims(mat)
    local d = dims_cache[mat]
    if d then return d[1], d[2] end
    local w = mat:GetInt("$realwidth") or 0
    local h = mat:GetInt("$realheight") or 0
    if w <= 0 or h <= 0 then w, h = mat:Width() or 0, mat:Height() or 0 end
    if w <= 0 or h <= 0 then w, h = 1, 1 end
    dims_cache[mat] = { w, h }
    return w, h
end

local function MaterialTextureFlags(displayW, displayH)
    displayW, displayH = tonumber(displayW), tonumber(displayH)
    if displayW and displayH and displayW > 0 and displayH > 0
        and displayW < 95 and displayH < 95 then
        return "mips smooth"
    end
    return "mips"
end

local function DrawCover(mat, x, y, w, h)
    local mw, mh = MatDims(mat)
    local ta, ia = w / h, mw / mh
    local u0, v0, u1, v1 = 0, 0, 1, 1
    if ia > ta then
        local f = ta / ia
        u0 = (1 - f) / 2; u1 = 1 - u0
    else
        local f = ia / ta
        v0 = (1 - f) / 2; v1 = 1 - v0
    end
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(mat)
    surface.DrawTexturedRectUV(x, y, w, h, u0, v0, u1, v1)
end

local votes_map = {}
local votes_diff = {}
local votes_map_players = {}
local remaining_time = 60
local vote_rev = 0

net.Receive("Horde_VotemapSync", function()
    votes_map = net.ReadTable() or {}
    vote_rev = vote_rev + 1
end)

net.Receive("Horde_VotediffSync", function()
    votes_diff = net.ReadTable() or {}
    vote_rev = vote_rev + 1
end)

net.Receive("Horde_RemainingTime", function()
    remaining_time = net.ReadInt(8)
end)

net.Receive("Horde_VotemapPlayersSync", function()
    local n = net.ReadUInt(8)
    local t = {}
    for _ = 1, n do
        local ply = net.ReadEntity()
        local map = net.ReadString()
        if IsValid(ply) then
            t[map] = t[map] or {}
            t[map][#t[map] + 1] = ply
        end
    end
    votes_map_players = t
    vote_rev = vote_rev + 1
end)

local VOTE_INTERVAL = 0.16
local last_vote = {}
local function SendVote(key, write)
    local function send()
        last_vote[key] = CurTime()
        net.Start(key)
        write()
        net.SendToServer()
    end
    local wait = VOTE_INTERVAL - (CurTime() - (last_vote[key] or -VOTE_INTERVAL))
    if wait > 0 then
        timer.Simple(wait, send)
    else
        send()
    end
end

local function SendMapVote(map)
    SendVote("Horde_Votemap", function()
        net.WriteString(map)
    end)
end

local function SendDiffVote(base, mod)
    SendVote("Horde_Votediff", function()
        net.WriteString(base or "")
        net.WriteString(mod or "")
    end)
end

local function DifficultyVotingDisabled()
    local cv = GetConVar("horde_disable_difficulty_voting")
    return cv ~= nil and cv:GetInt() == 1
end

local function BuildBadgeList(map, own_map)
    local list, seen = {}, {}
    for _, p in ipairs(votes_map_players[map] or {}) do
        if IsValid(p) and not seen[p] then list[#list + 1] = p; seen[p] = true end
    end
    local count = votes_map[map] or 0
    while #list < count do list[#list + 1] = false end

    if #list > MAX_BADGES then
        local extra = #list - (MAX_BADGES - 1)
        for i = #list, MAX_BADGES, -1 do list[i] = nil end
        list[#list + 1] = { more = extra }
    end
    return list
end

local function CollectDifficulties()
    local base, mods = {}, {}
    local by_name = {}
    for _, def in pairs(HORDE._difficulties or {}) do
        if istable(def) and def.Name then by_name[def.Name] = def end
    end
    for _, entry in ipairs(HORDE:GetDifficultyNameList()) do
        local name = entry.name
        if not (HORDE.IsDifficultyHidden and HORDE:IsDifficultyHidden(name)) then
            local def = by_name[name]
            local is_mod
            if def and HORDE.IsModifier then
                is_mod = HORDE:IsModifier(def)
            elseif def and HORDE.GetDifficultyInclude then
                is_mod = HORDE:GetDifficultyInclude(def) ~= nil
            else
                is_mod = entry.index > 4
            end
            if is_mod then mods[#mods + 1] = name else base[#base + 1] = name end
        end
    end
    for i, name in ipairs(mods) do
        if name == "WAVE_666" then
            table.remove(mods, i)
            mods[#mods + 1] = name
            break
        end
    end
    return base, mods
end

local Icons = {}
do
    local ICON_DIR      = "horde/mapicons_v2"
    local ICON_SIZE     = 256
    local STEP_TIMEOUT  = 10
    local MAX_ACTIVE    = 2
    local HOOK_ID       = "Horde_Summary_MapIconCapture"

    local entries   = {}
    local jobs      = {}
    local queue     = {}
    local active    = 0
    local map_index = nil
    local index_state = "idle"
    local index_waiters = {}
    local rt

    local function SafeName(map)
        return (string.gsub(string.lower(map), "[^%w_%-%.]", "_"))
    end

    local function IconPath(map) return ICON_DIR .. "/" .. SafeName(map) .. ".png" end

    local function CleanupStaleCache(serverMaps)
        if not istable(serverMaps) or #serverMaps == 0 then return end

        local available = {}
        for _, map in ipairs(serverMaps) do
            if isstring(map) and map ~= "" then
                available[SafeName(map) .. ".png"] = true
            end
        end
        if next(available) == nil then return end

        local files = file.Find(ICON_DIR .. "/*.png", "DATA") or {}
        for _, name in ipairs(files) do
            if not available[string.lower(name)] then
                file.Delete(ICON_DIR .. "/" .. name)
            end
        end

        for map, entry in pairs(entries) do
            if not available[SafeName(map) .. ".png"] then
                entry.mat = nil
                entry.state = "idle"
                entries[map] = nil
            end
        end
        for _, job in pairs(jobs) do
            for map in pairs(job.maps or {}) do
                if not available[SafeName(map) .. ".png"] then
                    job.maps[map] = nil
                end
            end
        end
    end

    net.Receive("Horde_Summary_MapCacheSync", function()
        local serverMaps = net.ReadTable()
        CleanupStaleCache(serverMaps)
        if Icons.Prefetch then Icons.Prefetch(serverMaps) end
    end)

    local function EnsureDir()
        if not file.IsDir("horde", "DATA") then file.CreateDir("horde") end
        if not file.IsDir(ICON_DIR, "DATA") then file.CreateDir(ICON_DIR) end
    end

    local function WritePng(map, data)
        if not data or data == "" then return end
        pcall(function()
            EnsureDir()
            file.Write(IconPath(map), data)
        end)
    end

    local function TryMaterial(paths, displayW, displayH)
        local flags = MaterialTextureFlags(displayW, displayH)
        for _, p in ipairs(paths) do
            local ok, m = pcall(Material, p, flags)
            if ok and m and not m:IsError() then return m end
        end
    end

    local function BuildIndex()
        if index_state ~= "idle" then return end
        index_state = "building"
        map_index = {}
        local ok, addons = pcall(engine.GetAddons)
        addons = (ok and addons) or {}
        local i = 0
        local function step()
            local n = 0
            while i < #addons and n < 25 do
                i = i + 1
                n = n + 1
                local a = addons[i]
                if a and a.mounted and a.title and a.wsid and a.wsid ~= "" and a.wsid ~= "0" then
                    local files = file.Find("maps/*.bsp", a.title)
                    if files then
                        for _, f in ipairs(files) do
                            local m = string.lower(string.StripExtension(f))
                            if not map_index[m] then
                                map_index[m] = { wsid = tostring(a.wsid), title = a.title }
                            end
                        end
                    end
                end
            end
            if i >= #addons then
                index_state = "ready"
                local waiters = index_waiters
                index_waiters = {}
                for _, cb in ipairs(waiters) do pcall(cb) end
            else
                timer.Simple(0, step)
            end
        end
        step()
    end

    local function WithIndex(cb)
        if index_state == "ready" then cb() return end
        index_waiters[#index_waiters + 1] = cb
        BuildIndex()
    end

    local capture_queue = {}

    local function RenderPng(mat)
        local mw, mh = MatDims(mat)
        local u0, v0, u1, v1 = 0, 0, 1, 1
        if mw > mh then
            local o = (mw - mh) / (mw * 2)
            u0, u1 = o, 1 - o
        elseif mh > mw then
            local o = (mh - mw) / (mh * 2)
            v0, v1 = o, 1 - o
        end
        rt = rt or GetRenderTargetEx("horde_mapicon_rt", ICON_SIZE, ICON_SIZE,
            RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_NONE, 0, 0, IMAGE_FORMAT_RGBA8888)
        render.PushRenderTarget(rt)
        local ok, data = pcall(function()
            render.Clear(0, 0, 0, 0, true, true)
            cam.Start2D()
            local drew = pcall(function()
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(mat)
                surface.DrawTexturedRectUV(0, 0, ICON_SIZE, ICON_SIZE, u0, v0, u1, v1)
            end)
            cam.End2D()
            if not drew then return nil end
            return render.Capture({ format = "png", x = 0, y = 0, w = ICON_SIZE, h = ICON_SIZE, alpha = true })
        end)
        render.PopRenderTarget()
        return ok and data or nil
    end

    local function ForeignPopupOpen()
        for _, p in ipairs(vgui.GetWorldPanel():GetChildren()) do
            if IsValid(p) and p:IsVisible() then
                local n = string.lower(tostring(p.ClassName or ""))
                if string.find(n, "pointshop", 1, true) or string.find(n, "ps2", 1, true) then return true end
            end
        end
        return false
    end

    local function OnPostRender()
        if ForeignPopupOpen() then return end
        local job = table.remove(capture_queue, 1)
        if job then
            local ok, data = pcall(RenderPng, job.mat)
            pcall(job.cb, ok and data or nil)
        end
        if #capture_queue == 0 then hook.Remove("PostRender", HOOK_ID) end
    end

    local function Capture(mat, cb)
        capture_queue[#capture_queue + 1] = { mat = mat, cb = cb }
        hook.Add("PostRender", HOOK_ID, OnPostRender)
    end

    local Pump

    local function FinishJob(job, ok)
        if job.done then return end
        job.done = true
        timer.Remove("Horde_MapIcon_" .. job.wsid)
        active = math.max(0, active - 1)

        if not ok then
            job.state = "failed"
            for _, e in pairs(job.maps) do
                e.mat = nil
                e.state = "failed"
            end
            Pump()
            return
        end

        job.state = "capturing"
        Capture(job.mat, function(data)
            job.png = data
            local ready = false
            if data and data ~= "" then
                for map, e in pairs(job.maps) do
                    WritePng(map, data)
                    e.material_paths = { "data/" .. IconPath(map), "../data/" .. IconPath(map) }
                    if e.display_w then
                        e.mat = TryMaterial(e.material_paths, e.display_w, e.display_h)
                        e.material_flags = e.mat and MaterialTextureFlags(e.display_w, e.display_h) or nil
                        e.state = e.mat and "ready" or "failed"
                    else
                        e.mat = nil
                        e.state = "ready"
                    end
                    if e.state == "ready" then ready = true end
                end
            else
                for _, e in pairs(job.maps) do
                    e.mat = nil
                    e.state = "failed"
                end
            end
            job.state = ready and "ready" or "failed"
            Pump()
        end)
        Pump()
    end

    local function StartJob(job)
        job.state = "loading"
        active = active + 1
        local timer_name = "Horde_MapIcon_" .. job.wsid
        local function arm()
            timer.Create(timer_name, STEP_TIMEOUT, 1, function() FinishJob(job, false) end)
        end
        arm()

        local ok_fi = pcall(steamworks.FileInfo, job.wsid, function(info)
            if job.done then return end
            if not info or info.error or not info.previewid then return FinishJob(job, false) end
            arm()
            local ok_dl = pcall(steamworks.Download, info.previewid, true, function(path)
                if job.done then return end
                if not path then return FinishJob(job, false) end
                local ok_m, mat = pcall(AddonMaterial, path)
                if not ok_m or not mat or mat:IsError() then return FinishJob(job, false) end
                job.mat = mat
                FinishJob(job, true)
            end)
            if not ok_dl then FinishJob(job, false) end
        end)
        if not ok_fi then FinishJob(job, false) end
    end

    Pump = function()
        while active < MAX_ACTIVE and #queue > 0 do
            local job = table.remove(queue, 1)
            if job.state == "queued" then StartJob(job) end
        end
    end

    local function GetEntry(map, displayW, displayH)
        local e = entries[map]
        if e then
            e.display_w, e.display_h = displayW or e.display_w, displayH or e.display_h
            return e
        end
        e = { state = "idle", display_w = displayW, display_h = displayH }
        entries[map] = e

        if file.Exists("maps/thumb/" .. map .. ".png", "GAME") then
            e.material_paths = { "maps/thumb/" .. map .. ".png" }
            e.mat = TryMaterial(e.material_paths, e.display_w, e.display_h)
        end
        if not e.mat and file.Exists(IconPath(map), "DATA") then
            e.material_paths = { "data/" .. IconPath(map), "../data/" .. IconPath(map) }
            e.mat = TryMaterial(e.material_paths, e.display_w, e.display_h)
        end
        if e.mat then
            e.state = "ready"
            e.material_flags = MaterialTextureFlags(e.display_w, e.display_h)
        end
        return e
    end

    local function Attach(map, e, urgent)
        local info = map_index and map_index[string.lower(map)]
        if not info then e.state = "failed" return end

        local job = jobs[info.wsid]
        if not job then
            job = { wsid = info.wsid, state = "queued", maps = {} }
            jobs[info.wsid] = job
            if urgent then table.insert(queue, 1, job) else queue[#queue + 1] = job end
        elseif urgent then
            if job.state == "queued" then
                table.RemoveByValue(queue, job)
                table.insert(queue, 1, job)
            elseif job.state == "failed" and not job.retried then
                job.retried = true
                job.state, job.done, job.mat, job.png = "queued", nil, nil, nil
                table.insert(queue, 1, job)
            end
        end
        job.maps[map] = e

        if job.state == "ready" then
            if job.png then WritePng(map, job.png) end
            e.material_paths = { "data/" .. IconPath(map), "../data/" .. IconPath(map) }
            if e.display_w then
                e.mat = TryMaterial(e.material_paths, e.display_w, e.display_h)
                e.material_flags = e.mat and MaterialTextureFlags(e.display_w, e.display_h) or nil
                e.state = e.mat and "ready" or "failed"
            else
                e.state = "ready"
            end
        elseif job.state == "failed" then
            e.state = "failed"
        end
    end

    function Icons.Request(map, displayW, displayH)
        if not isstring(map) or map == "" then return nil end
        local e = GetEntry(map, displayW, displayH)
        local wantedFlags = MaterialTextureFlags(e.display_w, e.display_h)

        if e.state == "ready" and not e.mat and e.material_paths and e.display_w then
            e.mat = TryMaterial(e.material_paths, e.display_w, e.display_h)
            e.material_flags = e.mat and wantedFlags or nil
            if not e.mat then e.state = "failed" end
        end

        if e.mat and e.material_paths and e.material_flags ~= wantedFlags then
            e.mat = TryMaterial(e.material_paths, e.display_w, e.display_h)
            e.material_flags = e.mat and wantedFlags or nil
        end

        if e.state == "failed" and not e.retried then
            e.retried = true
            e.state = "pending"
            e.urgent = true
            WithIndex(function() Attach(map, e, true) Pump() end)
            return e.mat
        end

        if e.state == "pending" and not e.urgent then
            e.urgent = true
            WithIndex(function() Attach(map, e, true) Pump() end)
            return e.mat
        end

        if e.state ~= "idle" then return e.mat end
        e.state = "pending"
        e.urgent = true

        WithIndex(function() Attach(map, e, true) Pump() end)
        return e.mat
    end

    function Icons.Prefetch(maps)
        if not istable(maps) then return end
        local todo = {}
        for _, map in ipairs(maps) do
            if isstring(map) and map ~= "" and not entries[map]
                and not file.Exists("maps/thumb/" .. map .. ".png", "GAME")
                and not file.Exists(IconPath(map), "DATA") then
                local e = { state = "pending" }
                entries[map] = e
                todo[#todo + 1] = { map, e }
            end
        end
        if #todo == 0 then return end

        WithIndex(function()
            for _, it in ipairs(todo) do
                if entries[it[1]] == it[2] then Attach(it[1], it[2], false) end
            end
            Pump()
        end)
    end

    hook.Add("InitPostEntity", "Horde_Summary_MapIconIndex", function()
        timer.Simple(20, BuildIndex)
    end)
end

local SCROLL = {}

local function VListLayout(self, x, cw, vh, off, dry)
    local gap = S(8)
    local y = 0
    for _, it in ipairs(self.items) do
        if IsValid(it) then
            local ih = it.item_h or it:GetTall()
            if not dry then
                it:SetPos(x, y - off)
                it:SetSize(cw, ih)
            end
            y = y + ih + gap
        end
    end
    return math.max(0, y - gap)
end

local function MapGridLayout(self, x, cw, vh, off, dry)
    local gap = S(8)
    local cell_w = (cw - gap * (MAP_COLS - 1)) / MAP_COLS
    local cell_h = (vh - gap * 2) / 3
    local n = #self.items
    local rows = math.max(3, math.ceil(n / MAP_COLS))
    if not dry then
        for i, it in ipairs(self.items) do
            if IsValid(it) then
                local r, c = math.floor((i - 1) / MAP_COLS), (i - 1) % MAP_COLS
                it:SetPos(math.floor(x + c * (cell_w + gap)), math.floor(r * (cell_h + gap) - off))
                it:SetSize(math.floor(cell_w), math.floor(cell_h))
            end
        end
    end
    self.wheel_step = cell_h + gap
    return rows * cell_h + (rows - 1) * gap
end

function SCROLL:Init()
    self.items = {}
    self.offset, self.max_off, self.content_h = 0, 0, 0
    self.has_bar = false
    self.bar_side = "right"
    self.pad_always = true
    self.layout_fn = VListLayout
end

function SCROLL:Configure(side, pad_always, layout_fn)
    self.bar_side = side or "right"
    self.pad_always = pad_always ~= false
    self.layout_fn = layout_fn or VListLayout
    self:InvalidateLayout()
end

function SCROLL:AddItem(p)
    p:SetParent(self)
    self.items[#self.items + 1] = p
    self:InvalidateLayout()
end

function SCROLL:ClearItems()
    for _, p in ipairs(self.items) do
        if IsValid(p) then p:Remove() end
    end
    self.items = {}
    self.offset = 0
    self:InvalidateLayout()
end

function SCROLL:Metrics(w, has_bar)
    local pad, bw = S(6), S(5)
    if self.bar_side == "left" then
        local x = (has_bar and bw or 0) + pad
        return x, w - x
    end
    local extra = 0
    if has_bar then extra = bw + pad elseif self.pad_always then extra = pad end
    return 0, w - extra
end

function SCROLL:PerformLayout()
    local w, h = self:GetSize()
    if w < 2 or h < 2 then return end
    local fn = self.layout_fn
    local x, cw = self:Metrics(w, false)
    local ch = fn(self, x, cw, h, 0, true)
    self.has_bar = ch > h + 1
    if self.has_bar then
        x, cw = self:Metrics(w, true)
        ch = fn(self, x, cw, h, 0, true)
    end
    self.content_h = ch
    self.max_off = math.max(0, ch - h)
    self.offset = math.Clamp(self.offset, 0, self.max_off)
    fn(self, x, cw, h, self.offset, false)
end

function SCROLL:SetOffset(v)
    v = math.Clamp(v, 0, self.max_off)
    if v ~= self.offset then
        self.offset = v
        self:InvalidateLayout(true)
    end
end

function SCROLL:ThumbRect()
    local w, h = self:GetSize()
    local bw = S(5)
    local bx = (self.bar_side == "left") and 0 or (w - bw)
    local th = math.max(S(24), math.floor(h * h / math.max(1, self.content_h)))
    local ty = self.max_off > 0 and math.floor((h - th) * (self.offset / self.max_off)) or 0
    return bx, bw, ty, th
end

function SCROLL:Paint(w, h)
    if not self.has_bar then return end
    local bx, bw, ty, th = self:ThumbRect()
    local r = math.floor(bw / 2)
    draw.RoundedBox(r, bx, 0, bw, h, TRACK)
    local hot = self.dragging
    if not hot and self:IsHovered() then
        local mx = self:CursorPos()
        hot = mx >= bx - S(4) and mx <= bx + bw + S(4)
    end
    draw.RoundedBox(r, bx, ty, bw, th, hot and RED_H or RED)
end

function SCROLL:OnMouseWheeled(delta)
    if self.max_off <= 0 then return false end
    self:SetOffset(self.offset - delta * (self.wheel_step or S(48)))
    return true
end

function SCROLL:OnMousePressed(code)
    if code ~= MOUSE_LEFT or not self.has_bar then return end
    local mx, my = self:CursorPos()
    local bx, bw, ty, th = self:ThumbRect()
    if mx < bx - S(6) or mx > bx + bw + S(6) then return end
    if my < ty or my > ty + th then
        local frac = math.Clamp((my - th / 2) / math.max(1, self:GetTall() - th), 0, 1)
        self:SetOffset(frac * self.max_off)
    end
    self.dragging = true
    self.drag_y, self.drag_off = my, self.offset
    self:MouseCapture(true)
end

function SCROLL:OnMouseReleased()
    self.dragging = false
    self:MouseCapture(false)
end

function SCROLL:Think()
    if not self.dragging then return end
    local _, my = self:CursorPos()
    local _, _, _, th = self:ThumbRect()
    local travel = math.max(1, self:GetTall() - th)
    self:SetOffset(self.drag_off + (my - self.drag_y) * self.max_off / travel)
end

vgui.Register("HordeSummaryScroll", SCROLL, "Panel")

local PILL = {}

function PILL:Init()
    self:SetText("")
    self.item_h = S(38)
end

function PILL:Setup(label, accent, state_fn, on_click)
    self.label, self.accent = label, accent
    self.state_fn, self.on_click = state_fn, on_click
end

function PILL:OnCursorEntered() SndHover() end

function PILL:OnMousePressed(code)
    if code ~= MOUSE_LEFT then return end
    if self._click_lock and self._click_lock > RealTime() then return end
    self._click_lock = RealTime() + 0.12
    SndClick()
    if self.on_click then self.on_click() end
end

function PILL:DoClick()
end

function PILL:Paint(w, h)
    local active, faded, votes = self.state_fn()
    local hov = self:IsHovered()
    local b = SB(1.5)
    local border
    if active then border = RED
    elseif self.accent then border = hov and RED or RED_DIM
    else border = hov and CARD_H or CARD end

    local r = math.floor(h / 2)
    draw.RoundedBox(r, 0, 0, w, h, border)
    draw.RoundedBox(math.max(0, r - b), b, b, w - 2 * b, h - 2 * b, hov and PILL_HOV or WIN)

    local col = self.accent and RED_TXT or WH
    if faded and not hov then col = TXT_FADED end
    draw.SimpleText(self.label, Font(14.5, false), w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if votes and votes > 0 then
        draw.SimpleText(votes .. "/" .. player.GetCount(), Font(12, false),
            w - S(16), h / 2, active and WH or DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
end

vgui.Register("HordeSummaryPill", PILL, "DButton")

local NAMEBAR = {}

function NAMEBAR:Init()
    self:SetMouseInputEnabled(false)
    self.alpha, self.t0, self.text, self.dim = 0, 0, "", false
    self.inner = vgui.Create("DPanel", self)
    self.inner:SetMouseInputEnabled(false)
    self.inner.Paint = function(_, w, h) self:PaintText(w, h) end
end

function NAMEBAR:SetLabel(text, dim)
    self.text, self.dim = text or "", dim and true or false
end

function NAMEBAR:Restart() self.t0 = CurTime() end

function NAMEBAR:PerformLayout(w, h)
    self.inner:SetPos(S(8), 0)
    self.inner:SetSize(math.max(1, w - S(16)), math.max(1, h - SB(1)))
end

function NAMEBAR:Paint(w, h)
    surface.SetAlphaMultiplier(self.alpha)
    surface.SetDrawColor(BAR_BG)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(BAR_LINE)
    surface.DrawRect(0, h - SB(1), w, SB(1))
end

function NAMEBAR:PaintText(w, h)
    local font = Font(11, false, true)
    local col = self.dim and DIM or WH
    surface.SetFont(font)
    local tw = surface.GetTextSize(self.text)
    if tw <= w then
        draw.SimpleText(self.text, font, 0, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        return
    end
    local unit = self.text .. "  \226\128\162  "
    local uw = surface.GetTextSize(unit)
    local off = -uw * (((CurTime() - self.t0) % MARQUEE_SEC) / MARQUEE_SEC)
    draw.SimpleText(unit, font, off, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(unit, font, off + uw, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

function NAMEBAR:PaintOver()
    surface.SetAlphaMultiplier(1)
end

vgui.Register("HordeSummaryNameBar", NAMEBAR, "Panel")

local BADGE = {}

function BADGE:Init()
    self:SetMouseInputEnabled(false)
    self.scale   = 0.2
    self.vel     = 0
    self.off_y   = 1
    self.off_vel = 0
    self.spawn   = true
    self.anchor_x, self.anchor_y = 0, 0
    self.base_s = 24
end

function BADGE:Setup(entry)
    self.entry = entry
    if isentity(entry) and IsValid(entry) and entry:IsPlayer() then
        self.me = (entry == LocalPlayer())
        self.avatar = vgui.Create("AvatarImage", self)
        self.avatar:SetMouseInputEnabled(false)
        self.avatar:SetPlayer(entry, 32)
    end
end

function BADGE:SetAnchor(x, y, base_s)
    self.anchor_x, self.anchor_y, self.base_s = x, y, base_s
    self:ApplyTransform()
end

function BADGE:ApplyTransform()
    local sc = self.scale or 1
    local bs = self.base_s or 24
    local s  = math.max(1, math.floor(bs * sc + 0.5))
    local ox = math.floor((bs - s) * 0.5)
    local slide = math.floor(bs * (self.off_y or 0) + 0.5)
    self:SetSize(s, s)
    self:SetPos(self.anchor_x + ox, self.anchor_y + ox + slide)
end

function BADGE:Think()
    if not self.spawn then return end
    local k, d = 520, 28
    local dt = FrameTime()

    local f_sc = (1 - self.scale) * k - self.vel * d
    self.vel   = self.vel + f_sc * dt
    self.scale = self.scale + self.vel * dt

    local f_oy = (0 - self.off_y) * k - self.off_vel * d
    self.off_vel = self.off_vel + f_oy * dt
    self.off_y   = self.off_y + self.off_vel * dt

    if math.abs(self.scale - 1) < 0.006 and math.abs(self.vel) < 0.02
        and math.abs(self.off_y) < 0.006 and math.abs(self.off_vel) < 0.02 then
        self.scale, self.vel = 1, 0
        self.off_y, self.off_vel = 0, 0
        self.spawn = false
    end
    self:ApplyTransform()
end

function BADGE:PerformLayout(w, h)
    if IsValid(self.avatar) then
        self.avatar:SetPos(0, 0)
        self.avatar:SetSize(math.max(1, w), math.max(1, h))
    end
end

function BADGE:Paint(w, h)
    if not self.avatar then
        local r = math.max(1, S(4) * (self.scale or 1))
        draw.RoundedBox(r, 0, 0, w, h, BADGE_BG)
        local txt = istable(self.entry) and ("+" .. self.entry.more) or "?"
        draw.SimpleText(txt, Font(12, true, true), w / 2, h / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

function BADGE:PaintOver(w, h)
    if not self.avatar then return end
    surface.SetDrawColor(BADGE_OUTLINE)
    surface.DrawOutlinedRect(0, 0, w, h, SB(1.5))
end

vgui.Register("HordeSummaryBadge", BADGE, "Panel")

local MAPCARD = {}

function MAPCARD:Init()
    self:SetText("")
    self.bar = vgui.Create("HordeSummaryNameBar", self)
    self.badges = {}
    self.rev = -1
    self.selected = false
    self.stripes = {}
end

function MAPCARD:Setup(map, scroll, page)
    self.map, self.scroll, self.page = map, scroll, page
    if map then
        self.bar:SetLabel(map, false)
        self:SetCursor("hand")
    else
        self.bar:SetLabel(T("EmptySlot"), true)
        self:SetCursor("arrow")
    end
end

function MAPCARD:InView()
    local sc = self.scroll
    if not IsValid(sc) then return true end
    local _, cy = self:LocalToScreen(0, 0)
    local _, sy = sc:LocalToScreen(0, 0)
    return cy < sy + sc:GetTall() and cy + self:GetTall() > sy
end

function MAPCARD:LayoutBadges()
    local n = #self.badges
    if n == 0 then return end
    local w, h = self:GetSize()
    local bs, gap = S(24), S(4)
    local inset = S(2) + SB(1.5)
    local per = math.max(1, math.min(BADGES_PER_ROW, math.floor((w - 2 * inset + gap) / (bs + gap))))
    local rows = math.ceil(n / per)
    local total_h = rows * bs + (rows - 1) * gap
    local y0 = h - inset - S(6) - total_h
    for i, bd in ipairs(self.badges) do
        local row, idx = math.floor((i - 1) / per), (i - 1) % per
        local in_row = math.min(per, n - row * per)
        local row_w = in_row * bs + (in_row - 1) * gap
        local ax = math.floor((w - row_w) / 2) + idx * (bs + gap)
        local ay = y0 + row * (bs + gap)
        if bd.SetAnchor then
            bd:SetAnchor(ax, ay, bs)
        else
            bd:SetSize(bs, bs)
            bd:SetPos(ax, ay)
        end
    end
end

function MAPCARD:SetVoters(list)
    list = list or {}
    local old = self.badges
    local used = {}
    local new_badges = {}

    local function key_of(entry)
        if isentity(entry) and IsValid(entry) then return entry end
        if entry == false then return false end
        if istable(entry) and entry.more then return "more:" .. tostring(entry.more) end
        return tostring(entry)
    end

    local old_by_key = {}
    for _, bd in ipairs(old) do
        if IsValid(bd) then
            local k = key_of(bd.entry)
            old_by_key[k] = old_by_key[k] or {}
            old_by_key[k][#old_by_key[k] + 1] = bd
        end
    end

    for _, entry in ipairs(list) do
        local k = key_of(entry)
        local pool = old_by_key[k]
        local bd
        if pool and #pool > 0 then
            bd = table.remove(pool, 1)
            used[bd] = true
        else
            bd = vgui.Create("HordeSummaryBadge", self)
            bd:Setup(entry)
        end
        new_badges[#new_badges + 1] = bd
    end

    for _, bd in ipairs(old) do
        if IsValid(bd) and not used[bd] then bd:Remove() end
    end

    self.badges = new_badges
    self:LayoutBadges()
end

function MAPCARD:PerformLayout(w, h)
    local inset = S(2) + SB(1.5)
    self.bar:SetPos(inset, inset)
    self.bar:SetSize(math.max(1, w - 2 * inset), S(24))
    self.stripes = BuildStripes(inset, inset, w - 2 * inset, h - 2 * inset)
    self:LayoutBadges()
end

function MAPCARD:Think()
    local bar = self.bar
    local target = self:IsHovered() and 1 or 0
    bar.alpha = Lerp(math.min(1, FrameTime() * 16), bar.alpha, target)
    if target == 0 and bar.alpha < 0.02 then bar.alpha = 0 end
    bar:SetVisible(bar.alpha > 0)

    if not self.map then return end

    if self.rev ~= vote_rev then
        self.rev = vote_rev
        self:SetVoters(BuildBadgeList(self.map, self.page and self.page.sel_map))
    end
    if self:InView() then
        local w, h = self:GetSize()
        local inset = S(2) + SB(1.5)
        local iw, ih = math.max(1, w - 2 * inset), math.max(1, h - 2 * inset)
        local mat = Icons.Request(self.map, iw, ih)
        if mat then self.mat = mat end
    end
end

function MAPCARD:OnCursorEntered()
    if self.map then SndHover() end
    self.bar:Restart()
end

function MAPCARD:OnMousePressed(code)
    if code ~= MOUSE_LEFT or not self.map then return end
    if self._vote_lock and self._vote_lock > RealTime() then return end
    self._vote_lock = RealTime() + 0.15
    SndClick()
    if self.page then self.page:PickMap(self.map) end
end

function MAPCARD:DoClick()
end

function MAPCARD:BorderColor()
    if not self.map then return self:IsHovered() and RED or CARD end
    if self.selected then return RED_H end
    return self:IsHovered() and RED_H or RED
end

function MAPCARD:Paint(w, h)
    local m, b, r = S(2), SB(1.5), S(6)
    draw.RoundedBox(r, m, m, w - 2 * m, h - 2 * m, self:BorderColor())

    local ix, iy = m + b, m + b
    local iw, ih = w - 2 * ix, h - 2 * iy
    if self.map and self.mat then
        DrawCover(self.mat, ix, iy, iw, ih)
    else
        surface.SetDrawColor(EMPTY_BG)
        surface.DrawRect(ix, iy, iw, ih)
        draw.NoTexture()
        for _, s in ipairs(self.stripes) do
            surface.SetDrawColor(s.col)
            surface.DrawPoly(s.poly)
        end
    end
end

function MAPCARD:PaintOver(w, h)
    local m, b, r = S(2), SB(1.5), S(6)
    local ri = math.max(0, r - b)
    local x0, y0, x1, y1 = m + b, m + b, w - m - b, h - m - b
    local col = self:BorderColor()
    DrawCornerMask(x0, y0, ri,  1,  1, col)
    DrawCornerMask(x1, y0, ri, -1,  1, col)
    DrawCornerMask(x0, y1, ri,  1, -1, col)
    DrawCornerMask(x1, y1, ri, -1, -1, col)
end

vgui.Register("HordeSummaryMapCard", MAPCARD, "DButton")

local VOTE = {}

function VOTE:Init()
    self.sel_map, self.sel_diff, self.sel_mod = nil, nil, nil
    self.voted = false
    self.cards, self.base_names, self.heads = {}, {}, {}

    self.diff_scroll = vgui.Create("HordeSummaryScroll", self)
    self.diff_scroll:Configure("left", true)
    self.maps_scroll = vgui.Create("HordeSummaryScroll", self)
    self.maps_scroll:Configure("right", false, MapGridLayout)
    self.mod_scroll = vgui.Create("HordeSummaryScroll", self)
    self.mod_scroll:Configure("right", true)

    self:BuildLists()
    self:SetMaps({})
end

function VOTE:FallbackDifficulty()
    local cur = HORDE.difficulty_text and HORDE.difficulty_text[HORDE.difficulty]
    local function is_base(name)
        for _, b in ipairs(self.base_names) do
            if b == name then return true end
        end
        return false
    end
    if is_base(cur) then return cur end

    local cur_def
    for _, def in pairs(HORDE._difficulties or {}) do
        if istable(def) and def.Name == cur then cur_def = def break end
    end

    if cur_def and HORDE.GetDifficultyOverride then
        local override = HORDE:GetDifficultyOverride(cur_def)
        if isstring(override) and is_base(string.upper(override)) then return string.upper(override) end
    end

    local cv = GetConVar("horde_difficulty_include_base")
    local saved = cv and string.upper(cv:GetString() or "") or ""
    if saved ~= "" and is_base(saved) then return saved end

    if cur_def and HORDE.GetDifficultyInclude then
        local inc = HORDE:GetDifficultyInclude(cur_def)
        if isstring(inc) and is_base(string.upper(inc)) then return string.upper(inc) end
    end
    local def_base = HORDE.DEFAULT_MODIFIER_BASE
    if isstring(def_base) and is_base(string.upper(def_base)) then return string.upper(def_base) end
    return self.base_names[1]
end

function VOTE:PickDifficulty(name)
    self.sel_diff = name
    self.voted = true
    local base = self.sel_diff or self:FallbackDifficulty()
    if not base then return end
    SendDiffVote(base, self.sel_mod)
end

function VOTE:PickModifier(name)
    self.sel_mod = name
    self.voted = true
    local base = self.sel_diff or self:FallbackDifficulty()
    if not base then return end
    SendDiffVote(base, self.sel_mod)
end

function VOTE:PickMap(map)
    if self.sel_map == map then
        SendMapVote(map)
        return
    end
    self.sel_map = map
    for _, c in ipairs(self.cards) do
        if IsValid(c) then c.selected = (c.map == map) end
    end
    SendMapVote(map)
end

function VOTE:BuildLists()
    self.diff_scroll:ClearItems()
    self.mod_scroll:ClearItems()
    local base, mods = CollectDifficulties()
    self.base_names = base

    local function add(scroll, label, accent, state_fn, on_click)
        local p = vgui.Create("HordeSummaryPill")
        p:Setup(label, accent, state_fn, on_click)
        scroll:AddItem(p)
    end

    add(self.mod_scroll, T("Default"), false,
        function() return self.voted and not self.sel_mod, false, nil end,
        function() self:PickModifier(nil) end)
    for _, name in ipairs(mods) do
        add(self.mod_scroll, DiffLabel(name), name == "WAVE_666",
            function() return self.sel_mod == name, false, votes_diff[name] end,
            function() self:PickModifier(name) end)
    end

    for _, name in ipairs(base) do
        add(self.diff_scroll, DiffLabel(name), false,
            function()
                return self.voted and self.sel_diff == name, false, votes_diff[name]
            end,
            function() self:PickDifficulty(name) end)
    end
end

function VOTE:SetMaps(maps)
    self.maps_scroll:ClearItems()
    self.cards = {}
    maps = istable(maps) and maps or {}
    local list = {}
    for _, m in ipairs(maps) do
        if isstring(m) and m ~= "" then list[#list + 1] = m end
    end

    local center = math.ceil(MAP_SLOTS / 2)
    local cur_lower = string.lower(game.GetMap() or "")
    local current, others = nil, {}
    for _, m in ipairs(list) do
        if string.lower(m) == cur_lower then
            current = current or m
        else
            others[#others + 1] = m
        end
    end
    local limit = current and (MAP_SLOTS - 1) or MAP_SLOTS

    if #others > limit then
        local seed = util.CRC(table.concat(list, ",") .. game.GetMap())
        local rnd = tonumber(seed) or 1
        for i = #others, 2, -1 do
            rnd = (rnd * 1103515245 + 12345) % 2147483648
            local j = rnd % i + 1
            others[i], others[j] = others[j], others[i]
        end
        while #others > limit do table.remove(others) end
    end

    local slots, k = {}, 1
    for i = 1, MAP_SLOTS do
        if current and i == center then
            slots[i] = current
        else
            slots[i] = others[k]
            k = k + 1
        end
    end

    for i = 1, MAP_SLOTS do
        local c = vgui.Create("HordeSummaryMapCard")
        c:Setup(slots[i], self.maps_scroll, self)
        c.selected = (slots[i] ~= nil and slots[i] == self.sel_map)
        self.maps_scroll:AddItem(c)
        self.cards[#self.cards + 1] = c
    end
    self._maps_list = slots
    vote_rev = vote_rev + 1
end

function VOTE:WarmIcons()
    if self._icons_warmed then return end
    self._icons_warmed = true
    local list = self._maps_list or {}
    local i = 0
    local function step()
        i = i + 1
        if i > MAP_SLOTS then return end
        if list[i] then
            local card = self.cards and self.cards[i]
            local w, h = 0, 0
            if IsValid(card) then w, h = card:GetSize() end
            if w > 0 and h > 0 then
                local inset = S(2) + SB(1.5)
                local iw, ih = math.max(1, w - 2 * inset), math.max(1, h - 2 * inset)
                Icons.Request(list[i], iw, ih)
            end
        end
        timer.Simple(0, step)
    end
    step()
end

function VOTE:PerformLayout(w, h)
    local gap = S(14)
    local head_h, head_gap = S(32), S(10)
    local top = head_h + head_gap
    local lh = math.max(1, h - top)
    self.heads = {}

    if DifficultyVotingDisabled() then
        self.diff_scroll:SetVisible(false)
        self.mod_scroll:SetVisible(false)
        self.maps_scroll:SetPos(0, top)
        self.maps_scroll:SetSize(w, lh)
        self.heads[1] = { x = 0, w = w, title = T("Maps") }
        return
    end

    self.diff_scroll:SetVisible(true)
    self.mod_scroll:SetVisible(true)
    local unit = (w - 11 * gap) / 12
    local c1 = math.floor(3 * unit + 2 * gap)
    local c2 = math.floor(6 * unit + 5 * gap)
    local x2 = c1 + gap
    local x3 = x2 + c2 + gap
    local c3 = w - x3

    self.diff_scroll:SetPos(0, top);  self.diff_scroll:SetSize(c1, lh)
    self.maps_scroll:SetPos(x2, top); self.maps_scroll:SetSize(c2, lh)
    self.mod_scroll:SetPos(x3, top);  self.mod_scroll:SetSize(c3, lh)
    self.heads = {
        { x = 0,  w = c1, title = T("Difficulty") },
        { x = x2, w = c2, title = T("Maps") },
        { x = x3, w = c3, title = T("Modifiers") },
    }
end

function VOTE:Paint()
    local hh = S(32)
    for _, hd in ipairs(self.heads) do
        draw.RoundedBox(math.floor(hh / 2), hd.x, 0, hd.w, hh, RED)
        draw.SimpleText(hd.title, Font(14.5, true), hd.x + hd.w / 2, hh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

vgui.Register("HordeSummaryVotePage", VOTE, "Panel")

local function SubclassOf(ply)
    if not IsValid(ply) or not HORDE.subclasses then return nil end
    local name = ply.Horde_GetCurrentSubclass and ply:Horde_GetCurrentSubclass() or nil
    return HORDE.subclasses[name or ""] or HORDE.subclasses[HORDE.Class_Survivor or "Survivor"] or HORDE.subclasses["Survivor"]
end

local icon_mats = {}
local function IconMat(path, displayW, displayH)
    if not path then return nil end
    local flags = MaterialTextureFlags(displayW, displayH)
    local key = path .. "\0" .. flags
    if icon_mats[key] == nil then
        local m = Material(path, flags)
        icon_mats[key] = (m and not m:IsError()) and m or false
    end
    return icon_mats[key] or nil
end

local AWARD = {}

function AWARD:Setup(ply, title, reason, mvp)
    self.ply, self.title, self.reason, self.mvp = ply, title or "", reason or "", mvp
    self.name = IsValid(ply) and ply:Nick() or "-"
    if IsValid(ply) then
        self.avatar = vgui.Create("AvatarImage", self)
        self.avatar:SetMouseInputEnabled(false)
        self.avatar:SetPlayer(ply, 64)
        local sc = SubclassOf(ply)
        self.icon_path = (sc and sc.Icon) or "icon16/user.png"
    end
end

function AWARD:PerformLayout(w, h)
    if IsValid(self.avatar) then
        local pad = S(10)
        local s = h - 2 * pad
        self.avatar:SetPos(pad, pad)
        self.avatar:SetSize(s, s)
    end
end

function AWARD:Paint(w, h)
    local r = S(8)
    local b = SB(1.5)
    draw.RoundedBox(r, 0, 0, w, h, RED)
    draw.RoundedBox(math.max(0, r - b), b, b, w - 2 * b, h - 2 * b, WIN)

    local pad = S(10)
    local tx = pad + (h - 2 * pad) + S(14)
    local icon_s = math.floor(h * 0.6)
    local icon_mat = self.icon_path and IconMat(self.icon_path, icon_s, icon_s) or nil
    local right = w - pad - (icon_mat and (icon_s + S(10)) or 0)
    local maxw = math.max(10, right - tx)

    local f_title = Font(self.mvp and 17 or 14.5, true)
    local f_name, f_reason = Font(18, true), Font(14, false)
    surface.SetFont(f_title); local _, h1 = surface.GetTextSize("A")
    surface.SetFont(f_name);  local _, h2 = surface.GetTextSize("A")
    surface.SetFont(f_reason); local _, h3 = surface.GetTextSize("A")
    local gap = S(2)
    local y = (h - (h1 + h2 + h3 + 2 * gap)) / 2

    draw.SimpleText(FitText(self.title, f_title, maxw), f_title, tx, y, RED_TXT)
    draw.SimpleText(FitText(self.name, f_name, maxw), f_name, tx, y + h1 + gap, WH)
    draw.SimpleText(FitText(self.reason, f_reason, maxw), f_reason, tx, y + h1 + h2 + 2 * gap, DIM)

    if icon_mat then
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(icon_mat)
        surface.DrawTexturedRect(w - pad - icon_s, (h - icon_s) / 2, icon_s, icon_s)
    end
end

vgui.Register("HordeSummaryAwardCard", AWARD, "Panel")

local STATS = {}

function STATS:Init()
    self.cards = {}
    self.result, self.rest, self.result_col = "", "", WH
end

function STATS:SetData(status, awards)
    for _, c in ipairs(self.cards) do
        if IsValid(c) then c:Remove() end
    end
    self.cards = {}

    local diff_label = HORDE:GetActiveModeLabel() or ""
    self.result = TR("Game_Result_" .. tostring(status), tostring(status))
    self.rest = "! " .. game.GetMap() .. (diff_label ~= "" and (" - " .. diff_label) or "")
    self.result_col = (status == "VICTORY" and GREEN) or (status == "DEFEAT" and RED_TXT) or WH

    for _, a in ipairs(awards) do
        local c = vgui.Create("HordeSummaryAwardCard", self)
        c:Setup(a.ply, a.title, a.reason, a.mvp)
        c.slot = a.slot
        self.cards[#self.cards + 1] = c
    end
    self:InvalidateLayout()
end

function STATS:PerformLayout(w, h)
    local top = S(56)
    local gap = S(10)
    local card_h = math.min(S(108), math.floor((h - top - 3 * gap) / 4))
    local half = math.floor((w - gap) / 2)
    local card_w = math.min(half, S(430))
    for _, c in ipairs(self.cards) do
        local s = c.slot
        if s.mvp then
            c:SetSize(card_w, card_h)
            c:SetPos(math.floor((w - card_w) / 2), top)
        else
            local col_x = s.col == 0 and 0 or (half + gap)
            c:SetSize(card_w, card_h)
            c:SetPos(col_x + math.floor((half - card_w) / 2), top + (s.row) * (card_h + gap))
        end
    end
end

function STATS:Paint(w, h)
    local font = Font(24, true)
    surface.SetFont(font)
    local w1 = surface.GetTextSize(self.result)
    local w2 = surface.GetTextSize(self.rest)
    local x = (w - (w1 + w2)) / 2
    draw.SimpleText(self.result, font, x, S(6), self.result_col)
    draw.SimpleText(self.rest, font, x + w1, S(6), WH)
end

vgui.Register("HordeSummaryStatsPage", STATS, "Panel")

local leaderboard_rows   = {}
local leaderboard_rev    = 0
local leaderboard_loaded = false
local leaderboard_time   = -1000

net.Receive("Horde_SyncTopTen", function()
    local data = util.JSONToTable(net.ReadString() or "") or {}
    local rows = {}
    for _, r in ipairs(data) do
        if istable(r) and r.steamid then
            rows[#rows + 1] = {
                steamid   = tostring(r.steamid),
                name      = isstring(r.name) and r.name ~= "" and r.name or nil,
                class     = r.class,
                level     = tonumber(r.level) or 0,
                kills     = tonumber(r.kills) or 0,
                mvps      = tonumber(r.mvps) or 0,
                last_seen = tonumber(r.last_seen),
                online    = r.online and true or false,
            }
        end
    end
    leaderboard_rows, leaderboard_loaded = rows, true
    leaderboard_time = CurTime()
    leaderboard_rev = leaderboard_rev + 1
    HORDE.LeaderboardData = rows
end)

local function RequestLeaderboard()
    if leaderboard_loaded and CurTime() - leaderboard_time < 20 then return end
    leaderboard_time = CurTime()
    net.Start("Horde_RequestLeaderboard")
    net.SendToServer()
end

local LB_SPANS = { 3, 2, 2, 2, 3 }
local LB_HEADS = { "LbPlayer", "LbKills", "LbMvps", "LbLevel", "LbLastSeen" }

local function LbColumns(total_w)
    local gap = S(12)
    local unit = (total_w - 11 * gap) / 12
    local cols, x = {}, 0
    for i, span in ipairs(LB_SPANS) do
        local w = span * unit + (span - 1) * gap
        cols[i] = { x = math.floor(x), w = math.floor(w) }
        x = x + w + gap
    end
    return cols
end

local LB_LINE   = Color(45, 46, 52)
local LB_HOVER  = Color(255, 255, 255, 6)
local LB_ME     = Color(220, 30, 56, 20)
local LB_AV_LN  = Color(220, 30, 56, 204)
local LB_DATE   = Color(255, 255, 255, 230)

local LBROW = {}

function LBROW:Setup(data, pos)
    self.data, self.pos = data, pos
    self.item_h = S(45)
    self.me = (IsValid(LocalPlayer()) and LocalPlayer():SteamID64() == data.steamid)

    self.avatar = vgui.Create("AvatarImage", self)
    self.avatar:SetMouseInputEnabled(false)
    local ply = player.GetBySteamID64(data.steamid)
    if IsValid(ply) then self.avatar:SetPlayer(ply, 32) else self.avatar:SetSteamID(data.steamid, 32) end

    if not data.name and data.steamid ~= "" then
        steamworks.RequestPlayerInfo(data.steamid, function(n)
            if n and n ~= "" then data.name = n end
        end)
    end
end

function LBROW:AvatarRect(w, h)
    local cols = LbColumns(w - 2 * S(8))
    local s = S(28)
    return S(8) + cols[1].x + S(26), math.floor((h - s) / 2), s
end

function LBROW:PerformLayout(w, h)
    local x, y, s = self:AvatarRect(w, h)
    self.avatar:SetPos(x, y)
    self.avatar:SetSize(s, s)
end

function LBROW:OnMousePressed(code)
    if code == MOUSE_LEFT and self.data.steamid ~= "" then
        local mx = self:CursorPos()
        local ax, _, as = self:AvatarRect(self:GetSize())
        if mx >= ax and mx <= ax + as then gui.OpenURL("https://steamcommunity.com/profiles/" .. self.data.steamid) end
    end
end

function LBROW:Paint(w, h)
    local d = self.data
    if self.me then
        surface.SetDrawColor(LB_ME)
        surface.DrawRect(0, 0, w, h)
    elseif self:IsHovered() then
        surface.SetDrawColor(LB_HOVER)
        surface.DrawRect(0, 0, w, h)
    end
    surface.SetDrawColor(LB_LINE)
    surface.DrawRect(0, h - SB(1), w, SB(1))

    local ox = S(8)
    local cols = LbColumns(w - 2 * ox)
    local cy = math.floor((h - SB(1)) / 2)

    local c1 = cols[1]
    draw.SimpleText(tostring(self.pos) .. ".", Font(13, true), ox + c1.x, cy,
        self.pos <= 3 and RED_TXT or DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    local name_x = ox + c1.x + S(26) + S(28) + S(10)
    local name_font = Font(13.5, false)
    local name = d.name or "..."
    draw.SimpleText(FitText(name, name_font, c1.x + c1.w - (name_x - ox)), name_font, name_x, cy,
        self.me and RED_TXT or WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    local mono = Font(13.5, false, true)
    draw.SimpleText(tostring(d.kills), mono, ox + cols[2].x + cols[2].w / 2, cy, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(tostring(d.mvps), mono, ox + cols[3].x + cols[3].w / 2, cy, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local c4 = cols[4]
    local icon_size = S(24)
    local gx = ox + c4.x + (c4.w - icon_size) / 2
    local gy = cy - icon_size / 2
    local subclass = HORDE.subclasses and (HORDE.subclasses[d.class or ""] or HORDE.subclasses["Survivor"])
    local mat = subclass and IconMat(subclass.Icon, icon_size, icon_size)
    local rank, rank_level
    if HORDE.LevelToRank then rank, rank_level = HORDE:LevelToRank(d.level) end
    local rcol = (rank and HORDE.Rank_Colors and HORDE.Rank_Colors[rank]) or WH

    if mat then
        surface.SetMaterial(mat)
        surface.SetDrawColor(rcol)
        surface.DrawTexturedRect(gx, gy, icon_size, icon_size)
    end

    if rank == HORDE.Rank_Master then
        draw.SimpleText(tostring(rank_level or 0), "Trebuchet18", gx, gy + S(1), rcol,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif (tonumber(rank_level) or 0) > 0 then
        local star_size = S(4)
        local star = IconMat("star.png", star_size, star_size)
        if star then
            surface.SetMaterial(star)
            surface.SetDrawColor(rcol)
            local star_x = gx - S(3)
            local star_y = gy + S(12)
            for i = 0, math.min(4, rank_level) - 1 do
                surface.DrawTexturedRect(star_x, star_y - i * S(3), star_size, star_size)
            end
        end
    end

    local c5 = cols[5]
    local txt = d.last_seen and os.date("%d.%m.%Y / %H:%M", d.last_seen) or "-"
    draw.SimpleText(txt, Font(12, false, true), ox + c5.x + c5.w / 2, cy,
        LB_DATE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function LBROW:PaintOver(w, h)
    local x, y, s = self:AvatarRect(w, h)
    surface.SetDrawColor(LB_AV_LN)
    surface.DrawOutlinedRect(x, y, s, s, SB(1))
end

function LBROW:OnCursorEntered() end

vgui.Register("HordeSummaryLbRow", LBROW, "Panel")

local LEADERBOARD = {}

function LEADERBOARD:Init()
    self.scroll = vgui.Create("HordeSummaryScroll", self)
    self.scroll:Configure("right", false)
    self.rev = -1
    RequestLeaderboard()
end

function LEADERBOARD:RefreshData()
    self.scroll:ClearItems()
    for i, row in ipairs(leaderboard_rows) do
        local r = vgui.Create("HordeSummaryLbRow")
        r:Setup(row, i)
        self.scroll:AddItem(r)
    end
    self.rev = leaderboard_rev
end

function LEADERBOARD:Think()
    if self.rev ~= leaderboard_rev then self:RefreshData() end
end

function LEADERBOARD:PerformLayout(w, h)
    local head_h, gap = S(32), S(8)
    local px = S(4)
    self.scroll:SetPos(px, head_h + gap)
    self.scroll:SetSize(w - 2 * px, math.max(1, h - head_h - gap))
end

function LEADERBOARD:Paint(w, h)
    local head_h = S(32)
    local px = S(4)
    local rows_w = (w - 2 * px) - (self.scroll.has_bar and (S(5) + S(6)) or 0)
    local ox = px + S(8)
    local cols = LbColumns(rows_w - 2 * S(8))
    local f = Font(13.5, true)
    for i, col in ipairs(cols) do
        draw.RoundedBox(math.floor(head_h / 2), ox + col.x, 0, col.w, head_h, RED)
        draw.SimpleText(T(LB_HEADS[i]), f, ox + col.x + col.w / 2, head_h / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    if #leaderboard_rows == 0 then
        draw.SimpleText(leaderboard_loaded and T("LbEmpty") or T("LbLoading"), Font(14, false),
            w / 2, head_h + S(60), DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

vgui.Register("HordeSummaryLeaderboardPage", LEADERBOARD, "Panel")

local PANEL = {}

local TABS = {
    { id = "stats", key = "Statistics" },
    { id = "vote",  key = "MapVoting" },
    { id = "leaderboard", key = "Leaderboard" },
}

local function CloseForeignMenus()
    if Pointshop2 and isfunction(Pointshop2.CloseMenu) then pcall(Pointshop2.CloseMenu, Pointshop2) end
    for _, p in ipairs(vgui.GetWorldPanel():GetChildren()) do
        if IsValid(p) and p:IsVisible() then
            local n = string.lower(tostring(p.ClassName or ""))
            if string.find(n, "pointshop", 1, true) or string.find(n, "ps2", 1, true) then
                p:SetVisible(false)
            end
        end
    end
end

function PANEL:Init()
    CloseForeignMenus()
    if IsValid(HORDE.SummaryPanel) then HORDE.SummaryPanel:Remove() end
    HORDE.SummaryPanel = self

    K = WINDOW_SCALE * math.max(1, ScrH() / 1080)
    K = math.max(0.6, math.min(K, (ScrW() - 20) / 1020, (ScrH() - 20) / 580))
    self:SetSize(S(1020), S(580))
    self:Center()
    self:MakePopup()
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(true)

    self.pages = {
        stats = vgui.Create("HordeSummaryStatsPage", self),
    }
    self._pending_maps = nil
    self._pending_stats = nil

    self.tab_btns = {}
    for _, tab in ipairs(TABS) do
        local btn = vgui.Create("DButton", self)
        btn:SetText("")
        btn.tab_id, btn.tab_key = tab.id, tab.key
        btn.Paint = function(b, w, h)
            local active = (self.active_tab == b.tab_id)
            local col = active and RED_TXT or (b:IsHovered() and TAB_HOVER or WH)
            draw.SimpleText(T(b.tab_key), Font(17, false), w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        btn.OnCursorEntered = function() SndHover() end
        btn.DoClick = function(b)
            SndClick()
            self:ShowTab(b.tab_id)
        end
        self.tab_btns[#self.tab_btns + 1] = btn
    end

    self:ShowTab("stats")
end

function PANEL:EnsurePage(id)
    if IsValid(self.pages[id]) then return self.pages[id] end
    if id == "vote" then
        self.pages.vote = vgui.Create("HordeSummaryVotePage", self)
        if self._pending_maps then
            self.pages.vote:SetMaps(self._pending_maps)
            self._pending_maps = nil
        end
    elseif id == "leaderboard" then
        self.pages.leaderboard = vgui.Create("HordeSummaryLeaderboardPage", self)
    end
    local w, h = self:GetSize()
    local pad = S(14)
    local head_h = S(36)
    local by = pad + head_h + S(8)
    local page = self.pages[id]
    if IsValid(page) then
        page:SetPos(pad, by)
        page:SetSize(w - 2 * pad, h - by - pad)
    end
    return page
end

function PANEL:ShowTab(id)
    self.active_tab = id
    self:EnsurePage(id)
    for pid, page in pairs(self.pages) do
        if IsValid(page) then page:SetVisible(pid == id) end
    end
    if id == "vote" and IsValid(self.pages.vote) and self.pages.vote.WarmIcons then
        self.pages.vote:WarmIcons()
    end
end

function PANEL:PerformLayout(w, h)
    local pad = S(14)
    local head_h = S(36)

    local gap = S(24)
    local widths, total = {}, 0
    for i, btn in ipairs(self.tab_btns) do
        surface.SetFont(Font(17, false))
        local tw = surface.GetTextSize(T(btn.tab_key)) + S(8)
        widths[i] = tw
        total = total + tw
    end
    total = total + gap * (#self.tab_btns - 1)
    local x = pad + S(8)
    for i, btn in ipairs(self.tab_btns) do
        btn:SetPos(x, pad)
        btn:SetSize(widths[i], head_h)
        x = x + widths[i] + gap
    end

    local by = pad + head_h + S(8)
    for _, page in pairs(self.pages) do
        page:SetPos(pad, by)
        page:SetSize(w - 2 * pad, h - by - pad)
    end
end

function PANEL:SetData(status, mvp_player, mvp_damage, mvp_kills, damage_player, most_damage, kills_player, most_kills, most_heal_player, most_heal, headshot_player, most_headshots, elite_kill_player, most_elite_kills, damage_taken_player, most_damage_taken, total_damage, maps)
    local percentage = 0
    if total_damage and total_damage > 0 then
        percentage = HORDE:Round2(mvp_damage / total_damage, 2) * 100
    end

    local kills_t, damage_t = TR("Game_Kills", "Kills"), TR("Game_Damage", "Damage")
    local awards = {
        { ply = mvp_player, title = "MVP", mvp = true, slot = { mvp = true },
          reason = mvp_kills .. " " .. kills_t .. ", " .. mvp_damage .. " " .. damage_t .. " (" .. percentage .. "%)" },
        { ply = damage_player, title = TR("Game_Most_Damage_Dealt", "Most Damage Dealt"),
          reason = most_damage .. " " .. damage_t, slot = { row = 0, col = 0 } },
        { ply = kills_player, title = TR("Game_Most_Kills", "Most Kills"),
          reason = most_kills .. " " .. kills_t, slot = { row = 0, col = 1 } },
        { ply = damage_taken_player, title = TR("Game_Most_Damage_Taken", "Most Damage Taken"),
          reason = most_damage_taken .. " " .. TR("Game_Damage_Taken", "Damage Taken"), slot = { row = 1, col = 0 } },
        { ply = elite_kill_player, title = TR("Game_Elite_Killer", "Elite Killer"),
          reason = most_elite_kills .. " " .. TR("Game_Elite_Kills", "Elite Kills"), slot = { row = 1, col = 1 } },
        { ply = most_heal_player, title = TR("Game_Most_Heal", "Team Healer"),
          reason = most_heal .. " " .. TR("Game_Healed", "Healed"), slot = { row = 2, col = 0 } },
        { ply = headshot_player, title = TR("Game_SharpShooter", "SharpShooter"),
          reason = most_headshots .. " " .. TR("Game_Headshots", "Headshots"), slot = { row = 2, col = 1 } },
    }
    for _, a in ipairs(awards) do
        if not a.slot.mvp then a.slot.row = a.slot.row + 1 end
    end

    self.pages.stats:SetData(status, awards)
    if IsValid(self.pages.vote) then
        self.pages.vote:SetMaps(maps)
    else
        self._pending_maps = maps
    end
end

function PANEL:Paint(w, h)
    local r = S(8)
    draw.RoundedBox(r, 0, 0, w, h, RED)
    draw.RoundedBox(math.max(0, r - 2), 2, 2, w - 4, h - 4, WIN)

    draw.SimpleText(tostring(remaining_time), Font(18, true, true), w - S(14) - S(4), S(14) + S(18),
        RED_TXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

vgui.Register("HordeSummaryPanel", PANEL, "EditablePanel")
