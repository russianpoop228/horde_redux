ENT.Base 			= "npc_vj_creature_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Fire God"
ENT.Purpose 		= "Spawn it and fight with it!"
ENT.Instructions 	= "Click on the spawnicon to spawn it."
ENT.Category		= "Horde"

if (CLIENT) then
local Name = "Fire God"
local LangName = "npc_vj_horde_scorcher_spectre"
local KillIcon = "materials/hud/killicons/spectre.png"
language.Add(LangName, Name)
killicon.Add(LangName, KillIcon, Color(255,120,40,255))
language.Add("#"..LangName, Name)
killicon.Add("#"..LangName, KillIcon, Color(255,120,40,255))
end
