AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model       = {"models/hl2beta/hound_bl.mdl"}
ENT.StartHealth = 400
ENT.SightDistance = 8000
ENT.HullType    = HULL_TINY
ENT.PlayerFriendly = true
ENT.VJ_NPC_Class = {"CLASS_PLAYER_ALLY", "CLASS_COMBINE"}
ENT.FriendlyMinion = true
ENT.BloodColor   = "Yellow"
ENT.Immune_Sonic              = true
ENT.Immune_Electricity        = true
ENT.Immune_AcidPoisonRadiation = true
ENT.Immune_Blast              = false
ENT.Horde_Immune_Status_All   = true

ENT.HasMeleeAttack                   = true
ENT.AnimTbl_MeleeAttack              = {ACT_RANGE_ATTACK1}
ENT.MeleeAttackDistance              = 194
ENT.MeleeAttackDamageDistance        = 300
ENT.TimeUntilMeleeAttackDamage       = 2.15
ENT.MeleeAttackDamage                = 140
ENT.MeleeAttackDamageType            = DMG_SONIC
ENT.MeleeAttackDSPSoundType          = 34
ENT.MeleeAttackDSPSoundUseDamage     = false
ENT.DisableDefaultMeleeAttackDamageCode = true

ENT.HasMeleeAttackKnockBack          = true
ENT.MeleeAttackKnockBack_Forward1    = 512
ENT.MeleeAttackKnockBack_Forward2    = 768
ENT.MeleeAttackKnockBack_Up1         = 20
ENT.MeleeAttackKnockBack_Up2         = 20
ENT.MeleeAttackKnockBack_Right1      = 0
ENT.MeleeAttackKnockBack_Right2      = 0

ENT.HasDeathAnimation   = true
ENT.AnimTbl_Death       = {ACT_DIESIMPLE}
ENT.DeathAnimationChance = 2
ENT.PushProps           = false
ENT.AttackProps         = false
ENT.FootStepTimeRun     = 0.3
ENT.FootStepTimeWalk    = 1
ENT.AnimTbl_IdleStand   = {ACT_IDLE, "leaderlook"}
ENT.CanFlinch           = 2
ENT.FlinchChance        = 1
ENT.AnimTbl_Flinch      = {ACT_SMALL_FLINCH}

ENT.SoundTbl_FootStep         = {"hl2beta_houndeye/he_step1.wav","hl2beta_houndeye/he_step2.wav","hl2beta_houndeye/he_step3.wav"}
ENT.SoundTbl_Idle             = {"hl2beta_houndeye/he_idle1.wav","hl2beta_houndeye/he_idle2.wav","hl2beta_houndeye/he_idle3.wav","hl2beta_houndeye/he_idle4.wav"}
ENT.SoundTbl_Alert            = {"hl2beta_houndeye/he_alert1.wav","hl2beta_houndeye/he_alert2.wav","hl2beta_houndeye/he_alert3.wav"}
ENT.SoundTbl_BeforeMeleeAttack = {"hl2beta_houndeye/he_attack1.wav","hl2beta_houndeye/he_attack2.wav"}
ENT.SoundTbl_Pain             = {"hl2beta_houndeye/he_pain1.wav","hl2beta_houndeye/he_pain2.wav","hl2beta_houndeye/he_pain3.wav","hl2beta_houndeye/he_pain4.wav","hl2beta_houndeye/he_pain5.wav"}
ENT.SoundTbl_Death            = {"hl2beta_houndeye/he_die1.wav","hl2beta_houndeye/he_die2.wav","hl2beta_houndeye/he_die3.wav"}

local _p = 100
ENT.MainSoundPitch = _p    ENT.MainSoundPitchStatic = true
ENT.GeneralSoundPitch1 = _p    ENT.GeneralSoundPitch2 = _p
ENT.IdleSoundPitch1 = _p       ENT.IdleSoundPitch2 = _p
ENT.AlertSoundPitch1 = _p      ENT.AlertSoundPitch2 = _p
ENT.EnemyTalkSoundPitch1 = _p  ENT.EnemyTalkSoundPitch2 = _p
ENT.BeforeMeleeAttackSoundPitch1 = _p  ENT.BeforeMeleeAttackSoundPitch2 = _p
ENT.MeleeAttackSoundPitch1 = _p        ENT.MeleeAttackSoundPitch2 = _p
ENT.ExtraMeleeSoundPitch1 = _p         ENT.ExtraMeleeSoundPitch2 = _p
ENT.MeleeAttackMissSoundPitch1 = _p    ENT.MeleeAttackMissSoundPitch2 = _p
ENT.PainSoundPitch1 = _p   ENT.PainSoundPitch2 = _p
ENT.DeathSoundPitch1 = _p  ENT.DeathSoundPitch2 = _p
ENT.GrenadeSoundPitch1 = _p    ENT.GrenadeSoundPitch2 = _p
ENT.SawPlayerPitch1 = _p       ENT.SawPlayerPitch2 = _p
ENT.StupidPlayerPitch1 = _p    ENT.StupidPlayerPitch2 = _p
ENT.FollowPlayerPitch1 = _p    ENT.FollowPlayerPitch2 = _p
ENT.UnFollowPlayerPitch1 = _p  ENT.UnFollowPlayerPitch2 = _p
ENT.BecomeEnemyToPlayerPitch1 = _p   ENT.BecomeEnemyToPlayerPitch2 = _p
ENT.GrenadeAttackSoundPitch1 = _p    ENT.GrenadeAttackSoundPitch2 = _p
ENT.OnGrenadeSightSoundPitch1 = _p   ENT.OnGrenadeSightSoundPitch2 = _p

function ENT:CustomOnInitialize()
    self:SetModelScale(1.5, 0)

    self:SetColor(Color(255, 80, 80, 255))
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)

    self:SetCollisionBounds(Vector(24, 24, 53), Vector(-24, -24, 0))
    self:SetCollisionGroup(COLLISION_GROUP_NPC_ACTOR)

    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) then
            self:SetNWEntity("HordeOwner", owner)
            self.Horde_Owner = owner
            HORDE:FriendlyAlly(self)
        end
    end
end

function ENT:CustomOnAlert()
    if self.VJ_IsBeingControlled == true then return end
    self:VJ_ACT_PLAYACTIVITY({"madidle", "madidle3"}, true, 1, true)
end

function ENT:CustomOnThink()
    if IsValid(self:GetEnemy()) then
        self.AnimTbl_IdleStand = {ACT_IDLE_ANGRY}
        if self:IsMoving() then
            if timer.TimeLeft("hunt_champ" .. self:EntIndex()) == nil and math.random() < 0.5 then
                VJ_EmitSound(self, "hl2beta_houndeye/he_hunt" .. math.random(1, 4) .. ".wav", 80, math.random(95, 105))
                timer.Create("hunt_champ" .. self:EntIndex(), 0.5, 1, function() end)
            end
        end
    else
        self.AnimTbl_IdleStand = {ACT_IDLE, "leaderlook"}
    end
end

function ENT:CustomOnMeleeAttack_BeforeChecks()
    effects.BeamRingPoint(self:GetPos() + Vector(0, 0, 24), 0.3, 2, 550, 16, 0, Color(255, 120, 120), {material = "sprites/vj_bms_shockwave", framerate = 20})
    effects.BeamRingPoint(self:GetPos() + Vector(0, 0, 24), 0.3, 2, 300, 16, 0, Color(255, 120, 120), {material = "sprites/vj_bms_shockwave", framerate = 20})

    if self.HasSounds == true and GetConVarNumber("vj_npc_sd_meleeattack") == 0 then
        VJ_EmitSound(self, "hl2beta_houndeye/he_blast" .. math.random(1, 3) .. ".wav", 110, math.random(90, 105))
    end

    util.VJ_SphereDamage(self, self, self:GetPos() + Vector(0, 0, 24), 400, self.MeleeAttackDamage * 2, self.MeleeAttackDamageType, true, true, {DisableVisibilityCheck = true, Force = 100})
end

function ENT:CustomDeathAnimationCode(dmginfo, hitgroup)
    self:SetLocalPos(Vector(self:GetPos().x, self:GetPos().y, self:GetPos().z + 5))
end

VJ.AddNPC("Houndeye Champion", "npc_vj_horde_houndeye_champion", "HORDE: Sapper")
ENT.Horde_TurretMinion = true
