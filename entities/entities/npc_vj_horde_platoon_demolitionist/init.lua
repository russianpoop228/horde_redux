AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = "models/combine_soldier.mdl"
ENT.StartHealth = 4250
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
ENT.GrenadeAttackEntity = "horde_vj_platoon_demolitionist_nade"
ENT.FootStepTimeRun = 0.3
ENT.FootStepTimeWalk = 0.5
ENT.CallForBackUpOnDamage = false
ENT.CanDetectDangers = false
ENT.MoveOrHideOnDamageByEnemy = false
ENT.WeaponSpread = 1.5
ENT.Weapon_FiringDistanceFar = 1500
ENT.WeaponReload_FindCover = false
ENT.Horde_Plague_Soldier = true
ENT.EntitiesToNoCollide = {"npc_vj_horde_platoon_heavy", "npc_vj_horde_platoon_berserker", "npc_vj_horde_platoon_demolitionist"}

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
ENT.DisableCritical = nil

function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
	if HORDE:IsBlastDamage(dmginfo) then
		dmginfo:ScaleDamage(0.75)
	end

	if (not self.DisableCritical) and self:Health() <= self:GetMaxHealth() * 0.5 then
		self.Critical = true
	end
end

function ENT:CustomOnInitialize()
	self:SetModelScale(1.25)
	self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
	self:SetColor(Color(100,100,100))

	local p = math.random()
	self:Give("weapon_vj_horde_rpg")
	local pos = Vector()
	local ang = Angle()
	local attach_id = self:LookupAttachment("eyes")
	local attach = self:GetAttachment(attach_id)
	pos = attach.Pos
	ang = attach.Ang
	pos.x = pos.x - 3
	pos.z = pos.z - 15
	pos.y = pos.y
	self.model = ents.Create("prop_dynamic")
	self.model:SetModel("models/headcrabclassic.mdl")
	self.model:SetColor(Color(100, 100, 100))
	self.model:SetSequence("idle01")
	self.model:SetPos(pos)
	self.model:SetAngles(ang)
	self.model:Spawn()
	self.model:SetParent(self, attach_id)
	self.model:SetModelScale(1.5)

	self:EmitSound("npc/combine_gunship/see_enemy.wav", 3000, 100, 2, CHAN_STATIC)
end

VJ.AddNPC("Platoon","npc_vj_horde_platoon_demolitionist", "Zombies")
