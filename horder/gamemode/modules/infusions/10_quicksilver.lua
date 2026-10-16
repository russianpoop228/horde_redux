INFUSION = {}

INFUSION.Id          = 10
INFUSION.Key         = "Quicksilver"
INFUSION.Name        = "Quicksilver"
INFUSION.Icon        = "infusion/quicksilver.png"
INFUSION.Color       = Color(220, 220, 220)
INFUSION.Description = [[
Increases/decreases weapon damage based on player's available weight.

<= 15% weight -> 30% damage increase
<= 30% weight -> 25% damage increase 
<= 40% weight -> 15% damage increase 
>40% weight -> 25% damage decrease
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    local percent = ply:Horde_GetWeight() / ply:Horde_GetMaxWeight()
    if percent >= 0.85 then
        bonus.increase = bonus.increase + 0.3
    elseif percent >= 0.7 then
        bonus.increase = bonus.increase + 0.25
    elseif percent >= 0.6 then
        bonus.increase = bonus.increase + 0.15
    else
        bonus.increase = bonus.increase - 0.25
    end
end
