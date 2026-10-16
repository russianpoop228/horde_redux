AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = "models/horde/infected_stalker/infected_stalker.mdl"
ENT.StartHealth = 200
ENT.HullType = HULL_HUMAN
ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.BloodColor = "Red"
ENT.HasMeleeAttack = false
ENT.AnimTbl_MeleeAttack = {}
ENT.MeleeAttackDistance = 32
ENT.MeleeAttackDamageDistance = 60
ENT.TimeUntilMeleeAttackDamage = 0.6
ENT.MeleeAttackDamage = 20
ENT.SlowPlayerOnMeleeAttack = true
ENT.SlowPlayerOnMeleeAttack_WalkSpeed = 100
ENT.SlowPlayerOnMeleeAttack_RunSpeed = 100
ENT.SlowPlayerOnMeleeAttackTime = 5
ENT.MeleeAttackBleedEnemy = false
ENT.FootStepTimeRun = 0.2
ENT.FootStepTimeWalk = 0.3
ENT.AnimTbl_Run = {ACT_WALK}
ENT.SoundTbl_FootStep = {"npc/stalker/stalker_footstep_left1.wav", "npc/stalker/stalker_footstep_left2.wav", "npc/stalker/stalker_footstep_right1.wav", "npc/stalker/stalker_footstep_right2.wav"}
ENT.SoundTbl_Breath = "npc/stalker/breathing3.wav"
ENT.SoundTbl_Idle = {"vj_zombies/special/zmisc_idle1.wav", "vj_zombies/special/zmisc_idle2.wav", "vj_zombies/special/zmisc_idle3.wav", "vj_zombies/special/zmisc_idle4.wav", "vj_zombies/special/zmisc_idle5.wav", "vj_zombies/special/zmisc_idle6.wav"}
ENT.SoundTbl_Alert = ""
ENT.SoundTbl_MeleeAttack = {"npc/zombie/claw_strike1.wav", "npc/zombie/claw_strike2.wav", "npc/zombie/claw_strike3.wav"}
ENT.SoundTbl_MeleeAttackMiss = {"vj_zombies/slow/miss1.wav", "vj_zombies/slow/miss2.wav", "vj_zombies/slow/miss3.wav", "vj_zombies/slow/miss4.wav"}
ENT.SoundTbl_Pain = {"vj_zombies/special/zmisc_pain1.wav", "vj_zombies/special/zmisc_pain2.wav", "vj_zombies/special/zmisc_pain3.wav", "vj_zombies/special/zmisc_pain4.wav", "vj_zombies/special/zmisc_pain5.wav", "vj_zombies/special/zmisc_pain6.wav"}
ENT.SoundTbl_Death = {"vj_zombies/special/zmisc_die1.wav", "vj_zombies/special/zmisc_die2.wav", "vj_zombies/special/zmisc_die3.wav"}

ENT.FootStepSoundLevel = 55
ENT.NextBlastTime = CurTime()
ENT.NextBlastCooldown = 8
ENT.AnimTbl_MeleeAttack = {}
ENT.Critical = nil
function ENT:CustomOnInitialize()
	self:SetCollisionBounds(Vector(12, 12, 65), Vector(-12, -12, 0))
	self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
end

function ENT:TranslateActivity(act)
    if act == ACT_RUN or act == ACT_WALK then
        if self.Critical then
            return ACT_RUN
        else
            return ACT_WALK
        end
    end
    return self.BaseClass.TranslateActivity(self, act)
end

function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
	if HORDE:IsLightningDamage(dmginfo) then
		dmginfo:ScaleDamage(0.5)
    elseif HORDE:IsBlastDamage(dmginfo) then
        dmginfo:ScaleDamage(1.25)
    end
end

function ENT:ShockAttack(delay)
	if self.Horde_Stunned then return end
	timer.Simple(delay, function()
		if not self:IsValid() then return end
		local dmg = DamageInfo()
		dmg:SetAttacker(self)
		dmg:SetInflictor(self)
		dmg:SetDamageType(DMG_SHOCK)
		dmg:SetDamage(12)
		util.BlastDamageInfo(dmg, self:GetPos(), 300)

		for _, ent in pairs(ents.FindInSphere(self:GetPos(), 300)) do
			if ent:IsPlayer() then
				ent:Horde_AddDebuffBuildup(HORDE.Status_Shock, 4, self)
			end
		end

		local e = EffectData()
			e:SetOrigin(self:GetPos())
			e:SetNormal(Vector(0,0,1))
		util.Effect("screecher_blast", e, true, true)
	end)
end

function ENT:CustomOnTakeDamage_AfterDamage(dmginfo, hitgroup)
	if not self.Critical and self:Health() < self:GetMaxHealth() / 2 then
        self.Critical = true
    end
end

function ENT:CustomOnThink()
    local enemy = self:GetEnemy()
    if not enemy then return end
    local EnemyDistance = self.EnemyData.Distance
    if EnemyDistance < 300 then
        if CurTime() > self.NextBlastTime then
            sound.Play("npc/stalker/go_alert2.wav", self:GetPos())
            self:VJ_ACT_PLAYACTIVITY("podconvulse", true, 1.5, false)
            self:ShockAttack(1.5)
            self:ShockAttack(1.7)
            self:ShockAttack(1.9)
            self:ShockAttack(2.1)
            self:ShockAttack(2.3)
            self.NextBlastTime = CurTime() + self.NextBlastCooldown
            timer.Simple(2.5, function ()
                if not self:IsValid() then return end
                self:VJ_ACT_PLAYACTIVITY("walk")
            end)
        end
    end
end

VJ.AddNPC("Screecher","npc_vj_horde_screecher", "Zombies")
