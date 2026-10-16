AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Type = "anim"
ENT.Base = "ent_mine_base"
ENT.PrintName = "Frosty Mine"

ENT.Model = "models/mechanics/wheels/wheel_smooth_18r.mdl"
ENT.Material = "models/player/shared/ice_player"
ENT.IsProximityMine = true
ENT.TriggerRadius = 150
ENT.Damage = 50
ENT.DamageRadius = 256
ENT.ArmDelay = 1.0

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

    local startDelay = 1.0
    local interval = 0.3

    for i = 0, 4 do
        timer.Simple(startDelay + (i * interval), function()
            if IsValid(self) then
                self:DoFrostWave()
            end
        end)
    end

    timer.Simple(startDelay + (5 * interval) + 0.5, function()
        if IsValid(self) then
            self:FinalRemove()
        end
    end)
end

function ENT:DoFrostWave()
    local pos = self:GetPos()
    local attacker = self:GetAttacker()

    local e = EffectData()
    e:SetOrigin(pos)
    e:SetNormal(Vector(0,0,1))
    e:SetScale(1)
    util.Effect("weeper_blast", e, true, true)

    self:EmitSound("npc/zombie/claw_strike1.wav", 75, 100)

    local dmg = DamageInfo()
    dmg:SetAttacker(attacker)
    dmg:SetInflictor(self)
    dmg:SetDamageType(DMG_REMOVENORAGDOLL)
    dmg:SetDamage(self.Damage)

    util.BlastDamageInfo(dmg, pos, self.DamageRadius)

    local targets = ents.FindInSphere(pos, self.DamageRadius)
    for _, ent in pairs(targets) do
        if (ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer()) and ent ~= self and ent ~= attacker then

            if ent.Horde_AddDebuffBuildup and HORDE.Status_Frostbite then
                 ent:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 15, attacker)
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
