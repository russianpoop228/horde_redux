ENT.Type        = "anim"
ENT.Base        = "base_entity"
ENT.PrintName   = "HE Round"
ENT.Information = ""

ENT.Spawnable   = false

AddCSLuaFile()

ENT.Model = "models/effects/combineball.mdl"
ENT.CollisionGroup = COLLISION_GROUP_PASSABLE_DOOR
ENT.CollisionGroupType = COLLISION_GROUP_PASSABLE_DOOR
ENT.Removing = nil
ENT.StartPos = nil
ENT.PlaySoundTimer = 0
ENT.StartTime = 0
ENT.BaseDamage = 25
ENT.BaseSplashDamage = 10
ENT.DirectDamage = 60
ENT.DirectDamageType = DMG_CRUSH

function ENT:Draw()
	self:DrawModel()
	self:SetAngles((LocalPlayer():EyePos() - self:GetPos()):Angle())
end

if ! SERVER then return end

function ENT:Initialize()
	self:SetModel(self.Model)
	self:SetModelScale(0.5)
	self:PhysicsInitSphere(1, "metal_bouncy")
	construct.SetPhysProp(self:GetOwner(), self, 0, self:GetPhysicsObject(),
		{ GravityToggle = false, Material = "metal_bouncy" })
	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Wake()
		phys:SetMass(1)
		phys:SetBuoyancyRatio(0)
		phys:EnableDrag(false)
		phys:EnableGravity(false)
	end

    self.dt = CurTime() + 5

	self:DrawShadow(false)
	self:ResetSequence("idle")
	self:SetCoreType(true)

	util.SpriteTrail(self, 0, colorWhite, true, 15, 0, 0.1, 1 / 6 * 0.5, "sprites/combineball_trail_black_1.vmt")
end

function ENT:Think()
    if SERVER then
        if CurTime() >= self.dt then
            self:Remove()
        end
    end
end

function ENT:SetCoreType(capture)
	if capture then
		self:SetSubMaterial(0, "models/effects/comball_glow1")
	else
		self:SetSubMaterial(0, "vj_base/effects/comball_glow2")
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Charged")
end

function ENT:OnBounce(data, phys)

end

function ENT:PhysicsCollide(data, phys)
	local owner = self:GetOwner()
	local hitEnt = data.HitEntity
	if IsValid(owner) then
		local dmg = DamageInfo()
		dmg:SetDamageType(DMG_GENERIC)
		dmg:SetAttacker(self.Owner)
		dmg:SetInflictor(self)
		dmg:SetDamage(35)
		dmg:SetDamagePosition(self:GetPos())
		hitEnt:TakeDamageInfo(dmg)
	end

	if (hitEnt:IsNPC() or hitEnt:IsPlayer()) then
		self:Remove()
		return
	end

	self:OnBounce(data, phys)

	local dataF = EffectData()
	dataF:SetOrigin(data.HitPos)
	util.Effect("cball_bounce", dataF)

	dataF = EffectData()
	dataF:SetOrigin(data.HitPos)
	dataF:SetNormal(data.HitNormal)
	dataF:SetScale(5)
	util.Effect("AR2Impact", dataF)
end

local color1 = Color(255, 255, 225, 32)
local color2 = Color(255, 255, 225, 64)
function ENT:DeathEffects(data, phys)
end

function ENT:Draw()
	self:DrawModel()
end
