AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = {"models/horde/bloodsquid/bloodsquid.mdl"}
ENT.StartHealth = 125
ENT.HullType = HULL_HUMAN
ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.BloodColor = "Red"
ENT.HasMeleeAttack = true
ENT.AnimTbl_MeleeAttack = {"bite"}
ENT.MeleeAttackDistance = 40
ENT.MeleeAttackDamageDistance = 85
ENT.TimeUntilMeleeAttackDamage = 0.8
ENT.MeleeAttackDamage = 30
ENT.MeleeAttackBleedEnemy = false
ENT.FootStepTimeRun = 0.5
ENT.FootStepTimeWalk = 0.5
ENT.AnimTbl_Walk = {ACT_WALK}
ENT.AnimTbl_Run = {ACT_WALK}

ENT.HasRangeAttack = true
ENT.AnimTbl_RangeAttack = {"range"}
ENT.RangeAttackEntityToSpawn = "obj_vj_horde_vomitter_projectile"
ENT.RangeDistance = 850
ENT.RangeToMeleeDistance = 200
ENT.RangeUseAttachmentForPos = true
ENT.RangeUseAttachmentForPosID = "attach_mouth"
ENT.TimeUntilRangeAttackProjectileRelease = 0.5
ENT.NextRangeAttackTime = 10

ENT.SoundTbl_FootStep = {"npc/zombie/foot1.wav","npc/zombie/foot2.wav","npc/zombie/foot3.wav"}
ENT.SoundTbl_Alert = {"horde/bloodsquid/bc_attackgrowl1.ogg","horde/bloodsquid/bc_attackgrowl2.ogg","horde/bloodsquid/bc_attackgrowl3.ogg"}
ENT.SoundTbl_MeleeAttack = {"npc/zombie/claw_strike1.wav","npc/zombie/claw_strike2.wav","npc/zombie/claw_strike3.wav"}
ENT.SoundTbl_MeleeAttackMiss = {"vj_zombies/slow/miss1.wav", "vj_zombies/slow/miss2.wav", "vj_zombies/slow/miss3.wav", "vj_zombies/slow/miss4.wav"}
ENT.SoundTbl_Pain = {"horde/bloodsquid/bc_pain1.ogg","horde/bloodsquid/bc_pain2.ogg","horde/bloodsquid/bc_pain3.ogg"}
ENT.SoundTbl_Death = {"horde/bloodsquid/bc_die1.ogg","horde/bloodsquid/bc_die2.ogg"}

ENT.GeneralSoundPitch1 = 100
ENT.GeneralSoundPitch2 = 100
function ENT:CustomOnInitialize()
	self:SetColor(Color(200, 100, 100))
	self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
end

function ENT:TranslateActivity(act)
    if act == ACT_RUN or act == ACT_WALK then
        return ACT_WALK
	end
	return self.BaseClass.TranslateActivity(self, act)
end

function ENT:CustomOnTakeDamage_BeforeImmuneChecks(dmginfo, hitgroup)
	if HORDE:IsPoisonDamage(dmginfo) then
		dmginfo:SetDamage(dmginfo:GetDamage() * 0.25)
	end
end

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

function ENT:ExecuteRangeAttack()
	if self.EnemyData.Distance <= self.RangeDistance and self.EnemyData.Distance >= self.RangeToMeleeDistance then
        local selfData = self:GetTable()
        if selfData.Dead or selfData.PauseAttacks or selfData.Flinching or selfData.AttackType == VJ.ATTACK_TYPE_MELEE then return end
        local ene = self:GetEnemy()
        local eneValid = IsValid(ene)
        if eneValid then
            selfData.AttackType = VJ.ATTACK_TYPE_RANGE
            if !self:OnRangeAttackExecute("Init", ene) then
                local projectile = ents.Create(self.RangeAttackEntityToSpawn)
                local EnemyDistanceAngle = math.max(150, self.EnemyData.Distance * 0.2)
                local target_pos = self:GetEnemy():GetPos() + Vector(0, 0, EnemyDistanceAngle)
                projectile:SetPos(self:GetAttachment(1).Pos)
                projectile:SetAngles((target_pos - projectile:GetPos()):Angle())
                projectile:SetOwner(self)
                projectile:SetPhysicsAttacker(self)
                projectile:Spawn()
                projectile:Activate()
                local phys = projectile:GetPhysicsObject()
                if IsValid(phys) then
                    phys:Wake()
                    local vel = (target_pos - self:GetAttachment(1).Pos) * 1.5
                    phys:SetVelocity(vel)
                    projectile:SetAngles(vel:GetNormal():Angle())
                else
                    local vel = self:RangeAttackProjVel(projectile)
                    projectile:SetVelocity(vel)
                    projectile:SetAngles(vel:GetNormal():Angle())
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
            end
        end
    end
end

VJ.AddNPC("Vomitter","npc_vj_horde_vomitter", "Zombies")
