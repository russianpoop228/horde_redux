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
    self.Horde_ShockAttackInterval = 0.1
    self:SetColor(Color(255, 150, 0))

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

    if CurTime() >= self.Horde_NextShockAttack + (HORDE:Horde_GetWardenBuildableCurrentAttackDelay(self:GetClass(), HORDE:Horde_GetBuildableOwner(self)) or self.Horde_ShockAttackInterval) then
        local myOwner = HORDE:Horde_GetBuildableOwner(self)
        local ownerless = (not myOwner) and HORDE:IsMapBuildable(self)
        local linked = {}
        for _, ent in pairs(ents.FindInSphere(self:GetPos(), 500)) do
            if ent ~= self and ent.Horde_WatchTower then
                if ownerless then
                    if HORDE:IsMapBuildable(ent) then table.insert(linked, ent) end
                elseif IsValid(myOwner) and ent.Horde_Owner == myOwner then
                    table.insert(linked, ent)
                end
            end
        end
        local free_charges = #linked

        for _, ent in ipairs(linked) do
            local start = self:GetPos() + self:OBBCenter()
            local epos = ent:GetPos() + ent:OBBCenter()

            local tr = util.TraceLine({
                start = start,
                endpos = epos,
                filter = self,
                mask = MASK_SHOT_HULL
            })

            if tr.Hit and IsValid(tr.Entity) and tr.Entity:IsWorld() then
                continue
            end

            local enes = ents.FindInBox(start + self:GetRight(), epos + ent:GetRight())
            local hit_any = false
            for _, ene in pairs(enes) do
                if HORDE:IsEnemy(ene) then
                    local dmg = DamageInfo()
                    HORDE:Horde_BuildableApplyAttacker(dmg, self)
                    dmg:SetInflictor(self)
                    dmg:SetDamageType(DMG_BLAST)
                    dmg:SetDamage(HORDE:Horde_GetWardenBuildableCurrentDamage(self:GetClass(), HORDE:Horde_GetBuildableOwner(self)))
                    dmg:SetDamagePosition(ene:GetPos())
                    ene:TakeDamageInfo(dmg)
                    hit_any = true
                end
            end

            if hit_any and SERVER and self.Horde_ConsumableType then
                if free_charges > 0 then
                    free_charges = free_charges - 1
                else
                    self:Horde_ConsumeCharge(1)
                end
            end

            local effectdata = EffectData()
            effectdata:SetOrigin(epos)
            effectdata:SetStart(start)
            effectdata:SetEntity(self)
            util.Effect("horde_laser_turret_laser", effectdata)
        end

        self.Horde_NextShockAttack = CurTime()
    end
end
