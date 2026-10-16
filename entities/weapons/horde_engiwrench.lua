AddCSLuaFile()

if CLIENT then
	SWEP.BounceWeaponIcon	= false
	language.Add("horde_engiwrench", "Personal Pocket Constructor")
end

SWEP.PrintName			= "Personal Pocket Constructor"
SWEP.Slot				= 3
SWEP.SlotPos			= 3
SWEP.DrawAmmo			= false
SWEP.HoldType			= "slam"

SWEP.Weight				= 0
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Purpose			= "Builds and manages the Engineer's constructions using Metal."
SWEP.Instructions		= "Left Click to open the Builder menu.\nLeft Click to confirm placement while aiming.\nRight Click to cancel placement while placing."
SWEP.Category           = "Horde"
SWEP.DrawCrosshair		= false
SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false

SWEP.Primary = SWEP.Primary or {}
SWEP.Primary.Delay = 0.5
SWEP.Secondary = SWEP.Secondary or {}
SWEP.Secondary.Delay = 0.5

SWEP.ViewModelFOV		= 75
SWEP.ViewModelFlip		= false
SWEP.UseHands 			= true
SWEP.ViewModel			= "models/horde/weapons/v_builder_engineer.mdl"
SWEP.WorldModel			= "models/horde/weapons/w_builder.mdl"

SWEP.ViewModelBoneMods = {
	["ValveBiped.square"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}

SWEP.VElements = {
	["v_element"] = { type = "Model", model = "models/horde/weapons/w_builder.mdl", bone = "ValveBiped.square", rel = "", pos = Vector(0, 3.834, -2.504), angle = Angle(90, 0, -90), size = Vector(0.8, 0.8, 0.8), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
}

SWEP.WElements = {
	["w_element"] = { type = "Model", model = "models/horde/weapons/w_builder.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.734, 1.621, 0.794), angle = Angle(-6.981, 0, 174.233), size = Vector(0.8, 0.8, 0.8), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
}

if CLIENT then
    local function CreateEngiWorldModel(self)
        if IsValid(self._EngiWorldModel) then return self._EngiWorldModel end

        local wm = ClientsideModel("models/horde/weapons/w_builder.mdl", RENDERGROUP_OPAQUE)
        if not IsValid(wm) then return nil end

        wm:SetNoDraw(true)
        wm:SetModelScale(0.8, 0)
        self._EngiWorldModel = wm
        return wm
    end

    function SWEP:DrawWorldModel()
        local owner = self:GetOwner()
        local wm = CreateEngiWorldModel(self)
        if not IsValid(wm) then return end

        if IsValid(owner) and owner:IsPlayer() then
            local bone = owner:LookupBone("ValveBiped.Bip01_R_Hand")
            local pos, ang

            if bone and bone >= 0 then
                local matrix = owner:GetBoneMatrix(bone)
                if matrix then
                    pos = matrix:GetTranslation()
                    ang = matrix:GetAngles()

                    pos = pos
                        + ang:Forward() * 2.734
                        + ang:Right() * 2.621
                        + ang:Up() * 0.25

                    ang:RotateAroundAxis(ang:Forward(), -180)
                    ang:RotateAroundAxis(ang:Up(), 190)
                end
            end

            if not pos then
                local attachment = owner:LookupAttachment("anim_attachment_RH")
                if attachment and attachment > 0 then
                    local data = owner:GetAttachment(attachment)
                    if data then
                        pos = data.Pos
                        ang = data.Ang
                    end
                end
            end

            if pos and ang then
                wm:SetRenderOrigin(pos)
                wm:SetRenderAngles(ang)
                wm:SetupBones()
                wm:DrawModel()
                return
            end
        end

        wm:SetRenderOrigin(self:GetPos())
        wm:SetRenderAngles(self:GetAngles())
        wm:SetupBones()
        wm:DrawModel()
    end
end
if CLIENT then
	function SWEP:GetViewModelPosition(pos, ang)
		self._EngiVMDown = self._EngiVMDown or 0

		local ply = LocalPlayer()
		local lookingAtConstruction = false

		if IsValid(ply) then
			local tr = util.TraceLine({
				start = ply:GetShootPos(),
				endpos = ply:GetShootPos() + ply:GetAimVector() * 96,
				filter = ply,
				mask = MASK_SOLID,
			})

			if IsValid(tr.Entity) then
				if tr.Entity:GetClass() == "horde_engiconstruction" then
					lookingAtConstruction = true
				elseif tr.Entity:GetNWString("Horde_BuiltClass", "") ~= ""
					and tr.Entity:GetNWEntity("HordeOwner") == ply then
					lookingAtConstruction = true
				end
			end
		end

		local shouldLower = self:GetReadytoBuild() or lookingAtConstruction
		local target = shouldLower and 6 or 0
		self._EngiVMDown = Lerp(math.Clamp(FrameTime() * 10, 0, 1), self._EngiVMDown, target)

		pos = pos - ang:Up() * self._EngiVMDown
		return pos, ang
	end
end

local PLACEMENT_RANGE = 96

function SWEP:SetupDataTables()
	self:NetworkVar( "Bool", 0, "ReadytoBuild" )
end

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
	self:SetWeaponHoldType(self.HoldType)
	self.Idle = 0
	self.IdleTimer = CurTime() + 1
end

function SWEP:Deploy()
	self:SendWeaponAnim(ACT_VM_DRAW)
	self:SetNextPrimaryFire( CurTime() + self:SequenceDuration())
	self:SetNextSecondaryFire( CurTime() + self:SequenceDuration())
	self.Idle = 0
	if IsValid(self.Owner) and IsValid(self.Owner:GetViewModel()) then
		self.IdleTimer = CurTime() + self.Owner:GetViewModel():SequenceDuration()
	end
	return true
end

function SWEP:Horde_StopPlacement()
	if SERVER then
		local cost = self.Horde_BuilderPaidCost
		if cost and cost > 0 then
			local ply = self:GetOwner()
			if IsValid(ply) then
				if self.Horde_BuilderCurrency == "metal" then
					ply:Horde_AddMetal(cost)
				else
					ply:Horde_AddMoney(cost)
				end
				if ply.Horde_SyncEconomy then ply:Horde_SyncEconomy() end
			end
		end
		self.Horde_BuilderPaidCost = nil
		self.Horde_BuilderCurrency = nil

		if IsValid(self.buildEnt) then
			self.buildEnt:Remove()
		end
		self.buildEnt = nil
		self.EngiCarryOver = nil
		if timer.Exists("Horde_EngiGhost_" .. self:EntIndex()) then
			timer.Remove("Horde_EngiGhost_" .. self:EntIndex())
		end
		if self:IsValid() then
			self:SetReadytoBuild(false)
		end
	end
end

function SWEP:OnDrop()
	self:Horde_StopPlacement()
end

function SWEP:OnRemove()
	self:Horde_StopPlacement()
end

function SWEP:Holster()
	self:Horde_StopPlacement()
	self.Idle = 0
	self.IdleTimer = CurTime()
	return true
end

local function EngiPlacementTrace(ply)
	return util.TraceLine({
		start = ply:GetShootPos(),
		endpos = ply:GetShootPos() + ply:GetAimVector() * PLACEMENT_RANGE,
		filter = ply,
		mask = MASK_SOLID,
	})
end

if SERVER then

local function Horde_UpdateGhost(self)
	if not self:IsValid() or not self:GetReadytoBuild() then return end
	local own = self:GetOwner()
	if not IsValid(own) then self:Horde_StopPlacement() return end

	local tr = EngiPlacementTrace(own)
	if tr.Hit then
		if not IsValid(self.buildEnt) then
			self.buildEnt = ents.Create("horde_engiconstruction")
			if not IsValid(self.buildEnt) then return end
			self.buildEnt.EntToBuild = self.EngiBuildClass
			self.buildEnt:SetColor(Color(255,255,255,50))
			self.buildEnt:SetModel(HORDE:Horde_GetBuildableData(self.EngiBuildClass).Model)
			self.buildEnt:SetRenderMode(RENDERMODE_TRANSCOLOR)
			self.buildEnt:SetPos(tr.HitPos + tr.HitNormal * (self.EngiModelHeight or 0))
			self.buildEnt:SetAngles(Angle(0, own:GetAngles().y + 180, 0))
			self.buildEnt:SetState(0)
			local mins, maxs = self.buildEnt:GetModelBounds()
			self.EngiModelHeight = mins and -mins.z or 0
		else
			self.buildEnt:SetPos(tr.HitPos + tr.HitNormal * (self.EngiModelHeight or 0))
			self.buildEnt:SetAngles(Angle(0, own:GetAngles().y + 180, 0))
		end
	else
		if IsValid(self.buildEnt) then
			self.buildEnt:Remove()
			self.buildEnt = nil
		end
	end
end

function SWEP:Horde_StartPlacement(class, carry_over)
	self.EngiBuildClass = class
	self.EngiModelHeight = 0
	self.EngiCarryOver = carry_over
	self.buildEnt = nil
	self:SetReadytoBuild(true)
	timer.Create("Horde_EngiGhost_" .. self:EntIndex(), 0.1, 0, function()
		if not IsValid(self) then return end
		Horde_UpdateGhost(self)
	end)
end

util.AddNetworkString("Horde_EngiOpenMenu")

end

function SWEP:PrimaryAttack()
	local own = self:GetOwner()
	if not IsValid(own) then return end

	if self:GetReadytoBuild() then
		self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

		if SERVER then
			if not IsValid(self.buildEnt) then return end

			local tr = EngiPlacementTrace(own)
			if not tr.Hit then return end

			local class = self.EngiBuildClass

			self.buildEnt.EntToBuild = class
			self.buildEnt.DeployTime = HORDE:Horde_GetBuildableDeployTime(class)
			self.buildEnt.CarryOver = self.EngiCarryOver
			self.buildEnt:SetColor(Color(255,255,255,100))
			self.buildEnt:SetOwner(own)
			self.buildEnt:SetNick(HORDE:Horde_GetBuildablePrintName(class))
			self.buildEnt:Spawn()
			self.buildEnt:Activate()
			self.buildEnt:SetState(1)
			self.buildEnt:Horde_CountTowardLimit()
			self.buildEnt = nil

			self.Horde_BuilderPaidCost = nil
			self.Horde_BuilderCurrency = nil

			sound.Play("weapons/building.wav", tr.HitPos, 80, 120)
			local ed = EffectData()
			ed:SetOrigin(tr.HitPos)
			util.Effect("builderef1", ed)

			self:Horde_StopPlacement()
		end
		return
	end
	if SERVER then
		self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
		local owner = self:GetOwner()
		if not IsValid(owner) then return end

		net.Start("Horde_EngiOpenMenu")
		net.Send(owner)
	end
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )

	if self:GetReadytoBuild() then
		if SERVER then
			self:Horde_StopPlacement()
		end
		return
	end
end

function SWEP:Reload()
end

if CLIENT then

surface.CreateFont("Engi_Body", { font = "CloseCaption_Normal", size = 18, weight = 500 })

local COL_RED           = Color(220, 30, 56)
local COL_RED_TEXT      = Color(232, 39, 73)
local COL_PURPLE        = Color(164, 30, 219)
local COL_CARD          = Color(60, 64, 70)
local COL_CARD_HOVER    = Color(72, 77, 84)
local COL_BTN_GRAY      = Color(66, 70, 78)
local COL_BTN_GRAY_HOVER= Color(80, 85, 94)
local COL_WINDOW_BG     = Color(31, 31, 31)
local COL_WHITE         = color_white
local COL_TAB_INACTIVE  = Color(255, 255, 255)
local COL_TAB_HOVER     = Color(187, 187, 188)

local function BT(s) return translate.Get("Builder_" .. s) or s end
local function BF(key, default, ...) return string.format(translate.Get(key) or default, ...) end
local function BuildableName(data)
	return translate.Get("Buildable_" .. data.ClassName) or data.PrintName
end
local function BuildableDesc(class)
	return translate.Get("Buildable_Desc_" .. class) or HORDE:Horde_GetBuildableDescription(class)
end

local CATEGORY_LABELS = { distant = BT("Distant"), nearby = BT("Nearby"), minions = BT("Minions") }
local CATEGORY_ORDER  = { "distant", "nearby", "minions" }

local function FormatFireRate(v)
	if isnumber(v) then return string.format("%.2g", v) .. BT(" BPS") end
	return tostring(v)
end

local function FormatDamage(v)
	return tostring(v) .. BT(" DMG")
end

local function GetBuiltCount(class)
	local drops = IsValid(MySelf) and MySelf:Horde_GetDropEntities()
	return (drops and drops[class]) or 0
end

local function SetupViewportModel(panel, model)
	if not model or model == "" then return end
	panel:SetModel(model)
	local ent = panel.Entity
	if not IsValid(ent) then return end
	local mins, maxs = ent:GetModelBounds()
	local size = 40
	if mins and maxs then size = math.max((maxs - mins):Length(), 8) end
	local dist = size * 0.85
	local center = mins and maxs and (mins + maxs) * 0.5 or Vector(0, 0, 0)
	panel:SetCamPos(center + Vector(dist, dist * 0.8, dist * 0.6))
	panel:SetLookAt(center)
	panel:SetFOV(45)
end

local function OpenBuilderMenu()
	if IsValid(EngiBuilderMenu) then EngiBuilderMenu:Close() end

	local frame = vgui.Create("DFrame")
	EngiBuilderMenu = frame
	frame:SetSize(820, 460)
	frame:Center()
	frame:SetTitle("")
	frame:ShowCloseButton(false)
	frame:SetDraggable(false)
	frame:MakePopup()
	frame.State = { tab = "distant", selected = nil, cards = {} }

	function frame:Paint(w, h)
		draw.RoundedBox(8, 0, 0, w, h, COL_WINDOW_BG)
		surface.SetDrawColor(COL_RED)
		surface.DrawOutlinedRect(0, 0, w, h, 2)
	end

	local header = vgui.Create("DPanel")
	header:SetSize(frame:GetWide(), 40)
	header:SetZPos(1000)

	local function UpdateHeaderPos()
		if not IsValid(frame) or not IsValid(header) then return end
		local x, y = frame:GetPos()
		header:SetPos(x, y - header:GetTall())
		header:SetWide(frame:GetWide())
	end

	UpdateHeaderPos()

	function header:Paint(w, h)
		draw.RoundedBoxEx(8, 0, 0, w, h, COL_RED, true, true, false, false)
		draw.SimpleText(BT("Builder"), "Trebuchet24", 16, h / 2, COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	function header:OnMousePressed(mcode)
		if mcode ~= MOUSE_LEFT then return end
		self.Dragging = { gui.MouseX() - frame:GetX(), gui.MouseY() - frame:GetY() }
		self:MouseCapture(true)
	end

	function header:OnMouseReleased(mcode)
		if mcode ~= MOUSE_LEFT then return end
		self.Dragging = nil
		self:MouseCapture(false)
		UpdateHeaderPos()
	end

	function header:Think()
		if self.Dragging then
			frame:SetPos(gui.MouseX() - self.Dragging[1], gui.MouseY() - self.Dragging[2])
			UpdateHeaderPos()
		end
	end

	local oldOnRemove = frame.OnRemove
	function frame:OnRemove()
		if IsValid(header) then header:Remove() end
		if oldOnRemove then oldOnRemove(self) end
		if EngiBuilderMenu == self then EngiBuilderMenu = nil end
	end

	local is_admin = LocalPlayer():IsSuperAdmin()

	local settings_btn = vgui.Create("DButton", header)
	settings_btn:SetText("")
	settings_btn:SetSize(32, 32)
	settings_btn:SetPos(810 - 16 - 20, 8)
	settings_btn:SetVisible(is_admin)
	function settings_btn:Paint(w, h)
		surface.SetMaterial(Material("perks/pioneer.png"))
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(2, 2, 20, 20)
	end
	settings_btn.DoClick = function()
		if LocalPlayer():IsSuperAdmin() then
			RunConsoleCommand("horde_builder_config")
			frame:Close()
		end
	end

	local close_btn = vgui.Create("DButton", header)
	close_btn:SetText("")
	close_btn:SetSize(20, 20)
	close_btn:SetPos(is_admin and (settings_btn:GetX() - 8 - 20) or (810 - 16 - 20), 10)
	function close_btn:Paint(w, h)
		draw.SimpleText("r", "Marlett", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	close_btn.DoClick = function() frame:Close() end

	local body = vgui.Create("DPanel", frame)
	body:Dock(FILL)
	body:DockMargin(20, -12, 20, 22)
	body:SetPaintBackground(false)

	local left = vgui.Create("DPanel", body)
	left:Dock(LEFT)
	left:SetWide(330)
	left:SetPaintBackground(false)

	local right = vgui.Create("DPanel", body)
	right:Dock(FILL)
	right:DockMargin(30, 0, 0, 0)
	right:SetPaintBackground(false)

	local GRID_PER_ROW, GRID_CARD, GRID_GAP = 3, 100, 10
	local GRID_WIDE = GRID_PER_ROW * GRID_CARD + (GRID_PER_ROW - 1) * GRID_GAP
	local TABS_LEFT_MARGIN = 4

	local tabs_row = vgui.Create("DPanel", left)
	tabs_row:Dock(TOP)
	tabs_row:SetTall(26)
	tabs_row:DockMargin(TABS_LEFT_MARGIN, 0, 0, 12)
	tabs_row:SetPaintBackground(false)

	local tab_buttons = {}
	for _, cat in ipairs(CATEGORY_ORDER) do
		local btn = vgui.Create("DButton", tabs_row)
		btn:SetText("")
		surface.SetFont("Trebuchet24")
		local tw = surface.GetTextSize(CATEGORY_LABELS[cat])
		local bw = tw + 4
		btn:SetSize(bw, 26)

		if cat == "distant" then
			btn:SetPos(0, 0)
		elseif cat == "nearby" then
			local mid_col_center = 1 * (GRID_CARD + GRID_GAP) + GRID_CARD / 2
			btn:SetPos(mid_col_center - TABS_LEFT_MARGIN - bw / 2, 0)
		elseif cat == "minions" then
			local right_edge = GRID_WIDE - TABS_LEFT_MARGIN
			btn:SetPos(right_edge - bw, 0)
		end

		btn.category = cat
		function btn:Paint(w, h)
			local col = COL_TAB_INACTIVE
			if frame.State.tab == self.category then col = COL_RED_TEXT
			elseif self:IsHovered() then col = COL_TAB_HOVER end
			draw.SimpleText(CATEGORY_LABELS[self.category], "Trebuchet24", 0, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		btn.DoClick = function()
			frame.State.tab = cat
			frame:RebuildGrid()
		end
		tab_buttons[cat] = btn
	end

	local grid_scroll = vgui.Create("DScrollPanel", left)
	grid_scroll:Dock(FILL)
	grid_scroll.VBar:SetWide(10)
	grid_scroll.VBar.btnUp:SetVisible(false)
	grid_scroll.VBar.btnDown:SetVisible(false)
	grid_scroll.VBar.btnUp:SetTall(0)
	grid_scroll.VBar.btnDown:SetTall(0)
	function grid_scroll.VBar:Paint(w, h)
		draw.RoundedBox(5, w/2 - 5, 0, 10, h, Color(24, 25, 28))
	end
	function grid_scroll.VBar.btnGrip:Paint(w, h)
		draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(255, 43, 73) or COL_RED)
	end

	local grid_canvas = vgui.Create("DPanel", grid_scroll)
	grid_canvas:SetPaintBackground(false)
	grid_canvas:SetWide(GRID_WIDE)

	local top_section = vgui.Create("DPanel", right)
	top_section:Dock(TOP)
	top_section:SetTall(110)
	top_section:SetPaintBackground(false)

	local viewport = vgui.Create("DModelPanel", top_section)
	viewport:SetSize(110, 110)
	viewport:Dock(RIGHT)
	viewport:SetAmbientLight(Color(190, 190, 190))
	viewport:SetColor(Color(255, 255, 255, 255))
	function viewport:LayoutEntity(ent)
		ent:SetAngles(Angle(0, (RealTime() * 40) % 360, 0))
	end

	local text_details = vgui.Create("DPanel", top_section)
	text_details:Dock(FILL)
	text_details:DockMargin(0, 0, 8, 0)
	text_details:SetPaintBackground(false)

	local item_title = vgui.Create("DLabel", text_details)
	item_title:Dock(TOP)
	item_title:SetTall(28)
	item_title:SetFont("Trebuchet24")
	item_title:SetTextColor(COL_RED_TEXT)

	local item_desc = vgui.Create("DLabel", text_details)
	item_desc:Dock(TOP)
	item_desc:SetTall(78)
	item_desc:SetFont("Engi_Body")
	item_desc:SetTextColor(COL_WHITE)
	item_desc:SetWrap(true)
	item_desc:SetAutoStretchVertical(false)

	local meta_row = vgui.Create("DPanel", right)
	meta_row:Dock(TOP)
	meta_row:SetTall(24)
	meta_row:DockMargin(0, 6, 0, 10)
	meta_row.costs_text = BT("Costs: -")
	meta_row.level_text = BT("Level: -")
	function meta_row:Paint(w, h)
		draw.SimpleText(self.costs_text, "Engi_Body", 0, h / 2, COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(self.level_text, "Engi_Body", w, h / 2, COL_WHITE, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	local actions = vgui.Create("DPanel", right)
	actions:Dock(TOP)
	actions:SetTall(78)
	actions:DockMargin(0, 0, 0, 14)
	actions:SetPaintBackground(false)

	local function MakeActionButton(bg, bg_hover, label)
		local btn = vgui.Create("DButton", actions)
		btn:SetText("")
		function btn:Paint(w, h)
			local col = self:IsEnabled() and (self:IsHovered() and bg_hover or bg) or Color(bg.r * 0.5, bg.g * 0.5, bg.b * 0.5)
			draw.RoundedBox(6, 0, 0, w, h, col)
			draw.SimpleText(isstring(label) and label or btn.Label, "Engi_Body", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		return btn
	end

	local btn_build   = MakeActionButton(COL_RED, Color(240, 50, 76), BT("Build"))
	local btn_upgrade = MakeActionButton(COL_PURPLE, Color(184, 50, 239), nil)
	local btn_destroy = MakeActionButton(COL_BTN_GRAY, COL_BTN_GRAY_HOVER, BT("Destroy"))
	local btn_infuse  = MakeActionButton(COL_BTN_GRAY, COL_BTN_GRAY_HOVER, BT("Infuse"))
	btn_upgrade.Label = BT("Upgrade+1")

	local function LayoutActions()
		local w, h = actions:GetSize()
		local cw = (w - 14) / 2
		local ch = (h - 10) / 2
		btn_build:SetPos(0, 0)          btn_build:SetSize(cw, ch)
		btn_upgrade:SetPos(cw + 14, 0)  btn_upgrade:SetSize(cw, ch)
		btn_destroy:SetPos(0, ch + 10)  btn_destroy:SetSize(cw, ch)
		btn_infuse:SetPos(cw + 14, ch + 10) btn_infuse:SetSize(cw, ch)
	end
	actions.PerformLayout = LayoutActions

	local specs = vgui.Create("DPanel", right)
	specs:Dock(FILL)
	specs:SetPaintBackground(false)
	specs.lines = {}
	function specs:Paint(w, h)
		if not self.lines or #self.lines == 0 then return end
		draw.SimpleText(BT("Specifications:"), "Trebuchet24", 0, 0, COL_RED_TEXT)
		local y = 28
		for _, line in ipairs(self.lines) do
			draw.SimpleText(line, "Engi_Body", 0, y, COL_WHITE)
			y = y + 22
		end
	end

	function frame:UpdateDetails(data)
		self.State.selected = data.ClassName
		item_title:SetText(BuildableName(data))
		item_desc:SetText(BuildableDesc(data.ClassName))

		SetupViewportModel(viewport, data.Model)

		btn_build.DoClick = function()
			net.Start("Horde_BuilderRequestBuild")
				net.WriteString(data.ClassName)
			net.SendToServer()
			frame:Close()
		end
		btn_upgrade.DoClick = function()
			net.Start("Horde_BuilderBuyUpgrade")
				net.WriteString(data.ClassName)
			net.SendToServer()
		end
		btn_destroy.DoClick = function()
			net.Start("Horde_BuilderDestroy")
				net.WriteString(data.ClassName)
			net.SendToServer()
		end
		btn_infuse.DoClick = function()
			OpenInfusionsModal(frame, data.ClassName)
		end

		self:RefreshDynamic()
	end

	function frame:RefreshDynamic()
		local class = self.State.selected
		if not class then return end

		local cost = HORDE:Horde_GetBuildableCostFor(MySelf, class)
		local level = IsValid(MySelf) and MySelf:Horde_GetUpgrade(class) or 0
		meta_row.costs_text = BF("Builder_CostsMetal", "Costs: %d Metal", cost)
		meta_row.level_text = BF("Builder_Level", "Level: %d/%d", level, HORDE.Metal_MaxUpgradeLevel)

		local base_health = HORDE:Horde_GetBuildableHealth(class)
		local cur_health = base_health + HORDE:Horde_GetBuildableBonusAtLevel(class, "Bonus_Health", level)

		local base_dmg = HORDE:Horde_GetBuildableDamage(class)
		local cur_dmg = base_dmg
		if isnumber(base_dmg) then
			cur_dmg = base_dmg + HORDE:Horde_GetBuildableBonusAtLevel(class, "Bonus_Damage", level)
		end

		local base_firerate = HORDE:Horde_GetBuildableFireRate(class)
		local cur_firerate = base_firerate
		if isnumber(base_firerate) then
			cur_firerate = base_firerate + HORDE:Horde_GetBuildableBonusAtLevel(class, "Bonus_FireRate", level)
		end

		local base_ammo = HORDE:Horde_GetBuildableAmmoMax(class)
		local cur_ammo = base_ammo
		if isnumber(base_ammo) then
			cur_ammo = base_ammo + HORDE:Horde_GetBuildableBonusAtLevel(class, "Bonus_AmmoMax", level)
		end

		local lvl_suffix = level > 0 and (BT(" (Lvl ") .. level .. ")") or ""
		local data = HORDE:Horde_GetBuildableData(class) or {}
		local is_minion = data.IsMinion == true

		local dmgtype = HORDE:Horde_GetBuildableDamageType(class)
		local has_combat = isnumber(base_dmg) or (isstring(base_dmg) and base_dmg ~= "N/A")
		local has_speed  = (base_firerate ~= nil) and (base_firerate ~= "N/A") and (base_firerate ~= "Passive")
		local has_ammo   = isnumber(base_ammo)
		local has_type   = isstring(dmgtype) and dmgtype ~= "N/A" and dmgtype ~= ""

		local lines = {}
		if is_minion then
			table.insert(lines, BT("Health: ") .. math.floor(cur_health) .. BT(" HP") .. lvl_suffix)
			if has_speed then
				table.insert(lines, BT("Attack Speed: ") .. FormatFireRate(cur_firerate) .. lvl_suffix)
			end
			if has_type then
				table.insert(lines, BT("Damage Type: ") .. dmgtype)
			end
		elseif has_combat or has_speed or has_ammo or has_type then
			table.insert(lines, BT("Health: ") .. math.floor(cur_health) .. BT(" HP") .. lvl_suffix)
			if has_combat then
				table.insert(lines, BT("Attack Damage: ") .. FormatDamage(cur_dmg) .. lvl_suffix)
			end
			if has_speed then
				table.insert(lines, BT("Attack Speed: ") .. FormatFireRate(cur_firerate) .. lvl_suffix)
			end
			if has_ammo then
				table.insert(lines, BT("Max Ammo: ") .. math.floor(cur_ammo) .. BT(" AMMO") .. lvl_suffix)
			end
			if has_type then
				table.insert(lines, BT("Damage Type: ") .. dmgtype)
			end
		end
		specs.lines = lines

		local built = GetBuiltCount(class)
		local limit = HORDE:Horde_GetBuildableLimit(class)
		local min_level = HORDE:Horde_GetBuildableMinLevel(class)
		local locked = IsValid(MySelf) and MySelf:Horde_GetLevel(HORDE.Class_Engineer) < min_level

		btn_build:SetEnabled(not locked and built < limit)
		btn_upgrade:SetEnabled(level < HORDE.Metal_MaxUpgradeLevel)
		btn_destroy:SetEnabled(built > 0)

		if level < HORDE.Metal_MaxUpgradeLevel then
			local up_price = HORDE:Horde_GetBuildableUpgradePrice(class, level, MySelf)
			local pct = math.floor((HORDE:Horde_GetBuildableUpgradePricePercent(class) or 0.1) * 100)
			local base = HORDE:Horde_GetBuildableUpgradePriceMoney(class)
			btn_upgrade:SetTooltip(BF("Builder_NextLevelMoneyBase", "Next level: $%d ($%d + %d%% of your Money)", up_price, base, pct))
		else
			btn_upgrade:SetTooltip(BT("Max level reached"))
		end
	end

	function frame:RebuildGrid()
		grid_canvas:Clear()
		local list = HORDE:Horde_GetBuildablesByCategory(self.State.tab)
		local per_row, card_size, gap = GRID_PER_ROW, GRID_CARD, GRID_GAP
		grid_canvas:SetTall(math.ceil(#list / per_row) * (card_size + gap))

		local first
		for i, data in ipairs(list) do
			local col = (i - 1) % per_row
			local row = math.floor((i - 1) / per_row)
			local card = vgui.Create("DButton", grid_canvas)
			card:SetText("")
			card:SetPos(col * (card_size + gap), row * (card_size + gap))
			card:SetSize(card_size, card_size)
			card.data = data

			function card:Paint(w, h)
				local bg = COL_CARD
				if frame.State.selected == data.ClassName then bg = COL_RED
				elseif self:IsHovered() then bg = COL_CARD_HOVER end
				draw.RoundedBox(6, 0, 0, w, h, bg)

				surface.SetMaterial(Material(data.Icon))
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawTexturedRect(w / 2 - 48, 18, 95, 48)

				local built = GetBuiltCount(data.ClassName)
				local limit = HORDE:Horde_GetBuildableLimit(data.ClassName)
				draw.SimpleText(built .. "/" .. limit, "Engi_Body", w / 2, h - 16, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end

			card.DoClick = function()
				frame.State.selected = data.ClassName
				frame:UpdateDetails(data)
			end

			if not first then first = data end
		end

		if first then
			self.State.selected = first.ClassName
			self:UpdateDetails(first)
		end
	end

	frame.next_refresh = 0
	local base_think = frame.Think
	function frame:Think()
		if base_think then base_think(self) end
		if CurTime() > self.next_refresh then
			self.next_refresh = CurTime() + 0.25
			self:RefreshDynamic()
		end
	end

	frame:RebuildGrid()
end

function OpenInfusionsModal(frame, buildable_class)
	if not IsValid(frame) then return end
	if IsValid(frame.InfuseModal) then frame.InfuseModal:Remove() end

	local overlay = vgui.Create("DButton", frame)
	overlay:SetPos(0, 0)
	overlay:SetSize(frame:GetWide(), frame:GetTall())
	overlay:SetText("")
	frame.InfuseModal = overlay
	function overlay:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 160)
		surface.DrawRect(0, 0, w, h)
	end
	overlay.DoClick = function() overlay:Remove() end

	local box = vgui.Create("DPanel", overlay)
	box:SetSize(530, 300)
	box:Center()
	box:SetMouseInputEnabled(true)
	box.selected = nil
	function box:Paint(w, h)
		draw.RoundedBox(8, 0, 0, w, h, COL_WINDOW_BG)
		surface.SetDrawColor(COL_RED)
		surface.DrawOutlinedRect(0, 0, w, h, 2)
	end

	local header = vgui.Create("DPanel", box)
	header:Dock(TOP)
	header:SetTall(34)
	function header:Paint(w, h)
		draw.RoundedBoxEx(8, 0, 0, w, h, COL_RED, true, true, false, false)
		draw.SimpleText(BT("Infusions"), "Trebuchet24", 14, h / 2, COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local close_btn = vgui.Create("DButton", header)
	close_btn:SetText("")
	close_btn:SetSize(20, 20)
	function close_btn:PerformLayout() self:SetPos(header:GetWide() - 14 - 20, 6) end
	function close_btn:Paint(w, h)
		draw.SimpleText("r", "Marlett", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	close_btn.DoClick = function() overlay:Remove() end

	local body = vgui.Create("DPanel", box)
	body:Dock(FILL)
	body:DockMargin(16, 14, 16, 16)
	body:SetPaintBackground(false)

	local grid_scroll = vgui.Create("DScrollPanel", body)
	grid_scroll:Dock(LEFT)
	grid_scroll:SetWide(252)
	grid_scroll.VBar:SetWide(8)
	grid_scroll.VBar.btnUp:SetVisible(false)
	grid_scroll.VBar.btnDown:SetVisible(false)
	grid_scroll.VBar.btnUp:SetTall(0)
	grid_scroll.VBar.btnDown:SetTall(0)
	function grid_scroll.VBar:Paint(w, h) draw.RoundedBox(4, w/2-4, 0, 8, h, Color(24,25,28)) end
	function grid_scroll.VBar.btnGrip:Paint(w, h) draw.RoundedBox(3, 0, 0, w, h, COL_RED) end

	local right_col = vgui.Create("DPanel", body)
	right_col:Dock(FILL)
	right_col:DockMargin(6, 0, 0, 0)
	right_col:SetPaintBackground(false)

	local inf_name = vgui.Create("DLabel", right_col)
	inf_name:Dock(TOP)
	inf_name:SetTall(26)
	inf_name:DockMargin(0, 0, 0, 8)
	inf_name:SetFont("Trebuchet24")
	inf_name:SetTextColor(COL_RED_TEXT)

	local inf_desc = vgui.Create("DLabel", right_col)
	inf_desc:Dock(FILL)
	inf_desc:SetFont("Engi_Body")
	inf_desc:SetTextColor(COL_WHITE)
	inf_desc:SetWrap(true)

	local apply_wrap = vgui.Create("DPanel", right_col)
	apply_wrap:Dock(BOTTOM)
	apply_wrap:SetTall(32 + 14)
	apply_wrap:SetPaintBackground(false)

	local apply_btn = vgui.Create("DButton", apply_wrap)
	apply_btn:SetText("")
	surface.SetFont("Engi_Body")
	local apply_tw = surface.GetTextSize(BT("Infuse"))
	apply_btn:SetSize(apply_tw + 56, 32)
	function apply_btn:PerformLayout()
		self:SetPos(apply_wrap:GetWide() - self:GetWide(), apply_wrap:GetTall() - self:GetTall())
	end
	function apply_btn:Paint(w, h)
		draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(240,50,76) or COL_RED)
		draw.SimpleText(BT("Infuse"), "Engi_Body", w/2, h/2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local function SelectInfusion(id)
		box.selected = id
		local iname = HORDE.Infusion_Names[id]
		inf_name:SetText((iname and translate.Get("Infusion_" .. iname)) or iname or "?")
		inf_desc:SetText((iname and translate.Get("Infusion_Description_" .. iname)) or HORDE.Infusion_Description[id] or "")
	end

	local canvas = vgui.Create("DPanel", grid_scroll)
	canvas:SetPaintBackground(false)
	canvas:SetWide(232)

	local ids = {}
	for id in pairs(HORDE.Infusion_Names) do
		if id ~= HORDE.Infusion_None and HORDE:Horde_IsInfusionAllowed(buildable_class, id) then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b) return HORDE.Infusion_Names[a] < HORDE.Infusion_Names[b] end)

	local per_row, size, gap = 3, 72, 8
	canvas:SetTall(math.ceil(#ids / per_row) * (size + gap))
	local current = (IsValid(MySelf) and MySelf:Horde_GetBuilderInfusion(buildable_class)) or HORDE.Infusion_None

	for i, id in ipairs(ids) do
		local col = (i - 1) % per_row
		local row = math.floor((i - 1) / per_row)
		local card = vgui.Create("DButton", canvas)
		card:SetText("")
		card:SetPos(col * (size + gap), row * (size + gap))
		card:SetSize(size, size)
		function card:Paint(w, h)
			local bg = COL_CARD
			if box.selected == id then bg = COL_RED
			elseif self:IsHovered() then bg = COL_CARD_HOVER end
			draw.RoundedBox(6, 0, 0, w, h, bg)
			local icon = HORDE.Infusion_Icons[id]
			if icon then
				surface.SetMaterial(Material(icon))
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawTexturedRect(w/2 - 18, h/2 - 18, 36, 36)
			end
		end
		card.DoClick = function() SelectInfusion(id) end
		if id == current then SelectInfusion(id) end
	end

	if not box.selected then SelectInfusion(ids[1]) end

	apply_btn.DoClick = function()
		net.Start("Horde_SetBuilderInfusion")
			net.WriteString(buildable_class)
			net.WriteUInt(box.selected, 5)
		net.SendToServer()
		overlay:Remove()
	end
end

net.Receive("Horde_EngiOpenMenu", function()
	if IsValid(EngiBuilderMenu) then
		EngiBuilderMenu:Close()
		return
	end
	OpenBuilderMenu()
end)

end
