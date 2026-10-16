PERK.PrintName   = "Scout Base"
PERK.Description = [[
The Scout class is focused on mobility.

{1} increased damage.]]
PERK.Icon        = "materials/perks/headhunter.png"
PERK.Params      = {
    [1] = { value = 0.10, percent = true },
}

PERK.OwnerHooks.Horde_OnPlayerDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    bonus.increase = bonus.increase + 0.10
end
