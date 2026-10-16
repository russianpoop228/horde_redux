PERK.PrintName = "Engineer Base"
PERK.Description = [[
The Engineer builds and fights with minions and structures.
Complexity: MEDIUM

{1} increased minion damage. ({2} per level, up to {3}).
Turrets have {4} base health and deal {5} base damage.

Starting Metal: {6} ({7} + {8} per level, up to {9}).
Regenerates {10} Metal every {11} seconds (down to {12} seconds at high level).
Green ammo boxes give {13} Metal.
When you kill an enemy, {14} chance ({15} + {16} per level, up to {17}) to gain Metal equal to {18} of its max health (up to {19} per kill).

Left Click opens the Pocket Constructor: spend Metal, place a unit, wait for it to finish building.
The Welder spends Metal to repair and reload your turrets.
A Metal Dispenser nearby reloads turrets over time.
Upgrade+1 spends Metal to permanently boost all units of that type.
Destroy removes one unit and refunds part of the cost.
Infusions can be applied per unit type.]]
PERK.Params = {
    [1]  = { percent = true, base = 0, level = 0.008, max = 0.20, classname = HORDE.Class_Engineer },
    [2]  = { percent = true, value = 0.008 },
    [3]  = { percent = true, value = 0.20 },
    [4]  = { value = 400 },
    [5]  = { value = 15 },
    [6]  = { base = 750, level = 20, max = 1250, classname = HORDE.Class_Engineer },
    [7]  = { value = 750 },
    [8]  = { value = 20 },
    [9]  = { value = 1250 },
    [10] = { value = 25 },
    [11] = { base = 30, level = -0.2, max = 30, classname = HORDE.Class_Engineer },
    [12] = { value = 25 },
    [13] = { value = 150 },
    [14] = { percent = true, base = 0.33, level = 0.0068, max = 0.50, classname = HORDE.Class_Engineer },
    [15] = { percent = true, value = 0.33 },
    [16] = { percent = true, value = 0.0068 },
    [17] = { percent = true, value = 0.50 },
    [18] = { percent = true, value = 0.10 },
    [19] = { value = 2500 },
}

PERK.Hooks = {}
PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if SERVER and perk == "engineer_base" then
        local level = ply:Horde_GetLevel(HORDE.Class_Engineer)
        ply:Horde_SetMetalRegenTick(HORDE:Horde_GetMetalRegenTick(level))
        if not ply.Horde_EngineerMetalGranted then
            local amount = HORDE:Horde_GetMetalStartAmount(level)
            if HORDE.Wave666_PrepMetalAmount then
                amount = HORDE:Wave666_PrepMetalAmount(ply, amount)
            end
            ply:Horde_SetMetal(amount)
            ply.Horde_EngineerMetalGranted = true
        end
    end
end

local ApplyPerkEffect = PERK.Hooks.Horde_OnSetPerk

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "engineer_base" then
        if ply.Horde_PerksRefreshing then return end
        ply:Horde_SetMetal(0)
        ply:Horde_SetMetalRegenTick(0)
        ply.Horde_EngineerMetalGranted = nil
    end
end

PERK.Hooks.Horde_OnPerksApplied = function(ply)
    if not SERVER or not ply:Horde_GetPerk("engineer_base") then return end
    ApplyPerkEffect(ply, "engineer_base")
end

PERK.OwnerHooks.Horde_OnPlayerMinionDamage = function(ply, npc, bonus, dmginfo)
    if ply:Horde_GetPerk("engineer_base") then
        bonus.increase = bonus.increase + ply:Horde_GetPerkLevelBonus("engineer_base")
    end
end

PERK.Hooks.OnEntityCreated = function(ent)
    if CLIENT then return end
    timer.Simple(0.1, function()
        if not ent:IsValid() then return end
        local ply = HORDE:GetMinionOwner(ent)
        if not ply or not ply:IsValid() then return end
        if not ply:Horde_GetPerk("engineer_base") then return end
        if ent:IsNPC() then
            if ent:GetClass() == "npc_turret_floor" or ent:GetClass() == "npc_vj_horde_rebel_turret" then
                if ent:GetMaxHealth() < 400 then
                    if ent.Horde_Is_Mini_Sentry then
                        ent:SetMaxHealth(200)
                    else
                        ent:SetMaxHealth(400)
                    end
                end
            end
        end
    end)
end

PERK.Hooks.Horde_PrecomputePerkLevelBonus = function(ply)
    if SERVER then
        ply:Horde_SetPerkLevelBonus("engineer_base", math.min(0.20, 0.008 * ply:Horde_GetLevel(HORDE.Class_Engineer)))
    end
end

PERK.Hooks.Horde_OnEnemyKilled = function(victim, killer, wpn)
    if not SERVER then return end
    if not IsValid(killer) or not killer:IsPlayer() then return end
    local killer_sid64 = killer:SteamID64()
    if not killer_sid64 or killer_sid64 == "" then return end
    if not killer:Horde_GetPerk("engineer_base") then return end
    if not IsValid(victim) then return end

    local level = killer:Horde_GetLevel(HORDE.Class_Engineer) or 0
    local chance = math.min(0.50, 0.33 + 0.0068 * level)
    if math.random() > chance then return end

    local maxhp = victim:GetMaxHealth() or 0
    if maxhp <= 0 then return end
    local amount = math.max(1, math.floor(maxhp * HORDE.Metal_PerKillPct))
    if HORDE.Metal_PerKillCap and HORDE.Metal_PerKillCap > 0 then
        amount = math.min(amount, HORDE.Metal_PerKillCap)
    end
    killer:Horde_AddMetal(amount)
end
