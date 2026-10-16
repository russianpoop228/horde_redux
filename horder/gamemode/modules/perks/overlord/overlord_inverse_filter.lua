PERK.PrintName = "Inverse Filter"
PERK.Description = [[{1} less debuff buildup received.
Restores {2} health whenever you receive any debuff buildup.]]
PERK.Icon = "materials/perks/overlord/inverse_filter.png"
PERK.Params = {
    [1] = { value = 0.5, percent = true },
    [2] = { value = 3 },
    [3] = { value = 0.01, percent = true },
}
PERK.Hooks = {}

PERK.FearStackBonus = 1

PERK.OwnerHooks.Horde_OnPlayerDebuffApply = function(ply, debuff, bonus, inflictor, buildup)
    if not ply:Horde_GetPerk("overlord_inverse_filter") then return end
    bonus.less = bonus.less * 0.5
    if buildup then
        HORDE:SelfHeal(ply, 3)
    end
end
