PERK.PrintName = "Pioneer"
PERK.Description = "{1} increased minion damage. All buildables cost {2} less Metal."
PERK.Icon = "materials/perks/pioneer.png"
PERK.Params = {
    [1] = {value = 0.10, percent = true},
    [2] = {value = 0.02, percent = true},
}

PERK.Hooks = {}

PERK.OwnerHooks.Horde_OnPlayerMinionDamage = function (ply, npc, bonus, dmginfo)
    if ply:Horde_GetPerk("engineer_pioneer") then
        bonus.increase = bonus.increase + 0.10
    end
end
