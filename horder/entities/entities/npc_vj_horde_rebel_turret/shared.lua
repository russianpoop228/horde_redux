ENT.Base 			= "npc_vj_creature_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Rebel Turret"
ENT.Purpose 		= "Engineer buildable — floor turret hacked/repainted by the resistance."
ENT.Instructions 	= "Built via the Engineer's Builder menu."
ENT.Category		= "Horde"

if (CLIENT) then
	local Name = "Rebel Turret"
	local LangName = "npc_vj_horde_rebel_turret"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
end
