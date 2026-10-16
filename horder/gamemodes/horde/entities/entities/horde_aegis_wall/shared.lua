ENT.Base 			= "npc_vj_creature_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Aegis Wall"
ENT.Purpose 		= "Passive defensive wall. Absorbs damage and blocks the path."
ENT.Instructions 	= "Built by the Engineer Personal Pocket Constructor."
ENT.Category		= "Horde"

if (CLIENT) then
	local Name = "Aegis Wall"
	local LangName = "horde_aegis_wall"
	language.Add(LangName, Name)
	killicon.Add(LangName, "HUD/killicons/default", Color(255, 80, 0, 255))
	language.Add("#" .. LangName, Name)
	killicon.Add("#" .. LangName, "HUD/killicons/default", Color(255, 80, 0, 255))
end
