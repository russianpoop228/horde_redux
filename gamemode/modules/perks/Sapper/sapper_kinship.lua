if not HORDE.Status_Sapper_Kinship then
    HORDE:RegisterStatus("Sapper_Kinship", "materials/perks/sapper/kinship.png", nil, nil, true)
end

PERK.PrintName = "Kinship"
PERK.Description = [[Summon 3 houndeyes at once (2 standard + 1 champion).
Each Houndeye's health increases by {1}.
Cooldown: 120 seconds.]]
PERK.Icon = "materials/perks/sapper/kinship.png"
PERK.Params = {
    [1] = {value = 0.10, percent = true}
}

PERK.Hooks = {}

PERK.Hooks.Horde_UseActivePerk = function(ply)
    if not SERVER then return end
    if not ply:Horde_GetPerk("sapper_kinship") then return end

    for _, v in ipairs(ents.FindByClass("npc_vj_horde_houndeye*")) do
        if IsValid(v) then
            local owner = v:GetNWEntity("HordeOwner")
            if not IsValid(owner) then owner = v:GetOwner() end
            if owner == ply and not v.Horde_PocketHoundeye then v:Remove() end
        end
    end

    local occupied = {}
    SpawnSapperHoundeye(ply, "npc_vj_horde_houndeye",          true, occupied)
    SpawnSapperHoundeye(ply, "npc_vj_horde_houndeye",          true, occupied)
    SpawnSapperHoundeye(ply, "npc_vj_horde_houndeye_champion", true, occupied)
    ply:Horde_SetPerkCooldown(120)
end

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if perk ~= "sapper_kinship" then return end
    if not SERVER then return end

    for _, v in ipairs(ents.FindByClass("npc_vj_horde_houndeye*")) do
        if IsValid(v) and v:GetOwner() == ply and not v.Horde_PocketHoundeye then v:Remove() end
    end

    net.Start("Horde_SyncActivePerk")
        net.WriteUInt(HORDE.Status_Sapper_Base, 8)
        net.WriteUInt(0, 3)
    net.Send(ply)

    net.Start("Horde_SyncActivePerk")
        net.WriteUInt(HORDE.Status_Sapper_Kinship, 8)
        net.WriteUInt(1, 3)
    net.Send(ply)
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if perk ~= "sapper_kinship" then return end
    if not SERVER then return end

    for _, v in ipairs(ents.FindByClass("npc_vj_horde_houndeye*")) do
        if IsValid(v) and v:GetOwner() == ply and not v.Horde_PocketHoundeye then v:Remove() end
    end

    net.Start("Horde_SyncActivePerk")
        net.WriteUInt(HORDE.Status_Sapper_Kinship, 8)
        net.WriteUInt(0, 3)
    net.Send(ply)

    if ply:Horde_GetPerk("sapper_base") then
        net.Start("Horde_SyncActivePerk")
            net.WriteUInt(HORDE.Status_Sapper_Base, 8)
            net.WriteUInt(1, 3)
        net.Send(ply)
    end

    HORDE:RefreshPerkCooldown(ply)
    ply:Horde_SetPerkCooldown(30)
end
