AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = {"models/horde/hulk/hulk.mdl"}
ENT.StartHealth = 1200
ENT.HullType = HULL_MEDIUM_TALL
ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.BloodColor = "Red"
ENT.HasMeleeAttack = true
ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
ENT.MeleeAttackDistance = 35
ENT.MeleeAttackDamageDistance = 95
ENT.TimeUntilMeleeAttackDamage = false
ENT.MeleeAttackDamage = 57
ENT.SlowPlayerOnMeleeAttack = false
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
	self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
	self:SetMoveVelocity(Vector(0,0,0))

	self:EmitSound("npc/zombie_poison/pz_call1.wav", 1500, 90, 1, CHAN_STATIC)
end
local HULK_SPECTRE_CLASSES = {
    ["npc_vj_horde_shadow_hulk"] = true,
}

function ENT:OnMaintainRelationships(ent, calculatedDisp, entDist)
    if not IsValid(ent) or ent == self or not ent:IsNPC() then return end
    if not HULK_SPECTRE_CLASSES[ent:GetClass()] then return end

    self:AddEntityRelationship(ent, D_HT, 99)
    self:SetRelationshipMemory(ent, VJ.MEM_OVERRIDE_DISPOSITION, D_HT)

    if not self:Visible(ent) or not self:IsInViewCone(ent:GetPos()) then return end

    local ene = self:GetEnemy()
    if IsValid(ene) and HULK_SPECTRE_CLASSES[ene:GetClass()] then return end

    self:ForceSetEnemy(ent, true)
end

function ENT:OnInput(key, activator, caller, data)
	if key == "step" then
		self:PlayFootstepSound()
	elseif key == "melee" then
		self:ExecuteMeleeAttack()
	end
end
function ENT:TranslateActivity(act)
	if act == ACT_RUN or act == ACT_WALK then
		if self:IsOnFire() then
			return ACT_WALK_ON_FIRE
		elseif act == ACT_RUN && self.Critical then
			return ACT_RUN
		end
		return ACT_WALK
	end
	return self.BaseClass.TranslateActivity(self, act)
end
function ENT:OnFootstepSound(moveType, sdFile)
	util.ScreenShake(self:GetPos(), 2, 5, 0.5, 250)
end
function ENT:CustomOnThink()
	if self.Critical and self:IsOnGround() then
		self:SetLocalVelocity(self:GetMoveVelocity() * 1.5)
	end
end
ENT.Critical = false
function ENT:CustomOnTakeDamage_AfterDamage(dmginfo, hitgroup)
    if not self.Critical and self:Health() < self:GetMaxHealth() / 2 then
        self.Critical = true
        self:SetColor(Color(255,0,0))
        self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    end
end

VJ.AddNPC("Hulk","npc_vj_horde_hulk", "Zombies")
