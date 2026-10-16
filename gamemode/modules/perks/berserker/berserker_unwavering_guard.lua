PERK.PrintName = "Unwavering Guard"
PERK.Description = [[
Your Aerial Parry works against all damage types.
{1} increased melee damage for {2} seconds on successful Aerial Parry.
{3} less damage taken for {4} seconds on successful Aerial Parry.]]

PERK.Icon = "materials/perks/unwavering_guard.png"
PERK.Params = {
    [1] = {value = 0.25, percent = true},
    [2] = {value = 3},
    [3] = {value = 0.25, percent = true},
    [4] = {value = 3},
}

PERK.Hooks = {}
PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if SERVER and perk == "berserker_unwavering_guard" then
        ply:Horde_SetUnwaveringGuardEnabled(true, {
            melee_damage_bonus = 0.25,
            melee_duration = 3,
            damage_reduction = 0.25,
            reduction_duration = 3
        })
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "berserker_unwavering_guard" then
        ply:Horde_SetUnwaveringGuardEnabled(false)
    end
end

PERK.OwnerHooks.Horde_OnPlayerDamage = function (ply, npc, bonus, hitgroup, dmginfo)
    if not ply:Horde_GetPerk("berserker_unwavering_guard") then return end
    if ply.HasUnwaveringGuardBuff and (HORDE:IsMeleeDamage(dmginfo) or HORDE:IsCurrentWeapon(dmginfo, "Melee") == true) then
        local perk_data = ply.Horde_UnwaveringGuardData
        if perk_data then
            bonus.increase = bonus.increase + (perk_data.melee_damage_bonus or 0.25)
        else
            bonus.increase = bonus.increase + 0.25
        end
    end
end
