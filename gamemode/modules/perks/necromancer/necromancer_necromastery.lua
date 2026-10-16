PERK.PrintName = "Necromastery"
PERK.Description =
[[+{1} to maximum Spectres alive.
Spectres deal {2} increased damage.
Minion spells have {3} reduced cooldown.]]
PERK.Icon = "materials/perks/necromancer/necromastery.png"
PERK.Params = {
    [1] = {value = 1},
    [2] = {value = 0.3, percent = true},
    [3] = {value = 0.4, percent = true},
}
PERK.Hooks = {}

PERK.SpectreMaxBonus = 1

PERK.OwnerHooks.Horde_OnPlayerMinionDamage = function(ply, npc, bonus, dmginfo)
    if not ply:Horde_GetPerk("necromancer_necromastery") then return end
    local inflictor = dmginfo and dmginfo:GetInflictor()
    if not IsValid(inflictor) then return end
    local class = inflictor:GetClass()
    if class == "npc_vj_horde_spectre" or class == "npc_vj_horde_shadow_hulk" or class == "npc_vj_horde_blight_spectre" then
        bonus.increase = bonus.increase + 0.3
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "necromancer_necromastery" then
        if not ply.Horde_PerksRefreshing then HORDE:RemoveSpectres(ply) end
    end
end

PERK.OwnerHooks.Horde_OnSpellCooldown = function (ply, bonus, spell)
    if ply:Horde_GetPerk("necromancer_necromastery") and table.HasValue(spell.Type, HORDE.Spell_Type_Minion) then
        bonus.less = bonus.less * 0.4
    end
end
