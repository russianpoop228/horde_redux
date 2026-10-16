AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = {"models/dog.mdl"}
ENT.StartHealth = 1400
ENT.SightDistance = 8000
ENT.HullType = HULL_HUMAN
ENT.MovementType = VJ_MOVETYPE_GROUND
ENT.DropWeaponOnDeath = false
ENT.SightAngle = 180
ENT.LastSeenEnemyTimeUntilReset = 60
ENT.VJ_NPC_Class = {"CLASS_PLAYER_ALLY", "CLASS_COMBINE"}
ENT.FriendlyMinion = true
ENT.BloodColor = "Oil"
ENT.HasBloodDecal = true
ENT.PlayerFriendly = true
ENT.HasMeleeAttack = true
ENT.DamageByPlayerDispositionLevel = 1
ENT.HasMeleeAttack = true
ENT.MeleeAttackDamage = math.random(180,215)
ENT.MeleeAttackAnimationDelay = 0
ENT.MeleeAttackAnimationFaceEnemy = true
ENT.MeleeAttackAnimationDecreaseLengthAmount = 0
ENT.MeleeAttackDistance = 60
ENT.MeleeAttackAngleRadius = 120
ENT.MeleeAttackDamageDistance = 82
ENT.MeleeAttackDamageAngleRadius = 100
ENT.TimeUntilMeleeAttackDamage = 0.5
ENT.NextAnyAttackTime_Melee = 1.10
ENT.SlowPlayerOnMeleeAttack = true
ENT.SlowPlayerOnMeleeAttack_WalkSpeed = 190
ENT.SlowPlayerOnMeleeAttack_RunSpeed = 390
ENT.SlowPlayerOnMeleeAttackTime = 0
ENT.MeleeAttackBleedEnemy = false
ENT.MeleeAttackBleedEnemyChance = 1
ENT.MeleeAttackBleedEnemyDamage = 1
ENT.MeleeAttackBleedEnemyTime = 1
ENT.MeleeAttackBleedEnemyReps = 5
ENT.MeleeAttackDamageType = DMG_CLUB
ENT.HasMeleeAttackKnockBack = true
ENT.MeleeAttackKnockBack_Forward1 = 100
ENT.MeleeAttackKnockBack_Forward2 = 130
ENT.MeleeAttackKnockBack_Up1 = 250
ENT.MeleeAttackKnockBack_Up2 = 260
ENT.AnimTbl_IdleStand = {ACT_IDLE}
ENT.AnimTbl_Walk = {ACT_WALK}
ENT.AnimTbl_Run = {ACT_RUN}
ENT.AnimTbl_MeleeAttack = {"throw"}
ENT.RunAwayOnUnknownDamage = false
ENT.HasRangeAttack = true
ENT.RangeAttackEntityToSpawn = "obj_vj_horde_boulder"
ENT.AnimTbl_RangeAttack = {"apc_throw"}
ENT.TimeUntilRangeAttackProjectileRelease = 3.8
ENT.RangeAttackPos_Up = 47
ENT.RangeDistance = 2000
ENT.RangeToMeleeDistance = 0
ENT.NextRangeAttackTime = 5
ENT.HasFootStepSound = true
ENT.SoundTbl_FootStep = {"npc/dog/dog_footstep_run1.wav","npc/dog/dog_footstep_run2.wav","npc/dog/dog_footstep_run3.wav","npc/dog/dog_footstep_run4.wav","npc/dog/dog_footstep_run5.wav","npc/dog/dog_footstep_run6.wav","npc/dog/dog_footstep_run7.wav","npc/dog/dog_footstep_run8.wav"}

ENT.Horde_Immune_Status_All = true

ENT.SoundTbl_MeleeAttackSlowPlayer = {}
ENT.SoundTbl_MeleeAttack = {
"npc/dog/dog_angry1.wav",
"npc/dog/dog_angry2.wav",
"npc/dog/dog_angry3.wav",
}
ENT.SoundTbl_MeleeAttackMiss = {
"npc/dog/dog_laugh1.wav",
}
ENT.SoundTbl_CallForHelp = {

}
ENT.SoundTbl_CombatIdle = {
"npc/dog/dog_combatmode_loop1.wav",
"npc/dog/dog_pneumatic1.wav",
"npc/dog/dog_pneumatic2.wav",
}
ENT.SoundTbl_Idle = {
"npc/dog/dog_disappointed.wav",
"npc/dog/dog_idle1.wav",
"npc/dog/dog_idle2.wav",
"npc/dog/dog_idle3.wav",
"npc/dog/dog_idle4.wav",
"npc/dog/dog_idle5.wav",
"npc/dog/dog_playfull1.wav",
"npc/dog/dog_playfull2.wav",
"npc/dog/dog_playfull3.wav",
"npc/dog/dog_playfull4.wav",
"npc/dog/dog_playfull5.wav",

}
ENT.SoundTbl_Pain = {
"npc/dog/dog_growl2.wav",
"npc/dog/dog_growl3.wav",
}

ENT.SoundTbl_Death = {
"npc/dog/dog_scared1.wav",
"npc/dog/dog_on_dropship.wav",
}

ENT.SoundTbl_Alert = {
"npc/dog/dog_alarmed1.wav",
"npc/dog/dog_alarmed3.wav",
}
ENT.CombatIdleSoundPitch1 = 100
ENT.CombatIdleSoundPitch2 = 100
ENT.AlertSoundPitch1 = 100
ENT.AlertSoundPitch2 = 100
ENT.MeleeAttackSoundPitch1 = 100
ENT.MeleeAttackSoundPitch2 = 100
ENT.PainSoundPitch1 = 100
ENT.PainSoundPitch2 = 100
ENT.DeathSoundPitch1 = 100
ENT.DeathSoundPitch2 = 100
ENT.OnKilledEnemySoundPitch1 = 100
ENT.OnKilledEnemySoundPitch2 = 100
ENT.RangeAttackPitch1 = 100
ENT.RangeAttackPitch2 = 100
ENT.Immune_AcidPoisonRadiation = true

local extraSounds = {"physics/concrete/concrete_block_impact_hard1.wav", "physics/concrete/concrete_block_impact_hard2.wav", "physics/concrete/concrete_block_impact_hard3.wav"}

function ENT:CustomOnInitialize()
	self:SetColor(Color(0,150,255))
end

function ENT:CustomOnMeleeAttack_AfterChecks(hitEnt, isProp)
	self:EmitSound(extraSounds[ math.random( #extraSounds ) ], 125, 100, 1, CHAN_AUTO)
	return false
end

function ENT:DoRelationshipCheck(ent)
    if ent:IsPlayer() or ent:GetNWEntity("HordeOwner"):IsValid() then return false end
    return true
end

VJ.AddNPC("Combat Bot","npc_vj_horde_combat_bot", "Horde")
