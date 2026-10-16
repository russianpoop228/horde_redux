AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = {"models/combine_turrets/floor_turret.mdl"}
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
ENT.RangeAttackAngleRadius = 80
ENT.DisableDefaultRangeAttackCode = true
ENT.DisableRangeAttackAnimation = true
ENT.RangeAttackReps = 1
ENT.NextRangeAttackTime = 0
ENT.NextAnyAttackTime_Range = 0.01
ENT.TimeUntilRangeAttackProjectileRelease = 0.2
ENT.RangeDistance = 1000
ENT.RangeToMeleeDistance = 0
ENT.NextRangeAttackTime = 0.1
ENT.HasFootStepSound = false
ENT.SoundTbl_FootStep = {}
ENT.CanTurnWhileStationary = false
ENT.HasOnPlayerSight = true

ENT.HasPoseParameterLooking = true
ENT.PoseParameterLooking_CanReset = true
ENT.PoseParameterLooking_InvertPitch = false
ENT.PoseParameterLooking_InvertYaw = false
ENT.PoseParameterLooking_InvertRoll = false

ENT.Sentry_MuzzleAttach = "eyes"
ENT.Sentry_AlarmAttach = "light"
ENT.Sentry_Type = 0
ENT.Sentry_OrientationType = 0
ENT.Sentry_GroundType = 0

ENT.Sentry_HasLOS = false
ENT.Sentry_StandDown = true
ENT.Sentry_SpunUp = false
ENT.Sentry_CurrentParameter = 0
ENT.Sentry_NextAlarmT = 0
ENT.Sentry_ControllerStatus = 0

ENT.Horde_Immune_Status_All = true

ENT.HasSounds = true
ENT.SoundTbl_CombatIdle = {
	"npc/turret_floor/ping.wav"
}
ENT.SoundTbl_Idle = {
	"npc/turret_floor/ping.wav"
}
ENT.SoundTbl_Pain = {

}

ENT.SoundTbl_Death = {
	"npc/turret_floor/die.wav"
}

ENT.SoundTbl_Alert = {
	"npc/turret_floor/deploy.wav"
}
ENT.SoundTbl_RangeAttack = {
	"npc/turret_floor/shoot.wav"
}

ENT.Immune_AcidPoisonRadiation = true
ENT.Horde_Immune_Bleeding = true

function ENT:CustomOnInitialize()
	self:SetCollisionBounds(Vector(13, 13, 60), Vector(-13, -13, 0))
	if not self.Horde_SkipDrop then
		timer.Simple(0.1, function ()
			if not IsValid(self) then return end
			HORDE:DropTurret(self)
		end)
	end

	local skins = {
		"models/combine_turrets/floor_turret/floor_turret_citizen",
		"models/combine_turrets/floor_turret/floor_turret_citizen2",
		"models/combine_turrets/floor_turret/floor_turret_citizen4",
	}
	local skin = skins[math.random(#skins)]
	self:SetSubMaterial(0, skin)
	self:SetMaterial(skin)
end

function ENT:CustomOnThink_AIEnabled()
	if self.Dead then return end
	local eneValid = IsValid(self:GetEnemy())
	if self.Alerted && !eneValid then
		self.PoseParameterLooking_CanReset = false
	else
		self.PoseParameterLooking_CanReset = true
	end
	if (self.Sentry_ControllerStatus == 1) or (!self.VJ_IsBeingControlled && (eneValid or self.Alerted == true)) then
		self.Sentry_StandDown = false
		self.AnimTbl_IdleStand = {"spin"}

		if CurTime() > self.Sentry_NextAlarmT && self.Sentry_Type != 2 then
			local glow = ents.Create("env_sprite")
			glow:SetKeyValue("model","vj_base/sprites/vj_glow1.vmt")
			glow:SetKeyValue("scale", self.Sentry_Type == 1 and "0.35" or "0.15")
			glow:SetKeyValue("rendermode","5")
			glow:SetKeyValue("rendercolor","255 0 0")
			glow:SetKeyValue("spawnflags","1")
			glow:SetParent(self)
			glow:Fire("SetParentAttachment", self.Sentry_AlarmAttach)
			glow:Spawn()
			glow:Activate()
			glow:Fire("Kill", "", 0.1)
			self:DeleteOnRemove(glow)
			self.Sentry_NextAlarmT = CurTime() + 1
		end

		if !eneValid then
			self:SetPoseParameter("aim_yaw", self:GetPoseParameter("aim_yaw") + 4)
		end
	end
end

function ENT:FireBullet(gunPos)
	local bullet = {}
	bullet.Num = 1
	bullet.Src = gunPos
	bullet.Dir = (self:GetEnemy():GetPos() + self:GetEnemy():OBBCenter() + Vector(0,0,10)) - gunPos
	bullet.Spread = Vector(0.02, 0.02, 0.02)
	bullet.Tracer = 1
	bullet.TracerName = "arccw_tracer"
	bullet.Force = 3
	bullet.Damage = self:GetNWFloat("Horde_UpgradeDamage", 10)
	bullet.AmmoType = "SMG1"
	self:FireBullets(bullet)
end

function ENT:CustomRangeAttackCode()
	local gunPos = self:GetAttachment(self:LookupAttachment(self.Sentry_MuzzleAttach)).Pos
	for i = 1, 3 do
		self:FireBullet(gunPos)
	end

	VJ_EmitSound(self, {"npc/turret_floor/shoot.wav"}, 110, self:VJ_DecideSoundPitch(100, 110))

	local muz = ents.Create("env_sprite_oriented")
	muz:SetKeyValue("model","vj_hl/sprites/muzzleflash3.vmt")
	muz:SetKeyValue("scale",""..math.Rand(0.3, 0.5))
	muz:SetKeyValue("GlowProxySize","2.0")
	muz:SetKeyValue("HDRColorScale","1.0")
	muz:SetKeyValue("renderfx","14")
	muz:SetKeyValue("rendermode","3")
	muz:SetKeyValue("renderamt","255")
	muz:SetKeyValue("disablereceiveshadows","0")
	muz:SetKeyValue("framerate","10.0")
	muz:SetKeyValue("spawnflags","0")
	muz:SetParent(self)
	muz:Fire("SetParentAttachment", self.Sentry_MuzzleAttach)
	muz:SetAngles(Angle(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100)))
	muz:Spawn()
	muz:Activate()
	muz:Fire("Kill","",0.08)

	local muzzleLight = ents.Create("light_dynamic")
	muzzleLight:SetKeyValue("brightness", "4")
	muzzleLight:SetKeyValue("distance", "120")
	muzzleLight:SetPos(gunPos)
	muzzleLight:SetLocalAngles(self:GetAngles())
	muzzleLight:Fire("Color", "255 150 60")
	muzzleLight:SetParent(self)
	muzzleLight:Spawn()
	muzzleLight:Activate()
	muzzleLight:Fire("TurnOn","",0)
	muzzleLight:Fire("Kill","",0.07)
	self:DeleteOnRemove(muzzleLight)
end

VJ.AddNPC("Rebel Turret","npc_vj_horde_rebel_turret", "Horde")
ENT.Horde_TurretMinion = true

function ENT:Follow(ply)
	if self:GetNWEntity("HordeOwner") == ply then
		local a = self:GetAngles()
		self:SetAngles(Angle(0,a.y,0))
		self:PhysicsInit(SOLID_VPHYSICS)
        ply:PickupObject(self)
		self:GetPhysicsObject():EnableMotion(true)
		self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
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
