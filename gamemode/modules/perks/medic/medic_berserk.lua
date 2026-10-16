PERK.PrintName = "Berserk"
PERK.Description = "Players you heal have Berserk for {1} seconds.\n{2} increased damage while you have Berserk."
PERK.Icon = "materials/perks/berserk.png"
PERK.Params = {
    [1] = {value = 10},
    [2] = {value = 0.15, percent = true},
}

PERK.Hooks = {}
PERK.Hooks.Horde_OnPlayerHeal = function(ply, healinfo)
    local healer = healinfo:GetHealer()
    if healer:IsPlayer() and healer:Horde_GetPerk("medic_berserk") then
        ply:Horde_AddBerserk(10)
    end
end
