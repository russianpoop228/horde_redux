ENT.Base 			= "npc_vj_human_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Plague Watchtower"
ENT.Purpose 		= "Plague Elite variation — a Warden watchtower bolted onto a shrunken head, wielding a fire axe."
ENT.Instructions 	= "Spawn it and fight with it!"
ENT.Category		= "Zombies"

if (CLIENT) then
local Name = "Plague Watchtower"
local LangName = "npc_vj_horde_plague_watchtower"
language.Add(LangName, Name)
killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
language.Add("#"..LangName, Name)
killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
end
