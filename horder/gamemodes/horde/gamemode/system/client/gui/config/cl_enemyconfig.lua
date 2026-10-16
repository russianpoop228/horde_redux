if not CLIENT then return end

surface.CreateFont("HE_Title", {font = "Trebuchet MS",        size = 30, weight = 700})
surface.CreateFont("HE_Label", {font = "CloseCaption_Normal", size = 20, weight = 500})
surface.CreateFont("HE_Body",  {font = "CloseCaption_Normal", size = 18, weight = 500})
surface.CreateFont("HE_Small", {font = "CloseCaption_Normal", size = 15, weight = 500})
surface.CreateFont("HE_Big",   {font = "Trebuchet MS",        size = 34, weight = 700})

local RED      = Color(220, 30,  56)
local RED_H    = Color(240, 50,  76)
local RED_TXT  = Color(232, 39,  73)
local RED_DARK = Color(150, 20,  40)
local WIN      = Color(31,  31,  31)
local CARD     = Color(60,  64,  70)
local CARD_H   = Color(72,  77,  84)
local BTN      = Color(66,  70,  78)
local BTN_H    = Color(80,  85,  94)
local TILE     = Color(38,  39,  43)
local TRACK    = Color(24,  25,  28)
local WH       = Color(255, 255, 255)
local DIM      = Color(150, 152, 158)
local GOLD     = Color(255, 190, 40)

local M        = 8
local HEADER_H = 64
local BAR_H    = 40
local BAR_GAP  = 22
local GAP      = 9
local WAVE666  = HORDE.WAVE666_ENEMY_WAVE or 666

local _mats = {}
local function GM(path)
    if _mats[path] == nil then
        local m = Material(path, "mips smooth")
        _mats[path] = (m and not m:IsError()) and m or false
    end
    return _mats[path] or nil
end

local _iconCache = {}
local function GetEnemyIcon(class)
    if _iconCache[class] ~= nil then return _iconCache[class] or nil end
    local m = GM("entities/" .. class .. ".png") or GM("vgui/entities/" .. class)
    _iconCache[class] = m or false
    return m
end

local function DrawIcon(mat, x, y, w, h, col)
    if not mat then return end
    local mw, mh = mat:Width(), mat:Height()
    if mw and mh and mw > 0 and mh > 0 then
        local s  = math.min(w / mw, h / mh)
        local dw, dh = mw * s, mh * s
        x = x + (w - dw) / 2
        y = y + (h - dh) / 2
        w, h = dw, dh
    end
    surface.SetMaterial(mat)
    surface.SetDrawColor(col or WH)
    surface.DrawTexturedRect(math.floor(x), math.floor(y), math.ceil(w), math.ceil(h))
end

local function DrawTri(cx, cy, s, down, col)
    draw.NoTexture()
    surface.SetDrawColor(col)
    if down then
        surface.DrawPoly({
            {x = cx - s, y = cy - s * 0.5},
            {x = cx + s, y = cy - s * 0.5},
            {x = cx,     y = cy + s * 0.6},
        })
    else
        surface.DrawPoly({
            {x = cx - s * 0.5, y = cy - s},
            {x = cx + s * 0.6, y = cy},
            {x = cx - s * 0.5, y = cy + s},
        })
    end
end

local function StyleScroll(scroll)
    local vb = scroll:GetVBar()
    vb:SetWide(10)
    vb:SetHideButtons(true)
    vb.Paint = function(_, w, h) draw.RoundedBox(5, 0, 0, w, h, TRACK) end
    vb.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and RED_H or RED)
    end
    vb.btnUp.Paint   = function() end
    vb.btnDown.Paint = function() end
end

local function StyledEntry(ent, placeholder)
    ent:SetFont("HE_Body")
    function ent:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, BTN)
        self:DrawTextEntryText(WH, RED, WH)
        if placeholder and self:GetValue() == "" then
            draw.SimpleText(placeholder, "HE_Body", 5, h / 2, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end

local function StyledCombo(combo)
    combo:SetFont("HE_Body")
    combo:SetTextColor(WH)
    combo:SetTextInset(10, 0)
    if IsValid(combo.DropButton) then combo.DropButton.Paint = function() end end
    combo.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and BTN_H or BTN)
        DrawTri(w - 16, h / 2, 5, true, DIM)
    end
end

local function FlatButton(parent, label, x, y, w, h, col, colHover, cb)
    local b = vgui.Create("DButton", parent)
    b:SetPos(x, y)
    b:SetSize(w, h)
    b:SetText("")
    b.Paint = function(s, bw, bh)
        draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and colHover or col)
        draw.SimpleText(label, "HE_Body", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.DoClick = cb
    return b
end

local function Modal(parent, w, h, title)
    local ovl = vgui.Create("DButton", parent)
    ovl:SetText("")
    ovl:SetSize(parent:GetWide(), parent:GetTall())
    ovl:SetPos(0, 0)
    ovl:MoveToFront()
    ovl.Paint = function(_, pw, ph) draw.RoundedBox(8, 0, 0, pw, ph, Color(0, 0, 0, 170)) end
    ovl.DoClick = function() end

    local box = vgui.Create("DPanel", ovl)
    box:SetSize(w, h)
    box:Center()
    box:SetMouseInputEnabled(true)
    box.Paint = function(_, bw, bh)
        draw.RoundedBox(8, 0, 0, bw, bh, RED)
        draw.RoundedBox(6, 2, 2, bw - 4, bh - 4, WIN)
        draw.RoundedBoxEx(8, 0, 0, bw, 40, RED, true, true, false, false)
        draw.SimpleText(title, "Trebuchet24", 16, 20, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local xb = vgui.Create("DButton", box)
    xb:SetText("")
    xb:SetSize(28, 28)
    xb:SetPos(w - 36, 6)
    xb.Paint = function(s, bw, bh)
        draw.SimpleText("r", "Marlett", bw / 2, bh / 2, s:IsHovered() and DIM or WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    xb.DoClick = function() ovl:Remove() end

    return ovl, box
end

local DIFF_BASIC_FIELDS = {
    { key = "DamageMult",               label = "Damage Mult:",           def = 1.0 },
    { key = "HealthMult",               label = "Health Mult:",           def = 1.0 },
    { key = "RewardMult",               label = "Reward Mult:",           def = 1.0 },
    { key = "StartMoneyMult",           label = "Start Money Mult:",      def = 1.0 },
    { key = "EnemyCountMult",           label = "Enemy Count Mult:",      def = 1.0 },
    { key = "SpawnRadiusMult",          label = "Spawn Radius Mult:",     def = 1.0 },
    { key = "MaxEnemiesScaleFactor",    label = "Max Enemies Scale:",     def = 1.0 },
    { key = "AdditionalPack",           label = "Additional Pack:",       def = 0 },
    { key = "AdditionalAmmoboxes",      label = "Additional Ammoboxes:",  def = 0 },
    { key = "AdditionalEnemiesPerSpawn", label = "Extra Enemies Per Spawn:", def = 0 },
    { key = "EnemiesPerSpawnWaveStep",   label = "Extra Spawn Ramp Step (waves):", def = 0,
      tip = "Каждые N волн добавляется Extra Spawn Ramp Amount врагов из точки спавна.\n0 = разгон выключен.\nПример: у Hundred Step 10 / Amount 1 / Cap 4 — +1 каждые 10 волн, максимум +4." },
    { key = "EnemiesPerSpawnWaveAmount", label = "Extra Spawn Ramp Amount:",      def = 1,
      tip = "Сколько врагов добавляется за каждый шаг разгона (см. Extra Spawn Ramp Step)." },
    { key = "EnemiesPerSpawnWaveCap",    label = "Extra Spawn Ramp Cap:",         def = 4,
      tip = "Потолок добавки от разгона — больше этого числа врагов из точки не выйдет." },
    { key = "SpawnSpeedMult",           label = "Spawn Speed Mult:",      def = 1.0 },
    { key = "SpawnInterval",            label = "Spawn Interval (s):",    def = 0, convar_fallback = true,
      tip = "Интервал спавна волны в секундах.\n0 = использовать конвар horde_director_interval (по умолчанию 9 с).\nНапример, 1 — спавн раз в секунду.\nSpawn Speed Mult ускоряет спавн поверх этого значения." },
    { key = "SpawnIntervalWaveStep",    label = "Spawn Interval Ramp Step (waves):", def = 0,
      tip = "Каждые N волн интервал спавна уменьшается на Spawn Interval Ramp Amount.\n0 = разгон выключен.\nПример: у Hundred Step 5 / Amount 0.05 / Cap 0.25 — −0.05 с каждые 5 волн, минимум 0.25 с." },
    { key = "SpawnIntervalWaveAmount",  label = "Spawn Interval Ramp Amount (s):", def = 0.05,
      tip = "На сколько секунд уменьшается интервал за каждый шаг разгона (см. Spawn Interval Ramp Step)." },
    { key = "SpawnIntervalWaveCap",     label = "Spawn Interval Ramp Cap (min s):", def = 0.1,
      tip = "Минимальный интервал спавна: ниже этого значения разгон не опускает интервал." },
    { key = "MaxEnemiesAliveBase",      label = "Max Enemies Alive Base:", def = 20, convar_fallback = true,
      tip = "База лимита одновременно живых врагов.\nИтог: min(Cap, Base * Max Enemies Scale + Per Player * игроков).\nЗадаётся в файле сложности; если не задано — берётся конвар horde_max_enemies_alive_base." },
    { key = "MaxEnemiesAlivePerPlayer", label = "Max Enemies Alive Per Player:", def = 5, convar_fallback = true,
      tip = "Сколько слотов добавляет каждый игрок на сервере.\nЗадаётся в файле сложности; если не задано — конвар horde_max_enemies_alive_scale_factor." },
    { key = "MaxEnemiesAliveCap",       label = "Max Enemies Alive Cap:", def = 50, convar_fallback = true,
      tip = "Жёсткий потолок лимита живых врагов (не может быть превышен).\nЗадаётся в файле сложности; если не задано — конвар horde_max_enemies_alive_max." },
    { key = "StatusDurationBonus",      label = "Status Duration Bonus:", def = 0 },
    { key = "BreakHealthLeft",          label = "Break Health Left:",     def = 0.20 },
    { key = "ShockDamageIncrease",      label = "Shock Damage Increase:", def = 0.15 },
    { key = "FrostbiteSlow",            label = "Frostbite Slow:",        def = 0.40 },
    { key = "PoisonHeadcrabDamage",     label = "Poison HC Damage:",      def = 50 },
    { key = "EliteHealthScaleAdd",         label = "Elite HP Scale Add:",      def = 0.025 },
    { key = "EliteHealthScaleMultiplier",  label = "Elite HP Scale Mult:",     def = 1.0 },
    { key = "MutationProbability",         label = "Mutation Prob:",           def = 0 },
    { key = "EliteMutationProbability",    label = "Elite Mutation Prob:",     def = 0 },
}

local function FindDifficultyByName(name)
    if not name then return nil, nil end
    for i, d in pairs(HORDE._difficulties or {}) do
        if istable(d) and d.Name == name then
            return d, i
        end
    end
    return nil, nil
end

local function ApplyDifficultyBasicsLocal(name, values)
    local d, idx = FindDifficultyByName(name)
    if not d or not idx then return false end

    for _, f in ipairs(DIFF_BASIC_FIELDS) do
        local v = values[f.key]
        if v ~= nil then
            d[f.key] = v
        end
    end

    if HORDE.difficulty_health_multiplier then
        HORDE.difficulty_health_multiplier[idx] = d.HealthMult
    end
    if HORDE.difficulty_reward_base_multiplier then
        HORDE.difficulty_reward_base_multiplier[idx] = d.RewardMult
    end
    if HORDE.difficulty_status_duration_bonus then
        HORDE.difficulty_status_duration_bonus[idx] = d.StatusDurationBonus
    end
    if HORDE.difficulty_break_health_left then
        HORDE.difficulty_break_health_left[idx] = d.BreakHealthLeft
    end
    if HORDE.difficulty_shock_damage_increase then
        HORDE.difficulty_shock_damage_increase[idx] = d.ShockDamageIncrease
    end
    if HORDE.difficulty_frostbite_slow then
        HORDE.difficulty_frostbite_slow[idx] = d.FrostbiteSlow
    end
    if HORDE.difficulty_elite_health_scale_add then
        HORDE.difficulty_elite_health_scale_add[idx] = d.EliteHealthScaleAdd
    end
    if HORDE.difficulty_elite_health_scale_multiplier then
        HORDE.difficulty_elite_health_scale_multiplier[idx] = d.EliteHealthScaleMultiplier
    end
    if HORDE.difficulty_additional_pack then
        HORDE.difficulty_additional_pack[idx] = d.AdditionalPack
    end
    if HORDE.difficulty_additional_ammoboxes then
        HORDE.difficulty_additional_ammoboxes[idx] = d.AdditionalAmmoboxes
    end
    if HORDE.difficulty_additional_enemies_per_spawn then
        HORDE.difficulty_additional_enemies_per_spawn[idx] = d.AdditionalEnemiesPerSpawn or 0
    end
    if HORDE.difficulty_spawn_speed_mult then
        HORDE.difficulty_spawn_speed_mult[idx] = d.SpawnSpeedMult or 1
    end
    if HORDE.difficulty_spawn_interval then
        HORDE.difficulty_spawn_interval[idx] = d.SpawnInterval
    end
    if HORDE.difficulty_mutation_probability then
        HORDE.difficulty_mutation_probability[idx] = d.MutationProbability
    end
    if HORDE.difficulty_elite_mutation_probability then
        HORDE.difficulty_elite_mutation_probability[idx] = d.EliteMutationProbability
    end

    HORDE._diff_damage_mult = HORDE._diff_damage_mult or {}
    HORDE._diff_damage_mult[idx] = d.DamageMult or 1
    HORDE._diff_enemy_count_mult = HORDE._diff_enemy_count_mult or {}
    HORDE._diff_enemy_count_mult[idx] = d.EnemyCountMult or 1
    HORDE._diff_start_money_mult = HORDE._diff_start_money_mult or {}
    HORDE._diff_start_money_mult[idx] = d.StartMoneyMult or 1
    HORDE._diff_spawn_radius_mult = HORDE._diff_spawn_radius_mult or {}
    HORDE._diff_spawn_radius_mult[idx] = d.SpawnRadiusMult or 1
    HORDE._diff_max_enemies_scale = HORDE._diff_max_enemies_scale or {}
    HORDE._diff_max_enemies_scale[idx] = d.MaxEnemiesScaleFactor or 1
    HORDE._diff_poison_headcrab_dmg = HORDE._diff_poison_headcrab_dmg or {}
    HORDE._diff_poison_headcrab_dmg[idx] = d.PoisonHeadcrabDamage or 50

    return true, idx
end

local function DiffTitle(name)
    return string.upper(string.Replace(tostring(name or "?"), "_", " "))
end

local function SpaceAround(total, n, itemW)
    return (total - n * itemW) / (n + 1)
end

local function IsTrue(v)
    return v ~= nil and v ~= false and v ~= 0
end

local MAX_SLOT = 10000
local function ParseWaves(str)
    local out, seen = {}, {}
    local function add(n)
        n = math.floor(n)
        if (n >= 1 and n <= MAX_SLOT) or n == WAVE666 then
            if not seen[n] then seen[n] = true; out[#out + 1] = n end
        end
    end
    for tok in string.gmatch(str or "", "[^;,%s]+") do
        local a, b = string.match(tok, "^(%d+)%-(%d+)$")
        if a then
            a, b = tonumber(a), tonumber(b)
            if a > b then a, b = b, a end
            for n = a, math.min(b, MAX_SLOT) do add(n) end
        elseif tonumber(tok) then
            add(tonumber(tok))
        end
    end
    table.sort(out)
    return out
end

local function EnemyKey(en) return en.name .. tostring(en.wave) end

HORDE.enemies_all = HORDE.enemies_all or {}
local STATE = { names = {}, active = nil, wave666 = {}, loaded = {}, difficulty_basics = {}, difficulty_defaults = {} }

local function Panel()
    local p = HORDE.EnemyConfigGUI
    return IsValid(p) and p or nil
end

net.Receive("Horde_SyncEnemyConfigMeta", function()
    local t = net.ReadTable()
    STATE.names   = t.names or {}
    STATE.active  = t.active
    STATE.wave666 = t.wave666 or {}
    STATE.loaded  = {}
    if istable(t.difficulty_basics) then
        STATE.difficulty_basics = t.difficulty_basics
    end
    if istable(t.difficulty_defaults) then
        STATE.difficulty_defaults = t.difficulty_defaults
    end
    local p = Panel()
    if p then p:OnConfigMeta() end
end)

net.Receive("Horde_SyncDifficultyBasics", function()
    local t = net.ReadTable() or {}
    if t.overrides ~= nil or t.defaults ~= nil then
        STATE.difficulty_basics   = t.overrides or {}
        STATE.difficulty_defaults = t.defaults or STATE.difficulty_defaults or {}
    else
        STATE.difficulty_basics = t
    end
    local p = Panel()
    if p and p._LoadDifficultyBasics then
        p:_LoadDifficultyBasics()
    end
end)

net.Receive("Horde_SyncEnemyConfig", function()
    local D   = net.ReadString()
    local len = net.ReadUInt(32)
    local str = util.Decompress(net.ReadData(len) or "")
    HORDE.enemies_all[D] = (str and util.JSONToTable(str)) or {}
    STATE.loaded[D] = true
    local p = Panel()
    if p then p:OnConfigData(D) end
end)

local _tipEnemy = nil

hook.Add("PostRenderVGUI", "HordeEnemyCfgV2_Tip", function()
    if not _tipEnemy then return end
    if not (IsValid(HORDE.EnemyConfigGUI) and HORDE.EnemyConfigGUI:IsVisible()) then return end

    local en = _tipEnemy
    local tags = {}
    if IsTrue(en.is_elite) then tags[#tags + 1] = "Elite" end
    if en.boss_properties and en.boss_properties.is_boss then tags[#tags + 1] = "Boss" end
    if en.mutation and en.mutation ~= "" then tags[#tags + 1] = "Mutation: " .. en.mutation end

    local lines = {
        {en.name or "?", "HE_Label", RED_TXT},
        {"Class: " .. tostring(en.class), "HE_Small", WH},
        {"Wave: " .. tostring(en.wave) .. "   Priority: " .. tostring(en.weight), "HE_Small", WH},
        {"HP x" .. tostring(en.health_scale or 1) .. "   DMG x" .. tostring(en.damage_scale or 1) ..
         "   Reward x" .. tostring(en.reward_scale or 1), "HE_Small", WH},
    }
    if #tags > 0 then lines[#lines + 1] = {table.concat(tags, "   "), "HE_Small", GOLD} end

    local maxW, totalH = 0, 0
    for _, l in ipairs(lines) do
        surface.SetFont(l[2])
        local tw, th = surface.GetTextSize(l[1])
        l.h = th
        if tw > maxW then maxW = tw end
        totalH = totalH + th + 2
    end

    local mx, my = gui.MouseX(), gui.MouseY()
    local pw, ph = maxW + 28, totalH + 18
    local tx = math.min(mx + 16, ScrW() - pw - 4)
    local ty = math.min(my + 16, ScrH() - ph - 4)

    draw.RoundedBox(6, tx, ty, pw, ph, Color(24, 25, 28, 255))
    draw.RoundedBoxEx(6, tx, ty, pw, 3, RED, true, true, false, false)
    local cy = ty + 10
    for _, l in ipairs(lines) do
        draw.SimpleText(l[1], l[2], tx + 14, cy, l[3])
        cy = cy + l.h + 2
    end
end)

local function NewBlock(parent, title, w)
    local b = vgui.Create("DPanel", parent)
    b:SetWide(w)
    b.title    = title
    b.labels   = {}
    b.cy       = title and (BAR_H + BAR_GAP) or 0
    b.gapAfter = 26
    b.Paint = function(s, bw, bh)
        if s.title then
            draw.RoundedBox(4, 0, 0, bw, BAR_H, RED)
            draw.SimpleText(s.title, "Trebuchet24", bw / 2, BAR_H / 2, WH,
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        for _, l in ipairs(s.labels) do
            draw.SimpleText(l.text, l.font, l.x, l.y, l.col or WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    return b
end

local PANEL = {}

function PANEL:Init()
    local sw, sh = ScrW(), ScrH()
    local w, h
    if sw < 1400 then
        w, h = sw, sh
    else
        w = math.max(math.floor(sw * 0.64), math.min(900, sw))
        h = math.floor(math.min(sh * 0.8, w / 1.5))
    end
    self:SetSize(w, h)
    self:SetPos((sw - w) / 2, (sh - h) / 2)
    self:MakePopup()

    self.LX = M
    self.LW = math.floor(w * 0.52) - M - 12
    self.RX = self.LX + self.LW + 36
    self.RW = w - M - self.RX

    self.selKey     = nil
    self.collapsed  = {}
    self.search     = ""
    self.debounceT  = 0
    self.tipEnemy   = nil
    self.total      = 0
    self.blocks     = {}
    self.nextCheck  = 0
    self.diff       = nil
    self.extraSlots = {}
    self.requested  = false

    self.useColor = false
    self.isElite  = false
    self.isBoss   = false
    self.bossEnd  = false
    self.bossUnl  = false

    self:_BuildHeader()
    self:_BuildLeft()
    self:_BuildRight()
    self:_Reset(1)
    self:_LoadDifficultyBasics()
    self:Refresh()
end

function PANEL:_Store()
    if not self.diff then return nil end
    return HORDE.enemies_all[self.diff]
end

function PANEL:_Send()
    local store = self:_Store()
    if not store or not self.diff then return end
    local str = util.Compress(util.TableToJSON(store))
    if string.len(str) > 65000 then
        notification.AddLegacy("Enemy config is too large to save (" .. string.len(str) .. " bytes)!", NOTIFY_ERROR, 5)
        return
    end
    net.Start("Horde_SetEnemiesData")
        net.WriteString(self.diff)
        net.WriteUInt(string.len(str), 32)
        net.WriteData(str, string.len(str))
    net.SendToServer()
    HORDE:PlayNotification("Your changes have been saved.")
end

function PANEL:OnConfigMeta()
    if not self.diff or not table.HasValue(STATE.names, self.diff) then
        self.diff = STATE.active
        if not self.diff or not table.HasValue(STATE.names, self.diff) then self.diff = STATE.names[1] end
    end
    self.selKey = nil
    self:_LoadDifficultyBasics()
    self:Refresh()
end

function PANEL:OnConfigData(D)
    if D == self.diff then self:Refresh() end
end

function PANEL:_SelectDifficulty(D)
    if D == self.diff then return end
    self.diff = D
    self.selKey = nil
    self.collapsed = {}
    self.leftScroll:GetVBar():SetScroll(0)
    self:_Reset(1)
    self:_LoadDifficultyBasics()
    self:Refresh()
end

function PANEL:_BuildHeader()
    local LX, LW, RX, RW = self.LX, self.LW, self.RX, self.RW

    local dBtn = vgui.Create("DButton", self)
    dBtn:SetPos(LX + 4, 6)
    dBtn:SetSize(math.floor(LW * 0.52) - 10, HEADER_H - 12)
    dBtn:SetText("")
    dBtn:SetTooltip("Select difficulty")
    dBtn.Paint = function(s, w, h)
        local hov = s:IsHovered()
        draw.RoundedBox(8, 0, (h - 44) / 2, 44, 44, hov and RED_H or RED)
        draw.SimpleText(string.upper(string.sub(self.diff or "?", 1, 1)), "HE_Big", 22, h / 2, WH,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        local title = self.diff and DiffTitle(self.diff) or "Loading..."
        draw.SimpleText(title, "HE_Title", 58, h / 2, hov and RED_TXT or WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        surface.SetFont("HE_Title")
        local tw = surface.GetTextSize(title)
        draw.SimpleText(tostring(self.total), "HE_Body", 58 + tw + 10, h / 2 + 3, DIM,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    dBtn.DoClick = function() self:OpenDifficultyPicker() end

    local sx = LX + math.floor(LW * 0.53)
    local srch = vgui.Create("DTextEntry", self)
    srch:SetPos(sx, (HEADER_H - 34) / 2)
    srch:SetSize(LX + LW - sx, 34)
    StyledEntry(srch, "Search...")
    srch.OnChange = function(s)
        local q = string.lower(s:GetValue() or "")
        if q ~= self.search then
            self.search    = q
            self.debounceT = CurTime() + 0.2
        end
    end
    self.searchEntry = srch

    local SM    = 34
    local GAPH  = 8
    local by    = (HEADER_H - 36) / 2
    local avail = RW - 4 - 3 * GAPH - SM
    local bw    = math.min(170, math.floor(avail / 3))
    local total = 3 * bw + SM + 3 * GAPH
    local x     = RX + RW - 4 - total

    FlatButton(self, "Delete All",  x, by, bw, 36, BTN, RED_DARK, function() self:_DoDeleteAll() end)
    x = x + bw + GAPH
    FlatButton(self, "Add Default", x, by, bw, 36, BTN, BTN_H,    function() self:_DoAddDefault() end)
    x = x + bw + GAPH
    FlatButton(self, "Save Enemy",  x, by, bw, 36, BTN, RED,      function() self:_DoSave() end)
    x = x + bw + GAPH

    local xb = vgui.Create("DButton", self)
    xb:SetPos(x, (HEADER_H - SM) / 2)
    xb:SetSize(SM, SM)
    xb:SetText("")
    xb.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and RED or BTN)
        draw.SimpleText("r", "Marlett", w / 2, h / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    xb.DoClick = function() HORDE:ToggleEnemyConfig() end
end

function PANEL:OpenDifficultyPicker()
    if #STATE.names == 0 then return end
    local ovl, box = Modal(self, math.min(720, self:GetWide() - 40), math.min(460, self:GetTall() - 40),
        "Select Difficulty")

    local scroll = vgui.Create("DScrollPanel", box)
    scroll:SetPos(16, 52)
    scroll:SetSize(box:GetWide() - 32, box:GetTall() - 52 - 16)
    StyleScroll(scroll)

    local CW, CH = 158, 84
    local avail  = scroll:GetWide() - 14
    local cols   = math.max(1, math.floor((avail + GAP) / (CW + GAP)))

    local canvas = vgui.Create("DPanel", scroll:GetCanvas())
    canvas.Paint = function() end
    canvas:SetSize(avail, math.ceil(#STATE.names / cols) * (CH + GAP))

    for i, D in ipairs(STATE.names) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local b = vgui.Create("DButton", canvas)
        b:SetPos(col * (CW + GAP), row * (CH + GAP))
        b:SetSize(CW, CH)
        b:SetText("")
        b.Paint = function(s, w, h)
            local cur = (D == self.diff)
            draw.RoundedBox(6, 0, 0, w, h, cur and RED or (s:IsHovered() and CARD_H or CARD))
            draw.SimpleText(DiffTitle(D), "HE_Label", w / 2, h / 2 - 8, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            local st = HORDE.enemies_all[D]
            local sub = st and (table.Count(st) .. " enemies") or "..."
            if D == STATE.active then sub = sub .. "  ·  current" end
            draw.SimpleText(sub, "HE_Small", w / 2, h / 2 + 16, cur and WH or DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function()
            ovl:Remove()
            self:_SelectDifficulty(D)
        end
    end
end

function PANEL:_BuildLeft()
    local scroll = vgui.Create("DScrollPanel", self)
    scroll:SetPos(self.LX, HEADER_H)
    scroll:SetSize(self.LW + 22, self:GetTall() - HEADER_H - M)
    StyleScroll(scroll)
    self.leftScroll = scroll

    local list = vgui.Create("DPanel", scroll:GetCanvas())
    list:SetSize(self.LW, 100)
    list.Paint = function() end
    self.listPanel = list
end

function PANEL:_Pass(en)
    if self.search == "" then return true end
    return string.find(string.lower(en.name  or ""), self.search, 1, true) ~= nil
        or string.find(string.lower(en.class or ""), self.search, 1, true) ~= nil
end

function PANEL:Refresh()
    if not IsValid(self.listPanel) then return end
    local lp = self.listPanel
    lp:Clear()

    local enemies = self:_Store() or {}
    self._lastTbl   = enemies
    self._lastCount = table.Count(enemies)
    self.total      = self._lastCount

    local lw    = lp:GetWide()
    local gridX = 16
    local gridW = lw - gridX - 12
    local COLS  = math.Clamp(math.floor((gridW + GAP) / (56 + GAP)), 3, 8)
    local ISIZ  = math.floor((gridW - (COLS - 1) * GAP) / COLS)

    local byWave = {}
    for _, en in pairs(enemies) do
        if self:_Pass(en) then
            local wv = en.wave or 1
            byWave[wv] = byWave[wv] or {}
            table.insert(byWave[wv], en)
        end
    end

    local maxSlot = math.max(10, self.extraSlots[self.diff or ""] or 0)
    local has666  = STATE.wave666[self.diff or ""] == true
    for _, en in pairs(enemies) do
        local wv = en.wave or 1
        if wv == WAVE666 then has666 = true
        elseif wv > maxSlot then maxSlot = wv end
    end
    self._maxSlot = maxSlot

    local waveOrder = {}
    for i = 1, maxSlot do waveOrder[#waveOrder + 1] = i end
    if has666 then waveOrder[#waveOrder + 1] = WAVE666 end

    local totalH = 0
    for _, wv in ipairs(waveOrder) do
        local grp = byWave[wv] or {}
        if not (#grp == 0 and self.search ~= "") then

        table.sort(grp, function(a, b) return (a.name or "") < (b.name or "") end)

        local closed = self.collapsed[wv]
        if closed == nil then closed = (#grp == 0) end

        local title = (wv == WAVE666) and "Wave 666 (Elite)" or ("Wave " .. wv)
        local tag = nil
        if wv ~= WAVE666 then
            if wv % 5 == 0 then tag = "boss slot" elseif wv >= 6 then tag = "pool" end
        end
        local cb = vgui.Create("DButton", lp)
        cb:SetPos(0, totalH)
        cb:SetSize(lw, BAR_H)
        cb:SetText("")
        cb:SetTooltip("Left-click to expand/collapse, Right-click for options")
        cb.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and RED_H or RED)
            draw.SimpleText(title, "Trebuchet24", w / 2, h / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            if tag then
                draw.SimpleText(tag, "HE_Small", 14, h / 2, Color(255, 255, 255, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            DrawTri(w - 22, h / 2, 6, not closed, Color(255, 255, 255, 170))
        end
        cb.DoClick = function()
            self.collapsed[wv] = not closed
            self:Refresh()
        end
        cb.DoRightClick = function()
            local m = DermaMenu()
            local del = m:AddOption("Delete " .. title, function()
                local count = #grp
                Derma_Query(
                    "Are you sure you want to delete " .. title .. "?\nWarning: All contents and enemies (" .. count .. ") in this wave will be deleted!",
                    "Delete Wave",
                    "Delete", function()
                        local st = self:_Store()
                        if st then
                            for k, v in pairs(st) do
                                if v.wave == wv then
                                    st[k] = nil
                                    if self.selKey == k then
                                        self.selKey = nil
                                    end
                                end
                            end
                        end

                        self.collapsed[wv] = nil

                        local maxRemaining = 10
                        for _, en in pairs(st or {}) do
                            if en.wave and en.wave ~= WAVE666 and en.wave > maxRemaining then
                                maxRemaining = en.wave
                            end
                        end
                        self.extraSlots[self.diff or ""] = maxRemaining

                        self:_Send()
                        self:Refresh()
                    end,
                    "Cancel", function() end
                )
            end)
            del:SetIcon("icon16/delete.png")
            m:Open()
        end

        totalH = totalH + BAR_H

        if closed then
            totalH = totalH + 12
        else
            totalH = totalH + BAR_GAP
            local count = #grp + 1
            local rows  = math.ceil(count / COLS)
            local gridH = rows * ISIZ + (rows - 1) * GAP

            local grid = vgui.Create("DPanel", lp)
            grid:SetPos(0, totalH)
            grid:SetSize(lw, gridH)
            grid.Paint = function() end

            for idx, en in ipairs(grp) do
                local col = (idx - 1) % COLS
                local row = math.floor((idx - 1) / COLS)
                local btn = vgui.Create("DButton", grid)
                btn:SetPos(gridX + col * (ISIZ + GAP), row * (ISIZ + GAP))
                btn:SetSize(ISIZ, ISIZ)
                btn:SetText("")
                local icon   = GetEnemyIcon(en.class or "")
                local key    = EnemyKey(en)
                local isBoss = en.boss_properties and en.boss_properties.is_boss
                local isElite = IsTrue(en.is_elite)
                btn.Paint = function(s, w, h)
                    local sel = (self.selKey == key)
                    draw.RoundedBox(6, 0, 0, w, h, sel and RED or (s:IsHovered() and CARD_H or CARD))
                    if icon then
                        DrawIcon(icon, 6, 6, w - 12, h - 12, WH)
                    else
                        draw.SimpleText(string.upper(string.sub(en.name or "?", 1, 1)), "HE_Big",
                            w / 2, h / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                    if isBoss or isElite then
                        draw.RoundedBox(4, w - 19, 4, 15, 15, Color(0, 0, 0, 160))
                        draw.SimpleText(isBoss and "B" or "E", "HE_Small", w - 11.5, 11.5,
                            isBoss and RED_TXT or GOLD, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end
                btn.DoClick = function()
                    self.selKey = key
                    self:LoadEnemy(en)
                end
                btn.OnCursorEntered = function() self.tipEnemy = en end
                btn.OnCursorExited  = function() self.tipEnemy = nil end
                btn.DoRightClick = function()
                    local m = DermaMenu()
                    m:AddOption("Modify", function()
                        self.selKey = key
                        self:LoadEnemy(en)
                    end)
                    m:AddSpacer()
                    local delEnemy = m:AddOption("Delete", function()
                        Derma_Query('Delete "' .. (en.name or key) .. '" (wave ' .. tostring(en.wave) .. ')?',
                            "Confirm",
                            "Delete", function()
                                local st = self:_Store()
                                if st then st[key] = nil end
                                if self.selKey == key then self.selKey = nil end
                                self:_Send()
                                self:Refresh()
                            end,
                            "Cancel", function() end)
                    end)
                    delEnemy:SetIcon("icon16/delete.png")
                    m:Open()
                end
            end

            local ai   = #grp
            local plus = vgui.Create("DButton", grid)
            plus:SetPos(gridX + (ai % COLS) * (ISIZ + GAP), math.floor(ai / COLS) * (ISIZ + GAP))
            plus:SetSize(ISIZ, ISIZ)
            plus:SetText("")
            plus:SetTooltip("Add enemy to " .. title)
            plus.Paint = function(s, w, h)
                draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and CARD or TILE)
                local c   = s:IsHovered() and DIM or Color(88, 91, 98)
                local len = math.floor(w * 0.34)
                local th  = 4
                draw.RoundedBox(2, w / 2 - len / 2, h / 2 - th / 2, len, th, c)
                draw.RoundedBox(2, w / 2 - th / 2, h / 2 - len / 2, th, len, c)
            end
            plus.DoClick = function()
                self.selKey = nil
                self:_Reset(wv)
                self.rightScroll:GetVBar():SetScroll(0)
                self:Refresh()
            end

            totalH = totalH + gridH + BAR_GAP
        end
        end
    end

    if not self.diff or not self:_Store() then
        local hint = vgui.Create("DLabel", lp)
        hint:SetPos(16, 12)
        hint:SetSize(lw - 32, 30)
        hint:SetFont("HE_Body")
        hint:SetTextColor(DIM)
        hint:SetText("Loading enemy config from the server...")
        totalH = 56
    else
        local addBar = vgui.Create("DButton", lp)
        addBar:SetPos(0, totalH)
        addBar:SetSize(lw, BAR_H)
        addBar:SetText("")
        addBar:SetTooltip("Add the next wave slot (" .. (maxSlot + 1) .. ")")
        addBar.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and BTN_H or BTN)
            draw.SimpleText("Add Wave", "Trebuchet24", w / 2, h / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        addBar.DoClick = function()
            local nxt = (self._maxSlot or 10) + 1
            self.extraSlots[self.diff] = nxt
            self.collapsed[nxt] = false
            self:Refresh()
            timer.Simple(0.05, function()
                if IsValid(self) and IsValid(self.leftScroll) then
                    self.leftScroll:GetVBar():AnimateTo(self.listPanel:GetTall(), 0.25)
                end
            end)
        end
        totalH = totalH + BAR_H
    end

    lp:SetTall(math.max(totalH + M, self.leftScroll:GetTall()))
end

function PANEL:_BuildRight()
    local cw   = self.RW - 22
    local LBX  = 28
    local SIDE = 28
    local EH   = 34
    local PITCH = 44

    local rScroll = vgui.Create("DScrollPanel", self)
    rScroll:SetPos(self.RX, HEADER_H)
    rScroll:SetSize(self.RW, self:GetTall() - HEADER_H - M)
    StyleScroll(rScroll)
    self.rightScroll = rScroll

    local rp = vgui.Create("DPanel", rScroll:GetCanvas())
    rp:SetSize(cw, 10)
    rp.Paint = function() end
    self.rightPanel = rp

    local function TextW(t, font)
        surface.SetFont(font or "HE_Label")
        return (surface.GetTextSize(t))
    end

    local function Entry(b, text, y)
        table.insert(b.labels, {text = text, x = LBX, y = y + EH / 2, font = "HE_Label"})
        local ex = LBX + TextW(text) + 14
        local e = vgui.Create("DTextEntry", b)
        e:SetPos(ex, y)
        e:SetSize(cw - ex - SIDE, EH)
        StyledEntry(e)
        return e, ex
    end

    local function DropButton(b, entry, ex, y, fill)
        local d = vgui.Create("DButton", b)
        d:SetPos(cw - SIDE - 34, y + 3)
        d:SetSize(30, EH - 6)
        d:SetText("")
        d.Paint = function(s, w, h)
            draw.RoundedBox(5, 0, 0, w, h, s:IsHovered() and BTN_H or BTN)
            DrawTri(w / 2, h / 2, 5, true, s:IsHovered() and WH or DIM)
        end
        d.DoClick = function()
            local m = DermaMenu()
            m:SetMaxHeight(ScrH() * 0.6)
            fill(m, function(v) entry:SetValue(v) end)
            m:Open()
        end
        return d
    end

    local function Toggle(b, label, x, y, w, h, get, set, onColor)
        local t = vgui.Create("DButton", b)
        t:SetPos(x, y)
        t:SetSize(w, h)
        t:SetText("")
        t.Paint = function(s, bw, bh)
            local on = get()
            local col = on and (onColor and onColor() or RED) or (s:IsHovered() and BTN_H or BTN)
            draw.RoundedBox(6, 0, 0, bw, bh, col)
            draw.SimpleText(label, "HE_Body", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        t.DoClick = function()
            set(not get())
            self:_Restack()
        end
        return t
    end

    local function AddBlock(b, gap, show)
        b.gapAfter = gap or 26
        b.showFn   = show
        table.insert(self.blocks, b)
        return b
    end

    do
        local b = NewBlock(rp, "Required", cw)
        local y = b.cy

        self.nameEntry = Entry(b, "Name:", y)
        y = y + PITCH

        local ce, cex = Entry(b, "Class:", y)
        self.classEntry = ce
        ce:SetWide(ce:GetWide() - 38)
        DropButton(b, ce, cex, y, function(m, set)
            for cls, _ in SortedPairs(list.Get("NPC") or {}) do
                m:AddOption(cls, function() set(cls) end)
            end
        end)
        y = y + PITCH

        local wlab, plab = "Waves:", "Priority:"
        local wlw, plw   = TextW(wlab), TextW(plab)
        local inner = cw - LBX - SIDE
        local pEW   = 92
        local wEW   = inner - wlw - 12 - 22 - plw - 12 - pEW
        table.insert(b.labels, {text = wlab, x = LBX, y = y + EH / 2, font = "HE_Label"})
        local we = vgui.Create("DTextEntry", b)
        we:SetPos(LBX + wlw + 12, y)
        we:SetSize(wEW, EH)
        StyledEntry(we)
        we:SetTooltip("Waves to save this enemy to: 5; 6; 8   or a range 2-5")
        self.wavesEntry = we

        local px = LBX + wlw + 12 + wEW + 22
        table.insert(b.labels, {text = plab, x = px, y = y + EH / 2, font = "HE_Label"})
        local pe = vgui.Create("DTextEntry", b)
        pe:SetPos(px + plw + 12, y)
        pe:SetSize(pEW, EH)
        StyledEntry(pe)
        pe:SetTooltip("Spawn weight (priority) of this enemy within the wave")
        self.weightEntry = pe
        y = y + PITCH

        b:SetTall(y + 4)
        AddBlock(b, 26)
    end

    do
        local b = NewBlock(rp, "Modifiers", cw)
        local y = b.cy

        self.hpEntry     = Entry(b, "HP Scale:",    y); y = y + PITCH
        self.dmgEntry    = Entry(b, "DMG Scale:",   y); y = y + PITCH
        self.mscaleEntry = Entry(b, "Model Size:",  y); y = y + PITCH

        local we, wex = Entry(b, "Weapon:", y)
        self.weaponEntry = we
        we:SetWide(we:GetWide() - 38)
        DropButton(b, we, wex, y, function(m, set)
            m:AddOption("_gmod_default", function() set("_gmod_default") end)
            m:AddOption("_gmod_none",    function() set("_gmod_none") end)
            m:AddSpacer()
            for wpn, _ in SortedPairs(list.Get("Weapon") or {}) do
                m:AddOption(wpn, function() set(wpn) end)
            end
        end)
        y = y + PITCH

        self.skinEntry   = Entry(b, "Skin:",        y); y = y + PITCH
        self.modelEntry  = Entry(b, "Model:",       y); y = y + PITCH
        self.limitEntry  = Entry(b, "Spawn Limit:", y)
        self.limitEntry:SetTooltip("0 = no limit")
        y = y + PITCH
        self.minEntry    = Entry(b, "Spawn Min:",   y)
        self.minEntry:SetTooltip("Enemies of this type that are forced to spawn during the wave")
        y = y + PITCH + 4

        local TW, TH = math.floor(cw * 0.26), 34
        local tg = SpaceAround(cw, 3, TW)
        Toggle(b, "Color",    tg, y, TW, TH,
            function() return self.useColor end,
            function(v) self.useColor = v end,
            function() return self.colorMixer and self.colorMixer:GetColor() or RED end)
        Toggle(b, "Is Elite", tg * 2 + TW, y, TW, TH,
            function() return self.isElite end,
            function(v) self.isElite = v end)
        Toggle(b, "Is Boss",  tg * 3 + TW * 2, y, TW, TH,
            function() return self.isBoss end,
            function(v) self.isBoss = v end)
        y = y + TH + 4

        b:SetTall(y)
        AddBlock(b, 18)
    end

    do
        local b = NewBlock(rp, nil, cw)
        local mixer = vgui.Create("DColorMixer", b)
        mixer:SetPos(LBX, 0)
        mixer:SetSize(cw - LBX - SIDE, 140)
        mixer:SetPalette(false)
        mixer:SetAlphaBar(false)
        mixer:SetWangs(true)
        self.colorMixer = mixer
        b:SetTall(140)
        AddBlock(b, 26, function() return self.useColor end)
    end

    do
        local b = NewBlock(rp, "Boss", cw)
        local y = b.cy
        local TWFULL = cw - LBX - SIDE

        Toggle(b, "End wave after defeated", LBX, y, TWFULL, 34,
            function() return self.bossEnd end,
            function(v)
                self.bossEnd = v
                if not v then self.bossUnl = false end
            end)
        y = y + PITCH
        Toggle(b, "Unlimited enemies spawn during wave", LBX, y, TWFULL, 34,
            function() return self.bossUnl end,
            function(v)
                self.bossUnl = v
                if v then self.bossEnd = true end
            end)
        y = y + PITCH

        self.thresholdEntry = Entry(b, "Spawn threshold:", y)
        self.thresholdEntry:SetTooltip("Spawn more enemies after the boss health dropped to this fraction of max health")
        y = y + PITCH
        self.musicEntry = Entry(b, "Music:", y)
        y = y + PITCH
        self.musicDurEntry = Entry(b, "Duration (s):", y)
        y = y + PITCH

        table.insert(b.labels, {text = "*Boss kill reward is global.", x = LBX, y = y + 8,
            font = "HE_Small", col = DIM})
        y = y + 24

        b:SetTall(y)
        AddBlock(b, 26, function() return self.isBoss end)
    end

    do
        local b = NewBlock(rp, "Mutation", cw)
        local y = b.cy
        table.insert(b.labels, {text = "Mutation:", x = LBX, y = y + EH / 2, font = "HE_Label"})
        local ex = LBX + TextW("Mutation:") + 14
        local combo = vgui.Create("DComboBox", b)
        combo:SetPos(ex, y)
        combo:SetSize(cw - ex - SIDE, EH)
        combo:SetSortItems(false)
        StyledCombo(combo)
        combo:AddChoice("")
        for cls, _ in SortedPairs(HORDE.mutations or {}) do
            combo:AddChoice(cls)
        end
        self.mutCombo = combo
        y = y + PITCH

        b:SetTall(y + 4)
        AddBlock(b, 26)
    end

    do
        local b = NewBlock(rp, "Drops & Rewards", cw)
        local y = b.cy

        self.rewardEntry = Entry(b, "Reward Scale:", y)
        y = y + PITCH

        table.insert(b.labels, {text = "Item Drop:", x = LBX, y = y + EH / 2, font = "HE_Label"})
        local ex = LBX + TextW("Item Drop:") + 14
        local combo = vgui.Create("DComboBox", b)
        combo:SetPos(ex, y)
        combo:SetSize(cw - ex - SIDE, EH)
        combo:SetSortItems(false)
        StyledCombo(combo)
        combo:AddChoice("")
        for class, item in SortedPairs(HORDE.items or {}) do
            local g = HORDE.gadgets and HORDE.gadgets[class]
            if item.category == "Gadget" and g and g.Droppable then
                combo:AddChoice(class)
            end
        end
        self.dropCombo = combo
        y = y + PITCH

        self.dropChanceEntry = Entry(b, "Drop Chance:", y)
        y = y + PITCH

        if GetConVarNumber("horde_default_enemy_config") == 1 or
           (GetConVarString("horde_external_lua_config") or "") ~= "" then
            table.insert(b.labels, {text = "Default/external config - changes won't be saved!",
                x = LBX, y = y + 8, font = "HE_Small", col = Color(255, 80, 80)})
            y = y + 26
        end

        b:SetTall(y + 4)
        AddBlock(b, 26)
    end

    do
        local b = NewBlock(rp, "Difficulty Basics", cw)
        local y = b.cy

        self.diffBasicEntries = {}
        for _, f in ipairs(DIFF_BASIC_FIELDS) do
            local e = Entry(b, f.label, y)
            e:SetTooltip(f.tip or ("RegisterDifficulty." .. f.key))
            self.diffBasicEntries[f.key] = e
            y = y + PITCH
        end

        local gap = 8
        local btnW = math.floor((cw - LBX - SIDE - gap * 2) / 3)
        local applyBtn = vgui.Create("DButton", b)
        applyBtn:SetPos(LBX, y)
        applyBtn:SetSize(btnW, EH)
        applyBtn:SetText("")
        applyBtn.Paint = function(s, bw, bh)
            draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and RED_H or RED)
            draw.SimpleText("Apply", "HE_Body", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        applyBtn.DoClick = function() self:_ApplyDifficultyBasics() end
        applyBtn:SetTooltip("Apply & save difficulty multipliers for the selected difficulty")

        local reloadBtn = vgui.Create("DButton", b)
        reloadBtn:SetPos(LBX + btnW + gap, y)
        reloadBtn:SetSize(btnW, EH)
        reloadBtn:SetText("")
        reloadBtn.Paint = function(s, bw, bh)
            draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and BTN_H or BTN)
            draw.SimpleText("Reload", "HE_Body", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        reloadBtn.DoClick = function() self:_LoadDifficultyBasics() end
        reloadBtn:SetTooltip("Reload values from the current saved / live definition")

        local resetBtn = vgui.Create("DButton", b)
        resetBtn:SetPos(LBX + (btnW + gap) * 2, y)
        resetBtn:SetSize(btnW, EH)
        resetBtn:SetText("")
        resetBtn.Paint = function(s, bw, bh)
            draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and Color(180, 90, 40) or Color(140, 70, 30))
            draw.SimpleText("Reset", "HE_Body", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        resetBtn.DoClick = function() self:_ResetDifficultyBasics() end
        resetBtn:SetTooltip("Reset to defaults from modules/difficulties (clears DB override)")
        y = y + PITCH

        table.insert(b.labels, {
            text = "Edits HORDE:RegisterDifficulty values for the selected difficulty.",
            x = LBX, y = y + 10, font = "HE_Small", col = DIM
        })
        y = y + 28

        b:SetTall(y + 4)
        AddBlock(b, 0)
    end

    self:_Restack()
end

function PANEL:_Restack()
    local y = 0
    for _, blk in ipairs(self.blocks) do
        local vis = (blk.showFn == nil) or blk.showFn()
        blk:SetVisible(vis)
        if vis then
            blk:SetPos(0, y)
            y = y + blk:GetTall() + blk.gapAfter
        end
    end
    self.rightPanel:SetTall(y + M)
    self.rightScroll:InvalidateLayout(true)
end

local function S(v, d)
    if v == nil then return tostring(d) end
    return tostring(v)
end

function PANEL:_LoadDifficultyBasics()
    if not self.diffBasicEntries then return end
    local d = select(1, FindDifficultyByName(self.diff))
    local ov = (STATE.difficulty_basics or {})[self.diff or ""]
    for _, f in ipairs(DIFF_BASIC_FIELDS) do
        local e = self.diffBasicEntries[f.key]
        if IsValid(e) then
            local v = nil
            if istable(ov) and ov[f.key] ~= nil then
                v = ov[f.key]
            elseif d then
                v = d[f.key]
            end
            if v == nil then v = f.def end
            e:SetValue(tostring(v))
        end
    end
end

function PANEL:_ApplyDifficultyBasics()
    if not self.diff or not self.diffBasicEntries then return end
    local values = {}
    for _, f in ipairs(DIFF_BASIC_FIELDS) do
        local e = self.diffBasicEntries[f.key]
        local raw = IsValid(e) and e:GetValue() or ""
        local num = tonumber(raw)
        if num == nil then
            notification.AddLegacy("Invalid number for " .. f.key, NOTIFY_ERROR, 3)
            return
        end
        values[f.key] = num
    end

    local ok, idx = ApplyDifficultyBasicsLocal(self.diff, values)
    if not ok then
        notification.AddLegacy("Difficulty definition not found: " .. tostring(self.diff), NOTIFY_ERROR, 3)
        return
    end

    STATE.difficulty_basics = STATE.difficulty_basics or {}
    STATE.difficulty_basics[self.diff] = values

    net.Start("Horde_ApplyDifficultyBasics")
        net.WriteString(self.diff)
        net.WriteUInt(idx, 16)
        net.WriteTable(values)
    net.SendToServer()

    HORDE:PlayNotification("Difficulty basics saved for " .. DiffTitle(self.diff) .. ".")
end

function PANEL:_ResetDifficultyBasics()
    if not self.diff or not self.diffBasicEntries then return end

    local defaults = (STATE.difficulty_defaults or {})[self.diff]
    if not istable(defaults) then
        defaults = {}
        for _, f in ipairs(DIFF_BASIC_FIELDS) do
            defaults[f.key] = f.def
        end
        notification.AddLegacy("File defaults not synced yet — using generic fallbacks.", NOTIFY_GENERIC, 3)
    end

    Derma_Query(
        "Reset " .. DiffTitle(self.diff) .. " to module defaults and clear saved override?",
        "Reset Difficulty Basics",
        "Reset",
        function()
            for _, f in ipairs(DIFF_BASIC_FIELDS) do
                local e = self.diffBasicEntries[f.key]
                if IsValid(e) then
                    local v = defaults[f.key]
                    if v == nil then v = f.def end
                    e:SetValue(tostring(v))
                end
            end

            if STATE.difficulty_basics then
                STATE.difficulty_basics[self.diff] = nil
            end
            ApplyDifficultyBasicsLocal(self.diff, defaults)

            local dd = select(1, FindDifficultyByName(self.diff))
            if dd then
                for _, f in ipairs(DIFF_BASIC_FIELDS) do
                    if f.convar_fallback and defaults[f.key] == nil then dd[f.key] = nil end
                end
            end

            net.Start("Horde_ResetDifficultyBasics")
                net.WriteString(self.diff)
            net.SendToServer()

            HORDE:PlayNotification("Difficulty basics reset for " .. DiffTitle(self.diff) .. ".")
        end,
        "Cancel",
        function() end
    )
end

function PANEL:_Reset(wave)
    self.nameEntry:SetValue("")
    self.classEntry:SetValue("")
    self.wavesEntry:SetValue(tostring(wave or 1))
    self.weightEntry:SetValue("1")
    self.hpEntry:SetValue("1")
    self.dmgEntry:SetValue("1")
    self.mscaleEntry:SetValue("1")
    self.weaponEntry:SetValue("_gmod_default")
    self.skinEntry:SetValue("")
    self.modelEntry:SetValue("")
    self.limitEntry:SetValue("0")
    self.minEntry:SetValue("0")
    self.useColor, self.isElite, self.isBoss = false, false, false
    self.bossEnd, self.bossUnl = false, false
    self.thresholdEntry:SetValue("0.5")
    self.musicEntry:SetValue("")
    self.musicDurEntry:SetValue("")
    self.mutCombo:SetValue("")
    self.rewardEntry:SetValue("1")
    self.dropCombo:SetValue("")
    self.dropChanceEntry:SetValue("")
    self:_Restack()
end

function PANEL:LoadEnemy(en)
    self.nameEntry:SetValue(en.name or "")
    self.classEntry:SetValue(en.class or "")
    self.wavesEntry:SetValue(S(en.wave, 1))
    self.weightEntry:SetValue(S(en.weight, 1))
    self.hpEntry:SetValue(S(en.health_scale, 1))
    self.dmgEntry:SetValue(S(en.damage_scale, 1))
    self.mscaleEntry:SetValue(S(en.model_scale, 1))
    if en.weapon and en.weapon ~= "" then
        self.weaponEntry:SetValue(en.weapon)
    else
        self.weaponEntry:SetValue("_gmod_none")
    end
    self.skinEntry:SetValue(en.skin and tostring(en.skin) or "")
    self.modelEntry:SetValue(en.model or "")
    self.limitEntry:SetValue(S(en.spawn_limit, 0))
    self.minEntry:SetValue(S(en.spawn_min, 0))

    self.isElite = IsTrue(en.is_elite)
    if en.color and en.color.r then
        self.useColor = true
        self.colorMixer:SetColor(Color(en.color.r, en.color.g, en.color.b, en.color.a or 255))
    else
        self.useColor = false
    end

    local bp = en.boss_properties or {}
    self.isBoss  = bp.is_boss == true
    self.bossEnd = bp.end_wave == true
    self.bossUnl = bp.unlimited_enemies_spawn == true
    self.thresholdEntry:SetValue(bp.enemies_spawn_threshold and tostring(bp.enemies_spawn_threshold) or "0.5")
    self.musicEntry:SetValue(bp.music or "")
    self.musicDurEntry:SetValue(bp.music_duration and tostring(bp.music_duration) or "")

    self.mutCombo:SetValue(en.mutation or "")
    self.rewardEntry:SetValue(S(en.reward_scale, 1))

    if en.gadget_drop and en.gadget_drop.gadget and en.gadget_drop.drop_rate and en.gadget_drop.drop_rate > 0 then
        self.dropCombo:SetValue(en.gadget_drop.gadget)
        self.dropChanceEntry:SetValue(tostring(en.gadget_drop.drop_rate))
    else
        self.dropCombo:SetValue("")
        self.dropChanceEntry:SetValue("")
    end

    self:_Restack()
end

function PANEL:_DoSave()
    local name  = string.Trim(self.nameEntry:GetValue() or "")
    local class = string.Trim(self.classEntry:GetValue() or "")
    if name == "" then
        notification.AddLegacy("Name cannot be empty!", NOTIFY_ERROR, 3); return
    end
    if class == "" then
        notification.AddLegacy("Class cannot be empty!", NOTIFY_ERROR, 3); return
    end

    local waves = ParseWaves(self.wavesEntry:GetValue())
    if #waves == 0 then
        notification.AddLegacy("Waves: enter at least one wave (1-" .. HORDE.max_max_waves ..
            ", or " .. WAVE666 .. "). Example: 2; 3; 5", NOTIFY_ERROR, 4)
        return
    end

    local color = nil
    if self.useColor then color = self.colorMixer:GetColor() end

    local weapon = string.Trim(self.weaponEntry:GetValue() or "")
    if weapon == "_gmod_none" or weapon == "" then weapon = nil end

    local skin = nil
    if string.Trim(self.skinEntry:GetValue() or "") ~= "" then
        skin = tonumber(self.skinEntry:GetValue())
    end

    local boss = {
        is_boss                 = self.isBoss,
        end_wave                = self.bossEnd,
        unlimited_enemies_spawn = self.bossUnl,
        enemies_spawn_threshold = tonumber(self.thresholdEntry:GetValue()),
        music                   = self.musicEntry:GetValue(),
        music_duration          = tonumber(self.musicDurEntry:GetValue()),
    }

    local gadget_drop = nil
    do
        local g  = string.Trim(self.dropCombo:GetValue() or "")
        local dr = tonumber(self.dropChanceEntry:GetValue())
        if g ~= "" and dr and dr > 0 then
            gadget_drop = {gadget = g, drop_rate = math.max(0, dr)}
        end
    end

    local weight = tonumber(self.weightEntry:GetValue()) or 1
    local hp     = tonumber(self.hpEntry:GetValue())     or 1
    local dmg    = tonumber(self.dmgEntry:GetValue())    or 1
    local reward = tonumber(self.rewardEntry:GetValue()) or 1
    local mscale = tonumber(self.mscaleEntry:GetValue()) or 1
    local limit  = math.floor(tonumber(self.limitEntry:GetValue()) or 0)
    local smin   = math.floor(tonumber(self.minEntry:GetValue())   or 0)

    if boss.unlimited_enemies_spawn and not boss.end_wave then boss.end_wave = true end

    local store = self:_Store()
    if not store then
        notification.AddLegacy("Config is still loading, try again in a second.", NOTIFY_ERROR, 3)
        return
    end

    local model = self.modelEntry:GetValue()
    for _, wv in ipairs(waves) do
        store[name .. tostring(wv)] = {
            name = name, class = class,
            weight = math.max(0, weight), wave = wv,
            is_elite = self.isElite == true,
            health_scale = hp, damage_scale = dmg, reward_scale = reward, model_scale = mscale,
            color = color and {r = color.r, g = color.g, b = color.b, a = color.a} or nil,
            weapon = weapon or "",
            spawn_limit = limit,
            boss_properties = table.Copy(boss),
            mutation = self.mutCombo:GetValue(),
            skin = skin,
            model = (model ~= nil and model ~= "") and model or nil,
            spawn_min = smin,
            gadget_drop = gadget_drop and table.Copy(gadget_drop) or nil,
        }
    end

    self.selKey = name .. tostring(waves[1])
    self:_Send()
    self:Refresh()
end

function PANEL:_DoDeleteAll()
    if not self.diff then return end
    Derma_Query("Delete ALL enemies of " .. DiffTitle(self.diff) .. "?", "Confirm",
        "Delete All", function()
            HORDE.enemies_all[self.diff] = {}
            self.selKey = nil
            self:_Send()
            self:Refresh()
        end, "Cancel", function() end)
end

function PANEL:_DoAddDefault()
    if not self.diff then return end
    local D = self.diff
    local function send(overwrite)
        net.Start("Horde_EnemyConfigDefault")
            net.WriteString(D)
            net.WriteBool(overwrite)
        net.SendToServer()
        self.selKey = nil
    end
    Derma_Query("Add the default enemies to " .. DiffTitle(D) .. "?", "Add Default",
        "Add to existing", function() send(false) end,
        "Overwrite all",   function() send(true) end,
        "Cancel",          function() end)
end

function PANEL:Think()
    if self.debounceT ~= 0 and CurTime() > self.debounceT then
        self.debounceT = 0
        self:Refresh()
    end

    if self:IsVisible() then
        if not self.requested then
            self.requested = true
            net.Start("Horde_RequestEnemyConfig")
            net.SendToServer()
        end
    else
        self.requested = false
    end

    if CurTime() > self.nextCheck then
        self.nextCheck = CurTime() + 0.5
        local en = self:_Store() or {}
        if en ~= self._lastTbl or table.Count(en) ~= self._lastCount then
            self:Refresh()
        end
    end

    _tipEnemy = self.tipEnemy
end

function PANEL:OnRemove() _tipEnemy = nil end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, RED)
    draw.RoundedBox(6, 2, 2, w - 4, h - 4, WIN)
end

vgui.Register("HordeEnemyConfig", PANEL, "EditablePanel")

if IsValid(HORDE.EnemyConfigGUI) then
    HORDE.EnemyConfigGUI:Remove()
    HORDE.EnemyConfigGUI = nil
    gui.EnableScreenClicker(false)
end

MsgC(Color(220, 30, 56), "[HORDE] ", color_white, "Enemy Config v2 (per-difficulty) loaded\n")
