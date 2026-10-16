AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = {"models/monk.mdl"}
ENT.StartHealth = 4500
ENT.HullType = HULL_HUMAN
ENT.VJ_NPC_Class = {"CLASS_ZOMBIE"}
ENT.WeaponSpread = 0.5
ENT.BloodColor = "Red"
ENT.SightDistance = 7000
ENT.BecomeEnemyToPlayer = true
ENT.BecomeEnemyToPlayerLevel = 2
ENT.HasMeleeAttack = true
ENT.HasFootStepSound = true
ENT.FootStepSoundLevel = 60
ENT.ShootDistance = 3000
ENT.MeleeAttackDamage = 35
ENT.AnimTbl_MeleeAttack = {"MeleeAttack01"}
ENT.TimeUntilMeleeAttackDamage = 0.6
ENT.HasMeleeAttackKnockBack = true
ENT.MeleeAttackKnockBack_Forward1 = 100
ENT.MeleeAttackKnockBack_Forward2 = 130
ENT.MeleeAttackKnockBack_Up1 = 250
ENT.MeleeAttackKnockBack_Up2 = 260

ENT.SquadName = "resistance"
ENT.FootStepTimeRun = 0.4
ENT.FootStepTimeWalk = 0.5
ENT.HasGrenadeAttack = false
ENT.AnimTbl_Flinch = {ACT_FLINCH_PHYSICS}
ENT.Passive_RunOnTouch = false
ENT.Passive_RunOnDamage = false
ENT.CallForHelp = false
ENT.HasItemDropsOnDeath = false
ENT.HasWeaponBackAway = false
ENT.WeaponBackAway_Distance = 0

ENT.HasGrenadeAttack = false
ENT.GrenadeAttackEntity = "npc_headcrab_poison"
ENT.GrenadeAttackModel = "models/headcrabblack.mdl"
ENT.AnimTbl_GrenadeAttack = {"grenThrow"}
ENT.GrenadeAttackAnimationDelay = 0
ENT.GrenadeAttackAnimationFaceEnemy = true
ENT.NextThrowGrenadeTime1 = 5
ENT.NextThrowGrenadeTime2 = 10
ENT.ThrowGrenadeChance = 1
ENT.GrenadeAttackThrowDistance = 1000
ENT.GrenadeAttackThrowDistanceClose = 500

ENT.SoundTbl_FootStep = {"zsszombie/foot1.wav","zsszombie/foot2.wav","zsszombie/foot3.wav","zsszombie/foot4.wav"}
ENT.SoundTbl_Idle = {"zsszombie/zombie_idle1.wav","zsszombie/zombie_idle2.wav","zsszombie/zombie_idle3.wav","zsszombie/zombie_idle4.wav","zsszombie/zombie_idle5.wav","zsszombie/zombie_idle6.wav"}
ENT.SoundTbl_Alert = {"vo/ravenholm/monk_mourn01.wav","vo/ravenholm/monk_mourn02.wav","vo/ravenholm/monk_mourn03.wav","vo/ravenholm/monk_mourn04.wav", "vo/ravenholm/monk_helpme05.wav"}
ENT.SoundTbl_MeleeAttack = {"zsszombie/zombie_attack_1.wav","zsszombie/zombie_attack_2.wav","zsszombie/zombie_attack_3.wav","zsszombie/zombie_attack_4.wav","zsszombie/zombie_attack_5.wav","zsszombie/zombie_attack_6.wav"}
ENT.SoundTbl_MeleeAttackMiss = {"zsszombie/miss1.wav","zsszombie/miss2.wav","zsszombie/miss3.wav","zsszombie/miss4.wav"}
ENT.SoundTbl_Pain = {"vo/ravenholm/monk_pain01.wav","vo/ravenholm/monk_pain02.wav","vo/ravenholm/monk_pain03.wav","vo/ravenholm/monk_pain04.wav","vo/ravenholm/monk_pain05.wav"}
ENT.SoundTbl_Death = {"vo/ravenholm/monk_death07.wav"}
ENT.DeathCorpseModel = {"models/zombie/classic_gal_boss.mdl"}

ENT.GeneralSoundPitch1 = 60
ENT.GeneralSoundPitch2 = 60
function ENT:CustomOnInitialize()
	self:SetModelScale(1.25)
	self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")

    self:Give("weapon_vj_horde_annabelle")
	self:SetSubMaterial(1, "models/zombie_gal/2/grigori_head")
	self:SetSubMaterial(4, "models/zombie_gal/2/monk_sheet")
	self:SetSubMaterial(2, "models/zombie_gal/2/eyeball_l")
	self:SetSubMaterial(3, "models/zombie_gal/2/eyeball_r")
	self:SetSubMaterial(6, "models/zombie_gal/2/glint")

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
	self.model:SetSequence("ragdoll")
	self.model:SetPos(pos)
	self.model:SetAngles(ang)
	self.model:Spawn()
	self.model:SetParent(self, attach_id)
	self.model:SetModelScale(1.25)
end

ENT.Critical = false
function ENT:CustomOnThink()
	if self.Critical and self:IsOnGround() then
		self:SetLocalVelocity(self:GetMoveVelocity() * 1.25)
	end
end
function ENT:CustomOnTakeDamage_AfterDamage(dmginfo, hitgroup)
    if not self.Critical and self:Health() <= self:GetMaxHealth() * 0.25 then
        self.Critical = true
    end
end

VJ.AddNPC("Father Grigori","npc_vj_horde_grigori", "Horde")
