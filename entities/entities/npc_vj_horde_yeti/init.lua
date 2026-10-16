AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = {"models/horde/hulk/hulk.mdl"}
ENT.StartHealth = 1350
ENT.HullType = HULL_MEDIUM_TALL
ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.BloodColor = "Red"
ENT.HasMeleeAttack = true
ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
ENT.MeleeAttackDistance = 35
ENT.MeleeAttackDamageDistance = 95
ENT.TimeUntilMeleeAttackDamage = 0.8
ENT.MeleeAttackDamage = 50
ENT.SlowPlayerOnMeleeAttack = true
ENT.SlowPlayerOnMeleeAttack_WalkSpeed = 100
ENT.SlowPlayerOnMeleeAttack_RunSpeed = 100
ENT.SlowPlayerOnMeleeAttackTime = 5
ENT.MeleeAttackBleedEnemy = false
ENT.FootStepTimeRun = 0.4
ENT.FootStepTimeWalk = 0.4
ENT.HasMeleeAttackKnockBack = true
ENT.MeleeAttackKnockBack_Forward1 = 100
ENT.MeleeAttackKnockBack_Forward2 = 130
ENT.MeleeAttackKnockBack_Up1 = 250
ENT.MeleeAttackKnockBack_Up2 = 260
ENT.SoundTbl_FootStep = {"npc/zombie/foot1.wav", "npc/zombie/foot2.wav", "npc/zombie/foot3.wav"}
ENT.SoundTbl_Breath = "npc/zombie_poison/pz_breathe_loop1.wav"
ENT.SoundTbl_Idle = {"npc/zombie_poison/pz_idle2.wav", "npc/zombie_poison/pz_idle3.wav", "npc/zombie_poison/pz_idle4.wav"}
ENT.SoundTbl_Alert = {"npc/zombie_poison/pz_alert1.wav", "npc/zombie_poison/pz_alert2.wav"}
ENT.SoundTbl_CallForHelp = "npc/zombie_poison/pz_call1.wav"
ENT.SoundTbl_BeforeMeleeAttack = {"npc/zombie_poison/pz_warn1.wav", "npc/zombie_poison/pz_warn2.wav"}
ENT.SoundTbl_MeleeAttack = {"npc/zombie/claw_strike1.wav", "npc/zombie/claw_strike2.wav", "npc/zombie/claw_strike3.wav"}
ENT.SoundTbl_MeleeAttackMiss = {"vj_zombies/slow/miss1.wav", "vj_zombies/slow/miss2.wav", "vj_zombies/slow/miss3.wav", "vj_zombies/slow/miss4.wav"}
ENT.SoundTbl_Pain = {"npc/zombie_poison/pz_pain1.wav", "npc/zombie_poison/pz_pain2.wav", "npc/zombie_poison/pz_pain3.wav"}
ENT.SoundTbl_Death = {"npc/zombie_poison/pz_die1.wav", "npc/zombie_poison/pz_die2.wav"}
ENT.NextTick = 0

ENT.GeneralSoundPitch1 = 60
ENT.GeneralSoundPitch2 = 65

ENT.HasWorldShakeOnMove = true
ENT.WorldShakeOnMoveAmplitude = 8
ENT.WorldShakeOnMoveRadius = 200
ENT.WorldShakeOnMoveDuration = 0.4
ENT.WorldShakeOnMoveFrequency = 100
function ENT:CustomOnInitialize()
	self:SetCollisionBounds(Vector(18, 18, 90), Vector(-18, -18, 0))
	self:SetSkin(math.random(0,3))
	self:SetColor(Color(0,255,255))
	self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
end

function ENT:TranslateActivity(act)
    if act == ACT_RUN or act == ACT_WALK then
        if self:IsOnFire() then
            return ACT_WALK_ON_FIRE
        else
            return ACT_WALK
        end
    end
    return self.BaseClass.TranslateActivity(self, act)
end

function ENT:CustomOnTakeDamage_BeforeImmuneChecks(dmginfo, hitgroup)
	if HORDE:IsColdDamage(dmginfo) then
		dmginfo:SetDamage(dmginfo:GetDamage() * 0.5)
	elseif HORDE:IsFireDamage(dmginfo) then
		dmginfo:SetDamage(dmginfo:GetDamage() * 1.25)
	end
end
function ENT:OnThinkActive()
	if self.Critical then
		if SERVER then
			if CurTime() >= self.NextTick then
				local dmg = DamageInfo()
				dmg:SetAttacker(self)
				dmg:SetInflictor(self)
				dmg:SetDamageType(DMG_REMOVENORAGDOLL)
				dmg:SetDamage(5)
				for _, ent in pairs(ents.FindInSphere(self:GetPos(), 150)) do
					if ent:IsPlayer() or HORDE:IsPlayerMinion(ent) then
						ent:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 4)
						ent:TakeDamageInfo(dmg)
						dmg:SetDamagePosition(ent:GetPos())
					end
				end

				self.NextTick = CurTime() + 0.5
				local e = EffectData()
					e:SetOrigin(self:GetPos())
					e:SetScale(1)
				util.Effect("frostcloud", e, true, true)
			end
		end
	end
end
ENT.Critical = false
function ENT:CustomOnTakeDamage_AfterDamage(dmginfo, hitgroup)
    if not self.Critical and self:Health() < self:GetMaxHealth() / 2 then
        self.Critical = true
    end
end

function ENT:CustomOnMeleeAttack_AfterChecks(hitEnt, isProp)
	if hitEnt and IsValid(hitEnt) and hitEnt:IsPlayer() then
		hitEnt:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 75)
	end
end

VJ.AddNPC("Yeti","npc_vj_horde_yeti", "Zombies")
