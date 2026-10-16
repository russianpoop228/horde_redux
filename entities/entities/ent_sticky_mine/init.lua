AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Type = "anim"
ENT.Base = "ent_mine_base"
ENT.PrintName = "Sticky Mine"

ENT.Model = "models/props_lab/tpplug.mdl"
ENT.IsProximityMine = true
ENT.TriggerRadius = 100
ENT.Damage = 350
ENT.DamageRadius = 300
ENT.ArmDelay = 1

function ENT:PhysicsCollide(data, phys)
    if self.Stuck then return end

    local ent = data.HitEntity

    if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() or ent:GetClass()=="ent_sticky_mine") then
        return
    end

    if ent:IsWorld() or IsValid(ent) then
        self.Stuck = true

        self:EmitSound("weapons/hegrenade/he_bounce-1.wav")

        local ang = data.HitNormal:Angle()
        ang:RotateAroundAxis(ang:Right(), -180)

        self:SetPos(data.HitPos)
        self:SetAngles(ang)

        constraint.Weld(self, ent, 0, 0, 0, true, false)

        local p = self:GetPhysicsObject()
        if IsValid(p) then p:EnableMotion(false) end
    end
end
