ENT.Base 			= "npc_vj_creature_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Antlion"
ENT.Purpose 		= "Spawn it and fight with it!"
ENT.Instructions 	= "Click on the spawnicon to spawn it."
ENT.Category		= "Horde"

if (CLIENT) then
    local Name = "Antlion"
    local LangName = "npc_vj_horde_antlion"
    language.Add(LangName, Name)
    killicon.Add(LangName, "vgui/hud/antlion", Color(0, 0, 0, 255))
    language.Add("#"..LangName, Name)
    killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
end
