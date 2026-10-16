PERK.PrintName = "Putrid Odor"
PERK.Description = [[{1} increased reload speed.
{2} chance to buildup Necrosis debuff per shot on enemy.
{3} tighter weapon spread.]]

PERK.Icon = "materials/perks/ghoul/putrid_odor.png"
PERK.Params = {
    [1] = {value = 0.33, percent = true},
    [2] = {value = 0.05, percent = true},
    [3] = {value = 0.05, percent = true}
}

PERK.Hooks = {}

PERK.Hooks.M_Hook_Mult_ReloadTime = function(wpn, data)
    local ply = wpn:GetOwner()
    if IsValid(ply) and ply:IsPlayer() and ply:Horde_GetPerk("ghoul_putrid_odor") then
        data.mult = (data.mult or 1) - 0.33
    end
end

PERK.Hooks.M_Hook_Mult_AccuracyMOA = function(wpn, data)
    local ply = wpn:GetOwner()
    if IsValid(ply) and ply:IsPlayer() and ply:Horde_GetPerk("ghoul_putrid_odor") then
        data.mult = (data.mult or 1) * 0.95
    end
end

PERK.Hooks.Hook_BulletHit = function(wpn, data)
    if not SERVER then return end

    local ply = wpn:GetOwner()
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not ply:Horde_GetPerk("ghoul_putrid_odor") then return end

    if math.random() <= 0.05 then
        ply:Horde_AddDebuffBuildup(HORDE.Status_Necrosis, math.random(2,30), ply)
    end
end

local function RecalcWeapons(ply, perk)
    if perk ~= "ghoul_putrid_odor" then return end
    for _, wpn in pairs(ply:GetWeapons()) do
        if wpn.ArcCW then wpn:RecalcAllBuffs() end
    end
end
PERK.Hooks.Horde_OnSetPerk   = RecalcWeapons
PERK.Hooks.Horde_OnUnsetPerk = RecalcWeapons
