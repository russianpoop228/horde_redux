INFUSION = {}

INFUSION.Id          = 3
INFUSION.Key         = "Septic"
INFUSION.Name        = "Septic"
INFUSION.Icon        = "damagetype/poison.png"
INFUSION.Color       = HORDE.DMG_COLOR[HORDE.DMG_POISON]
INFUSION.Description = [[
Convert 95% non-Poison damage into Poison damage.

Weapon deals only Poison damage.
Weapon damage increases Break buildup.
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    if not HORDE:IsPoisonDamage(dmginfo) then
        bonus.more = bonus.more * 0.95
        dmginfo:SetDamageType(DMG_NERVEGAS)
    end
    npc:Horde_AddDebuffBuildup(HORDE.Status_Break, dmginfo:GetDamage() * 0.25, ply, dmginfo:GetDamagePosition())
end
