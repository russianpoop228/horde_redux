AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = {"models/zombie/classic.mdl"}
ENT.StartHealth = 700
ENT.HeadHealth = 300
ENT.HullType = HULL_HUMAN
ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.BloodColor = "Red"
ENT.HasMeleeAttack = true
ENT.MeleeAttackDistance = 45
ENT.MeleeAttackDamageDistance = 65
ENT.TimeUntilMeleeAttackDamage = 0.8
ENT.MeleeAttackBleedEnemy = false
ENT.FootStepTimeRun = 1
ENT.FootStepTimeWalk = 1
ENT.HasExtraMeleeAttackSounds = true
ENT.CanFlinch = 1
ENT.AnimTbl_Flinch = {ACT_FLINCH_PHYSICS}
ENT.SoundTbl_FootStep = {"npc/zombie/foot1.wav","npc/zombie/foot2.wav","npc/zombie/foot3.wav"}
ENT.SoundTbl_Idle = {"npc/zombie/zombie_voice_idle1.wav","npc/zombie/zombie_voice_idle2.wav","npc/zombie/zombie_voice_idle3.wav","npc/zombie/zombie_voice_idle4.wav","npc/zombie/zombie_voice_idle5.wav","npc/zombie/zombie_voice_idle6.wav"}
ENT.SoundTbl_Alert = {"npc/zombie/zombie_alert1.wav","npc/zombie/zombie_alert2.wav","npc/zombie/zombie_alert3.wav"}
ENT.SoundTbl_MeleeAttack = {"npc/zombie/zo_attack1.wav","npc/zombie/zo_attack2.wav"}
ENT.SoundTbl_MeleeAttackMiss = {"vj_zombies/slow/miss1.wav", "vj_zombies/slow/miss2.wav", "vj_zombies/slow/miss3.wav", "vj_zombies/slow/miss4.wav"}
ENT.SoundTbl_Pain = {"npc/zombie/zombie_pain1.wav","npc/zombie/zombie_pain2.wav","npc/zombie/zombie_pain3.wav","npc/zombie/zombie_pain4.wav","npc/zombie/zombie_pain5.wav","npc/zombie/zombie_pain6.wav"}
ENT.SoundTbl_Death = {"npc/zombie/zombie_die1.wav","npc/zombie/zombie_die2.wav","npc/zombie/zombie_die3.wav"}

ENT.GeneralSoundPitch1 = 100
ENT.GeneralSoundPitch2 = 100
ENT.HasDeathRagdoll = false
ENT.HasGibOnDeath = true

function ENT:CustomOnInitialize()
    self:SetBodygroup(1,1)
    self:SetColor(Color(50, 50, 50))
    self.HeadHealth = self.HeadHealth * HORDE.difficulty_health_multiplier[HORDE.difficulty]
    self:SetModelScale(1.5, 0)
    self:ManipulateBoneScale(0, Vector(2,2,2))
    self:ManipulateBoneScale(9, Vector(2,2,4))

    self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
end

function ENT:CustomOnDeath_BeforeCorpseSpawned(dmginfo, hitgroup)
    local HordeMelee_HeadshotCheck = dmginfo:GetInflictor().WasHeadshot
    if hitgroup == HITGROUP_HEAD or HordeMelee_HeadshotCheck then
        self.HasDeathRagdoll = true
        return
    end
    local e = EffectData()
        e:SetOrigin(self:GetPos())
    util.Effect("blight_explosion", e, true, true)

    local dmg = DamageInfo()
    dmg:SetInflictor(self)
    dmg:SetAttacker(self)
    dmg:SetDamageType(DMG_DISSOLVE)
    dmg:SetDamage(50)
    util.BlastDamageInfo(dmg, self:GetPos(), 300)

    sound.Play("vj_base/ambience/acid_splat.wav", self:GetPos())
end

function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
    local HordeMelee_HeadshotCheck = dmginfo:GetInflictor().WasHeadshot
    if hitgroup == HITGROUP_HEAD or HordeMelee_HeadshotCheck then
        self.HeadHealth = self.HeadHealth - dmginfo:GetDamage()
        if self.HeadHealth <= 0 then
            self:SetHealth(1)
        end
        dmginfo:ScaleDamage(2)
    else
        if HORDE:IsBlastDamage(dmginfo) or HORDE:IsFireDamage(dmginfo) then
            dmginfo:ScaleDamage(1.5)
        end
        local e = EffectData()
            e:SetOrigin(self:GetPos())
        util.Effect("blight_mini_explosion", e, true, true)
        for _, ent in pairs(ents.FindInSphere(self:GetPos(), 200)) do
			if ent:IsPlayer() then
				ent:Horde_AddDebuffBuildup(HORDE.Status_Necrosis, 8, self)
			end
		end
    end
end

VJ.AddNPC("Blight","npc_vj_horde_blight", "Zombies")
