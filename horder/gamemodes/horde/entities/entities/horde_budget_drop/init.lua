AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
ENT.CleanupPriority = 2

local DEFAULT_MODEL    = "models/props_c17/oildrum001.mdl"
local DEFAULT_LIFETIME = 45

function ENT:Initialize()
    self:SetModel(self.Horde_Model or DEFAULT_MODEL)
    self:SetAngles(angle_zero)

    self:SetSolid(SOLID_BBOX)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetTrigger(true)
    self:UseTriggerBounds(true, 8)

    self.Removing = false

    self:Horde_DropToFloor()

    local lifetime = self.Horde_Lifetime
    if lifetime == nil then lifetime = DEFAULT_LIFETIME end
    if lifetime and lifetime > 0 then
        timer.Simple(lifetime, function()
            if IsValid(self) then self:Remove() end
        end)
    end
end

function ENT:Horde_DropToFloor()
    local tr = util.TraceLine({
        start  = self:GetPos() + Vector(0, 0, 8),
        endpos = self:GetPos() - Vector(0, 0, 512),
        mask   = MASK_SOLID_BRUSHONLY,
    })
    if not tr.Hit then return end
    self:SetPos(tr.HitPos - Vector(0, 0, self:OBBMins().z))
end

function ENT:StartTouch(entity)
    if self.Removing then return end
    if not entity:IsPlayer() or not entity:Alive() or entity:IsBot() then return end
    if not (HORDE and HORDE.Budget_Collect) then return end

    self.Removing = true
    HORDE:Budget_Collect(entity, self)
    self:Remove()
end
