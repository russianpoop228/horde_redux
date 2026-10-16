AddCSLuaFile("shared.lua")
include("shared.lua")
ENT.Model = {"models/vj_base/projectiles/spit_acid_large.mdl"}
ENT.DecalTbl_DeathDecals = {"VJ_RedBlood1"}
ENT.SoundTbl_Idle = {"vj_base/ambience/acid_idle.wav"}
ENT.SoundTbl_OnCollide = {"vj_base/ambience/acid_splat.wav"}
ENT.DoesRadiusDamage = false
ENT.RadiusDamageRadius = 150
ENT.RadiusDamage = 20
ENT.RadiusDamageUseRealisticRadius = true
ENT.RadiusDamageType = DMG_SLASH
ENT.DoesDirectDamage = false
function ENT:CustomPhysicsObjectOnInitialize(phys)
	phys:Wake()
	phys:SetBuoyancyRatio(0)
	phys:EnableDrag(false)
	phys:SetMass(1)
	phys:EnableGravity(true)
	timer.Simple(1.5, function ()
		if self:IsValid() then self:Remove() end
	end)
	self:SetColor(Color(153,0,0))
end
function ENT:CustomOnInitialize()
	ParticleEffectAttach("blood_impact_red_01", PATTACH_ABSORIGIN_FOLLOW, self, 0)
	ParticleEffectAttach("blood_zombie_split_spray", PATTACH_ABSORIGIN_FOLLOW, self, 0)
end
function ENT:CustomOnThink()
	ParticleEffectAttach("blood_impact_red_01", PATTACH_ABSORIGIN_FOLLOW, self, 0)
	ParticleEffectAttach("blood_zombie_split_spray", PATTACH_ABSORIGIN_FOLLOW, self, 0)
end
function ENT:DeathEffects(data,phys)
	local effectdata = EffectData()
	effectdata:SetOrigin(data.HitPos)
	effectdata:SetScale(5)
	util.Effect("BloodImpact",effectdata)
end

function ENT:CustomOnPhysicsCollide(data, phys)
	if self.Dead then return end
	self.Dead = true
	local dmg = DamageInfo()
    local proj_buildup = self.Owner
	if self.Owner:IsValid() then
		dmg:SetAttacker(self.Owner)
	else
		dmg:SetAttacker(self)
        proj_buildup = self
	end
	dmg:SetInflictor(self)
	dmg:SetDamageType(self.RadiusDamageType)
	dmg:SetDamage(self.RadiusDamage)
	util.BlastDamageInfo(dmg, self:GetPos(), self.RadiusDamageRadius)
	for _, e in pairs(ents.FindInSphere(self:GetPos(), self.RadiusDamageRadius + 30)) do
		if e:IsPlayer() then
			e:Horde_AddDebuffBuildup(HORDE.Status_Bleeding, 20, proj_buildup)
		end
	end

	self:Remove()
end
