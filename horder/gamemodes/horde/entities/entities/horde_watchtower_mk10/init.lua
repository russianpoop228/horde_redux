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

    self.Horde_NextThink = CurTime()
    self.Horde_Owner = self:GetNWEntity("HordeOwner")
    self.Horde_ThinkInterval = 30
    self.Horde_EnableShockwave = nil
    self.Horde_NextShockWave = CurTime()
    self.Horde_ShockwaveInterval = 2
    self.Horde_WatchTower = true
    self.Horde_NextShockAttack = CurTime()
    self.Horde_ShockAttackInterval = 0.125
    self:SetColor(Color(0, 80, 181))

    if not HORDE:Horde_BuildableOwnerReady(self) then return end

    if HORDE:Horde_BuildableHasPerk(self, "warden_restock") then
        self.Horde_ThinkInterval = 15
    end
    if HORDE:Horde_BuildableHasPerk(self, "warden_ex_machina") then
        self:Horde_AddWardenAura()
        self.Horde_EnableShockwave = true
    end
end

function ENT:Think()
    if not HORDE:Horde_BuildableOwnerReady(self) then return end
    if CurTime() >= self.Horde_NextThink + self.Horde_ThinkInterval then
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

    if CurTime() >= self.Horde_NextShockAttack + self.Horde_ShockAttackInterval then
        for _, ent in pairs(ents.FindInSphere(self:GetPos(), 200)) do
            if ent:IsValid() and ent:IsPlayer() and ent:Armor() < 100 then
               ent:SetArmor(math.min(100,ent:Armor()+1))
           sound.Play("horde/weapons/welder/spark"..math.random(1,4)..".ogg", ent:GetPos(), 75, 100, 1)
                util.ParticleTracerEx("vortigaunt_beam", self:GetPos(), ent:GetPos() + ent:OBBCenter(), true, self:EntIndex(), -1)
				util.ParticleTracerEx("vortigaunt_beam_b", self:GetPos(), ent:GetPos() + ent:OBBCenter(), true, self:EntIndex(), -1)

                break
            end
        end
        self.Horde_NextShockAttack = CurTime()
    end
end
