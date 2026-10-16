INFUSION = {}

INFUSION.Id          = 2
INFUSION.Key         = "Concussive"
INFUSION.Name        = "Concussive"
INFUSION.Icon        = "damagetype/blunt.png"
INFUSION.Color       = color_white
INFUSION.Description = [[
25% chance on hit to fully Stun the target.
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    if math.random() <= 0.25 then
        npc:Horde_AddDebuffBuildup(HORDE.Status_Stun, 100, ply, dmginfo:GetDamagePosition())
    end
end
