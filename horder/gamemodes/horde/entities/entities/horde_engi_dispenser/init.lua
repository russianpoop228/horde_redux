AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = {"models/items/ammocrate_rockets.mdl"}
ENT.StartHealth = 250
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
	local hp = (HORDE and HORDE.Horde_GetBuildableHealth and HORDE:Horde_GetBuildableHealth("horde_engi_dispenser")) or self.StartHealth
	self.StartHealth = hp
	if self.SetMaxHealth then self:SetMaxHealth(hp) end
	self:SetHealth(hp)

	self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	self.Horde_NoPickup = true

	local function try_place()
		if not IsValid(self) then return end
		PlaceOnGround(self)
	end
	timer.Simple(0, try_place)
	timer.Simple(0.1, try_place)
	timer.Simple(0.5, try_place)

	self._NextResupply = CurTime() + HORDE.Dispenser_Tick
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
	if CurTime() < (self._NextResupply or 0) then return end
	self._NextResupply = CurTime() + HORDE.Dispenser_Tick
	self:DoResupplyTick()
end

function ENT:DoResupplyTick()
	local own = HORDE:Horde_GetBuildableOwner(self)
	local refs
	if own then
		refs = HORDE.player_drop_entities and HORDE.player_drop_entities[own:SteamID()]
	elseif HORDE:IsMapBuildable(self) then
		refs = HORDE:Horde_GetMapBuildables()
	end
	if not refs then return end

	local my_pos = self:GetPos()
	local range_sqr = HORDE.Dispenser_Range * HORDE.Dispenser_Range
	local resupplied_any = false

	local metal_added = false
	if own and own.Horde_AddMetal then
		local metal_amount = math.max(1, math.floor((HORDE.Dispenser_MetalRefill or 15)))
		own:Horde_AddMetal(metal_amount)
		metal_added = true
	end

	for _, ent in pairs(refs) do
		if IsValid(ent) and ent ~= self and HORDE.Horde_IsAmmoTrackedBuildable and HORDE:Horde_IsAmmoTrackedBuildable(ent:GetClass()) then
			if ent:GetPos():DistToSqr(my_pos) <= range_sqr then
				local max_ammo = ent:GetNWInt("Horde_AmmoMax", 0)
				local cur_ammo = ent:GetNWInt("Horde_AmmoCurrent", 0)
				if max_ammo > 0 and cur_ammo < max_ammo then
					ent:SetNWInt("Horde_AmmoCurrent", math.min(max_ammo, cur_ammo + math.ceil(max_ammo * HORDE.Dispenser_RefillPct)))
					resupplied_any = true
				end
			end
		end
	end

	local clips = HORDE.Dispenser_PlayerClips or 1
	if clips > 0 then
		for _, ply in ipairs(player.GetAll()) do
			if ply:Alive() and ply:GetPos():DistToSqr(my_pos) <= range_sqr then
				local wpn = ply:GetActiveWeapon()
				if IsValid(wpn) then
					local ammo_type = wpn:GetPrimaryAmmoType()
					if ammo_type and ammo_type >= 0 then
						local clip = wpn:GetMaxClip1()
						if not clip or clip <= 0 then clip = 10 end
						ply:GiveAmmo(math.ceil(clip * clips), ammo_type, false)
						resupplied_any = true
					end
				end
			end
		end
	end

	if resupplied_any or metal_added then
		local ed = EffectData()
		ed:SetOrigin(my_pos + vector_up * 20)
		util.Effect("Sparks", ed)
		self:EmitSound("buttons/button14.wav", 60, 140, 0.4)
	end
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

VJ.AddNPC("Metal Dispenser", "horde_engi_dispenser", "Horde")
