PERK.PrintName = "Shotgun Punch"
PERK.Description = "ArcCW shotguns have 20mm extra penetration."

PERK.Hooks = {}

PERK.Hooks.O_Hook_Override_Penetration = function(wpn, data)
    local ply = wpn:GetOwner()
    if IsValid(ply) and ply:IsPlayer() and wpn:GetIsShotgun() and ply:Horde_GetPerk("arccw_shotgun_penetration") then
        data.current = (data.current or 0) + 20
    end
end
