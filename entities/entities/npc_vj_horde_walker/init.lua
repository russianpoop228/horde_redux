AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = {
    "models/vj_zombies/slow1.mdl",
    "models/vj_zombies/slow2.mdl",
    "models/vj_zombies/slow3.mdl",
    "models/vj_zombies/slow4.mdl",
    "models/vj_zombies/slow5.mdl",
    "models/vj_zombies/slow6.mdl",
    "models/vj_zombies/slow7.mdl",
    "models/vj_zombies/slow8.mdl",
    "models/vj_zombies/slow9.mdl",
    "models/vj_zombies/slow10.mdl",
    "models/vj_zombies/slow11.mdl",
    "models/vj_zombies/slow12.mdl",}
ENT.StartHealth = 75
ENT.HullType = HULL_HUMAN
ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.BloodColor = "Red"
ENT.HasMeleeAttack = true
ENT.MeleeAttackDistance = 32
ENT.MeleeAttackDamageDistance = 65
ENT.MeleeAttackDamage = 15
ENT.SlowPlayerOnMeleeAttack = true
ENT.SlowPlayerOnMeleeAttack_WalkSpeed = 100
ENT.SlowPlayerOnMeleeAttack_RunSpeed = 100
ENT.SlowPlayerOnMeleeAttackTime = 5
ENT.MeleeAttackBleedEnemy = false
ENT.FootStepTimeRun = 1
ENT.FootStepTimeWalk = 1
ENT.CanFlinch = 1
ENT.AnimTbl_Flinch = {ACT_FLINCH_PHYSICS}
ENT.SoundTbl_FootStep = {"npc/zombie/foot1.wav", "npc/zombie/foot2.wav", "npc/zombie/foot3.wav"}
ENT.SoundTbl_Idle = {"vj_zombies/slow/zombie_idle1.wav", "vj_zombies/slow/zombie_idle2.wav", "vj_zombies/slow/zombie_idle3.wav", "vj_zombies/slow/zombie_idle4.wav", "vj_zombies/slow/zombie_idle5.wav", "vj_zombies/slow/zombie_idle6.wav"}
ENT.SoundTbl_Alert = {"vj_zombies/slow/zombie_alert1.wav", "vj_zombies/slow/zombie_alert2.wav", "vj_zombies/slow/zombie_alert3.wav", "vj_zombies/slow/zombie_alert4.wav"}
ENT.SoundTbl_MeleeAttack = {"vj_zombies/slow/zombie_attack_1.wav", "vj_zombies/slow/zombie_attack_2.wav", "vj_zombies/slow/zombie_attack_3.wav", "vj_zombies/slow/zombie_attack_4.wav", "vj_zombies/slow/zombie_attack_5.wav", "vj_zombies/slow/zombie_attack_6.wav"}
ENT.SoundTbl_MeleeAttackMiss = {"vj_zombies/slow/miss1.wav", "vj_zombies/slow/miss2.wav", "vj_zombies/slow/miss3.wav", "vj_zombies/slow/miss4.wav"}
ENT.SoundTbl_Pain = {"vj_zombies/slow/zombie_pain1.wav", "vj_zombies/slow/zombie_pain2.wav", "vj_zombies/slow/zombie_pain3.wav", "vj_zombies/slow/zombie_pain4.wav", "vj_zombies/slow/zombie_pain5.wav", "vj_zombies/slow/zombie_pain6.wav", "vj_zombies/slow/zombie_pain7.wav", "vj_zombies/slow/zombie_pain8.wav"}
ENT.SoundTbl_Death = {"vj_zombies/slow/zombie_die1.wav", "vj_zombies/slow/zombie_die2.wav", "vj_zombies/slow/zombie_die3.wav", "vj_zombies/slow/zombie_die4.wav", "vj_zombies/slow/zombie_die5.wav", "vj_zombies/slow/zombie_die6.wav"}

local sdFootScuff = {"npc/zombie/foot_slide1.wav", "npc/zombie/foot_slide2.wav", "npc/zombie/foot_slide3.wav"}

ENT.Zombie_LastAnimSet = 0

function ENT:CustomOnInitialize()
	self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
end
function ENT:CustomOnThink()
	if self:IsOnFire() then
		if self.Zombie_LastAnimSet == 0 then
			self.Zombie_LastAnimSet = 1
			self.AnimTbl_Walk = {ACT_WALK_ON_FIRE}
			self.AnimTbl_Run = {ACT_WALK_ON_FIRE}
			self.AnimTbl_IdleStand = {ACT_IDLE_ON_FIRE}
		end
	elseif self.Zombie_LastAnimSet == 1 then
		self.Zombie_LastAnimSet = 0
		self.AnimTbl_Walk = {ACT_WALK}
		self.AnimTbl_Run = {ACT_RUN}
		self.AnimTbl_IdleStand = {ACT_IDLE}
	end
end
function ENT:MultipleMeleeAttacks()
	if math.random(1, 2) == 1 then
		self.AnimTbl_MeleeAttack = {"vjseq_attacka","vjseq_attackb","vjseq_attackc","vjseq_attackd"}
		self.TimeUntilMeleeAttackDamage = 1
		self.MeleeAttackDamage = 20
	else
		self.AnimTbl_MeleeAttack = {"vjseq_attacke","vjseq_attackf"}
		self.TimeUntilMeleeAttackDamage = 1
		self.MeleeAttackDamage = 30
	end
end

VJ.AddNPC("Walker","npc_vj_horde_walker", "Zombies")
