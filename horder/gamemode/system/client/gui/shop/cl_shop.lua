local UI = HORDE.ShopUI
local C = UI.C

local PANEL = {}

local VIEW_PANELS = {
    class = "HordeShopClassView",
    shop  = "HordeShopItemsView",
    perks = "HordeShopPerksView",
}

function PANEL:Init()
    local sw, sh = ScrW(), ScrH()
    local w = math.floor(math.min(sw * 0.782, sh * 0.782 * 16 / 9))
    local h = math.floor(w * 9 / 16)
    UI.k = w / 1200

    self:SetSize(w, h)
    self:SetPos(math.floor((sw - w) / 2), math.floor((sh - h) / 2))

    self.view = nil
    self.views = {}
    self.view_tw = {}
    self.back_tw = UI.Tween(0, 0.2)
    self.hdr = { x = 0, y = 0, w = 0, h = 0, pw = 0 }

    self.sidebar = vgui.Create("HordeShopSidebar", self)
    self.sidebar.shop = self
    self.sidebar:Build()
    self.sidebar:SetZPos(50)
    self.sidebar.OnClassClick = function(sub, locked) self:OnClassClick(sub, locked) end

    self.holder = vgui.Create("DPanel", self)
    self.holder.Paint = function() return true end

    self.back = vgui.Create("HordeUIButton", self)
    self.back.Draw = function(p, bw, bh, f) self:DrawHeaderButton(p, bw, bh, f, "<") end
    self.back.OnClick = function() self:ShowView("class") end
    self.back:SetVisible(false)

    self.close = vgui.Create("HordeUIButton", self)
    self.close.Draw = function(p, bw, bh, f) self:DrawHeaderButton(p, bw, bh, f, "X") end
    self.close.OnClick = function() HORDE:ToggleShop() end

    self:InvalidateLayout(true)

    local start = UI.START_VIEW
    if not VIEW_PANELS[start] then start = "class" end
    self:ShowView(start, true)
end

function PANEL:DrawHeaderButton(p, w, h, f, label)
    UI.Circle(w / 2, h / 2, w / 2, UI.Mix(C.RED, C.RED_H, f))
    UI.Text(label, UI.Font(14, true), w / 2, h / 2, C.WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function PANEL:EnsureView(name)
    local v = self.views[name]
    if IsValid(v) then return v end
    v = vgui.Create(VIEW_PANELS[name], self.holder)
    v.shop = self
    if v.SetShop then v:SetShop(self) end
    v:SetPos(0, 0)
    v:SetSize(self.holder:GetWide(), self.holder:GetTall())
    v:SetAlpha(0)
    v:SetVisible(false)
    self.views[name] = v
    self.view_tw[name] = UI.Tween(0, 0.2)
    return v
end

function PANEL:ShowView(name, instant)
    if not VIEW_PANELS[name] then return end
    if self.view == name and not instant then return end
    self:EnsureView(name)
    self.view = name

    for key, tw in pairs(self.view_tw) do
        if key == name then
            if instant then tw:Snap(1) else tw:Set(1) end
        else
            if instant then tw:Snap(0) else tw:Set(0) end
        end
    end

    local on_class = (name == "class")
    self.sidebar:SetCollapsed(not on_class)
    if instant then self.sidebar.col:Snap(on_class and 0 or 1) end
    if instant then self.back_tw:Snap(on_class and 0 or 1) else self.back_tw:Set(on_class and 0 or 1) end

    if name == "perks" then
        local v = self.views[name]
        if v.Rebuild and v.cur_sub ~= MySelf:Horde_GetCurrentSubclass() then v:Rebuild() end
    end
    self:InvalidateLayout()
end

function PANEL:TitleText()
    if self.view == "shop" then return UI.T("Shop_UI_Shop", "Shop") end
    if self.view == "perks" then return UI.T("Shop_UI_Perks", "Perks") end
    return UI.T("Shop_Class", "Class")
end

function PANEL:PerformLayout(w, h)
    local S = UI.S
    local padx, pady, gap = S(14), S(12), S(12)
    local sbw = math.floor(self.sidebar:CurrentWidth())
    self.sidebar:SetPos(padx, pady)
    self.sidebar:SetSize(sbw, h - pady * 2)

    local cx = padx + sbw + gap
    local cw = w - cx - padx
    local hh = S(34)
    local hdr = self.hdr
    hdr.x, hdr.y, hdr.w, hdr.h = cx, pady, cw, hh

    local bs = S(34)
    local bg = S(8)
    self.close:SetPos(cx + cw - bs, pady)
    self.close:SetSize(bs, bs)

    local bp = self.back_tw:Get()
    self.back:SetPos(cx + cw - bs - bg - bs, pady)
    self.back:SetSize(bs, bs)
    local back_on = bp > 0.01
    if self.back:IsVisible() ~= back_on then self.back:SetVisible(back_on) end
    self.back:SetAlpha(math.floor(255 * math.Clamp(bp, 0, 1)))
    self.back.disabled = (self.view == "class")

    hdr.pw = cw - (bs + bg) - bp * (bs + bg)

    local vy = pady + hh + S(10)
    self.holder:SetPos(cx, vy)
    self.holder:SetSize(cw, h - vy - pady)
    for _, v in pairs(self.views) do
        if IsValid(v) and (v:GetWide() ~= cw or v:GetTall() ~= h - vy - pady) then
            v:SetSize(cw, h - vy - pady)
        end
    end
end

function PANEL:Think()
    for name, v in pairs(self.views) do
        if IsValid(v) then
            local a = self.view_tw[name]:Get()
            v:SetAlpha(math.floor(255 * a))
            local vis = (a > 0.003) or (self.view == name)
            if v:IsVisible() ~= vis then v:SetVisible(vis) end
            v:SetMouseInputEnabled(self.view == name)
        end
    end

    local anim = self.sidebar:IsAnimating() or self.back_tw:Active()
    if anim or self.was_anim then self:InvalidateLayout() end
    self.was_anim = anim
end

function PANEL:Paint(w, h)
    local S, SB = UI.S, UI.SB
    UI.Rect(S(8), 0, 0, w, h, C.RED)
    UI.Rect(S(6), SB(2), SB(2), w - SB(4), h - SB(4), C.WIN)

    local hd = self.hdr
    UI.Pill(hd.x, hd.y, hd.pw, hd.h, C.RED)
    local cy = hd.y + hd.h / 2
    local f = UI.Font(15, true)
    local x = hd.x + S(16)

    UI.Text("$", f, x, cy, C.WH)
    surface.SetFont(f)
    x = x + surface.GetTextSize("$") + S(5)
    local money = tostring(MySelf:Horde_GetMoney())
    UI.Text(money, f, x, cy, C.WH)
    x = x + surface.GetTextSize(money) + S(16)

    local sm = UI.Mat("skull.png")
    local is = S(17)
    if sm then UI.DrawMat(sm, x, cy - is / 2, is, is, C.WH) end
    x = x + is + S(5)
    local skulls = tostring(MySelf:Horde_GetSkullTokens())
    UI.Text(skulls, f, x, cy, C.WH)
    x = x + surface.GetTextSize(skulls) + S(16)

    local wm = UI.Mat("weight.png")
    local ws = S(16)
    if wm then UI.DrawMat(wm, x, cy - ws / 2, ws, ws, C.WH) end
    x = x + ws + S(5)
    local weight = tostring(MySelf:Horde_GetMaxWeight() - MySelf:Horde_GetWeight()) .. "/" .. tostring(MySelf:Horde_GetMaxWeight())
    UI.Text(weight, f, x, cy, C.WH)

    UI.Text(self:TitleText(), UI.Font(18, true), hd.x + hd.pw - S(18), cy, C.WH, TEXT_ALIGN_RIGHT)
    return true
end

function PANEL:SetTip(lines, sx, sy, mode)
    self.tip = { lines = lines, sx = sx, sy = sy, mode = mode or "right" }
end

function PANEL:PaintOver(w, h)
    local t = self.tip
    self.tip = nil
    if not t or IsValid(self.modal) then return end
    local S, SB = UI.S, UI.SB

    local f1, f2 = UI.Font(13, true), UI.Font(12, false)
    local maxw = 0
    for i, l in ipairs(t.lines) do
        surface.SetFont(i == 1 and f1 or f2)
        maxw = math.max(maxw, (surface.GetTextSize(l)))
    end
    local pad = S(10)
    local lh = S(17)
    local bw, bh = maxw + pad * 2, #t.lines * lh + pad * 2 - S(2)

    local lx, ly = self:ScreenToLocal(t.sx, t.sy)
    local x, y
    if t.mode == "below" then
        x, y = lx - bw / 2, ly
    else
        x, y = lx + S(8), ly - bh / 2
    end
    local m = S(6)
    x = math.Clamp(x, m, w - bw - m)
    y = math.Clamp(y, m, h - bh - m)

    UI.Rect(S(6), x, y, bw, bh, C.TRACK)
    UI.Rect(0, x, y, bw, SB(3), C.RED)
    for i, l in ipairs(t.lines) do
        UI.Text(l, i == 1 and f1 or f2, x + pad, y + pad - S(1) + (i - 0.5) * lh, i == 1 and C.WH or C.DIM)
    end
end

local function class_label(name)
    return UI.T("Class_" .. name, UI.T("Subclass_Title_" .. name, name))
end

local function flat_description(sub)
    local d = string.Trim(tostring(sub.Description or ""))
    d = string.gsub(d, "%s*\n%s*", " ")
    return d
end

function PANEL:OnClassClick(sub, locked)
    if IsValid(self.modal) then return end
    local name = sub.PrintName
    if locked then
        self:OpenUnlockModal(sub)
    elseif MySelf:Horde_GetCurrentSubclass() ~= name then
        self:OpenSelectModal(sub)
    end
end

function PANEL:OpenUnlockModal(sub)
    local name = sub.PrintName
    local cost = tonumber(sub.UnlockCost) or 0
    local skulls = MySelf:Horde_GetSkullTokens()
    local can = skulls >= cost
    self.modal = UI.OpenModal(self, {
        title = UI.T("Shop_UI_UnlockClass", "Unlock Class"),
        heading = class_label(name),
        lines = { UI.T("Shop_UI_UnlockAsk", "Unlock this class permanently?") },
        dim = flat_description(sub),
        row = { label = UI.T("Shop_UI_Price", "Price:"), value = tostring(cost) .. " " .. UI.T("Shop_UI_Skulls", "Skulls"), icon = "skull.png" },
        balance = string.format(UI.T("Shop_UI_Balance", "Your balance: %s skulls"), tostring(skulls)),
        confirm = can and (UI.T("Shop_UI_Unlock", "Unlock") .. " " .. tostring(cost))
            or string.format(UI.T("Shop_UI_NeedMore", "Need %s more"), tostring(cost - skulls)),
        confirm_icon = can and "skull.png" or nil,
        can_confirm = can,
        on_confirm = function()
            net.Start("Horde_UnlockSubclass")
            net.WriteString(name)
            net.SendToServer()
        end,
    })
end

function PANEL:ApplyClassChange(sub)
    local name = sub.PrintName
    local parent = sub.ParentClass or sub.PrintName
    local cur_class = MySelf:Horde_GetClass()

    MySelf.Horde_subclass_choices = MySelf.Horde_subclass_choices or {}

    if cur_class and cur_class.name == parent then
        HORDE:SendSavedPerkChoices(name)
        MySelf:Horde_SetSubclass(parent, name)
        MySelf.Horde_subclass_choices[parent] = name
        HORDE.Prefs.Set("class_choice", name)
        HORDE:SaveSubclassChoices()
        HORDE:ToggleShop()
    else
        HORDE:SendSavedPerkChoices(name)
        MySelf.Horde_subclass_choices[parent] = name
        net.Start("Horde_SelectClass")
        net.WriteString(parent)
        net.WriteString(name)
        net.SendToServer()
        HORDE.Prefs.Set("class_choice", name)
        HORDE:SaveSubclassChoices()
    end
end

function PANEL:OpenSelectModal(sub)
    local name = sub.PrintName
    local parent = sub.ParentClass or sub.PrintName
    local cur_class = MySelf:Horde_GetClass()
    local same_parent = cur_class and cur_class.name == parent

    self.modal = UI.OpenModal(self, {
        title = UI.T("Shop_UI_ChangeClass", "Change Class"),
        heading = class_label(name),
        lines = same_parent
            and { UI.T("Shop_UI_ChangeClassAsk", "Switch to this class?") }
            or { UI.T("Shop_UI_ChangeClassAsk", "Switch to this class?"), UI.T("Shop_UI_ItemsRemoved", "Your items will be removed!") },
        dim = flat_description(sub),
        confirm = UI.T("Shop_UI_Select", "Select"),
        on_confirm = function() self:ApplyClassChange(sub) end,
    })
end

vgui.Register("HordeShop", PANEL)
