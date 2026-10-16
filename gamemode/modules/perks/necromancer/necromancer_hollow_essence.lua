PERK.PrintName = "Hollow Essence"
PERK.Description =
[[+{1} to maximum Spectres alive.
Each enemy killed by a Spectre grants you {2} Mind.]]
PERK.Icon = "materials/perks/necromancer/hollow_essence.png"
PERK.Params = {
    [1] = {value = 1},
    [2] = {value = 10},
}
PERK.Hooks = {}

PERK.SpectreMaxBonus = 1

PERK.Hooks.PostEntityKilled = function(victim, attacker, inflictor)
    if not SERVER then return end
    if not IsValid(victim) or not victim:IsNPC() then return end
    if HORDE:IsMinion(victim) then return end

    local function AsSpectre(candidate)
        if not IsValid(candidate) or not candidate:IsNPC() then return nil end
        local class = candidate:GetClass()
        if class == "npc_vj_horde_spectre" or class == "npc_vj_horde_shadow_hulk" or class == "npc_vj_horde_blight_spectre" then
            return candidate
        end
    end

    local spectre = AsSpectre(attacker) or AsSpectre(inflictor)
    if not spectre then return end

    local owner = HORDE:GetMinionOwner(spectre)
    if not IsValid(owner) or not owner:Horde_GetPerk("necromancer_hollow_essence") then return end

    local perk = HORDE.perks and HORDE.perks["necromancer_hollow_essence"]
    local gain = (perk and perk.Params and perk.Params[2] and perk.Params[2].value) or 10
    owner:Horde_AddMind(gain)
end

PERK.Hooks.Horde_OnUnsetPerk = function (ply, perk)
    if CLIENT then return end
    if perk == "necromancer_hollow_essence" then
        if not ply.Horde_PerksRefreshing then HORDE:RemoveSpectres(ply) end
    end
end
