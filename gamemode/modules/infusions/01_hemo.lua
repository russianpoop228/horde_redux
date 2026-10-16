INFUSION = {}

INFUSION.Id          = 1
INFUSION.Key         = "Hemo"
INFUSION.Name        = "Hemo"
INFUSION.Icon        = "status/bleeding.png"
INFUSION.Color       = HORDE.STATUS_COLOR[HORDE.Status_Bleeding]
INFUSION.Description = [[
25% chance on hit to fully apply Bleeding to the target.
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    if math.random() <= 0.25 then
        npc:Horde_AddDebuffBuildup(HORDE.Status_Bleeding, 100, ply, dmginfo:GetDamagePosition())
    end
end
