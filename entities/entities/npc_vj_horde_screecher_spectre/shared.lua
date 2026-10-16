ENT.Base 			= "npc_vj_creature_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Lightning God"
ENT.Purpose 		= "Spawn it and fight with it!"
ENT.Instructions 	= "Click on the spawnicon to spawn it."
ENT.Category		= "Horde"

if (CLIENT) then
local Name = "Lightning God"
local LangName = "npc_vj_horde_screecher_spectre"
local KillIcon = "materials/hud/killicons/spectre.png"
language.Add(LangName, Name)
killicon.Add(LangName, KillIcon, Color(90,150,255,255))
language.Add("#"..LangName, Name)
killicon.Add("#"..LangName, KillIcon, Color(90,150,255,255))
end
