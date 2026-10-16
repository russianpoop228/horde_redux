AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = {"models/vj_base/gibs/human/brain.mdl"}
ENT.ShakeWorldOnDeath = true
ENT.ShakeWorldOnDeathAmplitude = 3
ENT.ShakeWorldOnDeathRadius = 500
ENT.ShakeWorldOnDeathDuration = 1
ENT.ShakeWorldOnDeathFrequency = 200
ENT.DoesRadiusDamage = false
ENT.RadiusDamageRadius = 100
ENT.RadiusDamageUseRealisticRadius = false
ENT.RadiusDamage = 20
ENT.RadiusDamageType = DMG_BURN
ENT.RadiusDamageForce = 150
ENT.RadiusDamageForce_Up = false
ENT.RadiusDamageDisableVisibilityCheck = false
ENT.DecalTbl_DeathDecals = {"Scorch"}
ENT.SoundTbl_Idle = {"vj_base/ambience/fireball_throw.wav"}
ENT.SoundTbl_OnCollide = {"vj_base/ambience/fireball_explode.wav"}
function ENT:CustomPhysicsObjectOnInitialize(phys)
	phys:Wake()
	phys:SetBuoyancyRatio(0)
	phys:EnableDrag(false)
    phys:SetMass(1)
	phys:EnableGravity(true)
	timer.Simple(1.5, function ()
		if self:IsValid() then self:Remove() end
	end)
end
function ENT:CustomOnInitialize()
	ParticleEffectAttach("fire_jet_01_flame", PATTACH_ABSORIGIN_FOLLOW, self, 0)
	ParticleEffectAttach("vj_rocket_idle1", PATTACH_ABSORIGIN_FOLLOW, self, 0)
end
function ENT:DeathEffects(data,phys)
	local effectdata = EffectData()
	effectdata:SetOrigin(data.HitPos)
	effectdata:SetScale(2)
	util.Effect("m2_flame_explosion",effectdata)
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
	dmg:SetDamageType(DMG_BURN)
	dmg:SetDamage(20)
	util.BlastDamageInfo(dmg, self:GetPos(), 150)

	self:Remove()
end
