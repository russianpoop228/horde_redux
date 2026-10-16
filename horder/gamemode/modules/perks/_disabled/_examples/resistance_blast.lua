PERK.PrintName = "Blast Resistance"
PERK.Description = "25% increased Blast damage resistance."

PERK.Hooks = {}
PERK.Hooks.Horde_OnPlayerDamageTaken = function (ply, dmginfo, bonus)
    if not ply:Horde_GetPerk("resistance_blast") then return end
    if dmginfo:GetDamageType() == DMG_BLAST then
        bonus.resistance = bonus.resistance + 0.25
    end
end
