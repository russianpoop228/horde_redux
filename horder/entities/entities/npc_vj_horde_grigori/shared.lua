ENT.Base 			= "npc_vj_human_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Gorlami"
ENT.Purpose 		= "Spawn it and fight with it!"
ENT.Instructions 	= "Click on the spawnicon to spawn it."
ENT.Category		= "Horde"

VJ.AddNPC_HUMAN("Father Grigori","npc_vj_horde_grigori",{"weapon_vj_horde_annabelle"}, "Horde")

VJ.AddNPCWeapon("VJ Annabelle", "weapon_vj_horde_annabelle")

if (CLIENT) then
	local Name = "Father Grigori"
	local LangName = "npc_vj_horde_grigori"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
end
