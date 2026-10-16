PERK.PrintName = "Militant"
PERK.Description = [[{1} increased effectiveness of Agony.]]
PERK.Icon = "materials/perks/overlord/militant.png"
PERK.Params = {
    [1] = { value = 0.5, percent = true },
}
PERK.Hooks = {}

PERK.FearStackBonus = 1
PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "overlord_militant" then
        if ply:Horde_GetPerk("overlord_base") then
            ply:Horde_AddOverlordPresence()
        else
            ply:Horde_RemoveOverlordPresence()
        end
    end
end
