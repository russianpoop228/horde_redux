PERK.PrintName = "Pyromaniac"
PERK.Description = [[Increases healing from explosion by {1}.
Increases your speed by {2}.]]

PERK.Icon = "materials/perks/sapper/pyromaniac.png"

local PARAMS = {
    [1] = {value = 0.25, percent = true},
    [2] = {value = 0.45, percent = true}
}

PERK.Params = PARAMS
PERK.Hooks = {}

PERK.OwnerHooks.Horde_OnPlayerDamageTaken = function(ply, dmginfo, bonus)
    if not ply:Horde_GetPerk("sapper_pyromaniac") then return end
    if not HORDE:IsBlastDamage(dmginfo) then return end

    local attacker  = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()

    local isOwnBlast = (attacker == ply) or
        (IsValid(inflictor) and not inflictor:IsPlayer() and inflictor:GetOwner() == ply) or
        (IsValid(attacker)  and not attacker:IsPlayer()  and attacker:GetOwner()  == ply)

    if not isOwnBlast then return end

    if ply.Pyro_CD and ply.Pyro_CD > CurTime() then return end
    ply.Pyro_CD = CurTime() + 0.5

    timer.Simple(0.05, function()
        if not IsValid(ply) or not ply:Alive() then return end
        if not ply:Horde_GetPerk("sapper_pyromaniac") then return end
        HORDE:SelfHeal(ply, ply:GetMaxHealth() * PARAMS[1].value)
    end)
end

PERK.Hooks.Horde_PlayerMoveBonus = function(ply, bonus_walk, bonus_run)
    if not IsValid(ply) then return end
    if ply:Horde_GetPerk("sapper_pyromaniac") then
        bonus_walk.increase = bonus_walk.increase + PARAMS[2].value
        bonus_run.increase  = bonus_run.increase  + PARAMS[2].value
    end
end

PERK.OwnerHooks.Horde_OnUnsetPerk = function(ply, perk)
    if ply:Horde_GetPerk("sapper_pyromaniac") then
        ply.Pyro_CD = nil
    end
end

