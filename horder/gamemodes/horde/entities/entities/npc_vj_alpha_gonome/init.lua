AddCSLuaFile("shared.lua")
include('shared.lua')
include('autorun/vj_controls.lua')

ENT.Model = {"models/horde/gonome/gonome.mdl"}
ENT.StartHealth = 7500
ENT.HullType = HULL_MEDIUM_TALL
ENT.KnockbackImmune = true

ENT.SightDistance = 10000
ENT.SightAngle = 100
ENT.TurningSpeed = 40
ENT.MaxJumpLegalDistance = VJ_Set(400, 550)

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
ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
ENT.MeleeAttackDistance = 35
ENT.MeleeAttackDamageDistance = 90
ENT.TimeUntilMeleeAttackDamage = 0.6
ENT.NextAnyAttackTime_Melee = 0.8
ENT.MeleeAttackDamage = 40
ENT.SlowPlayerOnMeleeAttack = true
ENT.SlowPlayerOnMeleeAttack_WalkSpeed = 100
ENT.SlowPlayerOnMeleeAttack_RunSpeed = 100
ENT.MeleeAttackBleedEnemy = false
ENT.HasExtraMeleeAttackSounds = true
ENT.MeleeAttackWorldShakeOnMiss = true
ENT.MeleeAttackWorldShakeOnMissAmplitude = 8

ENT.HasRangeAttack = true
ENT.AnimTbl_RangeAttack = {ACT_RANGE_ATTACK1}
ENT.RangeAttackEntityToSpawn = "obj_vj_horde_gonome_acid"
ENT.RangeDistance = 2000
ENT.RangeToMeleeDistance = 0
ENT.RangeUseAttachmentForPos = false
ENT.RangeUseAttachmentForPosID = "Mouth"
ENT.TimeUntilRangeAttackProjectileRelease = 1.5
ENT.NextRangeAttackTime = 5
ENT.NextAnyAttackTime_Range = 0.5

ENT.HasLeapAttack = false
ENT.AnimTbl_LeapAttack = {ACT_RANGE_ATTACK2}
ENT.LeapAttackAnimationDelay = 0
ENT.NextLeapAttackTime = 15
ENT.LeapAttackVelocityForward = 400
ENT.LeapAttackVelocityUp = 0
ENT.LeapAttackDamageDistance = 150

ENT.HasMeleeAttackKnockBack = true
ENT.MeleeAttackKnockBack_Forward1 = 100
ENT.MeleeAttackKnockBack_Forward2 = 100
ENT.MeleeAttackKnockBack_Up1 = 10
ENT.MeleeAttackKnockBack_Up2 = 10
ENT.MeleeAttackKnockBack_Right1 = 0
ENT.MeleeAttackKnockBack_Right2 = 0

ENT.FootStepTimeRun = 1
ENT.FootStepTimeWalk = 1
ENT.PushProps = true
ENT.SoundTbl_FootStep = {"horde/gonome/gonome_step1.ogg","horde/gonome/gonome_step2.ogg","horde/gonome/gonome_step3.ogg","horde/gonome/gonome_step4.ogg"}
ENT.SoundTbl_Idle = {"horde/gonome/gonome_idle1.ogg","horde/gonome/gonome_idle2.ogg"}
ENT.SoundTbl_MeleeAttack = {"horde/gonome/gonome_melee1.ogg","horde/gonome/gonome_melee2.ogg"}
ENT.SoundTbl_MeleeAttackMiss = {"horde/gonome/gonome_melee1.ogg","horde/gonome/gonome_melee2.ogg"}
ENT.SoundTbl_BeforeLeapAttack = nil
ENT.SoundTbl_LeapAttackJump = {"horde/gonome/gonome_jumpattack.ogg"}
ENT.SoundTbl_Pain = {"horde/gonome/gonome_pain1.ogg","horde/gonome/gonome_pain2.ogg","horde/gonome/gonome_pain3.ogg","horde/gonome/gonome_pain4.ogg"}
ENT.SoundTbl_Death = {"horde/gonome/gonome_death.ogg"}
function ENT:CustomOnInitialize()
    self:SetCollisionBounds(Vector(20, 20, 85), Vector(-20, -20, 0))
    self:SetSkin(1)
    self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
end
function ENT:RangeAttackCode_GetShootPos(TheProjectile)
    return (self:GetEnemy():GetPos() - self:LocalToWorld(Vector(math.random(-30,30),math.random(-30,30),math.random(20,30))))*2 + self:GetUp()*300
end

ENT.RangeAttackCooldown = 0
function ENT:CustomRangeAttackCode_BeforeProjectileSpawn(projectile2)
    if true then
		self.RangeAttackCooldown = CurTime() + self.NextRangeAttackTime
		self.HasRangeAttack = false
    end
end

function ENT:CustomOnThink()
	if self.Critical and self:IsOnGround() then
		self:SetLocalVelocity(self:GetMoveVelocity() * 1.8)
	end
    if self.RangeAttackCooldown < CurTime() and not self.Critical then
        self.HasRangeAttack = true
    end
end
ENT.Critical = nil
function ENT:CustomOnTakeDamage_AfterDamage(dmginfo, hitgroup)
    if not self.Critical and self:Health() < self:GetMaxHealth() / 2 then
        self.Critical = true
        self.HasRangeAttack = false
        self.HasLeapAttack = true
        self:SetPlaybackRate(1.4)
        self:SetColor(Color(255,0,0))
        self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    end
end

function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
	if HORDE:IsPoisonDamage(dmginfo) then
		dmginfo:ScaleDamage(0.75)
    elseif HORDE:IsLightningDamage(dmginfo) then
        dmginfo:ScaleDamage(1.25)
    end
end

VJ.AddNPC("Alpha Gonome","npc_vj_alpha_gonome", "Zombies")
