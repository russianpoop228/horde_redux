AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = "models/combine_soldier_prisonguard.mdl"
ENT.StartHealth = 125
ENT.VJ_NPC_Class = { "CLASS_COMBINE", "CLASS_PLAYER_ALLY" }
ENT.FriendlyMinion = true
ENT.MeleeAttackDamage = 30
ENT.MoveType = MOVETYPE_STEP
ENT.HullType = HULL_HUMAN
ENT.SightDistance = 10000
ENT.SightAngle = 180
ENT.TurningSpeed = 20
ENT.Bleeds = true
ENT.BloodColor =
"Red"
ENT.HasBloodParticle = true
ENT.HasBloodDecal = true
ENT.HasBloodPool = false
ENT.Flinches = 0
ENT.FlinchingChance = 12
ENT.FlinchingSchedules = { SCHED_FLINCH_PHYSICS }
ENT.MoveWhenDamagedByEnemy = false
ENT.MoveWhenDamagedByEnemySCHED1 =
	SCHED_FORCED_GO_RUN
ENT.MoveWhenDamagedByEnemySCHED2 =
	SCHED_FORCED_GO_RUN
ENT.NextMoveWhenDamagedByEnemy1 = 3
ENT.NextMoveWhenDamagedByEnemy2 = 3.5
ENT.HasAllies = true
ENT.HasMeleeAttack = false
ENT.HasGrenadeAttack = false
ENT.NextThrowGrenadeTime1 = 10
ENT.NextThrowGrenadeTime2 = 15
ENT.ThrowGrenadeChance = 1
ENT.GrenadeAttackThrowDistance = 500
ENT.GrenadeAttackThrowDistanceClose = 0
ENT.AnimTbl_GrenadeAttack = { "grenThrow" }
ENT.GrenadeAttackAnimationDelay = 0
ENT.GrenadeAttackAnimationStopAttacks = false
ENT.GrenadeAttackEntity =
"npc_grenade_frag"
ENT.FootStepTimeRun = 0.3
ENT.FootStepTimeWalk = 0.5
ENT.CallForBackUpOnDamage = false
ENT.CanDetectDangers = false
ENT.MoveOrHideOnDamageByEnemy = false
ENT.WeaponSpread = 0.5
ENT.CallForHelp = false
ENT.CanInvestigate = false
ENT.PlayerFriendly = true
ENT.CanShootWhenMoving = true
ENT.ConstantlyFaceEnemy = true

ENT.HasItemDropsOnDeath = false
ENT.DropWeaponOnDeath = false

ENT.SoundTbl_FootStep = {
	"npc/combine_soldier/gear1.wav",
	"npc/combine_soldier/gear2.wav",
	"npc/combine_soldier/gear3.wav",
	"npc/combine_soldier/gear4.wav",
	"npc/combine_soldier/gear5.wav",
	"npc/combine_soldier/gear6.wav" }

ENT.UseTheSameGeneralSoundPitch = true
ENT.GeneralSoundPitch1 = 75
ENT.GeneralSoundPitch2 = 75

function ENT:CustomOnInitialize()
    self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
    if self.Is_Reinforcements then
        self:SetMaxHealth(self.StartHealth * 0.5)
		self:SetHealth(self:GetMaxHealth())
    end
    local ply = self:GetOwner()
    if IsValid(ply) and ply:IsPlayer() and ply:Horde_GetGadget() == "gadget_shotgun_surgeon" then
        self:SetSkin(1)
    end
    self:Give("weapon_vj_horde_projection_shotgun")
    self:SetNPCState(NPC_STATE_COMBAT)
    self:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_PERFECT)
    self.Horde_Immune_Status_All = true
    self:Horde_AddOverlordPresence()

    timer.Simple(self.Horde_Projection_Lifetime or 15, function()
        if not self:IsValid() then return end
        self:NextThink(CurTime() + 2)
        self:DankRemove()
    end)
end

function ENT:DankRemove()
    self:NextThink(CurTime() + 2)
    timer.Simple(1, function()
        if not self:IsValid() then return end
        self:Remove()
    end)
end

VJ.AddNPC("Projection", "npc_vj_horde_overlord_projection", "Zombies")
