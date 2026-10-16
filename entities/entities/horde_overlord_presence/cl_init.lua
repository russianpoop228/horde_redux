include("shared.lua")

local auras = auras or {}

function ENT:Initialize()
    if self:GetParent() == LocalPlayer() then
        auras[self] = true
    end
end

function ENT:OnRemove()
	auras[self] = nil
end

hook.Add( "PreDraw_ImmersionBreakingCircles", "Draw_PresenceCircle", function()
	if next(auras) == nil then return end
	for aura in pairs(auras) do
        HORDE.MaskedSphereRing(aura:GetPos(), aura:GetCircleRadius() + 20, 16, 4, Color(32, 0, 56, 100))
    end
end)
