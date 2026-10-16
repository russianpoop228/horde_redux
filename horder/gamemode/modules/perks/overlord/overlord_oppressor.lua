PERK.PrintName = "Oppressor"
PERK.Description = [[{1} increased effectiveness of Suffering.]]
PERK.Icon = "materials/perks/overlord/oppressor.png"
PERK.Params = {
    [1] = { value = 0.5, percent = true },
}
PERK.Hooks = {}

PERK.FearStackBonus = 1
PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "overlord_oppressor" then
        if ply:Horde_GetPerk("overlord_base") then
            ply:Horde_AddOverlordPresence()
        else
            ply:Horde_RemoveOverlordPresence()
        end
    end
end
