AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = {"models/horde/gonome/gonome.mdl"}
ENT.StartHealth = 9000
ENT.HullType = HULL_MEDIUM_TALL
ENT.FindEnemy_CanSeeThroughWalls = true

ENT.HasRangeAttack = true
ENT.AnimTbl_RangeAttack = {"vjseq_idle2"}
ENT.RangeAttackEntityToSpawn = "obj_vj_horde_breen_projectile"
ENT.RangeDistance = 5000
ENT.RangeToMeleeDistance = 0
ENT.RangeUseAttachmentForPos = false
ENT.RangeUseAttachmentForPosID = "hand_right"
ENT.TimeUntilRangeAttackProjectileRelease = 2
ENT.NextRangeAttackTime = 10
ENT.NextAnyAttackTime_Range = 0.5
ENT.RangeAttackPos_Up = 50
ENT.RangeAttackPos_Forward = 0
ENT.RangeAttackPos_Right = 0

ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.BloodColor = "Red"
ENT.HasMeleeAttack = true
ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
ENT.MeleeAttackExtraTimers = {1.0}
ENT.MeleeAttackDistance = 60
ENT.MeleeAttackDamageDistance = 80
ENT.TimeUntilMeleeAttackDamage = 0.6
ENT.MeleeAttackDamage = 40
ENT.FootStepTimeRun = 0.4
ENT.FootStepTimeWalk = 0.4
ENT.HasExtraMeleeAttackSounds = true
ENT.SlowPlayerOnMeleeAttack = true
ENT.SlowPlayerOnMeleeAttack_WalkSpeed = 100
ENT.SlowPlayerOnMeleeAttack_RunSpeed = 100
ENT.SlowPlayerOnMeleeAttackTime = 5
ENT.MeleeAttackBleedEnemy = false
ENT.HasMeleeAttackKnockBack = true
ENT.MeleeAttackKnockBack_Forward1 = 100
ENT.MeleeAttackKnockBack_Forward2 = 130
ENT.MeleeAttackKnockBack_Up1 = 250
ENT.MeleeAttackKnockBack_Up2 = 260
ENT.RangeUseAttachmentForPos = true
ENT.RangeUseAttachmentForPosID = "hand_right"
ENT.RangeAttackPos_Up = 20
ENT.RangeAttackPos_Forward = 10
ENT.RangeAttackPos_Right = 10
ENT.AnimTbl_IdleStand = {"Idle1","Idle2"}

ENT.CanFlinch = 0
ENT.AnimTbl_Flinch = {"Flinch"}

ENT.SoundTbl_BeforeRangeAttack = {"npc/attack_helicopter/aheli_charge_up.wav"}
ENT.SoundTbl_FootStep = {"horde/gonome/gonome_step1.ogg","horde/gonome/gonome_step2.ogg","horde/gonome/gonome_step3.ogg","horde/gonome/gonome_step4.ogg"}
ENT.SoundTbl_Idle = {"horde/gonome/gonome_idle1.ogg","horde/gonome/gonome_idle2.ogg", "vo/citadel/br_youneedme.wav", "vo/citadel/br_youfool.wav"}
ENT.SoundTbl_MeleeAttack = {"horde/gonome/gonome_melee1.ogg","horde/gonome/gonome_melee2.ogg"}
ENT.SoundTbl_MeleeAttackMiss = {"horde/gonome/gonome_melee1.ogg","horde/gonome/gonome_melee2.ogg"}
ENT.SoundTbl_Pain = {"horde/gonome/gonome_pain1.ogg","horde/gonome/gonome_pain2.ogg","horde/gonome/gonome_pain3.ogg","horde/gonome/gonome_pain4.ogg", "vo/citadel/br_no.wav"}
ENT.SoundTbl_Death = {"vo/citadel/br_no.wav"}
ENT.SoundTbl_SoundTrack = nil
ENT.NextBlastTime = CurTime()
ENT.NextBlastCooldown = 13
ENT.NextSummonTime = CurTime()
ENT.HaveSpawned = false

ENT.Breen_Cooldown = 0
ENT.DamageThreshold = 5000
ENT.DamageReceived = 0
ENT.Horde_NoRandAngle = true

ENT.Timer_Hemo = 3
ENT.Timer_Norm = 2.5

ENT.GeneralSoundPitch1 = 50
ENT.GeneralSoundPitch2 = 50
local attackTimers = {
	[VJ.ATTACK_TYPE_MELEE] = function(self, skipStopAttacks)
		if !skipStopAttacks then
			timer.Create("attack_melee_reset" .. self:EntIndex(), self:GetAttackTimer(self.NextAnyAttackTime_Melee, self.TimeUntilMeleeAttackDamage, self.AttackAnimDuration), 1, function()
				self:StopAttacks()
				self:MaintainAlertBehavior()
			end)
		end
		timer.Create("attack_melee_reset_able" .. self:EntIndex(), self:GetAttackTimer(self.NextMeleeAttackTime), 1, function()
			self.IsAbleToMeleeAttack = true
		end)
	end,
	[VJ.ATTACK_TYPE_RANGE] = function(self, skipStopAttacks)
		if !skipStopAttacks then
			timer.Create("attack_range_reset" .. self:EntIndex(), self:GetAttackTimer(self.NextAnyAttackTime_Range, self.TimeUntilRangeAttackProjectileRelease, self.AttackAnimDuration), 1, function()
				self:StopAttacks()
				self:MaintainAlertBehavior()
			end)
		end
		timer.Create("attack_range_reset_able" .. self:EntIndex(), self:GetAttackTimer(self.NextRangeAttackTime), 1, function()
			self.IsAbleToRangeAttack = true
		end)
	end,
	[VJ.ATTACK_TYPE_LEAP] = function(self, skipStopAttacks)
		if !skipStopAttacks then
			timer.Create("attack_leap_reset" .. self:EntIndex(), self:GetAttackTimer(self.NextAnyAttackTime_Leap, self.TimeUntilLeapAttackDamage, self.AttackAnimDuration), 1, function()
				self:StopAttacks()
				self:MaintainAlertBehavior()
			end)
		end
		timer.Create("attack_leap_reset_able" .. self:EntIndex(), self:GetAttackTimer(self.NextLeapAttackTime), 1, function()
			self.IsAbleToLeapAttack = true
		end)
	end
}

function ENT:CustomOnThink()
    if self.IsFiringRocket then return end
    if self.NextBlastTime < CurTime() then
        local enemy = self:GetEnemy()
        local EnemyDistance = self.EnemyData.Distance
        if enemy and EnemyDistance < 350 then
            if self.DamageReceived >= self.DamageThreshold then
                sound.Play("weapons/physcannon/physcannon_claws_close.wav", self:GetPos())
                sound.Play("weapons/physcannon/physcannon_claws_open.wav", self:GetPos())
                self:VJ_ACT_PLAYACTIVITY("big_flinch", true, self.Timer_Hemo, false)
                timer.Simple(self.Timer_Hemo, function()
                    if not self:IsValid() then return end
                    local blast = ents.Create("prop_combine_ball")
                    blast:SetPos(self:GetPos())
                    blast:SetParent(self)
                    blast:Spawn()
                    blast:Fire("explode","",0)
                    local dmg = DamageInfo()
                    dmg:SetAttacker(self)
                    dmg:SetInflictor(self)
                    dmg:SetDamageType(DMG_CRUSH)
                    dmg:SetDamage(75)
                    util.BlastDamageInfo(dmg, self:GetPos(), 500)

                    for _, ent in pairs(ents.FindInSphere(self:GetPos(), 450)) do
                        if ent:IsPlayer() then
                            ent:Horde_AddHemorrhage(self)
                            ent:Horde_AddDebuffBuildup(HORDE.Status_Shock, 30)
                        end
                    end
                end)
                self.NextBlastTime = CurTime() + self.NextBlastCooldown
                self.DamageReceived = 0
            else
                sound.Play("weapons/physcannon/physcannon_charge.wav", self:GetPos())
                self:VJ_ACT_PLAYACTIVITY("big_flinch", true, self.Timer_Norm, false)
                timer.Simple(self.Timer_Norm, function()
                    if not self:IsValid() then return end
                    local blast = ents.Create("prop_combine_ball")
                    blast:SetPos(self:GetPos())
                    blast:SetParent(self)
                    blast:Spawn()
                    blast:Fire("explode","",0)
                    local dmg = DamageInfo()
                    dmg:SetAttacker(self)
                    dmg:SetInflictor(self)
                    dmg:SetDamageType(DMG_CRUSH)
                    dmg:SetDamage(75)
                    util.BlastDamageInfo(dmg, self:GetPos(), 500)

                    for _, ent in pairs(ents.FindInSphere(self:GetPos(), 450)) do
                        if ent:IsPlayer() then
                            ent:Horde_AddDebuffBuildup(HORDE.Status_Bleeding, 60)
                            ent:Horde_AddDebuffBuildup(HORDE.Status_Shock, 30)
                        end
                    end
                end)
                self.NextBlastTime = CurTime() + self.NextBlastCooldown
            end
        end
    end
end

function ENT:CustomOnInitialize()
	self:SetColor(Color(148,0,211))
	self:SetCollisionBounds(Vector(25, 25, 90), Vector(-25, -25, 0))
	self:SetModelScale(1.25)
    self.NextBlastTime = CurTime() + self.NextBlastCooldown
	timer.Simple(1, function() self.DamageThreshold = self:GetMaxHealth() * 0.05 end)

	local pos = Vector()
	local ang = Angle()

	local bone_id = self:LookupBone("Bone01")

	pos, ang = self:GetBonePosition(bone_id)
    pos.x = pos.x
    pos.z = pos.z - 90
    pos.y = pos.y + 4

    ang.x = ang.x + 30
    ang.z = ang.z - 50
    ang.y = ang.y + 150
	self.breen = ents.Create("prop_dynamic")
	self.breen:SetModel("models/player/breen.mdl")
	self.breen:Activate()
	self.breen:DeleteOnRemove(self);
	self.breen:SetPos(pos)
	self.breen:SetAngles(ang)
    self.breen:Spawn()
	self.breen:SetColor(Color(255,100,100))
    self.breen:FollowBone(self, bone_id)
	self.breen:SetSequence("zombie_cidle_01")

	bone_id = self:LookupBone("Bone01")
	pos, ang = self:GetBonePosition(bone_id)
    pos.x = pos.x - 17
    pos.z = pos.z - 53
    pos.y = pos.y - 30

	ang.x = ang.x + 30
	ang.z = ang.z - 40

	self.model = ents.Create("prop_dynamic")
	self.model:SetModel("models/weapons/w_rocket_launcher.mdl")
	self.model:Activate()
	self.model:DeleteOnRemove(self);
	self.model:SetPos(pos)
	self.model:SetAngles(ang)
    self.model:Spawn()
    self.model:FollowBone(self, bone_id)
	self.model:SetModelScale(2)

	self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
end

function ENT:OnRangeAttack(status, enemy)
    if not self.IsAbleToRangeAttack then return end
    self.IsFiringRocket = true
end

function ENT:ExecuteRangeAttack()
    local selfData = self:GetTable()
	if selfData.Dead or selfData.PauseAttacks or selfData.Flinching or selfData.AttackType == VJ.ATTACK_TYPE_MELEE then return end
    local ene = self:GetEnemy()
	local eneValid = IsValid(ene)
	if eneValid then
		selfData.AttackType = VJ.ATTACK_TYPE_RANGE
		if !self:OnRangeAttackExecute("Init", ene) then
			local projectile = ents.Create(self.RangeAttackEntityToSpawn)
			local target_pos = self:GetEnemy():GetPos()
			projectile:SetPos(self:GetAttachment(1).Pos + Vector(0, 0, 10))
			projectile:SetAngles((target_pos - projectile:GetPos()):Angle())
			projectile:SetOwner(self)
			projectile:SetPhysicsAttacker(self)
            if self.Critical then
                projectile.OwnerCritical = true
            end
			projectile:Spawn()
			projectile:Activate()
			local phys = projectile:GetPhysicsObject()
			if IsValid(phys) then
				phys:Wake()
				local vel = (target_pos - self:GetAttachment(1).Pos) * 1.5
				phys:SetVelocity(vel)
				projectile:SetAngles(vel:GetNormalized():Angle())
				self.model:MuzzleFlash()
			else
				local vel = self:RangeAttackProjVel(projectile)
				projectile:SetVelocity(vel)
				projectile:SetAngles(vel:GetNormalized():Angle())
			end
			self:OnRangeAttackExecute("PostSpawn", ene, projectile)
		end
	end
	if selfData.AttackState < VJ.ATTACK_STATE_EXECUTED then
		if eneValid then
			self:PlaySoundSystem("RangeAttack")
		end
		selfData.AttackState = VJ.ATTACK_STATE_EXECUTED
		if selfData.TimeUntilRangeAttackProjectileRelease then
			attackTimers[VJ.ATTACK_TYPE_RANGE](self)
            self.IsFiringRocket = nil
		end
	end
end

function ENT:MultipleMeleeAttacks()
	local EnemyDistance = self:VJ_GetNearestPointToEntityDistance(self:GetEnemy(),self:GetPos():Distance(self:GetEnemy():GetPos()))
	if EnemyDistance < 100 then
		self.MeleeAttackDistance = 45
		self.TimeUntilMeleeAttackDamage = 0.6
		self.MeleeAttackAnimationFaceEnemy = false
		self.AnimTbl_MeleeAttack = {"vjseq_attack1"}
		self.MeleeAttackExtraTimers = {1.0}
		self.MeleeAttackDamage = 30
		self.MeleeAttackDamageDistance = 120
		self.MeleeAttackDamageType = DMG_SLASH

		if self.Breen_Cooldown <= CurTime() then
			sound.Play("vo/Citadel/br_laugh01.wav", self:GetPos(), 100, 50)
			self.Breen_Cooldown = CurTime() + math.random(30,60)
		end
	end
end

function ENT:CustomOnMeleeAttack_AfterChecks(TheHitEntity)
	ParticleEffect("vomit_barnacle",TheHitEntity:GetPos() + self:GetUp()* 10,Angle(0,0,0),nil)
	ParticleEffect("blood_impact_green_01",TheHitEntity:GetPos(),Angle(0,0,0),nil)

	if TheHitEntity and IsValid(TheHitEntity) and TheHitEntity:IsPlayer() then
        TheHitEntity:Horde_AddHemorrhage(self)
    end
end
function ENT:RangeAttackCode_GetShootPos(TheProjectile)
     return (self:GetEnemy():GetPos() - self:LocalToWorld(Vector(math.random(-10,20),math.random(-10,20),math.random(10,20))))*2 + self:GetUp()*200
end

ENT.Critical = false
function ENT:CustomOnTakeDamage_AfterDamage(dmginfo, hitgroup)
    if not self.Critical and self:Health() < self:GetMaxHealth() / 2 then
        self.Critical = true
        self:SetPlaybackRate(1.25)
        self.Timer_Hemo = 2.4
        self.Timer_Norm = 2
    end
	self.DamageReceived = self.DamageReceived + dmginfo:GetDamage()
end

function ENT:TranslateActivity(act)
    return self.BaseClass.TranslateActivity(self, act)
end

function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
	if HORDE:IsPhysicalDamage(dmginfo) then
		dmginfo:ScaleDamage(0.75)
    elseif HORDE:IsPoisonDamage(dmginfo) then
        dmginfo:ScaleDamage(1.25)
    end
end

VJ.AddNPC("Wallace Breen","npc_vj_horde_breen", "Zombies")
