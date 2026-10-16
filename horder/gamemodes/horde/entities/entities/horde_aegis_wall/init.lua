AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

ENT.Model = {"models/hunter/plates/plate2.mdl"}
ENT.StartHealth = 3000
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
ENT.GodMode = false

ENT.HasGibOnDeath = false
ENT.HasGibOnDeathSounds = false

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
	local bottom = (mins and mins.z) or -1
	local new_z = tr.HitPos.z - bottom + 1
	ent:SetPos(Vector(pos.x, pos.y, new_z))
	ent:SetAngles(Angle(0, ent:GetAngles().y, 0))

	if mins and maxs then
		local top_extra = 8
		ent:SetCollisionBounds(
			Vector(mins.x, mins.y, mins.z),
			Vector(maxs.x, maxs.y, maxs.z + top_extra)
		)
	end

	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end
end

function ENT:CustomOnInitialize()
	local hp = (HORDE and HORDE.Horde_GetBuildableHealth and HORDE:Horde_GetBuildableHealth("horde_aegis_wall")) or self.StartHealth
	self.StartHealth = hp
	if self.SetMaxHealth then self:SetMaxHealth(hp) end
	self:SetHealth(hp)

	self:SetMaterial("phoenix_storms/metalset_1-2")

	self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	self.Horde_NoPickup = true

	local function try_place()
		if not IsValid(self) then return end
		PlaceOnGround(self)
	end
	timer.Simple(0, try_place)
	timer.Simple(0.1, try_place)
	timer.Simple(0.5, try_place)
end

function ENT:DoRelationshipCheck(ent)
	if not IsValid(ent) then return false end
	if ent:IsPlayer() then return false end
	if IsValid(ent:GetNWEntity("HordeOwner")) then return false end
	return true
end

function ENT:Use(ply)
end

function ENT:CustomOnThink()
end

function ENT:Follow(ply)
end

function ENT:CustomOnKilled(dmginfo, hitgroup)
	local ed = EffectData()
	ed:SetOrigin(self:GetPos())
	ed:SetEntity(self)
	util.Effect("entity_remove", ed, true, true)
	self:Remove()
	return true
end

VJ.AddNPC("Aegis Wall", "horde_aegis_wall", "Horde")
