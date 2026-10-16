PERK.PrintName = "Humanity"
PERK.Description = [[{1} slower debuff buildup.
Healing from external sources is {2} effective instead of being fully blocked.
Max health increased up to {3}]]

PERK.Icon = "materials/perks/ghoul/humanity.png"
PERK.Params = {
    [1] = {value = 0.25, percent = true},
    [2] = {value = 0.1, percent = true},
    [3] = {value = 0.20, percent = true}
}

PERK.Hooks = {}

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if not SERVER then return end
    if perk ~= "ghoul_humanity" then return end

    if Ghoul_ScheduleMaxHPRecalc then
        Ghoul_ScheduleMaxHPRecalc(ply)
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if not SERVER then return end
    if perk ~= "ghoul_humanity" then return end

    if Ghoul_ScheduleMaxHPRecalc then
        Ghoul_ScheduleMaxHPRecalc(ply)
    end
end

PERK.Hooks.PlayerSpawn = function(ply)
    if SERVER and ply:Horde_GetPerk("ghoul_humanity") then
        timer.Simple(0.2, function()
            if IsValid(ply) and Ghoul_ScheduleMaxHPRecalc then
                Ghoul_ScheduleMaxHPRecalc(ply)
            end
        end)
    end
end

PERK.OwnerHooks.Horde_OnPlayerDebuffApply = function(ply, debuff, bonus, inflictor)
    if not ply:Horde_GetPerk("ghoul_humanity") then return end
    bonus.less = bonus.less * 0.75
end
