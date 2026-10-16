AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model           = "models/sapper/seabomb.mdl"
ENT.IsProximityMine = true
ENT.TriggerRadius   = 200
ENT.ArmDelay        = 2.0
ENT.Damage          = 1333
ENT.DamageRadius    = 512

ENT.ShockDamage     = 50
ENT.FrostyDamage    = 50
ENT.MagmaDamage     = 80
ENT.ImpulseRadius   = 256

function ENT:Initialize()
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    self:SetHealth(self.HealthVal or 50)
    self.SpawnTime = CurTime()
    self.Exploded  = false

    if IsValid(self:GetOwner()) then
        self.Horde_Owner = self:GetOwner()
    end

    if self.SoundDeploy then self:EmitSound(self.SoundDeploy) end
end

function ENT:Explode()
    if self.Exploded then return end
    self.Exploded = true

    self:EmitSound("npc/attack_helicopter/aheli_damaged_alarm1.wav", 80, 90)
    self.IsProximityMine = false

    for i = 0, 4 do
        timer.Simple(1.0 + i * 0.3, function()
            if IsValid(self) then self:DoShockPulse() end
        end)
    end

    for i = 0, 4 do
        timer.Simple(1.0 + i * 0.3, function()
            if IsValid(self) then self:DoFrostyPulse() end
        end)
    end

    for i = 0, 5 do
        timer.Simple(0.5 + i * 0.4, function()
            if IsValid(self) then self:DoMagmaBurst() end
        end)
    end

    timer.Simple(1.0, function()
        if not IsValid(self) then return end
        local pos = self:GetPos()
        local attacker = self:GetAttacker()

        local ed = EffectData()
        ed:SetOrigin(pos)
        util.Effect("Explosion", ed)
        self:EmitSound(self.SoundExplode or "BaseExplosionEffect.Sound")

        util.BlastDamage(self, attacker, pos, self.DamageRadius, self.Damage)
    end)

    timer.Simple(3.4, function()
        if IsValid(self) then
            local ed = EffectData()
            ed:SetOrigin(self:GetPos())
            util.Effect("cball_explode", ed)
            self:Remove()
        end
    end)
end

function ENT:DoShockPulse()
    local pos      = self:GetPos()
    local attacker = self:GetAttacker()

    local e = EffectData()
    e:SetOrigin(pos) ; e:SetNormal(Vector(0,0,1)) ; e:SetScale(1)
    util.Effect("screecher_blast", e, true, true)

    local dmg = DamageInfo()
    dmg:SetAttacker(attacker) ; dmg:SetInflictor(self)
    dmg:SetDamageType(DMG_SHOCK) ; dmg:SetDamage(self.ShockDamage)
    util.BlastDamageInfo(dmg, pos, self.ImpulseRadius)

    for _, ent in pairs(ents.FindInSphere(pos, self.ImpulseRadius)) do
        if (ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer()) and ent ~= self and ent ~= attacker then
            if ent.Horde_AddDebuffBuildup and HORDE.Status_Shock then
                ent:Horde_AddDebuffBuildup(HORDE.Status_Shock, 15, attacker)
            end
        end
    end
end

function ENT:DoFrostyPulse()
    local pos      = self:GetPos()
    local attacker = self:GetAttacker()

    local e = EffectData()
    e:SetOrigin(pos) ; e:SetNormal(Vector(0,0,1)) ; e:SetScale(1)
    util.Effect("weeper_blast", e, true, true)

    local dmg = DamageInfo()
    dmg:SetAttacker(attacker) ; dmg:SetInflictor(self)
    dmg:SetDamageType(DMG_REMOVENORAGDOLL) ; dmg:SetDamage(self.FrostyDamage)
    util.BlastDamageInfo(dmg, pos, self.ImpulseRadius)

    for _, ent in pairs(ents.FindInSphere(pos, self.ImpulseRadius)) do
        if (ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer()) and ent ~= self and ent ~= attacker then
            if ent.Horde_AddDebuffBuildup and HORDE.Status_Frostbite then
                ent:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 15, attacker)
            end
        end
    end
end

function ENT:DoMagmaBurst()
    local pos      = self:GetPos()
    local attacker = self:GetAttacker()

    local e = EffectData()
    e:SetOrigin(pos) ; e:SetScale(1)
    util.Effect("m2_flame_explosion", e, true, true)
    self:EmitSound("horde/weapons/inferno_blade/flame.ogg", 75, 100)

    local dmg = DamageInfo()
    dmg:SetAttacker(attacker) ; dmg:SetInflictor(self)
    dmg:SetDamageType(DMG_BURN) ; dmg:SetDamage(self.MagmaDamage)
    util.BlastDamageInfo(dmg, pos, self.ImpulseRadius)

    for _, ent in pairs(ents.FindInSphere(pos, self.ImpulseRadius)) do
        if (ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer()) and ent ~= self and ent ~= attacker then
            if ent.Horde_AddDebuffBuildup and HORDE.Status_Ignite then
                ent:Horde_AddDebuffBuildup(HORDE.Status_Ignite, 20, attacker)
            end
        end
    end
end
