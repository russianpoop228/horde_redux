INFUSION = {}

INFUSION.Id          = 14
INFUSION.Key         = "Ruination"
INFUSION.Name        = "Ruination"
INFUSION.Icon        = "status/necrosis.png"
INFUSION.Color       = Color(0, 0, 0)
INFUSION.Description = [[
Increases weapon damage based on your current Necrosis buildup.
5% damage increase per 10 Necrosis buildup, up to 33%.

Gain 0.5 Necrosis buildup per second while holding this weapon.
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    local curr_weapon = HORDE:GetCurrentWeapon(dmginfo:GetInflictor())
    if not IsValid(curr_weapon) then return end
    bonus.increase = math.min(0.33, bonus.increase + ply:Horde_GetDebuffBuildup(HORDE.Status_Necrosis) / 200)
end
