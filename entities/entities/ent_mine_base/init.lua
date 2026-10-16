AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/weapons/w_slam.mdl"
ENT.HealthVal = 50
ENT.ArmDelay = 2
ENT.TriggerRadius = 100
ENT.Damage = 100
ENT.DamageRadius = 256
ENT.IsProximityMine = false
ENT.SoundDeploy = "weapons/c4/c4_plant.wav"
ENT.SoundExplode = "BaseExplosionEffect.Sound"

function ENT:IsMindBlowerLocked()
    local owner = self:GetAttacker()
    return IsValid(owner)
        and owner:IsPlayer()
        and owner:Horde_GetGadget() == "gadget_mind_blower"
        and not self._MindBlowerRemote
end

function ENT:Initialize()
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

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

function ENT:GetAttacker()
    local owner = self.Horde_Owner
    if not IsValid(owner) then owner = self:GetOwner() end
    if not IsValid(owner) then owner = self end
    return owner
end

function ENT:OnTakeDamage(dmginfo)
    if self:IsMindBlowerLocked() then
        return
    end

    self:TakePhysicsDamage(dmginfo)
    if self:Health() - dmginfo:GetDamage() <= 0 then
        self:Explode()
    else
        self:SetHealth(self:Health() - dmginfo:GetDamage())
    end
end

function ENT:Think()
    if not self:GetArmed() then
        if CurTime() > self.SpawnTime + self.ArmDelay then
            self:SetArmed(true)
            self:OnArmed()
            self:EmitSound("weapons/c4/c4_click.wav")
        end
        return
    end

    if self.IsProximityMine then
        if self:IsMindBlowerLocked() then
            self:NextThink(CurTime() + 0.1)
            return true
        end

        local pos = self:GetPos()
        for _, v in pairs(ents.FindInSphere(pos, self.TriggerRadius)) do
            if IsValid(v) and v:Health() > 0 then

                if v:IsPlayer() then goto skip end

                if v:GetClass() == "npc_vj_horde_houndeye" then goto skip end

                if (v:IsNPC() or v:IsNextBot()) and not v:GetNWEntity("HordeOwner"):IsPlayer() then
                    if v.Horde_Owner == self:GetAttacker() then goto skip end

                    self:Explode()
                    break
                end
            end
            ::skip::
        end
    end

    self:NextThink(CurTime() + 0.1)
    return true
end

function ENT:OnArmed()
end

function ENT:Explode()
    if self:IsMindBlowerLocked() then return end
    if self.Exploded then return end
    self.Exploded = true

    local pos = self:GetPos()
    local attacker = self:GetAttacker()

    local effectdata = EffectData()
    effectdata:SetOrigin(pos)
    util.Effect("Explosion", effectdata)
    self:EmitSound(self.SoundExplode)

    self:DoExplosion(pos, attacker)

    self:Remove()
end

function ENT:DoExplosion(pos, attacker)
    util.BlastDamage(self, attacker, pos, self.DamageRadius, self.Damage)
end
