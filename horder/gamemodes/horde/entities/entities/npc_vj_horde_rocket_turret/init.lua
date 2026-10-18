AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = {"models/horde/rocket_turret/rocket_turret.mdl"}
ENT.StartHealth = 400
ENT.SightDistance = 8000
ENT.HullType = HULL_HUMAN
ENT.MovementType = VJ_MOVETYPE_STATIONARY
ENT.SightAngle = 180
ENT.LastSeenEnemyTimeUntilReset = 60
ENT.VJ_NPC_Class = {"CLASS_PLAYER_ALLY", "CLASS_COMBINE"}
ENT.FriendlyMinion = true
ENT.BloodColor = "Oil"
ENT.HasBloodDecal = false
ENT.PlayerFriendly = true
ENT.HasDeathCorpse = false
ENT.HasMeleeAttack = false
ENT.RunAwayOnUnknownDamage = false
ENT.HasRangeAttack = true
ENT.RangeAttackEntityToSpawn = "obj_horde_mini_rocket"
ENT.RangeAttackAngleRadius = 180
ENT.AnimTbl_RangeAttack = {"fire"}
ENT.RangeUseAttachmentForPos = true
ENT.RangeUseAttachmentForPosID = "barrel"
ENT.HasPoseParameterLooking = true
ENT.PoseParameterLooking_CanReset = true
ENT.PoseParameterLooking_InvertPitch = false
ENT.PoseParameterLooking_InvertYaw = false
ENT.PoseParameterLooking_InvertRoll = false
ENT.PoseParameterLooking_TurningSpeed = 10
ENT.TimeUntilRangeAttackProjectileRelease = 0.2
ENT.RangeDistance = 2000
ENT.RangeToMeleeDistance = 0
ENT.NextRangeAttackTime = 1
ENT.HasFootStepSound = false
ENT.SoundTbl_FootStep = {}
ENT.CanTurnWhileStationary = false
ENT.HasOnPlayerSight = true

ENT.Horde_Immune_Status_All = true

ENT.HasSounds = true
ENT.SoundTbl_CombatIdle = {

}
ENT.SoundTbl_Idle = {

}
ENT.SoundTbl_Pain = {

}

ENT.SoundTbl_Death = {

}

ENT.SoundTbl_Alert = {
	"horde/rocket_turret/turret_autosearch_1.ogg",
	"horde/rocket_turret/turret_autosearch_2.ogg",
	"horde/rocket_turret/turret_autosearch_3.ogg",
}
ENT.SoundTbl_RangeAttack = {
	"horde/rocket_turret/rocket_fire1.ogg"
}
ENT.SoundTbl_OnPlayerSight = {
	"horde/rocket_turret/turret_active_1.ogg",
	"horde/rocket_turret/turret_deploy_1.ogg",
	"horde/rocket_turret/turret_deploy_6.ogg"
}

ENT.Immune_AcidPoisonRadiation = true
ENT.Horde_Immune_Bleeding = true

function ENT:CustomOnInitialize()
	self:SetSkin(math.random(0,3))
	timer.Simple(0.1, function ()
		if not IsValid(self) then return end
		self:SetAngles(Angle(0, self:GetAngles().y, 0))
		HORDE:DropTurret(self)
	end)
end

function ENT:DoPoseParameterLooking()
	local ent = self:GetEnemy()
	local p_enemy = 0
	local y_enemy = 0
	if IsValid(ent) then
		local enemy_pos = ent:GetPos()
		local self_ang = self:GetAngles()
		local enemy_ang = (enemy_pos - (self:GetPos() + self:OBBCenter())):Angle()
		p_enemy = math.AngleDifference(enemy_ang.p, self_ang.p)
		y_enemy = math.AngleDifference(-enemy_ang.y - 90, self_ang.y)
	else
		return
	end
	self:SetPoseParameter("aim_pitch",  p_enemy)
	self:SetPoseParameter("aim_yaw",  y_enemy)
end

function ENT:DoRelationshipCheck(ent)
    if ent:IsPlayer() then return self.Horde_MapRelation == HORDE.HammerRelation.ENEMY end
    if ent:GetNWEntity("HordeOwner"):IsValid() then return false end
    if HORDE:IsMapBuildable(ent) then return false end
    return true
end

function ENT:CustomRangeAttackCode_AfterProjectileSpawn(projectile)
	if HORDE:Horde_IsAmmoTrackedBuildable(self:GetClass()) then
		local ammo = self:GetNWInt("Horde_AmmoCurrent", -1)
		if ammo >= 0 then
			if ammo <= 0 then
				self:EmitSound(HORDE.Turret_EmptySound, 75, 100)
				if IsValid(projectile) then projectile:Remove() end
				return
			end
			self:SetNWInt("Horde_AmmoCurrent", ammo - 1)
		end
	end

	local phys = projectile:GetPhysicsObject()
	local ent = self:GetEnemy()
	if IsValid(phys) then
		local dir = (ent:GetPos() - self:GetAttachment(2).Pos)
		dir:Normalize()
		local vel = dir * 4000
		phys:SetVelocity(vel)
	end
end

VJ.AddNPC("Rocket Turret","npc_vj_horde_rocket_turret", "Horde")
ENT.Horde_TurretMinion = true

function ENT:Follow(ply)
	if self:GetNWEntity("HordeOwner") == ply then
		self:PhysicsInit(SOLID_VPHYSICS)
		local p = self:GetPos()
		p.z = ply:GetPos().z + 12
		self:SetPos(p)
        ply:PickupObject(self)
		self:GetPhysicsObject():EnableMotion(true)
		self.Horde_Pickedup = true
		timer.Simple(0.2, function ()
			if self:IsValid() then
				self.Horde_Pickedup = nil
			end
		end)
    end
end

function ENT:CustomOnKilled(dmginfo, hitgroup)
	local ent = self
	timer.Simple(0.1, function()
		if IsValid(ent) then
			ent:Remove()
		end
	end)
end
