PERK.PrintName = "Bushido"
PERK.Description = [[
{1} increased movement speed.
{2} increased melee damage.]]

PERK.Icon = "materials/perks/bushido.png"
PERK.Params = {
    [1] = {value = 0.3, percent = true},
    [2] = {value = 0.3, percent = true},
}

PERK.Hooks = {}
PERK.OwnerHooks.Horde_OnPlayerDamage = function (ply, npc, bonus, hitgroup, dmginfo)
    if not ply:Horde_GetPerk("berserker_bushido") then return end
    if HORDE:IsMeleeDamage(dmginfo) or HORDE:IsCurrentWeapon(dmginfo, "Melee") == true then
        bonus.increase = bonus.increase + 0.3
    end
end

PERK.OwnerHooks.Horde_PlayerMoveBonus = function(ply, bonus_walk, bonus_run)
    if not ply:Horde_GetPerk("berserker_bushido") then return end
    bonus_walk.increase = bonus_walk.increase + 0.2
    bonus_run.increase = bonus_run.increase + 0.3
end
