AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = {"models/vj_base/projectiles/spit_acid_medium.mdl"}
ENT.ShakeWorldOnDeath = true
ENT.ShakeWorldOnDeathAmplitude = 4
ENT.ShakeWorldOnDeathRadius = 500
ENT.ShakeWorldOnDeathDuration = 1
ENT.ShakeWorldOnDeathFrequency = 200
ENT.DoesRadiusDamage = false
ENT.RadiusDamageRadius = 250
ENT.RadiusDamageUseRealisticRadius = false
ENT.RadiusDamage = 20
ENT.RadiusDamageType = DMG_ACID
ENT.RadiusDamageForce = 200
ENT.RadiusDamageForce_Up = false
ENT.RadiusDamageDisableVisibilityCheck = false
ENT.DecalTbl_DeathDecals = {"VJ_AcidSlime1"}
ENT.SoundTbl_Idle = {"vj_base/ambience/acid_idle.wav"}
ENT.SoundTbl_OnCollide = {"vj_base/ambience/acid_splat.wav"}
function ENT:CustomPhysicsObjectOnInitialize(phys)
	phys:Wake()
	phys:SetMass(1)
	phys:SetBuoyancyRatio(0)
	phys:EnableDrag(false)
end
function ENT:CustomOnInitialize()
	self:SetNoDraw(true)
	self:DrawShadow(false)

	ParticleEffect("xen_host_spit_spawn", self:GetPos(), Angle(0,0,0), nil)
	ParticleEffectAttach("xen_host_spit", PATTACH_ABSORIGIN_FOLLOW, self, 0)
end

function ENT:CustomOnPhysicsCollide(data, phys)
    if self.Dead then return end
    self.Dead = true
    local dmg = DamageInfo()
    if self.Owner:IsValid() then
        dmg:SetAttacker(self.Owner)
    else
        dmg:SetAttacker(self)
    end
    dmg:SetInflictor(self)
    dmg:SetDamageType(self.RadiusDamageType)
    dmg:SetDamage(self.RadiusDamage)
    util.BlastDamageInfo(dmg, self:GetPos(), self.RadiusDamageRadius)

    self:Remove()
end
