AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/vj_base/projectiles/spit_acid_large.mdl"

function ENT:Initialize()
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    self:SetColor(Color(0, 255, 255))
    self:SetMaterial("models/debug/debugwhite")

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableGravity(true)
        phys:SetMass(1)
        phys:EnableDrag(false)
    end

    util.SpriteTrail(self, 0, Color(0,255,255), false, 40, 15, 1, 1/(15+1)*0.5, "trails/laser.vmt")
end

function ENT:PhysicsCollide(data, phys)
    if self.Dead then return end
    self.Dead = true
    self:EmitSound("physics/glass/glass_largesheet_break3.wav", 85, 100)

    local attacker = self:GetOwner()
    if not IsValid(attacker) then attacker = self end

    local targets = ents.FindInSphere(self:GetPos(), 100)

    for _, target in pairs(targets) do
        if IsValid(target) and (target:IsPlayer() or (target:IsNPC() and target ~= attacker)) then

            local maxHP = target:GetMaxHealth()
            local damageAmount = maxHP * 0.1

            local dmgInfo = DamageInfo()
            dmgInfo:SetDamage(damageAmount)
            dmgInfo:SetAttacker(attacker)
            dmgInfo:SetInflictor(self)
            dmgInfo:SetDamageType(DMG_REMOVENORAGDOLL)

            target:TakeDamageInfo(dmgInfo)
            if HORDE.Status_Frostbite and target.Horde_AddDebuffBuildup then
                target:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 1.5, attacker)

                if target:IsPlayer() then
                    target:ScreenFade(SCREENFADE.IN, Color(0, 255, 255, 60), 0.3, 0)
                end
            end
        end
    end

    self:Remove()
end
