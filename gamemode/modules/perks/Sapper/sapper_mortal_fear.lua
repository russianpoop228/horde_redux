if not HORDE.Status_Sapper_MortalRisk then
    HORDE:RegisterStatus("Sapper_MortalRisk", "materials/perks/sapper/mortal_fear.png", true)
end

if SERVER then
    util.AddNetworkString("Horde_MortalRisk_FearStacks")
end

if CLIENT then
    local fearStacks = 0

    net.Receive("Horde_MortalRisk_FearStacks", function()
        fearStacks = net.ReadUInt(3)
        if MySelf and MySelf.SetStatus then
            MySelf:SetStatus(HORDE.Status_Sapper_MortalRisk, fearStacks)
        end
    end)
end

PERK.PrintName   = "Mortal Risk"
PERK.Description = [[Gain 1 Fear stack for every 25% of debuff buildup you accumulate.
Maximum {1} Fear stacks.
(Each Fear stack increases movement speed by {2}.)]]

PERK.Icon   = "materials/perks/sapper/mortal_fear.png"

local PARAMS = {
    [1] = {value = 4},
    [2] = {value = 0.05, percent = true},
}
PERK.Params = PARAMS
PERK.Hooks  = {}

local function UpdateFearStacks(ply)
    if not SERVER or not IsValid(ply) then return end

    local max_buildup = 0
    if ply.Horde_Debuff_Buildup then
        for _, v in pairs(ply.Horde_Debuff_Buildup) do
            if v > max_buildup then max_buildup = v end
        end
    end

    local stacks = math.min(PARAMS[1].value, math.floor(max_buildup / 25))
    if ply.Horde_FearStacks == stacks then return end

    ply.Horde_FearStacks = stacks

    ply:Horde_SyncStatus(HORDE.Status_Sapper_MortalRisk, stacks)

    net.Start("Horde_MortalRisk_FearStacks")
        net.WriteUInt(stacks, 3)
    net.Send(ply)
end

PERK.OwnerHooks.Horde_OnPlayerDebuffApply = function(ply, debuff, bonus)
    if not ply:Horde_GetPerk("sapper_mortal_fear") then return end
    timer.Simple(0, function()
        if IsValid(ply) then UpdateFearStacks(ply) end
    end)
end

PERK.OwnerHooks.Horde_PlayerMoveBonus = function(ply, bonus_walk, bonus_run)
    if not ply:Horde_GetPerk("sapper_mortal_fear") then return end
    local stacks = ply.Horde_FearStacks or 0
    if stacks <= 0 then return end
    local spd = stacks * PARAMS[2].value
    bonus_walk.increase = bonus_walk.increase + spd
    bonus_run.increase  = bonus_run.increase  + spd
end

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if not SERVER or perk ~= "sapper_mortal_fear" then return end

    ply.Horde_FearStacks = 0

    local id = ply:SteamID64()
    timer.Create("Horde_MortalRisk_Poll_" .. id, 0.5, 0, function()
        if not IsValid(ply) or not ply:Horde_GetPerk("sapper_mortal_fear") then
            timer.Remove("Horde_MortalRisk_Poll_" .. id)
            return
        end
        UpdateFearStacks(ply)
    end)
end

local ApplyPerkEffect = PERK.Hooks.Horde_OnSetPerk

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if not SERVER or perk ~= "sapper_mortal_fear" then return end

    timer.Remove("Horde_MortalRisk_Poll_" .. ply:SteamID64())
    ply.Horde_FearStacks = 0

    ply:Horde_SyncStatus(HORDE.Status_Sapper_MortalRisk, 0)

    net.Start("Horde_MortalRisk_FearStacks")
        net.WriteUInt(0, 3)
    net.Send(ply)
end

PERK.Hooks.Horde_OnPerksApplied = function(ply)
    if not SERVER or not ply:Horde_GetPerk("sapper_mortal_fear") then return end
    if timer.Exists("Horde_MortalRisk_Poll_" .. ply:SteamID64()) then return end
    ApplyPerkEffect(ply, "sapper_mortal_fear")
end
