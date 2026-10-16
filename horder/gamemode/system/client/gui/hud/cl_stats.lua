if not CLIENT then return end

HORDE = HORDE or {}

function HORDE_GetFixedValue(input)
    local target = 0.016666
    return input / (target / RealFrameTime())
end

function HORDE_GetTextSize(font, text)
    surface.SetFont(font)
    return surface.GetTextSize(text)
end

function HORDE_CreatePanel(parent, x, y, w, h, color, r)
    r = r || 0
    local panel = vgui.Create("DPanel", parent)
        panel:SetPos(x, y)
        panel:SetSize(w, h)
        panel.Paint2x = function() end
        panel.Paint = function()
            draw.RoundedBox(r, 0, 0, w, h, color)
            panel.Paint2x()
        end
        panel:SetZPos(0)
    return panel
end

function HORDE_CreateLabel(parent, x, y, text, font, color, bg, bgcolor)
    local label = vgui.Create("DLabel", parent)
        label.oPos = Vector(x, y)
        label:SetPos(x, y)
        label:SetFont(font)
        label:SetText(text)
        label:SetColor(color)
        local w, h = HORDE_GetTextSize(font, label:GetText())
        label:SetSize(w, h)

        label.CentHor = function()
            local w, h = HORDE_GetTextSize(font, label:GetText())
            label:SetPos(label.oPos.x - w / 2, label.oPos.y)
            label:SetSize(w, h)
        end

        label.CentVer = function()
            local w, h = HORDE_GetTextSize(font, label:GetText())
            label:SetPos(label.oPos.x, label.oPos.y - h / 2)
            label:SetSize(w, h)
        end

        label.CentPos = function()
            local w, h = HORDE_GetTextSize(font, label:GetText())
            label:SetPos(label.oPos.x - w / 2, label.oPos.y - h / 2)
            label:SetSize(w, h)
        end

        label.UpdateText = function(text)
            label:SetText(text)
            local w, h = HORDE_GetTextSize(font, label:GetText())
            label:SetSize(w, h)
        end

        if(bg) then
            label.oPaint = label.Paint
            label.Paint = function()
                draw.RoundedBox(0, 0, 0, label:GetWide(), label:GetTall(), bgcolor)
                label.oPaint(label)
            end
        end

    local tw, th = HORDE_GetTextSize(font, label:GetText())
    return tw, th, label
end

function HORDE_CreateScroll(parent, x, y, w, h, color)
    local frame = vgui.Create("DScrollPanel", parent)
    frame:SetPos(x, y)
    frame:SetSize(w, h)
    frame.Paint = function() draw.RoundedBox(0, 0, 0, w, h, color) end

    frame.ScrollAmount = ScreenScaleH(64)
    frame.Smoothing = 0.2

    frame.CurrrentScroll = 0
    frame.MaximumScroll = 0
    frame.Panels = {}

    frame.FiltePanels = function(searchString)
        for k,v in ipairs(frame.Panels) do
            if(!IsValid(v)) then
                table.remove(frame.Panels, k)
                continue
            end
            if(!v.SortString) then continue end
            if(string.find(v.SortString, searchString)) then
                if(!frame.HideAnimation) then
                    v:SetVisible(true)
                else
                    v.Display = true
                end
            else
                if(!frame.HideAnimation) then
                    v:SetVisible(false)
                    v.Display = false
                end
            end
            local t = v:GetTall()
            v:SetTall(t - 1)
            v:SetTall(t)
        end
    end

    frame.AddPanel = function(ui)
        table.insert(frame.Panels, ui)
    end

    local DVBar = frame:GetVBar()
    local down = false
    local clr = 0

    DVBar:SetWide(ScreenScaleH(4))
    DVBar:SetX(DVBar:GetX() - DVBar:GetWide())

    DVBar.Think = function()
        frame.MaximumScroll = DVBar.CanvasSize
        if(down) then return end
        local dvscroll = DVBar:GetScroll()
        local step = frame.CurrrentScroll - dvscroll
        if(math.abs(step) > 1) then
            clr = 125
        end
        DVBar:SetScroll(dvscroll + HORDE_GetFixedValue(step * frame.Smoothing))
    end

    function frame:OnMouseWheeled(delta)
        frame.CurrrentScroll = math.Clamp(frame.CurrrentScroll + frame.ScrollAmount * -delta, 0, frame.MaximumScroll)
    end

    function DVBar:Paint(drawW, drawH)
        draw.RoundedBox(0, 0, 0, drawW, drawH, Color(0, 0, 0, 150))
    end

    function DVBar.btnUp:Paint() return end
    function DVBar.btnDown:Paint() return end

    DVBar.btnGrip.oOnMousePressed = DVBar.btnGrip.OnMousePressed
    function DVBar.btnGrip.OnMousePressed(self, code)
        down = true
        DVBar.btnGrip.oOnMousePressed(self, code)
        frame.CurrrentScroll = DVBar:GetScroll()
    end
    DVBar.oOnMousePressed = DVBar.OnMousePressed
    function DVBar.OnMousePressed(self, code)
        down = true
        DVBar.oOnMousePressed(self, code)
    end

    function DVBar.btnGrip:Paint(drawW, drawH)
        local roundWide = drawW * 0.5
        if(DVBar.btnGrip:IsHovered()) then
            clr = math.Clamp(clr + HORDE_GetFixedValue(8), 0, 80)
            if(input.IsMouseDown(107) && !down) then
                down = true
            end
        else
            clr = math.Clamp(clr - HORDE_GetFixedValue(8), 0, 80)
        end

        if(down && !input.IsMouseDown(107)) then
            down = false
        end

        if(down) then
            frame.CurrrentScroll = DVBar:GetScroll()
            clr = 125
        end

        local _color = 130 + clr
        draw.RoundedBox(roundWide, 0, 0, drawW, drawH, Color(_color, _color, _color, 255))
    end
    return frame
end

function HORDE_InvisButton(parent, x, y, w, h, func)
    local btn = vgui.Create("DButton", parent)
        btn:SetPos(x, y)
        btn:SetSize(w, h)
        btn:SetText("")
        btn.Paint = function() end
        btn.DoClick = func

        return btn
end

local RED      = Color(209, 18, 55)
local RED_H    = Color(231, 40, 77)
local WIN      = Color(35, 35, 35)
local GREY     = Color(78, 78, 78)
local GREY_H   = Color(98, 98, 98)
local TRACK    = Color(16, 16, 16)
local WH       = Color(255, 255, 255)
local DIM      = Color(150, 152, 158)
local BLACK    = Color(0, 0, 0)

local BASE_W, BASE_H = 1266, 731
local K = 1

local function S(v) return math.floor(v * K + 0.5) end
local function SB(v) return math.max(1, S(v)) end

local fonts_made = {}
local function Font(px, bold)
    local size = math.max(9, S(px))
    local key = (bold and "B" or "R") .. size
    local name = "HordeF1_" .. key
    if not fonts_made[key] then
        local fscale = tonumber(translate.Get("Default_Font_Scale")) or 1
        surface.CreateFont(name, {
            font     = bold and translate.GetBoldFont() or translate.GetFont(),
            size     = math.floor(size * fscale),
            weight   = bold and 700 or 500,
            extended = true,
        })
        fonts_made[key] = true
    end
    return name
end

local function SndHover() surface.PlaySound("UI/buttonrollover.wav") end
local function SndClick() surface.PlaySound("UI/buttonclick.wav") end

local DATA_LANGS = { ru = true }

local function Lang()
    local cv = GetConVar("gmod_language")
    local l = cv and string.sub(string.lower(cv:GetString() or ""), 1, 2) or "en"
    return DATA_LANGS[l] and l or "en"
end

local function Loc(v)
    if istable(v) then return v[Lang()] or v.en end
    return v
end

local function T(key, ...)
    local v = translate.Get("F1_" .. key)
    if v == nil or v == "" then v = key end
    if select("#", ...) > 0 then
        local ok, res = pcall(string.format, v, ...)
        if ok then return res end
    end
    return v
end

local function TSoft(key, ...)
    local v = translate.Get("F1_" .. key)
    if v == nil or v == "" then return nil end
    if select("#", ...) > 0 then
        local ok, res = pcall(string.format, v, ...)
        if ok then return res end
    end
    return v
end

local function FitText(text, font, maxw)
    text = tostring(text or "")
    surface.SetFont(font)
    if (surface.GetTextSize(text)) <= maxw then return text end
    local len = utf8.len(text) or #text
    for n = len - 1, 1, -1 do
        local pos = utf8.offset(text, n + 1) or (#text + 1)
        local cut = string.sub(text, 1, pos - 1) .. "..."
        if (surface.GetTextSize(cut)) <= maxw then return cut end
    end
    return "..."
end

local function Wrap(text, font, maxw)
    surface.SetFont(font)
    local out = {}
    local function limit()
        if isfunction(maxw) then return maxw(#out + 1) end
        return maxw
    end
    for _, para in ipairs(string.Split(tostring(text or ""), "\n")) do
        if para == "" then
            out[#out + 1] = ""
        else
            local cur = ""
            for word in string.gmatch(para, "%S+") do
                local try = (cur == "") and word or (cur .. " " .. word)
                if (surface.GetTextSize(try)) <= limit() then
                    cur = try
                else
                    if cur ~= "" then out[#out + 1] = cur; cur = "" end
                    if (surface.GetTextSize(word)) > limit() then
                        local piece = ""
                        for _, cp in utf8.codes(word) do
                            local ch = utf8.char(cp)
                            if piece ~= "" and (surface.GetTextSize(piece .. ch)) > limit() then
                                out[#out + 1] = piece
                                piece = ""
                            end
                            piece = piece .. ch
                        end
                        cur = piece
                    else
                        cur = word
                    end
                end
            end
            out[#out + 1] = cur
        end
    end
    return out
end

local function IsLowerCP(cp) return (cp >= 0x61 and cp <= 0x7A) or (cp >= 0x430 and cp <= 0x45F) end
local function IsUpperCP(cp) return (cp >= 0x41 and cp <= 0x5A) or (cp >= 0x400 and cp <= 0x42F) end
local function LowerCP(cp)
    if cp >= 0x41 and cp <= 0x5A then return cp + 32 end
    if cp >= 0x410 and cp <= 0x42F then return cp + 32 end
    if cp >= 0x400 and cp <= 0x40F then return cp + 80 end
    return cp
end

local function TitleCase(s)
    s = tostring(s or "")
    local ok, res = pcall(function()
        local cps = {}
        for _, cp in utf8.codes(s) do
            if IsLowerCP(cp) then return s end
            cps[#cps + 1] = cp
        end
        local out, start = {}, true
        for _, cp in ipairs(cps) do
            if cp == 0x20 or cp == 0x5F or cp == 0x2D then
                start = true
                out[#out + 1] = utf8.char(cp == 0x5F and 0x20 or cp)
            else
                if IsUpperCP(cp) and not start then cp = LowerCP(cp) end
                start = false
                out[#out + 1] = utf8.char(cp)
            end
        end
        return table.concat(out)
    end)
    return ok and res or s
end

local function DiffLabel(name)
    return TitleCase(translate.Get("Game_Difficulty_" .. name) or name)
end

local function ServerKey(id)
    if not (HORDE and HORDE.GetGameplayControl) then return "" end
    local ok, _, key = pcall(HORDE.GetGameplayControl, HORDE, id)
    return ok and tostring(key or "") or ""
end

local function EffectiveKey(id)
    if not (HORDE and HORDE.GetEffectiveGameplayControl) then return "" end
    local ok, _, key = pcall(HORDE.GetEffectiveGameplayControl, HORDE, id)
    return ok and tostring(key or "") or ""
end

local function KeyLabel(key)
    key = tostring(key or "")
    if key == "" then return "—" end
    return (string.gsub(string.upper(key), "^MOUSE(%d)", "MOUSE %1"))
end

local function SubstKeys(text)
    return (string.gsub(text, "{([%w_]+)}", function(id)
        local k = ServerKey(id)
        return k ~= "" and string.upper(k) or "—"
    end))
end

local function ParseGuide(text)
    local blocks = {}
    for _, line in ipairs(string.Split(SubstKeys(text), "\n")) do
        line = string.gsub(line, "\r", "")
        if string.sub(line, 1, 2) == "# " then
            blocks[#blocks + 1] = { h = string.sub(line, 3) }
        elseif string.Trim(line) == "" then
            if #blocks > 0 and not blocks[#blocks].gap then blocks[#blocks + 1] = { gap = true } end
        else
            blocks[#blocks + 1] = { p = line }
        end
    end
    while #blocks > 0 and blocks[#blocks].gap do blocks[#blocks] = nil end
    return blocks
end

local TIP_COUNT = 14

local function RandomTip()
    local tip = translate.Get(string.format("F1_Tip%02d", math.random(TIP_COUNT)))
    return SubstKeys(tip or "")
end

local INFO = {}
local function I(name, hp, dmg, atk, resist)
    INFO[name] = { hp = hp, dmg = dmg, atk = atk, resist = resist }
end

local function EnemyTextKey(name, suffix)
    return "Enemy_" .. (string.gsub(tostring(name), "[^%w]", "_")) .. "_" .. suffix
end

I("Walker", 75, 15, nil)
I("Sprinter", 90, 20, nil)
I("Crawler", 30, 10, 0.6)
I("Fast Zombie", nil, nil, nil)
I("Poison Zombie", nil, nil, nil)
I("Zombine", 250, 25, nil)
I("Charred Zombine", 350, 35, nil, { fire = 0.5, cold = 1.25 })
I("Plague Soldier", 325, 30, nil)
I("Exploder", 350, nil, nil, { poison = 0.5, fire = 1.5, blast = 1.5 })
I("Vomitter", 125, 30, nil)
I("Scorcher", 250, 30, nil, { fire = 0.5, cold = 1.25 })
I("Screecher", 200, 20, nil, { lightning = 0.5, blast = 1.25 })
I("Blight", 700, nil, nil, { lightning = 1.5 })
I("Weeper", 350, 20, nil, { fire = 1.25, cold = 0.5, lightning = 0.75, blast = 1.25 })
I("Hulk", 1200, 57, nil)
I("Yeti", 1350, 50, nil, { fire = 1.25, cold = 0.5 })
I("Lesion", 1000, 40, 0.6)
I("Plague Elite", 1050, 30, nil)
I("Alpha Gonome", 7500, 40, 0.8)
I("Gamma Gonome", 7500, 40, 0.8)
I("Subject: Wallace Breen", 9000, 40, nil)
I("Xen Host Unit", 7000, 30, nil)
I("Xen Destroyer Unit", 8000, 30, nil)
I("Xen Psychic Unit", 7000, 30, nil)
I("Plague Platoon", 7750, nil, nil)
I("Plague Heavy", 4500, 30, nil)
I("Plague Demolition", 4250, 30, nil)
I("Plague Berserker", 5000, 30, nil)
I("Hell Knight", 6500, 30, 0.6)
I("Dead Hound", 10000, 20, 0.6)
I("Hunter", 4000, 40, nil)
I("Hunter Mega", 10000, 80, nil)
I("Mutated Hulk", 5500, 55, nil)
I("Build Buster", 4000, nil, nil)
I("Blue Prince", 2000, 40, nil)
I("Winter Knight", 6500, 30, nil)
I("Plague Sentry", nil, nil, nil)
I("Plague Watchtower", nil, nil, nil)

local VISUAL = {}
local LESION_MAT = "models/horde/lesion/lesion_sheet"
local HEADCRAB_ATTACH = { attach = "eyes", pos = Vector(-3, 0, -6) }
local function Headcrab(model, col, scale)
    return { model = model, color = col, scale = scale, attach = HEADCRAB_ATTACH.attach, pos = HEADCRAB_ATTACH.pos }
end

VISUAL.npc_vj_horde_walker        = { model = "models/vj_zombies/slow1.mdl" }
VISUAL.npc_vj_horde_sprinter      = { model = "models/vj_zombies/panic_carrier.mdl" }
VISUAL.npc_vj_horde_crawler       = { model = "models/vj_zombies/fast1.mdl" }
VISUAL.npc_fastzombie             = { model = "models/zombie/fast.mdl" }
VISUAL.npc_poisonzombie           = { model = "models/zombie/poison.mdl" }
VISUAL.npc_vj_horde_zombine       = { model = "models/vj_zombies/zombine.mdl", bg = { [1] = 1 } }
VISUAL.npc_vj_horde_charred_zombine = { model = "models/vj_zombies/zombine.mdl", bg = { [1] = 1 }, color = Color(125, 50, 50) }
VISUAL.npc_vj_horde_plague_soldier  = { model = "models/combine_soldier.mdl", scale = 1,
    extras = { Headcrab("models/headcrabblack.mdl", Color(255, 0, 0), 1.25) } }

VISUAL.npc_vj_horde_exploder  = { model = "models/zombie/classic.mdl", bg = { [1] = 1 }, color = Color(255, 0, 255), scale = 1.25 }
VISUAL.npc_vj_horde_blight    = { model = "models/zombie/classic.mdl", bg = { [1] = 1 }, color = Color(50, 50, 50), scale = 1.5 }
VISUAL.npc_vj_horde_vomitter  = { model = "models/horde/bloodsquid/bloodsquid.mdl", color = Color(200, 100, 100) }
VISUAL.npc_vj_horde_scorcher  = { model = "models/horde/bloodsquid/bloodsquid.mdl", color = Color(50, 50, 0), scale = 1.25 }
VISUAL.npc_vj_horde_screecher = { model = "models/horde/infected_stalker/infected_stalker.mdl" }
VISUAL.npc_vj_horde_weeper    = { model = "models/horde/infected_stalker/infected_stalker.mdl", color = Color(0, 150, 250), scale = 1.25 }
VISUAL.npc_vj_horde_hulk      = { model = "models/horde/hulk/hulk.mdl" }
VISUAL.npc_vj_horde_yeti      = { model = "models/horde/hulk/hulk.mdl", color = Color(0, 255, 255) }
VISUAL.npc_vj_horde_lesion    = { model = "models/vj_zombies/fast_main.mdl", submat = { [0] = LESION_MAT }, scale = 1.75 }
VISUAL.npc_vj_horde_plague_elite = { model = "models/combine_super_soldier.mdl", color = Color(50, 50, 50), scale = 1.25,
    extras = { Headcrab("models/headcrabblack.mdl", Color(255, 0, 0), 1.5) } }

VISUAL.npc_vj_horde_build_buster = { model = "models/vj_zombies/fast_main.mdl", submat = { [0] = LESION_MAT }, color = Color(255, 50, 50), scale = 1.75 }
VISUAL.npc_vj_horde_blue_prince  = { model = "models/vj_zombies/fast_main.mdl", submat = { [0] = LESION_MAT }, color = Color(70, 140, 255), scale = 1.75,
    extras = { { model = "models/player/items/demo/crown.mdl", bone = "ValveBiped.Bip01_Head1", pos = Vector(2, -2, 1), ang = Angle(90, 45, 0), scale = 1.05 } } }
VISUAL.npc_vj_horde_winterknight = { model = "models/vj_zombies/fast_main.mdl", color = Color(25, 25, 25), scale = 1.75 }
VISUAL.npc_vj_horde_plague_sentry     = { model = "models/combine_super_soldier.mdl", color = Color(50, 50, 50), scale = 1.25 }
VISUAL.npc_vj_horde_plague_watchtower = { model = "models/police.mdl", color = Color(50, 50, 50), scale = 1.25 }

VISUAL.npc_vj_alpha_gonome        = { model = "models/horde/gonome/gonome.mdl", skin = 1 }
VISUAL.npc_vj_horde_gamma_gonome  = { model = "models/horde/gonome/gonome.mdl", skin = 1, color = Color(0, 150, 255, 255) }
VISUAL.npc_vj_horde_breen         = { model = "models/horde/gonome/gonome.mdl", color = Color(148, 0, 211), scale = 1.25 }
VISUAL.npc_vj_horde_hellknight    = { model = "models/vj_zombies/fast_main.mdl", color = Color(25, 25, 25), scale = 1.75 }
VISUAL.npc_vj_horde_dead_hound    = { model = "models/vj_zombies/fast_main.mdl", submat = { [0] = LESION_MAT }, color = Color(90, 90, 90), scale = 1.9 }
VISUAL.npc_vj_horde_hunter        = { model = "models/hunter.mdl" }
VISUAL.npc_vj_horde_hunter_mega   = { model = "models/hunter.mdl", scale = 1.25 }
VISUAL.npc_vj_mutated_hulk        = { model = "models/horde/hulk/hulk.mdl", color = Color(255, 0, 255) }
VISUAL.npc_vj_horde_xen_destroyer_unit = { model = "models/horde/gargantua/gargantua.mdl", scale = 0.5 }
VISUAL.npc_vj_horde_xen_host_unit      = { model = "models/horde/gonarch/gonarch.mdl", scale = 0.75 }
VISUAL.npc_vj_horde_xen_psychic_unit   = { model = "models/horde/kingpin/kingpin.mdl" }
VISUAL.npc_vj_horde_platoon_heavy = { model = "models/combine_super_soldier.mdl", color = Color(100, 100, 100), scale = 1.25,
    extras = { Headcrab("models/headcrabblack.mdl", Color(100, 100, 100), 1.5) } }
VISUAL.npc_vj_horde_platoon_berserker = { model = "models/police.mdl", color = Color(150, 100, 100), scale = 1.25,
    extras = { Headcrab("models/headcrab.mdl", Color(150, 100, 100), 1.5) } }
VISUAL.npc_vj_horde_platoon_demolitionist = { model = "models/combine_soldier.mdl", color = Color(100, 100, 100), scale = 1.25,
    extras = { Headcrab("models/headcrabclassic.mdl", Color(100, 100, 100), 1.5) } }
VISUAL.npc_vj_horde_plague_platoon = VISUAL.npc_vj_horde_platoon_heavy

local function PM() return HORDE.PlayerMenu or {} end

local function DrawPill(x, y, w, h, col)
    draw.RoundedBox(math.floor(h / 2), x, y, w, h, col)
end

local function DrawPillOutline(x, y, w, h, border, inner)
    local b, r = SB(2), math.floor(h / 2)
    draw.RoundedBox(r, x, y, w, h, border)
    draw.RoundedBox(math.max(0, r - b), x + b, y + b, w - 2 * b, h - 2 * b, inner)
end

local function MakeButton(parent, paint, click)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b.Paint = paint
    b.DoClick = function(s) SndClick(); if click then click(s) end end
    b.OnCursorEntered = function() SndHover() end
    return b
end

local function HeaderPaint(text)
    return function(_, w, h)
        DrawPill(0, 0, w, h, RED)
        draw.SimpleText(FitText(Loc(text), Font(25), w - S(20)), Font(25), w / 2, h / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local SCROLL = {}

function SCROLL:Init()
    self.items, self.offset, self.max_off, self.content_h = {}, 0, 0, 0
    self.has_bar = false
    self.bar_mode, self.bar_gap, self.bar_w = "overlay", 0, SB(12)
    self.view_top, self.gap, self.pad_top = 0, S(8), 0
    self.view = vgui.Create("Panel", self)
    self.drag = nil
end

function SCROLL:Configure(o)
    for k, v in pairs(o) do self[k] = v end
    self:InvalidateLayout()
end

function SCROLL:AddItem(p)
    p:SetParent(self.view)
    self.items[#self.items + 1] = p
    self:InvalidateLayout()
end

function SCROLL:Clear()
    for _, it in ipairs(self.items) do if IsValid(it) then it:Remove() end end
    self.items, self.offset = {}, 0
    self:InvalidateLayout()
end

function SCROLL:Layout(cw, off, dry)
    local y, lastgap = self.pad_top, 0
    for _, it in ipairs(self.items) do
        if IsValid(it) then
            local ih = it.GetHeightFor and it:GetHeightFor(cw) or it.item_h or it:GetTall()
            if not dry then it:SetPos(0, y - off); it:SetSize(cw, ih) end
            lastgap = it.gap_after or self.gap
            y = y + ih + lastgap
        end
    end
    return math.max(0, y - lastgap)
end

function SCROLL:PerformLayout(w, h)
    if w < 2 or h < 2 then return end
    local bw, bg = self.bar_w, self.bar_gap
    local vh = h - self.view_top
    local cw = (self.bar_mode == "reserve") and (w - bw - bg) or w
    local ch = self:Layout(cw, 0, true)
    self.has_bar = ch > vh + 1
    self.content_h = ch
    self.max_off = math.max(0, ch - vh)
    self.offset = math.Clamp(self.offset, 0, self.max_off)
    self.view:SetPos(0, self.view_top)
    self.view:SetSize(cw, vh)
    self:Layout(cw, self.offset, false)
end

function SCROLL:SetOffset(o)
    o = math.Clamp(o, 0, self.max_off)
    if o == self.offset then return end
    self.offset = o
    self:InvalidateLayout(true)
end

function SCROLL:OnMouseWheeled(d)
    if not self.has_bar then return false end
    self:SetOffset(self.offset - d * (self.wheel_step or S(54)))
    return true
end

function SCROLL:Thumb()
    local w, h = self:GetSize()
    local vh = h - self.view_top
    local th = math.max(S(28), math.floor(h * vh / math.max(1, self.content_h)))
    local travel = math.max(1, h - th)
    local ty = (self.max_off > 0) and math.floor(travel * self.offset / self.max_off) or 0
    return w - self.bar_w, ty, th, travel
end

function SCROLL:Paint(w, h)
    if not self.has_bar then return end
    local bx, ty, th = self:Thumb()
    local r = math.floor(self.bar_w / 2)
    draw.RoundedBox(r, bx, 0, self.bar_w, h, TRACK)
    draw.RoundedBox(r, bx, ty, self.bar_w, th, RED)
end

function SCROLL:OnMousePressed(code)
    if code ~= MOUSE_LEFT or not self.has_bar then return end
    local mx, my = self:CursorPos()
    local bx, ty, th, travel = self:Thumb()
    if mx < bx - S(4) then return end
    if my >= ty and my <= ty + th then
        self.drag = { my = my, off = self.offset }
    else
        self:SetOffset(self.offset + ((my < ty) and -1 or 1) * (self:GetTall() - self.view_top))
        return
    end
    self:MouseCapture(true)
end

function SCROLL:OnMouseReleased() self.drag = nil; self:MouseCapture(false) end

function SCROLL:Think()
    if not self.drag then return end
    if not input.IsMouseDown(MOUSE_LEFT) then self:OnMouseReleased() return end
    local _, my = self:CursorPos()
    local _, _, _, travel = self:Thumb()
    self:SetOffset(self.drag.off + (my - self.drag.my) * self.max_off / math.max(1, travel))
end

vgui.Register("HordeF1Scroll", SCROLL, "Panel")

local HSCROLL = {}

function HSCROLL:Init()
    self.items, self.offset, self.max_off, self.content_w = {}, 0, 0, 0
    self.item_w, self.gap, self.row_h, self.bar_gap, self.bar_h = S(185), S(35), S(39), S(19), SB(10)
    self.has_bar = false
    self.view = vgui.Create("Panel", self)
end

function HSCROLL:Clear()
    for _, it in ipairs(self.items) do if IsValid(it) then it:Remove() end end
    self.items, self.offset = {}, 0
    self:InvalidateLayout()
end

function HSCROLL:AddItem(p)
    p:SetParent(self.view)
    self.items[#self.items + 1] = p
    self:InvalidateLayout()
end

function HSCROLL:PerformLayout(w, h)
    if w < 2 then return end
    local n = #self.items
    self.content_w = n * self.item_w + math.max(0, n - 1) * self.gap
    self.has_bar = self.content_w > w + 1
    self.max_off = math.max(0, self.content_w - w)
    self.offset = math.Clamp(self.offset, 0, self.max_off)
    self.view:SetPos(0, 0)
    self.view:SetSize(w, self.row_h)
    for i, it in ipairs(self.items) do
        it:SetPos((i - 1) * (self.item_w + self.gap) - self.offset, 0)
        it:SetSize(self.item_w, self.row_h)
    end
end

function HSCROLL:SetOffset(o)
    o = math.Clamp(o, 0, self.max_off)
    if o == self.offset then return end
    self.offset = o
    self:InvalidateLayout(true)
end

function HSCROLL:OnMouseWheeled(d)
    if not self.has_bar then return false end
    self:SetOffset(self.offset - d * (self.item_w + self.gap))
    return true
end

function HSCROLL:Thumb()
    local w = self:GetWide()
    local tw = math.max(S(28), math.floor(w * w / math.max(1, self.content_w)))
    local travel = math.max(1, w - tw)
    local tx = (self.max_off > 0) and math.floor(travel * self.offset / self.max_off) or 0
    return tx, tw, travel, self.row_h + self.bar_gap
end

function HSCROLL:Paint(w)
    if not self.has_bar then return end
    local tx, tw, _, by = self:Thumb()
    local r = math.floor(self.bar_h / 2)
    draw.RoundedBox(r, 0, by, w, self.bar_h, TRACK)
    draw.RoundedBox(r, tx, by, tw, self.bar_h, RED)
end

function HSCROLL:OnMousePressed(code)
    if code ~= MOUSE_LEFT or not self.has_bar then return end
    local mx, my = self:CursorPos()
    local tx, tw, _, by = self:Thumb()
    if my < by - S(6) then return end
    if mx >= tx and mx <= tx + tw then
        self.drag = { mx = mx, off = self.offset }
        self:MouseCapture(true)
    else
        self:SetOffset(self.offset + ((mx < tx) and -1 or 1) * self:GetWide())
    end
end

function HSCROLL:OnMouseReleased() self.drag = nil; self:MouseCapture(false) end

function HSCROLL:Think()
    if not self.drag then return end
    if not input.IsMouseDown(MOUSE_LEFT) then self:OnMouseReleased() return end
    local mx = self:CursorPos()
    local _, _, travel = self:Thumb()
    self:SetOffset(self.drag.off + (mx - self.drag.mx) * self.max_off / math.max(1, travel))
end

vgui.Register("HordeF1HScroll", HSCROLL, "Panel")

local TEXT = {}

function TEXT:Init() self.blocks, self.list, self.cw, self.total = {}, {}, 0, S(10) end

function TEXT:SetBlocks(b) self.blocks, self.cw = b, 0; self:InvalidateLayout() end

function TEXT:Rebuild(cw)
    if cw == self.cw then return end
    self.cw = cw
    local fh, fb = Font(25), Font(19)
    local lh, hh, gap, hgap = S(24), S(26), S(28), S(26)
    local padx, maxw = S(6), cw - S(6) - S(30)
    local list, y = {}, 0
    for i, b in ipairs(self.blocks) do
        if b.h then
            if i > 1 then y = y + hgap end
            list[#list + 1] = { t = b.h, f = fh, c = RED, y = y + hh / 2 }
            y = y + hh
        elseif b.gap then
            local nxt = self.blocks[i + 1]
            if nxt and not nxt.h then y = y + gap end
        else
            for _, ln in ipairs(Wrap(b.p, fb, maxw)) do
                list[#list + 1] = { t = ln, f = fb, c = WH, y = y + lh / 2 }
                y = y + lh
            end
        end
    end
    self.list, self.total, self.padx = list, y + S(8), padx
end

function TEXT:GetHeightFor(cw) self:Rebuild(cw); return self.total end

function TEXT:Paint(w, h)
    local par = self:GetParent()
    local _, py = self:GetPos()
    local vh = IsValid(par) and par:GetTall() or h
    for _, l in ipairs(self.list) do
        local sy = l.y + py
        if sy > -S(30) and sy < vh + S(30) then
            draw.SimpleText(l.t, l.f, self.padx or 0, l.y, l.c, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end

vgui.Register("HordeF1Text", TEXT, "Panel")

local KEYBTN = {}

function KEYBTN:Init()
    self:SetText("")
    self.value, self.capturing = "", false
    self:ResetCap()
end

function KEYBTN:ResetCap() self.cap_down, self.cap_order, self.cap_peak, self.cap_had = {}, {}, {}, false end
function KEYBTN:SetValue(v) self.value = v or "" end
function KEYBTN:IsCapturing() return self.capturing end
function KEYBTN:Cancel() self.capturing = false; self:ResetCap() end

function KEYBTN:Commit()
    self.capturing = false
    local names = {}
    for _, code in ipairs(self.cap_peak) do names[#names + 1] = (PM().CAPTURE_NAME or {})[code] end
    local v = table.concat(names, "+")
    self:ResetCap()
    if v == "" or v == "ESCAPE" then return end
    self.value = v
    if self.OnChange then self:OnChange(v) end
end

function KEYBTN:Think()
    if not self.capturing then return end
    local pm = PM()
    for _, code in ipairs(pm.CAPTURE_CODES or {}) do
        local down = pm.IsCodeDown(code)
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
    if self.cap_had and #self.cap_order == 0 then self:Commit() end
end

function KEYBTN:Paint(w, h)
    local text, col = KeyLabel(self.value), WH
    if self.value == "" then text, col = T("KbNone"), DIM end
    if self.capturing then
        local parts = {}
        for _, code in ipairs(self.cap_order) do parts[#parts + 1] = (PM().CAPTURE_NAME or {})[code] end
        text = (#parts > 0) and KeyLabel(table.concat(parts, "+")) or T("KbPress")
        col = (#parts > 0) and WH or Color(255, 210, 215)
    end
    local bg = self.capturing and RED or (self:IsHovered() and GREY_H or GREY)
    draw.RoundedBox(S(8), 0, 0, w, h, bg)
    draw.SimpleText(FitText(text, Font(25), w - S(16)), Font(25), w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function KEYBTN:OnMousePressed(code)
    local pm = PM()
    if self.capturing then
        if code == MOUSE_RIGHT then self:Cancel() end
        return
    end
    if code ~= MOUSE_LEFT or not pm.CAPTURE_CODES then return end
    if self.OnBeginCapture then self:OnBeginCapture() end
    self.capturing = true
    self:ResetCap()
    for _, c in ipairs(pm.CAPTURE_CODES) do
        if pm.IsCodeDown(c) then self.cap_down[c] = true end
    end
    self.cap_down[code] = true
    SndClick()
end

function KEYBTN:OnCursorEntered() SndHover() end

vgui.Register("HordeF1KeyButton", KEYBTN, "DButton")

local PREVIEW = {}

local function ModelExists(path)
    if not isstring(path) or path == "" then return false end
    return file.Exists(path, "GAME") or util.IsValidModel(path)
end

local function FitDistance(mn, mx, fov)
    local radius = math.max(1, (mx - mn):Length() * 0.5)
    return radius / math.tan(math.rad(fov * 0.5)) * 1.3, (mn + mx) * 0.5
end

function PREVIEW:Init() self.extras, self.vis, self.ok = {}, nil, false end

function PREVIEW:ClearExtras()
    for _, e in ipairs(self.extras) do
        if IsValid(e.ent) then e.ent:Remove() end
    end
    self.extras = {}
end

function PREVIEW:OnRemove() self:ClearExtras() end

function PREVIEW:MakeModelPanel()
    local mp = vgui.Create("DModelPanel", self)
    mp:SetMouseInputEnabled(false)
    mp:SetFOV(30)
    mp:SetAmbientLight(Color(110, 110, 110))
    mp:SetCamPos(Vector(60, 0, 20))
    mp:SetLookAt(vector_origin)
    mp.owner = self

    function mp:LayoutEntity(ent)
        if not IsValid(ent) then return end
        if self.fit_model ~= ent:GetModel() then
            self.fit_model = ent:GetModel()
            local mn, mx = ent:GetRenderBounds()
            self.fit_dist, self.fit_center = FitDistance(mn, mx, self:GetFOV())
        end
        local ang = Angle(0, (SysTime() * 55) % 360, 0)
        ent:SetAngles(ang)
        local c = Vector(self.fit_center.x, self.fit_center.y, self.fit_center.z)
        c:Rotate(ang)
        ent:SetPos(-c)
        self:SetCamPos(Vector(self.fit_dist, 0, self.fit_dist * 0.32))
        self:SetLookAt(vector_origin)
    end

    function mp:PreDrawModel(ent)
        local v = self.owner.vis
        local c = v and v.color
        if c then
            render.SetColorModulation(c.r / 255, c.g / 255, c.b / 255)
            render.SetBlend((c.a or 255) / 255)
        end
    end

    function mp:PostDrawModel(ent)
        render.SetColorModulation(1, 1, 1)
        render.SetBlend(1)
        local extras = self.owner.extras
        if #extras == 0 then return end
        ent:SetupBones()
        for _, e in ipairs(extras) do
            if IsValid(e.ent) then
                local c = e.color
                if c then render.SetColorModulation(c.r / 255, c.g / 255, c.b / 255) end
                e.ent:DrawModel()
                render.SetColorModulation(1, 1, 1)
            end
        end
    end

    self.mp = mp
    return mp
end

function PREVIEW:PerformLayout(w, h)
    if IsValid(self.mp) then self.mp:SetSize(w, h) end
end

function PREVIEW:SetVisual(v)
    self:ClearExtras()
    self.vis, self.ok = v, false
    if not (v and ModelExists(v.model)) then
        if v and GetConVar("developer"):GetInt() > 0 then
            MsgN("[Horde F1] enemy preview: model not found: " .. tostring(v.model))
        end
        if IsValid(self.mp) then self.mp:SetVisible(false) end
        return false
    end
    util.PrecacheModel(v.model)
    local mp = IsValid(self.mp) and self.mp or self:MakeModelPanel()
    mp.fit_model = nil
    mp:SetModel(v.model)
    mp:SetSize(self:GetWide(), self:GetTall())
    mp:SetVisible(true)

    local ent = mp.Entity
    if IsValid(ent) then
        ent:SetSkin(v.skin or 0)
        for i, val in pairs(v.bg or {}) do ent:SetBodygroup(i, val) end
        for i, m in pairs(v.submat or {}) do ent:SetSubMaterial(i, m) end
        local main_scale = v.scale or 1
        for _, x in ipairs(v.extras or {}) do
            if ModelExists(x.model) then
                util.PrecacheModel(x.model)
                local ex = ClientsideModel(x.model, RENDERGROUP_OPAQUE)
                if IsValid(ex) then
                    ex:SetNoDraw(true)
                    ex:SetModelScale((x.scale or 1) / main_scale, 0)
                    local attached = false
                    if x.attach then
                        local id = ent:LookupAttachment(x.attach)
                        if id and id > 0 then ex:SetParent(ent, id); attached = true end
                    elseif x.bone then
                        local bone = ent:LookupBone(x.bone)
                        if bone then ex:SetParent(ent); ex:FollowBone(ent, bone); attached = true end
                    end
                    if attached then
                        ex:SetLocalPos(x.pos or vector_origin)
                        ex:SetLocalAngles(x.ang or angle_zero)
                        self.extras[#self.extras + 1] = { ent = ex, color = x.color }
                    else
                        ex:Remove()
                    end
                end
            end
        end
    end
    self.ok = true
    return true
end

vgui.Register("HordeF1ModelPreview", PREVIEW, "Panel")

local PAGE_W, PAGE_H = 1214, 644
local COL_L, COL_GAP = 577, 18
local COL_R = PAGE_W - COL_L - COL_GAP

local MAT_BOLT   = Material("materials/gui/bolt.png", "mips smooth")
local MAT_MEDKIT = Material("materials/items/weapon_medkit.png", "mips smooth")
local MAT_SKULL  = Material("materials/skull.png", "mips smooth")
local mat_cache  = {}
local function CachedMat(path)
    if not isstring(path) or path == "" then return nil end
    if not mat_cache[path] then mat_cache[path] = Material(path, "mips smooth") end
    return mat_cache[path]
end

local GUIDE_PAGE = {}

local function RandomPerkIcon()
    local pool = {}
    for _, perk in pairs(HORDE.perks or {}) do
        if istable(perk) and isstring(perk.Icon) and perk.Icon ~= "" and file.Exists(perk.Icon, "GAME") then
            pool[#pool + 1] = perk.Icon
        end
    end
    while #pool > 0 do
        local i = math.random(#pool)
        local mat = Material(pool[i], "mips smooth")
        if mat and not mat:IsError() then return mat end
        table.remove(pool, i)
    end
    return MAT_BOLT
end

function GUIDE_PAGE:Init()
    self.tip = RandomTip()
    self.tip_icon = RandomPerkIcon()
    self.scroll = vgui.Create("HordeF1Scroll", self)
    self.scroll:Configure({ bar_mode = "overlay", gap = 0 })
    local txt = vgui.Create("HordeF1Text")
    txt:SetBlocks(ParseGuide(T("GuideText")))
    self.scroll:AddItem(txt)
end

function GUIDE_PAGE:PerformLayout(w, h)
    self.scroll:SetPos(0, S(48))
    self.scroll:SetSize(w, S(465))
end

function GUIDE_PAGE:Paint(w, h)
    DrawPill(0, 0, w, S(36), RED)
    draw.SimpleText(FitText(T("GuideWelcome", GetHostName() or ""), Font(25), w - S(40)), Font(25),
        w / 2, S(18), WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local bx, by, bw, bh = S(196), S(523), S(818), S(113)
    local b = SB(2)
    draw.RoundedBox(S(14), bx, by, bw, bh, RED)
    draw.RoundedBox(math.max(0, S(14) - b), bx + b, by + b, bw - 2 * b, bh - 2 * b, WIN)

    local isz = S(76)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(self.tip_icon or MAT_BOLT)
    surface.DrawTexturedRect(bx + S(22), by + (bh - isz) / 2, isz, isz)

    local tx = bx + S(114)
    draw.SimpleText(T("GuideTip"), Font(25), tx, by + S(30), RED, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    local lines = Wrap(self.tip, Font(19), bw - S(114) - S(24))
    for i = 1, math.min(#lines, 2) do
        draw.SimpleText(lines[i], Font(19), tx, by + S(64) + (i - 1) * S(24), WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

vgui.Register("HordeF1Guide", GUIDE_PAGE, "Panel")

local KB_PAGE = {}

local function ControlLabel(def)
    local key = "Ctl_" .. def.id
    local v = translate.Get("F1_" .. key)
    if v and v ~= "" and v ~= "F1_" .. key then return v end
    return (string.gsub(tostring(def.label or def.id), ":%s*$", ""))
end

function KB_PAGE:Init()
    self.rows, self.draft, self.saved_until = {}, {}, 0

    self.scroll = vgui.Create("HordeF1Scroll", self)
    self.scroll:Configure({ bar_mode = "overlay", gap = 0, pad_top = S(6) })

    for _, def in ipairs(HORDE.GameplayControlDefs or {}) do
        if (def.cmd or "") ~= "" then self:AddRow(def) end
    end

    local function btn(red, text_key, click)
        return MakeButton(self, function(s, w, h)
            local col = red and (s:IsHovered() and RED_H or RED) or (s:IsHovered() and GREY_H or GREY)
            draw.RoundedBox(S(8), 0, 0, w, h, col)
            local label = (red and CurTime() < self.saved_until) and T("KbSaved") or T(text_key)
            draw.SimpleText(FitText(label, Font(25), w - S(16)), Font(25), w / 2, h / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end, click)
    end
    self.b_unbind = btn(false, "KbUnbindAll", function() self:SetAll(function() return "" end) end)
    self.b_reset  = btn(false, "KbReset",     function() self:SetAll(function(def) return ServerKey(def.id) end) end)
    self.b_save   = btn(true,  "KbSave",      function() self:Save() end)
end

function KB_PAGE:AddRow(def)
    local id = def.id
    local cur = EffectiveKey(id)
    self.draft[id] = cur

    local row = vgui.Create("Panel")
    row.item_h = S(65)
    row.label = ControlLabel(def)

    local kb = vgui.Create("HordeF1KeyButton", row)
    kb:SetValue(cur)
    kb.OnChange = function(_, v) self.draft[id] = v end
    kb.OnBeginCapture = function()
        for _, r in ipairs(self.rows) do if IsValid(r.kb) and r.kb ~= kb then r.kb:Cancel() end end
    end

    local xb = MakeButton(row, function(s, w, h)
        draw.RoundedBox(S(8), 0, 0, w, h, s:IsHovered() and GREY_H or GREY)
        draw.SimpleText("X", Font(25), w / 2, h / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end, function()
        kb:Cancel()
        kb:SetValue("")
        self.draft[id] = ""
    end)

    row.Paint = function(s, w, h)
        draw.SimpleText(FitText(s.label, Font(25), S(540)), Font(25), S(288), h / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    row.PerformLayout = function(s, w, h)
        local bh = S(44)
        kb:SetPos(S(701), (h - bh) / 2); kb:SetSize(S(349), bh)
        xb:SetPos(S(1063), (h - bh) / 2); xb:SetSize(S(43), bh)
    end
    row.kb, row.def = kb, def
    self.rows[#self.rows + 1] = row
    self.scroll:AddItem(row)
end

function KB_PAGE:SetAll(fn)
    for _, r in ipairs(self.rows) do
        local v = fn(r.def) or ""
        r.kb:Cancel()
        r.kb:SetValue(v)
        self.draft[r.def.id] = v
    end
end

function KB_PAGE:Save()
    for _, r in ipairs(self.rows) do
        local id = r.def.id
        local v = self.draft[id] or ""
        HORDE.PlayerControls = HORDE.PlayerControls or {}
        if v == ServerKey(id) then HORDE.PlayerControls[id] = nil else HORDE.PlayerControls[id] = v end
    end
    if PM().SaveControls then PM().SaveControls() end
    self.saved_until = CurTime() + 1.5
    surface.PlaySound("buttons/button14.wav")
end

function KB_PAGE:IsCapturing()
    for _, r in ipairs(self.rows) do
        if IsValid(r.kb) and r.kb:IsCapturing() then return true end
    end
    return false
end

function KB_PAGE:PerformLayout(w, h)
    self.scroll:SetPos(0, S(48))
    self.scroll:SetSize(w, S(507))
    local by, bh = S(570), S(46)
    self.b_unbind:SetPos(S(3), by);   self.b_unbind:SetSize(S(390), bh)
    self.b_reset:SetPos(S(440), by);  self.b_reset:SetSize(S(389), bh)
    self.b_save:SetPos(S(876), by);   self.b_save:SetSize(S(333), bh)
end

function KB_PAGE:Paint(w, h)
    DrawPill(0, 0, S(COL_L), S(36), RED)
    DrawPill(S(COL_L + COL_GAP), 0, S(COL_R), S(36), RED)
    draw.SimpleText(T("KbEvent"), Font(25), S(COL_L) / 2, S(18), WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(T("KbKeys"), Font(25), S(COL_L + COL_GAP) + S(COL_R) / 2, S(18), WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

vgui.Register("HordeF1Keyboard", KB_PAGE, "Panel")

local INFO_BLOCK = {}

local HALO = Color(20, 21, 24)

function INFO_BLOCK:Init()
    self.list, self.total, self.cw = {}, 0, -1
    self.has_model = false
end

function INFO_BLOCK:SetEntry(e)
    self.entry, self.cw = e, -1
    local vis = e and e.visual
    if vis then
        if not IsValid(self.preview) then self.preview = vgui.Create("HordeF1ModelPreview", self) end
        self.preview:SetSize(S(110), S(110))
        self.has_model = self.preview:SetVisual(vis)
    else
        if IsValid(self.preview) then self.preview:SetVisual(nil) end
        self.has_model = false
    end
    if IsValid(self.preview) then self.preview:SetVisible(self.has_model) end
end

function INFO_BLOCK:PerformLayout()
    local p = self.port
    if IsValid(self.preview) and p then
        local sz = self.preview:GetWide()
        self.preview:SetPos(p.x + (p.d - sz) / 2, p.y + (p.d - sz) / 2)
    end
end

function INFO_BLOCK:Think()
    local pv = self.preview
    if not IsValid(pv) then return end
    local par = self:GetParent()
    local _, py = self:GetPos()
    local top = py + pv:GetY()
    local fits = IsValid(par) and top >= 0 and top + pv:GetTall() <= par:GetTall()
    pv:SetVisible(self.has_model and fits and self.port ~= nil)
end

function INFO_BLOCK:Rebuild(cw)
    if cw == self.cw then return end
    self.cw = cw
    local e = self.entry or {}
    local padx, lh = S(21), S(24)
    local f_t, f_b = Font(26), Font(19)
    local list = {}
    local port
    if e.portrait then
        local d = S(90)
        port = { x = cw - S(28) - d, y = S(31), d = d, mat = e.portrait_mat }
    end

    list[#list + 1] = { t = FitText(e.title or "", f_t, (port and port.x or cw) - padx - S(10)), f = f_t, c = RED, x = padx, y = S(29) }

    local desc_y = S(106)
    local maxw_full = cw - padx - S(30)
    local lines = Wrap(e.desc or "", f_b, function(i)
        local ly = desc_y + (i - 1) * lh
        if port and ly < port.y + port.d + S(4) then return port.x - padx - S(16) end
        return maxw_full
    end)
    local y = desc_y
    for _, ln in ipairs(lines) do
        list[#list + 1] = { t = ln, f = f_b, c = WH, x = padx, y = y + lh / 2 }
        y = y + lh
    end
    y = y + S(24)

    local function Pair(label, value)
        surface.SetFont(f_b)
        local lw = surface.GetTextSize(label)
        list[#list + 1] = { t = label, f = f_b, c = RED, x = padx, y = y + lh / 2 }
        if value and value ~= "" then
            list[#list + 1] = { t = FitText(value, f_b, cw - padx - lw - S(8) - S(30)), f = f_b, c = WH, x = padx + lw + S(8), y = y + lh / 2 }
        end
        y = y + lh
    end

    for _, r in ipairs(e.rows or {}) do Pair(r[1], r[2]) end
    if e.abil_label then
        if e.abil and e.abil ~= "" then
            Pair(e.abil_label)
            for _, ln in ipairs(Wrap(e.abil, f_b, maxw_full)) do
                list[#list + 1] = { t = ln, f = f_b, c = WH, x = padx, y = y + lh / 2 }
                y = y + lh
            end
        else
            Pair(e.abil_label, "—")
        end
    end
    if e.footer and #e.footer > 0 then
        y = y + S(24)
        for _, r in ipairs(e.footer) do Pair(r[1], r[2]) end
    end

    self.list, self.port, self.total = list, port, y + S(12)
end

function INFO_BLOCK:GetHeightFor(cw) self:Rebuild(cw); return self.total end

function INFO_BLOCK:Paint(w, h)
    local par = self:GetParent()
    local _, py = self:GetPos()
    local vh = IsValid(par) and par:GetTall() or h
    for _, l in ipairs(self.list) do
        local sy = l.y + py
        if sy > -S(30) and sy < vh + S(30) then
            draw.SimpleText(l.t, l.f, l.x, l.y, l.c, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    local p = self.port
    if p then
        local cx, cy, r = p.x + p.d / 2, p.y + p.d / 2, p.d / 2
        local UI = HORDE.ShopUI
        if UI and UI.Circle then
            UI.Circle(cx, cy, r, HALO)
        else
            draw.RoundedBox(math.floor(r), p.x, p.y, p.d, p.d, HALO)
        end
        if not self.has_model then
            if p.mat then
                local iw = p.d * 0.62
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(p.mat)
                surface.DrawTexturedRect(cx - iw / 2, cy - iw / 2, iw, iw)
            else
                draw.SimpleText("?", Font(46, true), cx, cy, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end
end

vgui.Register("HordeF1Info", INFO_BLOCK, "Panel")

local function CollectEnemies()
    local by_class, all = {}, {}
    for _, e in pairs(HORDE.enemies or {}) do
        if istable(e) and isstring(e.class) and isstring(e.name) then
            local c = by_class[e.class]
            if not c then
                c = { class = e.class, name = e.name, waves = {}, elite = false, boss = false }
                by_class[e.class] = c
                all[#all + 1] = c
            end
            if INFO[e.name] and not INFO[c.name] then c.name = e.name end
            if e.is_elite then c.elite = true end
            if istable(e.boss_properties) and e.boss_properties.is_boss then c.boss = true end
            local w = tonumber(e.wave)
            if w and (c.boss or (tonumber(e.weight) or 0) > 0) then c.waves[w] = true end
        end
    end
    local function first_wave(c)
        local m = math.huge
        for w in pairs(c.waves) do if w ~= 666 and w < m then m = w end end
        return m
    end
    table.sort(all, function(a, b)
        local fa, fb = first_wave(a), first_wave(b)
        if fa ~= fb then return fa < fb end
        return a.name < b.name
    end)
    local cats = {
        { key = "CatDefault", list = {} },
        { key = "CatElites",  list = {} },
        { key = "CatBosses",  list = {} },
    }
    for _, c in ipairs(all) do
        local idx = c.boss and 3 or (c.elite and 2 or 1)
        table.insert(cats[idx].list, c)
    end
    return cats, by_class
end

local function AppearanceText(c)
    local ws = {}
    for w in pairs(c.waves) do if w ~= 666 then ws[#ws + 1] = w end end
    table.sort(ws)
    local has666 = c.waves[666]
    if #ws == 0 then return has666 and T("AppearW666") or "—" end
    local a, b = ws[1], ws[#ws]
    local s = (a == b) and T("AppearOne", a) or T("AppearRange", a, b)
    if has666 then s = T("AppearAlso666", s) end
    return s
end

local RESIST_ORDER = { "fire", "cold", "lightning", "poison", "blast" }
local RESIST_KEY = { fire = "Fire", cold = "Cold", lightning = "Lightning", poison = "Poison", blast = "Blast" }

local function ResistText(res)
    local parts = {}
    for _, k in ipairs(RESIST_ORDER) do
        if res[k] then parts[#parts + 1] = T(RESIST_KEY[k]) .. " x" .. tostring(res[k]) end
    end
    return table.concat(parts, ", ")
end

local function BuildEnemyEntry(c, variation)
    local name = variation and (variation.Name or c.name) or c.name
    local info = INFO[name] or {}
    local rows = {
        { T("Health"),   info.hp  and tostring(info.hp)  or "—" },
        { T("Damage"),   info.dmg and tostring(info.dmg) or "—" },
        { T("Move"),     Loc(info.move) or "—" },
        { T("AtkSpeed"), info.atk and T("AtkEvery", info.atk) or "—" },
    }
    if info.resist then rows[#rows + 1] = { T("Resist"), ResistText(info.resist) } end
    return {
        title = name,
        portrait = true,
        portrait_mat = CachedMat(info.portrait),
        visual = VISUAL[variation and variation.Class or c.class],
        desc = T(EnemyTextKey(name, "Desc")) or T("NoDesc"),
        rows = rows,
        abil_label = T("Abilities"),
        abil = TSoft(EnemyTextKey(name, "Abil")),
        footer = { { T("DefAppear"), AppearanceText(c) } },
    }
end

local function VariationsOf(class)
    local out = {}
    for _, v in ipairs(HORDE.enemy_variations or {}) do
        if v.ParentEntity == class and v.Name then out[#out + 1] = v end
    end
    return out
end

local function CollectDifficulties()
    local base, mods, defs = {}, {}, {}
    for _, def in pairs(HORDE._difficulties or {}) do
        if istable(def) and def.Name then defs[def.Name] = def end
    end
    for _, entry in ipairs(HORDE:GetDifficultyNameList()) do
        local name = entry.name
        if not (HORDE.IsDifficultyHidden and HORDE:IsDifficultyHidden(name)) then
            local def = defs[name]
            local is_mod
            if def and HORDE.IsModifier then
                is_mod = HORDE:IsModifier(def)
            elseif def and HORDE.GetDifficultyInclude then
                is_mod = HORDE:GetDifficultyInclude(def) ~= nil
            else
                is_mod = entry.index > 4
            end
            if is_mod then mods[#mods + 1] = name else base[#base + 1] = name end
        end
    end
    return base, mods, defs
end

local function BuildDiffEntry(name, def)
    def = def or {}
    local function mult(v)
        v = tonumber(v)
        return v and ("x" .. tostring(math.Round(v, 3))) or "—"
    end
    local rows = {
        { T("Health"),      mult(def.HealthMult) },
        { T("Damage"),      mult(def.DamageMult) },
        { T("DiffRewards"), mult(def.RewardMult) },
        { T("DiffCount"),   mult(def.EnemyCountMult) },
    }
    if tonumber(def.MaxWaves) then rows[#rows + 1] = { T("DiffWaves"), tostring(def.MaxWaves) } end
    return { title = DiffLabel(name), desc = TSoft("Diff_" .. name) or T("NoDesc"), rows = rows }
end

local ALM = {}
local TILE_COLS = 5

function ALM:Init()
    self.mode = "enemies"
    self.sel, self.sel_var = nil, 1

    self.left = vgui.Create("HordeF1Scroll", self)
    self.left:Configure({ bar_mode = "reserve", bar_gap = S(19), view_top = S(46), gap = S(10) })

    self.info_scroll = vgui.Create("HordeF1Scroll", self)
    self.info_scroll:Configure({ bar_mode = "overlay", gap = 0 })
    self.info = vgui.Create("HordeF1Info")
    self.info_scroll:AddItem(self.info)

    self.vars = vgui.Create("HordeF1HScroll", self)
    self.vars:SetVisible(false)

    local function sub(mode, key)
        return MakeButton(self, function(s, w, h)
            DrawPillOutline(0, 0, w, h, self.mode == mode and RED or (s:IsHovered() and GREY_H or GREY), WIN)
            draw.SimpleText(T(key), Font(25), w / 2, h / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end, function() self:SetMode(mode) end)
    end
    self.b_enemies = sub("enemies", "AlEnemies")
    self.b_diffs   = sub("difficulties", "AlDifficulties")

    self:BuildList()
end

function ALM:SetInfo(entry)
    self.info:SetEntry(entry)
    self.info_scroll.offset = 0
    self.info_scroll:InvalidateLayout(true)
end

function ALM:SetMode(mode)
    if self.mode == mode then return end
    self.mode, self.sel, self.sel_var = mode, nil, 1
    self:BuildList()
end

local function EmptyItem(text)
    local p = vgui.Create("Panel")
    p.item_h = S(48)
    p.Paint = function(_, w, h)
        draw.SimpleText(text, Font(19), w / 2, h / 2, DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    return p
end

local function HeaderItem(text)
    local p = vgui.Create("Panel")
    p.item_h = S(36)
    p.Paint = HeaderPaint(text)
    return p
end

function ALM:MakeGrid(entries)
    local g = vgui.Create("Panel")
    g.gap_after = S(28)
    local tiles = {}
    for _, c in ipairs(entries) do
        local t = MakeButton(g, nil, function() self:SelectEnemy(c.class) end)
        t.entry = c
        t.Paint = function(s, w, h)
            local sel = (self.sel == c.class)
            draw.RoundedBox(S(10), 0, 0, w, h, sel and RED or (s:IsHovered() and GREY_H or GREY))
            local custom = CachedMat((INFO[c.name] or {}).icon)
            surface.SetDrawColor(255, 255, 255, 255)
            if custom then
                local sz = S(58)
                surface.SetMaterial(custom)
                surface.DrawTexturedRect((w - sz) / 2, (h - sz) / 2 - S(4), sz, sz)
            else
                local iw, ih = S(100), S(50)
                surface.SetMaterial(MAT_MEDKIT)
                surface.DrawTexturedRect((w - iw) / 2, (h - ih) / 2 - S(8), iw, ih)
            end
            if not custom or s:IsHovered() then
                draw.SimpleText(FitText(c.name, Font(13), w - S(8)), Font(13), w / 2, h - S(14), Color(255, 255, 255, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
        tiles[#tiles + 1] = t
    end
    local th, tg = S(88), S(13)
    function g:GetHeightFor()
        local rows = math.ceil(#tiles / TILE_COLS)
        return rows * th + math.max(0, rows - 1) * tg
    end
    function g:PerformLayout(w)
        local gap = S(14)
        local tw = math.floor((w - S(6) - gap * (TILE_COLS - 1)) / TILE_COLS)
        for i, t in ipairs(tiles) do
            local col, row = (i - 1) % TILE_COLS, math.floor((i - 1) / TILE_COLS)
            t:SetPos(S(3) + col * (tw + gap), row * (th + tg))
            t:SetSize(tw, th)
        end
    end
    return g
end

function ALM:BuildList()
    self.left:Clear()
    self.vars:Clear()
    self.vars:SetVisible(false)

    if self.mode == "enemies" then
        local cats, by_class = CollectEnemies()
        self.by_class = by_class
        local first
        for _, cat in ipairs(cats) do
            if #cat.list > 0 then
                first = first or cat.list[1].class
                self.left:AddItem(HeaderItem(T(cat.key)))
                self.left:AddItem(self:MakeGrid(cat.list))
            end
        end
        if not first then
            self.left:AddItem(EmptyItem(T("NoEnemies")))
            self:SetInfo({ title = "", desc = T("NoEnemies"), rows = {} })
        else
            self:SelectEnemy(self.sel or first)
        end
    else
        local base, mods, defs = CollectDifficulties()
        self.defs = defs
        local first
        local function add(header_key, names)
            if #names == 0 then return end
            self.left:AddItem(HeaderItem(T(header_key)))
            for i, name in ipairs(names) do
                first = first or name
                local b = MakeButton(nil, nil, function() self:SelectDiff(name) end)
                b.item_h = S(40)
                b.gap_after = (i == #names) and S(28) or S(8)
                local label = DiffLabel(name)
                b.Paint = function(s, w, h)
                    draw.RoundedBox(S(10), 0, 0, w, h, (self.sel == name) and RED or (s:IsHovered() and GREY_H or GREY))
                    draw.SimpleText(FitText(label, Font(22), w - S(20)), Font(22), w / 2, h / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                self.left:AddItem(b)
            end
        end
        add("CatBase", base)
        add("CatMods", mods)
        if not first then
            self.left:AddItem(EmptyItem(T("NoDiffs")))
            self:SetInfo({ title = "", desc = T("NoDiffs"), rows = {} })
        else
            local cur = HORDE.difficulty_text and HORDE.difficulty_text[HORDE.difficulty]
            self:SelectDiff(self.sel or cur or first)
        end
    end
end

function ALM:SelectEnemy(class)
    local c = self.by_class and self.by_class[class]
    if not c then return end
    if self.sel ~= class then self.sel_var = 1 end
    self.sel = class
    self:RefreshEnemyInfo()

    self.vars:Clear()
    local variations = VariationsOf(class)
    if #variations > 0 then
        local function pill(name, idx)
            local p = MakeButton(nil, nil, function()
                self.sel_var = idx
                self:RefreshEnemyInfo()
            end)
            p.Paint = function(s, w, h)
                local on = (self.sel_var == idx)
                DrawPill(0, 0, w, h, on and RED or (s:IsHovered() and GREY_H or GREY))
                draw.SimpleText(FitText(name, Font(24), w - S(24)), Font(24), w / 2, h / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            self.vars:AddItem(p)
        end
        pill(c.name, 1)
        for i, v in ipairs(variations) do pill(v.Name, i + 1) end
    end
    self.vars:SetVisible(#variations > 0)
    self.has_vars = #variations > 0
    self:InvalidateLayout()
end

function ALM:RefreshEnemyInfo()
    local c = self.by_class and self.by_class[self.sel]
    if not c then return end
    local variation
    if self.sel_var > 1 then variation = VariationsOf(c.class)[self.sel_var - 1] end
    self:SetInfo(BuildEnemyEntry(c, variation))
end

function ALM:SelectDiff(name)
    self.sel = name
    self:SetInfo(BuildDiffEntry(name, self.defs and self.defs[name]))
end

function ALM:PerformLayout(w, h)
    local pw = S(251)
    self.left:SetPos(0, 0)
    self.left:SetSize(S(522 + 19 + 12), S(613))
    self.b_enemies:SetPos(0, 0);          self.b_enemies:SetSize(pw, S(36))
    self.b_diffs:SetPos(S(522) - pw, 0);  self.b_diffs:SetSize(pw, S(36))

    self.info_scroll:SetPos(S(570), S(44))
    self.info_scroll:SetSize(S(644), S(462))
    self.vars:SetPos(S(591), S(545))
    self.vars:SetSize(S(623), S(68))
end

function ALM:Paint(w, h)
    DrawPill(S(570), 0, S(644), S(36), RED)
    draw.SimpleText(T("AlDescription"), Font(25), S(570 + 322), S(18), WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    if self.mode == "enemies" and self.has_vars then
        draw.SimpleText(T("Variants"), Font(19), S(591), S(522), RED, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

vgui.Register("HordeF1Almanac", ALM, "Panel")

local ACH_ROW = {}

function ACH_ROW:Setup(def) self.def = def; self.item_h = S(115) end

local function AchState() return HORDE.PlayerAchievements and HORDE.PlayerAchievements.state or { progress = {}, unlocked = {}, owned = {} } end

local function AchFraction(def)
    local A = HORDE.PlayerAchievements
    return A and A:GetFraction(def) or 0
end

function ACH_ROW:Paint(w, h)
    local d = self.def
    local f_t, f_d, f_s = Font(26), Font(17), Font(16)

    local cw, b = S(573), SB(2)
    local cx = S(2)
    draw.RoundedBox(S(10), cx, 0, cw, h, RED)
    draw.RoundedBox(math.max(0, S(10) - b), cx + b, b, cw - 2 * b, h - 2 * b, WIN)

    local icon = CachedMat(d.icon)
    if icon then
        local isz = S(84)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(icon)
        surface.DrawTexturedRect(cx + S(14), (h - isz) / 2, isz, isz)
    end

    local tx = cx + S(116)
    local maxw = cw - S(116) - S(16)
    draw.SimpleText(FitText(Loc(d.name) or d.id, f_t, maxw), f_t, tx, S(28), RED, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    local lines = Wrap(Loc(d.desc) or "", f_d, maxw)
    for i = 1, math.min(#lines, 2) do
        draw.SimpleText(lines[i], f_d, tx, S(54) + (i - 1) * S(19), WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local ry = S(94)
    surface.SetFont(f_s)
    local x = tx
    local lbl = T("Reward")
    draw.SimpleText(lbl, f_s, x, ry, RED, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    x = x + (surface.GetTextSize(lbl)) + S(8)
    local rw = d.reward or {}
    if (rw.skulls or 0) > 0 then
        local s = tostring(rw.skulls)
        draw.SimpleText(s, f_s, x, ry, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        x = x + (surface.GetTextSize(s)) + S(4)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(MAT_SKULL)
        surface.DrawTexturedRect(x, ry - S(8), S(16), S(16))
        x = x + S(16) + S(6)
    end
    if (rw.exp or 0) > 0 then
        draw.SimpleText(rw.exp .. " " .. T("Exp"), f_s, x, ry, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local px = S(COL_L + COL_GAP)
    local pct = AchFraction(d)
    draw.SimpleText(T("Completed", math.floor(pct * 100 + 0.5)), Font(25), px, S(14), WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    local owned = AchState().owned[d.id]
    if owned then
        draw.SimpleText(T("OwnedBy", string.format("%.2f", owned)), Font(16), px, S(39), DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local bw, bh, by = S(583), S(20), S(94)
    draw.RoundedBox(bh / 2, px, by, bw, bh, GREY)
    if pct > 0 then
        draw.RoundedBox(bh / 2, px, by, math.max(bh, math.floor(bw * pct)), bh, WH)
    end
end

vgui.Register("HordeF1AchRow", ACH_ROW, "Panel")

local ACH_PAGE = {}

function ACH_PAGE:Init()
    self.scroll = vgui.Create("HordeF1Scroll", self)
    self.scroll:Configure({ bar_mode = "overlay", gap = S(20), pad_top = S(12), view_top = 0 })
    self.next_req = 0
    self.shown = 0
    self:Rebuild()
end

function ACH_PAGE:Rebuild()
    self.scroll:Clear()
    local A, n = HORDE.PlayerAchievements, 0
    if A then
        local st = A.state
        for _, def in ipairs(A:List()) do
            if not def.hidden or st.unlocked[def.id] then
                local row = vgui.Create("HordeF1AchRow")
                row:Setup(def)
                self.scroll:AddItem(row)
                n = n + 1
            end
        end
    end
    self.shown = n
end

function ACH_PAGE:Think()
    local A = HORDE.PlayerAchievements
    if A and A.Request and CurTime() >= self.next_req then
        self.next_req = CurTime() + 5
        A:Request()
    end
end

function ACH_PAGE:OnSynced()
    local A = HORDE.PlayerAchievements
    if not (A and IsValid(self.scroll)) then return end
    local n = 0
    for _, def in ipairs(A:List()) do
        if not def.hidden or A.state.unlocked[def.id] then n = n + 1 end
    end
    if n ~= self.shown then self:Rebuild() end
end

function ACH_PAGE:PerformLayout(w, h)
    self.scroll:SetPos(0, S(48))
    self.scroll:SetSize(w, S(582))
end

function ACH_PAGE:Paint(w, h)
    DrawPill(0, 0, S(COL_L), S(36), RED)
    DrawPill(S(COL_L + COL_GAP), 0, S(COL_R), S(36), RED)
    draw.SimpleText(T("AchTitle"), Font(25), S(COL_L) / 2, S(18), WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(T("AchProgress"), Font(25), S(COL_L + COL_GAP) + S(COL_R) / 2, S(18), WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    if self.shown == 0 then
        draw.SimpleText(T("AchEmpty"), Font(19), w / 2, S(120), DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

vgui.Register("HordeF1Achievements", ACH_PAGE, "Panel")

local TABS = {
    { id = "guide",        key = "TabGuide",        class = "HordeF1Guide" },
    { id = "keyboard",     key = "TabKeyboard",     class = "HordeF1Keyboard" },
    { id = "almanac",      key = "TabAlmanac",      class = "HordeF1Almanac" },
    { id = "achievements", key = "TabAchievements", class = "HordeF1Achievements" },
}

local AUTO_FILE = "horde/hidemenu.txt"

local function AutoOpenEnabled()
    if file.Exists(AUTO_FILE, "DATA") and file.Read(AUTO_FILE, "DATA") == "false" then return false end
    return true
end

local MODIFIER_CODES = {
    SHIFT = { KEY_LSHIFT, KEY_RSHIFT }, CTRL = { KEY_LCONTROL, KEY_RCONTROL }, ALT = { KEY_LALT, KEY_RALT },
}
local function ComboDown(combo)
    combo = tostring(combo or "")
    if combo == "" then return false end
    for _, part in ipairs(string.Explode("+", combo)) do
        part = string.upper(string.Trim(part))
        local ok = false
        if MODIFIER_CODES[part] then
            for _, c in ipairs(MODIFIER_CODES[part]) do if input.IsKeyDown(c) then ok = true end end
        else
            local code = input.GetKeyCode(part)
            if not code or code <= 0 then code = _G["KEY_" .. part] end
            if isnumber(code) and code > 0 then ok = input.IsKeyDown(code) end
        end
        if not ok then return false end
    end
    return true
end

local PANEL = {}

function PANEL:Init()
    K = math.max(0.5, math.min(ScrH() / 1080, (ScrW() - 20) / BASE_W, (ScrH() - 20) / BASE_H))
    self:SetSize(S(BASE_W), S(BASE_H))
    self:SetPos((ScrW() - self:GetWide()) / 2, (ScrH() - self:GetTall()) / 2)

    self.auto_on = AutoOpenEnabled()
    self.pages, self.tab_btns, self.cur = {}, {}, nil

    local x = S(28)
    surface.SetFont(Font(26))
    for _, tab in ipairs(TABS) do
        local label = T(tab.key)
        local tw = surface.GetTextSize(label)
        local b = MakeButton(self, function(s, w, h)
            local col = (self.cur == tab.id) and RED or (s:IsHovered() and Color(255, 210, 215) or WH)
            draw.SimpleText(label, Font(26), w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end, function() self:ShowTab(tab.id) end)
        b:SetPos(x, S(14))
        b:SetSize(tw + S(4), S(48))
        x = x + tw + S(4) + S(34)
        self.tab_btns[tab.id] = b
    end

    self.auto_btn = MakeButton(self, function(s, w, h)
        local box = S(18)
        local bx, by = w - box, (h - box) / 2
        if self.auto_on then
            draw.RoundedBox(S(4), bx, by, box, box, RED)
        else
            draw.RoundedBox(S(4), bx, by, box, box, GREY)
            draw.RoundedBox(S(3), bx + SB(2), by + SB(2), box - 2 * SB(2), box - 2 * SB(2), WIN)
        end
        draw.SimpleText(FitText(T("AutoOpen"), Font(16), w - box - S(12)), Font(16), bx - S(10), h / 2,
            s:IsHovered() and WH or DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end, function()
        self.auto_on = not self.auto_on
        file.CreateDir("horde")
        file.Write(AUTO_FILE, self.auto_on and "true" or "false")
    end)
    self.auto_btn:SetSize(S(260), S(30))

    local cs = S(28)
    self.close_btn = MakeButton(self, function(s, w, h)
        local col = s:IsHovered() and RED_H or WH
        local m, th = S(7), math.max(2, S(2))
        surface.SetDrawColor(col.r, col.g, col.b, 255)
        for o = -th / 2, th / 2, 0.5 do
            surface.DrawLine(m, m + o, w - m, h - m + o)
            surface.DrawLine(m, h - m + o, w - m, m + o)
        end
    end, function() HORDE:ToggleStats() end)
    self.close_btn:SetSize(cs, cs)
    self.close_btn:SetPos(S(BASE_W - 25) - cs, S(24))
    self.auto_btn:SetPos(S(BASE_W - 25) - cs - S(14) - S(260), S(23))

    hook.Add("Horde_AchievementsSynced", self, function(s)
        local pg = s.pages.achievements
        if IsValid(pg) then pg:OnSynced() end
    end)

    self:ShowTab(HORDE.has_new_update and "almanac" or "guide")

    self._esc = input.IsKeyDown(KEY_ESCAPE)
    self._stats_down = ComboDown(EffectiveKey("stats"))
end

function PANEL:ShowTab(id)
    if self.cur == id then return end
    self.cur = id
    for _, p in pairs(self.pages) do if IsValid(p) then p:SetVisible(false) end end
    local page = self.pages[id]
    if not IsValid(page) then
        for _, tab in ipairs(TABS) do
            if tab.id == id then
                page = vgui.Create(tab.class, self)
                page:SetPos(S(27), S(72))
                page:SetSize(S(PAGE_W), S(PAGE_H))
                self.pages[id] = page
            end
        end
    end
    if IsValid(page) then page:SetVisible(true) end
end

function PANEL:IsCapturing()
    local kb = self.pages.keyboard
    return IsValid(kb) and kb:IsVisible() and kb:IsCapturing()
end

function PANEL:Think()
    local esc = input.IsKeyDown(KEY_ESCAPE)
    local stats = ComboDown(EffectiveKey("stats"))
    local capturing = self:IsCapturing()

    if esc and not self._esc then
        gui.HideGameUI()
        if not capturing then
            self._esc, self._stats_down = esc, stats
            HORDE:ToggleStats()
            return
        end
    end
    if stats and not self._stats_down and not capturing then
        self._esc, self._stats_down = esc, stats
        HORDE:ToggleStats()
        return
    end
    self._esc, self._stats_down = esc, stats
end

function PANEL:Paint(w, h)
    local r, b = S(14), SB(2)
    draw.RoundedBox(r, 0, 0, w, h, RED)
    draw.RoundedBox(math.max(0, r - b), b, b, w - 2 * b, h - 2 * b, WIN)
end

vgui.Register("HordeStats", PANEL, "Panel")

HORDE_OpenMenu = HORDE_OpenMenu == nil and true or HORDE_OpenMenu
hook.Add("HUDPaint", "HORDE_AutoMenu", function()
    if HORDE_OpenMenu == true then
        HORDE_OpenMenu = false
        if not AutoOpenEnabled() then return end
        HORDE:ToggleStats()
    end
end)

hook.Add("Horde_AchievementReceived", "HordeF1_AchToast", function(id, def)
    local name = def and Loc(def.name) or id
    if notification and notification.AddLegacy then
        notification.AddLegacy(T("AchUnlocked", name), NOTIFY_GENERIC, 6)
    end
    surface.PlaySound("garrysmod/content_downloaded.wav")
end)
