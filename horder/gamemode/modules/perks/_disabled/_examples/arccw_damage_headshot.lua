PERK.PrintName = "Headhunter"
PERK.Description = "ArcCW weapons do 50% extra damage on headshots."

PERK.Hooks = {}
PERK.Hooks.Hook_BulletHit = function(wpn, data)
    local attacker = wpn:GetOwner()
    if SERVER and IsValid(attacker) and attacker:IsPlayer()
            and data.tr.HitGroup == HITGROUP_HEAD and attacker:Horde_GetPerk("arccw_damage_headshot") then
        data.damage = data.damage * 1.5
    end
end
