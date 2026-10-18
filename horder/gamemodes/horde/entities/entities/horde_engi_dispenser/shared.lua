ENT.Base 			= "npc_vj_creature_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Metal Dispenser"
ENT.Purpose 		= "Passive structure. Periodically resupplies ammo to you and your nearby buildings."
ENT.Instructions 	= "Built by the Engineer Personal Pocket Constructor."
ENT.Category		= "Horde"

HORDE = HORDE or {}
HORDE.Dispenser_Range     = 150
HORDE.Dispenser_Tick      = HORDE.Dispenser_Tick or 5
HORDE.Dispenser_RefillPct = HORDE.Dispenser_RefillPct or 0.15
HORDE.Dispenser_PlayerClips = HORDE.Dispenser_PlayerClips or 1
HORDE.Dispenser_MetalRefill = HORDE.Dispenser_MetalRefill or 15

if (CLIENT) then
	local Name = "Metal Dispenser"
	local LangName = "horde_engi_dispenser"
	language.Add(LangName, Name)
	killicon.Add(LangName, "HUD/killicons/default", Color(255, 80, 0, 255))
	language.Add("#" .. LangName, Name)
	killicon.Add("#" .. LangName, "HUD/killicons/default", Color(255, 80, 0, 255))
end
