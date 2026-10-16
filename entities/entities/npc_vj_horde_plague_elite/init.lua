AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = "models/combine_super_soldier.mdl"
ENT.StartHealth = 1050
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
ENT.Weapon_FiringDistanceFar = 1750
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
ENT.GeneralSoundPitch1 = 75
ENT.GeneralSoundPitch2 = 75

function ENT:CustomOnInitialize()
	self:SetModelScale(1.25)
	self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
	self:SetColor(Color(50,50,50))

	local p = math.random()
	local horde_ar2 = self:Give("weapon_vj_horde_ar2")
	if IsValid(horde_ar2) then
		horde_ar2.NPC_HasSecondaryFire = false
	end
	local pos = Vector()
	local ang = Angle()
	local attach_id = self:LookupAttachment("eyes")
	local attach = self:GetAttachment(attach_id)
	pos = attach.Pos
	ang = attach.Ang
	pos.x = pos.x - 3
	pos.z = pos.z - 6
	pos.y = pos.y
	self.model = ents.Create("prop_dynamic")
	self.model:SetModel("models/headcrabblack.mdl")
	self.model:SetColor(Color(255, 0, 0))
	self.model:SetSequence("ragdoll")
	self.model:SetPos(pos)
	self.model:SetAngles(ang)
	self.model:Spawn()
	self.model:SetParent(self, attach_id)
	self.model:SetModelScale(1.5)

	self:EmitSound("npc/combine_gunship/see_enemy.wav", 3000, 100, 2, CHAN_STATIC)
end

function ENT:CustomOnThink_AIEnabled()
	if self.ZBoss_MiniBossesSpawned then return end
	if not IsValid(self:GetEnemy()) then return end
	self.ZBoss_MiniBossesSpawned = true

	self:VJ_ACT_PLAYACTIVITY("vjseq_releasecrab", true, false, false)
	self:EmitSound("horde/plague_elite/summon.ogg")

	if (!IsValid(self.MiniBoss1)) then
		self.MiniBoss1 = ents.Create("npc_vj_horde_plague_soldier")
		self.MiniBoss1:SetPos(self:GetPos() + self:GetRight()*45)
		self.MiniBoss1:SetAngles(self:GetAngles())
		self.MiniBoss1:Spawn()
		self.MiniBoss1:SetOwner(self)
	end

	if (!IsValid(self.MiniBoss2)) then
		self.MiniBoss2 = ents.Create("npc_vj_horde_zombine")
		self.MiniBoss2:SetPos(self:GetPos() + self:GetRight()*-45)
		self.MiniBoss2:SetAngles(self:GetAngles())
		self.MiniBoss2:Spawn()
		self.MiniBoss2:SetOwner(self)
	end
end

VJ.AddNPC("Hulk","npc_vj_horde_plague_elite", "Zombies")
