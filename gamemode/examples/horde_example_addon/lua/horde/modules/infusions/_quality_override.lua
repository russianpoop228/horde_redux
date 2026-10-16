INFUSION = {}

INFUSION.Id          = 7
INFUSION.Key         = "Quality"
INFUSION.Name        = "Quality (Enhanced)"
INFUSION.Icon        = "star.png"
INFUSION.Color       = color_white
INFUSION.Description = [[
30% increased weapon damage.

Weapon damage is no longer affected by perks or gadgets.
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    bonus.increase = 0.30
    bonus.more = 1
    bonus.damage_add = 0
    return true
end
