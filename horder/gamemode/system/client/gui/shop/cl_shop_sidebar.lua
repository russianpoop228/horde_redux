if not CLIENT then return end

local UI = HORDE.ShopUI
local C = UI.C
local S, SB = UI.S, UI.SB

local PANEL = {}

local C_HOVER_BG   = Color(60, 64, 70, 115)
local C_LOCK_HOVER = Color(40, 42, 48, 128)
local C_BADGE_BG   = Color(18, 19, 22, 217)
local C_DISC_RING  = Color(255, 255, 255, 217)

function PANEL:Init()
    UI.VScrollInit(self)
    self:SetSide("left")
    self.col = UI.Tween(0, 0.22)
    self.entries = {}
    self.first_layout = true
end

local function class_label(name)
    return UI.T("Class_" .. name, UI.T("Subclass_Title_" .. name, name))
end

function PANEL:Build()
    local OTHER = HORDE.SubclassCategory_Other or 99
    local cats = HORDE.SubclassCategories or {}
    local groups = {}

    for name, sub in pairs(HORDE.subclasses or {}) do
        local parent = sub.ParentClass or sub.PrintName
        if HORDE.classes and HORDE.classes[parent] then
            local cat = sub.Category
            if not cat or not cats[cat] then cat = OTHER end
            groups[cat] = groups[cat] or {}
            table.insert(groups[cat], sub)
        end
    end

    local ids = table.GetKeys(groups)
    table.sort(ids, function(a, b)
        if a == OTHER then return false end
        if b == OTHER then return true end
        return a < b
    end)

    self.entries = {}
    for _, cat in ipairs(ids) do
        local list = groups[cat]
        table.sort(list, function(a, b)
            local ua = MySelf:Horde_GetSubclassUnlocked(a.PrintName) and 0 or 1
            local ub = MySelf:Horde_GetSubclassUnlocked(b.PrintName) and 0 or 1
            if ua ~= ub then return ua < ub end
            local oa, ob = a.SortOrder or 0, b.SortOrder or 0
            if oa ~= ob then return oa < ob end
            return a.PrintName < b.PrintName
        end)

        local meta = cats[cat] or { name = "Other", icon = "status/minion.png" }
        self.entries[#self.entries + 1] = {
            kind = "cat",
            label = UI.T("Shop_Cat_" .. meta.name, meta.name),
            desc = UI.T("Shop_CatDesc_" .. meta.name, nil),
            icon = UI.Mat(meta.icon),
        }
        for _, sub in ipairs(list) do
            local name = sub.PrintName
            self.entries[#self.entries + 1] = {
                kind = "class",
                sub = sub,
                name = name,
                label = class_label(name),
                icon = UI.Mat(sub.Icon),
                hov = UI.Tween(0, 0.15),
                act = UI.Tween(0, 0.15),
                lock = UI.Tween(0, 0.2),
                inited = false,
            }
        end
    end
end

function PANEL:SetCollapsed(b)
    self.col:Set(b and 1 or 0)
end

function PANEL:Progress()
    return self.col:Get()
end

function PANEL:IsAnimating()
    return self.col:Active()
end

function PANEL:CurrentWidth()
    return Lerp(self.col:Get(), S(240), S(50))
end

function PANEL:LayoutEntries(cw)
    local p = self.col:Get()
    local gap = S(6)
    local y = 0
    for i, e in ipairs(self.entries) do
        local h_exp = (e.kind == "cat") and S(32) or S(40)
        e.h = Lerp(p, h_exp, S(36))
        if e.kind == "cat" and i > 1 then y = y + S(6) end
        e.y = y
        e.w = Lerp(p, cw, S(36))
        e.x = (cw - e.w) / 2
        y = y + e.h + gap
    end
    self:SetContentHeight(math.max(0, y - gap))
end

function PANEL:EntryAt(cx, cy)
    if not cx then return nil end
    for _, e in ipairs(self.entries) do
        if e.y and cx >= e.x and cx <= e.x + e.w and cy >= e.y and cy <= e.y + e.h then
            return e
        end
    end
    return nil
end

function PANEL:ScrollToActive(instant)
    local cur = IsValid(MySelf) and MySelf:Horde_GetCurrentSubclass()
    for _, e in ipairs(self.entries) do
        if e.kind == "class" and e.name == cur and e.y then
            self:ScrollTo(e.y + e.h / 2 - self:GetTall() / 2, instant)
            return
        end
    end
end

local function draw_class(self, e, ox, oy, p)
    local locked = not MySelf:Horde_GetSubclassUnlocked(e.name)
    local active = (MySelf:Horde_GetCurrentSubclass() == e.name)
    local hovered = (self.hover == e)

    if not e.inited then
        e.hov:Snap(0)
        e.act:Snap(active and 1 or 0)
        e.lock:Snap(locked and 1 or 0)
        e.inited = true
    end
    e.hov:Set(hovered and 1 or 0)
    e.act:Set(active and 1 or 0)
    e.lock:Set(locked and 1 or 0)

    local hov, act, lock = e.hov:Get(), e.act:Get(), e.lock:Get()
    local x, y, w, h = ox + e.x, oy + e.y, e.w, e.h
    local th = SB(1.5)

    local border, bg
    local lockf = lock
    local b_open = UI.Mix(C.CARD, C.CARD_H, hov)
    local b_lock = UI.Mix(C.LOCK_BORDER, C.CARD, hov)
    border = UI.Mix(b_open, b_lock, lockf)
    local bg_open = UI.Mix(Color(60, 64, 70, 0), C_HOVER_BG, hov)
    local bg_lock = UI.Mix(Color(40, 42, 48, 0), C_LOCK_HOVER, hov)
    bg = UI.Mix(bg_open, bg_lock, lockf)

    if act > 0 then
        local red = UI.Mix(C.RED, C.RED_H, hov)
        border = UI.Mix(border, red, act)
    end

    UI.Pill(x, y, w, h, border)
    UI.Pill(x + th, y + th, w - th * 2, h - th * 2, C.WIN)
    UI.Pill(x + th, y + th, w - th * 2, h - th * 2, bg)

    local txt_col = UI.Mix(C.WH, C.LOCK_TXT, lockf)

    local rank = MySelf:Horde_GetRank(e.name) or HORDE.Rank_Novice
    local rank_col = (HORDE.Rank_Colors and HORDE.Rank_Colors[rank]) or C.WH
    local icon_col = UI.Mix(rank_col, C.LOCK_DISC, lockf)

    local dr = S(12)
    local dcx = Lerp(p, w - S(12) - dr, w / 2)
    local dcy = h / 2
    UI.DrawClassIcon(e.icon, x + dcx, y + dcy, dr * 2, icon_col)

    if lock > 0.01 then
        local br = dr + S(2)
        UI.Circle(x + dcx, y + dcy, br, UI.Alpha(C_BADGE_BG, lock))
        local lm = UI.Mat("locked.png")
        if lm then
            local ls = S(11)
            UI.DrawMat(lm, x + dcx - ls / 2, y + dcy - ls / 2, ls, ls, UI.Alpha(C.WH, lock))
        end
    end

    local ta = math.Clamp(1 - p * 2.2, 0, 1)
    if ta > 0.01 then
        local font = UI.Font(14.5, false)
        surface.SetFont(font)
        local tw = surface.GetTextSize(e.label)
        if S(16) + tw + S(8) < w - S(12) - dr * 2 then
            UI.Text(e.label, font, x + S(16), y + h / 2, UI.Alpha(txt_col, ta))
        else
            local avail = w - S(12) - dr * 2 - S(16) - S(8)
            if avail > S(30) then
                UI.Text(UI.Ellipsis(e.label, font, avail), font, x + S(16), y + h / 2, UI.Alpha(txt_col, ta))
            end
        end
    end
end

local function draw_cat(self, e, ox, oy, p)
    local x, y, w, h = ox + e.x, oy + e.y, e.w, e.h
    UI.Pill(x, y, w, h, C.RED)

    local isz = S(13)
    local icx = Lerp(p, w - S(14) - isz / 2, w / 2)
    if e.icon then
        UI.DrawMat(e.icon, x + icx - isz / 2, y + h / 2 - isz / 2, isz, isz, C.WH)
    end

    local ta = math.Clamp(1 - p * 2.2, 0, 1)
    if ta > 0.01 then
        local font = UI.Font(13, true)
        surface.SetFont(font)
        local tw = surface.GetTextSize(e.label)
        if S(14) + tw + S(8) < w - S(14) - isz then
            UI.Text(e.label, font, x + S(14), y + h / 2, UI.Alpha(C.WH, ta))
        end
    end
end

function PANEL:PaintContent(cw, h, ox, oy)
    local p = self.col:Get()
    self:LayoutEntries(cw)

    if self.first_layout then
        self.first_layout = false
        self:ScrollToActive(true)
        oy = -self:Scroll()
    end

    for _, e in ipairs(self.entries) do
        local ey = oy + e.y
        if ey + e.h >= -S(2) and ey <= h + S(2) then
            if e.kind == "cat" then
                draw_cat(self, e, ox, oy, p)
            else
                draw_class(self, e, ox, oy, p)
            end
        end
    end
end

function PANEL:OnThink()
    local e = self:EntryAt(self.hx, self.hy)
    if e and e.kind ~= "class" and e.kind ~= "cat" then e = nil end
    self.hover = (e and e.kind == "class") and e or nil
    self:SetCursor((self.hover and not self.dragging) and "hand" or "arrow")
    if self.hover and self.hover ~= self.last_hover then
        surface.PlaySound("UI/buttonrollover.wav")
    end
    self.last_hover = self.hover

    local shop = self.shop
    if e and IsValid(shop) and shop.SetTip then
        local p = self.col:Get()
        local lines
        if e.kind == "cat" then
            lines = { e.label }
            if e.desc then lines[2] = e.desc end
        elseif p > 0.5 then
            lines = { e.label }
            if not MySelf:Horde_GetSubclassUnlocked(e.name) then
                lines[2] = UI.T("Shop_UI_Locked", "Locked")
            end
        end
        if lines then
            local ex, ey = self:LocalToScreen(self:GetWide(), (e.y - self:Scroll()) + e.h / 2)
            shop:SetTip(lines, ex, ey)
        end
    end
end

function PANEL:ContentPressed(cx, cy, code)
    if code ~= MOUSE_LEFT then return end
    local e = self:EntryAt(cx, cy)
    if e and e.kind == "class" and self.OnClassClick then
        surface.PlaySound("UI/buttonclick.wav")
        self.OnClassClick(e.sub, not MySelf:Horde_GetSubclassUnlocked(e.name))
    end
end

vgui.Register("HordeShopSidebar", PANEL, "HordeUIVScroll")
