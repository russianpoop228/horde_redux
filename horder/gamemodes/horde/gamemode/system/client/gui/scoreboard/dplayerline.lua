local P_meta = FindMetaTable("Panel")
local P_Player = FindMetaTable("Player")
local P_IsValid = P_meta.IsValid

local PANEL = {}

local function UI_WrapText(text, font, maxW)
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

local _perkTip = nil

PANEL.m_Player = NULL
PANEL.NextRefresh = 0
PANEL.RefreshTime = 1

local draw_RoundedBox = draw.RoundedBox

local function MuteDoClick(self)
	local pl = self:GetParent():GetPlayer()
	if pl:IsValid() then
		pl:SetMuted(not pl:IsMuted())
		self:GetParent().NextRefresh = RealTime()
	end
end

function P_Player:LongName()
	local name = self:Name()
	if #name > 25 then
		name = string.sub(name, 1, 25)..".."
	end

	return name
end

function PANEL:Init()

    self.m_AvatarPanel = vgui.Create("DPanel", self)
    self.m_AvatarPanel:SetText(" ")
	self.m_AvatarPanel:SetSize(32, 32 )
	self.m_AvatarPanel:Center()
	self.m_AvatarPanel:SetPaintBackground(false)

	self.m_AvatarButton = self:Add( "DButton", self.m_AvatarPanel )
	self.m_AvatarButton:SetSize( 32, 32 )
	self.m_AvatarButton:Center()

    self.m_Avatar = vgui.Create("AvatarImage", self.m_AvatarButton)
	self.m_Avatar:SetSize(32, 32)
	self.m_Avatar:SetVisible(false)
	self.m_Avatar:SetMouseInputEnabled(false)

	self.m_PlayerLabel = HORDE:EasyLabel(self, " ", "Content", COLOR_WHITE)
	self.m_KillsLabel = HORDE:EasyLabel(self, " ", "Content", COLOR_WHITE)
	self.m_DeathsLabel = HORDE:EasyLabel(self, " ", "Content", COLOR_WHITE)

	self.m_RankLabel = HORDE:EasyLabel(self, " ", "Content", COLOR_WHITE)

	self.m_MoneyLabel = HORDE:EasyLabel(self, " ", "Content", COLOR_WHITE)

	self.m_PingMeter = vgui.Create("DPingMeter", self)

	self.m_Mute = vgui.Create("DImageButton", self)
	self.m_Mute.DoClick = MuteDoClick

	self:InvalidateLayout()
end

function PANEL:Think()
	if RealTime() >= self.NextRefresh then
		self.NextRefresh = RealTime() + self.RefreshTime
		self:RefreshPlayer()
	end

end

function PANEL:PerformLayout()

	self:SetSize(self:GetWide(), 40)

    local w = self:GetWide()
	local h = self:GetTall()

    self.m_AvatarPanel:AlignLeft(w * 0.015)
	self.m_AvatarPanel:CenterVertical()

	self.m_AvatarButton:AlignLeft(w * 0.015)
	self.m_AvatarButton:CenterVertical()

	self.m_PlayerLabel:SizeToContents()
	self.m_PlayerLabel:AlignLeft(w * 0.05)
	self.m_PlayerLabel:CenterVertical()

	self.m_RankLabel:AlignLeft(w * 0.25)
	self.m_RankLabel:SizeToContents()
	self.m_RankLabel:CenterVertical()

	self.m_MoneyLabel:SizeToContents()
	self.m_MoneyLabel:AlignRight(w * 0.26)
	self.m_MoneyLabel:CenterVertical()

	self.m_KillsLabel:SizeToContents()
	self.m_KillsLabel:AlignRight(w * 0.18, 0)
	self.m_KillsLabel:CenterVertical()

	self.m_DeathsLabel:SizeToContents()
	self.m_DeathsLabel:AlignRight(w * 0.1, 0)
	self.m_DeathsLabel:CenterVertical()

	local pingsize = self:GetTall() - 8

	self.m_PingMeter:SizeToContents()
	self.m_PingMeter:SetSize(self:GetTall() - 2, pingsize)
	self.m_PingMeter:AlignRight(w * 0.02)
	self.m_PingMeter:CenterVertical()

	self.m_Mute:SizeToContents()
	self.m_Mute:SetSize(16, 16)
	self.m_Mute:MoveLeftOf(self.m_PingMeter, 15)
	self.m_Mute:CenterVertical()

end

function PANEL:RefreshPlayer()

	local pl = self:GetPlayer()

	local subclass_name = HORDE.Class_Survivor
    if pl:Horde_GetCurrentSubclass() then
		subclass_name = pl:Horde_GetCurrentSubclass()
	end

    local subclass = HORDE.subclasses[subclass_name]

	local class = translate.Get("Class_" .. subclass.PrintName) or subclass.PrintName

	local name = pl:LongName()
	local color = color_white

	self.m_AvatarPanel:CenterVertical()

	self.m_PlayerLabel:SetText( name )
	self.m_PlayerLabel:SetColor( color )
	self.m_PlayerLabel:SizeToContents()

	self.m_RankLabel:SetText( class )
	self.m_RankLabel:SizeToContents()
	self.m_RankLabel:SetColor( color )

	self.m_MoneyLabel:SizeToContents()
	self.m_MoneyLabel:SetText(pl:Horde_GetMoney().."$")
	self.m_MoneyLabel:SetColor( color )

	self.m_KillsLabel:SizeToContents()
	self.m_KillsLabel:SetText(pl:Frags())
	self.m_KillsLabel:SetColor( color )

	self.m_DeathsLabel:SizeToContents()
	self.m_DeathsLabel:SetText(pl:Deaths())
	self.m_DeathsLabel:SetColor( color )

	self.m_PingMeter:CenterVertical()

	if pl == MySelf then
		self.m_Mute:SetVisible(false)
	else
		if pl:IsMuted() then
			self.m_Mute:SetImage("icon16/sound_mute.png")
		else
			self.m_Mute:SetImage("icon16/sound.png")
		end

	end
	self.m_Mute:SizeToContents()

	self:InvalidateLayout()
end

local colTemp = Color(255, 255, 255, 200)
function PANEL:Paint()

	local wide = self:GetWide()
	local tall = self:GetTall()

	local col = Color(40,40,40,200)
	local mul = 0.5
	local pl = self:GetPlayer()

	if P_IsValid then
		col = Color(40,40,40,200)
		if not pl:Alive() then
			col = Color(100, 0, 0, 200)
		end

		if self.Hovered then
			mul = 2
		end

		colTemp.r = col.r * mul
		colTemp.g = col.g * mul
		colTemp.b = col.b * mul

		draw_RoundedBox(0, 0, 0, wide , tall , colTemp)
    end

    local subclass_name = HORDE.Class_Survivor
    if pl:Horde_GetCurrentSubclass() then subclass_name = pl:Horde_GetCurrentSubclass() end

    local perks
    if HORDE.classes[subclass_name] then
        perks = HORDE.classes[subclass_name].perks
    else
        perks = HORDE.subclasses[subclass_name].Perks
    end

    local gadget = pl:Horde_GetGadget()

    local subclass = HORDE.subclasses[subclass_name]
    if subclass then
        local mat = Material(subclass.Icon, "mips smooth")
        local rank = pl:Horde_GetRank(subclass.PrintName)
        local rank_level = pl:Horde_GetRankLevel(subclass.PrintName)
        surface.SetMaterial(mat)
        surface.SetDrawColor(HORDE.Rank_Colors[rank])
        surface.DrawTexturedRect(wide * 0.215, 2, 38, 38)
        if rank == HORDE.Rank_Master then
            draw.SimpleText(rank_level, "Trebuchet18", wide * 0.2075, 12, HORDE.Rank_Colors[rank], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        else
            if rank_level > 0 then
                local star = Material("star.png", "mips smooth")
                surface.SetMaterial(star)
                local y_pos = 26
                for i = 0, rank_level - 1 do
                    surface.DrawTexturedRect(wide * 0.2075, y_pos, 10, 10)
                    y_pos = y_pos - 7
            	end
        	end
        end

    end

	local perk_x0 = wide * 0.36
	local perk_x1 = wide * 0.526
	local perk_w  = perk_x1 - perk_x0
	local PERK_STEP, PERK_ICON = 40, 35
	local PERK_SCROLL_SPEED = 40
	local perk_list = {}

	if pl.Horde_PerkChoices and pl.Horde_PerkChoices[subclass_name] then
		for perk_level, v in SortedPairs(perks or {}) do
			if (not perk_level) or (not v.choices) then break end
			local choice = v.choices[pl.Horde_PerkChoices[subclass_name][perk_level] or 1]
			local perk = HORDE.perks[choice]
			if perk then
				local color = color_white
				if HORDE.current_wave < HORDE:Horde_GetWaveForPerk(perk_level) then
					color = Color(150,150,150)
				end
				perk_list[#perk_list + 1] = {
					name  = choice,
					perk  = perk,
					icon  = perk.Icon or (subclass and subclass.Icon),
					color = color,
				}
			end
		end
	end

	if #perk_list > 0 then
		local track = #perk_list * PERK_STEP
		local scrolling = track > perk_w
		local passes = scrolling and 2 or 1

		if not self.m_PerkOff then self.m_PerkOff = 0 end
		if scrolling and not self.m_PerkHover then
			self.m_PerkOff = (self.m_PerkOff + FrameTime() * PERK_SCROLL_SPEED) % track
		end
		local off = scrolling and -self.m_PerkOff or 0

		local cx, cy = self:CursorPos()
		local hovered = nil
		if cy >= 2 and cy <= 2 + PERK_ICON then
			for pass = 0, passes - 1 do
				local bx = perk_x0 + off + pass * track
				for _, it in ipairs(perk_list) do
					if cx >= bx and cx <= bx + PERK_ICON then
						hovered = { it = it, x = bx }
					end
					bx = bx + PERK_STEP
				end
			end
		end
		self.m_PerkHover = hovered

		local scissor_ok = false
		if render and render.SetScissorRect then
			local sx, sy  = self:LocalToScreen(perk_x0, 0)
			local _, sy2  = self:LocalToScreen(perk_x0, self:GetTall())
			render.SetScissorRect(sx, sy, sx + perk_w, sy2, true)
			scissor_ok = true
		end

		for pass = 0, passes - 1 do
			local bx = perk_x0 + off + pass * track
			for _, it in ipairs(perk_list) do
				if it.icon then
					surface.SetMaterial(Material(it.icon, "mips smooth"))
					surface.SetDrawColor(it.color)
					surface.DrawTexturedRect(bx, 2, PERK_ICON, PERK_ICON)
				end
				bx = bx + PERK_STEP
			end
		end

		if scissor_ok then render.SetScissorRect(0, 0, 0, 0, false) end

		if hovered then
			local gx, gy = self:LocalToScreen(hovered.x, 2)
			_perkTip = {
				name      = hovered.it.name,
				perk      = hovered.it.perk,
				classname = subclass_name,
				sx        = gx,
				sy        = gy + PERK_ICON,
			}
		end
	end

    if gadget then
        local mat = Material(HORDE.gadgets[gadget].Icon, "mips smooth")
        surface.SetMaterial(mat)
        if HORDE.gadgets[gadget].Active then
            if HORDE.gadgets[gadget].Once then
                surface.SetDrawColor(HORDE.color_gadget_once)
            else
                surface.SetDrawColor(HORDE.color_gadget_active)
            end
        else
            surface.SetDrawColor(color_white)
        end
        surface.DrawTexturedRect(wide * 0.526, -2, 90, 45)
    end

	return true
end

function PANEL:SetPlayer(pl)
	self.m_Player = pl or NULL

	self.m_Avatar:SetPlayer(pl)
	self.m_Avatar:SetVisible(true)

	self.m_AvatarButton.DoClick = function() pl:ShowProfile() end

	self.m_PingMeter:SetPlayer(pl)

	self:RefreshPlayer()
end

function PANEL:GetPlayer()
	return self.m_Player
end

vgui.Register("DPlayerLine", PANEL, "Panel")

local TIP_MAX_W = 340

local function PerkTipLines(name, perk, classname)
    if not perk then return nil end
    local title = translate.Get("Perk_Title_" .. name) or perk.PrintName or name
    local desc  = translate.Get("Perk_" .. name) or perk.Description or ""
    if HORDE.ShopUI and HORDE.ShopUI.FormatParams then
        desc = HORDE.ShopUI.FormatParams(desc, perk.Params, classname)
    end
    desc = string.Trim(desc)
    if desc == "" then return nil end
    return title, desc
end

hook.Add("PostRenderVGUI", "Horde_ScoreboardPerkTip", function()
    local tip = _perkTip
    _perkTip = nil
    if not tip then return end
    if not (IsValid(HORDE.ScoreboardPanel) and HORDE.ScoreboardPanel:IsVisible()) then return end

    local title, desc = PerkTipLines(tip.name, tip.perk, tip.classname)
    if not title then return end

    local f_title = "Content"
    local f_desc  = "Content"
    local pad, lh = 10, 17

    local lines = { { title, f_title, Color(255,255,255) } }
    for _, l in ipairs(UI_WrapText(desc, f_desc, TIP_MAX_W)) do
        lines[#lines + 1] = { l, f_desc, Color(150,152,158) }
    end

    local maxw = 0
    for _, l in ipairs(lines) do
        surface.SetFont(l[2])
        maxw = math.max(maxw, (surface.GetTextSize(l[1])))
    end
    local bw, bh = maxw + pad * 2, #lines * lh + pad * 2 - 2

    local x = math.Clamp(tip.sx, 6, ScrW() - bw - 6)
    local y = math.Clamp(tip.sy + 6, 6, ScrH() - bh - 6)

    draw.RoundedBox(6, x, y, bw, bh, Color(24, 25, 28, 255))
    draw.RoundedBoxEx(6, x, y, bw, 3, Color(220, 30, 56), true, true, false, false)
    for i, l in ipairs(lines) do
        draw.SimpleText(l[1], l[2], x + pad, y + pad - 1 + (i - 0.5) * lh, l[3], TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end)
