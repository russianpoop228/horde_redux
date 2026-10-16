AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = {"models/headcrabclassic.mdl"}
ENT.VJ_NPC_Class = {"CLASS_PLAYER_ALLY", "CLASS_COMBINE"}
ENT.FriendlyMinion = true
ENT.TurningSpeed = 60
ENT.StartHealth = 1
ENT.LeapDistance = 100
ENT.NoChaseAfterCertainRange_FarDistance = 150
ENT.LeapAttackVelocityForward = 100
ENT.LeapAttackVelocityUp = 150
ENT.NextLeapAttackTime = 5
ENT.NextAnyAttackTime_Leap = 1
ENT.PlayerFriendly = true
ENT.HasMeleeAttack = false
ENT.MeleeAttackDamage = 1
ENT.HasLeapAttack = true
ENT.LeapAttackDamage = 1

ENT.GeneralSoundPitch1 = 120
ENT.GeneralSoundPitch2 = 120

function ENT:CustomOnInitialize()
	self:SetCollisionBounds(Vector(20, 20, 20), Vector(-20, -20, 0))
end

VJ.AddNPC("Headcrab","npc_vj_horde_headcrab", "Horde")
