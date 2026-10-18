include("shared.lua")

local dispensers = {}

function ENT:Draw()
	self:DrawModel()
end

function ENT:Initialize()
	dispensers[self] = true
end

function ENT:OnRemove()
	dispensers[self] = nil
end

local next_scan = 0
hook.Add("PreDraw_ImmersionBreakingCircles", "Draw_EngiDispenserRadius", function()
	if CurTime() >= next_scan then
		next_scan = CurTime() + 0.5
		for _, e in ipairs(ents.FindByClass("horde_engi_dispenser")) do dispensers[e] = true end
	end
	if next(dispensers) == nil then return end
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local range = (HORDE and HORDE.Dispenser_Range) or 150
	for disp in pairs(dispensers) do
		if not IsValid(disp) then
			dispensers[disp] = nil
		else
			local owner = disp:GetNWEntity("HordeOwner")
			if (not IsValid(owner) or owner == ply) and HORDE and HORDE.MaskedSphereRing then
				HORDE.MaskedSphereRing(disp:GetPos(), range, 16, 4, Color(40, 120, 255, 110))
			end
		end
	end
end)
