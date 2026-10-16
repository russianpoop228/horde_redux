INFUSION = {}

INFUSION.Id          = 12
INFUSION.Key         = "Titanium"
INFUSION.Name        = "Titanium"
INFUSION.Icon        = "infusion/titanium.png"
INFUSION.Color       = Color(192, 192, 192)
INFUSION.Description = [[
Reduces player damage taken based on weapon weight.

Decrease 1% damage taken for every 1 weight on the weapon.

10% less weapon damage.
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    bonus.more = bonus.more * 0.9
end
