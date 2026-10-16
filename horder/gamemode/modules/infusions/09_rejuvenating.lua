INFUSION = {}

INFUSION.Id          = 9
INFUSION.Key         = "Rejuvenating"
INFUSION.Name        = "Rejuvenating"
INFUSION.Icon        = "infusion/rejuvenating.png"
INFUSION.Color       = Color(50, 205, 50)
INFUSION.Description = [[
Amplifies weapon healing/leeching by 25%.

5% chance on hit to apply Weaken to yourself.
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    if math.random() <= 0.05 then
        ply:Horde_AddDebuffBuildup(HORDE.Status_Weaken, 100, ply, ply:GetPos())
    end
end
