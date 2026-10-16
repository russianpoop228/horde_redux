AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Type = "anim"
ENT.Base = "ent_mine_base"
ENT.PrintName = "Magma Mine"

ENT.Model = "models/mechanics/wheels/wheel_smooth_18r.mdl"
ENT.Material = "models/player/shared/gold_player"
ENT.IsProximityMine = true
ENT.TriggerRadius = 180
ENT.Damage = 80
ENT.DamageRadius = 200
ENT.ArmDelay = 1.5

function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetMaterial(self.Material)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    self:SetHealth(self.HealthVal or 50)
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

    self:EmitSound("npc/attack_helicopter/aheli_damaged_alarm1.wav", 75, 80)
    self.IsProximityMine = false

    local startDelay = 0.5
    local interval = 0.4
    local burstCount = 6

    for i = 0, burstCount - 1 do
        timer.Simple(startDelay + (i * interval), function()
            if IsValid(self) then
                self:DoMagmaBurst()
            end
        end)
    end

    timer.Simple(startDelay + (burstCount * interval) + 0.2, function()
        if IsValid(self) then
            self:FinalRemove()
        end
    end)
end

function ENT:DoMagmaBurst()
    local pos = self:GetPos()
    local attacker = self:GetAttacker()

    local e = EffectData()
    e:SetOrigin(pos)
    e:SetScale(1)
    util.Effect("m2_flame_explosion", e, true, true)

    self:EmitSound("horde/weapons/inferno_blade/flame.ogg", 80, 100)

    local dmg = DamageInfo()
    dmg:SetAttacker(attacker)
    dmg:SetInflictor(self)
    dmg:SetDamageType(DMG_BURN)
    dmg:SetDamage(self.Damage)

    util.BlastDamageInfo(dmg, pos, self.DamageRadius)

    local targets = ents.FindInSphere(pos, self.DamageRadius)
    for _, ent in pairs(targets) do
        if (ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer()) and ent ~= self and ent ~= attacker then
            if ent.Horde_AddDebuffBuildup and HORDE.Status_Burn then
                 ent:Horde_AddDebuffBuildup(HORDE.Status_Burn, 20, attacker)
            end
        end
    end
end

function ENT:FinalRemove()
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    util.Effect("cball_explode", effectdata)
    self:Remove()
end
