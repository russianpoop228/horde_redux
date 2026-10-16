INFUSION = {}

INFUSION.Id          = 13
INFUSION.Key         = "Chrono"
INFUSION.Name        = "Chrono"
INFUSION.Icon        = "infusion/chrono.png"
INFUSION.Color       = Color(0, 139, 139)
INFUSION.Description = [[
Increases weapon damage the longer the weapon is being held by the user.

6% damage increase per wave held by the user.
Increase caps at 50%.

20% decreased weapon damage.
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    local curr_weapon = HORDE:GetCurrentWeapon(dmginfo:GetInflictor())
    if not IsValid(curr_weapon) then return end
    local wave0 = ply.Horde_Infusion_Chrono_Wave and ply.Horde_Infusion_Chrono_Wave[curr_weapon:GetClass()]
    if not wave0 then return end
    bonus.increase = math.min(0.50, bonus.increase - 0.20 + (HORDE.current_wave - wave0) * 0.06)
end
