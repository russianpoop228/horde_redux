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
ENT.RadiusDamage = 25
ENT.RadiusDamageType = DMG_REMOVENORAGDOLL
ENT.RadiusDamageForce = 200
ENT.RadiusDamageForce_Up = false
ENT.RadiusDamageDisableVisibilityCheck = false
ENT.DecalTbl_DeathDecals = {"VJ_AcidSlime1"}
ENT.SoundTbl_Idle = {"vj_base/ambience/acid_idle.wav"}
ENT.SoundTbl_OnCollide = {"horde/status/frostbite_buildup.ogg"}
function ENT:CustomPhysicsObjectOnInitialize(phys)
	phys:Wake()
	phys:SetBuoyancyRatio(0)
	phys:EnableDrag(false)
	self:SetColor(Color(0,150,255,255))
end
function ENT:CustomOnInitialize()
	ParticleEffectAttach("vj_acid_idle", PATTACH_ABSORIGIN_FOLLOW, self, 0)
end
function ENT:CustomOnThink()
	local e = EffectData()
		e:SetOrigin(self:GetPos())
		e:SetScale(0.5)
	util.Effect("frostcloud", e, true, true)
end
function ENT:DeathEffects(data,phys)
	local effectdata = EffectData()
	effectdata:SetOrigin(data.HitPos)
	effectdata:SetScale( 2 )
	util.Effect("frostcloud", effectdata, true, true)
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
