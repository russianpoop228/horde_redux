AddCSLuaFile()

if CLIENT then
	SWEP.BounceWeaponIcon	= false
	language.Add("horde_wardenstaff", "Warden's Watchtower Staff")
end

SWEP.PrintName			= "Warden's Watchtower Staff"
SWEP.Slot				= 3
SWEP.SlotPos			= 3
SWEP.DrawAmmo			= false
SWEP.HoldType			= "slam"

SWEP.Weight				= 0
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Purpose			= "Builds and manages the Warden's Watchtowers using Money."
SWEP.Instructions		= "Left Click to open the Watchtower menu.\nLeft Click to confirm placement while aiming.\nRight Click to cancel placement while placing."
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
SWEP.ViewModel			= "models/horde/weapons/buddyfinder_c.mdl"
SWEP.WorldModel			= "models/horde/weapons/buddyfinder_w.mdl"

SWEP.ViewModelBoneMods = {
	["ValveBiped.square"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}

SWEP.VElements = {
	["v_element"] = { type = "Model", model = "models/horde/weapons/buddyfinder_w.mdl", bone = "ValveBiped.square", rel = "", pos = Vector(0, 3.834, -2.504), angle = Angle(90, 0, -90), size = Vector(0.8, 0.8, 0.8), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
}

SWEP.WElements = {
	["w_element"] = { type = "Model", model = "models/horde/weapons/buddyfinder_w.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.734, 1.621, 0.794), angle = Angle(-6.981, 0, 174.233), size = Vector(0.8, 0.8, 0.8), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
}

if CLIENT then
    local function CreateWardenWorldModel(self)
        if IsValid(self._WardenWorldModel) then return self._WardenWorldModel end

        local wm = ClientsideModel("models/horde/weapons/buddyfinder_w.mdl", RENDERGROUP_OPAQUE)
        if not IsValid(wm) then return nil end

        wm:SetNoDraw(true)
        wm:SetModelScale(0.8, 0)
        self._WardenWorldModel = wm
        return wm
    end

    function SWEP:DrawWorldModel()
        local owner = self:GetOwner()
        local wm = CreateWardenWorldModel(self)
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
                        + ang:Forward() * 6
                        + ang:Right() * 2
                        + ang:Up() * -2

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
		self._WardenVMDown = self._WardenVMDown or 0

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
				if tr.Entity:GetClass() == "horde_wardenconstruction" then
					lookingAtConstruction = true
				elseif tr.Entity:GetNWString("Horde_BuiltClass", "") ~= ""
					and tr.Entity:GetNWEntity("HordeOwner") == ply then
					lookingAtConstruction = true
				end
			end
		end

		local shouldLower = self:GetReadytoBuild() or lookingAtConstruction
		local target = shouldLower and 6 or 0
		self._WardenVMDown = Lerp(math.Clamp(FrameTime() * 10, 0, 1), self._WardenVMDown, target)

		pos = pos - ang:Up() * self._WardenVMDown
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
		self.WardenCarryOver = nil
		if timer.Exists("Horde_WardenGhost_" .. self:EntIndex()) then
			timer.Remove("Horde_WardenGhost_" .. self:EntIndex())
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

local function WardenPlacementTrace(ply)
	return util.TraceLine({
		start = ply:GetShootPos(),
		endpos = ply:GetShootPos() + ply:GetAimVector() * PLACEMENT_RANGE,
		filter = ply,
		mask = MASK_SOLID,
	})
end

local WARDEN_BLOCKED_TEX_KEYWORDS = {
	"tools/",
	"playerclip",
	"npcclip",
	"toolsclip",
	"toolstrigger",
	"toolsskybox",
	"toolsblocklos",
	"toolshint",
	"toolsskip",
	"toolsoccluder",
	"toolsinvisible",
	"nodraw",
	"invisible",
}

local function WardenIsToolOrClipTexture(tr)
	if not tr.HitTexture or tr.HitTexture == "" or tr.HitTexture == "**empty**" then
		return false
	end
	local tex = string.lower(tr.HitTexture)
	for _, kw in ipairs(WARDEN_BLOCKED_TEX_KEYWORDS) do
		if string.find(tex, kw, 1, true) then
			return true
		end
	end
	return false
end

local function WardenIsFloorSurface(tr)
	if not tr.Hit or not tr.HitNormal or tr.HitNormal.z < 0.7 then
		return false
	end
	if WardenIsToolOrClipTexture(tr) then
		return false
	end
	return true
end

if SERVER then

local function Horde_UpdateGhost(self)
	if not self:IsValid() or not self:GetReadytoBuild() then return end
	local own = self:GetOwner()
	if not IsValid(own) then self:Horde_StopPlacement() return end

	local tr = WardenPlacementTrace(own)
	if WardenIsFloorSurface(tr) then
		if not IsValid(self.buildEnt) then
			self.buildEnt = ents.Create("horde_wardenconstruction")
			if not IsValid(self.buildEnt) then return end
			self.buildEnt.EntToBuild = self.WardenBuildClass
			self.buildEnt:SetColor(Color(120,160,255,50))
			self.buildEnt:SetModel(HORDE:Horde_GetWardenBuildableData(self.WardenBuildClass).Model)
			self.buildEnt:SetRenderMode(RENDERMODE_TRANSCOLOR)
			self.buildEnt:SetPos(tr.HitPos + tr.HitNormal * (self.WardenModelHeight or 0))
			self.buildEnt:SetAngles(Angle(0, own:GetAngles().y + 180, 0))
			self.buildEnt:SetState(0)
			local mins, maxs = self.buildEnt:GetModelBounds()
			self.WardenModelHeight = mins and -mins.z or 0
		else
			self.buildEnt:SetPos(tr.HitPos + tr.HitNormal * (self.WardenModelHeight or 0))
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
	self.WardenBuildClass = class
	self.WardenModelHeight = 0
	self.WardenCarryOver = carry_over
	self.buildEnt = nil
	self:SetReadytoBuild(true)
	timer.Create("Horde_WardenGhost_" .. self:EntIndex(), 0.1, 0, function()
		if not IsValid(self) then return end
		Horde_UpdateGhost(self)
	end)
end

util.AddNetworkString("Horde_WardenOpenMenu")

end

function SWEP:PrimaryAttack()
	local own = self:GetOwner()
	if not IsValid(own) then return end

	if self:GetReadytoBuild() then
		self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

		if SERVER then
			if not IsValid(self.buildEnt) then return end

			local tr = WardenPlacementTrace(own)
			if not WardenIsFloorSurface(tr) then return end

			local class = self.WardenBuildClass

			self.buildEnt.EntToBuild = class
			self.buildEnt.DeployTime = HORDE:Horde_GetWardenBuildableDeployTime(class)
			self.buildEnt.CarryOver = self.WardenCarryOver
			self.buildEnt:SetColor(Color(120,160,255,100))
			self.buildEnt:SetOwner(own)
			self.buildEnt:SetNick(HORDE:Horde_GetWardenBuildablePrintName(class))
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

		net.Start("Horde_WardenOpenMenu")
		net.Send(owner)
	end
end

function SWEP:SecondaryAttack()
	if self:GetReadytoBuild() then
		self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
		if SERVER then
			self:Horde_StopPlacement()
		end
		return
	end
end

function SWEP:Horde_MeleeSwing(damage, sound_variant)
	local own = self:GetOwner()
	if not IsValid(own) then return end
	local dir = self:GetForward()
	local src = own:GetShootPos() - dir * 64
	own:LagCompensation(true)

	local tr = util.TraceHull({
		start = own:GetShootPos(),
		endpos = own:GetShootPos() + own:GetAimVector() * 96,
		filter = own,
		mins = Vector(-16, -16, 0),
		maxs = Vector(16, 16, 0),
		mask = MASK_SHOT_HULL,
	})

	own:SetAnimation(PLAYER_ATTACK1)
	self:SendWeaponAnim(ACT_VM_HITCENTER)
	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )
	own:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 80, math.random(95, 100))

	if CLIENT then return end

	if IsValid(tr.Entity) and not tr.Entity:IsWorld() then
		own:EmitSound(")weapons/cbar_hitbod" .. math.random(1,3) .. ".wav", 80, math.random(95, 100))
		if HORDE:IsEnemy(tr.Entity) then
			self:FireBullets({
				Attacker = own,
				Damage = damage,
				Force = 1,
				Distance = 1024,
				HullSize = 16,
				Num = 1,
				Tracer = 1,
				Src = src,
				Dir = dir,
				Spread = Vector(0, 0, 0),
				IgnoreEntity = self,
			})
		end
	elseif tr.Entity:IsWorld() then
		own:EmitSound("weapons/cbar_hit" .. math.random(1,2) .. ".wav", 80, math.random(95, 100))
	end
	own:LagCompensation(false)
end

if CLIENT then

surface.CreateFont("Warden_Body", { font = "CloseCaption_Normal", size = 18, weight = 500 })

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
	return translate.Get("Buildable_Desc_" .. class) or HORDE:Horde_GetWardenBuildableDescription(class)
end
local function InfusionLabel(id)
	local nm = HORDE.Infusion_Names[id]
	return (nm and translate.Get("Infusion_" .. nm)) or nm
end
local function InfusionLabelDesc(id)
	local nm = HORDE.Infusion_Names[id]
	return (nm and translate.Get("Infusion_Description_" .. nm)) or HORDE.Infusion_Description[id]
end

local CATEGORY_LABELS = { defense = BT("Defense"), support = BT("Support") }
local CATEGORY_ORDER  = { "defense", "support" }

local function FormatDamage(v)
	return tostring(v) .. BT(" DMG")
end

local function FormatFireRate(v)
	if isnumber(v) then return string.format("%.2g/s", v):gsub("%.?0+/", "/") end
	return tostring(v)
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

local function FormatConsumableLine(class, level)
	local ctype = HORDE:Horde_GetWardenBuildableConsumableType(class)
	local lvl_suffix = level > 0 and (BT(" (Lvl ") .. level .. ")") or ""
	if ctype == "lifetime" then
		local base = HORDE:Horde_GetWardenBuildableLifetime(class)
		local bonus = HORDE:Horde_GetWardenBuildableBonusAtLevel(class, "Bonus_Lifetime", level)
		local total = math.floor(base + bonus)
		local mins = math.floor(total / 60)
		local secs = total % 60
		local label = mins > 0 and (mins .. "m " .. secs .. "s") or (secs .. "s")
		return BT("Expires: After ") .. label .. lvl_suffix
	elseif ctype == "damage_charges" then
		local base = HORDE:Horde_GetWardenBuildableDamageCharges(class)
		local bonus = HORDE:Horde_GetWardenBuildableBonusAtLevel(class, "Bonus_DamageCharges", level)
		local total = math.floor(base + bonus)
		return BT("Charges: ") .. total .. BT(" hits") .. lvl_suffix
	elseif ctype == "wave_limited" then
		return BT("Expires: End of current wave")
	end
	return nil
end

local function OpenWardenMenu()
	if IsValid(WardenBuilderMenu) then WardenBuilderMenu:Close() end

	local frame = vgui.Create("DFrame")
	WardenBuilderMenu = frame
	frame:SetSize(820, 460)
	frame:Center()
	frame:SetTitle("")
	frame:ShowCloseButton(false)
	frame:SetDraggable(false)
	frame:MakePopup()
	frame.State = { tab = "defense", selected = nil, cards = {} }

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
		draw.SimpleText(BT("Warding Units"), "Trebuchet24", 16, h / 2, COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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
		if WardenBuilderMenu == self then WardenBuilderMenu = nil end
	end

	local close_btn = vgui.Create("DButton", header)
	close_btn:SetText("")
	close_btn:SetSize(20, 20)
	close_btn:SetPos(810 - 16 - 20, 10)
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

		if cat == "defense" then
			btn:SetPos(0, 0)
		elseif cat == "support" then
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
	item_desc:SetFont("Warden_Body")
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
		draw.SimpleText(self.costs_text, "Warden_Body", 0, h / 2, COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(self.level_text, "Warden_Body", w, h / 2, COL_WHITE, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
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
			draw.SimpleText(isstring(label) and label or btn.Label, "Warden_Body", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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

		if btn_infuse:IsVisible() then
			btn_destroy:SetPos(0, ch + 10)     btn_destroy:SetSize(cw, ch)
			btn_infuse:SetPos(cw + 14, ch + 10) btn_infuse:SetSize(cw, ch)
		else
			btn_destroy:SetPos(0, ch + 10)     btn_destroy:SetSize(w, ch)
		end
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
			draw.SimpleText(line, "Warden_Body", 0, y, COL_WHITE)
			y = y + 22
		end
	end

	function frame:UpdateDetails(data)
		self.State.selected = data.ClassName
		item_title:SetText(BuildableName(data))
		item_desc:SetText(BuildableDesc(data.ClassName))

		SetupViewportModel(viewport, data.Model)
		do
			local c = HORDE.WardenBuildableColors and HORDE.WardenBuildableColors[data.ClassName]
			local col = c or Color(255, 255, 255)
			viewport:SetColor(col)
			if IsValid(viewport.Entity) then
				viewport.Entity:SetColor(col)
			end
		end

		btn_infuse:SetVisible(data.Category == "defense")
		actions:InvalidateLayout(true)

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
			OpenWardenInfusionsModal(frame, data.ClassName)
		end

		self:RefreshDynamic()
	end

	function frame:RefreshDynamic()
		local class = self.State.selected
		if not class then return end

		local cost = HORDE:Horde_GetWardenBuildableCostFor(MySelf, class)
		local level = IsValid(MySelf) and MySelf:Horde_GetUpgrade(class) or 0
		meta_row.costs_text = BF("Builder_CostsMoney", "Costs: $%d", cost)
		meta_row.level_text = BF("Builder_Level", "Level: %d/%d", level, HORDE.Warden_MaxUpgradeLevel)

		local data = HORDE:Horde_GetWardenBuildableData(class) or {}
		local base_dmg = HORDE:Horde_GetWardenBuildableDamage(class)
		local display_dmg = HORDE:Horde_GetWardenBuildableCurrentDamage(class, MySelf)
		local base_firerate = HORDE:Horde_GetWardenBuildableFireRate(class)
		local display_delay = HORDE:Horde_GetWardenBuildableCurrentAttackDelay(class, MySelf)
		local dmgtype = HORDE:Horde_GetWardenBuildableDamageType(class)

		local has_combat = isnumber(base_dmg)
		local has_speed  = isnumber(base_firerate) and isnumber(display_delay)
		local has_type   = isstring(dmgtype) and dmgtype ~= "N/A" and dmgtype ~= ""

		local lvl_suffix = level > 0 and (BT(" (Lvl ") .. level .. ")") or ""
		local lines = {}

		local consumable_line = FormatConsumableLine(class, level)
		if consumable_line then table.insert(lines, consumable_line) end

		if has_combat then
			table.insert(lines, BT("Deals Damage: ") .. FormatDamage(display_dmg) .. lvl_suffix)
		end
		if has_speed then
			table.insert(lines, BT("Attack Delay: ") .. string.format("%.2g", display_delay) .. ((display_delay ~= 1) and BT(" Seconds") or BT(" Second")) .. lvl_suffix)
		end
		if has_type then
			table.insert(lines, BT("Damage Type: ") .. dmgtype)
		end
		specs.lines = lines

		local built = GetBuiltCount(class)
		local limit = HORDE:Horde_GetWardenBuildableLimit(class)

		btn_build:SetEnabled(built < limit)
		btn_upgrade:SetEnabled(level < HORDE.Warden_MaxUpgradeLevel)
		btn_destroy:SetEnabled(built > 0)

		if level < HORDE.Warden_MaxUpgradeLevel then
			local up_price = HORDE:Horde_GetWardenBuildableUpgradePrice(class, level, MySelf)
			local pct = math.floor((HORDE:Horde_GetWardenBuildableUpgradePricePercent(class) or 0.1) * 100)
			btn_upgrade:SetTooltip(BF("Builder_NextLevelMoney", "Next level: $%d (%d%% of your Money)", up_price, pct))
		else
			btn_upgrade:SetTooltip(BT("Max level reached"))
		end
	end

	function frame:RebuildGrid()
		grid_canvas:Clear()
		local list = HORDE:Horde_GetWardenBuildablesByCategory(self.State.tab)
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

				if data.Icon then
					surface.SetMaterial(Material(data.Icon))
					surface.SetDrawColor(255, 255, 255, 255)
					surface.DrawTexturedRect(w / 2 - 48, 18, 95, 48)
				end

				local built = GetBuiltCount(data.ClassName)
				local limit = HORDE:Horde_GetWardenBuildableLimit(data.ClassName)
				draw.SimpleText(built .. "/" .. limit, "Warden_Body", w / 2, h - 16, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end

			card.DoClick = function()
				frame.State.selected = data.ClassName
				frame:UpdateDetails(data)
			end

			if not first then first = data end
		end

		if first then
			frame.State.selected = first.ClassName
			frame:UpdateDetails(first)
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

function OpenWardenInfusionsModal(frame, buildable_class)
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
	inf_desc:SetFont("Warden_Body")
	inf_desc:SetTextColor(COL_WHITE)
	inf_desc:SetWrap(true)

	local apply_wrap = vgui.Create("DPanel", right_col)
	apply_wrap:Dock(BOTTOM)
	apply_wrap:SetTall(32 + 14)
	apply_wrap:SetPaintBackground(false)

	local apply_btn = vgui.Create("DButton", apply_wrap)
	apply_btn:SetText("")
	surface.SetFont("Warden_Body")
	local apply_tw = surface.GetTextSize(BT("Infuse"))
	apply_btn:SetSize(apply_tw + 56, 32)
	function apply_btn:PerformLayout()
		self:SetPos(apply_wrap:GetWide() - self:GetWide(), apply_wrap:GetTall() - self:GetTall())
	end
	function apply_btn:Paint(w, h)
		draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(240,50,76) or COL_RED)
		draw.SimpleText(BT("Infuse"), "Warden_Body", w/2, h/2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local function SelectInfusion(id)
		box.selected = id
		inf_name:SetText(InfusionLabel(id) or "?")
		inf_desc:SetText(InfusionLabelDesc(id) or "")
	end

	local canvas = vgui.Create("DPanel", grid_scroll)
	canvas:SetPaintBackground(false)
	canvas:SetWide(232)

	local ids = {}
	for id in pairs(HORDE.Infusion_Names) do
		if id ~= HORDE.Infusion_None and HORDE:Horde_IsWardenInfusionAllowed(buildable_class, id) then
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

net.Receive("Horde_WardenOpenMenu", function()
	if IsValid(WardenBuilderMenu) then
		WardenBuilderMenu:Close()
		return
	end
	OpenWardenMenu()
end)

end
