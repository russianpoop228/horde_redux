ENT.Base 			= "npc_vj_creature_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Dead Hound"
ENT.Purpose 		= "Spawn it and fight with it!"
ENT.Instructions 	= "Click on the spawnicon to spawn it."
ENT.Category		= "Zombies"

VJ.AddNPC_HUMAN("Dead Hound","npc_vj_horde_dead_hound", nil, "Horde")

if (CLIENT) then
local Name = "Dead Hound"
local LangName = "npc_vj_horde_dead_hound"
language.Add(LangName, Name)
killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
language.Add("#"..LangName, Name)
killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
end
