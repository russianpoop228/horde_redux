include("shared.lua")

local towers = {}

function ENT:Draw()
	self:DrawModel()
end

function ENT:Initialize()
	towers[self] = true
end

function ENT:OnRemove()
	towers[self] = nil
end

local next_scan = 0
hook.Add("PreDraw_ImmersionBreakingCircles", "Draw_EngiHealingTowerRadius", function()
	if CurTime() >= next_scan then
		next_scan = CurTime() + 0.5
		for _, e in ipairs(ents.FindByClass("horde_engi_healing_tower")) do towers[e] = true end
	end
	if next(towers) == nil then return end
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local range = (HORDE and HORDE.HealingTower_Range) or 150
	for tower in pairs(towers) do
		if not IsValid(tower) then
			towers[tower] = nil
		else
			local owner = tower:GetNWEntity("HordeOwner")
			if (not IsValid(owner) or owner == ply) and HORDE and HORDE.MaskedSphereRing then
				HORDE.MaskedSphereRing(tower:GetPos(), range, 16, 4, Color(60, 220, 80, 110))
			end
		end
	end
end)
