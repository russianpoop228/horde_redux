if not CLIENT then return end

HORDE = HORDE or {}
local SWAPI = HORDE.SpecialWaves
if not SWAPI then return end

local UI_SCALE = 1.1
local function sc(n) return math.floor(n * UI_SCALE + 0.5) end

surface.CreateFont("HSW_Title",   { font = "Trebuchet MS",        size = sc(22), weight = 700 })
surface.CreateFont("HSW_Section", { font = "Trebuchet MS",        size = sc(18), weight = 700 })
surface.CreateFont("HSW_Body",    { font = "CloseCaption_Normal", size = sc(18), weight = 500 })
surface.CreateFont("HSW_Small",   { font = "CloseCaption_Normal", size = sc(15), weight = 500 })
surface.CreateFont("HSW_Mono",    { font = "Courier New",         size = sc(15), weight = 700 })

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
local WH_90    = Color(255, 255, 255, 230)
local DIM      = Color(150, 152, 158)

local WIN_MAX_W   = sc(960)
local WIN_H       = sc(600)
local BORDER      = 2
local HEADER_H    = BORDER + sc(40)
local PAD         = sc(16)
local COL_GAP     = sc(20)
local LEFT_W      = sc(235)
local PILL_H      = sc(32)
local PILL_GAP    = sc(8)
local PRESET_H    = sc(36)
local PRESET_GAP  = sc(6)
local ADD_GAP     = sc(10)
local FIELD_H     = sc(28)
local MIXER_H     = sc(140)
local ROW_GAP     = sc(8)
local FIRST_GAP   = sc(12)
local SECTION_GAP = sc(16)
local GRID_GAP    = sc(12)
local BTN_HEIGHT  = sc(36)
local FOOT_GAP    = sc(12)
local SCROLL_PAD  = sc(12)

local SOURCE_CHOICES = {
    "Custom (Manually written classnames)",
    "Data Config (enemies.txt)",
}
local SOURCE_VALUES  = { "custom", "config" }
local DEFAULT_SOURCE = 2

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
        draw.SimpleText(label, "HSW_Body", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.DoClick = cb or function() end
    return b
end

local function SectionPill(parent, text)
    local p = parent:Add("DPanel")
    p:Dock(TOP)
    p:DockMargin(0, 0, SCROLL_PAD, 0)
    p:SetTall(PILL_H)
    p.Paint = function(_, pw, ph)
        draw.RoundedBox(ph / 2, 0, 0, pw, ph, RED)
        draw.SimpleText(text, "HSW_Section", pw / 2, ph / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    return p
end

local function MakeField(parent, placeholder, validate)
    local box = vgui.Create("DPanel", parent)
    local entry = vgui.Create("DTextEntry", box)
    entry:SetFont("HSW_Small")
    entry:SetDrawLanguageID(false)
    entry:SetPaintBackground(false)

    entry.Paint = function(s, w, h)
        local value = s:GetValue()
        if value == "" and not s:HasFocus() and placeholder then
            draw.SimpleText(placeholder, "HSW_Small", sc(3), h / 2, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local ok = (validate == nil) or validate(value)
        s:DrawTextEntryText(ok and WH or RED_TXT, RED, WH)
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

local function IsNumber(v) return v == "" or tonumber(v) ~= nil end

local function MakeCombo(parent, choices, default_index)
    local combo = vgui.Create("DComboBox", parent)
    combo:SetFont("HSW_Small")
    combo:SetTextColor(WH)
    combo:SetTextInset(sc(10), 0)
    combo:SetSortItems(false)
    for i, text in ipairs(choices) do
        combo:AddChoice(text, i, i == default_index)
    end

    if IsValid(combo.DropButton) then
        combo.DropButton.Paint = function() end
    end

    combo.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and CARD_H or CARD)

        local cx, cy, a, b = w - sc(16), h / 2, sc(5), sc(3)
        draw.NoTexture()
        surface.SetDrawColor(DIM)
        surface.DrawPoly({
            { x = cx - a, y = cy - b },
            { x = cx + a, y = cy - b },
            { x = cx,     y = cy + b },
        })
    end

    return combo
end

local function MakeBannerColor(parent)
    local mixer = vgui.Create("DColorMixer", parent)
    mixer:SetPalette(false)
    mixer:SetAlphaBar(false)
    mixer:SetWangs(true)
    mixer:SetColor(Color(SWAPI.DEFAULT_BANNER.r, SWAPI.DEFAULT_BANNER.g, SWAPI.DEFAULT_BANNER.b))
    return mixer
end

local function ParseColor(str)
    if not isstring(str) then return nil end
    str = string.Trim(str)
    if str == "" then return nil end
    local r, g, b = string.match(str, "^(%d+)%s*[%s,]+%s*(%d+)%s*[%s,]+%s*(%d+)$")
    if not r then return nil end
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if r > 255 or g > 255 or b > 255 then return nil end
    return r, g, b
end

local function SplitList(str, maxlen)
    local out, seen = {}, {}
    if not isstring(str) then return out end
    for _, part in ipairs(string.Explode(",", str)) do
        local s = string.Trim(part)
        if s ~= "" then
            if maxlen and #s > maxlen then s = string.sub(s, 1, maxlen) end
            local key = string.lower(s)
            if not seen[key] then
                seen[key] = true
                out[#out + 1] = s
            end
        end
    end
    return out
end

local PANEL = {}

function PANEL:Init()
    local w = math.min(WIN_MAX_W, ScrW() - sc(32))
    local h = math.min(WIN_H,     ScrH() - sc(32))

    self:SetSize(w, h)
    self:SetPos((ScrW() - w) / 2, (ScrH() - h) / 2)
    self:MakePopup()

    self.presets      = table.Copy(HORDE.specialwaves_presets or {})
    self.selected     = (#self.presets > 0) and 1 or nil
    self.seen_version = HORDE.specialwaves_version or 0

    self:_BuildUI(w, h)
    self:_RebuildPresets()
    self:_FillForm(self.selected and self.presets[self.selected] or nil)
end

function PANEL:_BuildUI(w, h)
    local close_btn = vgui.Create("DButton", self)
    close_btn:SetText("")
    close_btn:SetSize(sc(28), sc(28))
    close_btn:SetPos(w - BORDER - sc(12) - sc(28), (HEADER_H - sc(28)) / 2)
    close_btn.Paint = function(s, bw, bh)
        draw.SimpleText("r", "Marlett", bw / 2, bh / 2, s:IsHovered() and DIM or WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close_btn.DoClick = function() HORDE:ToggleSpecialWavesConfig() end

    local left_x   = BORDER + PAD
    local top_y    = HEADER_H + PAD
    local body_end = h - BORDER - PAD
    local foot_y   = body_end - BTN_HEIGHT
    local right_x  = left_x + LEFT_W + COL_GAP
    local right_w  = w - BORDER - PAD - right_x

    local pill = vgui.Create("DPanel", self)
    pill:SetPos(left_x, top_y)
    pill:SetSize(LEFT_W, PILL_H)
    pill.Paint = function(_, pw, ph)
        draw.RoundedBox(ph / 2, 0, 0, pw, ph, RED)
        draw.SimpleText("Wave Presets", "HSW_Section", pw / 2, ph / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local list_y = top_y + PILL_H + PILL_GAP
    local list_h = foot_y - ADD_GAP - list_y

    local preset_scroll = vgui.Create("DScrollPanel", self)
    preset_scroll:SetPos(left_x, list_y)
    preset_scroll:SetSize(LEFT_W, list_h)
    StyleScroll(preset_scroll)
    self.presetScroll = preset_scroll

    local add = vgui.Create("DButton", self)
    add:SetPos(left_x, foot_y)
    add:SetSize(LEFT_W, BTN_HEIGHT)
    add:SetText("")
    add.Paint = function(s, bw, bh)
        draw.RoundedBox(bh / 2, 0, 0, bw, bh, s:IsHovered() and RED_H or RED)
        draw.SimpleText("+ Add Preset", "HSW_Section", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    add.DoClick = function() self:_AddPreset() end

    local form_h = foot_y - FOOT_GAP - top_y

    local form = vgui.Create("DScrollPanel", self)
    form:SetPos(right_x, top_y)
    form:SetSize(right_w, form_h)
    StyleScroll(form)
    self.formScroll = form

    self:_BuildForm()

    surface.SetFont("HSW_Body")
    local function btn_w(text) return surface.GetTextSize(text) + sc(48) end

    local save_w, del_w, gap = btn_w("Save Preset"), btn_w("Delete Preset"), sc(12)
    local save_x = right_x + right_w - save_w

    FlatButton(self, "Delete Preset", save_x - gap - del_w, foot_y, del_w, BTN_HEIGHT, function() self:_DeletePreset() end)
    FlatButton(self, "Save Preset",   save_x,               foot_y, save_w, BTN_HEIGHT, function() self:_Save() end)
end

function PANEL:_AddRow(label, top, height, build)
    local row = self.formScroll:Add("DPanel")
    row:Dock(TOP)
    row:DockMargin(0, top, SCROLL_PAD, 0)
    row:SetTall(height)

    row.Paint = function(_, rw, rh)
        draw.SimpleText(label, "HSW_Body", 0, math.min(rh, FIELD_H) / 2, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local ctl = build(row)

    row.PerformLayout = function(_, rw, rh)
        local col = (rw - 11 * GRID_GAP) / 12
        local label_w = math.floor(4 * col + 3 * GRID_GAP)
        local ctl_x = label_w + GRID_GAP
        ctl:SetPos(ctl_x, 0)
        ctl:SetSize(rw - ctl_x, rh)
    end

    return ctl, row
end

function PANEL:_FieldRow(label, top, placeholder, validate)
    local entry
    local _, row = self:_AddRow(label, top, FIELD_H, function(r)
        local box, e = MakeField(r, placeholder, validate)
        entry = e
        return box
    end)
    return entry, row
end

function PANEL:_BuildForm()
    SectionPill(self.formScroll, "Main Settings")

    self.nameEntry = self:_FieldRow("Preset Name:", FIRST_GAP, "Preset name", nil)
    self.minWaveEntry = self:_FieldRow("Starting with Wave:", ROW_GAP, "1", IsNumber)

    self.sourceCombo = self:_AddRow("Source of enemies:", ROW_GAP, FIELD_H, function(row)
        return MakeCombo(row, SOURCE_CHOICES, DEFAULT_SOURCE)
    end)

    self.pickEntry, self.row_pick = self:_FieldRow("Different enemies:", ROW_GAP, "2", IsNumber)
    self.customEntry, self.row_custom = self:_FieldRow("Custom enemies:", ROW_GAP, "classname, classname", nil)

    local function applySource(key)
        local source
        if type(key) == "number" then
            source = SOURCE_VALUES[key]
        elseif isstring(key) then
            source = (key == SOURCE_CHOICES[1]) and "custom" or "config"
        end
        source = source or "config"

        self.currentSource = source
        self.row_pick:SetVisible(source ~= "custom")
        self.row_custom:SetVisible(source == "custom")
        if IsValid(self.formScroll) then self.formScroll:InvalidateLayout(true) end
    end
    function self.sourceCombo:OnSelect(_, val, data)
        applySource(data or val)
    end
    self._applySource = applySource
    self.currentSource = "config"

    local mod_pill = SectionPill(self.formScroll, "Modifiers")
    mod_pill:DockMargin(0, SECTION_GAP, SCROLL_PAD, 0)

    self.hpEntry   = self:_FieldRow("Health Scale:",   ROW_GAP, "1.0", IsNumber)
    self.dmgEntry  = self:_FieldRow("Damage Scale:",   ROW_GAP, "1.0", IsNumber)
    self.rwdEntry  = self:_FieldRow("Reward Scale:",   ROW_GAP, "1.0", IsNumber)
    self.mdlEntry  = self:_FieldRow("Model Scale:",    ROW_GAP, "1.0", IsNumber)
    self.skinEntry = self:_FieldRow("Skin (-1 = default):", ROW_GAP, "-1", IsNumber)
    self.mutEntry  = self:_FieldRow("Mutations:",      ROW_GAP, "mutation1, mutation2", nil)
    self.colorEntry = self:_FieldRow("Enemies color:", ROW_GAP, "255 255 255", nil)
    self.matEntry  = self:_FieldRow("Enemy material:", ROW_GAP, "Default", nil)

    self.bannerMixer = self:_AddRow("Banner color:", ROW_GAP, MIXER_H, function(row)
        return MakeBannerColor(row)
    end)
end

function PANEL:_FillForm(p)
    local m = (p and istable(p.mods)) and p.mods or {}

    self.nameEntry:SetValue(p and p.name or "")
    self.minWaveEntry:SetValue(p and tostring(p.min_wave or 1) or "")
    self.pickEntry:SetValue(p and tostring(p.pick_count or 2) or "")
    self.customEntry:SetValue((p and istable(p.custom_enemies)) and table.concat(p.custom_enemies, ", ") or "")

    local source_idx = (p and p.enemy_source == "custom") and 1 or DEFAULT_SOURCE
    self.sourceCombo:SetValue(SOURCE_CHOICES[source_idx])
    if self._applySource then self._applySource(source_idx) end

    self.hpEntry:SetValue(tostring(m.health_scale or 1))
    self.dmgEntry:SetValue(tostring(m.damage_scale or 1))
    self.rwdEntry:SetValue(tostring(m.reward_scale or 1))
    self.mdlEntry:SetValue(tostring(m.model_scale or 1))
    self.skinEntry:SetValue(tostring(m.skin ~= nil and m.skin or -1))
    self.mutEntry:SetValue(istable(m.mutations) and table.concat(m.mutations, ", ") or "")

    if m.use_color then
        self.colorEntry:SetValue(string.format("%d %d %d", m.color_r or 255, m.color_g or 255, m.color_b or 255))
    else
        self.colorEntry:SetValue("")
    end
    self.matEntry:SetValue(m.material or "")

    local b = (p and istable(p.banner)) and p.banner or SWAPI.DEFAULT_BANNER
    self.bannerMixer:SetColor(Color(b.r, b.g, b.b))
end

function PANEL:_CommitForm()
    local p = self.selected and self.presets[self.selected]
    if not p then return false end

    local name = string.Trim(self.nameEntry:GetValue())
    if name == "" then
        HORDE:PlayNotification("Preset name cannot be empty.", 1)
        return false
    end
    if self.minWaveEntry:GetValue() ~= "" and not tonumber(self.minWaveEntry:GetValue()) then
        HORDE:PlayNotification("Starting with Wave must be a number.", 1)
        return false
    end

    p.name     = name
    p.min_wave = math.max(1, math.floor(tonumber(self.minWaveEntry:GetValue()) or 1))

    p.enemy_source = self.currentSource or "config"

    if p.enemy_source == "custom" then
        p.custom_enemies = SplitList(self.customEntry:GetValue(), SWAPI.ENEMY_NAME_MAX)
        if #p.custom_enemies == 0 then
            HORDE:PlayNotification("Custom source needs at least one classname.", 1)
            return false
        end
    else
        p.pick_count     = math.max(1, math.floor(tonumber(self.pickEntry:GetValue()) or 1))
        p.custom_enemies = {}
    end

    local color_enabled = string.Trim(self.colorEntry:GetValue()) ~= ""
    local cr, cg, cb
    if color_enabled then
        cr, cg, cb = ParseColor(self.colorEntry:GetValue())
        if not cr then
            HORDE:PlayNotification("Enemies color must be 'R G B' (0-255) or empty.", 1)
            return false
        end
    end

    local mat = string.Trim(self.matEntry:GetValue())
    if string.lower(mat) == "default" then mat = "" end

    p.mods = p.mods or {}
    p.mods.health_scale = tonumber(self.hpEntry:GetValue())  or 1
    p.mods.damage_scale = tonumber(self.dmgEntry:GetValue()) or 1
    p.mods.reward_scale = tonumber(self.rwdEntry:GetValue()) or 1
    p.mods.model_scale  = tonumber(self.mdlEntry:GetValue()) or 1
    p.mods.skin         = math.floor(tonumber(self.skinEntry:GetValue()) or -1)
    p.mods.mutations    = SplitList(self.mutEntry:GetValue(), SWAPI.NAME_MAX)
    p.mods.use_color    = color_enabled
    p.mods.color_r      = cr or 255
    p.mods.color_g      = cg or 255
    p.mods.color_b      = cb or 255
    p.mods.material     = mat

    local col = self.bannerMixer:GetColor()
    p.banner = { r = col.r, g = col.g, b = col.b }

    SWAPI.NormalizePreset(p)
    return true
end

function PANEL:_AddPresetRow(index, data)
    local row = self.presetScroll:Add("DButton")
    row:Dock(TOP)
    row:DockMargin(0, 0, SCROLL_PAD - sc(4), PRESET_GAP)
    row:SetTall(PRESET_H)
    row:SetText("")

    local tag = (data.enemy_source == "custom") and "CUSTOM" or (tostring(data.pick_count or 1) .. "x")

    row.Paint = function(s, rw, rh)
        local active = (self.selected == index)
        if active then
            draw.RoundedBox(rh / 2, 0, 0, rw, rh, RED)
        else
            draw.RoundedBox(rh / 2, 0, 0, rw, rh, s:IsHovered() and CARD_H or CARD)
            draw.RoundedBox(rh / 2 - BORDER, BORDER, BORDER, rw - BORDER * 2, rh - BORDER * 2, WIN)
        end
        draw.SimpleText(data.name or "?", "HSW_Body", sc(16), rh / 2, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(tag, "HSW_Mono", rw - sc(16), rh / 2, active and WH_90 or DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    row.DoClick = function()
        if not self:_CommitForm() then return end
        self.selected = index
        self:_RebuildPresets()
        self:_FillForm(self.presets[index])
    end
end

function PANEL:_RebuildPresets()
    self.presetScroll:Clear()
    for i, data in ipairs(self.presets) do
        self:_AddPresetRow(i, data)
    end
end

function PANEL:_AddPreset()
    self.presets[#self.presets + 1] = SWAPI.NewPreset("New Preset " .. (#self.presets + 1))
    self.selected = #self.presets
    self:_RebuildPresets()
    self:_FillForm(self.presets[self.selected])
    self:_Push()
end

function PANEL:_DeletePreset()
    if not self.selected then return end
    local p = self.presets[self.selected]
    Derma_Query("Delete preset \"" .. tostring(p.name or "?") .. "\"?", "Confirm",
        "Yes", function()
            table.remove(self.presets, self.selected)
            self.selected = (#self.presets > 0) and math.min(self.selected, #self.presets) or nil
            self:_RebuildPresets()
            self:_FillForm(self.selected and self.presets[self.selected] or nil)
            self:_Push()
        end,
        "No", function() end)
end

function PANEL:_Save()
    if not self:_CommitForm() then return end
    self:_RebuildPresets()
    self:_Push()
    HORDE:PlayNotification("Preset \"" .. tostring(self.presets[self.selected].name) .. "\" saved.")
end

function PANEL:_Push()
    net.Start("Horde_SetSpecialWaves")
        net.WriteTable({ presets = self.presets })
    net.SendToServer()
end

function PANEL:Think()
    local ver = HORDE.specialwaves_version or 0
    if self.seen_version ~= ver then
        self.seen_version = ver
        self.presets = table.Copy(HORDE.specialwaves_presets or {})
        if self.selected and self.selected > #self.presets then
            self.selected = (#self.presets > 0) and #self.presets or nil
        end
        self:_RebuildPresets()
        self:_FillForm(self.selected and self.presets[self.selected] or nil)
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, RED)
    draw.RoundedBox(6, BORDER, BORDER, w - BORDER * 2, h - BORDER * 2, WIN)
    draw.RoundedBoxEx(8, 0, 0, w, HEADER_H, RED, true, true, false, false)
    draw.SimpleText("Special Wave Config", "HSW_Title", 16, HEADER_H / 2, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

vgui.Register("HordeSpecialWavesConfig", PANEL, "EditablePanel")

function HORDE:ToggleSpecialWavesConfig()
    if not IsValid(HORDE.SpecialWavesConfigGUI) then
        HORDE.SpecialWavesConfigGUI = vgui.Create("HordeSpecialWavesConfig")
        HORDE.SpecialWavesConfigGUI:SetVisible(false)
    end

    if HORDE.SpecialWavesConfigGUI:IsVisible() then
        HORDE.SpecialWavesConfigGUI:Hide()
        gui.EnableScreenClicker(false)
    else
        HORDE.SpecialWavesConfigGUI:Show()
        gui.EnableScreenClicker(true)
    end
end

if IsValid(HORDE.SpecialWavesConfigGUI) then
    HORDE.SpecialWavesConfigGUI:Remove()
    HORDE.SpecialWavesConfigGUI = nil
    gui.EnableScreenClicker(false)
end

MsgC(Color(220, 30, 56), "[HORDE] ", color_white, "Special Waves Config loaded\n")
