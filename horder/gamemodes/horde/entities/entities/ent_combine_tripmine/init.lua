AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/props_combine/combine_mine01.mdl"
ENT.HealthVal = 25
ENT.ArmDelay = 1.5
ENT.IsProximityMine = false
ENT.Damage = 150
ENT.DamageRadius = 350

function ENT:Initialize()
    self.BaseClass.Initialize(self)

    self:SetMoveType(MOVETYPE_NONE)

    self:EmitSound("items/suitchargeno1.wav")
end

function ENT:OnArmed()
    self:EmitSound("weapons/mine_activate.wav")

    local tr = self:GetBeamTrace()
    self:SetBeamEnd(tr.HitPos)
    self:SetDrawLaser(true)
    self.BeamLen = tr.Fraction
end

function ENT:Think()
    self.BaseClass.Think(self)

    if self:GetArmed() then
        self:BeamThink()
    end

    self:NextThink(CurTime() + 0.1)
    return true
end

function ENT:BeamThink()
    if self:IsMindBlowerLocked() then
        return
    end

    local tr = self:GetBeamTrace()

    if self.BeamLen and math.abs(self.BeamLen - tr.Fraction) > 0.05 then
        local ent = tr.Entity

        if tr.HitNonWorld or (IsValid(ent) and (ent:IsNPC() or ent:IsNextBot())) then

            if IsValid(ent) and ent:IsPlayer() then return end

            if IsValid(ent) and (ent:IsNPC() or ent:IsNextBot()) then
                local laserDmg = DamageInfo()
                laserDmg:SetAttacker(self:GetAttacker())
                laserDmg:SetInflictor(self)
                laserDmg:SetDamage(self.Damage * 0.5)
                laserDmg:SetDamageType(DMG_SHOCK)
                laserDmg:SetDamagePosition(tr.HitPos)
                laserDmg:SetDamageForce(self:GetUp() * 500)

                ent:TakeDamageInfo(laserDmg)

                local effectdata = EffectData()
                effectdata:SetOrigin(tr.HitPos)
                effectdata:SetNormal(tr.HitNormal)
                util.Effect("StunstickImpact", effectdata)

                if ent.Horde_AddDebuffBuildup then
                    ent:Horde_AddDebuffBuildup(HORDE.Status_Stun, 100, self:GetOwner())
                end
            end

            self:Explode()
        end
    end
end

function ENT:GetBeamTrace()
    local up = self:GetUp()
    local src = self:GetPos() + up * 5
    local endpos = src + up * 2048

    return util.TraceLine({
        start = src,
        endpos = endpos,
        filter = table.Add({self}, player.GetAll())
    })
end
