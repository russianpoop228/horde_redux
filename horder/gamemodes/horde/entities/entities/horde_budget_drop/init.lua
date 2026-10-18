AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
ENT.CleanupPriority = 2

local DEFAULT_LIFETIME = 45
local LEGACY_MODEL = "models/props_c17/oildrum001.mdl"

function ENT:Initialize()
    local model = self.Horde_Model
    if not isstring(model) or model == "" or string.lower(model) == LEGACY_MODEL then
        model = IsMounted("cstrike") and "models/props/cs_assault/money.mdl" or "models/items/flare.mdl"
        if not IsMounted("cstrike") then self:SetColor(Color(0, 255, 0)) end
    end
    self:SetModel(model)
    self:SetModelScale(2)
    self:SetAngles(angle_zero)

    self:SetSolid(SOLID_BBOX)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetCollisionBounds(Vector(-8, -8, 0), Vector(8, 8, 12))
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetSolidFlags(bit.bor(FSOLID_NOT_SOLID, FSOLID_TRIGGER))
    self:SetTrigger(true)
    self:UseTriggerBounds(true, 24)

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
    self:SetPos(tr.HitPos + Vector(0, 0, 2))
end

function ENT:StartTouch(entity)
    if self.Removing then return end
    if not entity:IsPlayer() or not entity:Alive() or entity:IsBot() then return end
    if not (HORDE and HORDE.Budget_Collect) then return end

    self.Removing = true
    HORDE:Budget_Collect(entity, self)
    self:Remove()
end
