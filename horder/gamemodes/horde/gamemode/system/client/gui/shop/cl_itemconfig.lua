if not CLIENT then return end

surface.CreateFont("HC_Class", {font = "Trebuchet MS",        size = 30, weight = 700})
surface.CreateFont("HC_Label", {font = "CloseCaption_Normal", size = 22, weight = 500})
surface.CreateFont("HC_Body",  {font = "CloseCaption_Normal", size = 18, weight = 500})
surface.CreateFont("HC_Small", {font = "CloseCaption_Normal", size = 15, weight = 500})
surface.CreateFont("HC_Num",   {font = "CloseCaption_Normal", size = 20, weight = 700})

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

local M        = 8
local HEADER_H = 64
local BAR_H    = 40
local BAR_GAP  = 22
local GAP      = 9

local _mats = {}
local function GM(path)
    if not _mats[path] then
        _mats[path] = Material(path, "mips smooth")
    end
    return _mats[path]
end

local MAT_FALLBACK = nil
local function GetFallback()
    if not MAT_FALLBACK then
        local m = GM("items/hl2/weapon_crowbar.png")
        MAT_FALLBACK = (m and not m:IsError()) and m or GM("vgui/hud/item")
    end
    return MAT_FALLBACK
end

local function GetItemIcon(item)
    if not item then return GetFallback() end
    if item.shop_icon and item.shop_icon ~= "" then
        local m = GM(item.shop_icon)
        if m and not m:IsError() then return m end
    end
    if item.entity_properties and item.entity_properties.type == HORDE.ENTITY_PROPERTY_GADGET then
        local g = HORDE.gadgets and HORDE.gadgets[item.class]
        if g and g.Icon then
            local m = GM(g.Icon)
            if m and not m:IsError() then return m, true end
        end
    end
    local m = GM("arccw/weaponicons/" .. (item.class or ""))
    if m and not m:IsError() then return m end
    m = GM("entities/" .. (item.class or "") .. ".png")
    if m and not m:IsError() then return m end
    m = GM("items/hl2/" .. (item.class or "") .. ".png")
    if m and not m:IsError() then return m end
    return GetFallback()
end

local function GetSubIcon(name)
    local sub = HORDE.subclasses and HORDE.subclasses[name]
    if sub and sub.Icon then
        local m = GM(sub.Icon)
        if m and not m:IsError() then return m end
    end
    return GetFallback()
end

local ICON_SKULL   = "skull.png"
local ICON_WEIGHT  = "weight.png"
local ICON_PRICE   = "status/canbuy_white.png"
local ICON_DESC    = "server.png"
local ICON_ALL     = "star.png"
local TYPE_ICONS = {
    weapon = "damagetype/ballistic.png",
    give   = "ammo.png",
    drop   = "status/grenade_ui.png",
    gadget = "status/health.png",
}

local function DrawIcon(mat, x, y, w, h, col)
    if not mat or mat:IsError() then return end
    local mw, mh = mat:Width(), mat:Height()
    if mw and mh and mw > 0 and mh > 0 then
        local s  = math.min(w / mw, h / mh)
        local dw = mw * s
        local dh = mh * s
        x = x + (w - dw) / 2
        y = y + (h - dh) / 2
        w, h = dw, dh
    end
    surface.SetMaterial(mat)
    surface.SetDrawColor(col or WH)
    surface.DrawTexturedRect(math.floor(x), math.floor(y), math.ceil(w), math.ceil(h))
end

local GADGET_ICON_SCALE = 2

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

local function DrawScrollBar(scroll)
    local vb = scroll:GetVBar()
    vb:SetWide(10)
    vb:SetHideButtons(true)
    vb.Paint = function(_, w, h)
        draw.RoundedBox(5, 0, 0, w, h, TRACK)
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
        draw.RoundedBox(6, 0, 0, w, h, BTN)
        self:DrawTextEntryText(WH, RED, WH)
        if placeholder and self:GetValue() == "" then
            draw.SimpleText(placeholder, "HC_Body", 5, h / 2, DIM,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end

local function StyledCombo(combo)
    combo:SetFont("HC_Body")
    combo:SetTextColor(WH)
    combo:SetTextInset(10, 0)
    if IsValid(combo.DropButton) then combo.DropButton.Paint = function() end end
    combo.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and BTN_H or BTN)
        DrawTri(w - 16, h / 2, 5, true, DIM)
    end
end

local function SectionBar(parent, text, y, w)
    local b = vgui.Create("DPanel", parent)
    b:SetPos(0, y)
    b:SetSize(w, BAR_H)
    b.Paint = function(_, bw, bh)
        draw.RoundedBox(4, 0, 0, bw, bh, RED)
        draw.SimpleText(text, "Trebuchet24", bw / 2, bh / 2, WH,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    return y + BAR_H + BAR_GAP
end

local function SpaceAround(total, n, itemW)
    return (total - n * itemW) / (n + 1)
end

local function Modal(parent, w, h, title)
    local ovl = vgui.Create("DButton", parent)
    ovl:SetText("")
    ovl:SetSize(parent:GetWide(), parent:GetTall())
    ovl:SetPos(0, 0)
    ovl:MoveToFront()
    ovl.Paint = function(_, pw, ph)
        draw.RoundedBox(8, 0, 0, pw, ph, Color(0, 0, 0, 170))
    end
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
        draw.SimpleText("r", "Marlett", bw / 2, bh / 2, s:IsHovered() and DIM or WH,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    xb.DoClick = function() ovl:Remove() end

    return ovl, box
end

local function FlatButton(parent, label, x, y, w, h, col, colHover, cb)
    local b = vgui.Create("DButton", parent)
    b:SetPos(x, y)
    b:SetSize(w, h)
    b:SetText("")
    b.Paint = function(s, bw, bh)
        draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and colHover or col)
        draw.SimpleText(label, "HC_Body", bw / 2, bh / 2, WH,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.DoClick = cb
    return b
end

local _tipData = nil
local TIP_MAX_W = 340

local function WrapText(text, font, maxW)
    surface.SetFont(font)
    local out = {}
    for para in string.gmatch(text .. "\n", "(.-)\n") do
        local line = ""
        for word in string.gmatch(para, "%S+") do
            local try = (line == "") and word or (line .. " " .. word)
            if line ~= "" and surface.GetTextSize(try) > maxW then
                out[#out + 1] = line
                line = word
            else
                line = try
            end
        end
        out[#out + 1] = line
    end
    return out
end

hook.Add("PostRenderVGUI", "HordeItemCfgV2_Tip", function()
    if not _tipData then return end
    if not (IsValid(HORDE.ItemConfigGUI) and HORDE.ItemConfigGUI:IsVisible()) then return end

    local mx, my = gui.MouseX(), gui.MouseY()
    local lines = {}

    if _tipData.item then
        local it = _tipData.item
        local qcol = (HORDE.GetQualityColor and it.quality) and HORDE:GetQualityColor(it.quality) or RED_TXT
        lines[#lines + 1] = {it.name or "?", "HC_Label", qcol}
        lines[#lines + 1] = {"Class: " .. (it.class or ""),       "HC_Small", WH}
        lines[#lines + 1] = {"Category: " .. (it.category or ""), "HC_Small", WH}
        if it.quality then
            lines[#lines + 1] = {"Quality: " .. tostring(it.quality), "HC_Small", qcol}
        end
        lines[#lines + 1] = {"$" .. tostring(it.price or 0) ..
                             "   Skulls: " .. tostring(it.skull_tokens or 0) ..
                             "   Weight: " .. tostring(it.weight or 0), "HC_Small", WH}
        if it.description and it.description ~= "" then
            for _, l in ipairs(WrapText(it.description, "HC_Small", TIP_MAX_W)) do
                lines[#lines + 1] = {l, "HC_Small", DIM}
            end
        end
    elseif _tipData.cls then
        lines[1] = {_tipData.cls, "HC_Body", WH}
    else
        return
    end

    local maxW, totalH = 0, 0
    for _, l in ipairs(lines) do
        surface.SetFont(l[2])
        local tw, th = surface.GetTextSize(l[1])
        l.h = th
        if tw > maxW then maxW = tw end
        totalH = totalH + th + 2
    end

    local pw, ph = maxW + 28, totalH + 18
    local tx = math.min(mx + 16, ScrW() - pw - 4)
    local ty = math.min(my + 16, ScrH() - ph - 4)

    draw.RoundedBox(6, tx, ty, pw, ph, Color(24, 25, 28, 255))
    if _tipData.item then
        draw.RoundedBoxEx(6, tx, ty, pw, 3, RED, true, true, false, false)
    end
    local cy = ty + 10
    for _, l in ipairs(lines) do
        draw.SimpleText(l[1], l[2], tx + 14, cy, l[3])
        cy = cy + l.h + 2
    end
end)

local PANEL = {}

function PANEL:Init()
    local sw, sh = ScrW(), ScrH()
    local w, h
    if sw < 1400 then
        w, h = sw, sh
    else
        w = math.max(math.floor(sw * 0.64), math.min(900, sw))
        h = math.floor(math.min(sh * 0.72, w / 1.76))
    end
    self:SetSize(w, h)
    self:SetPos((sw - w) / 2, (sh - h) / 2)
    self:MakePopup()

    self.LX = M
    self.LW = math.floor(w * 0.52) - M - 12
    self.RX = self.LX + self.LW + 36
    self.RW = w - M - self.RX

    self.curClass     = "ALL"
    self.selKey       = nil
    self.collapsed    = {}
    self.search       = ""
    self.debounceT    = 0
    self.e            = self:_Empty()
    self.itemSelected = false

    self.wlBtns       = {}
    self.levelEditors = {}
    self.dmgBtns      = {}
    self.infBtns      = {}
    self.tipItem      = nil
    self.tipCls       = nil

    self:_BuildHeader()
    self:_BuildLeft()
    self:_BuildRight()
    self:Refresh()
end

function PANEL:_Empty()
    return {
        entity_type    = "weapon",
        class          = "",
        category       = (HORDE.categories and HORDE.categories[1]) or "Melee",
        name           = "",
        price          = 0,
        quality        = "Common",
        quality_manual = false,
        price_manual   = false,
        skull_tokens   = 0,
        weight         = 0,
        description    = "",
        whitelist      = nil,
        ammo_price     = HORDE.default_ammo_price or 0,
        sec_ammo_price = -1,
        shop_icon      = "",
        levels         = {},
        dmgtype        = {},
        infusions      = {},
        starter_classes = {},
        drop_x = 50, drop_z = 15, drop_yaw = 0, drop_limit = 5,
        is_arccw = false, arccw_type = "",
    }
end

function PANEL:_BuildHeader()
    local LX, LW, RX, RW = self.LX, self.LW, self.RX, self.RW

    local classBtn = vgui.Create("DButton", self)
    classBtn:SetPos(LX + 4, 6)
    classBtn:SetSize(math.floor(LW * 0.52) - 10, HEADER_H - 12)
    classBtn:SetText("")
    classBtn:SetTooltip("Filter by class")
    classBtn.Paint = function(s, w, h)
        local isAll = (self.curClass == "ALL")
        local ic = isAll and GM(ICON_ALL) or GetSubIcon(self.curClass)
        DrawIcon(ic, 4, (h - 44) / 2, 44, 44, WH)
        draw.SimpleText(isAll and "Show All" or self.curClass, "HC_Class", 62, h / 2,
            s:IsHovered() and RED_TXT or WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    classBtn.DoClick = function() self:OpenClassPicker() end

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
    local avail = RW - 4 - 5 * GAPH - SM
    local bw    = math.min(150, math.floor(avail / 5))
    local total = 5 * bw + SM + 5 * GAPH
    local x     = RX + RW - 4 - total

    FlatButton(self, "Scan Weapons", x, by, bw, 36, BTN, RED,     function() self:OpenScanWeapons() end)
    x = x + bw + GAPH
    FlatButton(self, "Recalc All",   x, by, bw, 36, BTN, BTN_H,   function() self:_RecalcAllMenu() end)
    x = x + bw + GAPH
    FlatButton(self, "Delete All",   x, by, bw, 36, BTN, RED_DARK, function() self:_DoDeleteAll() end)
    x = x + bw + GAPH
    FlatButton(self, "Add Default",  x, by, bw, 36, BTN, BTN_H,   function() self:_DoAddDefault() end)
    x = x + bw + GAPH
    FlatButton(self, "Save Item",    x, by, bw, 36, BTN, RED,     function() self:_DoSave() end)
    x = x + bw + GAPH

    local xb = vgui.Create("DButton", self)
    xb:SetPos(x, (HEADER_H - SM) / 2)
    xb:SetSize(SM, SM)
    xb:SetText("")
    xb.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and RED or BTN)
        draw.SimpleText("r", "Marlett", w / 2, h / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    xb.DoClick = function() HORDE:ToggleItemConfig() end
end

function PANEL:_BuildLeft()
    local scroll = vgui.Create("DScrollPanel", self)
    scroll:SetPos(self.LX, HEADER_H)
    scroll:SetSize(self.LW + 22, self:GetTall() - HEADER_H - M)
    DrawScrollBar(scroll)
    self.leftScroll = scroll

    local list = vgui.Create("DPanel", scroll)
    list:SetSize(self.LW, 100)
    list.Paint = function() end
    self.listPanel = list
end

function PANEL:_Pass(item)
    if self.curClass ~= "ALL" and item.whitelist ~= nil and not item.whitelist[self.curClass] then
        return false
    end
    if self.search ~= "" then
        local n  = string.lower(item.name     or "")
        local cl = string.lower(item.class    or "")
        local ca = string.lower(item.category or "")
        local wt = tostring(item.weight       or 0)
        local ql = string.lower(item.quality  or "")
        if not (string.find(n,  self.search, 1, true) or
                string.find(cl, self.search, 1, true) or
                string.find(ca, self.search, 1, true) or
                string.find(wt, self.search, 1, true) or
                string.find(ql, self.search, 1, true)) then
            return false
        end
    end
    return true
end

function PANEL:Refresh()
    if not IsValid(self.listPanel) then return end
    local lp = self.listPanel
    lp:Clear()

    local lw = lp:GetWide()

    local gridX  = 16
    local gridW  = lw - gridX - 12
    local COLS   = math.Clamp(math.floor((gridW + GAP) / (56 + GAP)), 3, 8)
    local ISIZ   = math.floor((gridW - (COLS - 1) * GAP) / COLS)

    local groups, orderset, order = {}, {}, {}
    for _, cat in ipairs(HORDE.categories or {}) do
        if not orderset[cat] then
            orderset[cat] = true
            table.insert(order, cat)
        end
    end

    for k, item in pairs(HORDE.items or {}) do
        if self:_Pass(item) then
            local cat = item.category or "Other"
            if not groups[cat] then
                groups[cat] = {}
                if not orderset[cat] then
                    orderset[cat] = true
                    table.insert(order, cat)
                end
            end
            table.insert(groups[cat], {key = k, data = item})
        end
    end

    local totalH = 0
    local anyShown = false

    for _, cat in ipairs(order) do
        local grp = groups[cat]
        if grp and #grp > 0 then
            anyShown = true
            table.sort(grp, function(a, b)
                return (a.data.name or a.data.class or "") < (b.data.name or b.data.class or "")
            end)

            local cb = vgui.Create("DButton", lp)
            cb:SetPos(0, totalH)
            cb:SetSize(lw, BAR_H)
            cb:SetText("")
            cb.Paint = function(s, w, h)
                draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and RED_H or RED)
                draw.SimpleText(cat, "Trebuchet24", w / 2, h / 2, WH,
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                DrawTri(w - 22, h / 2, 6, not self.collapsed[cat], Color(255, 255, 255, 170))
            end
            cb.DoClick = function()
                self.collapsed[cat] = not self.collapsed[cat]
                self:Refresh()
            end
            totalH = totalH + BAR_H

            if self.collapsed[cat] then
                totalH = totalH + 12
            else
                totalH = totalH + BAR_GAP

                local total = #grp + 1
                local rows  = math.ceil(total / COLS)
                local gridH = rows * ISIZ + (rows - 1) * GAP

                local grid = vgui.Create("DPanel", lp)
                grid:SetPos(0, totalH)
                grid:SetSize(lw, gridH)
                grid.Paint = function() end

                for idx, it in ipairs(grp) do
                    local col = (idx - 1) % COLS
                    local row = math.floor((idx - 1) / COLS)
                    local btn = vgui.Create("DButton", grid)
                    btn:SetPos(gridX + col * (ISIZ + GAP), row * (ISIZ + GAP))
                    btn:SetSize(ISIZ, ISIZ)
                    btn:SetText("")
                    btn._icon, btn._gadget = GetItemIcon(it.data)

                    btn.Paint = function(s, w, h)
                        local sel = (self.selKey == it.key)
                        draw.RoundedBox(6, 0, 0, w, h,
                            sel and RED or (s:IsHovered() and CARD_H or CARD))
                        local ix, iy, iw, ih = 8, 8, w - 16, h - 16
                        if s._gadget then
                            local cx, cy = ix + iw / 2, iy + ih / 2
                            iw, ih = iw * GADGET_ICON_SCALE, ih * GADGET_ICON_SCALE
                            ix, iy = cx - iw / 2, cy - ih / 2
                        end
                        DrawIcon(s._icon, ix, iy, iw, ih, WH)

                        if HORDE.GetQualityStars and it.data.quality then
                            local stars = HORDE:GetQualityStars(it.data.quality)
                            local ss, sg = 6, 2
                            local total = stars * ss + (stars - 1) * sg
                            local sx = (w - total) / 2
                            local sy = h - ss - 3
                            for k = 1, stars do
                                draw.RoundedBox(1, sx + (k - 1) * (ss + sg), sy, ss, ss, WH)
                            end
                        end
                    end

                    btn.DoClick = function()
                        self.selKey = it.key
                        self:LoadItem(it.data)
                    end
                    btn.OnCursorEntered = function()
                        self.tipItem = it.data
                        self.tipCls  = nil
                    end
                    btn.OnCursorExited = function() self.tipItem = nil end

                    btn.DoRightClick = function()
                        local m = DermaMenu()
                        m:AddOption("Modify", function()
                            self.selKey = it.key
                            self:LoadItem(it.data)
                        end)
                        m:AddOption("Give to me (test)", function()
                            RunConsoleCommand("horde_give_test", it.key)
                        end)
                        m:AddSpacer()
                        local del = m:AddOption("Delete", function()
                            Derma_Query('Delete "' .. (it.data.name or it.key) .. '"?',
                                "Confirm",
                                "Delete", function()
                                    HORDE.items[it.key] = nil
                                    if self.selKey == it.key then
                                        self.selKey       = nil
                                        self.itemSelected = false
                                    end
                                    self:NetSave()
                                    self:Refresh()
                                end,
                                "Cancel", function() end)
                        end)
                        del:SetIcon("icon16/delete.png")
                        m:Open()
                    end
                end

                local ai   = #grp
                local plus = vgui.Create("DButton", grid)
                plus:SetPos(gridX + (ai % COLS) * (ISIZ + GAP), math.floor(ai / COLS) * (ISIZ + GAP))
                plus:SetSize(ISIZ, ISIZ)
                plus:SetText("")
                plus:SetTooltip("Add item to " .. cat)
                plus.Paint = function(s, w, h)
                    draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and CARD or TILE)
                    local c  = s:IsHovered() and DIM or Color(88, 91, 98)
                    local len = math.floor(w * 0.34)
                    local th  = 4
                    draw.RoundedBox(2, w / 2 - len / 2, h / 2 - th / 2, len, th, c)
                    draw.RoundedBox(2, w / 2 - th / 2, h / 2 - len / 2, th, len, c)
                end
                plus.DoClick = function() self:_NewItem(cat) end

                totalH = totalH + gridH + BAR_GAP
            end
        end
    end

    if not anyShown then
        local hint = vgui.Create("DLabel", lp)
        hint:SetPos(16, 12)
        hint:SetSize(lw - 32, 30)
        hint:SetFont("HC_Body")
        hint:SetTextColor(DIM)
        hint:SetText("No items found. Change the class filter or search.")
        totalH = 56
    end

    lp:SetTall(math.max(totalH + M, self.leftScroll:GetTall()))
end

function PANEL:_NewItem(cat)
    self.selKey       = nil
    self.itemSelected = false
    self.e            = self:_Empty()
    if cat then self.e.category = cat end
    self:_PopRight()
    if IsValid(self.rightScroll) then self.rightScroll:GetVBar():SetScroll(0) end
end

function PANEL:_BuildRight()
    local cw  = self.RW - 22
    local LBX = 40
    local SIDE = 40

    local rScroll = vgui.Create("DScrollPanel", self)
    rScroll:SetPos(self.RX, HEADER_H)
    rScroll:SetSize(self.RW, self:GetTall() - HEADER_H - M)
    DrawScrollBar(rScroll)
    self.rightScroll = rScroll

    local rp = vgui.Create("DPanel", rScroll)
    rp:SetSize(cw, 10)
    rp.labels = {}
    rp.Paint = function(s)
        for _, l in ipairs(s.labels) do
            draw.SimpleText(l.text, l.font, l.x, l.y, l.col or WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    self.rightPanel = rp

    local function AddLabel(text, x, y, font, col)
        table.insert(rp.labels, {text = text, x = x, y = y, font = font or "HC_Label", col = col})
    end

    local ry = 0

    ry = SectionBar(rp, "Type", ry, cw)

    local TYPES = {
        {key = "weapon", label = "Weapon"},
        {key = "give",   label = "Give"},
        {key = "drop",   label = "Drop"},
        {key = "gadget", label = "Gadget"},
    }
    local PW, PH = math.floor(cw * 0.16), 34
    local pg = SpaceAround(cw, #TYPES, PW)
    self.typeBtns = {}
    for i, tp in ipairs(TYPES) do
        local tb = vgui.Create("DButton", rp)
        local ic = GM(TYPE_ICONS[tp.key])
        tb:SetPos(pg + (i - 1) * (PW + pg), ry)
        tb:SetSize(PW, PH)
        tb:SetText("")
        tb:SetTooltip(tp.label)
        tb._key = tp.key
        tb.Paint = function(s, w, h)
            local act = (self.e.entity_type == s._key)
            draw.RoundedBox(6, 0, 0, w, h, act and RED or (s:IsHovered() and BTN_H or BTN))
            DrawIcon(ic, w / 2 - 10, h / 2 - 10, 20, 20, WH)
        end
        tb.DoClick = function()
            self.e.entity_type = tp.key
            self:_UpdateTypeVis()
        end
        self.typeBtns[tp.key] = tb
    end
    ry = ry + PH + 30

    surface.SetFont("HC_Label")
    local lblW = surface.GetTextSize("Category:")
    local EX   = LBX + lblW + 24
    local EW   = cw - EX - SIDE
    local EH   = 36
    local PITCH = EH + 30

    AddLabel("Class:",    LBX, ry + EH / 2)
    AddLabel("Category:", LBX, ry + PITCH + EH / 2)
    AddLabel("Name:",     LBX, ry + PITCH * 2 + EH / 2)

    self.classEntry = vgui.Create("DTextEntry", rp)
    self.classEntry:SetPos(EX, ry)
    self.classEntry:SetSize(EW, EH)
    StyledEntry(self.classEntry)
    self.classEntry.OnChange = function(s) self.e.class = s:GetValue() end

    local cdrop = vgui.Create("DButton", rp)
    cdrop:SetPos(EX + EW - 34, ry + 3)
    cdrop:SetSize(30, EH - 6)
    cdrop:SetText("")
    cdrop:SetTooltip("Pick a registered weapon")
    cdrop.Paint = function(s, w, h)
        draw.RoundedBox(5, 0, 0, w, h, s:IsHovered() and BTN_H or BTN)
        DrawTri(w / 2, h / 2, 5, true, s:IsHovered() and WH or DIM)
    end
    cdrop.DoClick = function()
        local m = DermaMenu()
        m:SetMaxHeight(ScrH() * 0.6)
        for wpn, _ in SortedPairs(list.Get("Weapon") or {}) do
            m:AddOption(wpn, function()
                self.e.class = wpn
                self.classEntry:SetValue(wpn)
            end)
        end
        m:Open()
    end
    self.classDropBtn = cdrop

    self.gadgetCombo = vgui.Create("DComboBox", rp)
    self.gadgetCombo:SetPos(EX, ry)
    self.gadgetCombo:SetSize(EW, EH)
    StyledCombo(self.gadgetCombo)
    self.gadgetCombo:SetVisible(false)
    for gadget, _ in SortedPairs(HORDE.gadgets or {}) do
        self.gadgetCombo:AddChoice(gadget)
    end
    self.gadgetCombo.OnSelect = function(_, _, val)
        self.e.class = val
        self.classEntry:SetValue(val)
    end

    self.catCombo = vgui.Create("DComboBox", rp)
    self.catCombo:SetPos(EX, ry + PITCH)
    self.catCombo:SetSize(EW, EH)
    self.catCombo:SetSortItems(false)
    StyledCombo(self.catCombo)
    for _, cat in ipairs(HORDE.categories or {}) do
        self.catCombo:AddChoice(cat)
    end
    self.catCombo.OnSelect = function(_, _, val) self.e.category = val end

    self.nameEntry = vgui.Create("DTextEntry", rp)
    self.nameEntry:SetPos(EX, ry + PITCH * 2)
    self.nameEntry:SetSize(EW, EH)
    StyledEntry(self.nameEntry)
    self.nameEntry.OnChange = function(s) self.e.name = s:GetValue() end

    ry = ry + PITCH * 2 + EH + 34

    ry = SectionBar(rp, "Properties", ry, cw)

    local PROPS = {
        {key = "skull_tokens", icon = ICON_SKULL,  tip = "Skull tokens"},
        {key = "price",        icon = ICON_PRICE,  tip = "Price"},
        {key = "weight",       icon = ICON_WEIGHT, tip = "Weight"},
        {key = "_desc",        icon = ICON_DESC,   tip = "Description"},
    }
    local PPH = 32
    local ppg = SpaceAround(cw, #PROPS, PW)
    for i, pp in ipairs(PROPS) do
        local pb  = vgui.Create("DButton", rp)
        local pic = GM(pp.icon)
        pb:SetPos(ppg + (i - 1) * (PW + ppg), ry)
        pb:SetSize(PW, PPH)
        pb:SetText("")
        pb:SetTooltip(pp.tip)
        pb.Paint = function(s, w, h)
            draw.RoundedBox(6, 0, 0, w, h, s:IsHovered() and BTN_H or BTN)
            DrawIcon(pic, 8, h / 2 - 11, 22, 22, WH)
            local val, col = nil, WH
            if pp.key == "_desc" then
                local has = self.e.description and self.e.description ~= ""
                val = "D"
                col = has and WH or DIM
            else
                val = tostring(self.e[pp.key] or 0)
            end
            draw.SimpleText(val, "HC_Num", w - 12, h / 2, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        pb.DoClick = function()
            if pp.key == "_desc" then
                self:OpenDescEditor()
            else
                Derma_StringRequest(pp.tip, "Enter value:",
                    tostring(self.e[pp.key] or 0), function(v)
                        local n = tonumber(v)
                        if n then
                            self.e[pp.key] = n
                            if pp.key == "price" then self.e.price_manual = true end
                        end
                    end)
            end
        end
    end
    ry = ry + PPH + 30

    AddLabel("Quality:", LBX, ry + EH / 2)
    self.qualityCombo = vgui.Create("DComboBox", rp)
    self.qualityCombo:SetPos(EX, ry)
    self.qualityCombo:SetSize(EW, EH)
    self.qualityCombo:SetSortItems(false)
    StyledCombo(self.qualityCombo)
    for _, qk in ipairs(HORDE.QualityOrder or {}) do
        self.qualityCombo:AddChoice(qk)
    end
    self.qualityCombo.OnSelect = function(_, _, val)
        self.e.quality = val
        self.e.quality_manual = true
    end
    ry = ry + EH + 12

    local qbw = math.floor((cw - LBX - SIDE - GAP) / 2)
    FlatButton(rp, "Recalculate", LBX, ry, qbw, 32, BTN, RED,
        function() self:_RecalcAuto(false) end)
    FlatButton(rp, "Reset to auto", LBX + qbw + GAP, ry, qbw, 32, BTN, BTN_H,
        function() self:_RecalcAuto(true) end)
    ry = ry + 32 + 30

    AddLabel("Whitelist:", LBX, ry + 14)

    ry = ry + 40

    local WX    = 24
    local WCOLS = 7
    local WSZ   = math.floor((cw - WX - 12 - (WCOLS - 1) * GAP) / WCOLS)
    self.wlBtns = {}
    local wi = 0
    for clsName, _ in SortedPairs(HORDE.subclasses or {}) do
        local col = wi % WCOLS
        local row = math.floor(wi / WCOLS)
        wi = wi + 1

        local wb  = vgui.Create("DButton", rp)
        local wic = GetSubIcon(clsName)
        wb:SetPos(WX + col * (WSZ + GAP), ry + row * (WSZ + GAP))
        wb:SetSize(WSZ, WSZ)
        wb:SetText("")
        wb._cls = clsName
        wb.on   = true
        wb.Paint = function(s, w, h)
            draw.RoundedBox(6, 0, 0, w, h, s.on and RED or (s:IsHovered() and CARD_H or CARD))
            DrawIcon(wic, 8, 8, w - 16, h - 16, WH)
        end
        wb.OnCursorEntered = function()
            self.tipCls  = clsName
            self.tipItem = nil
        end
        wb.OnCursorExited = function() self.tipCls = nil end
        wb.DoClick = function()
            wb.on = not wb.on
            if not self.e.whitelist then
                self.e.whitelist = {}
                for cn, _ in pairs(HORDE.subclasses or {}) do
                    self.e.whitelist[cn] = true
                end
            end
            self.e.whitelist[clsName] = wb.on
        end
        self.wlBtns[clsName] = wb
    end
    self.wlRows = math.max(1, math.ceil(wi / WCOLS))
    ry = ry + self.wlRows * (WSZ + GAP) + 16

    ry = SectionBar(rp, "Ammo & Icon", ry, cw)

    surface.SetFont("HC_Body")
    local aw   = surface.GetTextSize("Alt ammo price:")
    local AX   = LBX + aw + 20
    local AW   = cw - AX - SIDE
    local AH   = 32
    local APIT = AH + 12

    local function LabeledEntry(text, y)
        AddLabel(text, LBX, y + AH / 2, "HC_Body")
        local ent = vgui.Create("DTextEntry", rp)
        ent:SetPos(AX, y)
        ent:SetSize(AW, AH)
        StyledEntry(ent)
        return ent
    end

    self.ammoPriceEntry = LabeledEntry("Ammo price:", ry)
    self.ammoPriceEntry.OnChange = function(s)
        local n = tonumber(s:GetValue())
        if n then self.e.ammo_price = n end
    end
    self.secAmmoPriceEntry = LabeledEntry("Alt ammo price:", ry + APIT)
    self.secAmmoPriceEntry.OnChange = function(s)
        local n = tonumber(s:GetValue())
        if n then self.e.sec_ammo_price = n end
    end
    self.shopIconEntry = LabeledEntry("Shop icon:", ry + APIT * 2)
    self.shopIconEntry.OnChange = function(s) self.e.shop_icon = s:GetValue() end
    ry = ry + APIT * 2 + AH + 30

    ry = SectionBar(rp, "Levels (0-100)", ry, cw)

    AddLabel("5=Green  10=Blue  15=Purple  20=Orange  25=Yellow  30+=Red",
        LBX, ry - 6, "HC_Small", DIM)
    ry = ry + 22

    local classes = {}
    for k, _ in SortedPairs(HORDE.subclasses or {}) do
        table.insert(classes, k)
    end
    local CELL_W, CELL_H = 104, 36
    local lvlCols = math.max(1, math.floor((cw - LBX - SIDE + 10) / CELL_W))
    local lvlRows = math.max(1, math.ceil(#classes / lvlCols))

    local lvlCont = vgui.Create("DPanel", rp)
    lvlCont:SetPos(LBX, ry)
    lvlCont:SetSize(cw - LBX - SIDE, lvlRows * CELL_H)
    lvlCont.Paint = function()
        for i, cls in ipairs(classes) do
            local col = (i - 1) % lvlCols
            local row = math.floor((i - 1) / lvlCols)
            DrawIcon(GetSubIcon(cls), col * CELL_W, row * CELL_H + 2, 30, 30, WH)
        end
    end

    self.levelEditors = {}
    for i, cls in ipairs(classes) do
        local col = (i - 1) % lvlCols
        local row = math.floor((i - 1) / lvlCols)
        local ent = vgui.Create("DTextEntry", lvlCont)
        ent:SetPos(col * CELL_W + 36, row * CELL_H + 2)
        ent:SetSize(52, 30)
        ent:SetNumeric(true)
        ent:SetTooltip(cls)
        StyledEntry(ent)
        ent._cls = cls
        ent.OnChange = function(s)
            local n = tonumber(s:GetValue())
            self.e.levels[s._cls] = (n and n > 0) and n or nil
        end
        self.levelEditors[cls] = ent
    end
    ry = ry + lvlRows * CELL_H + 30

    ry = SectionBar(rp, "Damage Type", ry, cw)

    local DMGS = {}
    local dmgRaw = {
        {k = "DMG_BALLISTIC", name = "Ballistic"},
        {k = "DMG_SLASH",     name = "Slash"},
        {k = "DMG_BLUNT",     name = "Blunt"},
        {k = "DMG_PHYSICAL",  name = "Physical"},
        {k = "DMG_FIRE",      name = "Fire"},
        {k = "DMG_COLD",      name = "Cold"},
        {k = "DMG_LIGHTNING", name = "Lightning"},
        {k = "DMG_POISON",    name = "Poison"},
        {k = "DMG_BLAST",     name = "Blast"},
    }
    for _, d in ipairs(dmgRaw) do
        if HORDE[d.k] then
            table.insert(DMGS, {k = HORDE[d.k], name = d.name})
        end
    end

    local TCOLS = 3
    local TH    = 32
    local TW    = math.floor((cw - LBX - SIDE - (TCOLS - 1) * GAP) / TCOLS)

    local function ToggleGrid(defs, store, listKey, iconTbl, colorTbl, y0)
        for i, d in ipairs(defs) do
            local col = (i - 1) % TCOLS
            local row = math.floor((i - 1) / TCOLS)
            local b   = vgui.Create("DButton", rp)
            b:SetPos(LBX + col * (TW + GAP), y0 + row * (TH + GAP))
            b:SetSize(TW, TH)
            b:SetText("")
            b._key = d.k
            b.on   = false
            local iconM = iconTbl and iconTbl[d.k] and GM(iconTbl[d.k]) or nil
            b.Paint = function(s, w, h)
                draw.RoundedBox(6, 0, 0, w, h, s.on and RED or (s:IsHovered() and CARD_H or CARD))
                local tx = 10
                if iconM and not iconM:IsError() then
                    local dc = (colorTbl and colorTbl[s._key]) or WH
                    DrawIcon(iconM, 8, h / 2 - 10, 20, 20, dc)
                    tx = 36
                end
                draw.SimpleText(d.name, "HC_Body", tx, h / 2, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            b.DoClick = function()
                b.on = not b.on
                local arr = self.e[listKey]
                if b.on then
                    if not table.HasValue(arr, b._key) then table.insert(arr, b._key) end
                else
                    for idx2, v in ipairs(arr) do
                        if v == b._key then table.remove(arr, idx2); break end
                    end
                end
            end
            store[d.k] = b
        end
        return y0 + math.ceil(#defs / TCOLS) * (TH + GAP)
    end

    self.dmgBtns = {}
    ry = ToggleGrid(DMGS, self.dmgBtns, "dmgtype", HORDE.DMG_TYPE_ICON, HORDE.DMG_COLOR, ry) + 18

    ry = SectionBar(rp, "Infusions", ry, cw)

    local INF_RAW = {
        {k = "Infusion_Hemo",         name = "Hemo"},
        {k = "Infusion_Concussive",   name = "Concussive"},
        {k = "Infusion_Septic",       name = "Septic"},
        {k = "Infusion_Flaming",      name = "Flaming"},
        {k = "Infusion_Arctic",       name = "Arctic"},
        {k = "Infusion_Galvanizing",  name = "Galvanizing"},
        {k = "Infusion_Quality",      name = "Quality"},
        {k = "Infusion_Impaling",     name = "Impaling"},
        {k = "Infusion_Rejuvenating", name = "Rejuvenating"},
        {k = "Infusion_Quicksilver",  name = "Quicksilver"},
        {k = "Infusion_Titanium",     name = "Titanium"},
        {k = "Infusion_Chrono",       name = "Chrono"},
        {k = "Infusion_Ruination",    name = "Ruination"},
    }
    local INFS = {}
    for _, d in ipairs(INF_RAW) do
        if HORDE[d.k] then
            table.insert(INFS, {k = HORDE[d.k], name = d.name})
        end
    end

    self.infBtns = {}
    ry = ToggleGrid(INFS, self.infBtns, "infusions", HORDE.Infusion_Icons, HORDE.Infusion_Colors, ry) + 18

    ry = SectionBar(rp, "Starter Class", ry, cw)

    AddLabel("Separate by comma.  e.g. Assault,Survivor,SpecOps", LBX, ry - 6, "HC_Small", DIM)
    AddLabel("Shown as read-only Starter Weapons in Class Config.", LBX, ry + 16, "HC_Small", DIM)
    ry = ry + 44

    self.starterEntry = vgui.Create("DTextEntry", rp)
    self.starterEntry:SetPos(LBX, ry)
    self.starterEntry:SetSize(cw - LBX - SIDE, AH)
    StyledEntry(self.starterEntry)
    self.starterEntry.OnChange = function(s)
        self.e.starter_classes = {}
        for _, v in ipairs(string.Explode(",", s:GetValue())) do
            local t = string.Trim(v)
            if t ~= "" then table.insert(self.e.starter_classes, t) end
        end
    end
    ry = ry + AH + 24

    if GetConVarNumber("horde_default_item_config") == 1 or
       (GetConVarString("horde_external_lua_config") or "") ~= "" then
        AddLabel("Default/external config - changes won't be saved!", LBX, ry + 9, "HC_Small", Color(255, 80, 80))
        ry = ry + 26
    end

    rp:SetTall(ry + M)
end

function PANEL:LoadItem(item)
    self.itemSelected = true
    local etype = "weapon"
    if item.entity_properties then
        local t = item.entity_properties.type
        if     t == HORDE.ENTITY_PROPERTY_GIVE   then etype = "give"
        elseif t == HORDE.ENTITY_PROPERTY_DROP   then etype = "drop"
        elseif t == HORDE.ENTITY_PROPERTY_GADGET then etype = "gadget"
        end
    end
    self.e = {
        entity_type    = etype,
        class          = item.class         or "",
        category       = item.category      or "",
        name           = item.name          or "",
        price          = item.price         or 0,
        quality        = item.quality       or (HORDE.GetQualityByPrice and HORDE:GetQualityByPrice(item.price)) or "Common",
        quality_manual = item.quality_manual or false,
        price_manual   = item.price_manual  or false,
        skull_tokens   = item.skull_tokens  or 0,
        weight         = item.weight        or 0,
        description    = item.description   or "",
        whitelist      = item.whitelist     and table.Copy(item.whitelist) or nil,
        ammo_price     = item.ammo_price    or (HORDE.default_ammo_price or 0),
        sec_ammo_price = item.secondary_ammo_price or -1,
        shop_icon      = item.shop_icon     or "",
        levels         = item.levels        and table.Copy(item.levels)    or {},
        dmgtype        = item.dmgtype       and table.Copy(item.dmgtype)   or {},
        infusions      = item.infusions     and table.Copy(item.infusions) or {},
        starter_classes = item.starter_classes and table.Copy(item.starter_classes) or {},
        drop_x    = item.entity_properties and item.entity_properties.x     or 50,
        drop_z    = item.entity_properties and item.entity_properties.z     or 15,
        drop_yaw  = item.entity_properties and item.entity_properties.yaw   or 0,
        drop_limit= item.entity_properties and item.entity_properties.limit or 5,
        is_arccw  = item.entity_properties and item.entity_properties.is_arccw_attachment or false,
        arccw_type= item.entity_properties and item.entity_properties.arccw_attachment_type or "",
    }
    self:_PopRight()
end

function PANEL:_PopRight()
    local e = self.e
    if IsValid(self.classEntry) then self.classEntry:SetValue(e.class) end
    if IsValid(self.nameEntry)  then self.nameEntry:SetValue(e.name) end
    if IsValid(self.catCombo)   then self.catCombo:SetValue(e.category) end
    if e.entity_type == "gadget" and e.class ~= "" then
        if IsValid(self.gadgetCombo) then self.gadgetCombo:SetValue(e.class) end
    end

    for clsName, wb in pairs(self.wlBtns) do
        if e.whitelist ~= nil then
            wb.on = (e.whitelist[clsName] == true)
        else
            wb.on = true
        end
    end

    if IsValid(self.qualityCombo) then self.qualityCombo:SetValue(e.quality or "Common") end
    if IsValid(self.ammoPriceEntry)    then self.ammoPriceEntry:SetValue(tostring(e.ammo_price or 0)) end
    if IsValid(self.secAmmoPriceEntry) then self.secAmmoPriceEntry:SetValue(tostring(e.sec_ammo_price or -1)) end
    if IsValid(self.shopIconEntry)     then self.shopIconEntry:SetValue(e.shop_icon or "") end

    for cls, ent in pairs(self.levelEditors) do
        if IsValid(ent) then
            local v = e.levels and e.levels[cls]
            ent:SetValue(v and tostring(v) or "")
        end
    end
    for dmg, b in pairs(self.dmgBtns) do
        if IsValid(b) then b.on = e.dmgtype and table.HasValue(e.dmgtype, dmg) or false end
    end
    for inf, b in pairs(self.infBtns) do
        if IsValid(b) then b.on = e.infusions and table.HasValue(e.infusions, inf) or false end
    end
    if IsValid(self.starterEntry) then
        self.starterEntry:SetValue(table.concat(e.starter_classes or {}, ","))
    end

    self:_UpdateTypeVis()
end

function PANEL:_UpdateTypeVis()
    local isGadget = (self.e.entity_type == "gadget")
    if IsValid(self.gadgetCombo)  then self.gadgetCombo:SetVisible(isGadget) end
    if IsValid(self.classEntry)   then self.classEntry:SetVisible(not isGadget) end
    if IsValid(self.classDropBtn) then self.classDropBtn:SetVisible(not isGadget) end
end

function PANEL:_RecalcAuto(reset)
    local e = self.e
    if not e.class or e.class == "" then
        notification.AddLegacy("Set a class first!", NOTIFY_ERROR, 3); return
    end
    if not HORDE.ComputeItemAutoValues then return end

    local manual_price   = (not reset) and (e.price_manual and e.price or nil) or nil
    local manual_quality = (not reset) and (e.quality_manual and e.quality or nil) or nil

    local v = HORDE:ComputeItemAutoValues(e.class, e.category, manual_price, manual_quality)
    if not v then return end
    if not v.stats then
        notification.AddLegacy("No weapon stats found for this class.", NOTIFY_ERROR, 3); return
    end

    if reset or not e.price_manual then
        e.price = v.price
        e.price_manual = false
    end
    if reset or not e.quality_manual then
        e.quality = v.quality
    end
    e.weight = v.weight
    e.skull_tokens = v.skull_tokens

    self:_PopRight()
    if v.stats then
        HORDE:PlayNotification(string.format(
            "Auto: $%d  %s  (DPS %.0f, E %.0f)",
            v.price, tostring(v.quality), v.stats.damage * v.stats.num / v.stats.delay, v.efficiency or 0))
    end
end

function PANEL:OpenDescEditor()
    local ovl, box = Modal(self, 480, 340, "Edit Description")

    local ta = vgui.Create("DTextEntry", box)
    ta:SetPos(16, 56)
    ta:SetSize(box:GetWide() - 32, 214)
    ta:SetMultiline(true)
    ta:SetFont("HC_Body")
    ta:SetValue(self.e.description or "")
    ta.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, BTN)
        s:DrawTextEntryText(WH, RED, WH)
    end

    local bw = (box:GetWide() - 32 - 12) / 2
    FlatButton(box, "Save", 16, box:GetTall() - 52, bw, 36, RED, RED_H, function()
        self.e.description = ta:GetValue()
        ovl:Remove()
    end)
    FlatButton(box, "Cancel", 16 + bw + 12, box:GetTall() - 52, bw, 36, BTN, BTN_H, function()
        ovl:Remove()
    end)
end

function PANEL:OpenClassPicker()
    local ovl, box = Modal(self, math.min(700, self:GetWide() - 40), math.min(520, self:GetTall() - 40),
        "Select class")

    local scroll = vgui.Create("DScrollPanel", box)
    scroll:SetPos(16, 52)
    scroll:SetSize(box:GetWide() - 32, box:GetTall() - 52 - 16)
    DrawScrollBar(scroll)

    local CW, CH = 100, 118
    local avail  = scroll:GetWide() - 14
    local cols   = math.max(1, math.floor((avail + GAP) / (CW + GAP)))

    local canvas = vgui.Create("DPanel", scroll)
    canvas.Paint = function() end

    local names = {"__ALL"}
    for clsName, _ in SortedPairs(HORDE.subclasses or {}) do
        table.insert(names, clsName)
    end
    canvas:SetSize(avail, math.ceil(#names / cols) * (CH + GAP))

    for i, nm in ipairs(names) do
        local isAll = (nm == "__ALL")
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local b = vgui.Create("DButton", canvas)
        b:SetPos(col * (CW + GAP), row * (CH + GAP))
        b:SetSize(CW, CH)
        b:SetText("")
        local ic = isAll and GM(ICON_ALL) or GetSubIcon(nm)
        local label = isAll and "Show All" or nm
        b.Paint = function(s, w, h)
            local cur = (isAll and self.curClass == "ALL") or (nm == self.curClass)
            draw.RoundedBox(6, 0, 0, w, h, cur and RED or (s:IsHovered() and CARD_H or CARD))
            DrawIcon(ic, 14, 12, w - 28, w - 28, WH)
            draw.SimpleText(label, "HC_Small", w / 2, h - 16, WH,
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function()
            self.curClass = isAll and "ALL" or nm
            ovl:Remove()
            self:Refresh()
        end
    end
end

function PANEL:NetSave()
    local tab = util.TableToJSON(HORDE.items)
    local str = util.Compress(tab)
    net.Start("Horde_SetItemsData")
        net.WriteUInt(string.len(str), 32)
        net.WriteData(str, string.len(str))
    net.SendToServer()
    HORDE:PlayNotification("Your changes have been saved.")
end

function PANEL:_DoSave()
    local e = self.e
    if not e.class or e.class == "" then
        notification.AddLegacy("Class cannot be empty!", NOTIFY_ERROR, 3); return
    end
    if not e.name or e.name == "" then
        notification.AddLegacy("Name cannot be empty!", NOTIFY_ERROR, 3); return
    end

    local ep = {type = HORDE.ENTITY_PROPERTY_WPN}
    if e.entity_type == "weapon" then
        ep.type = HORDE.ENTITY_PROPERTY_WPN
    elseif e.entity_type == "give" then
        ep.type = HORDE.ENTITY_PROPERTY_GIVE
        ep.is_arccw_attachment = e.is_arccw
        if e.is_arccw then ep.arccw_attachment_type = e.arccw_type end
    elseif e.entity_type == "drop" then
        ep.type = HORDE.ENTITY_PROPERTY_DROP
        ep.x = e.drop_x; ep.z = e.drop_z; ep.yaw = e.drop_yaw; ep.limit = e.drop_limit
    elseif e.entity_type == "gadget" then
        ep.type = HORDE.ENTITY_PROPERTY_GADGET
    end

    local whitelist = {}
    local anyFalse = false
    for clsName, wb in pairs(self.wlBtns) do
        whitelist[clsName] = wb.on
        if not wb.on then anyFalse = true end
    end
    if not anyFalse then whitelist = nil end

    HORDE:CreateItem(
        e.category, e.name, e.class,
        e.price or 0, e.weight or 0, e.description or "",
        whitelist,
        e.ammo_price or 0, e.sec_ammo_price or -1,
        ep, e.shop_icon or "", e.levels or {},
        e.skull_tokens or 0, e.dmgtype or {}, e.infusions or {},
        e.starter_classes or {},
        nil,
        e.quality or "Common",
        e.price_manual or false
    )

    self.selKey = e.class
    self:NetSave()
    self:Refresh()
end

function PANEL:_UnregisteredWeapons()
    local out = {}
    local known = HORDE.GetKnownWeaponClasses and HORDE:GetKnownWeaponClasses() or {}
    for _, cls in ipairs(known) do
        if not (HORDE.items and HORDE.items[cls]) then
            out[#out + 1] = cls
        end
    end
    return out
end

function PANEL:_FillFromWeapon(cls)
    local e = self:_Empty()
    e.class = cls

    local swep = weapons.GetStored(cls) or weapons.Get(cls)
    if swep then
        e.name = swep.PrintName or cls
        if swep.Trivia_Desc and swep.Trivia_Desc ~= "" then
            e.description = swep.Trivia_Desc
        end
        local slot = swep.Slot
        local slot_cat = { [0] = "Melee", [1] = "Pistol", [2] = "SMG", [3] = "Rifle",
                           [4] = "Shotgun", [5] = "MG", [6] = "Explosive" }
        if slot_cat[slot] then e.category = slot_cat[slot] end
    else
        e.name = cls
    end

    if HORDE.ComputeItemAutoValues then
        local v = HORDE:ComputeItemAutoValues(cls, e.category, nil, nil)
        if v.stats then
            e.price        = v.price
            e.quality      = v.quality
            e.weight       = v.weight
            e.skull_tokens = v.skull_tokens
        end
        e.price_manual = false
    end

    if swep and swep.WepSelectIcon then
        local tex = swep.WepSelectIcon
        if isstring(tex) then e.shop_icon = tex end
    end

    return e
end

function PANEL:OpenScanWeapons()
    local list = self:_UnregisteredWeapons()
    local ovl, box = Modal(self, math.min(760, self:GetWide() - 40),
        math.min(560, self:GetTall() - 40), "Scan Weapons")

    local scroll = vgui.Create("DScrollPanel", box)
    scroll:SetPos(16, 52)
    scroll:SetSize(box:GetWide() - 32, box:GetTall() - 52 - 60)
    DrawScrollBar(scroll)

    local canvas = vgui.Create("DPanel", scroll)
    canvas.Paint = function() end
    local rowH = 30
    canvas:SetSize(scroll:GetWide() - 14, math.max(#list * rowH, 10))

    if #list == 0 then
        local lbl = vgui.Create("DLabel", canvas)
        lbl:SetPos(8, 8)
        lbl:SetFont("HC_Body")
        lbl:SetTextColor(DIM)
        lbl:SetText("All available weapons are already registered.")
    end

    for i, cls in ipairs(list) do
        local swep = weapons.GetStored(cls) or weapons.Get(cls)
        local nm = (swep and swep.PrintName) or cls
        local b = vgui.Create("DButton", canvas)
        b:SetPos(0, (i - 1) * rowH)
        b:SetSize(canvas:GetWide(), rowH - 2)
        b:SetText("")
        b.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and CARD_H or CARD)
            draw.SimpleText(nm, "HC_Body", 10, h / 2, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(cls, "HC_Small", w - 10, h / 2, DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function()
            self.e = self:_FillFromWeapon(cls)
            self.selKey = nil
            self.itemSelected = true
            self:_PopRight()
            if IsValid(self.rightScroll) then self.rightScroll:GetVBar():SetScroll(0) end
            ovl:Remove()
            HORDE:PlayNotification("Filled: " .. nm .. " — check and press Save Item.")
        end
    end

    FlatButton(box, "Close", box:GetWide() - 16 - 120, box:GetTall() - 48, 120, 34, BTN, BTN_H,
        function() ovl:Remove() end)
end

function PANEL:_RecalcAll(only_auto)
    if not HORDE.ComputeItemAutoValues then return end
    local n = 0
    for cls, item in pairs(HORDE.items or {}) do
        if item.entity_properties and item.entity_properties.type == HORDE.ENTITY_PROPERTY_WPN then
            if (not only_auto) or (not item.price_manual) then
                local v = HORDE:ComputeItemAutoValues(cls, item.category, nil, nil)
                if v and v.stats then
                    item.price        = v.price
                    item.quality      = v.quality
                    item.weight       = v.weight
                    item.skull_tokens = v.skull_tokens
                    n = n + 1
                end
            end
        end
    end
    self:NetSave()
    self:Refresh()
    HORDE:PlayNotification("Recalculated " .. n .. " weapon(s).")
end

function PANEL:_RecalcAllMenu()
    local m = DermaMenu()
    m:AddOption("Recalculate ALL weapons", function() self:_RecalcAll(false) end)
    m:AddOption("Recalculate auto-priced only", function() self:_RecalcAll(true) end)
    m:Open()
end

function PANEL:_DoDeleteAll()
    Derma_Query("Delete ALL items?", "Confirm",
        "Delete All", function()
            HORDE.items = {}
            self.selKey = nil; self.itemSelected = false
            self:NetSave(); self:Refresh()
        end, "Cancel", function() end)
end

function PANEL:_DoAddDefault()
    Derma_Query("Add default items?", "Add Default",
        "Yes", function()
            HORDE:GetDefaultItemsData()
            self:NetSave(); self:Refresh()
        end, "No", function() end)
end

function PANEL:Think()
    if self.debounceT ~= 0 and CurTime() > self.debounceT then
        self.debounceT = 0
        self:Refresh()
    end
    if self.tipItem      then _tipData = {item = self.tipItem}
    elseif self.tipCls   then _tipData = {cls  = self.tipCls}
    else                      _tipData = nil
    end
end

function PANEL:OnRemove() _tipData = nil end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, RED)
    draw.RoundedBox(6, 2, 2, w - 4, h - 4, WIN)
end

vgui.Register("HordeItemConfig", PANEL, "EditablePanel")

if IsValid(HORDE.ItemConfigGUI) then
    HORDE.ItemConfigGUI:Remove()
    HORDE.ItemConfigGUI = nil
    gui.EnableScreenClicker(false)
end

MsgC(Color(220, 30, 56), "[HORDE] ", color_white, "Item Config redesign v3.1 loaded\n")
