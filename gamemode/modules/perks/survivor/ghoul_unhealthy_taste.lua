PERK.PrintName = "Unhealthy Taste"
PERK.Description = [[Max health increased up to {1}
Speed decreases {2} per {3} HP above {4}. (max -{5} at {1} HP)
{6} increased reload speed.]]

PERK.Icon = "materials/perks/ghoul/unhealthy_taste.png"
PERK.Params = {
    [1] = {value = 125,  percent = false},
    [2] = {value = 0.01, percent = true},
    [3] = {value = 10,   percent = false},
    [4] = {value = 100,  percent = false},
    [5] = {value = 0.10, percent = true},
    [6] = {value = 0.05, percent = true}
}

PERK.Hooks = {}

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if not SERVER then return end
    if perk ~= "ghoul_unhealthy_taste" then return end

    if Ghoul_ScheduleMaxHPRecalc then
        Ghoul_ScheduleMaxHPRecalc(ply)
    end

    for _, wpn in pairs(ply:GetWeapons()) do
        if wpn.ArcCW then wpn:RecalcAllBuffs() end
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if not SERVER then return end
    if perk ~= "ghoul_unhealthy_taste" then return end

    if Ghoul_ScheduleMaxHPRecalc then
        Ghoul_ScheduleMaxHPRecalc(ply)
    end

    for _, wpn in pairs(ply:GetWeapons()) do
        if wpn.ArcCW then wpn:RecalcAllBuffs() end
    end
end

PERK.Hooks.PlayerSpawn = function(ply)
    if SERVER and ply:Horde_GetPerk("ghoul_unhealthy_taste") then
        timer.Simple(0.2, function()
            if IsValid(ply) and Ghoul_ScheduleMaxHPRecalc then
                Ghoul_ScheduleMaxHPRecalc(ply)
            end
        end)
    end
end

PERK.Hooks.M_Hook_Mult_ReloadTime = function(wpn, data)
    local ply = wpn:GetOwner()
    if IsValid(ply) and ply:IsPlayer() and ply:Horde_GetPerk("ghoul_unhealthy_taste") then
        data.mult = (data.mult or 1) - 0.05
    end
end
