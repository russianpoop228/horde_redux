AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = "models/combine_soldier.mdl"
ENT.StartHealth = 325
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
ENT.WeaponSpread = 1.35
ENT.Weapon_FiringDistanceFar = 1500
ENT.WeaponReload_FindCover = false
ENT.Horde_Plague_Soldier = true
ENT.CallForHelp = false
ENT.CanInvestigate = false

ENT.HasItemDropsOnDeath = false
ENT.DropWeaponOnDeath = false

ENT.SoundTbl_Pain = {
"npc/combine_soldier/pain1.wav",
"npc/combine_soldier/pain2.wav",
"npc/combine_soldier/pain3.wav"}

ENT.SoundTbl_Death = {
"npc/combine_soldier/die1.wav",
"npc/combine_soldier/die2.wav",
"npc/combine_soldier/die3.wav"}

ENT.SoundTbl_FootStep = {
"npc/combine_soldier/gear1.wav",
"npc/combine_soldier/gear2.wav",
"npc/combine_soldier/gear3.wav",
"npc/combine_soldier/gear4.wav",
"npc/combine_soldier/gear5.wav",
"npc/combine_soldier/gear6.wav"}

ENT.SoundTbl_Alert = {"vj_zombies/zombine/alert1.wav", "vj_zombies/zombine/alert2.wav", "vj_zombies/zombine/alert3.wav", "vj_zombies/zombine/alert4.wav", "vj_zombies/zombine/alert5.wav", "vj_zombies/zombine/alert6.wav"}

ENT.UseTheSameGeneralSoundPitch = true
ENT.GeneralSoundPitch1 = 75
ENT.GeneralSoundPitch2 = 75

function ENT:CustomOnInitialize()
	self:SetSkin(math.random(0,1))
	self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")

	local p = math.random()
	if p <= 0.65 then
		self:Give("weapon_vj_horde_smg1")
	else
		self:Give("weapon_vj_horde_shotgun")
		self.Weapon_FiringDistanceFar = 800
	end
	local pos = Vector()
	local ang = Angle()
	local attach_id = self:LookupAttachment("eyes")
	local attach = self:GetAttachment(attach_id)
	pos = attach.Pos
	ang = attach.Ang
	pos.x = pos.x - 3
	pos.z = pos.z - 7
	pos.y = pos.y
	self.model = ents.Create("prop_dynamic")
	self.model:SetModel("models/headcrabblack.mdl")
	self.model:SetColor(Color(255, 0, 0))
	self.model:SetSequence("ragdoll")
	self.model:SetPos(pos)
	self.model:SetAngles(ang)
	self.model:Spawn()
	self.model:SetParent(self, attach_id)
	self.model:SetModelScale(1.25)
end

VJ.AddNPC("Plague Solder","npc_vj_horde_plague_soldier", "Zombies")
