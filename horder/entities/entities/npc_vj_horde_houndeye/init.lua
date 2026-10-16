AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = {"models/hl2beta/houndeye.mdl"}
ENT.StartHealth = 200
ENT.SightDistance = 8000
ENT.HullType = HULL_TINY
ENT.PlayerFriendly = true
ENT.VJ_NPC_Class = {"CLASS_PLAYER_ALLY", "CLASS_COMBINE"}
ENT.FriendlyMinion = true
ENT.BloodColor = "Yellow"
ENT.Immune_Sonic = true
ENT.Immune_Electricity = true
ENT.Immune_AcidPoisonRadiation = true
ENT.Immune_Blast = false
ENT.Horde_Immune_Status_All = true

ENT.HasMeleeAttack = true
ENT.AnimTbl_MeleeAttack = {ACT_RANGE_ATTACK1}
ENT.MeleeAttackDistance = 194
ENT.MeleeAttackDamageDistance = 300
ENT.TimeUntilMeleeAttackDamage = 2.15
ENT.MeleeAttackDamage = 75
ENT.MeleeAttackDamageType = DMG_SONIC
ENT.MeleeAttackDSPSoundType = 34
ENT.MeleeAttackDSPSoundUseDamage = false
ENT.DisableDefaultMeleeAttackDamageCode = true

ENT.HasMeleeAttackKnockBack = true
ENT.MeleeAttackKnockBack_Forward1 = 512
ENT.MeleeAttackKnockBack_Forward2 = 768
ENT.MeleeAttackKnockBack_Up1 = 20
ENT.MeleeAttackKnockBack_Up2 = 20
ENT.MeleeAttackKnockBack_Right1 = 0
ENT.MeleeAttackKnockBack_Right2 = 0

ENT.HasDeathAnimation = true
ENT.AnimTbl_Death = {ACT_DIESIMPLE}
ENT.DeathAnimationChance = 2
ENT.PushProps = false
ENT.AttackProps = false
ENT.FootStepTimeRun = 0.3
ENT.FootStepTimeWalk = 1
ENT.AnimTbl_IdleStand = {ACT_IDLE, "leaderlook"}
ENT.CanFlinch = 2
ENT.FlinchChance = 1
ENT.AnimTbl_Flinch = {ACT_SMALL_FLINCH}

ENT.SoundTbl_FootStep = {"hl2beta_houndeye/he_step1.wav","hl2beta_houndeye/he_step2.wav","hl2beta_houndeye/he_step3.wav"}
ENT.SoundTbl_Idle = {"hl2beta_houndeye/he_idle1.wav","hl2beta_houndeye/he_idle2.wav","hl2beta_houndeye/he_idle3.wav","hl2beta_houndeye/he_idle4.wav"}
ENT.SoundTbl_Alert = {"hl2beta_houndeye/he_alert1.wav","hl2beta_houndeye/he_alert2.wav","hl2beta_houndeye/he_alert3.wav"}
ENT.SoundTbl_BeforeMeleeAttack = {"hl2beta_houndeye/he_attack1.wav","hl2beta_houndeye/he_attack2.wav"}
ENT.SoundTbl_Pain = {"hl2beta_houndeye/he_pain1.wav","hl2beta_houndeye/he_pain2.wav","hl2beta_houndeye/he_pain3.wav","hl2beta_houndeye/he_pain4.wav","hl2beta_houndeye/he_pain5.wav"}
ENT.SoundTbl_Death = {"hl2beta_houndeye/he_die1.wav","hl2beta_houndeye/he_die2.wav","hl2beta_houndeye/he_die3.wav"}

ENT.MainSoundPitch = 100
ENT.MainSoundPitchStatic = true
ENT.GeneralSoundPitch1 = 100
ENT.GeneralSoundPitch2 = 100
ENT.IdleSoundPitch1 = 100
ENT.IdleSoundPitch2 = 100
ENT.AlertSoundPitch1 = 100
ENT.AlertSoundPitch2 = 100
ENT.EnemyTalkSoundPitch1 = 100
ENT.EnemyTalkSoundPitch2 = 100
ENT.BeforeMeleeAttackSoundPitch1 = 100
ENT.BeforeMeleeAttackSoundPitch2 = 100
ENT.MeleeAttackSoundPitch1 = 100
ENT.MeleeAttackSoundPitch2 = 100
ENT.ExtraMeleeSoundPitch1 = 100
ENT.ExtraMeleeSoundPitch2 = 100
ENT.MeleeAttackMissSoundPitch1 = 100
ENT.MeleeAttackMissSoundPitch2 = 100
ENT.PainSoundPitch1 = 100
ENT.PainSoundPitch2 = 100
ENT.DeathSoundPitch1 = 100
ENT.DeathSoundPitch2 = 100
ENT.GrenadeSoundPitch1 = 100
ENT.GrenadeSoundPitch2 = 100
ENT.SawPlayerPitch1 = 100
ENT.SawPlayerPitch2 = 100
ENT.StupidPlayerPitch1 = 100
ENT.StupidPlayerPitch2 = 100
ENT.FollowPlayerPitch1 = 100
ENT.FollowPlayerPitch2 = 100
ENT.UnFollowPlayerPitch1 = 100
ENT.UnFollowPlayerPitch2 = 100
ENT.BecomeEnemyToPlayerPitch1 = 100
ENT.BecomeEnemyToPlayerPitch2 = 100
ENT.GrenadeAttackSoundPitch1 = 100
ENT.GrenadeAttackSoundPitch2 = 100
ENT.OnGrenadeSightSoundPitch1 = 100
ENT.OnGrenadeSightSoundPitch2 = 100

function ENT:CustomOnInitialize()
    self:SetCollisionBounds(Vector(16, 16, 35), Vector(-16, -16, 0))
    self:SetCollisionGroup(COLLISION_GROUP_NPC_ACTOR)
    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) then
            self:SetNWEntity("HordeOwner", owner)
            self.Horde_Owner = owner
            self.Horde_Owner = self:GetNWEntity("HordeOwner")
            HORDE:FriendlyAlly(self)
        end
    end
end
function ENT:CustomOnAlert()
	if self.VJ_IsBeingControlled == true then return end
	self:VJ_ACT_PLAYACTIVITY({"madidle","madidle3"},true,1,true)
end
function ENT:CustomOnThink()
	if IsValid(self:GetEnemy()) then
		self.AnimTbl_IdleStand = {ACT_IDLE_ANGRY}
		if self:IsMoving() then
			if timer.TimeLeft( "hunt"..self:EntIndex() ) == nil and math.random() < 0.5 then
				VJ_EmitSound(self,"hl2beta_houndeye/he_hunt"..math.random(1,4)..".wav",75,math.random(95,105))
				timer.Create( "hunt"..self:EntIndex(), 0.5, 1, function() end )
			end
		end
	else
		self.AnimTbl_IdleStand = {ACT_IDLE,"leaderlook"}
	end
end
function ENT:CustomOnMeleeAttack_BeforeChecks()
	effects.BeamRingPoint(self:GetPos() + Vector(0,0,16), 0.3, 2, 400, 16, 0, Color(188, 220, 255), {material="sprites/vj_bms_shockwave", framerate=20})
	effects.BeamRingPoint(self:GetPos() + Vector(0,0,16), 0.3, 2, 200, 16, 0, Color(188, 220, 255), {material="sprites/vj_bms_shockwave", framerate=20})

	if self.HasSounds == true && GetConVarNumber("vj_npc_sd_meleeattack") == 0 then
		VJ_EmitSound(self,"hl2beta_houndeye/he_blast"..math.random(1,3)..".wav",100,math.random(95,105))
	end

	util.VJ_SphereDamage(self, self, self:GetPos() + Vector(0,0,16), 350, self.MeleeAttackDamage*2, self.MeleeAttackDamageType, true, true, {DisableVisibilityCheck=true, Force=80})
end
function ENT:CustomDeathAnimationCode(dmginfo,hitgroup)
	self:SetLocalPos(Vector(self:GetPos().x,self:GetPos().y,self:GetPos().z +5))
end

function ENT:CustomOnKilled(dmginfo, hitgroup)
    if not SERVER then return end

    if self.Horde_PocketHoundeye then return end

    local owner = self:GetNWEntity("HordeOwner")

    if not IsValid(owner) then
        owner = self:GetOwner()
    end

    if IsValid(owner) and owner:IsPlayer() then
        if owner.Horde_GetPerk and owner:Horde_GetPerk("sapper_mutation") then

            if math.random(1, 3) == 1 then
                local pos = self:GetPos()

                local explode = ents.Create("env_explosion")
                if IsValid(explode) then
                    explode:SetPos(pos)
                    explode:SetOwner(owner)
                    explode:Spawn()
                    explode:SetKeyValue("iMagnitude", "150")
                    explode:SetKeyValue("iRadiusOverride", "250")
                    explode:Fire("Explode", 0, 0)

                end
            end
        end
    end
end

VJ.AddNPC("Houndeye","npc_vj_horde_houndeye", "HORDE: Sapper")
ENT.Horde_TurretMinion = true
