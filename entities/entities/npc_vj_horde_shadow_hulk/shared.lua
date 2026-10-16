ENT.Base 			= "npc_vj_creature_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Spectre"
ENT.Purpose 		= "Spawn it and fight with it!"
ENT.Instructions 	= "Click on the spawnicon to spawn it."
ENT.Category		= "Horde"

if (CLIENT) then
local Name = "Hulk Spectre"
local LangName = "npc_vj_horde_shadow_hulk"
local KillIcon = "materials/hud/killicons/hulk_spectre.png"
language.Add(LangName, Name)
killicon.Add(LangName, KillIcon, Color(255,255,255,255))
language.Add("#"..LangName, Name)
killicon.Add("#"..LangName, KillIcon, Color(255,255,255,255))
end
