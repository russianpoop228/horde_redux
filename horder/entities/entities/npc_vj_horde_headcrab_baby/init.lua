AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = {"models/horde/gonarch/headcrab_baby.mdl"}
ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.TurningSpeed = 60
ENT.EntitiesToNoCollide = {"npc_vj_horde_xen_host_unit"}
ENT.StartHealth = 1
ENT.LeapDistance = 100
ENT.NoChaseAfterCertainRange_FarDistance = 150
ENT.LeapAttackVelocityForward = 100
ENT.LeapAttackVelocityUp = 150
ENT.NextLeapAttackTime = 5
ENT.NextAnyAttackTime_Leap = 1
ENT.HasMeleeAttack = true
ENT.MeleeAttackDamage = 1
ENT.HasLeapAttack = true
ENT.LeapAttackDamage = 1

ENT.GeneralSoundPitch1 = 120
ENT.GeneralSoundPitch2 = 120

ENT.BabH_Mother = NULL
function ENT:CustomOnInitialize()
	self:SetCollisionBounds(Vector(5, 5, 10), Vector(-5, -5, 0))
end
function ENT:CustomOnAlert(ent)
end
function ENT:CustomOnPriorToKilled(dmginfo, hitgroup)
	if IsValid(self.BabH_Mother) then
		self.BabH_Mother:Gonarch_BabyDeath()
	end
end

function ENT:BecomeFriendlyToPlayers()
	HORDE:FriendlyAlly(self)
end

VJ.AddNPC("Headcrab Baby","npc_vj_horde_headcrab_baby", "Horde")
