AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = {"models/horde/gonarch/gonarch.mdl"}
ENT.StartHealth = 7000
ENT.HullType = HULL_MEDIUM

ENT.SightDistance = 10000
ENT.SightAngle = 100
ENT.TurningSpeed = 40
ENT.MaxJumpLegalDistance = VJ_Set(400, 550)
ENT.EntitiesToNoCollide = {"npc_vj_horde_baby_headcrab", "npc_headcrab"}

ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.ConstantlyFaceEnemy = true
ENT.ConstantlyFaceEnemy_IfAttacking = true
ENT.ConstantlyFaceEnemy_Postures = "Standing"
ENT.ConstantlyFaceEnemyDistance = 2000
ENT.NoChaseAfterCertainRange = false
ENT.NoChaseAfterCertainRange_FarDistance = "UseRangeDistance"
ENT.NoChaseAfterCertainRange_CloseDistance = "UseRangeDistance"
ENT.NoChaseAfterCertainRange_Type = "OnlyRange"
ENT.InvestigateSoundDistance = 100

ENT.AttackProps = true
ENT.PushProps = true
ENT.PropAP_MaxSize = 2
ENT.FindEnemy_CanSeeThroughWalls = true

ENT.BloodColor = "Red"
ENT.Immune_Dissolve = true
ENT.Immune_Physics = true

ENT.CanFlinch = 0
ENT.NextFlinchTime = 2
ENT.AnimTbl_Flinch = {ACT_FLINCH_PHYSICS}
ENT.RunAwayOnUnknownDamage = false
ENT.CallForBackUpOnDamage = false

ENT.HasMeleeAttack = true
ENT.AnimTbl_MeleeAttack = {"claw", "claw_2", "claw_3"}
ENT.MeleeAttackDistance = 100
ENT.MeleeAttackDamageDistance = 150
ENT.TimeUntilMeleeAttackDamage = 0.7
ENT.MeleeAttackDamage = 30

ENT.HasRangeAttack = true
ENT.RangeAttackEntityToSpawn = "obj_vj_horde_gonarch_acid"
ENT.AnimTbl_RangeAttack = {ACT_RANGE_ATTACK1}
ENT.RangeDistance = 2000
ENT.RangeToMeleeDistance = 500
ENT.TimeUntilRangeAttackProjectileRelease = 0.5
ENT.NextRangeAttackTime = 0.1
ENT.NextRangeAttackTime_DoRand = 4
ENT.RangeAttackPos_Up = 180

ENT.HasMeleeAttackKnockBack = true
ENT.MeleeAttackKnockBack_Forward1 = 100
ENT.MeleeAttackKnockBack_Forward2 = 100
ENT.MeleeAttackKnockBack_Up1 = 50
ENT.MeleeAttackKnockBack_Up2 = 50
ENT.MeleeAttackKnockBack_Right1 = 0
ENT.MeleeAttackKnockBack_Right2 = 0

ENT.FootStepTimeRun = 1
ENT.FootStepTimeWalk = 1
ENT.PushProps = true

ENT.SoundTbl_FootStep = {"horde/gonarch/gon_step1.ogg","horde/gonarch/gon_step2.ogg","horde/gonarch/gon_step3.ogg"}
ENT.SoundTbl_Alert = {"horde/gonarch/gon_alert1.ogg","horde/gonarch/gon_alert2.ogg","horde/gonarch/gon_alert3.ogg"}
ENT.SoundTbl_BeforeMeleeAttack = {"horde/gonarch/gon_attack1.ogg","horde/gonarch/gon_attack2.ogg","horde/gonarch/gon_attack3.ogg"}
ENT.SoundTbl_MeleeAttackMiss = {"vj_zombies/slow/miss1.wav", "vj_zombies/slow/miss2.wav", "vj_zombies/slow/miss3.wav", "vj_zombies/slow/miss4.wav"}
ENT.SoundTbl_BeforeRangeAttack = {"horde/gonarch/gon_attack1.ogg","horde/gonarch/gon_attack2.ogg","horde/gonarch/gon_attack3.ogg"}
ENT.SoundTbl_RangeAttack = {"horde/gonarch/gon_sack1.ogg","horde/gonarch/gon_sack2.ogg","horde/gonarch/gon_sack3.ogg"}
ENT.SoundTbl_Pain = {"horde/gonarch/gon_pain1.ogg","horde/gonarch/gon_pain2.ogg","horde/gonarch/gon_pain3.ogg"}
ENT.SoundTbl_Death = {"horde/gonarch/gon_die1.ogg"}
local sdBirth = {"horde/gonarch/gon_birth1.ogg", "horde/gonarch/gon_birth2.ogg", "horde/gonarch/gon_birth3.ogg"}
local sdBabyDeath = {"horde/gonarch/gon_childdie1.ogg", "horde/gonarch/gon_childdie2.ogg", "horde/gonarch/gon_childdie3.ogg"}

ENT.Gonarch_NumBabies = 0
ENT.Gonarch_BabyLimit = 20
ENT.Gonarch_NextBirthT = 0
ENT.Gonarch_NextDeadBirthT = 0
function ENT:CustomOnInitialize()
    self:SetCollisionBounds(Vector(80,80,180),Vector(-80,-80,0))
	self:SetModelScale(0.75)
    self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")

	self.Gonarch_NextBirthT = CurTime() + 3
	self.Gonarch_NumBabies = 0
end

ENT.Critical = nil
function ENT:CustomOnTakeDamage_AfterDamage(dmginfo, hitgroup)
    if not self.Critical and (self:Health() < self:GetMaxHealth() * 0.6) then
        self.Critical = true
    end
end

function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
	if HORDE:IsPhysicalDamage(dmginfo) then
		dmginfo:ScaleDamage(0.75)
	elseif HORDE:IsPoisonDamage(dmginfo) then
		dmginfo:ScaleDamage(0.5)
	elseif HORDE:IsBlastDamage(dmginfo) then
		dmginfo:ScaleDamage(1.25)
	end
end

function ENT:Gonarch_BabyDeath()
	self.Gonarch_NumBabies = self.Gonarch_NumBabies - 1
	if CurTime() > self.Gonarch_NextDeadBirthT then
		self.AllyDeathSoundT = 0
		self:PlaySoundSystem("AllyDeath", sdBabyDeath)
		self.Gonarch_NextDeadBirthT = CurTime() + 10
	end
end

function ENT:CustomOnThink_AIEnabled()
	if self.Critical and IsValid(self:GetEnemy()) && CurTime() > self.Gonarch_NextBirthT && self.Gonarch_NumBabies < self.Gonarch_BabyLimit then
		self:VJ_ACT_PLAYACTIVITY(ACT_SPECIAL_ATTACK1, true, false, true)

		for i = 1, 3 do
			local bCrab = ents.Create("npc_vj_horde_headcrab_baby")
			if i == 1 then
				bCrab:SetPos(self:GetPos() + self:GetUp()*20)
			elseif i == 2 then
				bCrab:SetPos(self:GetPos() + self:GetUp()*20 + self:GetRight()*25)
			elseif i == 3 then
				bCrab:SetPos(self:GetPos() + self:GetUp()*20 + self:GetRight()*-25)
			end
			bCrab:SetAngles(self:GetAngles())
			bCrab.BabH_Mother = self
			bCrab.VJ_NPC_Class = self.VJ_NPC_Class
			bCrab:Spawn()
			bCrab:Activate()
			bCrab:SetOwner(self)
			self.Gonarch_NumBabies = self.Gonarch_NumBabies + 1
		end

		self.Gonarch_NextBirthT = CurTime() + 15
	end
end

function ENT:RangeAttackCode_GetShootPos(projectile)
	return (self:GetEnemy():GetPos() - self:GetPos()) *0.45 + self:GetUp() *600
end

VJ.AddNPC("Xen Host Unit","npc_vj_horde_xen_host_unit", "Zombies")
