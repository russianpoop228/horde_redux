if not CLIENT then return end

local UI = HORDE.ShopUI
local C = UI.C
local S, SB = UI.S, UI.SB

local COLS = 2

local function build_tiers()
    local name = MySelf:Horde_GetCurrentSubclass()
    local sub = name and HORDE.subclasses and HORDE.subclasses[name]
    if not sub then return {}, nil end

    local parent = sub.ParentClass or sub.PrintName
    local cls = HORDE.classes and HORDE.classes[parent]
    local classname, perks
    if sub.ParentClass then
        classname, perks = sub.PrintName, sub.Perks
    else
        classname, perks = parent, cls and cls.perks
    end
    if not perks then return {}, classname end

    local tiers = {}
    local levels = table.GetKeys(perks)
    table.sort(levels)
    for _, level in ipairs(levels) do
        local v = perks[level]
        if v and v.choices then
            local wave = HORDE:Horde_GetWaveForPerk(level)
            local tier = {
                level = level,
                title = UI.T("Perk_Title_" .. classname .. "_Tier_" .. level, v.title or ""),
                wave = wave,
                choices = {},
            }
            for choice, perk_name in pairs(v.choices) do
                local perk = HORDE.perks and HORDE.perks[perk_name]
                if perk then
                    local icon = perk.Icon and UI.Mat(perk.Icon) or UI.Mat(sub.Icon)
                    local text = UI.T("Perk_" .. perk_name, perk.Description or "")
                    text = UI.FormatParams(text, perk.Params, classname)
                    tier.choices[#tier.choices + 1] = {
                        choice = choice,
                        perk_name = perk_name,
                        title = UI.T("Perk_Title_" .. perk_name, perk.PrintName or "Unnamed Perk"),
                        desc = string.Trim(text),
                        icon = icon,
                    }
                end
            end
            table.sort(tier.choices, function(a, b) return a.choice < b.choice end)
            if #tier.choices > 0 then tiers[#tiers + 1] = tier end
        end
    end
    return tiers, classname
end

local function is_locked(tier)
    return tier.wave > 0 and tier.wave > (HORDE.current_wave or 0)
end

local function active_choice(classname, level)
    local t = MySelf.Horde_PerkChoices and MySelf.Horde_PerkChoices[classname]
    return (t and t[level]) or 1
end

local function send_choice(classname, level, choice)
    MySelf.Horde_PerkChoices = MySelf.Horde_PerkChoices or {}
    MySelf.Horde_PerkChoices[classname] = MySelf.Horde_PerkChoices[classname] or {}
    MySelf.Horde_PerkChoices[classname][level] = choice
    HORDE.Prefs.Set("perk_choices", util.TableToJSON(MySelf.Horde_PerkChoices))
    net.Start("Horde_PerkChoice")
    net.WriteString(classname)
    net.WriteUInt(level, 4)
    net.WriteUInt(choice, 4)
    net.SendToServer()
end

local LIST = {}

function LIST:Init()
    UI.VScrollInit(self)
    self.tiers = {}
    self.tw = {}
    self.sel = nil
end

function LIST:SetTiers(tiers, classname)
    self.tiers = tiers
    self.classname = classname
    self.tw = {}
    self.lay_w = nil
end

function LIST:Layout(cw)
    if self.lay_w == cw then return end
    self.lay_w = cw
    local gap = S(8)
    self.bw = (cw - gap) / 2
    self.bh = S(64)
    self.gap = gap
    local y = 0
    for _, tier in ipairs(self.tiers) do
        tier.y = y
        local rows = math.ceil(#tier.choices / COLS)
        y = y + rows * (self.bh + gap)
    end
    self:SetContentHeight(math.max(0, y - gap))
end

function LIST:Tw(level, choice)
    local k = level .. ":" .. choice
    local t = self.tw[k]
    if not t then
        t = { hov = UI.Tween(0, 0.15), act = UI.Tween(0, 0.15) }
        self.tw[k] = t
    end
    return t
end

function LIST:ButtonAt(cx, cy)
    if not cx or not self.bw then return nil end
    for _, tier in ipairs(self.tiers) do
        for i, ch in ipairs(tier.choices) do
            local row, col = math.floor((i - 1) / COLS), (i - 1) % COLS
            local x = col * (self.bw + self.gap)
            local y = tier.y + row * (self.bh + self.gap)
            if cx >= x and cx <= x + self.bw and cy >= y and cy <= y + self.bh then
                return tier, ch
            end
        end
    end
    return nil
end

function LIST:PaintContent(cw, h, ox, oy)
    self:Layout(cw)
    local f = UI.Font(18, true)
    local hover_t, hover_c
    if self.hx then hover_t, hover_c = self:ButtonAt(self.hx, self.hy) end

    for _, tier in ipairs(self.tiers) do
        local locked = is_locked(tier)
        local cur = active_choice(self.classname, tier.level)
        for i, ch in ipairs(tier.choices) do
            local row, col = math.floor((i - 1) / COLS), (i - 1) % COLS
            local x = ox + col * (self.bw + self.gap)
            local y = oy + tier.y + row * (self.bh + self.gap)
            if y + self.bh >= 0 and y <= h then
                local tw = self:Tw(tier.level, ch.choice)
                tw.hov:Set((hover_c == ch) and 1 or 0)
                tw.act:Set((cur == ch.choice) and 1 or 0)
                local hov, act = tw.hov:Get(), tw.act:Get()

                local th = SB(1.5)
                local red = UI.Mix(C.RED, C.RED_H, hov)
                local border = UI.Mix(C.RED, red, act)
                local bg = UI.Mix(UI.Mix(C.WIN, C.CARD, hov), red, act)
                local r = S(8)
                UI.Rect(r, x, y, self.bw, self.bh, border)
                UI.Rect(math.max(0, r - th), x + th, y + th, self.bw - th * 2, self.bh - th * 2, C.WIN)
                UI.Rect(math.max(0, r - th), x + th, y + th, self.bw - th * 2, self.bh - th * 2, bg)

                local is = S(48)
                local col_icon = locked and UI.Mix(C.LOCK_TXT, C.WH, act) or C.WH
                if ch.icon then
                    UI.DrawMat(ch.icon, x + S(12), y + (self.bh - is) / 2, is, is, col_icon)
                end
                local tx = x + S(12) + is + S(10)
                local avail = self.bw - (tx - x) - S(12) - (locked and S(18) or 0)
                UI.Text(UI.Ellipsis(ch.title, f, avail), f, tx, y + self.bh / 2, col_icon)

                if locked then
                    local lm = UI.Mat("locked.png")
                    if lm then
                        local ls = S(18)
                        UI.DrawMat(lm, x + self.bw - S(12) - ls, y + (self.bh - ls) / 2, ls, ls, C.WH)
                    end
                end
            end
        end
    end
end

function LIST:OnThink()
    local t, ch = nil, nil
    if self.hx then t, ch = self:ButtonAt(self.hx, self.hy) end
    self:SetCursor(ch and "hand" or "arrow")
    if ch and ch ~= self.last_hover then surface.PlaySound("UI/buttonrollover.wav") end
    self.last_hover = ch
end

function LIST:ContentPressed(cx, cy, code)
    if code ~= MOUSE_LEFT then return end
    local tier, ch = self:ButtonAt(cx, cy)
    if tier and ch then
        surface.PlaySound("UI/buttonclick.wav")
        if self.OnPick then self.OnPick(tier, ch) end
    end
end

vgui.Register("HordeShopPerkList", LIST, "HordeUIVScroll")

local PDESC = {}

function PDESC:Init()
    self.fade = UI.Tween(1, 0.18)
    self.text = vgui.Create("HordeShopDescText", self)
    self.text.center = true
end

function PDESC:SetPerk(tier, ch, classname)
    self.tier, self.ch, self.classname = tier, ch, classname
    self.fade:Snap(0.2)
    self.fade:Set(1)
    self.text:SetText(ch and ch.desc or "")
end

function PDESC:InfoRect()
    local w, h = self:GetWide(), self:GetTall()
    return 0, h - S(40), w, S(40)
end

function PDESC:PerformLayout(w, h)
    local top = S(42) + S(26) + S(26) + S(24)
    self.text:SetPos(S(10), top)
    self.text:SetSize(w - S(20), math.max(S(30), h - S(40) - S(14) - top))
end

function PDESC:Think()
    self.text:SetAlpha(math.floor(255 * math.Clamp(self.fade:Get(), 0, 1)))
end

function PDESC:Paint(w, h)
    UI.Rect(S(3), 0, 0, w, S(30), C.RED)
    surface.SetDrawColor(C.RED)
    surface.DrawRect(0, 0, w, S(15))
    UI.Text(UI.T("Shop_UI_Description", "Description"), UI.Font(13.5, true), w / 2, S(15), C.WH, TEXT_ALIGN_CENTER)

    local tier, ch = self.tier, self.ch
    if not ch then
        UI.Text(UI.T("Shop_UI_NoPerks", "This class has no perks."), UI.Font(13.5, false), w / 2, h / 2, C.DIM, TEXT_ALIGN_CENTER)
        return true
    end
    local a = math.Clamp(self.fade:Get(), 0, 1)
    local y = S(42) + S(14)
    UI.Text(UI.Ellipsis(ch.title, UI.Font(16, true), w - S(20)), UI.Font(16, true), w / 2, y, UI.Alpha(C.WH, a), TEXT_ALIGN_CENTER)

    local sub = UI.T("Shop_UI_Tier", "Tier") .. " " .. tier.level
    if tier.title and tier.title ~= "" then sub = sub .. "  ·  " .. tier.title end
    UI.Text(UI.Ellipsis(sub, UI.Font(13.5, false), w - S(20)), UI.Font(13.5, false), w / 2, y + S(26), UI.Alpha(C.DIM, a), TEXT_ALIGN_CENTER)

    local bx, by, bw, bh = self:InfoRect()
    local th = SB(1.5)
    UI.Pill(bx, by, bw, bh, C.RED)
    UI.Pill(bx + th, by + th, bw - th * 2, bh - th * 2, C.WIN)
    local label
    if (tier.wave or 0) > 0 then
        label = string.format(UI.T("Shop_Unlocks_After_Wave", "Unlocks After Wave %d"), tier.wave)
    else
        label = UI.T("Shop_UI_AvailableFromStart", "Available from the start")
    end
    UI.Text(label, UI.Font(14.5, true), bx + bw / 2, by + bh / 2, C.WH, TEXT_ALIGN_CENTER)
    return true
end

vgui.Register("HordeShopPerkDesc", PDESC, "DPanel")

local VIEW = {}

function VIEW:Init()
    self.list = vgui.Create("HordeShopPerkList", self)
    self.desc = vgui.Create("HordeShopPerkDesc", self)

    local function pick(tier, ch)
        send_choice(self.classname, tier.level, ch.choice)
        self:Inspect(tier, ch)
    end
    self.list.OnPick = pick

    self:Rebuild()
end

function VIEW:Inspect(tier, ch)
    self.list.sel = { tier.level, ch.choice }
    self.desc:SetPerk(tier, ch, self.classname)
end

function VIEW:Rebuild()
    self.cur_sub = MySelf:Horde_GetCurrentSubclass()
    local tiers, classname = build_tiers()
    self.tiers, self.classname = tiers, classname
    self.list:SetTiers(tiers, classname)
    local t = tiers[1]
    if t then
        local want = active_choice(classname, t.level)
        local pick = t.choices[1]
        for _, ch in ipairs(t.choices) do if ch.choice == want then pick = ch end end
        self:Inspect(t, pick)
    else
        self.desc:SetPerk(nil, nil, classname)
    end
end

function VIEW:Think()
    if MySelf:Horde_GetCurrentSubclass() ~= self.cur_sub then self:Rebuild() end
end

function VIEW:PerformLayout(w, h)
    local gap = S(14)
    local colw = math.floor((w - gap) / 2)
    self.list:SetPos(0, 0)
    self.list:SetSize(colw, h)
    self.desc:SetPos(colw + gap, 0)
    self.desc:SetSize(w - colw - gap, h)
end

function VIEW:Paint() return true end

vgui.Register("HordeShopPerksView", VIEW, "DPanel")
