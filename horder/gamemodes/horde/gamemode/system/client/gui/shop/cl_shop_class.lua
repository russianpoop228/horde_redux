if not CLIENT then return end

local UI = HORDE.ShopUI
local C = UI.C
local S, SB = UI.S, UI.SB

local function FormatExpMultiplier(mult)
    local s = string.format("%.2f", mult)
    s = s:gsub("0+$", "")
    s = s:gsub("%.$", "")
    return "x" .. s
end

local function fmt_percent(v)
    local r = math.Round(v * 1000) / 10
    if r == math.floor(r) then return tostring(math.floor(r)) .. "%" end
    return tostring(r) .. "%"
end

local function fmt_number(v)
    if type(v) ~= "number" then return tostring(v) end
    local r = math.Round(v * 100) / 100
    if r == math.floor(r) then return tostring(math.floor(r)) end
    return tostring(r)
end

function UI.FormatParams(text, params, default_class)
    if not params then return text end
    for i, v in pairs(params) do
        local token = "{" .. tostring(i) .. "}"
        if string.find(text, token, 1, true) then
            local value, percent
            if type(v) == "table" then
                if v.level then
                    local lvl = MySelf:Horde_GetLevel(v.classname or default_class) or 0
                    value = math.min(v.max or math.huge, (v.base or 0) + lvl * v.level)
                else
                    value = v.value
                end
                percent = v.percent
            else
                value = v
            end
            local shown
            if percent and type(value) == "number" then
                shown = fmt_percent(value)
            else
                shown = fmt_number(value)
            end
            text = string.Replace(text, token, shown)
        end
    end
    return text
end

function UI.BasePerkText(sub)
    if not sub then return nil end
    local perk = HORDE.perks and HORDE.perks[sub.BasePerk]
    if not perk then return nil end
    local text = UI.T("Perk_" .. sub.BasePerk, perk.Description or "")
    return UI.FormatParams(text, perk.Params, sub.PrintName)
end

function UI.ParseClassText(text)
    local out = { desc = {}, complexity = nil, paras = {} }
    text = string.Replace(tostring(text or ""), "\r", "")

    local paras, cur = {}, {}
    for _, line in ipairs(string.Explode("\n", text, false)) do
        local t = string.Trim(line)
        if t == "" then
            if #cur > 0 then paras[#paras + 1] = cur; cur = {} end
        else
            cur[#cur + 1] = t
        end
    end
    if #cur > 0 then paras[#paras + 1] = cur end

    for idx, para in ipairs(paras) do
        local kept = {}
        for _, line in ipairs(para) do
            local val = string.match(string.lower(line), "^complexity%s*:%s*(.-)%s*$")
            if val and not out.complexity then
                out.complexity = val
            else
                kept[#kept + 1] = line
            end
        end
        if idx == 1 and #kept > 0 then
            local looks_like_stats = false
            for _, l in ipairs(kept) do
                if string.match(l, "^[%+%-]?%d") then looks_like_stats = true end
            end
            if looks_like_stats then
                out.paras[#out.paras + 1] = kept
            else
                out.desc = kept
            end
        elseif #kept > 0 then
            out.paras[#out.paras + 1] = kept
        end
    end
    return out
end

function UI.StatSegments(line, f_main, f_bold, f_dim)
    local segs = {}
    local before, paren, after = string.match(line, "^(.-)(%b())(.*)$")
    local main = before or line
    local num, rest = string.match(main, "^([%+%-]?%d[%d%.,]*%%?)(.*)$")
    if num then
        segs[#segs + 1] = { text = num, font = f_bold, col = C.WH }
        segs[#segs + 1] = { text = rest, font = f_main, col = C.WH }
    else
        segs[#segs + 1] = { text = main, font = f_main, col = C.WH }
    end
    if paren then
        segs[#segs + 1] = { text = " " .. paren, font = f_dim, col = C.DIM }
        if after and string.find(after, "%S") then
            segs[#segs + 1] = { text = after, font = f_main, col = C.WH }
        end
    end
    return segs
end

local VIEW = {}

local function random_perk_icon()
    local name = MySelf:Horde_GetCurrentSubclass()
    local sub = name and HORDE.subclasses and HORDE.subclasses[name]
    if not sub then return UI.Mat("star.png") end

    local parent = sub.ParentClass or sub.PrintName
    local cls = HORDE.classes and HORDE.classes[parent]
    local perks = sub.ParentClass and sub.Perks or (cls and cls.perks)
    if not perks then return UI.Mat(sub.Icon) or UI.Mat("star.png") end

    local icons = {}
    for _, v in pairs(perks) do
        if v and v.choices then
            for _, perk_name in pairs(v.choices) do
                local perk = HORDE.perks and HORDE.perks[perk_name]
                if perk and perk.Icon then
                    local m = UI.Mat(perk.Icon)
                    if m then icons[#icons + 1] = m end
                end
            end
        end
    end
    if #icons == 0 then return UI.Mat(sub.Icon) or UI.Mat("star.png") end
    return icons[math.random(1, #icons)]
end

function VIEW:Init()
    self.cache_key = nil
    self.badge_anim = UI.Tween(0, 0.2)
    self.perk_icon = random_perk_icon()
    self.scroll = 0
    self.scroll_target = 0
    self.content_h = 0
    self.viewport_h = 0

    self.btn_perks = vgui.Create("HordeUIButton", self)
    self.btn_perks.Draw = function(p, w, h, f)
        self:DrawNav(p, w, h, f, UI.T("Shop_UI_Perks", "Perks"), self.perk_icon or UI.Mat("star.png"), C.WH)
    end
    self.btn_perks.OnClick = function() if self.shop then self.shop:ShowView("perks") end end

    self.btn_shop = vgui.Create("HordeUIButton", self)
    self.btn_shop.Draw = function(p, w, h, f) self:DrawNav(p, w, h, f, UI.T("Shop_UI_Shop", "Shop"), UI.Mat("status/canbuy.png"), C.WH) end
    self.btn_shop.OnClick = function() if self.shop then self.shop:ShowView("shop") end end
end

function VIEW:OnMouseWheeled(delta)
    local max = math.max(0, (self.content_h or 0) - (self.viewport_h or 0))
    if max <= 0 then return end
    self.scroll_target = math.Clamp((self.scroll_target or 0) - delta * S(28), 0, max)
    return true
end

function VIEW:Think()
    local max = math.max(0, (self.content_h or 0) - (self.viewport_h or 0))
    self.scroll_target = math.Clamp(self.scroll_target or 0, 0, max)
    local cur = self.scroll or 0
    if math.abs(cur - self.scroll_target) > 0.5 then
        self.scroll = Lerp(FrameTime() * 14, cur, self.scroll_target)
    else
        self.scroll = self.scroll_target
    end
end

function VIEW:DrawNav(p, w, h, f, label, icon, icon_col)
    local th = SB(1.5)
    UI.Pill(0, 0, w, h, C.RED)
    UI.Pill(th, th, w - th * 2, h - th * 2, UI.Mix(C.WIN, C.CARD, f))
    UI.Text(label, UI.Font(16, false), S(20), h / 2, C.WH)
    local is = S(20)
    UI.DrawMat(icon, w - S(20) - is, (h - is) / 2, is, is, icon_col)
end

function VIEW:PerformLayout(w, h)
    local gap = S(10)
    local bh = S(40)
    local perks_on = GetConVar("horde_enable_perk") and GetConVar("horde_enable_perk"):GetInt() == 1
    local y = h - bh
    if perks_on then
        local bw = math.floor((w - gap) / 2)
        self.btn_perks:SetVisible(true)
        self.btn_perks:SetPos(0, y)
        self.btn_perks:SetSize(bw, bh)
        self.btn_shop:SetPos(bw + gap, y)
        self.btn_shop:SetSize(w - bw - gap, bh)
    else
        self.btn_perks:SetVisible(false)
        self.btn_shop:SetPos(0, y)
        self.btn_shop:SetSize(w, bh)
    end
end

function VIEW:Rebuild(w)
    local name = MySelf:Horde_GetCurrentSubclass()
    local sub = name and HORDE.subclasses and HORDE.subclasses[name]
    local lvl = name and MySelf:Horde_GetLevel(name) or 0
    local key = tostring(name) .. "|" .. w .. "|" .. lvl .. "|" .. UI.k
    if key == self.cache_key then return end
    local prefix = tostring(name) .. "|"
    if not self.cache_key or string.sub(self.cache_key, 1, #prefix) ~= prefix then
        self.perk_icon = random_perk_icon()
        self.badge_inited = false
        self.scroll = 0
        self.scroll_target = 0
    end
    self.cache_key = key

    local c = { name = name, sub = sub }
    local f_title = UI.Font(32, true)
    local f_desc  = UI.Font(13.5, false)
    local f_main  = UI.Font(13.5, false)
    local f_bold  = UI.Font(13.5, true)
    local f_dim   = UI.Font(12, false)

    c.title = UI.Upper(sub and UI.T("Class_" .. name, UI.T("Subclass_Title_" .. name, name)) or "")
    c.f_title = f_title

    local text = sub and UI.BasePerkText(sub)
    if not text or text == "" then
        local cls = MySelf:Horde_GetClass()
        text = UI.T("Class_Description_" .. tostring(name),
            (cls and cls.extra_description ~= "" and cls.extra_description) or (sub and sub.Description) or "")
    end
    local parsed = UI.ParseClassText(text)

    local desc_text = table.concat(parsed.desc, " ")
    if desc_text == "" and sub then
        desc_text = string.Trim(UI.T("Subclass_" .. tostring(sub.Description), sub.Description or ""))
        desc_text = string.gsub(desc_text, "%s*\n%s*", " ")
    end
    c.desc_lines = UI.Wrap(desc_text, f_desc, math.min(S(600), w - S(40)))
    c.f_desc = f_desc

    c.complexity = parsed.complexity and UI.Upper(parsed.complexity) or nil
    c.f_comp, c.f_comp_b = UI.Font(12, false), UI.Font(12, true)

    c.stats = {}
    local maxw = math.min(w - S(40), S(780))
    for pi, para in ipairs(parsed.paras) do
        for li, line in ipairs(para) do
            local segs
            if pi == 1 then
                segs = UI.StatSegments(line, f_main, f_bold, f_dim)
            else
                segs = { { text = line, font = f_main, col = C.DIM } }
            end
            c.stats[#c.stats + 1] = {
                lines = UI.RichWrap(segs, maxw),
                gap_before = (pi > 1 and li == 1) and S(4) or 0,
            }
        end
    end

    if name then
        c.rank = MySelf:Horde_GetRank(name)
        c.rank_level = MySelf:Horde_GetRankLevel(name)
        c.rank_text = UI.T("Rank_" .. tostring(c.rank), tostring(c.rank)) .. " " .. tostring(c.rank_level)
        c.rank_col = (HORDE.Rank_Colors and HORDE.Rank_Colors[c.rank]) or C.WH
        c.icon = sub and UI.Mat(sub.Icon)
    end
    self.c = c
end

function VIEW:Paint(w, h)
    self:Rebuild(w)
    local c = self.c
    if not c or not c.sub then return true end

    local bottom_h = S(40) + S(8) + S(42) + S(10)
    local viewport_top = 0
    local viewport_h = h - bottom_h
    self.viewport_h = viewport_h

    local lh = S(19)
    local y_measure = S(10)
    local lh_title = S(38)
    y_measure = y_measure + lh_title + S(4)
    y_measure = y_measure + #c.desc_lines * lh + S(3)
    if c.complexity then y_measure = y_measure + S(16) end
    y_measure = y_measure + S(20)
    for _, st in ipairs(c.stats) do
        y_measure = y_measure + st.gap_before
        y_measure = y_measure + #st.lines * lh + S(8)
    end
    self.content_h = y_measure

    local max_scroll = math.max(0, self.content_h - viewport_h)
    self.scroll_target = math.Clamp(self.scroll_target or 0, 0, max_scroll)
    self.scroll = math.Clamp(self.scroll or 0, 0, max_scroll)
    local sc = self.scroll

    local scissor_ok = false
    if render and render.SetScissorRect then
        local sx, sy = self:LocalToScreen(0, viewport_top)
        local _, sy2 = self:LocalToScreen(0, viewport_top + viewport_h)
        render.SetScissorRect(sx, sy, sx + w, sy2, true)
        scissor_ok = true
    end

    local y = S(10) - sc
    UI.SpacedText(c.title, c.f_title, w / 2, y + lh_title / 2, C.RED_TXT, S(2), "center")
    y = y + lh_title + S(4)

    for i, l in ipairs(c.desc_lines) do
        UI.Text(l, c.f_desc, w / 2, y + (i - 0.5) * lh, C.WH, TEXT_ALIGN_CENTER)
    end
    y = y + #c.desc_lines * lh + S(3)

    if c.complexity then
        local lab = UI.T("Shop_UI_Complexity", "Complexity") .. ": "
        surface.SetFont(c.f_comp)
        local lw = surface.GetTextSize(lab)
        surface.SetFont(c.f_comp_b)
        local vw = surface.GetTextSize(c.complexity)
        local x0 = w / 2 - (lw + vw) / 2
        UI.Text(lab, c.f_comp, x0, y + S(8), C.DIM)
        UI.Text(c.complexity, c.f_comp_b, x0 + lw, y + S(8), C.WH)
        y = y + S(16)
    end
    y = y + S(20)

    for _, st in ipairs(c.stats) do
        y = y + st.gap_before
        local sh = #st.lines * lh
        if y + sh >= viewport_top - S(4) and y <= viewport_top + viewport_h + S(4) then
            UI.DrawRichLines(st.lines, w / 2, y, lh, "center")
        end
        y = y + sh + S(8)
    end

    if scissor_ok then
        render.SetScissorRect(0, 0, 0, 0, false)
    end

    if max_scroll > 0 then
        local track_w = SB(3)
        local track_x = w - track_w - S(2)
        local track_y = viewport_top + S(4)
        local track_h = viewport_h - S(8)
        UI.Rect(0, track_x, track_y, track_w, track_h, C.TRACK)
        local ratio = viewport_h / self.content_h
        local bar_h = math.max(S(24), track_h * ratio)
        local bar_y = track_y + (track_h - bar_h) * (sc / max_scroll)
        UI.Rect(0, track_x, bar_y, track_w, bar_h, C.RED)
    end

    local ch = S(42)
    local cy = h - S(40) - S(8) - ch
    local r = ch / 2
    local th = SB(1.5)
    local badge_r = S(20)
    local core_r  = S(19)

    local lvl = MySelf:Horde_GetLevel(c.name) or 0
    local exp = MySelf:Horde_GetExp(c.name) or 0
    local need = HORDE:GetExpToNextLevel(lvl + 1)
    local progress
    if lvl >= (HORDE.max_level or 100) then
        progress = 1
    else
        progress = (need and need > 0) and math.Clamp(exp / need, 0, 1) or 0
    end

    local rank_font = UI.Font(16, true)
    local exp_font  = UI.Font(14, true)
    local rank_txt  = c.rank_text or ""
    local exp_text
    if lvl >= (HORDE.max_level or 100) then
        exp_text = "MAX"
    else
        exp_text = tostring(exp) .. "/" .. tostring(need) .. " " .. UI.T("Shop_UI_Exp", "EXP")
        if HORDE.hundred_mode or HORDE.unarmed_mode then
            local mult = HORDE.GetWaveExpMultiplier and HORDE:GetWaveExpMultiplier() or 1
            exp_text = exp_text .. " (" .. FormatExpMultiplier(mult) .. ")"
        end
    end
    surface.SetFont(rank_font)
    local rank_w = surface.GetTextSize(rank_txt)
    local pad = S(12)
    local bx_min = S(20) + rank_w + pad + badge_r
    local bx_max = w - S(20) - badge_r
    if bx_max < bx_min then
        local mid = (bx_min + bx_max) / 2
        bx_min, bx_max = mid, mid
    end

    if not self.badge_inited then
        self.badge_anim:Snap(progress)
        self.badge_inited = true
    else
        self.badge_anim:Set(progress)
    end
    local t = self.badge_anim:Get()
    local bx = math.floor(Lerp(t, bx_min, bx_max) + 0.5)
    local by = cy + r

    UI.Pill(0, cy, w, ch, C.RED)
    UI.Pill(th, cy + th, w - th * 2, ch - th * 2, C.WIN)

    local fill_w = bx
    if fill_w > th then
        UI.Pill(0, cy, math.min(w, fill_w + r), ch, C.RED)
    end

    UI.Text(rank_txt, rank_font, S(20), cy + r, C.WH)
    UI.Text(exp_text, exp_font, w - S(20), cy + r, C.WH, TEXT_ALIGN_RIGHT)

    UI.Circle(bx, by, badge_r, C.RED)
    UI.Circle(bx, by, core_r, C.WIN)
    local icon_d = badge_r * 2 * 0.76
    UI.DrawClassIcon(c.icon, bx, by, icon_d, c.rank_col)

    local star_mat = UI.Mat("star.png")
    local token_r = S(9)
    local token_col = Color(24, 25, 28, 255)
    local step = token_r * 2 + S(3)
    local right_x = bx - badge_r - S(4) - token_r
    if c.rank == HORDE.Rank_Master then
        local px = right_x
        local py = by
        UI.Circle(px, py, token_r, token_col)
        UI.Text(tostring(c.rank_level or 0), UI.Font(12, true), px, py, c.rank_col or C.WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        local stars = math.Clamp(c.rank_level or 0, 0, 4)
        for i = 1, stars do
            local px = right_x - (i - 1) * step
            local py = by
            UI.Circle(px, py, token_r, token_col)
            if star_mat then
                local ss = S(12)
                UI.DrawMat(star_mat, px - ss / 2, py - ss / 2, ss, ss, c.rank_col or C.WH)
            end
        end
    end
    return true
end

vgui.Register("HordeShopClassView", VIEW, "DPanel")
