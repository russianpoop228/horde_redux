AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = {"models/combine_turrets/ground_turret.mdl"}
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
ENT.RangeAttackAngleRadius = 75
ENT.HasRangeAttack = true
ENT.DisableDefaultRangeAttackCode = true
ENT.DisableRangeAttackAnimation = true
ENT.RangeAttackReps = 1
ENT.NextRangeAttackTime = 0
ENT.NextAnyAttackTime_Range = 0.01
ENT.TimeUntilRangeAttackProjectileRelease = 0.2
ENT.RangeDistance = 4000
ENT.RangeToMeleeDistance = 0
ENT.NextRangeAttackTime = 0.9
ENT.HasFootStepSound = false
ENT.SoundTbl_FootStep = {}
ENT.CanTurnWhileStationary = false
ENT.HasOnPlayerSight = true

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
	"npc/sniper/sniper1.wav"
}

ENT.Immune_AcidPoisonRadiation = true

function ENT:CustomOnInitialize()
	self:SetCollisionBounds(Vector(13, 13, 60), Vector(-13, -13, 0))
	timer.Simple(0.1, function ()
		if not IsValid(self) then return end
		self:SetAngles(Angle(0, self:GetAngles().y, 180))
		self:SetModelScale(1.5)
		HORDE:DropTurret(self)
	end)
end

function ENT:CustomRangeAttackCode()
	local gunPos = self:GetAttachment(self:LookupAttachment(self.Sentry_MuzzleAttach)).Pos
	local bullet = {}
	local v = self:GetEnemy():OBBMaxs().z - self:GetEnemy():OBBMins().z
	if v < 60 then v = 0 end
	bullet.Num = 1
	bullet.Src = gunPos
	local pos = self:GetEnemy():GetPos() + self:GetEnemy():OBBCenter()
	bullet.Dir = pos - gunPos
	bullet.Spread = Vector(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
	bullet.Tracer = 1
	bullet.TracerName = "HelicopterTracer"
	bullet.Force = 10
	bullet.Damage = self:GetNWFloat("Horde_UpgradeDamage", 160)
	bullet.AmmoType = "SniperRound"
	bullet.Callback = function (ent, tr)
		util.ParticleTracerEx("HelicopterTracer", gunPos, tr.HitPos, true, self:EntIndex(), -1)
	end
	self:FireBullets(bullet)

	VJ_EmitSound(self, {"npc/sniper/sniper1.wav"}, 90, self:VJ_DecideSoundPitch(100, 110))
	VJ_EmitSound(self, {"npc/sniper/sniper1.wav"}, 140, self:VJ_DecideSoundPitch(100, 110))

	local muz = ents.Create("env_sprite_oriented")
	muz:SetKeyValue("model","vj_hl/sprites/muzzleflash3.vmt")
	if self.Sentry_Type == 1 then
		muz:SetKeyValue("scale",""..math.Rand(0.8, 1))
	else
		muz:SetKeyValue("scale",""..math.Rand(0.3, 0.5))
	end
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

VJ.AddNPC("Sniper Turret","npc_vj_horde_sniper_turret", "Horde")
ENT.Horde_TurretMinion = true

function ENT:Follow(ply)
	if self:GetNWEntity("HordeOwner") == ply then
		local a = self:GetAngles()
		self:SetAngles(Angle(a.x,a.y,180))
		self:PhysicsInit(SOLID_VPHYSICS)
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
