AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
ENT.CleanupPriority = 2

function ENT:Initialize()
    self:SetModel("models/props_combine/combine_light001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
        phys:EnableGravity(true)
        phys:SetMass(10)
    end

    self.Horde_HealthVial = nil
    self.Horde_NextThink = CurTime()
    self.Horde_Owner = self:GetNWEntity("HordeOwner")
    self.Horde_ThinkInterval = 30
    self.Horde_EnableShockwave = nil
    self.Horde_NextShockWave = CurTime()
    self.Horde_ShockwaveInterval = 2
    self.Horde_WatchTower = true

    if not HORDE:Horde_BuildableOwnerReady(self) then return end
    if HORDE:Horde_BuildableHasPerk(self, "warden_restock") then
        self.Horde_ThinkInterval = 15
    end

    if HORDE:Horde_BuildableHasPerk(self, "warden_rejection_pulse") then
        self.Horde_EnableShockwave = true
    end

    if HORDE:Horde_BuildableHasPerk(self, "warden_ex_machina") then
        timer.Simple(0.1, function()
            self:Horde_AddWardenAura()
        end)
    end
end

function ENT:Think()
    if not HORDE:Horde_BuildableOwnerReady(self) then return end
    if HORDE:Horde_BuildableIsSubclass(self, "Overlord") then return end
    if CurTime() >= self.Horde_NextThink + self.Horde_ThinkInterval then
        if self.Horde_HealthVial and self.Horde_HealthVial:IsValid() then
            self.Horde_HealthVial:Remove()
        end
        self.Horde_HealthVial = ents.Create("horde_healthvial")
        self.Horde_HealthVial:SetPos(self:GetPos() - self:GetAngles():Forward() * 30)
        self.Horde_HealthVial.Owner = self.Horde_Owner
        self.Horde_HealthVial:Spawn()
        if SERVER then
            if HORDE:Horde_GetBuildableOwner(self) then
                hook.Run("Horde_WardenWatchtower", HORDE:Horde_GetBuildableOwner(self), self)
            end
        end
        self.Horde_NextThink = CurTime()
    end

    if self.Horde_EnableShockwave then
        if CurTime() >= self.Horde_NextShockWave + self.Horde_ShockwaveInterval then
            local dmg = DamageInfo()
            HORDE:Horde_BuildableApplyAttacker(dmg, self)
            dmg:SetInflictor(self)
            dmg:SetDamageType(DMG_SHOCK)
            dmg:SetDamage(50)
            local e = EffectData()
            e:SetOrigin(self:GetPos())
            util.Effect("explosion_shock", e, true, true)
            util.BlastDamageInfo(dmg, self:GetPos(), 160)
            self.Horde_NextShockWave = CurTime()
        end
    end
end
