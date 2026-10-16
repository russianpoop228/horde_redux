if not CLIENT then return end

HORDE.ShopUI = HORDE.ShopUI or {}
local UI = HORDE.ShopUI

UI.START_VIEW = "class"

UI.C = {
    RED         = Color(220, 30, 56),
    RED_H       = Color(240, 50, 76),
    RED_TXT     = Color(232, 39, 73),
    RED_DARK    = Color(112, 22, 36),
    WIN         = Color(31, 31, 31),
    CARD        = Color(60, 64, 70),
    CARD_H      = Color(72, 77, 84),
    BTN         = Color(66, 70, 78),
    BTN_H       = Color(80, 85, 94),
    TILE        = Color(38, 39, 43),
    TRACK       = Color(24, 25, 28),
    HALO        = Color(20, 21, 24),
    WH          = Color(255, 255, 255),
    DIM         = Color(150, 152, 158),
    GOLD        = Color(255, 190, 40),
    GREEN       = Color(0, 230, 118),
    LOCK_TXT    = Color(123, 126, 135),
    LOCK_BORDER = Color(46, 48, 55),
    LOCK_DISC   = Color(85, 88, 97),
}
local C = UI.C

UI.k = 1

function UI.S(v)
    return math.floor(v * UI.k + 0.5)
end

function UI.SB(v)
    return math.max(1, math.floor(v * UI.k + 0.5))
end

local font_cache = {}
function UI.Font(px, bold)
    local size = math.max(9, math.floor(px * UI.k + 0.5))
    local key = (bold and "B" or "R") .. size
    local name = "HordeShop_" .. key
    if not font_cache[key] then
        local family = bold and translate.GetBoldFont() or translate.GetFont()
        local fscale = tonumber(translate.Get("Default_Font_Scale")) or 1
        surface.CreateFont(name, {
            font = family,
            size = math.floor(size * fscale),
            weight = bold and 700 or 500,
            extended = true,
        })
        font_cache[key] = true
    end
    return name
end

function UI.T(key, fallback)
    local ok, v = pcall(translate.Get, key)
    if ok and v and v ~= "" then return v end
    return fallback
end

function UI.Upper(s)
    s = tostring(s or "")
    local ok, out = pcall(function()
        local t = {}
        for _, cp in utf8.codes(s) do
            if cp >= 0x61 and cp <= 0x7A then
                cp = cp - 32
            elseif cp >= 0x430 and cp <= 0x44F then
                cp = cp - 32
            elseif cp >= 0x450 and cp <= 0x45F then
                cp = cp - 80
            end
            t[#t + 1] = utf8.char(cp)
        end
        return table.concat(t)
    end)
    return ok and out or string.upper(s)
end

function UI.make_bezier(x1, y1, x2, y2)
    local cx = 3 * x1
    local bx = 3 * (x2 - x1) - cx
    local ax = 1 - cx - bx
    local cy = 3 * y1
    local by = 3 * (y2 - y1) - cy
    local ay = 1 - cy - by

    local function sx(t) return ((ax * t + bx) * t + cx) * t end
    local function sy(t) return ((ay * t + by) * t + cy) * t end
    local function dx(t) return (3 * ax * t + 2 * bx) * t + cx end

    return function(x)
        if x <= 0 then return 0 end
        if x >= 1 then return 1 end
        local t = x
        for _ = 1, 8 do
            local e = sx(t) - x
            if math.abs(e) < 1e-5 then return sy(t) end
            local d = dx(t)
            if math.abs(d) < 1e-6 then break end
            t = t - e / d
        end
        local lo, hi = 0, 1
        t = x
        for _ = 1, 24 do
            local e = sx(t) - x
            if math.abs(e) < 1e-5 then break end
            if e > 0 then hi = t else lo = t end
            t = (lo + hi) * 0.5
        end
        return sy(t)
    end
end

UI.Ease = UI.make_bezier(0.25, 0.1, 0.25, 1)

local Tween = {}
Tween.__index = Tween

function UI.Tween(initial, duration)
    return setmetatable({
        from = initial, to = initial, t0 = -1e9, dur = duration or 0.15,
    }, Tween)
end

function Tween:Get()
    local t = (SysTime() - self.t0) / self.dur
    if t >= 1 then return self.to end
    if t <= 0 then return self.from end
    return self.from + (self.to - self.from) * UI.Ease(t)
end

function Tween:Set(to, duration)
    if to == self.to then return end
    self.from = self:Get()
    self.to = to
    self.t0 = SysTime()
    if duration then self.dur = duration end
end

function Tween:Snap(v)
    self.from, self.to, self.t0 = v, v, -1e9
end

function Tween:Active()
    return (SysTime() - self.t0) < self.dur
end

function UI.Mix(a, b, f)
    f = math.Clamp(f, 0, 1)
    local aa, ba = a.a or 255, b.a or 255
    return Color(
        a.r + (b.r - a.r) * f,
        a.g + (b.g - a.g) * f,
        a.b + (b.b - a.b) * f,
        aa + (ba - aa) * f)
end

function UI.Alpha(col, a)
    return Color(col.r, col.g, col.b, math.Clamp((col.a or 255) * a, 0, 255))
end

function UI.Rect(r, x, y, w, h, col)
    if w <= 0 or h <= 0 then return end
    r = math.max(0, math.min(math.floor(r), math.floor(math.min(w, h) / 2)))
    draw.RoundedBox(r, math.floor(x), math.floor(y), math.ceil(w), math.ceil(h), col)
end

function UI.Pill(x, y, w, h, col)
    UI.Rect(math.floor(h / 2), x, y, w, h, col)
end

function UI.PillOutline(x, y, w, h, th, border, bg)
    UI.Pill(x, y, w, h, border)
    UI.Pill(x + th, y + th, w - th * 2, h - th * 2, bg)
end

function UI.Circle(cx, cy, r, col, seg)
    if r <= 0 then return end
    seg = seg or math.Clamp(math.floor(r * 2.8) + 24, 32, 96)
    local function poly_at(rr)
        local poly = {}
        for i = 0, seg - 1 do
            local a = math.rad((i / seg) * -360)
            poly[#poly + 1] = { x = cx + math.sin(a) * rr, y = cy + math.cos(a) * rr }
        end
        return poly
    end
    draw.NoTexture()
    local a0 = col.a or 255
    for pass = 3, 1, -1 do
        local aa = math.floor(a0 * (0.22 / pass))
        if aa > 0 then
            surface.SetDrawColor(col.r, col.g, col.b, aa)
            surface.DrawPoly(poly_at(r + pass * 0.55))
        end
    end
    surface.SetDrawColor(col)
    surface.DrawPoly(poly_at(r))
end

function UI.CircleOutline(cx, cy, r, th, border, bg)
    UI.Circle(cx, cy, r, border)
    UI.Circle(cx, cy, r - th, bg)
end

function UI.Text(str, font, x, y, col, ax, ay)
    draw.SimpleText(str, font, x, y, col, ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_CENTER)
end

function UI.SpacedText(str, font, x, cy, col, spacing, align)
    str = tostring(str or "")
    local chars = {}
    local ok = pcall(function()
        for _, cp in utf8.codes(str) do chars[#chars + 1] = utf8.char(cp) end
    end)
    if not ok or #chars == 0 then
        UI.Text(str, font, x, cy, col, align == "center" and TEXT_ALIGN_CENTER or TEXT_ALIGN_LEFT)
        return
    end
    surface.SetFont(font)
    local widths, total = {}, 0
    for i, ch in ipairs(chars) do
        widths[i] = (surface.GetTextSize(ch))
        total = total + widths[i] + (i < #chars and spacing or 0)
    end
    local px = (align == "center") and (x - total / 2) or x
    for i, ch in ipairs(chars) do
        draw.SimpleText(ch, font, math.floor(px), cy, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        px = px + widths[i] + spacing
    end
end

local mat_cache = {}
function UI.Mat(path)
    if not path or path == "" then return nil end
    local m = mat_cache[path]
    if m == nil then
        local ok, mat = pcall(Material, path, "smooth")
        if not (ok and mat and not mat:IsError()) then
            ok, mat = pcall(Material, path)
        end
        if ok and mat and not mat:IsError() then
            local mw, mh = mat:Width() or 0, mat:Height() or 0
            if mw > 32 or mh > 32 then
                local ok2, mat2 = pcall(Material, path, "mips smooth")
                if ok2 and mat2 and not mat2:IsError() then
                    mat = mat2
                end
            end
            m = mat
        else
            m = false
        end
        mat_cache[path] = m
    end
    return m or nil
end

function UI.DrawMat(mat, x, y, w, h, col)
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
    surface.SetDrawColor(col or C.WH)
    surface.DrawTexturedRect(math.floor(x), math.floor(y), math.ceil(w), math.ceil(h))
end

function UI.DrawPlaceholder(x, y, w, h, alpha)
    alpha = alpha or 1
    local s = math.min(w, h)
    UI.Text("?", UI.Font(math.max(10, math.floor(s / UI.k * 0.7)), true), x + w / 2, y + h / 2,
        UI.Alpha(C.WH, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

UI.CLASS_ICON_RING = 430 / 512
function UI.DrawClassIcon(mat, cx, cy, d, col)
    if not mat then return end
    local size = d / UI.CLASS_ICON_RING
    UI.DrawMat(mat, cx - size / 2, cy - size / 2, size, size, col)
end

function UI.WrapWith(measure, text, maxw)
    local lines = {}
    text = tostring(text or "")
    for _, para in ipairs(string.Explode("\n", text, false)) do
        if para == "" then
            lines[#lines + 1] = ""
        else
            local cur = ""
            for _, word in ipairs(string.Explode(" ", para, false)) do
                local try = (cur == "") and word or (cur .. " " .. word)
                if cur ~= "" and measure(try) > maxw then
                    lines[#lines + 1] = cur
                    cur = word
                else
                    cur = try
                end
            end
            lines[#lines + 1] = cur
        end
    end
    return lines
end

function UI.Wrap(text, font, maxw)
    surface.SetFont(font)
    return UI.WrapWith(function(s) return (surface.GetTextSize(s)) end, text, maxw)
end

function UI.Ellipsis(text, font, maxw)
    surface.SetFont(font)
    if (surface.GetTextSize(text)) <= maxw then return text end
    local s = text
    while #s > 1 and (surface.GetTextSize(s .. "...")) > maxw do
        s = string.sub(s, 1, #s - 1)
        while #s > 1 and (string.byte(s, #s) or 0) >= 0x80 and (string.byte(s, #s) or 0) < 0xC0 do
            s = string.sub(s, 1, #s - 1)
        end
    end
    return s .. "..."
end

function UI.RichWords(segs, measure)
    measure = measure or function(font, s)
        surface.SetFont(font)
        return (surface.GetTextSize(s))
    end
    local words = {}
    local prev_ws = false
    for _, seg in ipairs(segs) do
        local text = seg.text or ""
        local sp = measure(seg.font, " ")
        local pos = 1
        while true do
            local s, e = string.find(text, "%S+", pos)
            if not s then
                if string.find(string.sub(text, pos), "%s") then prev_ws = true end
                break
            end
            if s > pos then prev_ws = true end
            local w = string.sub(text, s, e)
            words[#words + 1] = {
                text = w, font = seg.font, col = seg.col,
                w = measure(seg.font, w), gap = sp, gap_before = prev_ws and #words > 0,
            }
            prev_ws = false
            pos = e + 1
        end
    end
    return words
end

function UI.RichWrap(segs, maxw, measure)
    local words = UI.RichWords(segs, measure)
    local lines, cur, curw = {}, {}, 0
    for _, w in ipairs(words) do
        local add = w.w + ((#cur > 0 and w.gap_before) and w.gap or 0)
        if #cur > 0 and curw + add > maxw then
            lines[#lines + 1] = { words = cur, w = curw }
            cur, curw = {}, 0
            add = w.w
        end
        cur[#cur + 1] = w
        curw = curw + add
    end
    if #cur > 0 then lines[#lines + 1] = { words = cur, w = curw } end
    return lines
end

function UI.DrawRichLines(lines, x, y, lh, align, alpha)
    alpha = alpha or 1
    for i, line in ipairs(lines) do
        local px = (align == "center") and (x - line.w / 2) or x
        local cy = y + (i - 0.5) * lh
        for j, w in ipairs(line.words) do
            if j > 1 and w.gap_before then px = px + w.gap end
            draw.SimpleText(w.text, w.font, math.floor(px), math.floor(cy), UI.Alpha(w.col, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            px = px + w.w
        end
    end
end

local HL2_MODELS = {
    weapon_crowbar    = "models/weapons/w_crowbar.mdl",
    weapon_stunstick  = "models/weapons/w_stunbaton.mdl",
    weapon_pistol     = "models/weapons/w_pistol.mdl",
    weapon_357        = "models/weapons/w_357.mdl",
    weapon_smg1       = "models/weapons/w_smg1.mdl",
    weapon_ar2        = "models/weapons/w_irifle.mdl",
    weapon_shotgun    = "models/weapons/w_shotgun.mdl",
    weapon_rpg        = "models/weapons/w_rocket_launcher.mdl",
    weapon_crossbow   = "models/weapons/w_crossbow.mdl",
    weapon_frag       = "models/weapons/w_grenade.mdl",
    weapon_slam       = "models/weapons/w_slam.mdl",
    weapon_physcannon = "models/weapons/w_physics.mdl",
    weapon_bugbait    = "models/weapons/w_bugbait.mdl",
}

local HL2_ICON_CLASSES = {
    weapon_crowbar = true, weapon_stunstick = true, weapon_pistol = true, weapon_357 = true,
    weapon_rpg = true, weapon_frag = true, weapon_slam = true, weapon_smg1 = true,
    weapon_shotgun = true, weapon_ar2 = true, weapon_physcannon = true,
    weapon_crossbow = true, weapon_bugbait = true,
}

local model_cache = {}

local function accept_model(path)
    if not isstring(path) or path == "" then return nil end
    if util.IsValidModel(path) then return path end
    local lower = string.lower(path)
    if string.sub(lower, -4) == ".mdl" then return path end
    return nil
end

function UI.GetItemModel(item)
    if not item or not item.class then return nil end
    local cached = model_cache[item.class]
    if cached ~= nil then return cached or nil end

    local result = false
    local ep = item.entity_properties
    local typ = ep and ep.type
    local no_model =
        (typ == HORDE.ENTITY_PROPERTY_GADGET) or
        (typ == HORDE.ENTITY_PROPERTY_ARMOR) or
        (typ == HORDE.ENTITY_PROPERTY_SPECIAL_UPGRADE) or
        (ep and ep.is_arccw_attachment)

    if not no_model then
        local mdl
        if typ == nil or typ == HORDE.ENTITY_PROPERTY_WPN then
            local wpn = weapons.Get(item.class) or weapons.GetStored(item.class)
            if wpn then
                local wm = wpn.WorldModel
                local vm = wpn.ViewModel
                if wpn.MirrorVMWM then
                    mdl = accept_model(vm) or accept_model(wm)
                else
                    mdl = accept_model(wm) or accept_model(vm)
                end
            end
            if not mdl and HL2_MODELS[item.class] then
                mdl = accept_model(HL2_MODELS[item.class])
            end
        elseif typ == HORDE.ENTITY_PROPERTY_DROP then
            local ent = scripted_ents.Get(item.class) or scripted_ents.GetStored(item.class)
            if ent then
                mdl = accept_model(ent.Model) or accept_model(ent.WorldModel)
            end
        end
        if mdl then result = mdl end
    end

    model_cache[item.class] = result
    return result or nil
end

local icon_cache = {}
function UI.GetItemIcon(item)
    if not item or not item.class then return nil end
    local cached = icon_cache[item.class]
    if cached ~= nil then return cached or nil end

    local class = item.class
    local ep = item.entity_properties
    local typ = ep and ep.type
    local result = false

    if ep and ep.is_arccw_attachment and ArcCW and ArcCW.AttachmentTable and ArcCW.AttachmentTable[class] then
        local ic = ArcCW.AttachmentTable[class].Icon
        if ic then result = { mat = ic } end
    end

    if not result and typ == HORDE.ENTITY_PROPERTY_GADGET then
        local g = HORDE.gadgets and HORDE.gadgets[class]
        local m = g and UI.Mat(g.Icon or "")
        if m then
            local col = C.WH
            if g.Active and g.Once then
                col = HORDE.color_gadget_once or col
            elseif g.Active then
                col = HORDE.color_gadget_active or col
            end
            result = { mat = m, col = col, gadget = true }
        end
    end

    if not result and item.shop_icon and item.shop_icon ~= "" then
        local m = UI.Mat(item.shop_icon)
        if m then result = { mat = m } end
    end

    if not result then
        local wpn = weapons.Get(class)
        if wpn then
            local icon = wpn.WepSelectIcon
            if type(icon) == "number" then
                if icon > 0 and icon ~= surface.GetTextureID("weapons/swep") then
                    result = { tex = icon }
                end
            elseif icon ~= nil and TypeID(icon) == TYPE_MATERIAL then
                result = { mat = icon }
            end
            if not result and wpn.ArcCW then
                local mat = Material("arccw/weaponicons/" .. class)
                local tex = mat and mat:GetTexture("$basetexture")
                if tex and tex:GetName() ~= "error" then
                    result = { tex = surface.GetTextureID(tex:GetName()) }
                end
            end
        elseif HL2_ICON_CLASSES[class] then
            local m = UI.Mat("items/hl2/" .. class .. ".png")
            if m then result = { mat = m } end
        end
    end

    icon_cache[class] = result
    return result or nil
end

UI.GADGET_ICON_SCALE = 2

function UI.DrawItemIcon(icon, x, y, w, h, alpha)
    if not icon then return end
    alpha = alpha or 1
    if icon.mat then
        local col = icon.col or C.WH
        if icon.gadget then
            local scale = UI.GADGET_ICON_SCALE or 2
            local cx, cy = x + w / 2, y + h / 2
            w, h = w * scale, h * scale
            x, y = cx - w / 2, cy - h / 2
        end
        UI.DrawMat(icon.mat, x, y, w, h, UI.Alpha(col, alpha))
    elseif icon.tex then
        local dw, dh = w, w / 2
        if dh > h then dh = h; dw = h * 2 end
        surface.SetTexture(icon.tex)
        surface.SetDrawColor(255, 255, 255, 255 * alpha)
        surface.DrawTexturedRect(math.floor(x + (w - dw) / 2), math.floor(y + (h - dh) / 2), math.ceil(dw), math.ceil(dh))
    end
end

function UI.FitDistance(mn, mx, fov)
    local radius = (mx - mn):Length() * 0.5
    if radius < 1 then radius = 1 end
    local dist = radius / math.tan(math.rad(fov * 0.5))
    return dist * 1.3, (mn + mx) * 0.5, radius
end

function UI.ParentsAlpha(p)
    local a = 1
    while IsValid(p) do
        a = a * (p:GetAlpha() / 255)
        p = p:GetParent()
    end
    return a
end

do
    local BTN = {}

    function BTN:Init()
        self:SetText("")
        self.hov = UI.Tween(0, 0.15)
        self.disabled = false
    end

    function BTN:Paint(w, h)
        self.hov:Set((self:IsHovered() and not self.disabled) and 1 or 0)
        if self.Draw then self:Draw(w, h, self.hov:Get()) end
        return true
    end

    function BTN:OnCursorEntered()
        if self.disabled or self.silent then return end
        surface.PlaySound("UI/buttonrollover.wav")
    end

    function BTN:DoClick()
        if self.disabled then return end
        if not self.silent then surface.PlaySound("UI/buttonclick.wav") end
        if self.OnClick then self:OnClick() end
    end

    vgui.Register("HordeUIButton", BTN, "DButton")
end

do
    local VS = {}

    function VS:Init()
        self.cur, self.target = 0, 0
        self.content_h = 0
        self.side = "right"
        self.bar_px = 6
        self.gap_px = 4
        self.step = 64
        self.hx, self.hy = nil, nil
        self:SetMouseInputEnabled(true)
    end

    function VS:SetSide(side) self.side = side end

    function VS:BarW() return UI.SB(self.bar_px) end
    function VS:BarGap() return UI.S(self.gap_px) end

    function VS:ContentX()
        if self.side == "left" then return self:BarW() + self:BarGap() end
        return 0
    end

    function VS:ContentW()
        return math.max(1, self:GetWide() - self:BarW() - self:BarGap())
    end

    function VS:SetContentHeight(h)
        self.content_h = math.max(0, h)
        self.target = math.Clamp(self.target, 0, self:MaxScroll())
        self.cur = math.Clamp(self.cur, 0, self:MaxScroll())
    end

    function VS:MaxScroll()
        return math.max(0, self.content_h - self:GetTall())
    end

    function VS:ScrollTo(y, instant)
        self.target = math.Clamp(y, 0, self:MaxScroll())
        if instant then self.cur = self.target end
    end

    function VS:Scroll()
        return math.floor(self.cur + 0.5)
    end

    function VS:OnMouseWheeled(delta)
        if self:MaxScroll() <= 0 then return false end
        self.target = math.Clamp(self.target - delta * UI.S(self.step), 0, self:MaxScroll())
        return true
    end

    function VS:Thumb()
        local H = self:GetTall()
        local max = self:MaxScroll()
        if max <= 0 or self.content_h <= 0 then return nil end
        local th = math.max(UI.S(24), H * H / self.content_h)
        local ty = (H - th) * (self.cur / max)
        return ty, th
    end

    function VS:BarHit(mx)
        local bw, pad = self:BarW(), UI.S(3)
        if self.side == "left" then return mx >= 0 and mx <= bw + pad end
        return mx >= self:GetWide() - bw - pad
    end

    function VS:OnMousePressed(code)
        local mx, my = self:CursorPos()
        if code == MOUSE_LEFT and self:BarHit(mx) then
            local ty, th = self:Thumb()
            if not ty then return end
            self.drag_off = (my >= ty and my <= ty + th) and (my - ty) or (th / 2)
            self.dragging = true
            self:MouseCapture(true)
            return
        end
        if self.ContentPressed then
            self:ContentPressed(mx - self:ContentX(), my + self:Scroll(), code)
        end
    end

    function VS:OnMouseReleased()
        if self.dragging then
            self.dragging = false
            self:MouseCapture(false)
        end
    end

    function VS:Think()
        if self.dragging then
            if not input.IsMouseDown(MOUSE_LEFT) then
                self:OnMouseReleased()
            else
                local _, my = self:CursorPos()
                local _, th = self:Thumb()
                if th then
                    local free = self:GetTall() - th
                    if free > 0 then
                        self.target = math.Clamp((my - self.drag_off) / free, 0, 1) * self:MaxScroll()
                        self.cur = self.target
                    end
                end
            end
        end

        if math.abs(self.cur - self.target) > 0.2 then
            self.cur = Lerp(1 - math.exp(-FrameTime() * 18), self.cur, self.target)
        else
            self.cur = self.target
        end

        local hovered = (vgui.GetHoveredPanel() == self) or self.dragging
        if hovered then
            local mx, my = self:CursorPos()
            if self:BarHit(mx) then
                self.hx, self.hy = nil, nil
            else
                self.hx, self.hy = mx - self:ContentX(), my + self:Scroll()
            end
        else
            self.hx, self.hy = nil, nil
        end
        self.bar_hot = hovered and self:BarHit((self:CursorPos()))
        if self.OnThink then self:OnThink() end
    end

    function VS:Paint(w, h)
        if self.PaintContent then
            self:PaintContent(self:ContentW(), h, self:ContentX(), -self:Scroll())
        end
        local ty, th = self:Thumb()
        if ty then
            local bw = self:BarW()
            local bx = (self.side == "left") and 0 or (w - bw)
            UI.Rect(UI.S(4), bx, 0, bw, h, C.TRACK)
            UI.Rect(UI.S(4), bx, math.floor(ty), bw, math.ceil(th),
                (self.dragging or self.bar_hot) and C.RED_H or C.RED)
        end
        return true
    end

    UI.VScrollInit = VS.Init

    vgui.Register("HordeUIVScroll", VS, "DPanel")
end

do
    local PV = {}

    function PV:Init()
        self.fade = UI.Tween(1, 0.18)
        self.kind = nil
        self.item = nil
    end

    function PV:MakeModelPanel()
        local mp = vgui.Create("DModelPanel", self)
        mp:SetMouseInputEnabled(false)
        mp:SetFOV(30)
        mp:SetAmbientLight(Color(110, 110, 110))
        mp:SetCamPos(Vector(60, 0, 20))
        mp:SetLookAt(vector_origin)
        mp.preview = self

        function mp:LayoutEntity(ent)
            if not IsValid(ent) then return end
            if self.fit_model ~= ent:GetModel() then
                self.fit_model = ent:GetModel()
                local mn, mx = ent:GetRenderBounds()
                self.fit_dist, self.fit_center = UI.FitDistance(mn, mx, self:GetFOV())
            end
            local ang = Angle(0, (SysTime() * 55) % 360, 0)
            ent:SetAngles(ang)
            local c = Vector(self.fit_center.x, self.fit_center.y, self.fit_center.z)
            c:Rotate(ang)
            ent:SetPos(-c)
            self:SetCamPos(Vector(self.fit_dist, 0, self.fit_dist * 0.32))
            self:SetLookAt(vector_origin)

            local a = UI.ParentsAlpha(self:GetParent()) * self.preview.fade:Get()
            self:SetAlpha(math.floor(255 * math.Clamp(a, 0, 1)))
        end

        self.mp = mp
        return mp
    end

    function PV:PerformLayout(w, h)
        if IsValid(self.mp) then self.mp:SetSize(w, h) end
    end

    function PV:SetItem(item)
        self.item = item
        self.icon = nil
        self.fade:Snap(0.2)
        self.fade:Set(1)

        local mdl = item and UI.GetItemModel(item)
        if mdl then
            if not IsValid(self.mp) then self:MakeModelPanel() end
            self.mp.fit_model = nil
            self.mp:SetModel(mdl)
            self.mp:SetSize(self:GetWide(), self:GetTall())
            self.mp:SetVisible(true)
            self.kind = "model"
            return
        end

        if IsValid(self.mp) then self.mp:SetVisible(false) end
        local icon = item and UI.GetItemIcon(item)
        if icon then
            self.kind, self.icon = "icon", icon
        else
            self.kind = "placeholder"
        end
    end

    function PV:Paint(w, h)
        local a = math.Clamp(self.fade:Get(), 0, 1)
        UI.Circle(w / 2, h / 2, UI.S(38), UI.Alpha(C.HALO, 1))

        if self.kind == "icon" then
            local box = UI.S(66)
            UI.DrawItemIcon(self.icon, (w - box) / 2, (h - box) / 2, box, box, a)
        elseif self.kind == "placeholder" then
            local box = UI.S(56)
            UI.DrawPlaceholder((w - box) / 2, (h - box) / 2, box, box, a)
        end
        return true
    end

    vgui.Register("HordeUIPreview", PV, "DPanel")
end

do
    local MD = {}

    function MD:Init()
        self.fade = UI.Tween(0, 0.2)
        self.closing = false
        self:SetMouseInputEnabled(true)
    end

    function MD:Setup(opts)
        self.opts = opts
        local W = UI.S(380)
        local padx, pady = UI.S(24), UI.S(20)
        local gap = UI.S(14)
        local inner = W - padx * 2

        local f_head = UI.Font(24, true)
        local f_text = UI.Font(13.5, false)
        local f_dim  = UI.Font(12.5, false)
        local f_row  = UI.Font(15, true)
        local f_bal  = UI.Font(13, false)
        local f_btn  = UI.Font(14.5, true)

        local layout = {}
        local y = pady
        local function push(kind, h, extra)
            local e = extra or {}
            e.kind, e.y, e.h = kind, y, h
            layout[#layout + 1] = e
            y = y + h + gap
        end

        if opts.heading then
            surface.SetFont(f_head)
            local _, hh = surface.GetTextSize("Ag")
            push("heading", hh)
        end
        if opts.lines then
            local lh = UI.S(19)
            local all = {}
            for _, l in ipairs(opts.lines) do
                for _, w in ipairs(UI.Wrap(l, f_text, inner)) do all[#all + 1] = w end
            end
            if #all > 7 then
                local cut = {}
                for i = 1, 7 do cut[i] = all[i] end
                cut[7] = cut[7] .. "..."
                all = cut
            end
            push("text", #all * lh, { lines = all, lh = lh })
        end
        if opts.dim then
            local lh = UI.S(17)
            local all = UI.Wrap(opts.dim, f_dim, inner)
            if #all > 4 then
                local cut = {}
                for i = 1, 4 do cut[i] = all[i] end
                cut[4] = cut[4] .. "..."
                all = cut
            end
            push("dim", #all * lh, { lines = all, lh = lh })
        end
        if opts.row then push("row", UI.S(40)) end
        if opts.balance then push("balance", UI.S(18)) end
        y = y - gap + UI.S(4)
        local btn_y = y
        local btn_h = UI.S(36)
        y = y + btn_h + pady

        local header_h = UI.S(36)
        local H = header_h + y

        local win = vgui.Create("DPanel", self)
        win:SetSize(W, H)
        self.win, self.win_w, self.win_h = win, W, H

        win.Paint = function(p, w, h)
            UI.Rect(UI.S(8), 0, 0, w, h, C.RED)
            UI.Rect(UI.S(6), UI.SB(2), UI.SB(2), w - UI.SB(4), h - UI.SB(4), C.WIN)
            UI.Rect(UI.S(6), UI.SB(2), UI.SB(2), w - UI.SB(4), header_h, C.RED)
            surface.SetDrawColor(C.RED)
            surface.DrawRect(UI.SB(2), UI.SB(2) + header_h / 2, w - UI.SB(4), header_h / 2)
            UI.Text(opts.title or "", UI.Font(15, true), UI.S(14), UI.SB(2) + header_h / 2, C.WH)
            UI.Text("X", UI.Font(14, true), w - UI.S(14), UI.SB(2) + header_h / 2,
                p.close_hot and UI.Alpha(C.WH, 0.65) or C.WH, TEXT_ALIGN_RIGHT)

            for _, e in ipairs(layout) do
                local ey = header_h + e.y
                if e.kind == "heading" then
                    UI.Text(opts.heading, f_head, w / 2, ey + e.h / 2, C.RED_TXT, TEXT_ALIGN_CENTER)
                elseif e.kind == "text" then
                    for i, l in ipairs(e.lines) do
                        UI.Text(l, f_text, w / 2, ey + (i - 0.5) * e.lh, C.WH, TEXT_ALIGN_CENTER)
                    end
                elseif e.kind == "dim" then
                    for i, l in ipairs(e.lines) do
                        UI.Text(l, f_dim, w / 2, ey + (i - 0.5) * e.lh, C.DIM, TEXT_ALIGN_CENTER)
                    end
                elseif e.kind == "row" then
                    UI.Rect(UI.S(8), padx, ey, inner, e.h, C.CARD)
                    UI.Rect(UI.S(8), padx + UI.SB(1), ey + UI.SB(1), inner - UI.SB(2), e.h - UI.SB(2), C.TRACK)
                    UI.Text(opts.row.label or "", f_row, padx + UI.S(18), ey + e.h / 2, C.WH)
                    local val = tostring(opts.row.value or "")
                    surface.SetFont(f_row)
                    local tw = surface.GetTextSize(val)
                    local rx = padx + inner - UI.S(18)
                    UI.Text(val, f_row, rx, ey + e.h / 2, C.RED_TXT, TEXT_ALIGN_RIGHT)
                    local m = opts.row.icon and UI.Mat(opts.row.icon)
                    if m then
                        local is = UI.S(18)
                        UI.DrawMat(m, rx - tw - is - UI.S(5), ey + (e.h - is) / 2, is, is, C.RED_TXT)
                    end
                elseif e.kind == "balance" then
                    UI.Text(opts.balance, f_bal, w / 2, ey + e.h / 2, C.DIM, TEXT_ALIGN_CENTER)
                end
            end
        end

        local cb = vgui.Create("DButton", win)
        cb:SetText("")
        cb:SetSize(UI.S(34), header_h)
        cb:SetPos(W - UI.S(34) - UI.SB(2), UI.SB(2))
        cb.Paint = function() end
        cb.OnCursorEntered = function() win.close_hot = true end
        cb.OnCursorExited = function() win.close_hot = false end
        cb.DoClick = function() surface.PlaySound("UI/buttonclick.wav") self:Close() end

        local bw = math.floor((inner - UI.S(10)) / 2)
        local by = header_h + btn_y

        local cancel = vgui.Create("HordeUIButton", win)
        cancel:SetPos(padx, by)
        cancel:SetSize(bw, btn_h)
        cancel.Draw = function(p, w, h, f)
            UI.Rect(UI.S(6), 0, 0, w, h, UI.Mix(C.BTN, C.BTN_H, f))
            UI.Text(opts.cancel or UI.T("Shop_UI_Cancel", "Cancel"), f_btn, w / 2, h / 2, C.WH, TEXT_ALIGN_CENTER)
        end
        cancel.OnClick = function() self:Close() end

        local ok = vgui.Create("HordeUIButton", win)
        ok:SetPos(padx + bw + UI.S(10), by)
        ok:SetSize(bw, btn_h)
        ok.disabled = (opts.can_confirm == false)
        ok.Draw = function(p, w, h, f)
            local txt = opts.confirm or "OK"
            local col
            if p.disabled then
                UI.Rect(UI.S(6), 0, 0, w, h, C.BTN)
                col = UI.Alpha(C.DIM, 0.6)
            else
                UI.Rect(UI.S(6), 0, 0, w, h, UI.Mix(C.RED, C.RED_H, f))
                col = C.WH
            end
            local m = opts.confirm_icon and UI.Mat(opts.confirm_icon)
            if m then
                surface.SetFont(f_btn)
                local tw = surface.GetTextSize(txt)
                local is = UI.S(15)
                local total = tw + UI.S(6) + is
                UI.Text(txt, f_btn, w / 2 - total / 2, h / 2, col)
                UI.DrawMat(m, w / 2 - total / 2 + tw + UI.S(6), (h - is) / 2, is, is, col)
            else
                UI.Text(txt, f_btn, w / 2, h / 2, col, TEXT_ALIGN_CENTER)
            end
        end
        ok.OnClick = function()
            local fn = opts.on_confirm
            self:Close()
            if fn then fn() end
        end

        self.fade:Snap(1)
        self:InvalidateLayout()
    end

    function MD:PerformLayout(w, h)
        if not IsValid(self.win) then return end
        self.base_x = math.floor((w - self.win_w) / 2)
        self.base_y = math.floor((h - self.win_h) / 2)
        self.win:SetPos(self.base_x, self.base_y)
    end

    function MD:Think()
        local a = self.fade:Get()
        self:SetAlpha(math.floor(255 * a))
        if IsValid(self.win) and self.base_x then
            self.win:SetPos(self.base_x, self.base_y + math.floor((1 - a) * UI.S(10)))
        end
        if self.closing and not self.fade:Active() then
            self:Remove()
        end
    end

    function MD:Close()
        if self.closing then return end
        self.closing = true
        self.fade:Snap(0)
        self:Remove()
    end

    function MD:OnMousePressed() self:Close() end

    function MD:Paint(w, h)
        surface.SetDrawColor(0, 0, 0, 190)
        surface.DrawRect(0, 0, w, h)
        return true
    end

    vgui.Register("HordeUIModal", MD, "DPanel")

    function UI.OpenModal(parent, opts)
        local m = vgui.Create("HordeUIModal", parent)
        m:SetPos(0, 0)
        m:SetSize(parent:GetWide(), parent:GetTall())
        m:SetZPos(1000)
        m:MoveToFront()
        m:Setup(opts)
        return m
    end
end
