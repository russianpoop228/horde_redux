AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local TRAP_SIZE     = 8
local TRAP_HEIGHT   = 32
local STUN_DURATION = 5

function ENT:Initialize()
    self:SetUseType(SIMPLE_USE)
    self:SetModel("models/trap/trap.mdl")
    self:SetModelScale(2, 0)

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    self:SetCollisionBounds(
        Vector(-TRAP_SIZE, -TRAP_SIZE, 0),
        Vector(TRAP_SIZE,  TRAP_SIZE,  10)
    )

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    self.Triggered   = false
    self.LandingDone = false
end

function ENT:PhysicsCollide(data, phys)
    if self.LandingDone or self.Triggered then return end

    if data.OurOldVelocity:Length() > 250 then return end

    self.LandingDone = true
    phys:EnableMotion(false)

    if data.HitNormal and data.HitNormal.z > 0.5 then
        self:SetAngles(Angle(0, self:GetAngles().y, 0))
    end
end

function ENT:Think()
    if self.Triggered then return end

    local pos      = self:GetPos()
    local entities = ents.FindInBox(
        pos + Vector(-TRAP_SIZE, -TRAP_SIZE, 0),
        pos + Vector(TRAP_SIZE,  TRAP_SIZE,  TRAP_HEIGHT)
    )

    for _, ent in ipairs(entities) do
        if IsValid(ent) and ent:Health() > 0 then
            if (ent:IsNPC() or ent:IsNextBot()) and ent ~= self then
                local owner = self:GetOwner()
                if not IsValid(owner) or ent ~= owner then
                    self:TriggerTrap(ent)
                    return
                end
            end
        end
    end

    self:NextThink(CurTime() + 0.1)
    return true
end

function ENT:TriggerTrap(ent)
    if self.Triggered then return end
    self.Triggered = true

    self:SetModel("models/trap/trap_close.mdl")
    self:SetModelScale(2, 0)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    self:EmitSound("trap/trap.mp3")

    if ent then
        if ent.Horde_AddStun then
            ent:Horde_AddStun(STUN_DURATION)
        elseif ent:IsNPC() then
            ent:SetSchedule(SCHED_NPC_FREEZE)
            timer.Simple(STUN_DURATION, function()
                if IsValid(ent) and not ent:IsPlayer() then
                    ent:SetSchedule(SCHED_WAKE_ANGRY)
                end
            end)
        end
    end

    timer.Create("TrapRemove_" .. self:EntIndex(), STUN_DURATION, 1, function()
        if IsValid(self) then
            local ed = EffectData()
            ed:SetOrigin(self:GetPos())
            util.Effect("cball_explode", ed)
            self:Remove()
        end
    end)
end

function ENT:OnTakeDamage(dmg)
    if self.Triggered then return end
    self:TriggerTrap(nil)

    local timerID = "TrapRemove_" .. self:EntIndex()
    if timer.Exists(timerID) then
        timer.Adjust(timerID, 5, 1, nil)
    end
end
