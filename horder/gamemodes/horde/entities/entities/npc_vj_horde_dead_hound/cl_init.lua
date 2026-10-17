include("shared.lua")

function ENT:Initialize()
    self.CurrentAura = nil
    self.CurrentAuraEffect = nil
end

function ENT:UpdateAura()
    local phase2 = self:GetNWBool("Phase2", false)
    local phase3 = self:GetNWBool("Phase3", false)

    local targetEffect = nil
    if phase3 then
        targetEffect = "dh_phase3"
    elseif phase2 then
        targetEffect = "dh_aura"
    end

    if self.CurrentAura == targetEffect then return end

    if self.CurrentAuraEffect and IsValid(self.CurrentAuraEffect) then
        self.CurrentAuraEffect:StopEmission()
        self.CurrentAuraEffect = nil
    end

    self.CurrentAura = targetEffect
    if targetEffect then
        self.CurrentAuraEffect = self:CreateParticleEffect(targetEffect, PATTACH_ABSORIGIN_FOLLOW, 0)
    end
end

function ENT:Think()
    self:UpdateAura()
end
