ENT.Base 			= "npc_vj_creature_base"

ENT.Type 			= "ai"
ENT.PrintName 		= "Hunter Mega"
ENT.Purpose 		= "Spawn it and fight with it!"
ENT.Instructions 	= "Click on the spawnicon to spawn it."
ENT.Category		= "Wolfenstein 2009"

if (CLIENT) then
	local Name = "Hunter Mega"
	local LangName = "npc_vj_horde_hunter_mega"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
end
