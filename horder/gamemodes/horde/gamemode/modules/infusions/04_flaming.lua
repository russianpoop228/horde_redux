INFUSION = {}

INFUSION.Id          = 4
INFUSION.Key         = "Flaming"
INFUSION.Name        = "Flaming"
INFUSION.Icon        = "damagetype/fire.png"
INFUSION.Color       = HORDE.DMG_COLOR[HORDE.DMG_FIRE]
INFUSION.Description = [[
5% chance on hit to Ignite the target.

While holding this weapon: 20% resistance to Fire damage.
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    if math.random() <= 0.05 then
        if npc.Horde_SetMostRecentFireAttacker then
            npc:Horde_SetMostRecentFireAttacker(ply, dmginfo)
        end
        local dur = (IsValid(ply) and ply.Horde_GetApplyIgniteDuration and ply:Horde_GetApplyIgniteDuration()) or 4
        npc:Ignite(dur)
    end
end
