ENT.Base 			= "npc_vj_human_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Plague Sentry"
ENT.Purpose 		= "Plague Elite variation — tiny head with a hostile sentry turret on top."
ENT.Instructions 	= "Spawn it and fight with it!"
ENT.Category		= "Zombies"

if (CLIENT) then
local Name = "Plague Sentry"
local LangName = "npc_vj_horde_plague_sentry"
language.Add(LangName, Name)
killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
language.Add("#"..LangName, Name)
killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
end
