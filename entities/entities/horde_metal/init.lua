AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
ENT.CleanupPriority = 2

local DEFAULT_LIFETIME = 60

function ENT:Initialize()
    self:SetModel("models/Mechanics/gears/gear12x6_small.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_PHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetTrigger(true)
    self:UseTriggerBounds(true, 4)
    self:PhysWake()

    self.Removing = false

    local lifetime = self.Horde_Lifetime
    if lifetime == nil then lifetime = DEFAULT_LIFETIME end
    if lifetime and lifetime > 0 then
        timer.Simple(lifetime, function()
            if IsValid(self) then self:Remove() end
        end)
    end
end

function ENT:SetMetalAmount(amount)
    amount = tonumber(amount)
    if amount == nil then return end
    self.Horde_MetalAmount = math.max(1, math.floor(amount))
end

function ENT:GetMetalAmount()
    return self.Horde_MetalAmount or 100
end

function ENT:StartTouch(entity)
    if self.Removing then return end
    if not entity:IsPlayer() or not entity:Alive() or entity:IsBot() then return end

    self.Removing = true
    entity:Horde_AddMetal(self:GetMetalAmount())
    entity:EmitSound("physics/metal/metal_box_impact_hard" .. math.random(1, 3) .. ".wav", 70, 130, 0.4)
    HORDE:SendNotification("Metal salvaged: +" .. tostring(self:GetMetalAmount()), 0, entity)
    self:Remove()
end
