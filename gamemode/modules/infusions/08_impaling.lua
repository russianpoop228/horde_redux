INFUSION = {}

INFUSION.Id          = 8
INFUSION.Key         = "Impaling"
INFUSION.Name        = "Impaling"
INFUSION.Icon        = "infusion/impaling.png"
INFUSION.Color       = color_white
INFUSION.Description = [[
25% increased weapon headshot damage.

25% less weapon non-headshot damage.
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    if hitgroup == HITGROUP_HEAD then
        bonus.increase = bonus.increase + 0.25
    else
        bonus.more = bonus.more * 0.75
    end
end
