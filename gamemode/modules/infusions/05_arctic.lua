INFUSION = {}

INFUSION.Id          = 5
INFUSION.Key         = "Arctic"
INFUSION.Name        = "Arctic"
INFUSION.Icon        = "damagetype/cold.png"
INFUSION.Color       = HORDE.DMG_COLOR[HORDE.DMG_COLD]
INFUSION.Description = [[
25% chance on hit to fully apply Frostbite to the target.
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    if math.random() <= 0.25 then
        npc:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 100, ply, dmginfo:GetDamagePosition())
    end
end
