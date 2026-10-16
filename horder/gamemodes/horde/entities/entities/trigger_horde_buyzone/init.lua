ENT.Type = "brush"

local BuyZonePlayers = {}
function ENT:StartTouch(ent)
	if ent:IsPlayer() then
		if HORDE.current_break_time > 0 then
			ent:Horde_SetInBuyZone(true)
		else
			ent:Horde_SetInBuyZone(false)
		end
		BuyZonePlayers[ ent ] = true
	end
end

function ENT:EndTouch(ent)
	if ent:IsPlayer() then
		BuyZonePlayers[ ent ] = nil
		ent:Horde_SetInBuyZone(false)
		net.Start("Horde_ForceCloseShop")
    		net.Send(ent)
	end
end

hook.Add("HordeWaveEnd", "FixBuyZone", function()
	for ply , bool in pairs( BuyZonePlayers ) do
		if ply:IsValid() then
			ply:Horde_SetInBuyZone(true)
		end
	end
end)
