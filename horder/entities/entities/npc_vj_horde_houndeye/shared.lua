ENT.Base 			= "npc_vj_creature_base"
ENT.Type 			= "ai"
ENT.PrintName 		= "Houndeye"
ENT.Purpose 		= "Spawn it and fight with it!"
ENT.Instructions 	= "Click on the spawnicon to spawn it."
ENT.Category		= "Half-Life 2 Beta"

if CLIENT then
    killicon.Add("npc_vj_horde_houndeye", "materials/items/houndeye.png", Color(255,255,255,255))
end

local HOUNDEYE_CLASS_PREFIX = "npc_vj_horde_houndeye"

local function Horde_IsHoundeye(ent)
    if not IsValid(ent) then return false end
    return string.sub(ent:GetClass(), 1, #HOUNDEYE_CLASS_PREFIX) == HOUNDEYE_CLASS_PREFIX
end

hook.Add("Horde_ShouldCollide", "Horde_Houndeye_NoPlayerCollision", function(ent1, ent2)
    if not IsValid(ent1) or not IsValid(ent2) then return end
    if ent2:IsPlayer() and Horde_IsHoundeye(ent1) then return false end
    if ent1:IsPlayer() and Horde_IsHoundeye(ent2) then return false end
end)
