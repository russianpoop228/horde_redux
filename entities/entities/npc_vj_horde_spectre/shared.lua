ENT.Base 			= "npc_vj_creature_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Spectre"
ENT.Purpose 		= "Spawn it and fight with it!"
ENT.Instructions 	= "Click on the spawnicon to spawn it."
ENT.Category		= "Horde"

if (CLIENT) then
local Name = "Spectre"
local LangName = "npc_vj_horde_spectre"
local KillIcon = "materials/hud/killicons/spectre.png"
language.Add(LangName, Name)
killicon.Add(LangName, KillIcon, Color(255,255,255,255))
language.Add("#"..LangName, Name)
killicon.Add("#"..LangName, KillIcon, Color(255,255,255,255))
end
