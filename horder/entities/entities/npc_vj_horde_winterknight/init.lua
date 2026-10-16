AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = "models/vj_zombies/fast_main.mdl"
ENT.StartHealth = 6500
ENT.HullType = HULL_HUMAN
ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.BloodColor = "Red"
ENT.HasMeleeAttack = true
ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
ENT.MeleeAttackDistance = 32
ENT.MeleeAttackDamageDistance = 85
ENT.TimeUntilMeleeAttackDamage = 0.4
ENT.MeleeAttackDamage = 30
ENT.MeleeAttackBleedEnemy = false
ENT.NextAnyAttackTime_Melee = 0.6
ENT.HasLeapAttack = true
ENT.AnimTbl_LeapAttack = {"leapstrike"}
ENT.LeapDistance = 400
ENT.LeapToMeleeDistance = 250
ENT.TimeUntilLeapAttackDamage = 0.2
ENT.NextLeapAttackTime = 3
ENT.NextAnyAttackTime_Leap = 1
ENT.LeapAttackExtraTimers = {0.4,0.6,0.8,1}
ENT.TimeUntilLeapAttackVelocity = 0.2
ENT.LeapAttackVelocityForward = 300
ENT.LeapAttackVelocityUp = 250
ENT.LeapAttackDamage = 40
ENT.LeapAttackDamageDistance = 100
ENT.FootStepTimeRun = 0.4
ENT.FootStepTimeWalk = 0.6

ENT.HasMeleeAttackKnockBack = true
ENT.MeleeAttackKnockBack_Forward1 = 100
ENT.MeleeAttackKnockBack_Forward2 = 130

ENT.SoundTbl_FootStep = {"npc/fast_zombie/foot1.wav", "npc/fast_zombie/foot2.wav", "npc/fast_zombie/foot3.wav", "npc/fast_zombie/foot4.wav"}
ENT.SoundTbl_Breath = "npc/fast_zombie/breathe_loop1.wav"
ENT.SoundTbl_Alert = {"npc/fast_zombie/fz_alert_close1.wav", "npc/fast_zombie/fz_alert_far1.wav"}
ENT.SoundTbl_MeleeAttack = {"npc/zombie/claw_strike1.wav", "npc/zombie/claw_strike2.wav", "npc/zombie/claw_strike3.wav"}
ENT.SoundTbl_MeleeAttackExtra = {"npc/zombie/claw_strike1.wav", "npc/zombie/claw_strike2.wav", "npc/zombie/claw_strike3.wav"}
ENT.SoundTbl_MeleeAttackMiss = {"vj_zombies/slow/miss1.wav", "vj_zombies/slow/miss2.wav", "vj_zombies/slow/miss3.wav", "vj_zombies/slow/miss4.wav"}
ENT.SoundTbl_LeapAttackJump = ""
ENT.SoundTbl_LeapAttackDamage = {"npc/fast_zombie/claw_strike1.wav", "npc/fast_zombie/claw_strike2.wav", "npc/fast_zombie/claw_strike3.wav"}
ENT.SoundTbl_Pain = {"npc/fast_zombie/idle1.wav", "npc/fast_zombie/idle2.wav", "npc/fast_zombie/idle3.wav"}
ENT.SoundTbl_Death = "npc/fast_zombie/wake1.wav"

ENT.GeneralSoundPitch1 = 50
ENT.GeneralSoundPitch2 = 50

ENT.Raging = nil
ENT.Raged = nil
ENT.DamageReceived = 0

ENT.HasWorldShakeOnMove = true
ENT.WorldShakeOnMoveAmplitude = 6
ENT.WorldShakeOnMoveRadius = 300
ENT.WorldShakeOnMoveDuration = 0.4
ENT.WorldShakeOnMoveFrequency = 100

ENT.FrostParticle     = "ice_smoke"
ENT.FrostAuraRadius   = 256
ENT.FrostAuraBuildup  = 10
ENT.FrostAuraInterval = 1
function ENT:Rage()
    if self.Raging or self.Raged then return end
    self.Raging = true
    sound.Play("horde/lesion/lesion_enrage.ogg", self:GetPos(), 100, 50)
    self:VJ_ACT_PLAYACTIVITY("BR2_Roar", true, 1.5, true)
    timer.Simple(1.5, function ()
        if not IsValid(self) then return end
        self.HasLeapAttack = true
        self.Raged = true
        self.Raging = false
        self:SetColor(Color(125, 50, 50))
    end)
end

function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
	if HORDE:IsFireDamage(dmginfo) then
		dmginfo:ScaleDamage(0.75)
	elseif HORDE:IsColdDamage(dmginfo) or HORDE:IsMeleeDamage(dmginfo) or HORDE:IsBlastDamage(dmginfo) then
		dmginfo:ScaleDamage(1.25)
	end
end

function ENT:CustomOnInitialize()
	self:SetCollisionBounds(Vector(13, 13, 50), Vector(-13, -13, 0))
    self:SetModelScale(1.75)
    self.HasLeapAttack = false
    self:SetColor(Color(25, 25, 25))

    ParticleEffectAttach(self.FrostParticle, PATTACH_ABSORIGIN_FOLLOW, self, 0)

    self:StartFrostAura()
    local id = self:GetCreationID()
    self:CallOnRemove("Horde_WinterKnightAura", function()
        timer.Remove("Horde_WinterKnightAura" .. id)
    end)

    timer.Remove("Horde_FlayerRage" .. id)
    timer.Create("Horde_FlayerRage" .. id, 10, 1, function ()
        if not IsValid(self) then return end
        self:Rage()
    end)
    self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
end

function ENT:StartFrostAura()
    local id = self:GetCreationID()
    timer.Remove("Horde_WinterKnightAura" .. id)
    timer.Create("Horde_WinterKnightAura" .. id, self.FrostAuraInterval, 0, function()
        if not IsValid(self) or self.Dead then
            timer.Remove("Horde_WinterKnightAura" .. id)
            return
        end
        for _, ent in ipairs(ents.FindInSphere(self:GetPos(), self.FrostAuraRadius)) do
            if (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) and HORDE:IsFriendlyUnit(ent) then
                ent:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, self.FrostAuraBuildup, self)
            end
        end
    end)
end

function ENT:TranslateActivity(act)
    if act == ACT_RUN or act == ACT_WALK then
        if self.Raging or self.Raged then
			return ACT_RUN
		else
            return ACT_WALK
        end
	end
	return self.BaseClass.TranslateActivity(self, act)
end

function ENT:CustomOnMeleeAttack_AfterChecks(hitEnt, isProp)
    if isProp then return end
    if hitEnt and IsValid(hitEnt) and hitEnt:IsPlayer() then
        self:UnRage()
        hitEnt:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 100, self)
    elseif not self.Raging then
        local id = self:GetCreationID()
        timer.Remove("Horde_FlayerRage" .. id)
        timer.Create("Horde_FlayerRage" .. id, 10, 1, function ()
            if not IsValid(self) then return end
            self:Rage()
        end)
    end
end

function ENT:CustomOnMeleeAttack_Miss()
    if not self.Raging then
        local id = self:GetCreationID()
        timer.Remove("Horde_FlayerRage" .. id)
        timer.Create("Horde_FlayerRage" .. id, 10, 1, function ()
            if not IsValid(self) then return end
            self:Rage()
        end)
    end
end

function ENT:UnRage()
    self.Raged = nil
    self.Raging = nil
    self.DamageReceived = 0
    self.HasLeapAttack = false
    self:SetColor(Color(25, 25, 25))
    local id = self:GetCreationID()
    timer.Remove("Horde_FlayerRage" .. id)
    timer.Create("Horde_FlayerRage" .. id, 10, 1, function ()
        if not IsValid(self) then return end
        self:Rage()
    end)
end

function ENT:CustomOnLeapAttack_BeforeChecks(hitEnt, isProp)
    self:EmitSound("horde/lesion/lesion_leap.ogg", 75, 75)
end

function ENT:CustomOnLeapAttack_AfterChecks(hitEnt, isProp)
    if isProp then return end
    if not self.Raged then return end
    if hitEnt and IsValid(hitEnt) and (HORDE:IsPlayerOrMinion(hitEnt) == true) then
        self:UnRage()
        hitEnt:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 100, self)
    end
end

function ENT:CustomOnTakeDamage_AfterDamage(dmginfo, hitgroup)
    self.DamageReceived = self.DamageReceived + dmginfo:GetDamage()
    if self.DamageReceived >= self:GetMaxHealth() * 0.10 then
        self:Rage()
        self.DamageReceived = 0
    end
end

VJ.AddNPC("Winter Knight","npc_vj_horde_winterknight", "Zombies")
