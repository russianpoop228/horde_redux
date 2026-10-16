PERK.PrintName   = "Fury"
PERK.Description = [[
Killing an enemy grants an Overcharge stack.
Each stack grants {1} increased damage.]]
PERK.Icon        = "materials/status/damage.png"
PERK.Params      = {
    [1] = { value = 0.05, percent = true },
}

PERK.Hooks = {}

PERK.Hooks.Horde_OnEnemyKilled = function(victim, killer, wpn)
    if not IsValid(killer) or not killer:IsPlayer() then return end
    if not killer:Horde_GetPerk("scout_fury") then return end
    killer:Horde_AddOverchargeStack()
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "scout_fury" then
        ply:Horde_ClearOvercharge()
    end
end
