PERK.PrintName = "Cornered Beast"
PERK.Description = [[{1} chance to bleed the enemy.
{2} slower health drain when standing still.]]

PERK.Icon = "materials/perks/ghoul/cornered_beast.png"
PERK.Params = {
    [1] = {value = 0.10, percent = true},
    [2] = {value = 0.15, percent = true}
}

PERK.Hooks = {}

local STILL_THRESHOLD_SQ = 100

PERK.Hooks.Hook_BulletHit = function(wpn, data)
    if not SERVER then return end

    local ply = wpn:GetOwner()
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not ply:Horde_GetPerk("ghoul_cornered_beast") then return end

    local target = data.tr.Entity
    if not IsValid(target) or not target:IsNPC() then return end

    if math.random() <= 0.10 then
        target:Horde_AddDebuffBuildup(HORDE.Status_Bleeding, 25, ply)
    end
end
