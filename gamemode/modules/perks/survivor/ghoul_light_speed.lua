PERK.PrintName = "Light Speed"
PERK.Description = [[Removes {1} from maximum weight.
Your movement speed is increased by {2}
You can shoot while running.]]

PERK.Icon = "materials/perks/phase_walk.png"
PERK.Params = {
    [1] = {value = 5,    percent = false},
    [2] = {value = 0.30, percent = true}
}

PERK.Hooks = {}

local function SetSprintFire(ply, enabled)
    for _, wpn in pairs(ply:GetWeapons()) do
        if wpn.ArcCW then
            wpn.ShootWhileSprint = enabled or nil
            wpn:RecalcAllBuffs()
        end
    end
end

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if perk ~= "ghoul_light_speed" then return end
    if SERVER then
        ply:Horde_SetMaxWeight(HORDE.max_weight - 5)
    end
    SetSprintFire(ply, true)
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if perk ~= "ghoul_light_speed" then return end
    if SERVER then
        ply:Horde_SetMaxWeight(HORDE.max_weight)
    end
    SetSprintFire(ply, false)
end

PERK.Hooks.PlayerSwitchWeapon = function(ply, oldWpn, newWpn)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not ply:Horde_GetPerk("ghoul_light_speed") then return end
    if IsValid(newWpn) and newWpn.ArcCW then
        newWpn.ShootWhileSprint = true
        newWpn:RecalcAllBuffs()
    end
end
