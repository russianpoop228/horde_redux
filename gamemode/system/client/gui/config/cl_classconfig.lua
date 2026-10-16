if not CLIENT then return end

surface.CreateFont("HC_Title",  {font = "Trebuchet MS",        size = 24, weight = 700})
surface.CreateFont("HC_Header", {font = "Trebuchet MS",        size = 20, weight = 700})
surface.CreateFont("HC_Label",  {font = "CloseCaption_Normal", size = 20, weight = 500})
surface.CreateFont("HC_Body",   {font = "CloseCaption_Normal", size = 18, weight = 500})
surface.CreateFont("HC_Small",  {font = "CloseCaption_Normal", size = 15, weight = 500})
surface.CreateFont("HC_Tag",    {font = "Trebuchet MS",        size = 18, weight = 700})
surface.CreateFont("HC_Num",    {font = "CloseCaption_Normal", size = 18, weight = 700})

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

local ICON_SKULL = "skull.png"
local ICON_DESC  = "server.png"
local ICON_ALL   = "star.png"
local ICON_USERS = "status/minion.png"
local ICON_ORDER = "icon16/page_white_text.png"

local _mats = {}
local function GM(path)
    if _mats[path] == nil then
        local m = Material(path, "noclamp smooth mips")
        _mats[path] = (m and not m:IsError()) and m or false
    end
    return _mats[path] or nil
end

local function GetClassIcon(class)
    if not class then return GM(ICON_ALL) end
    if class.icon and class.icon ~= "" then
        local m = GM(class.icon)
        if m then return m end
    end
    local sub = HORDE.subclasses and HORDE.subclasses[class.name]
    if sub and sub.Icon then
        local m = GM(sub.Icon)
        if m then return m end
    end
    return GM(ICON_ALL)
end

local function GetSubclassIcon(name)
    local sub = HORDE.subclasses and HORDE.subclasses[name]
    if sub and sub.Icon and sub.Icon ~= "" then
        local m = GM(sub.Icon)
        if m then return m end
    end
    return GM(ICON_ALL)
end

local function DrawIcon(mat, x, y, w, h, col)
    if not mat then return end
    local mw, mh = mat:Width(), mat:Height()
    if mw and mh and mw > 0 and mh > 0 then
        local s = math.min(w / mw, h / mh)
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
    vb:SetWide(8)
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

local function StyledEntry(ent, placeholder)
    ent:SetFont("HC_Body")
    function ent:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, CARD)
        self:DrawTextEntryText(WH, RED, WH)
        if placeholder and self:GetValue() == "" then
            draw.SimpleText(placeholder, "HC_Body", 8, h / 2, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end

local function StyledCombo(combo)
    combo:SetFont("HC_Body")
    combo:SetTextColor(WH)
    combo:SetTextInset(8, 0)
    if IsValid(combo.DropButton) then combo.DropButton.Paint = function() end end
    combo.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and CARD_H or CARD)
        DrawTri(w - 14, h / 2, 4, true, DIM)
    end
end

local function FlatButton(parent, label, x, y, w, h, col, colHover, cb)
    local b = vgui.Create("DButton", parent)
    b:SetPos(x, y)
    b:SetSize(w, h)
    b:SetText("")
    b.Paint = function(s, bw, bh)
        draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and colHover or col)
        draw.SimpleText(label, "HC_Body", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.DoClick = cb
    return b
end

local function SectionBar(parent, text, y, w)
    local b = vgui.Create("DPanel", parent)
    b:SetPos(12, y)
    b:SetSize(w - 24, 30)
    b.Paint = function(_, bw, bh)
        draw.RoundedBox(4, 0, 0, bw, bh, RED)
        draw.SimpleText(text, "HC_Header", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    return y + 30 + 10
end

local function Modal(parent, w, h, title)
    local ovl = vgui.Create("DButton", parent)
    ovl:SetText("")
    ovl:SetSize(parent:GetWide(), parent:GetTall())
    ovl:SetPos(0, 0)
    ovl:MoveToFront()
    ovl.Paint = function(_, pw, ph)
        draw.RoundedBox(8, 0, 0, pw, ph, Color(0, 0, 0, 180))
    end
    ovl.DoClick = function() end

    local box = vgui.Create("DPanel", ovl)
    box:SetSize(w, h)
    box:Center()
    box:SetMouseInputEnabled(true)
    box.Paint = function(_, bw, bh)
        draw.RoundedBox(8, 0, 0, bw, bh, RED)
        draw.RoundedBox(6, 2, 2, bw - 4, bh - 4, WIN)
        draw.RoundedBoxEx(8, 0, 0, bw, 36, RED, true, true, false, false)
        draw.SimpleText(title, "HC_Header", 14, 18, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local xb = vgui.Create("DButton", box)
    xb:SetText("")
    xb:SetSize(28, 28)
    xb:SetPos(w - 32, 4)
    xb.Paint = function(s, bw, bh)
        draw.SimpleText("r", "Marlett", bw / 2, bh / 2, s:IsHovered() and DIM or WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    xb.DoClick = function() ovl:Remove() end

    return ovl, box
end

local PANEL = {}

local ENTRY_FIELDS = {
    class = {
        id         = "name",
        display    = "display_name",
        model      = "model",
        icon       = "icon",
        base_perk  = "base_perk",
        limit      = "player_limit",
        skull      = "skull_tokens",
        order      = "order",
        desc       = "extra_description",
        perks      = "perks",
    },
    subclass = {
        id         = "PrintName",
        icon       = "Icon",
        base_perk  = "BasePerk",
        limit      = "player_limit",
        skull      = "UnlockCost",
        order      = "SortOrder",
        desc       = "Description",
        perks      = "Perks",
    },
}

local function GetStarterWeaponsForClass(name)
    local list = {}
    if not name then return list end

    for item_class, item in pairs(HORDE.items or {}) do
        local sc = item.starter_classes
        if istable(sc) and table.HasValue(sc, name) then
            list[#list + 1] = item_class
        end
    end
    table.sort(list)
    return list
end

function PANEL:_F(field)
    local map = ENTRY_FIELDS[self.selectedKind] or ENTRY_FIELDS.class
    return map[field]
end

function PANEL:_G(field)
    local key = self:_F(field)
    if not key or not self.selectedClass then return nil end
    return self.selectedClass[key]
end

function PANEL:_S(field, value)
    local key = self:_F(field)
    if not key or not self.selectedClass then return end
    self.selectedClass[key] = value
end

function PANEL:_GetEntryIcon()
    if not self.selectedClass then return GM(ICON_ALL) end
    if self.selectedKind == "subclass" then
        return GetSubclassIcon(self:_G("id"))
    end
    return GetClassIcon(self.selectedClass)
end

function PANEL:Init()
    local sw, sh = ScrW(), ScrH()
    local w = math.Clamp(math.floor(sw * 0.40), 560, 640)
    local h = math.Clamp(math.floor(sh * 0.82), 580, 720)

    self:SetSize(w, h)
    self:SetPos((sw - w) / 2, (sh - h) / 2)
    self:MakePopup()

    self.selectedClass = nil
    self.selectedKind  = nil
    self.selectedName  = nil
    self.tierCombos    = {}
    self.tierCount     = 0
    self.lastCount     = -1

    self:_BuildUI()
    self:_SelectFirstEntry()
end

function PANEL:_BuildUI()
    local w = self:GetWide()
    local M = 12

    local headerH = 46

    local clsBtn = vgui.Create("DButton", self)
    clsBtn:SetPos(M, 8)
    clsBtn:SetSize(260, headerH - 12)
    clsBtn:SetText("")
    clsBtn:SetTooltip("Click to switch class")
    clsBtn.Paint = function(s, bw, bh)
        local name = self:_G("display") or self:_G("id") or "Select Class"

        local iconSize = 28
        local cx, cy = 16, bh / 2

        local ic = self:_GetEntryIcon()
        if ic then
            DrawIcon(ic, cx - iconSize / 2, cy - iconSize / 2, iconSize, iconSize, WH)
        end

        draw.SimpleText(name, "HC_Title", cx + iconSize / 2 + 10, bh / 2, s:IsHovered() and RED_TXT or WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    clsBtn.DoClick = function() self:OpenClassPicker() end
    self.classBtn = clsBtn

    local sm = 28
    local gap = 8
    local rx = w - M - sm

    local xb = vgui.Create("DButton", self)
    xb:SetPos(rx, (headerH - sm) / 2 + 2)
    xb:SetSize(sm, sm)
    xb:SetText("")
    xb.Paint = function(s, bw, bh)
        draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and RED or BTN)
        draw.SimpleText("r", "Marlett", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    xb.DoClick = function() HORDE:ToggleClassConfig() end

    local bwSave = 110
    rx = rx - gap - bwSave
    FlatButton(self, "Save Class", rx, (headerH - sm) / 2 + 2, bwSave, sm, BTN, RED, function()
        self:_DoSave()
    end)

    local bwReset = 74
    rx = rx - gap - bwReset
    FlatButton(self, "Reset", rx, (headerH - sm) / 2 + 2, bwReset, sm, BTN, RED_DARK, function()
        self:_DoResetMenu()
    end)

    local scroll = vgui.Create("DScrollPanel", self)
    scroll:SetPos(0, headerH)
    scroll:SetSize(w, self:GetTall() - headerH - 8)
    StyleScroll(scroll)
    self.contentScroll = scroll

    local content = vgui.Create("DPanel", scroll)
    content:SetWide(w - 12)
    content.Paint = function() end
    self.content = content
end

function PANEL:_BuildRows()
    local content = self.content
    if not IsValid(content) then return end

    for _, child in ipairs(content:GetChildren()) do
        child:Remove()
    end

    self.displayNameEntry = nil
    self.modelEntry       = nil
    self.iconEntry        = nil
    self.starterBox       = nil
    self.basePerkCombo    = nil
    self.tiersHost        = nil
    self.addTierBtn       = nil

    local w       = self:GetWide()
    local M       = 12
    local isSub   = (self.selectedKind == "subclass")

    local curY = 4
    local LBX   = 16
    local EX    = 136
    local EW    = w - EX - M - 8
    local EH    = 28
    local PITCH = 34

    local function AddRowLabel(text, y)
        local lbl = vgui.Create("DLabel", content)
        lbl:SetPos(LBX, y + EH / 2 - 10)
        lbl:SetFont("HC_Label")
        lbl:SetTextColor(WH)
        lbl:SetText(text)
        lbl:SizeToContents()
        return lbl
    end

    curY = SectionBar(content, "Basic Settings", curY, w - 12)

    AddRowLabel("Internal ID:", curY)
    local idBox = vgui.Create("DPanel", content)
    idBox:SetPos(EX, curY)
    idBox:SetSize(EW, EH)
    idBox.Paint = function(_, bw, bh)
        draw.RoundedBox(6, 0, 0, bw, bh, TILE)
        draw.SimpleText(self:_G("id") or "", "HC_Body", 8, bh / 2, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    curY = curY + PITCH

    if not isSub then
        AddRowLabel("Display Name:", curY)
        self.displayNameEntry = vgui.Create("DTextEntry", content)
        self.displayNameEntry:SetPos(EX, curY)
        self.displayNameEntry:SetSize(EW, EH)
        StyledEntry(self.displayNameEntry)
        curY = curY + PITCH

        AddRowLabel("Player Model:", curY)
        local mdlEntry = vgui.Create("DTextEntry", content)
        mdlEntry:SetPos(EX, curY)
        mdlEntry:SetSize(EW, EH)
        StyledEntry(mdlEntry, "Optional")

        local mdlDrop = vgui.Create("DButton", content)
        mdlDrop:SetPos(EX + EW - 26, curY + 2)
        mdlDrop:SetSize(24, EH - 4)
        mdlDrop:SetText("")
        mdlDrop.Paint = function(s, bw, bh)
            DrawTri(bw / 2, bh / 2, 4, true, s:IsHovered() and WH or DIM)
        end
        mdlDrop.DoClick = function()
            local m = DermaMenu()
            local samples = {
                "alyx", "barney", "breen", "eli", "gman", "kleiner", "mossman",
                "odessa", "monk", "css_arctic", "css_guerilla", "css_leet", "css_phoenix"
            }
            for _, mdl in ipairs(samples) do
                m:AddOption(mdl, function() mdlEntry:SetValue(mdl) end)
            end
            m:Open()
        end
        self.modelEntry = mdlEntry
        curY = curY + PITCH
    end

    AddRowLabel("Icon Path:", curY)
    self.iconEntry = vgui.Create("DTextEntry", content)
    self.iconEntry:SetPos(EX, curY)
    self.iconEntry:SetSize(EW, EH)
    StyledEntry(self.iconEntry)
    curY = curY + PITCH

    AddRowLabel("Starter Weapons:", curY)
    local starterBox = vgui.Create("DPanel", content)
    starterBox:SetPos(EX, curY)
    starterBox:SetSize(EW, EH)
    starterBox:SetTooltip("Read-only. Set via 'Starter Class' in Item Config.")
    starterBox.Paint = function(_, bw, bh)
        draw.RoundedBox(6, 0, 0, bw, bh, TILE)
        draw.SimpleText(self.starterText or "", "HC_Body", 8, bh / 2, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    self.starterBox = starterBox
    self:RefreshStarterText()
    curY = curY + PITCH

    local pillW = 66
    local pillH = 26
    local pillGap = 8
    local totalPills = 4
    local pillsTotalW = totalPills * pillW + (totalPills - 1) * pillGap
    local pillStartX = EX + EW - pillsTotalW
    local pillY = curY

    local limitBtn = vgui.Create("DButton", content)
    limitBtn:SetPos(pillStartX, pillY)
    limitBtn:SetSize(pillW, pillH)
    limitBtn:SetText("")
    limitBtn:SetTooltip("Max players that can take this class on the server (0 = unlimited). Default: 4")
    limitBtn.Paint = function(s, bw, bh)
        draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and BTN_H or BTN)
        local ic = GM(ICON_USERS)
        if ic then
            DrawIcon(ic, 6, bh / 2 - 7, 14, 14, WH)
        else
            draw.SimpleText("P", "HC_Num", 10, bh / 2, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local limit = self:_G("limit")
        local val = tostring(limit ~= nil and limit or 4)
        draw.SimpleText(val, "HC_Num", bw - 8, bh / 2, WH, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    limitBtn.DoClick = function()
        if not self.selectedClass then return end
        local limit = self:_G("limit")
        Derma_StringRequest("Player Limit",
            "Max players that can select this class (0 = unlimited):",
            tostring(limit ~= nil and limit or 4),
            function(val)
                local n = tonumber(val)
                if n then self:_S("limit", math.max(0, math.floor(n))) end
            end)
    end
    self.limitBtn = limitBtn

    local skullBtn = vgui.Create("DButton", content)
    skullBtn:SetPos(pillStartX + pillW + pillGap, pillY)
    skullBtn:SetSize(pillW, pillH)
    skullBtn:SetText("")
    skullBtn:SetTooltip("Skull Tokens required to unlock (click to edit)")
    skullBtn.Paint = function(s, bw, bh)
        draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and BTN_H or BTN)
        local ic = GM(ICON_SKULL)
        DrawIcon(ic, 8, bh / 2 - 8, 16, 16, WH)
        local val = tostring(self:_G("skull") or 0)
        draw.SimpleText(val, "HC_Num", bw - 10, bh / 2, WH, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    skullBtn.DoClick = function()
        if not self.selectedClass then return end
        Derma_StringRequest("Skull Tokens", "Enter skull tokens required to unlock:",
            tostring(self:_G("skull") or 0), function(val)
                local n = tonumber(val)
                if n then self:_S("skull", math.max(0, n)) end
            end)
    end
    self.skullBtn = skullBtn

    local descBtn = vgui.Create("DButton", content)
    descBtn:SetPos(pillStartX + 2 * (pillW + pillGap), pillY)
    descBtn:SetSize(pillW, pillH)
    descBtn:SetText("")
    descBtn:SetTooltip("Edit class description")
    descBtn.Paint = function(s, bw, bh)
        draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and BTN_H or BTN)
        local ic = GM(ICON_DESC)
        DrawIcon(ic, 8, bh / 2 - 8, 16, 16, WH)
        local desc = self:_G("desc")
        local has = desc and desc ~= ""
        draw.SimpleText("D", "HC_Num", bw - 10, bh / 2, has and WH or DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    descBtn.DoClick = function() self:OpenDescEditor() end
    self.descBtn = descBtn

    local orderBtn = vgui.Create("DButton", content)
    orderBtn:SetPos(pillStartX + 3 * (pillW + pillGap), pillY)
    orderBtn:SetSize(pillW, pillH)
    orderBtn:SetText("")
    orderBtn:SetTooltip("Sort order of the class in menus (click to edit)")
    orderBtn.Paint = function(s, bw, bh)
        draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and BTN_H or BTN)
        local ic = GM(ICON_ORDER)
        if ic then
            DrawIcon(ic, 6, bh / 2 - 7, 14, 14, WH)
        else
            draw.SimpleText("#", "HC_Num", 10, bh / 2, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local val = tostring(self:_G("order") or 0)
        draw.SimpleText(val, "HC_Num", bw - 8, bh / 2, WH, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
    orderBtn.DoClick = function()
        if not self.selectedClass then return end
        Derma_StringRequest("Class Order", "Enter sort order index:",
            tostring(self:_G("order") or 0), function(val)
                local n = tonumber(val)
                if n then self:_S("order", math.floor(n)) end
            end)
    end
    self.orderBtn = orderBtn

    curY = pillY + pillH + 12

    curY = SectionBar(content, "Perks", curY, w - 12)

    AddRowLabel("Base Perk:", curY)
    self.basePerkCombo = vgui.Create("DComboBox", content)
    self.basePerkCombo:SetPos(EX, curY)
    self.basePerkCombo:SetSize(EW, EH)
    StyledCombo(self.basePerkCombo)
    curY = curY + PITCH + 2

    self.tiersHost = vgui.Create("DPanel", content)
    self.tiersHost:SetPos(0, curY)
    self.tiersHost:SetWide(w - 12)
    self.tiersHost.Paint = function() end
    self.tiersHostY = curY

    self.addTierBtn = vgui.Create("DButton", content)
    self.addTierBtn:SetSize(EW, 30)
    self.addTierBtn:SetText("")
    self.addTierBtn:SetTooltip("Add another perk tier")
    self.addTierBtn.Paint = function(s, bw, bh)
        draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and BTN_H or BTN)
        draw.SimpleText("Add", "HC_Body", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    self.addTierBtn.DoClick = function()
        self:_AddTierRow()
        self:_LayoutTiers()
    end

    self.tierCombos = {}
    self.tierCount = 0
    for i = 1, 4 do
        self:_AddTierRow()
    end
    self:_LayoutTiers()

    self:_PopulatePerks()
end

function PANEL:SelectEntry(name)
    local cls = HORDE.classes and HORDE.classes[name]
    local sub = HORDE.subclasses and HORDE.subclasses[name]

    if cls then
        self.selectedKind  = "class"
        self.selectedClass = cls
    elseif sub then
        self.selectedKind  = "subclass"
        self.selectedClass = sub
    else
        return
    end

    self.selectedName = name
    self:_BuildRows()
    self:_FillRows()
end

function PANEL:_SelectFirstEntry()
    local names = table.GetKeys(HORDE.subclasses or {})
    if #names == 0 then return end
    table.sort(names)

    self:SelectEntry(table.HasValue(names, "Survivor") and "Survivor" or names[1])
end

function PANEL:_AddTierRow()
    local content = self.content
    local w = self:GetWide()
    local M = 12
    local EX = 136
    local EW = w - EX - M - 8
    local EH = 28
    local tagW = 16
    local choiceGap = 16
    local removeW = 24
    local choiceW = math.floor((EW - (tagW * 2 + 10 * 2 + choiceGap + removeW + 8)) / 2)

    local idx = #self.tierCombos + 1
    local row = vgui.Create("DPanel", self.tiersHost)
    row:SetSize(w - 12, EH + 6)
    row.Paint = function() end

    local LBX = 16
    local tierLbl = vgui.Create("DLabel", row)
    tierLbl:SetPos(LBX + 44, EH / 2 - 10)
    tierLbl:SetFont("HC_Label")
    tierLbl:SetTextColor(WH)
    tierLbl:SetText("Tier " .. idx .. ":")
    tierLbl:SizeToContents()
    row.tierLbl = tierLbl

    local tx = EX

    local lblL = vgui.Create("DLabel", row)
    lblL:SetPos(tx, EH / 2 - 10)
    lblL:SetFont("HC_Tag")
    lblL:SetTextColor(RED_TXT)
    lblL:SetText("L")
    lblL:SizeToContents()
    tx = tx + tagW + 8

    local comboL = vgui.Create("DComboBox", row)
    comboL:SetPos(tx, 0)
    comboL:SetSize(choiceW, EH)
    StyledCombo(comboL)
    tx = tx + choiceW + choiceGap

    local lblR = vgui.Create("DLabel", row)
    lblR:SetPos(tx, EH / 2 - 10)
    lblR:SetFont("HC_Tag")
    lblR:SetTextColor(RED_TXT)
    lblR:SetText("R")
    lblR:SizeToContents()
    tx = tx + tagW + 8

    local comboR = vgui.Create("DComboBox", row)
    comboR:SetPos(tx, 0)
    comboR:SetSize(choiceW, EH)
    StyledCombo(comboR)
    tx = tx + choiceW + 8

    local removeBtn = vgui.Create("DButton", row)
    removeBtn:SetPos(tx, 2)
    removeBtn:SetSize(removeW, EH - 4)
    removeBtn:SetText("")
    removeBtn:SetTooltip("Remove this tier")
    removeBtn.Paint = function(s, bw, bh)
        draw.SimpleText("X", "HC_Tag", bw / 2, bh / 2, s:IsHovered() and RED_TXT or DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    local myIdx = idx
    removeBtn.DoClick = function()
        self:_RemoveTierRow(myIdx)
    end
    row.removeBtn = removeBtn

    local choices = {""}
    for pName, _ in SortedPairs(HORDE.perks or {}) do
        table.insert(choices, pName)
    end
    for _, c in ipairs(choices) do
        comboL:AddChoice(c)
        comboR:AddChoice(c)
    end

    table.insert(self.tierCombos, {left = comboL, right = comboR, row = row, removeBtn = removeBtn})
    self.tierCount = #self.tierCombos
end

function PANEL:_RemoveTierRow(idx)
    if #self.tierCombos <= 1 then
        notification.AddLegacy("At least one perk tier is required.", NOTIFY_ERROR, 2)
        return
    end
    if idx < 1 or idx > #self.tierCombos then return end

    local ed = self.tierCombos[idx]
    if IsValid(ed.row) then ed.row:Remove() end
    table.remove(self.tierCombos, idx)

    for i, e in ipairs(self.tierCombos) do
        if IsValid(e.row) and IsValid(e.row.tierLbl) then
            e.row.tierLbl:SetText("Tier " .. i .. ":")
            e.row.tierLbl:SizeToContents()
        end
        if IsValid(e.removeBtn) then
            e.removeBtn.DoClick = function()
                self:_RemoveTierRow(i)
            end
        end
    end
    self.tierCount = #self.tierCombos
    self:_LayoutTiers()
end

function PANEL:_LayoutTiers()
    local PITCH = 34
    local y = 0
    for i, ed in ipairs(self.tierCombos) do
        if IsValid(ed.row) then
            ed.row:SetPos(0, y)
            y = y + PITCH
        end
    end
    self.tiersHost:SetTall(math.max(y, 10))

    local addY = self.tiersHostY + y + 4
    local EX = 136
    local w = self:GetWide()
    local M = 12
    local EW = w - EX - M - 8
    if IsValid(self.addTierBtn) then
        self.addTierBtn:SetPos(EX, addY)
        self.addTierBtn:SetSize(EW, 30)
    end

    if IsValid(self.content) then
        self.content:SetTall(addY + 40)
    end
end

function PANEL:_PopulatePerks()
    local choices = {""}
    for pName, _ in SortedPairs(HORDE.perks or {}) do
        table.insert(choices, pName)
    end

    if IsValid(self.basePerkCombo) then
        local cur = self.basePerkCombo:GetValue()
        self.basePerkCombo:Clear()
        for _, c in ipairs(choices) do self.basePerkCombo:AddChoice(c) end
        if cur and cur ~= "" then self.basePerkCombo:SetValue(cur) end
    end

    for i, ed in ipairs(self.tierCombos) do
        if ed then
            local cl, cr = ed.left:GetValue(), ed.right:GetValue()
            ed.left:Clear()
            ed.right:Clear()
            for _, c in ipairs(choices) do
                ed.left:AddChoice(c)
                ed.right:AddChoice(c)
            end
            if cl then ed.left:SetValue(cl) end
            if cr then ed.right:SetValue(cr) end
        end
    end
end

function PANEL:_FillRows()
    if not self.selectedClass then return end

    if IsValid(self.displayNameEntry) then
        self.displayNameEntry:SetValue(self:_G("display") or "")
    end
    if IsValid(self.modelEntry) then
        self.modelEntry:SetValue(self:_G("model") or "")
    end
    if IsValid(self.iconEntry) then
        self.iconEntry:SetValue(self:_G("icon") or "")
    end
    if IsValid(self.basePerkCombo) then
        self.basePerkCombo:SetValue(self:_G("base_perk") or "")
    end

    self:RefreshStarterText()

    local perks = self:_G("perks") or {}
    local levels = table.GetKeys(perks)
    table.sort(levels, function(a, b) return tonumber(a) < tonumber(b) end)
    local needed = math.max(#levels, 1)

    while #self.tierCombos > needed do
        local ed = table.remove(self.tierCombos)
        if IsValid(ed.row) then ed.row:Remove() end
    end
    while #self.tierCombos < needed do
        self:_AddTierRow()
    end
    self.tierCount = #self.tierCombos

    for i, e in ipairs(self.tierCombos) do
        if IsValid(e.row) and IsValid(e.row.tierLbl) then
            e.row.tierLbl:SetText("Tier " .. i .. ":")
            e.row.tierLbl:SizeToContents()
        end
        if IsValid(e.removeBtn) then
            e.removeBtn.DoClick = function()
                self:_RemoveTierRow(i)
            end
        end
    end

    for i, level in ipairs(levels) do
        local ed = self.tierCombos[i]
        if ed then
            local pTier = perks[level]
            if pTier and pTier.choices then
                ed.left:SetValue(pTier.choices[1] or "")
                ed.right:SetValue(pTier.choices[2] or "")
            else
                ed.left:SetValue("")
                ed.right:SetValue("")
            end
        end
    end
    for i = #levels + 1, #self.tierCombos do
        local ed = self.tierCombos[i]
        if ed then
            ed.left:SetValue("")
            ed.right:SetValue("")
        end
    end

    self:_LayoutTiers()
end

function PANEL:_CollectTiers()
    local old  = self:_G("perks") or {}
    local perks = {}

    for i, ed in ipairs(self.tierCombos) do
        local c1 = ed and string.Trim(ed.left:GetValue() or "") or ""
        local c2 = ed and string.Trim(ed.right:GetValue() or "") or ""
        local prev = old[i]
        perks[i] = {
            title   = (prev and prev.title) or ("Tier " .. i),
            choices = { c1, c2 },
        }
    end
    return perks
end

function PANEL:OpenClassPicker()
    local ovl, box = Modal(self, math.min(700, self:GetWide() - 40),
        math.min(520, self:GetTall() - 40), "Select class")

    local FOOTER_H = 46

    local scroll = vgui.Create("DScrollPanel", box)
    scroll:SetPos(16, 52)
    scroll:SetSize(box:GetWide() - 32, box:GetTall() - 52 - FOOTER_H)
    StyleScroll(scroll)

    local CW, CH = 100, 118
    local GAP    = 9
    local avail  = scroll:GetWide() - 14
    local cols   = math.max(1, math.floor((avail + GAP) / (CW + GAP)))

    local canvas = vgui.Create("DPanel", scroll)
    canvas.Paint = function() end

    local names = table.GetKeys(HORDE.subclasses or {})
    table.sort(names)

    canvas:SetSize(avail, math.max(1, math.ceil(#names / cols)) * (CH + GAP))

    for i, nm in ipairs(names) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        local b = vgui.Create("DButton", canvas)
        b:SetPos(col * (CW + GAP), row * (CH + GAP))
        b:SetSize(CW, CH)
        b:SetText("")

        local cls = HORDE.classes and HORDE.classes[nm]
        local ic = cls and GetClassIcon(cls) or GetSubclassIcon(nm)
        if cls and cls.base_perk and cls.base_perk ~= "" then
            b:SetTooltip(cls.base_perk)
        end

        b.Paint = function(s, w, h)
            local cur = (self.selectedName == nm)
            draw.RoundedBox(6, 0, 0, w, h, cur and RED or (s:IsHovered() and CARD_H or CARD))
            DrawIcon(ic, 14, 12, w - 28, w - 28, WH)
            draw.SimpleText(nm, "HC_Small", w / 2, h - 16, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        b.DoClick = function()
            self:SelectEntry(nm)
            ovl:Remove()
        end

        b.DoRightClick = function()
            if not (HORDE.classes and HORDE.classes[nm]) then return end

            local m = DermaMenu()
            local del = m:AddOption("Delete Class", function()
                Derma_Query("Delete class '" .. nm .. "'?", "Confirm",
                    "Delete", function()
                        HORDE.classes[nm] = nil
                        if self.selectedKind == "class" and self.selectedName == nm then
                            self.selectedClass = nil
                            self.selectedKind  = nil
                            self.selectedName  = nil
                        end
                        net.Start("Horde_SetClassData")
                            net.WriteTable(HORDE.classes)
                        net.SendToServer()
                        if IsValid(ovl) then ovl:Remove() end
                        self:_SelectFirstEntry()
                    end,
                    "Cancel", function() end)
            end)
            del:SetIcon("icon16/delete.png")
            m:Open()
        end
    end

    FlatButton(box, "+ Create New Class", 16, box:GetTall() - FOOTER_H + 8,
        box:GetWide() - 32, 30, BTN, BTN_H, function()
        Derma_StringRequest("New Class", "Enter new internal class ID (e.g. Medic):", "", function(id)
            id = string.Trim(id or "")
            if id == "" then return end
            if HORDE.classes[id] then
                notification.AddLegacy("Class with ID '" .. id .. "' already exists!", NOTIFY_ERROR, 3)
                return
            end
            HORDE.classes[id] = {
                name = id,
                display_name = id,
                perks = {},
                player_limit = 4,
                skull_tokens = 0,
                order = table.Count(HORDE.classes),
            }
            self:SelectEntry(id)
            ovl:Remove()
        end)
    end)
end

function PANEL:OpenDescEditor()
    if not self.selectedClass then return end
    local title = (self.selectedKind == "subclass") and "Edit Subclass Description" or "Edit Class Description"
    local ovl, box = Modal(self, 480, 320, title)

    local ta = vgui.Create("DTextEntry", box)
    ta:SetPos(16, 52)
    ta:SetSize(box:GetWide() - 32, 200)
    ta:SetMultiline(true)
    ta:SetFont("HC_Body")
    ta:SetValue(self:_G("desc") or "")
    ta.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, CARD)
        s:DrawTextEntryText(WH, RED, WH)
    end

    local bw = (box:GetWide() - 32 - 10) / 2
    local by = box:GetTall() - 44

    FlatButton(box, "Save", 16, by, bw, 32, RED, RED_H, function()
        self:_S("desc", string.Trim(ta:GetValue() or ""))
        ovl:Remove()
    end)

    FlatButton(box, "Cancel", 16 + bw + 10, by, bw, 32, BTN, BTN_H, function()
        ovl:Remove()
    end)
end

function PANEL:RefreshStarterText()
    self.starterText = table.concat(GetStarterWeaponsForClass(self:_G("id")), ", ")
end

function PANEL:_DoSave()
    if GetConVarNumber("horde_default_class_config") == 1 then
        notification.AddLegacy("Default config is active! Changes cannot be saved.", NOTIFY_ERROR, 3)
        return
    end

    if not self.selectedClass then
        notification.AddLegacy("Select a class to save!", NOTIFY_ERROR, 3)
        return
    end

    local name = self:_G("id")
    if not name then
        notification.AddLegacy("Invalid class selected!", NOTIFY_ERROR, 3)
        return
    end

    if self.selectedKind == "subclass" then
        local sub = HORDE.subclasses[name]
        if not sub then
            notification.AddLegacy("Invalid subclass selected!", NOTIFY_ERROR, 3)
            return
        end

        local ico = string.Trim(self.iconEntry:GetValue() or "")
        sub.Icon = (ico ~= "") and ico or nil

        local bp = string.Trim(self.basePerkCombo:GetValue() or "")
        sub.BasePerk = (bp ~= "") and bp or nil

        sub.Perks = self:_CollectTiers()

        HORDE.subclass_overrides[name] = HORDE:BuildSubclassOverride(sub)

        net.Start("Horde_SetSubclassData")
            net.WriteTable(HORDE.subclass_overrides)
        net.SendToServer()

        HORDE:PlayNotification("Subclass '" .. name .. "' saved.")
        return
    end

    if not HORDE.classes[name] then
        notification.AddLegacy("Invalid class selected!", NOTIFY_ERROR, 3)
        return
    end

    local cls = HORDE.classes[name]
    cls.display_name = string.Trim(self.displayNameEntry:GetValue() or "")

    local mdl = string.Trim(self.modelEntry:GetValue() or "")
    cls.model = (mdl ~= "" and mdl ~= "Optional") and mdl or nil

    local ico = string.Trim(self.iconEntry:GetValue() or "")
    cls.icon = (ico ~= "") and ico or nil

    local bp = string.Trim(self.basePerkCombo:GetValue() or "")
    cls.base_perk = (bp ~= "") and bp or nil

    if cls.player_limit == nil then cls.player_limit = 4 end
    cls.skull_tokens = cls.skull_tokens or 0
    cls.order = cls.order or 0
    cls.extra_description = cls.extra_description or ""

    cls.perks = self:_CollectTiers()

    net.Start("Horde_SetClassData")
        net.WriteTable(HORDE.classes)
    net.SendToServer()

    HORDE:PlayNotification("Class '" .. (cls.display_name ~= "" and cls.display_name or cls.name) .. "' saved.")
end

function PANEL:_DoResetMenu()
    local m = DermaMenu()

    m:AddOption("Reset This " .. (self.selectedKind == "subclass" and "Subclass" or "Class"), function()
        if not self.selectedClass then return end
        local name = self:_G("id")
        if not name then return end

        Derma_Query("Reset '" .. name .. "' to default settings?", "Reset",
            "Yes, Reset", function()
                if self.selectedKind == "subclass" then
                    HORDE:RestoreSubclassDefaults(name)
                    net.Start("Horde_SetSubclassData")
                        net.WriteTable(HORDE.subclass_overrides)
                    net.SendToServer()
                    self:SelectEntry(name)
                    HORDE:PlayNotification("Subclass reset to default.")
                else
                    HORDE:GetDefaultClassesData()
                    if HORDE.classes[name] then
                        self:SelectEntry(name)
                        net.Start("Horde_SetClassData")
                            net.WriteTable(HORDE.classes)
                        net.SendToServer()
                        HORDE:PlayNotification("Class reset to default.")
                    end
                end
            end,
            "Cancel", function() end)
    end)

    m:AddSpacer()

    local resetAll = m:AddOption("Reset All Classes to Default", function()
        Derma_Query("Reset ALL classes to default settings?", "Reset All Classes",
            "Reset Everything", function()
                HORDE.classes = {}
                HORDE:GetDefaultClassesData()
                net.Start("Horde_SetClassData")
                    net.WriteTable(HORDE.classes)
                net.SendToServer()
                HORDE:PlayNotification("All classes reset to default.")
                if self.selectedName and HORDE.classes[self.selectedName] then
                    self:SelectEntry(self.selectedName)
                end
            end,
            "Cancel", function() end)
    end)
    resetAll:SetIcon("icon16/arrow_refresh.png")

    m:AddOption("Reset All Subclasses to Default", function()
        Derma_Query("Reset ALL subclass configs to default settings?", "Reset All Subclasses",
            "Reset Everything", function()
                HORDE:RestoreAllSubclassDefaults()
                net.Start("Horde_SetSubclassData")
                    net.WriteTable(HORDE.subclass_overrides)
                net.SendToServer()
                HORDE:PlayNotification("All subclasses reset to default.")
                if self.selectedName then
                    self:SelectEntry(self.selectedName)
                end
            end,
            "Cancel", function() end)
    end)

    m:Open()
end

function PANEL:Think()
    local cnt = table.Count(HORDE.subclasses or {})
    if cnt ~= self.lastCount then
        self.lastCount = cnt
        self:_PopulatePerks()
        if not self.selectedClass then
            self:_SelectFirstEntry()
        end
    end

    self.starterRefreshT = (self.starterRefreshT or 0) + FrameTime()
    if self.starterRefreshT >= 0.25 then
        self.starterRefreshT = 0
        self:RefreshStarterText()
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, RED)
    draw.RoundedBox(6, 2, 2, w - 4, h - 4, WIN)
end

function HORDE:RefreshClassConfigUI()
    local gui = HORDE.ClassConfigGUI
    if not IsValid(gui) or not gui.SelectEntry then return end
    if gui.selectedName then gui:SelectEntry(gui.selectedName) end
end

vgui.Register("HordeClassConfig", PANEL, "EditablePanel")

if IsValid(HORDE.ClassConfigGUI) then
    HORDE.ClassConfigGUI:Remove()
    HORDE.ClassConfigGUI = nil
    gui.EnableScreenClicker(false)
end

MsgC(Color(220, 30, 56), "[HORDE] ", color_white, "Class Config redesign v5 loaded (all subclasses + dynamic tiers)\n")
