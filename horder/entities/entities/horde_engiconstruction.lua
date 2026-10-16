AddCSLuaFile()

ENT.PrintName		= "Construction"
ENT.Type 			= "anim"
ENT.Base 			= "base_gmodentity"
ENT.Spawnable		= false
ENT.AdminOnly 		= true
ENT.DoNotDuplicate 	= false
ENT.EntToBuild = NULL
ENT.DeployTime = 30
ENT._Seen        = false
ENT._Lerp        = 0
ENT._Ler2 		= 0
ENT.Limit = 0

function ENT:SetupDataTables()
	local own = self:GetOwner()
	self:NetworkVar( "Int", 0, "State" )
	self:NetworkVar( "Float", 0, "Progress" )
	self:NetworkVar( "String", 0, "Nick" )
	self:NetworkVar( "Entity", 0, "Owned" )
	if !SERVER then return end
	self:NetworkVarNotify( "Progress", function( self, name, old, new )
		if new >= 99.9 then
			local own = self:GetOwner()
			if self:GetState() == 2 then return end
			self:SetState( 2 )
			self:SpawnEntity()

			sound.Play("weapons/building.wav",self:GetPos() + vector_up*16,80,120)
			self:Remove()
		else
			self:SetColor(Color(255,255,255,math.Clamp(new/100*255,32,192)))
		end
	end )
	self:NetworkVarNotify( "Owned", function( self, name, old, new )
		if old == new then return end
	end )
end

function ENT:SpawnEntity()
	local own = self:GetOwner()
	local class = self.EntToBuild
	local data = HORDE:Horde_GetBuildableData(class)

	if self._CountedAsBuildable and IsValid(own) then
		own:Horde_RemoveDropEntity(class, self:GetCreationID(), true)
		self._CountedAsBuildable = false
	end

	local is_minion = (data and data.IsMinion) and true or false

	self.buildEnt = ents.Create(class)
	if not IsValid(self.buildEnt) then return end

	if data and data.Model and data.Model ~= "" then
		self.buildEnt:SetModel(data.Model)
	end

	local spawn_pos = self:GetPos()
	if is_minion then
		spawn_pos = spawn_pos + Vector(0, 0, 16)
	end
	self.buildEnt:SetPos(spawn_pos)
	self.buildEnt:SetAngles(self:GetAngles())

	if is_minion then
		HORDE:AssignMinionOwner(self.buildEnt, own)
	end

	self.buildEnt:Spawn()
	if not is_minion then
		self.buildEnt:Activate()
	end

	self.buildEnt:SetAngles(self:GetAngles())
	do
		local ent, ang = self.buildEnt, self:GetAngles()
		timer.Simple(0, function()
			if IsValid(ent) then ent:SetAngles(ang) end
		end)
	end

	self.buildEnt.Horde_NoPickup = true
	self.buildEnt:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
	if not is_minion then
		local phys = self.buildEnt:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(false)
			phys:SetMass(50000)
			phys:Wake()
		end
	end

	if not is_minion then
		local anchor = ents.Create("prop_physics")
		if IsValid(anchor) then
			anchor:SetModel("models/hunter/blocks/cube1x1x1.mdl")
			anchor:SetPos(self.buildEnt:GetPos())
			anchor:SetAngles(self.buildEnt:GetAngles())
			anchor:SetParent(self.buildEnt)
			anchor:Spawn()
			anchor:Activate()
			anchor:SetSolid(SOLID_NONE)
			anchor:SetMoveType(MOVETYPE_NONE)
			anchor:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
			anchor:SetNoDraw(true)
			anchor:DrawShadow(false)
			anchor.Horde_NoPickup = true
			local aphys = anchor:GetPhysicsObject()
			if IsValid(aphys) then
				aphys:EnableMotion(false)
				aphys:SetMass(50000)
				aphys:EnableCollisions(false)
			end
			self.buildEnt.Horde_PickupAnchor = anchor
			self.buildEnt:DeleteOnRemove(anchor)
		end
	end

	if self.buildEnt:GetModel() == "models/combine_turrets/floor_turret.mdl" then
		self.buildEnt:SetNWBool("RebSentri",true)
	end
	if not is_minion then
		self.buildEnt:SetSaveValue("m_bPlacedByPlayer",true)
		if self.buildEnt:IsNPC() then
			self.buildEnt:SetSaveValue("m_Efficiency",2)
			self.buildEnt:SetSaveValue("m_CurrentWeaponProficiency",100)
		end
	end
	self.buildEnt:SetNWEntity("HordeOwner", own)
	self.buildEnt:SetNWString("Horde_BuiltClass", class)
	if HORDE:Horde_IsAmmoTrackedBuildable(class) then
		local max_ammo = HORDE:Horde_GetBuildableAmmoMax(class)
		self.buildEnt:SetNWInt("Horde_AmmoMax", max_ammo)
		self.buildEnt:SetNWInt("Horde_AmmoCurrent", max_ammo)
	end
	own:Horde_AddDropEntity(self.buildEnt:GetClass(), self.buildEnt)
	own:Horde_SyncEconomy()
	own:Horde_SetMinionCount(own:Horde_GetMinionCount() + 1)
	HORDE:Horde_ApplyBuildableUpgradeBonus(self.buildEnt, class, own:Horde_GetUpgrade(class))

	if self.CarryOver then
		if self.CarryOver.HealthRatio then
			local hp = math.max(1, math.floor(self.buildEnt:GetMaxHealth() * self.CarryOver.HealthRatio))
			self.buildEnt:SetHealth(hp)
		end
		if self.CarryOver.AmmoRatio and HORDE:Horde_IsAmmoTrackedBuildable(class) then
			local ammo_max = self.buildEnt:GetNWInt("Horde_AmmoMax", 0)
			self.buildEnt:SetNWInt("Horde_AmmoCurrent", math.floor(ammo_max * self.CarryOver.AmmoRatio))
		end
	end
	self.buildEnt.FalldamageImmune = true
	self.buildEnt.Immune_AcidPoisonRadiation = true
	self.buildEnt.Horde_Immune_Bleeding = true
	self.buildEnt.Horde_Immune_Status_All = true

	if data and data.IsMinion and self.buildEnt:IsNPC() then
		HORDE:SetupBuiltMinion(self.buildEnt, own)
	end

	self.buildEnt:CallOnRemove("Horde_EntityRemoved", function(ent)
		if own:IsValid() then
			local owner = ent:GetNWEntity("HordeOwner")
			if IsValid(owner) then
				owner:Horde_RemoveDropEntity(ent:GetClass(), ent:GetCreationID(), true)
				owner:Horde_SyncEconomy()
			end
			own:Horde_SetMinionCount(own:Horde_GetMinionCount() - 1)
		end
	end)
end

function ENT:Horde_CountTowardLimit()
	if CLIENT then return end
	local own = self:GetOwner()
	if not IsValid(own) or self._CountedAsBuildable then return end

	own:Horde_AddDropEntity(self.EntToBuild, self)
	self._CountedAsBuildable = true
	if own.Horde_SyncEconomy then own:Horde_SyncEconomy() end

	self:CallOnRemove("Horde_UncountBuildable", function(ent)
		if not ent._CountedAsBuildable then return end
		if IsValid(own) then
			own:Horde_RemoveDropEntity(ent.EntToBuild, ent:GetCreationID(), true)
			if own.Horde_SyncEconomy then own:Horde_SyncEconomy() end
		end
	end)
end

function ENT:Initialize()
	local own = self:GetOwner()
	if CLIENT then return end
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:DrawShadow(false)
	self:SetUseType(SIMPLE_USE)
	self:SetCollisionGroup( COLLISION_GROUP_PLAYER )
	if self:GetModel() == "models/combine_turrets/floor_turret.mdl" then
		self:SetNWBool("RebSentri",true)
	end
	self:SetProgress( 0 )
	self:SetOwned( own )
	self:GetPhysicsObject():EnableMotion( false )
	self:StartMotionController()

	local final_hp = HORDE:Horde_GetBuildableHealth(self.EntToBuild)
	self._FinalHP = math.max(1, math.floor(final_hp))
	self:SetMaxHealth( self._FinalHP )
	self:SetHealth( 1 )
	self.Horde_IsConstructing = true
	self.Horde_NoPickup = true

	self._BuildStartTime = CurTime()
	self:NextThink( CurTime() )

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
end

function ENT:Think()
	if CLIENT then return end
	if self:GetState() ~= 2 then
		local deploy_time = math.max(0.1, self.DeployTime or 30)
		local pct = math.Clamp( (CurTime() - (self._BuildStartTime or CurTime())) / deploy_time, 0, 1 ) * 100
		self:SetProgress( pct )

		local final_hp = self._FinalHP or self:GetMaxHealth()
		local target = math.max(1, math.floor(final_hp * (pct / 100)))
		if self:Health() < target and not self._RecentlyDamaged then
			self:SetHealth( target )
		end
		if self._RecentlyDamaged and (CurTime() - (self._DamagedAt or 0)) > 1.5 then
			self._RecentlyDamaged = false
		end
	end
	self:NextThink( CurTime() + 0.1 )
	return true
end

function ENT:Use(ply)
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage(dmginfo)
	if CLIENT then return end
	if self.Removing or self:GetState() == 2 then return end
	local dmgtype = dmginfo:GetDamageType()
	if bit.band(dmgtype, DMG_POISON + DMG_ACID + DMG_RADIATION + DMG_NERVEGAS) ~= 0 then
		return
	end
	self:SetHealth( self:Health() - dmginfo:GetDamage() )
	self._RecentlyDamaged = true
	self._DamagedAt = CurTime()
	if self:Health() <= 0 then
		self.Removing = true
		local ed = EffectData()
		ed:SetOrigin(self:GetPos())
		ed:SetEntity(self)
		util.Effect( "entity_remove", ed, true, true )
		self:Remove()
	end
end

function ENT:PhysicsCollide(data, phys)
	if data.DeltaTime > 0.2 then
		if data.Speed > 250 then
			self:EmitSound("physics/metal/metal_box_impact_hard" .. math.random(1, 3) .. ".wav", 75, math.random(90,110), 0.5)
		else
			self:EmitSound("physics/metal/metal_box_impact_soft" .. math.random(1, 3) .. ".wav", 75, math.random(90,110), 0.2)
		end
	end
end

hook.Add( "GetPreferredCarryAngles", "BuilderCarryAngs", function( ent )
	if ent:GetNWBool("RebSentri") then
		return Angle( -10, 0, 0 )
	end
end)

if SERVER then
	local function Horde_BlockPickup(ply, ent)
		if not IsValid(ent) then return end
		if ent.Horde_NoPickup then return false end
		if ent.Horde_IsConstructing then return false end
		if HORDE and HORDE.Horde_IsBuildable and HORDE:Horde_IsBuildable(ent:GetClass()) then
			return false
		end
	end

	hook.Add("PhysgunPickup", "Horde_NoPickupEngineerBuildables", Horde_BlockPickup)
	hook.Add("GravGunPickupAllowed", "Horde_NoPickupEngineerBuildables", Horde_BlockPickup)
	hook.Add("AllowPlayerPickup", "Horde_NoPickupEngineerBuildables", Horde_BlockPickup)

	hook.Add("PlayerUse", "Horde_NoPickupEngineerBuildables", function(ply, ent)
		if not IsValid(ent) then return end
		if ent.Horde_NoPickup or ent.Horde_IsConstructing then return false end
		if HORDE and HORDE.Horde_IsBuildable and HORDE:Horde_IsBuildable(ent:GetClass()) then
			return false
		end
	end)
end

if SERVER then return end

function ENT:OnRemove()
	if self:GetState() > 0 then
		local ed = EffectData()
		ed:SetOrigin(self:GetPos())
		ed:SetEntity(self)
		util.Effect( "entity_remove", ed, true, true )
	end
end

function ENT:Think()
	if self._Seen != self:BeingLookedAtByLocalPlayer() then
		self._Seen = self:BeingLookedAtByLocalPlayer()  self._Lerp = SysTime() +0.2
	end
	self._Ler2 = Lerp( 0.1, self._Ler2, self:GetProgress() )
end

local glow = Material( "models/wireframe" )
local Mat = Material( "particle/particle_ring_wave_addnofog" )

function ENT:Draw()
	self:DrawModel( )

	render.CullMode(MATERIAL_CULLMODE_CW)
		self.DrawModel( self )
	render.CullMode(MATERIAL_CULLMODE_CCW)

	if self:GetState() == 0 then
        render.SuppressEngineLighting( true )
        render.SetBlend( 0.25 ) render.MaterialOverride( glow )
        render.SetColorModulation( 1, 1, 0 )
        self:DrawModel()
        render.SetBlend( 1 ) render.MaterialOverride()
        render.SetColorModulation( 1, 1, 1 )
        render.SuppressEngineLighting( false )
	else
		local pro = math.Clamp( 1 -self:GetProgress()/100, 0, 1 )
        render.SuppressEngineLighting( true )
        render.SetBlend( pro/4 ) render.MaterialOverride( glow )
        render.SetColorModulation( 1, 1, 1 )
        self:DrawModel()
        render.SetBlend( 1 ) render.MaterialOverride()
        render.SetColorModulation( 1, 1, 1 )
        render.SuppressEngineLighting( false )
	end
	if self._Seen or self._Lerp > SysTime() then
		local ler = math.Clamp( ( self._Lerp -SysTime() )/0.2, 0, 1 )
		if self._Seen then ler = 1-ler end
		cam.Start2D()
		render.OverrideDepthEnable( true, false )
		local pos = self:WorldSpaceCenter():ToScreen()
		local x, y, radius, seg, per = math.Round( pos.x ), math.Round( pos.y ), ler*40, 360, self._Ler2/100
		for i=1, 6 do surface.DrawCircle( x, y, radius -7 +i, Color( 0, 0, 0, 192*ler ) ) end
		per = isnumber( per ) and per or 1
		local cir = {}
		table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
		for i = 0, seg do
			if i > math.ceil( seg*per ) then break end
			local a = math.rad( ( i/seg )*-360 +180 )
			table.insert( cir, { x = x +math.sin( a )*radius, y = y +math.cos( a )*radius, u = math.sin( a )/2 +0.5, v = math.cos( a )/2 +0.5 } )
		end
		local a = math.rad( 0 )
		surface.SetMaterial( Mat ) surface.SetDrawColor( 255, 200, 25, 255*ler )
		surface.DrawPoly( cir )
		draw.TextShadow( {
			text = math.Clamp( math.Round( self._Ler2 ), 0, 100 ).."%",
			pos = { x, y },
			font = "Trebuchet24",
			xalign = TEXT_ALIGN_CENTER,
			yalign = TEXT_ALIGN_CENTER,
			color = Color( 255, 200, 25, ler*255 )
		}, 1, ler*255 )
		draw.TextShadow( {
			text = self:GetNick(),
			pos = { x, y -ler*52 },
			font = "TargetID",
			xalign = TEXT_ALIGN_CENTER,
			yalign = TEXT_ALIGN_CENTER,
			color = Color( 255, 200, 25, ler*255 )
		}, 1, ler*255 )
		render.OverrideDepthEnable( false )
		cam.End2D()
	end
end
