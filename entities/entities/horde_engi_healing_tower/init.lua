AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

ENT.Model = {"models/props_trainstation/trainstation_ornament002.mdl"}
ENT.StartHealth = 300
ENT.SightDistance = 1
ENT.HullType = HULL_HUMAN
ENT.MovementType = VJ_MOVETYPE_STATIONARY
ENT.SightAngle = 0
ENT.LastSeenEnemyTimeUntilReset = 9999

ENT.VJ_NPC_Class = {"CLASS_PLAYER_ALLY", "CLASS_COMBINE"}
ENT.FriendlyMinion = true
ENT.BloodColor = ""
ENT.HasBloodParticle = false
ENT.HasBloodDecal = false
ENT.HasBloodPool = false
ENT.PlayerFriendly = true
ENT.HasMeleeAttack = false
ENT.HasRangeAttack = false
ENT.RunAwayOnUnknownDamage = false
ENT.HasFootStepSound = false
ENT.SoundTbl_FootStep = {}
ENT.CanTurnWhileStationary = false
ENT.HasOnPlayerSight = false
ENT.HasSounds = false
ENT.DisableWandering = true
ENT.DisableChasingEnemy = true
ENT.FindEnemy_CanSeeThroughWalls = false

ENT.HasDeathRagdoll = false
ENT.HasDeathAnimation = false
ENT.HasExtraMeleeAttackSounds = false

ENT.Horde_Immune_Status_All = true
ENT.Immune_AcidPoisonRadiation = true
ENT.Horde_Immune_Bleeding = true
ENT.Horde_TurretMinion = true
ENT.Horde_NoPickup = true

function ENT:Use(ply)
end

local function PlaceOnGround(ent)
	if not IsValid(ent) then return end

	local pos = ent:GetPos()
	local tr = util.TraceLine({
		start = pos + Vector(0, 0, 64),
		endpos = pos + Vector(0, 0, -10000),
		filter = ent,
		mask = MASK_SOLID_BRUSHONLY,
	})
	if not tr.Hit then return end

	local mins, maxs = ent:GetModelBounds()
	local bottom = (mins and mins.z) or -12
	local new_z = tr.HitPos.z - bottom + 2
	ent:SetPos(Vector(pos.x, pos.y, new_z))
	ent:SetAngles(Angle(0, ent:GetAngles().y, 0))

	if mins and maxs then
		ent:SetCollisionBounds(mins, maxs)
	end

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end
end

function ENT:CustomOnInitialize()
	local hp = (HORDE and HORDE.Horde_GetBuildableHealth and HORDE:Horde_GetBuildableHealth("horde_engi_healing_tower")) or self.StartHealth
	self.StartHealth = hp
	if self.SetMaxHealth then self:SetMaxHealth(hp) end
	self:SetHealth(hp)

	self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	self.Horde_NoPickup = true

	self:SetColor(Color(80, 220, 80))
	self:SetRenderMode(RENDERMODE_TRANSCOLOR)

	self:_SpawnRings()

	local function try_place()
		if not IsValid(self) then return end
		PlaceOnGround(self)
		self:_RepositionRings()
	end
	timer.Simple(0, try_place)
	timer.Simple(0.1, try_place)
	timer.Simple(0.5, try_place)

	self._NextHeal = CurTime() + (HORDE.HealingTower_Tick or 15)
end

function ENT:_SpawnRings()
	if IsValid(self.RingsEnt) then return end

	local rings = ents.Create("prop_dynamic")
	if not IsValid(rings) then return end

	rings:SetModel("models/maxofs2d/hover_rings.mdl")
	rings:SetPos(self:GetPos())
	rings:SetAngles(self:GetAngles())
	rings:SetParent(self)
	rings:SetOwner(self)
	rings:Spawn()
	rings:Activate()
	rings:SetSolid(SOLID_NONE)
	rings:SetMoveType(MOVETYPE_NONE)
	rings:SetColor(Color(80, 220, 80))
	rings:SetRenderMode(RENDERMODE_TRANSCOLOR)
	rings:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

	self.RingsEnt = rings
	self:_RepositionRings()
end

function ENT:_RepositionRings()
	if not IsValid(self.RingsEnt) then return end

	local mins, maxs = self:GetModelBounds()
	local top = (maxs and maxs.z) or 40
	self.RingsEnt:SetLocalPos(Vector(0, 0, top + 8))
	self.RingsEnt:SetLocalAngles(Angle(0, 0, 0))
end

function ENT:DoRelationshipCheck(ent)
	if not IsValid(ent) then return false end
	if ent:IsPlayer() then return false end
	if IsValid(ent:GetNWEntity("HordeOwner")) then return false end
	if HORDE:IsMapBuildable(ent) then return false end
	return true
end

function ENT:CustomOnThink()
	if self.Dead then return end
	if CurTime() < (self._NextHeal or 0) then return end
	self._NextHeal = CurTime() + (HORDE.HealingTower_Tick or 15)
	self:DoHealTick()
end

function ENT:DoHealTick()
	local own = HORDE:Horde_GetBuildableOwner(self)

	local my_pos = self:GetPos()
	local range = HORDE.HealingTower_Range or 150
	local range_sqr = range * range
	local healed_any = false

	local build_heal = HORDE.HealingTower_BuildHeal or 50
	local player_heal = HORDE.HealingTower_PlayerHeal or 5

	local refs
	if own then
		refs = HORDE.player_drop_entities and HORDE.player_drop_entities[own:SteamID()]
	elseif HORDE:IsMapBuildable(self) then
		refs = HORDE:Horde_GetMapBuildables()
	end
	if refs then
		for _, ent in pairs(refs) do
			if IsValid(ent) and ent ~= self then
				if ent:GetPos():DistToSqr(my_pos) <= range_sqr then
					local max_hp = ent:GetMaxHealth()
					local cur_hp = ent:Health()
					if max_hp > 0 and cur_hp < max_hp then
						ent:SetHealth(math.min(max_hp, cur_hp + build_heal))
						healed_any = true
					end
				end
			end
		end
	end

	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:Alive() then
			if ply:GetPos():DistToSqr(my_pos) <= range_sqr then
				local max_hp = ply:GetMaxHealth()
				local cur_hp = ply:Health()
				if cur_hp < max_hp then
					ply:SetHealth(math.min(max_hp, cur_hp + player_heal))
					healed_any = true
				end
			end
		end
	end

	if healed_any then
		local ed = EffectData()
		ed:SetOrigin(my_pos + vector_up * 24)
		ed:SetScale(1)
		util.Effect("horde_heal_mist", ed, true, true)
		self:EmitSound("items/medshot4.wav", 60, 110, 0.45)
	end
end

function ENT:Follow(ply)
end

function ENT:OnRemove()
	if IsValid(self.RingsEnt) then
		self.RingsEnt:Remove()
		self.RingsEnt = nil
	end
end

function ENT:CustomOnKilled(dmginfo, hitgroup)
	if IsValid(self.RingsEnt) then
		self.RingsEnt:Remove()
		self.RingsEnt = nil
	end
	local ed = EffectData()
	ed:SetOrigin(self:GetPos())
	ed:SetEntity(self)
	util.Effect("entity_remove", ed, true, true)
	self:Remove()
	return true
end

VJ.AddNPC("Healing Tower", "horde_engi_healing_tower", "Horde")
