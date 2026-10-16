INFUSION = {}

INFUSION.Id          = 6
INFUSION.Key         = "Galvanizing"
INFUSION.Name        = "Galvanizing"
INFUSION.Icon        = "damagetype/lightning.png"
INFUSION.Color       = HORDE.DMG_COLOR[HORDE.DMG_LIGHTNING]
INFUSION.Description = [[
20% chance on hit to fully apply Shock to the target.

5% chance to convert the hit into Lightning damage.
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    if math.random() <= 0.20 then
        npc:Horde_AddDebuffBuildup(HORDE.Status_Shock, 100, ply, dmginfo:GetDamagePosition())
    end
    if math.random() <= 0.05 then
        dmginfo:SetDamageType(DMG_SHOCK)
    end
end
