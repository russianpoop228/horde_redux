if not CLIENT then return end

local UI_SCALE = 1.1
local function sc(n) return math.floor(n * UI_SCALE + 0.5) end

surface.CreateFont("HGC_Title",   { font = "Trebuchet MS",        size = sc(22), weight = 700 })
surface.CreateFont("HGC_Section", { font = "Trebuchet MS",        size = sc(18), weight = 700 })
surface.CreateFont("HGC_Body",    { font = "CloseCaption_Normal", size = sc(18), weight = 500 })
surface.CreateFont("HGC_Small",   { font = "CloseCaption_Normal", size = sc(15), weight = 500 })

local RED      = Color(220, 30,  56)
local RED_H    = Color(240, 50,  76)
local RED_TXT  = Color(232, 39,  73)
local WIN      = Color(31,  31,  31)
local CARD     = Color(60,  64,  70)
local CARD_H   = Color(72,  77,  84)
local BTN      = Color(66,  70,  78)
local BTN_H    = Color(80,  85,  94)
local TRACK    = Color(24,  25,  28)
local WH       = Color(255, 255, 255)
local DIM      = Color(150, 152, 158)
local EYE_ON   = Color(255, 255, 255, 204)

local WIN_MAX_W  = sc(980)
local BORDER     = 2
local HEADER_H   = BORDER + sc(40)
local PAD        = sc(16)
local COL_GAP    = sc(20)
local LEFT_W     = sc(240)
local PILL_H     = sc(32)
local PILL_GAP   = sc(8)
local LIST_H_MAX = sc(360)
local DIFF_H     = sc(40)
local DIFF_GAP   = sc(6)
local CTRL_H     = sc(28)
local BTN_HEIGHT = sc(36)
local FOOT_GAP   = sc(16)
local CHROME_H   = HEADER_H + PAD + PILL_H + PILL_GAP + FOOT_GAP + BTN_HEIGHT + PAD + BORDER

local EYE_MAT = Material("gui/eye.png", "smooth mips")

local function StyleScroll(scroll)
    local vb = scroll:GetVBar()
    vb:SetWide(sc(6))
    vb:SetHideButtons(true)
    vb.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, TRACK)
    end
    vb.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and RED_H or RED)
    end
    vb.btnUp.Paint   = function() end
    vb.btnDown.Paint = function() end
end

local function FlatButton(parent, label, x, y, w, h, cb)
    local b = vgui.Create("DButton", parent)
    b:SetPos(x, y)
    b:SetSize(w, h)
    b:SetText("")
    b.Paint = function(s, bw, bh)
        draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and BTN_H or BTN)
        draw.SimpleText(label, "HGC_Body", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.DoClick = cb
    return b
end

local function SectionPill(parent, x, y, w, text)
    local p = vgui.Create("DPanel", parent)
    p:SetPos(x, y)
    p:SetSize(w, PILL_H)
    p.Paint = function(_, pw, ph)
        draw.RoundedBox(ph / 2, 0, 0, pw, ph, RED)
        draw.SimpleText(text, "HGC_Section", pw / 2, ph / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    return p
end

local function MakeField(parent, placeholder, validate, on_change)
    local box = vgui.Create("DPanel", parent)
    local entry = vgui.Create("DTextEntry", box)
    entry:SetFont("HGC_Small")
    entry:SetDrawLanguageID(false)
    entry:SetPaintBackground(false)

    entry.Paint = function(s, w, h)
        local value = s:GetValue()
        if value == "" and not s:HasFocus() then
            draw.SimpleText(placeholder, "HGC_Small", sc(3), h / 2, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local ok = validate(value)
        s:DrawTextEntryText(ok and WH or RED_TXT, RED, WH)
    end
    entry.OnChange = function()
        if on_change then on_change() end
    end

    box.Paint = function(_, w, h)
        if entry:HasFocus() then
            draw.RoundedBox(6, 0, 0, w, h, RED)
            draw.RoundedBox(5, 1, 1, w - 2, h - 2, CARD)
        else
            draw.RoundedBox(6, 0, 0, w, h, CARD)
        end
    end
    box.PerformLayout = function(_, w, h)
        entry:SetPos(sc(10), 0)
        entry:SetSize(math.max(0, w - sc(20)), h)
    end

    return box, entry
end

local MOUSE_CODES = {
    [MOUSE_LEFT] = true, [MOUSE_RIGHT] = true, [MOUSE_MIDDLE] = true,
    [MOUSE_4] = true, [MOUSE_5] = true,
}

local KEY_NAME_FIX = {
    LSHIFT = "SHIFT", RSHIFT = "SHIFT",
    LCONTROL = "CTRL", RCONTROL = "CTRL",
    LALT = "ALT", RALT = "ALT",
}

local CAPTURE_NAME, CAPTURE_CODES = {}, {}
do
    local function add(code, name)
        if not code or code <= 0 or CAPTURE_NAME[code] then return end
        CAPTURE_NAME[code] = name
        CAPTURE_CODES[#CAPTURE_CODES + 1] = code
    end

    add(MOUSE_LEFT, "MOUSE1"); add(MOUSE_RIGHT, "MOUSE2"); add(MOUSE_MIDDLE, "MOUSE3")
    add(MOUSE_4, "MOUSE4"); add(MOUSE_5, "MOUSE5")

    for gname, code in pairs(_G) do
        if isstring(gname) and type(code) == "number" and string.sub(gname, 1, 4) == "KEY_" then
            local n = string.sub(gname, 5)
            if n ~= "" and n ~= "NONE" and n ~= "FIRST" and n ~= "LAST" and n ~= "COUNT"
                and string.sub(n, 1, 5) ~= "MOUSE" then
                local name = KEY_NAME_FIX[n] or n
                if input.GetKeyCode(name) == code then
                    add(code, name)
                end
            end
        end
    end
end

local function IsCodeDown(code)
    if MOUSE_CODES[code] then return input.IsMouseDown(code) end
    return input.IsKeyDown(code)
end

local function ComboHeld(codes)
    for _, code in ipairs(codes) do
        if not IsCodeDown(code) then return false end
    end
    return true
end

local function KeyCodeForName(name)
    local code = input.GetKeyCode(name)
    if code and code > 0 then return code end
    return _G["KEY_" .. name]
end

local function MakeKeyButton(parent, on_change)
    local btn = vgui.Create("DButton", parent)
    btn:SetText("")
    btn.value    = ""
    btn.capturing = false
    btn.cap_down  = {}
    btn.cap_order = {}
    btn.cap_peak  = {}
    btn.cap_had   = false

    local function reset()
        btn.cap_down  = {}
        btn.cap_order = {}
        btn.cap_peak  = {}
        btn.cap_had   = false
    end

    function btn:GetValue() return self.value end
    function btn:SetValue(v)
        self.value = tostring(v or "")
        self.capturing = false
        reset()
    end

    function btn:StartCapture(trigger)
        self.capturing = true
        reset()
        for _, code in ipairs(CAPTURE_CODES) do
            if IsCodeDown(code) then self.cap_down[code] = true end
        end
        if trigger then self.cap_down[trigger] = true end
    end

    function btn:CancelCapture()
        self.capturing = false
        reset()
    end

    function btn:CommitCapture()
        self.capturing = false
        local parts = {}
        for _, code in ipairs(self.cap_peak) do
            parts[#parts + 1] = CAPTURE_NAME[code]
        end
        local value = table.concat(parts, "+")
        reset()
        if value == "" or value == "ESCAPE" then return end
        self.value = value
        if on_change then on_change() end
    end

    function btn:Think()
        if not self.capturing then return end

        for _, code in ipairs(CAPTURE_CODES) do
            local down = IsCodeDown(code)
            if down and not self.cap_down[code] then
                self.cap_down[code] = true
                self.cap_order[#self.cap_order + 1] = code
                self.cap_peak = table.Copy(self.cap_order)
                self.cap_had = true
            elseif not down and self.cap_down[code] then
                self.cap_down[code] = false
                for i = #self.cap_order, 1, -1 do
                    if self.cap_order[i] == code then table.remove(self.cap_order, i) end
                end
            end
        end

        if self.cap_had and #self.cap_order == 0 then
            self:CommitCapture()
        end
    end

    function btn:Paint(w, h)
        local text, col
        if self.capturing then
            local parts = {}
            for _, code in ipairs(self.cap_order) do parts[#parts + 1] = CAPTURE_NAME[code] end
            text = (#parts > 0) and table.concat(parts, "+") or "press..."
            col  = (#parts > 0) and WH or DIM
        elseif self.value ~= "" then
            text, col = self.value, WH
        else
            text, col = "key", DIM
        end

        draw.RoundedBox(6, 0, 0, w, h, self.capturing and RED or (self:IsHovered() and BTN_H or CARD))
        draw.SimpleText(text, "HGC_Small", w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    btn.OnMousePressed = function(s, code)
        if s.capturing then
            if code == MOUSE_RIGHT then s:CancelCapture() end
            return
        end
        if code == MOUSE_LEFT then
            s:StartCapture(code)
        elseif code == MOUSE_RIGHT and s.value ~= "" then
            s.value = ""
            if on_change then on_change() end
        end
    end

    return btn
end

local PANEL = {}

function PANEL:Init()
    local w = math.min(WIN_MAX_W, ScrW() - sc(32))
    local list_h = math.Clamp(ScrH() - CHROME_H - sc(40), sc(160), LIST_H_MAX)
    local h = CHROME_H + list_h

    self:SetSize(w, h)
    self:SetPos((ScrW() - w) / 2, (ScrH() - h) / 2)
    self:MakePopup()

    self.hidden       = {}
    self.fields       = {}
    self.specialFields = {}
    self.selected     = HORDE.difficulty_text and HORDE.difficulty_text[HORDE.difficulty] or nil
    self.dirty        = false
    self.awaiting     = false
    self.seen_version = -1

    self:_BuildUI(w, list_h)
    self:Reload()
end

function PANEL:_BuildUI(w, list_h)
    local close_btn = vgui.Create("DButton", self)
    close_btn:SetText("")
    close_btn:SetSize(sc(28), sc(28))
    close_btn:SetPos(w - BORDER - sc(12) - sc(28), (HEADER_H - sc(28)) / 2)
    close_btn.Paint = function(s, bw, bh)
        draw.SimpleText("r", "Marlett", bw / 2, bh / 2, s:IsHovered() and DIM or WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close_btn.DoClick = function() HORDE:ToggleGameplayConfig() end

    local left_x  = BORDER + PAD
    local top_y   = HEADER_H + PAD
    local list_y  = top_y + PILL_H + PILL_GAP
    local right_x = left_x + LEFT_W + COL_GAP
    local right_w = w - BORDER - PAD - right_x

    SectionPill(self, left_x, top_y, LEFT_W, "Difficulties")

    local diff_scroll = vgui.Create("DScrollPanel", self)
    diff_scroll:SetPos(left_x, list_y)
    diff_scroll:SetSize(LEFT_W, list_h)
    StyleScroll(diff_scroll)
    self.diffScroll = diff_scroll

    SectionPill(self, right_x, top_y, right_w, "Default Controls")

    local ctrl_scroll = vgui.Create("DScrollPanel", self)
    ctrl_scroll:SetPos(right_x, list_y)
    ctrl_scroll:SetSize(right_w, list_h)
    StyleScroll(ctrl_scroll)
    self.ctrlScroll = ctrl_scroll

    for _, def in ipairs(HORDE.GameplayControlDefs) do
        self:_AddControlRow(def)
    end

    self:_AddSpecialSection()

    local foot_y = list_y + list_h + FOOT_GAP
    local save_w, reset_w, btn_gap = sc(140), sc(90), sc(12)
    local save_x = right_x + right_w - save_w

    FlatButton(self, "Reset", save_x - btn_gap - reset_w, foot_y, reset_w, BTN_HEIGHT, function()
        self:ApplyDefaults()
    end)
    FlatButton(self, "Save settings", save_x, foot_y, save_w, BTN_HEIGHT, function()
        self:Save()
    end)
end

function PANEL:_AddControlRow(def)
    local row = vgui.Create("DPanel", self.ctrlScroll)
    row:Dock(TOP)
    row:DockMargin(0, 0, sc(12), sc(6))
    row:SetTall(CTRL_H)

    local note = def.hint or (HORDE:IsGameplayControlAdditive(def) and "Additive" or nil)

    row.Paint = function(_, rw, rh)
        draw.SimpleText(def.label, "HGC_Body", 0, rh / 2, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if note then
            surface.SetFont("HGC_Body")
            local tw = surface.GetTextSize(def.label)
            draw.SimpleText(note, "HGC_Small", tw + sc(8), rh / 2, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    local function mark_dirty() self.dirty = true end

    local cmd_box, cmd_entry = MakeField(row, "command", function(v)
        return HORDE:NormalizeGameplayCommand(v) ~= nil
    end, mark_dirty)
    local key_box = MakeKeyButton(row, mark_dirty)

    row.PerformLayout = function(_, rw, rh)
        local col = math.floor((rw - sc(16)) / 3)
        cmd_box:SetPos(col + sc(8), 0)
        cmd_box:SetSize(col, rh)
        key_box:SetPos(2 * (col + sc(8)), 0)
        key_box:SetSize(rw - 2 * (col + sc(8)), rh)
    end

    self.fields[def.id] = { cmd = cmd_entry, key = key_box }
end

function PANEL:_AddSpecialSection()
    local pill = vgui.Create("DPanel", self.ctrlScroll)
    pill:Dock(TOP)
    pill:DockMargin(0, sc(16), sc(12), 0)
    pill:SetTall(PILL_H)
    pill.Paint = function(_, pw, ph)
        draw.RoundedBox(ph / 2, 0, 0, pw, ph, RED)
        draw.SimpleText("Special Waves", "HGC_Section", pw / 2, ph / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local cap = vgui.Create("DPanel", self.ctrlScroll)
    cap:Dock(TOP)
    cap:DockMargin(0, sc(4), sc(12), sc(6))
    cap:SetTall(sc(16))
    cap.Paint = function(_, cw, ch)
        draw.SimpleText("Per run: max special waves + chance for each wave. Empty = off.",
            "HGC_Small", 0, 0, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local list = {}
    for idx, name in pairs(HORDE.difficulty_text or {}) do
        if isstring(name) then list[#list + 1] = { idx = idx, name = name } end
    end
    table.sort(list, function(a, b) return a.idx < b.idx end)

    for _, d in ipairs(list) do
        self:_AddSpecialRow(d.name)
    end
end

function PANEL:_AddSpecialRow(name)
    local row = vgui.Create("DPanel", self.ctrlScroll)
    row:Dock(TOP)
    row:DockMargin(0, 0, sc(12), sc(6))
    row:SetTall(CTRL_H)

    local label = translate.Get("Game_Difficulty_" .. name) or name
    row.Paint = function(_, rw, rh)
        draw.SimpleText(label, "HGC_Body", 0, rh / 2, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local function mark_dirty() self.dirty = true end

    local count_box, count_entry = MakeField(row, "count", function(v)
        if v == "" then return true end
        local n = tonumber(v)
        return n ~= nil and n >= 0 and n == math.floor(n) and n <= 999
    end, mark_dirty)

    local chance_box, chance_entry = MakeField(row, "chance", function(v)
        if v == "" then return true end
        local n = tonumber(v)
        return n ~= nil and n >= 0 and n <= 1
    end, mark_dirty)

    row.PerformLayout = function(_, rw, rh)
        local col = math.floor((rw - sc(16)) / 3)
        count_box:SetPos(col + sc(8), 0)
        count_box:SetSize(col, rh)
        chance_box:SetPos(2 * (col + sc(8)), 0)
        chance_box:SetSize(rw - 2 * (col + sc(8)), rh)
    end

    self.specialFields[name] = { count = count_entry, chance = chance_entry }
end

function PANEL:_AddDifficultyRow(name)
    local label = translate.Get("Game_Difficulty_" .. name) or name

    local row = vgui.Create("DButton", self.diffScroll)
    row:Dock(TOP)
    row:DockMargin(0, 0, sc(8), DIFF_GAP)
    row:SetTall(DIFF_H)
    row:SetText("")

    row.Paint = function(s, w, h)
        local border
        if self.selected == name then
            border = RED
        elseif s:IsHovered() or s:IsChildHovered() then
            border = CARD_H
        else
            border = CARD
        end
        draw.RoundedBox(h / 2, 0, 0, w, h, border)
        draw.RoundedBox(h / 2 - BORDER, BORDER, BORDER, w - BORDER * 2, h - BORDER * 2, WIN)
        draw.SimpleText(label, "HGC_Body", sc(16), h / 2, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local function press()
        self:ToggleDifficulty(name)
    end

    row.DoClick = press

    local eye = vgui.Create("DButton", row)
    eye:Dock(RIGHT)
    eye:DockMargin(0, sc(6), sc(12), sc(6))
    eye:SetWide(sc(28))
    eye:SetText("")
    eye.Paint = function(s, w, h)
        local is_hidden = self.hidden[name] == true
        local col = is_hidden and DIM or (s:IsHovered() and WH or EYE_ON)
        local size = sc(20)
        local x, y = (w - size) / 2, (h - size) / 2

        surface.SetDrawColor(col)
        surface.SetMaterial(EYE_MAT)
        surface.DrawTexturedRect(x, y, size, size)

        if is_hidden then
            draw.NoTexture()
            for ox = -1, 1 do
                surface.DrawLine(x + 2 + ox, y + 2, x + size - 2 + ox, y + size - 2)
            end
        end
    end
    eye.DoClick = press
end

function PANEL:RebuildDifficulties()
    self.diffScroll:Clear()

    local list = {}
    for idx, name in pairs(HORDE.difficulty_text or {}) do
        if isstring(name) then list[#list + 1] = { idx = idx, name = name } end
    end
    table.sort(list, function(a, b) return a.idx < b.idx end)

    if not self.selected and list[1] then self.selected = list[1].name end
    for _, d in ipairs(list) do
        self:_AddDifficultyRow(d.name)
    end
end

function PANEL:ToggleDifficulty(name)
    if self.hidden[name] then
        self.hidden[name] = nil
    else
        local visible = 0
        for _, n in pairs(HORDE.difficulty_text or {}) do
            if isstring(n) and not self.hidden[n] then visible = visible + 1 end
        end
        if visible <= 1 then
            HORDE:PlayNotification("At least one difficulty must stay visible.", 1)
            return
        end
        self.hidden[name] = true
    end
    self.dirty = true
end

function PANEL:Reload()
    local cfg = HORDE.gameplay_config or {}

    self.hidden = {}
    for name, flag in pairs(cfg.hidden_difficulties or {}) do
        if flag == true then self.hidden[name] = true end
    end
    self:RebuildDifficulties()

    for _, def in ipairs(HORDE.GameplayControlDefs) do
        local f = self.fields[def.id]
        if f then
            local cmd, key = HORDE:GetGameplayControl(def.id)
            f.cmd:SetValue(cmd)
            f.key:SetValue(key)
        end
    end

    for name, f in pairs(self.specialFields or {}) do
        local count, chance = HORDE:GetSpecialWaveSettings(name)
        f.count:SetValue(count > 0 and tostring(count) or "")
        f.chance:SetValue(chance > 0 and tostring(chance) or "")
    end

    self.dirty        = false
    self.awaiting     = false
    self.seen_version = HORDE.gameplay_config_version
end

function PANEL:ApplyDefaults()
    self.hidden = {}
    for _, def in ipairs(HORDE.GameplayControlDefs) do
        local f = self.fields[def.id]
        if f then
            f.cmd:SetValue(def.cmd)
            f.key:SetValue(def.key)
        end
    end
    for _, f in pairs(self.specialFields or {}) do
        f.count:SetValue("")
        f.chance:SetValue("")
    end
    self.dirty = true
end

function PANEL:Save()
    local controls = {}
    for _, def in ipairs(HORDE.GameplayControlDefs) do
        local f = self.fields[def.id]
        local name = string.gsub(def.label, ":%s*$", "")

        local cmd, err_c = HORDE:NormalizeGameplayCommand(f.cmd:GetValue())
        if cmd == nil then
            HORDE:PlayNotification(name .. " - command: " .. tostring(err_c), 1)
            return
        end
        local key, err_k = HORDE:NormalizeGameplayKey(f.key:GetValue())
        if key == nil then
            HORDE:PlayNotification(name .. " - key: " .. tostring(err_k), 1)
            return
        end
        controls[def.id] = { cmd = cmd, key = key }
    end

    local special_waves = {}
    for name, f in pairs(self.specialFields or {}) do
        local count  = tonumber(f.count:GetValue()) or 0
        local chance = tonumber(f.chance:GetValue()) or 0
        if count < 0 or count > 999 or count ~= math.floor(count) then
            HORDE:PlayNotification("Special Waves - " .. name .. ": count must be a whole number 0-999.", 1)
            return
        end
        if chance < 0 or chance > 1 then
            HORDE:PlayNotification("Special Waves - " .. name .. ": chance must be between 0 and 1.", 1)
            return
        end
        if count > 0 and chance > 0 then
            special_waves[name] = { count = count, chance = chance }
        end
    end

    net.Start("Horde_SetGameplayConfig")
        net.WriteTable({
            hidden_difficulties = table.Copy(self.hidden),
            controls = controls,
            special_waves = special_waves,
        })
    net.SendToServer()
    self.awaiting = true
end

function PANEL:Think()
    if self.seen_version ~= HORDE.gameplay_config_version and (self.awaiting or not self.dirty) then
        self:Reload()
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, RED)
    draw.RoundedBox(6, BORDER, BORDER, w - BORDER * 2, h - BORDER * 2, WIN)
    draw.RoundedBoxEx(8, 0, 0, w, HEADER_H, RED, true, true, false, false)
    draw.SimpleText("Gameplay Config Menu", "HGC_Title", 16, HEADER_H / 2, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

vgui.Register("HordeGameplayConfig", PANEL, "EditablePanel")

if IsValid(HORDE.GameplayConfigGUI) then
    HORDE.GameplayConfigGUI:Remove()
    HORDE.GameplayConfigGUI = nil
    gui.EnableScreenClicker(false)
end

local cv_use_defaults = CreateClientConVar("horde_use_default_controls", "1", true, false,
    "Use the server's default keys for commands you have not bound yourself.")

local default_binds = nil
local held = {}

function HORDE.InvalidateGameplayBinds()
    default_binds = nil
    held = {}
end

hook.Add("Horde_GameplayConfigSynced", "Horde_GameplayDefaultControls_Rebuild", function()
    default_binds = nil
    held = {}
end)

local function GetDefaultBinds()
    if default_binds then return default_binds end
    default_binds = {}
    for _, def in ipairs(HORDE.GameplayControlDefs) do
        local cmd, key = HORDE:GetEffectiveGameplayControl(def.id)
        if cmd ~= "" and key ~= "" then
            local codes, ok = {}, true
            for _, part in ipairs(string.Explode("+", key)) do
                local code = KeyCodeForName(part)
                if not code or code <= 0 then ok = false break end
                codes[#codes + 1] = code
            end
            if ok and #codes > 0 then
                default_binds[#default_binds + 1] = {
                    id        = def.id,
                    key       = key,
                    cmd       = cmd,
                    codes     = codes,
                    single    = (#codes == 1) and codes[1] or nil,
                    additive  = HORDE:IsGameplayControlAdditive(def),
                    ignore_ui = def.ignore_ui == true,
                }
            end
        end
    end
    return default_binds
end

local function BindState(entry)
    local bound = input.LookupBinding(entry.cmd, true)
    local engine_owns_key = bound ~= nil and string.upper(bound) == string.upper(entry.key)
    return bound, engine_owns_key, (not engine_owns_key) and (entry.additive or bound == nil)
end

local function PollDefaultControls()
    if not cv_use_defaults:GetBool() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local typing   = ply:IsTyping()
    local console  = gui.IsConsoleVisible and gui.IsConsoleVisible() or false
    local cursor   = vgui.CursorVisible() or gui.IsGameUIVisible()

    for _, entry in ipairs(GetDefaultBinds()) do
        local ui_block = typing or console or (cursor and not entry.ignore_ui)
        local down = (not ui_block) and ComboHeld(entry.codes)

        if down and not held[entry] then
            local _, _, run = BindState(entry)
            if run then
                held[entry] = true
                RunConsoleCommand(entry.cmd)
            end
        elseif not down and held[entry] then
            held[entry] = nil
            if string.sub(entry.cmd, 1, 1) == "+" then
                RunConsoleCommand("-" .. string.sub(entry.cmd, 2))
            end
        end
    end
end

hook.Remove("Think", "Horde_GameplayDefaultControls")
timer.Create("Horde_GameplayDefaultControls", 0, 0, PollDefaultControls)

concommand.Add("horde_controls_debug", function()
    local ply = LocalPlayer()
    print(string.format("[Horde Controls] use_defaults=%s typing=%s console=%s cursor=%s gameui=%s",
        tostring(cv_use_defaults:GetBool()), tostring(IsValid(ply) and ply:IsTyping()),
        tostring(gui.IsConsoleVisible and gui.IsConsoleVisible()), tostring(vgui.CursorVisible()),
        tostring(gui.IsGameUIVisible())))
    for _, def in ipairs(HORDE.GameplayControlDefs) do
        local cmd, key = HORDE:GetEffectiveGameplayControl(def.id)
        local entry
        for _, e in ipairs(GetDefaultBinds()) do if e.id == def.id then entry = e break end end
        if entry then
            local bound, owns, run = BindState(entry)
            print(string.format("  %-14s %-28s key=%-10s codes=%s engine_bind=%s run=%s",
                def.id, cmd, key, table.concat(entry.codes, "+"), tostring(bound), tostring(run)))
        else
            print(string.format("  %-14s %-28s key=%-10s (inactive)", def.id, cmd, key))
        end
    end
end)

MsgC(Color(220, 30, 56), "[HORDE] ", color_white, "Gameplay Config loaded\n")
