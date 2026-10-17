AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = "models/vj_zombies/fast_main.mdl"
ENT.StartHealth = 10000
ENT.HullType = HULL_HUMAN
ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.BloodColor = "Oil"
ENT.HasMeleeAttack = true
ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
ENT.MeleeAttackDistance = 50
ENT.MeleeAttackDamageDistance = 85
ENT.TimeUntilMeleeAttackDamage = 0.2
ENT.MeleeAttackDamage = 20
ENT.MeleeAttackBleedEnemy = false
ENT.HasLeapAttack = true
ENT.NextAnyAttackTime_Melee = 0.6
ENT.AnimTbl_LeapAttack = {"leapstrike"}
ENT.LeapDistance = 350
ENT.LeapToMeleeDistance = 200
ENT.TimeUntilLeapAttackDamage = 0.2
ENT.NextLeapAttackTime = 10
ENT.NextAnyAttackTime_Leap = 0.6
ENT.LeapAttackExtraTimers = {0.4,0.6,0.8,1}
ENT.TimeUntilLeapAttackVelocity = 0.2
ENT.LeapAttackVelocityForward = 150
ENT.LeapAttackVelocityUp = 265
ENT.LeapAttackDamage = 30
ENT.LeapAttackDamageDistance = 100
ENT.FootStepTimeRun = 0.3
ENT.FootStepTimeWalk = 0.5

ENT.HasMeleeAttackKnockBack = true
ENT.MeleeAttackKnockBack_Forward1 = 150
ENT.MeleeAttackKnockBack_Forward2 = 200

ENT.SoundTbl_FootStep = {"horde/dead_hound/dh_foot1.mp3"}
ENT.SoundTbl_Breath = {"horde/dead_hound/dh_breath.mp3"}
ENT.SoundTbl_Alert = {"npc/fast_zombie/fz_alert_close1.wav"}
ENT.SoundTbl_MeleeAttack = {"npc/fast_zombie/claw_strike1.wav","npc/fast_zombie/claw_strike2.wav","npc/fast_zombie/claw_strike3.wav"}
ENT.SoundTbl_MeleeAttackMiss = {"zsszombie/miss1.wav","zsszombie/miss2.wav","zsszombie/miss3.wav","zsszombie/miss4.wav"}
ENT.SoundTbl_LeapAttackDamage = {"npc/fast_zombie/claw_strike1.wav","npc/fast_zombie/claw_strike2.wav","npc/fast_zombie/claw_strike3.wav"}
ENT.SoundTbl_Pain = {"npc/fast_zombie/idle1.wav","npc/fast_zombie/idle2.wav","npc/fast_zombie/idle3.wav"}
ENT.SoundTbl_Death = {"npc/fast_zombie/wake1.wav"}

ENT.GeneralSoundPitch1 = 45
ENT.GeneralSoundPitch2 = 45

ENT.Raging = nil
ENT.Enraging = nil
ENT.Furious = nil
ENT.Raged = nil
ENT.Phase2 = nil
ENT.Phase3 = nil
ENT.Finisher = nil

ENT.DamageAccumulator = 0
ENT.Quotes = 0
ENT.RageDamageAccumulator  = 0

ENT.LastAttacker = nil
ENT.DeathHandled = nil
ENT.StunCooldown = 25

ENT.HasWorldShakeOnMove = true
ENT.WorldShakeOnMoveAmplitude = 3
ENT.WorldShakeOnMoveRadius = 450
ENT.WorldShakeOnMoveDuration = 0.3
ENT.WorldShakeOnMoveFrequency = 100

local defeatPhrases = {
    "Dead Hound: I will avenge.",
    "Dead Hound: This is not the end.",
    "Dead Hound: I am not the doom. I am its servant.",
    "Dead Hound: You have sealed your own extinction.",
    "Dead Hound: Your world will burn with me.",
    "Dead Hound: Death is only the beginning... for you.",
    "Dead Hound: The grave has no chains strong enough to hold me.",
    "Dead Hound: Your victory is an illusion.",
}

local enragePhrases = {
    "Dead Hound: You cannot stop the inevitable.",
    "Dead Hound: Your fear feeds me.",
    "Dead Hound: The abyss is calling... and you will answer.",
    "Dead Hound: Run while you still have legs.",
    "Dead Hound: I am the nightmare that walks.",
    "Dead Hound: Your hope dies here.",
    "Dead Hound: Every wound only makes me stronger.",
    "Dead Hound: You are already dead. You just don't know it yet.",
}

local furyPhrases = {
    "Dead Hound: THERE IS NO ESCAPE FROM OBLIVION!",
    "Dead Hound: I WILL DRAG YOU ALL INTO THE VOID!",
    "Dead Hound: YOUR WORLD ENDS IN SMOKE AND ASH!",
    "Dead Hound: THE FINAL BREATH HAS COME FOR YOU!",
    "Dead Hound: BOW BEFORE YOUR ANNIHILATION!",
    "Dead Hound: NOTHING WILL REMAIN BUT SILENCE!",
    "Dead Hound: I AM THE CATACLYSM INCARNATE!",
    "Dead Hound: WITNESS YOUR DOOM, MORTALS!",
    "Dead Hound: THE GRAVEYARD WILL BE YOUR NEW HOME!",
    "Dead Hound: SCREAM FOR ME... NO ONE WILL HEAR YOU!",
}
function ENT:CustomOnInitialize()
    self.StunSoundPlayed = false

	self:SetCollisionBounds(Vector(13, 13, 50), Vector(-13, -13, 0))
    self:SetModelScale(1.9)
	if not self.Phase2 then
		self.HasLeapAttack = false
		self:SetColor(Color(90, 90, 90))
	else
		self.HasLeapAttack = true
		self:SetColor(Color(15, 15, 15))
	end

	local id = self:GetCreationID()
		timer.Create("Horde_DHAura" .. id, 0.5, 0, function()
			if !IsValid(self) then timer.Remove("Horde_DHAura" .. id) return end
			if self.Phase2 and not self.Phase3 then
				for _, ent in pairs(ents.FindInSphere(self:GetPos(), 150)) do
					if HORDE:IsPlayerOrMinion(ent) then
						local dmg = DamageInfo()
						dmg:SetAttacker(self)
						dmg:SetInflictor(self)
						dmg:SetDamageType(DMG_GENERIC)
						dmg:SetDamage(1)
						dmg:SetDamagePosition(self:GetPos())
						ent:TakeDamageInfo(dmg)
						ent:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 3, self)
						ent:Horde_AddDebuffBuildup(HORDE.Status_Deafenation, 7, self)
					end
				end
			end
			for _, ent in pairs(ents.FindInSphere(self:GetPos(), 50)) do
				if HORDE:IsPlayerOrMinion(ent) then
					local dmg = DamageInfo()
					dmg:SetAttacker(self)
					dmg:SetInflictor(self)
					dmg:SetDamageType(DMG_GENERIC)
					dmg:SetDamage(2)
					dmg:SetDamagePosition(self:GetPos())
					ent:TakeDamageInfo(dmg)
					ent:Horde_AddDebuffBuildup(HORDE.Status_Necrosis, 3, self)
					ent:Horde_AddDebuffBuildup(HORDE.Status_Deafenation, 3, self)
				end
			end
		end)
	self:SetPlaybackRate(0.7)
	self:SetMoveVelocity(self:GetMoveVelocity() * 2)
    self:StartRageTimer()

    self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")

	local mat = Material("models/horde/lesion/lesion_sheet", "mips smooth")
    self:SetSubMaterial(0, "models/horde/lesion/lesion_sheet")
end

function ENT:TranslateActivity(act)
    if act == ACT_WALK or act == ACT_RUN then
		if self.Raging or self.Raged or self.Enraging or self.Phase2 then
			return ACT_RUN
        else
			return ACT_WALK
		end
    end
    return self.BaseClass.TranslateActivity(self, act)
end

function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
    if self.Finisher then
        dmginfo:ScaleDamage(0)
        return
    end

    local damageMultipliers = {
        [0] = { meleeFire = 1.25, cold = 0.55, other = 0.9 },
        [1] = { meleeFire = 1.0,  cold = 0.3,  other = 0.65 },
        [2] = { meleeFire = 0.75,  cold = 0.1, other = 0.3 },
    }

    local phase = self.Quotes or 0

    if HORDE:IsMeleeDamage(dmginfo) or HORDE:IsFireDamage(dmginfo) then
        dmginfo:ScaleDamage(damageMultipliers[phase].meleeFire)
    elseif HORDE:IsColdDamage(dmginfo) then
        dmginfo:ScaleDamage(damageMultipliers[phase].cold)
    else
        dmginfo:ScaleDamage(damageMultipliers[phase].other)
    end
end

function ENT:CustomOnMeleeAttack_AfterChecks(hitEnt, isProp)
    if isProp then return end
    if hitEnt and IsValid(hitEnt) and hitEnt:IsPlayer() then
		if self.Raged then
			self:UnRage()
		end
        hitEnt:Horde_AddDebuffBuildup(HORDE.Status_Necrosis, 15, self)
        hitEnt:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 25, self)
    end
end

function ENT:CustomOnLeapAttack_BeforeChecks(hitEnt, isProp)
    self:EmitSound("horde/lesion/lesion_leap.ogg")
end

function ENT:CustomOnLeapAttack_AfterChecks(hitEnt, isProp)
    if isProp then return end
    if not self.Raged and not self.Phase2 then return end
    if hitEnt and IsValid(hitEnt) and (HORDE:IsPlayerOrMinion(hitEnt) == true) then
        if not self.Phase3 then
            self:UnRage()
        end
        hitEnt:Horde_AddDebuffBuildup(HORDE.Status_Necrosis, 25, self)
        hitEnt:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 45, self)
    end
end

function ENT:CustomOnTakeDamage_AfterDamage(dmginfo, hitgroup)
	local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() then
        self.LastAttacker = attacker
    end

    local maxHealth = self:GetMaxHealth()
    local damage = dmginfo:GetDamage()
    local damagePercent = (damage / maxHealth) * 100

    self.DamageAccumulator = self.DamageAccumulator + damagePercent
    self.RageDamageAccumulator = self.RageDamageAccumulator + damagePercent

    if self.Horde_Stunned then return end

    if self:Health() <= 1 then
        self:HandleDeath()
        return
    end

    if not self.Phase2 and not self.Phase3 and not self.Enraging then
        if self.DamageAccumulator >= 40 then
            timer.Simple(0.01, function()
                if IsValid(self) and not self.Horde_Stunned and not self.Phase2 then
                    self:HandleEnragePhase()
                end
            end)
        end
    end

    if self.Phase2 and not self.Phase3 and not self.Furious then
        if self.DamageAccumulator >= 70 then
            timer.Simple(0.01, function()
                if IsValid(self) and not self.Horde_Stunned and not self.Phase3 then
                    self:HandleFuryPhase()
                end
            end)
        end
    end

    if not self.Raging and not self.Phase3 and not self.Raged and not self.Enraging and not self.Horde_Stunned then
        if self.RageDamageAccumulator >= 15 then
            timer.Simple(0.01, function()
                if IsValid(self) and not self.Horde_Stunned and not self.Phase3 and not self.Furious then
                    self:Rage()
                end
            end)
            self.RageDamageAccumulator = self.RageDamageAccumulator - 15
        end
    end
end

function ENT:UnRage()
    if self.Phase3 then return end

    self.Raging = nil
    self.Raged = nil

    if self.Phase2 then
        self.HasLeapAttack = true
        self:SetColor(Color(15,15,15))
    else
        self.HasLeapAttack = false
        self:SetColor(Color(90,90,90))
    end

    self:StartRageTimer()
end

function ENT:Rage()
    if self.Raging or self.Raged or self.Enraging then return end
    self.Raging = true
	for i = 1, 3 do
		sound.Play("horde/dead_hound/dh_rage.mp3", self:GetPos(), 100, 80)
	end
    self:VJ_ACT_PLAYACTIVITY("BR2_Roar", true, 1.7, false)
	for i = 0.2, 1.4, 0.2 do
		self:RageEffect(i)
	end
    timer.Simple(1.7, function ()
        if not IsValid(self) then return end
		if not self.Phase2 then
			self.HasLeapAttack = true
			self.Raged = true
			self:SetColor(Color(45, 45, 45))
		else
			self.HasLeapAttack = true
			self:SetColor(Color(15, 15, 15))
        end
		self.Raging = false
    end)
end

function ENT:Enrage()
	if self.Enraging then return end
	self.Enraging = true

    for i = 1, 3 do sound.Play("npc/strider/charging.wav", self:GetPos(), 150, 75) end

    for i = 1, 10 do
        timer.Simple(0.1 * i, function()
            if IsValid(self) then
                self:StopMoving()
            end
        end)
    end

	timer.Simple(1.0, function()
		if not IsValid(self) then return end
		for i = 1, 3 do
			sound.Play("npc/stalker/go_alert2.wav", self:GetPos(), 150, 50)
			sound.Play("ambient/creatures/town_zombie_call1.wav", self:GetPos(), 150, 80)
		end
		self:EnrageEffect(1.7)

        self:VJ_ACT_PLAYACTIVITY("BR2_Roar", true, 1.7, false)

        timer.Simple(1.7, function()
            if not IsValid(self) then return end
            self.HasLeapAttack = true
            self.Phase2 = true
            self:SetNWBool("Phase2", true)
            self.Enraging = false
            self:SetColor(Color(15, 15, 15))
        end)
	end)
end

function ENT:Fury()
    if self.Furious or self.Phase3 then return end

    self.Furious = true

    self:VJ_ACT_PLAYACTIVITY("BR2_Roar", true, 1.7, false)

	for i = 1, 5 do
		sound.Play("horde/dead_hound/dh_phase3.mp3", self:GetPos(), 150, 50)
	end

    timer.Simple(1.3, function()
        if not IsValid(self) then return end

        self.Phase3 = true
        self:SetNWBool("Phase3", true)
        self.HasLeapAttack = true
        self.Furious = false
        self.NextLeapAttackTime = 4
        self.LeapDistance = 200

        self:SetPlaybackRate(1.0)
        self:SetColor(Color(0, 0, 0))

        self:StartFuryDebuffAura()
    end)

end

function ENT:RageEffect(delay)
	if self.Horde_Stunned then return end
	timer.Simple(delay, function()
		if not self:IsValid() then return end
		local dmg = DamageInfo()
		dmg:SetAttacker(self)
		dmg:SetInflictor(self)
		dmg:SetDamageType(DMG_GENERIC)
		dmg:SetDamage(5)
		util.BlastDamageInfo(dmg, self:GetPos(), 450)

		if self.Phase2 then
			for _, ent in pairs(ents.FindInSphere(self:GetPos(), 275)) do
				if ent:IsPlayer() then
					ent:Horde_AddDebuffBuildup(HORDE.Status_Deafenation, 9, self)
				end
			end
		end

		for _, ent in pairs(ents.FindInSphere(self:GetPos(), 450)) do
			if ent:IsPlayer() then
				ent:Horde_AddDebuffBuildup(HORDE.Status_Necrosis, 1, self)
				ent:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 6, self)
			end
		end
		local e = EffectData()
			e:SetOrigin(self:GetPos())
		util.Effect("dead_hound_rage", e, true, true)
	end)
end

function ENT:EnrageEffect(delay)
    if self.Horde_Stunned then return end
    timer.Simple(delay, function()
        if not self:IsValid() then return end

        local chaosDamage = {10, 10, 15, 15}

        for chaos = 0, 3 do
            local radius = 700 - (chaos * 150)

            for _, ent in pairs(ents.FindInSphere(self:GetPos(), radius)) do
                if ent == self then continue end

                if HORDE:IsPlayerOrMinion(ent) then
                    if chaos > 1 then
                        ent:Horde_AddDebuffBuildup(HORDE.Status_Deafenation, 70, self)
                    end
                    if chaos > 0 then
                        ent:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 40, self)
                    end
                    ent:Horde_AddDebuffBuildup(HORDE.Status_Necrosis, 15, self)

                    local dmg = DamageInfo()
                    dmg:SetAttacker(self)
                    dmg:SetInflictor(self)
                    dmg:SetDamageType(DMG_GENERIC)
                    dmg:SetDamage(chaosDamage[chaos + 1])
                    dmg:SetDamagePosition(ent:GetPos())
                    ent:TakeDamageInfo(dmg)
                end
            end

            local e = EffectData()
            e:SetOrigin(self:GetPos())
            util.Effect("dead_hound_enrage", e, true, true)
        end
    end)
end

function ENT:HandleEnragePhase()
    if self.Phase2 or self.Phase3 or self.Enraging then return end

    self:UnRage()
    self:Enrage()
    self:SetPlaybackRate(0.8)

    self.RageDamageAccumulator = 0

    local enrageMsg = enragePhrases[math.random(1, #enragePhrases)]
    PrintMessage(HUD_PRINTTALK, enrageMsg)

    self.Quotes = 1
end

function ENT:HandleFuryPhase()
    if self.Phase3 or self.Furious then return end
    if not self.Phase2 then return end

    local id = self:GetCreationID()
    timer.Remove("Horde_FlayerRage" .. id)

    if self.Raging then
        self.Raging = nil
    end

    self:Fury()

    local furyMsg = furyPhrases[math.random(1, #furyPhrases)]
    PrintMessage(HUD_PRINTTALK, furyMsg)

    self.Quotes = 2
end

function ENT:StartFuryDebuffAura()
    local id = self:GetCreationID()
    timer.Create("Horde_FuryDebuff" .. id, 0.3, 0, function()
        if not IsValid(self) or not self.Phase3 then
            timer.Remove("Horde_FuryDebuff" .. id)
            return
        end

        for _, ent in pairs(ents.FindInSphere(self:GetPos(), 400)) do
            if HORDE:IsPlayerOrMinion(ent) then
                ent:Horde_AddDebuffBuildup(HORDE.Status_Deafenation, 3, self)
                ent:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 2, self)
            end
        end
    end)
end

function ENT:HandleDeath()
    if self.DeathHandled then return end
    self.DeathHandled = true

    self.Finisher = true
    self:SetHealth(1)

    local killer = self.LastAttacker

    for i = 1, 3 do
        sound.Play("npc/zombie_poison/pz_alert1.wav", self:GetPos(), 100, 75)
    end
    self:VJ_ACT_PLAYACTIVITY("BR2_Roar", true, 2, false)

    local deathMsg = defeatPhrases[math.random(1, #defeatPhrases)]
    PrintMessage(HUD_PRINTTALK, deathMsg)
    ParticleEffect("dh_death", self:GetPos() + Vector(0, 0, 15), Angle(0, 0, 0))

    timer.Simple(2, function()
        if not IsValid(self) then return end

        self:SetNoDraw(true)

        if IsValid(killer) and killer:IsPlayer() then
            self.Finisher = false
            local dmgInfo = DamageInfo()
            dmgInfo:SetAttacker(killer)
            dmgInfo:SetInflictor(self)
            dmgInfo:SetDamage(10000)
            dmgInfo:SetDamageType(DMG_GENERIC + DMG_REMOVENORAGDOLL)
            self:TakeDamageInfo(dmgInfo)
            self.Finisher = true
        end

        local explodeSounds = {"weapons/mortar/mortar_explode1.wav", "weapons/mortar/mortar_explode2.wav", "weapons/mortar/mortar_explode3.wav"}
        local sngch = math.random(1, 3)
        for i = 1, 3 do
            sound.Play(explodeSounds[sngch], self:GetPos(), 100, 50)
        end

        self:Remove()
    end)
end

function ENT:StartRageTimer()
    local id = self:GetCreationID()
    timer.Remove("Horde_FlayerRage" .. id)

    if self.Phase3 then return end

    timer.Create("Horde_FlayerRage" .. id, 15, 1, function()
        if not IsValid(self) then return end
        if self.Phase3 then return end
        if self.Raging or self.Raged then return end
        self:Rage()
    end)
end

local meta = FindMetaTable("Entity")

local oldAddStun = meta.Horde_AddStun
local oldSetStunned = meta.SetHorde_Stunned

function meta:Horde_AddStun(duration)
    if self:GetClass() == "npc_vj_horde_dead_hound" then
        local phase2 = self:GetNWBool("Phase2", false) or self.Phase2
        local phase3 = self:GetNWBool("Phase3", false) or self.Phase3
        local currentTime = CurTime()

        if phase2 or phase3 then
            if currentTime - (self.LastStunPhraseTime or 0) >= 10 then
                self.LastStunPhraseTime = currentTime
                local immunePhrases = {
                    "Dead Hound: You cannot stop me now!",
                    "Dead Hound: Your stun is useless against my rage!",
                    "Dead Hound: I've evolved beyond your tricks!",
                    "Dead Hound: Feel my power, weakling!",
                    "Dead Hound: This form is immune to your pathetic gadgets!",
                }
                PrintMessage(HUD_PRINTTALK, immunePhrases[math.random(1, #immunePhrases)])
            end
            return
        end

        if self.LastStunAttempt and currentTime - self.LastStunAttempt < 25 then
            if currentTime - (self.LastStunPhraseTime or 0) >= 10 then
                self.LastStunPhraseTime = currentTime
                local cooldownPhrases = {
                    "Dead Hound: You think you can stun me that often? Pathetic.",
                    "Dead Hound: Nice try, but I'm ready for you.",
                    "Dead Hound: Your petty tricks won't work twice.",
                    "Dead Hound: Did you really think that would work again?",
                    "Dead Hound: You're wasting your grenades, fool.",
                    "Dead Hound: I'm still standing, in case you haven't noticed.",
                }
                PrintMessage(HUD_PRINTTALK, cooldownPhrases[math.random(1, #cooldownPhrases)])
            end
            return
        end

        self.LastStunAttempt = currentTime

        self:StopSound("horde/dead_hound/dh_stunned.mp3")
        self:StopSound("horde/status/shock_trigger.ogg")

        for i = 1, 3 do
            sound.Play("horde/dead_hound/dh_stunned.mp3", self:GetPos(), 150, 100)
            sound.Play("horde/status/shock_trigger.ogg", self:GetPos(), 150, 100)
        end

        ParticleEffectAttach("dh_stunned", PATTACH_ABSORIGIN_FOLLOW, self, 0)

        if self.Raged then
            self:UnRage()
        end
        self.Raging = nil
        self.Raged = nil
    end
    return oldAddStun(self, duration)
end

function meta:SetHorde_Stunned(value)
    if self:GetClass() == "npc_vj_horde_dead_hound" then
        local phase2 = self:GetNWBool("Phase2", false) or self.Phase2
        local phase3 = self:GetNWBool("Phase3", false) or self.Phase3


        if (phase2 or phase3) and value == true then
            return
        end
    end
    return oldSetStunned(self, value)
end

VJ.AddNPC("Dead Hound","npc_vj_horde_dead_hound", "Zombies")
