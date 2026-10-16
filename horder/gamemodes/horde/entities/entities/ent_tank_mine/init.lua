AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Type = "anim"
ENT.Base = "ent_mine_base"
ENT.PrintName = "Tank Mine"

ENT.Model = "models/mechanics/wheels/wheel_smooth_18r.mdl"
ENT.Material = "models/player/shared/ice_player"
ENT.IsProximityMine = true
ENT.TriggerRadius = 150
ENT.Damage = 1000
ENT.DamageRadius = 512
ENT.ArmDelay = 2.0

function ENT:Initialize()
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    self:SetHealth(self.HealthVal)
    self.SpawnTime = CurTime()
    self.Exploded = false

    if IsValid(self:GetOwner()) then
        self.Horde_Owner = self:GetOwner()
    end

    if self.SoundDeploy then self:EmitSound(self.SoundDeploy) end
end

function ENT:Explode()
    if self.Exploded then return end
    self.Exploded = true

    self:EmitSound("npc/attack_helicopter/aheli_damaged_alarm1.wav")

    self.IsProximityMine = false
end

function ENT:Explode()
    if self.Exploded then return end
    self.Exploded = true

    self:EmitSound("npc/attack_helicopter/aheli_damaged_alarm1.wav")

    self.IsProximityMine = false

    timer.Simple(1.0, function()
        if IsValid(self) then
            local pos = self:GetPos()
            local attacker = self:GetAttacker()

            local effectdata = EffectData()
            effectdata:SetOrigin(pos)
            util.Effect("Explosion", effectdata)
            self:EmitSound(self.SoundExplode or "BaseExplosionEffect.Sound")

            util.BlastDamage(self, attacker, pos, self.DamageRadius, self.Damage)

            self:FinalRemove()
        end
    end)
end

function ENT:FinalRemove()
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    util.Effect("cball_explode", effectdata)
    self:Remove()
end
