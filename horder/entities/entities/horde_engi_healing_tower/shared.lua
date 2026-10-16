ENT.Base 			= "npc_vj_creature_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Healing Tower"
ENT.Purpose 		= "Passive structure. Periodically heals nearby constructions and players."
ENT.Instructions 	= "Built by the Engineer Personal Pocket Constructor."
ENT.Category		= "Horde"

HORDE = HORDE or {}
HORDE.HealingTower_Range       = 150
HORDE.HealingTower_Tick        = 15
HORDE.HealingTower_BuildHeal   = 50
HORDE.HealingTower_PlayerHeal  = 5

if (CLIENT) then
	local Name = "Healing Tower"
	local LangName = "horde_engi_healing_tower"
	language.Add(LangName, Name)
	killicon.Add(LangName, "HUD/killicons/default", Color(80, 255, 80, 255))
	language.Add("#" .. LangName, Name)
	killicon.Add("#" .. LangName, "HUD/killicons/default", Color(80, 255, 80, 255))
end
