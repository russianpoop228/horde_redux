PERK.PrintName = "Flesh Bloom"
PERK.Description =
[[Melee damage applies Bleeding buildup equal to {1} of damage in an area.]]
PERK.Icon = "materials/perks/samurai/flesh_bloom.png"
PERK.Params = {
    [1] = {value = 0.20, percent = true},
}
PERK.Hooks = {}

PERK.OwnerHooks.Horde_OnPlayerDamage = function (ply, npc, bonus, hitgroup, dmginfo)
    if not ply:Horde_GetPerk("samurai_flesh_bloom") then return end
    if HORDE:IsMeleeDamage(dmginfo) then
        local buildup = dmginfo:GetDamage() * 0.20
        HORDE:ApplyDebuffInRadius(HORDE.Status_Bleeding, npc:GetPos(), 150, buildup, ply)
    end
end
