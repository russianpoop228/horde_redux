AddCSLuaFile("shared.lua")
include('shared.lua')

local HEAD_SCALE    = 0.1
local TURRET_CLASS  = "npc_vj_horde_rebel_turret"
local TURRET_ATTACH = "eyes"
local TURRET_SCALE  = 0.875
local TURRET_DROP   = 20
local TURRET_DAMAGE     = math.random(1,4)
local TURRET_RATE       = 0.002
local TURRET_SPREAD_MIN = 0.02
local TURRET_SPREAD_MAX = 0.32
local TURRET_JITTER     = 4
local WEAPON_CLASS  = "arccw_horde_trenchgun"
local SHOT_SOUND    = "weapons/fesiugmw2/fire/shot_w1200.wav"
local SHOT_PELLETS  = 8
local SHOT_DAMAGE   = 4
local SHOT_SPREAD   = 0.06
local SHOT_RANGE    = 1500
local SHOT_DELAY    = 1.5
local SHOT_BURST    = 3
local SHOT_INTERVAL = 0.25
local SHOT_COOLDOWN = 10
local CHASE_DISTANCE = 384
local CHASE_RETRY    = 2
local CHASE_ACTIVITY = ACT_RUN

ENT.Model = "models/combine_super_soldier.mdl"
ENT.StartHealth = 1800
ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.MeleeAttackDamage = 30
ENT.MoveType = MOVETYPE_STEP
ENT.HullType = HULL_HUMAN
ENT.SightDistance = 10000
ENT.SightAngle = 80
ENT.TurningSpeed = 20
ENT.Bleeds = true
ENT.BloodColor = "Red"
ENT.HasBloodParticle = true
ENT.HasBloodDecal = true
ENT.HasBloodPool = false
ENT.Flinches = 1
ENT.FlinchingChance = 12
ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS}
ENT.MoveWhenDamagedByEnemy = false
ENT.MoveWhenDamagedByEnemySCHED1 = SCHED_FORCED_GO_RUN
ENT.MoveWhenDamagedByEnemySCHED2 = SCHED_FORCED_GO_RUN
ENT.NextMoveWhenDamagedByEnemy1 = 3
ENT.NextMoveWhenDamagedByEnemy2 = 3.5
ENT.HasAllies = true
ENT.HasMeleeAttack = true
ENT.HasGrenadeAttack = true
ENT.NextThrowGrenadeTime1 = 10
ENT.NextThrowGrenadeTime2 = 15
ENT.ThrowGrenadeChance = 1
ENT.GrenadeAttackThrowDistance = 1000
ENT.GrenadeAttackThrowDistanceClose = 500
ENT.AnimTbl_GrenadeAttack = {"grenThrow"}
ENT.GrenadeAttackAnimationDelay = 0
ENT.GrenadeAttackAnimationStopAttacks = true
ENT.GrenadeAttackEntity = "npc_grenade_frag"
ENT.FootStepTimeRun = 0.3
ENT.FootStepTimeWalk = 0.5
ENT.CallForBackUpOnDamage = false
ENT.CanDetectDangers = false
ENT.MoveOrHideOnDamageByEnemy = false
ENT.WeaponSpread = 1.5
ENT.Weapon_FiringDistanceFar = CHASE_DISTANCE
ENT.WeaponReload_FindCover = false
ENT.Horde_Plague_Soldier = true
ENT.WeaponAttackSecondaryTimeUntilFire = 2
ENT.EntitiesToNoCollide = {"npc_vj_horde_zombine", "npc_vj_horde_plague_soldier"}
ENT.CallForHelp = false
ENT.CanInvestigate = false
ENT.AnimTbl_WeaponAttackSecondary = ACT_RANGE_ATTACK1

ENT.HasItemDropsOnDeath = false
ENT.DropWeaponOnDeath = false

ENT.SoundTbl_Pain = {
"npc/combine_soldier/pain1.wav",
"npc/combine_soldier/pain2.wav",
"npc/combine_soldier/pain3.wav"}

ENT.SoundTbl_FootStep = {
	"npc/combine_soldier/gear1.wav",
	"npc/combine_soldier/gear2.wav",
	"npc/combine_soldier/gear3.wav",
	"npc/combine_soldier/gear4.wav",
	"npc/combine_soldier/gear5.wav",
	"npc/combine_soldier/gear6.wav"}
ENT.SoundTbl_Idle = {"vj_zombies/zombine/idle1.wav", "vj_zombies/zombine/idle2.wav", "vj_zombies/zombine/idle3.wav", "vj_zombies/zombine/idle4.wav", "vj_zombies/zombine/idle5.wav"}
ENT.SoundTbl_Alert = {"vj_zombies/zombine/alert1.wav", "vj_zombies/zombine/alert2.wav", "vj_zombies/zombine/alert3.wav", "vj_zombies/zombine/alert4.wav", "vj_zombies/zombine/alert5.wav", "vj_zombies/zombine/alert6.wav"}

ENT.UseTheSameGeneralSoundPitch = true
ENT.GeneralSoundPitch1 = 30
ENT.GeneralSoundPitch2 = 30

function ENT:FindHeadBone()
	for i = 0, self:GetBoneCount() - 1 do
		local name = self:GetBoneName(i)
		if name and string.find(string.lower(name), "head", 1, true) then
			return i
		end
	end
	return nil
end

function ENT:CustomOnInitialize()
	self:SetModelScale(1.25)
	self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
	self:SetColor(Color(50,50,50))

	self:ShrinkHead()
	self:SpawnHeadTurret()

	local ok, wep = pcall(function() return self:Give(WEAPON_CLASS) end)
	if ok and IsValid(wep) then
		self:SelectWeapon(wep)
	else
		self.Horde_WeaponFailed = true
	end

	self:EmitSound("npc/combine_gunship/see_enemy.wav", 3000, 100, 2, CHAN_STATIC)
end

function ENT:ShrinkHead()
	local head = self:FindHeadBone()
	if not head then return end
	self.Horde_HeadBone = head
	self:ManipulateBoneScale(head, Vector(HEAD_SCALE, HEAD_SCALE, HEAD_SCALE))
end

function ENT:SpawnHeadTurret()
	local turret = ents.Create(TURRET_CLASS)
	if not IsValid(turret) then return end

	turret.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
	turret.PlayerFriendly = false
	turret.Horde_SkipDrop = true
	turret.Horde_NoReward = true
	turret.SightDistance = 999999
	turret.SightAngle = 360
	turret.RangeDistance = 999999
	turret.LastSeenEnemyTimeUntilReset = 60
	turret.NextRangeAttackTime = TURRET_RATE
	turret.NextAnyAttackTime_Range = TURRET_RATE

	turret:SetPos(self:GetPos() + Vector(0, 0, 90 - TURRET_DROP))
	turret:SetAngles(self:GetAngles())
	turret:Spawn()
	turret:SetModelScale(TURRET_SCALE)
	turret:SetParent(self)

	self.HeadTurret = turret
	self.HeadTurretAttach = self:LookupAttachment(TURRET_ATTACH)
	self:DeleteOnRemove(turret)
	self:UpdateHeadTurret()

	turret.FireBullet = function(ent, gunPos)
		local ene = ent:GetEnemy()
		if not IsValid(ene) then return end
		local target = ene:GetPos() + ene:OBBCenter() + Vector(0, 0, 10)
		local spread = math.Rand(TURRET_SPREAD_MIN, TURRET_SPREAD_MAX)
		local ang = (target - gunPos):Angle()
		ang:RotateAroundAxis(ang:Up(), math.Rand(-TURRET_JITTER, TURRET_JITTER))
		ang:RotateAroundAxis(ang:Right(), math.Rand(-TURRET_JITTER, TURRET_JITTER))
		local bullet = {}
		bullet.Num = 1
		bullet.Src = gunPos
		bullet.Dir = ang:Forward()
		bullet.Spread = Vector(spread, spread, spread)
		bullet.Tracer = 1
		bullet.TracerName = "arccw_tracer"
		bullet.Force = 3
		bullet.Damage = TURRET_DAMAGE
		bullet.AmmoType = "SMG1"
		bullet.Attacker = ent
		bullet.Inflictor = ent
		ent:FireBullets(bullet)
	end

	turret.CustomRangeAttackCode = function(ent)
		local attach = ent:LookupAttachment(ent.Sentry_MuzzleAttach or "eyes")
		local a = attach and attach > 0 and ent:GetAttachment(attach)
		ent:FireBullet(a and a.Pos or ent:GetPos())
		ent:EmitSound("npc/turret_floor/shoot.wav", 110, math.random(95, 105))
	end
end

function ENT:UpdateHeadTurret()
	local turret = self.HeadTurret
	if not IsValid(turret) then return end

	local pos
	local attach_id = self.HeadTurretAttach
	if attach_id and attach_id > 0 then
		local attach = self:GetAttachment(attach_id)
		if attach then pos = attach.Pos end
	end
	if not pos then pos = self:GetPos() + Vector(0, 0, 90) end

	pos.z = pos.z - TURRET_DROP
	turret:SetLocalPos(self:WorldToLocal(pos))
	turret:SetLocalAngles(Angle(0, 0, 0))
end

function ENT:StartTrenchgunBurst()
	if CurTime() < (self.Horde_NextTrenchgunT or 0) then return end
	self.Horde_NextTrenchgunT = CurTime() + SHOT_COOLDOWN
	self.Horde_ShotsLeft = SHOT_BURST
	self.Horde_NextShotT = 0
end

function ENT:FireTrenchgun()
	local ene = self:GetEnemy()
	if not IsValid(ene) then
		self.Horde_ShotsLeft = nil
		return
	end

	if self.Horde_ShotsLeft == SHOT_BURST then
		self:VJ_ACT_PLAYACTIVITY(ACT_RANGE_ATTACK1, true, SHOT_BURST * SHOT_INTERVAL + 0.5, true)
	end

	local src
	local wep = self:GetActiveWeapon()
	if IsValid(wep) then
		local att = wep:LookupAttachment("muzzle")
		if att and att > 0 then
			local attach = wep:GetAttachment(att)
			if attach then src = attach.Pos end
		end
	end
	if not src then
		local att = self:LookupAttachment("eyes")
		local attach = att and att > 0 and self:GetAttachment(att)
		src = attach and attach.Pos or (self:GetPos() + Vector(0, 0, 60))
	end

	local dir = ((ene:GetPos() + ene:OBBCenter()) - src):GetNormalized()

	self:EmitSound(SHOT_SOUND, 110, math.random(95, 105), 1, CHAN_WEAPON)

	local flash = ents.Create("env_sprite_oriented")
	if IsValid(flash) then
		flash:SetKeyValue("model", "vj_hl/sprites/muzzleflash3.vmt")
		flash:SetKeyValue("scale", "0.6")
		flash:SetKeyValue("rendermode", "3")
		flash:SetKeyValue("renderamt", "255")
		flash:SetPos(src)
		flash:Spawn()
		flash:Activate()
		flash:Fire("Kill", "", 0.08)
	end

	self:FireBullets({
		Num = SHOT_PELLETS,
		Src = src,
		Dir = dir,
		Spread = Vector(SHOT_SPREAD, SHOT_SPREAD, SHOT_SPREAD),
		Tracer = 1,
		TracerName = "Tracer",
		Damage = SHOT_DAMAGE,
		AmmoType = "Buckshot",
		Force = 5,
		Attacker = self,
		Inflictor = self,
	})

	self.Horde_ShotsLeft = (self.Horde_ShotsLeft or 1) - 1
	self.Horde_NextShotT = CurTime() + SHOT_INTERVAL
	if self.Horde_ShotsLeft <= 0 then self.Horde_ShotsLeft = nil end
end

function ENT:CustomOnThink_AIEnabled()
	self:UpdateHeadTurret()

	local ene = self:GetEnemy()
	local in_range = IsValid(ene)
		and self:GetPos():DistToSqr(ene:GetPos()) <= SHOT_RANGE * SHOT_RANGE

	if self.Horde_ShotsLeft then
		if CurTime() >= (self.Horde_NextShotT or 0) then
			self:FireTrenchgun()
		end
	elseif in_range then
		if not self.Horde_NextTrenchgunT then
			self.Horde_NextTrenchgunT = CurTime() + SHOT_DELAY
		elseif CurTime() >= self.Horde_NextTrenchgunT then
			self:StartTrenchgunBurst()
		end
	end

	if IsValid(ene) and self:GetPos():DistToSqr(ene:GetPos()) > CHASE_DISTANCE * CHASE_DISTANCE then
		self:MaintainAlertBehavior(true)

		if not self:IsMoving() and CurTime() >= (self.Horde_NextChaseT or 0) then
			self.Horde_NextChaseT = CurTime() + CHASE_RETRY
			self:SetLastPosition(ene:GetPos())
			self:SetMovementActivity(CHASE_ACTIVITY)
			self:SCHEDULE_GOTO_POSITION("TASK_RUN_PATH", function(schedule)
				schedule:EngTask("TASK_FACE_ENEMY", 0)
				schedule.CanShootWhenMoving = true
				schedule.TurnData = { Type = VJ.FACE_ENEMY }
			end)
		end
	end
end

VJ.AddNPC("Plague Sentry","npc_vj_horde_plague_sentry", "Zombies")
