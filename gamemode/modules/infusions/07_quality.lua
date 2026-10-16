INFUSION = {}

INFUSION.Id          = 7
INFUSION.Key         = "Quality"
INFUSION.Name        = "Quality"
INFUSION.Icon        = "star.png"
INFUSION.Color       = color_white
INFUSION.Description = [[
33% increased weapon damage.

Weapon damage is no longer affected by perks or gadgets.
(i.e. Your perks become useless for this weapon)
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    bonus.increase = 0.33
    bonus.more = 1
    return true
end
