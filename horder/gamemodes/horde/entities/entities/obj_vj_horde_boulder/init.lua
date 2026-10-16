AddCSLuaFile("shared.lua")
include("shared.lua")
ENT.Model = {"models/props_lab/bigrock.mdl"}
ENT.DoesRadiusDamage = true
ENT.RadiusDamageRadius = 175
ENT.RadiusDamage = 250
ENT.RadiusDamageUseRealisticRadius = false
ENT.RadiusDamageType = DMG_CLUB
ENT.SoundTbl_OnCollide = {"physics/concrete/boulder_impact_hard1.wav","physics/concrete/boulder_impact_hard2.wav", "physics/concrete/boulder_impact_hard3.wav"}

ENT.IdleSoundLevel = 200
ENT.OnCollideSoundPitch1 = 150
ENT.OnCollideSoundPitch1 = 140
function ENT:CustomPhysicsObjectOnInitialize(phys)
	phys:Wake()
	phys:SetBuoyancyRatio(0)
	phys:EnableDrag(false)
	timer.Simple(10, function ()
		if self:IsValid() then self:Remove() end
	end)
end
function ENT:CustomOnInitialize()
end
function ENT:DeathEffects(data,phys)
	for i = 1, math.random(10,20) do
		local debris = ents.Create("base_gmodentity")
		local mat = "debris/debris" .. tostring(math.random(1, 4))

		debris:SetPos(self:GetPos())
		debris:SetAngles(VectorRand():Angle())
		debris:SetModel("models/props_junk/rock001a.mdl")
		debris:SetCollisionGroup(COLLISION_GROUP_WORLD)
		debris:PhysicsInit(SOLID_VPHYSICS)

		local physobj = debris:GetPhysicsObject()
		local force = 1000

		physobj:AddVelocity(Vector(math.random(-force, force), math.random(-force, force), math.random(-force, force)))
		physobj:AddAngleVelocity(Vector(math.random(-force, force), math.random(-force, force), math.random(-force, force)))

		timer.Simple(5, function()

			if IsValid(debris) then
				local effect = EffectData()
				local debrisPos = debris:GetPos()
				effect:SetStart(debrisPos)
				effect:SetOrigin(debrisPos)
				effect:SetEntity(debris)
				util.Effect("entity_remove", effect)
				debris:Remove()
			end
		end)
	end
end
function ENT:CustomOnThink()
end
