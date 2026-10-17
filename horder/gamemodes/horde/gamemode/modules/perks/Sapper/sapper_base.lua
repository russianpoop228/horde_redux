if not HORDE.Status_Sapper_Base then
    HORDE:RegisterStatus("Sapper_Base", "materials/items/houndeye.png", nil, nil, true)
end

PERK.PrintName = "Sapper Base"
PERK.Description = [[\
The Sapper class is a crowd-control class that can also provide high single target damage.
This class doesn't use any weapons except mines & traps.

Complexity: SLIGHTLY EASY

{1} increased Blast damage. ({2} per level, up to {3}).
{4} immunity to explosion damage.
25% increased debuff buildup from non-explosive sources.

Regenerate {6} sticky mine every {7} seconds, if you have 0 ammo.
Press SHIFT+E to deploy Houndeye. Cooldown: 30s.]]
PERK.Icon = "materials/subclasses/sapper.png"

local PARAMS = {
    [1]  = {percent = true, level = 0.004, base = 0.004, max = 0.1, classname = "Sapper"},
    [2]  = {value = 0.004, percent = true},
    [3]  = {value = 0.1, percent = true},
    [4]  = {value = 1.0, percent = true},
    [5]  = {value = 1.35, percent = true},
    [6]  = {value = 1},
    [7]  = {value = 15},
    [8]  = {value = 0.005},
    [9]  = {value = 0.10},
    [10] = {value = 1},
}

PERK.Params = PARAMS
PERK.Hooks  = {}

local HOUNDEYE_MINS = Vector(-16, -16, 0)
local HOUNDEYE_MAXS = Vector(16, 16, 35)

local function GetSapperHoundeyes(ply)
    local list = {}
    for _, ent in pairs(ents.FindByClass("npc_vj_horde_houndeye*")) do
        if IsValid(ent) then
            local owner = ent:GetNWEntity("HordeOwner")
            if not IsValid(owner) then owner = ent:GetOwner() end
            if owner == ply and not ent.Horde_PocketHoundeye then table.insert(list, ent) end
        end
    end
    return list
end

local function FindFreeSpawnPos(ply, minDist, occupied)
    minDist  = minDist  or 100
    occupied = occupied or {}

    local playerPos = ply:GetPos()

    local function IsPosFree(pos)
        local tr = util.TraceHull({
            start  = pos + Vector(0, 0, 2),
            endpos = pos + Vector(0, 0, 2),
            mins   = HOUNDEYE_MINS,
            maxs   = HOUNDEYE_MAXS,
            filter = ply,
            mask   = MASK_SOLID_BRUSHONLY,
        })
        return not tr.StartSolid and not tr.AllSolid
    end

    local function DropToGround(pos)
        local tr = util.TraceLine({
            start  = pos + Vector(0, 0, 40),
            endpos = pos - Vector(0, 0, 512),
            filter = ply,
            mask   = MASK_SOLID_BRUSHONLY,
        })
        return tr.Hit and (tr.HitPos + Vector(0, 0, 4)) or pos
    end

    local function HasLOS(pos)
        local tr = util.TraceLine({
            start  = playerPos + Vector(0, 0, 16),
            endpos = pos        + Vector(0, 0, 16),
            filter = ply,
            mask   = MASK_SOLID_BRUSHONLY,
        })
        return not tr.Hit
    end

    local function NotOccupied(pos)
        for _, occ in ipairs(occupied) do
            if pos:Distance(occ) < 50 then return false end
        end
        return true
    end

    if HORDE and HORDE.ai_nodes and #HORDE.ai_nodes > 0 then
        local nearNodes = {}
        for _, node in ipairs(HORDE.ai_nodes) do
            local np   = node.pos
            local dist = np:Distance(playerPos)
            local zDif = math.abs(np.z - playerPos.z)
            if dist >= minDist and dist <= 400 and zDif < 200 then
                table.insert(nearNodes, {pos = np, dist = dist})
            end
        end
        table.sort(nearNodes, function(a, b) return a.dist < b.dist end)

        for _, nd in ipairs(nearNodes) do
            local pos = nd.pos
            if IsPosFree(pos) and HasLOS(pos) and NotOccupied(pos) then
                return pos
            end
        end
    end

    local baseYaw = ply:GetAngles().y
    local radii  = {minDist, minDist + 60, minDist + 130, minDist + 220}
    local deltas = {0, 45, 90, 135, 180, 225, 270, 315, 22, 67, 112, 157, 202, 247, 292, 337}

    for _, radius in ipairs(radii) do
        for _, delta in ipairs(deltas) do
            local rad    = math.rad(baseYaw + delta)
            local offset = Vector(math.cos(rad) * radius, math.sin(rad) * radius, 0)
            local tryPos = DropToGround(playerPos + offset)

            if IsPosFree(tryPos) and HasLOS(tryPos) and NotOccupied(tryPos) then
                return tryPos
            end
        end
    end

    local fallback = DropToGround(playerPos + ply:GetForward() * 60)
    return fallback
end

function SpawnSapperHoundeye(ply, classname, applyKinshipBonus, occupied)
    if not SERVER then return end

    local ent = ents.Create(classname)
    if not IsValid(ent) then
        ErrorNoHalt("[Sapper] Failed to create: " .. tostring(classname) .. "\n")
        return
    end

    if ply:Horde_GetPerk("sapper_evolution") then
        ent.MeleeAttackDamage = (ent.MeleeAttackDamage or 75)  * 1.20
        ent.StartHealth       = (ent.StartHealth       or 200) * 1.10
    end

    if applyKinshipBonus then
        ent.StartHealth = (ent.StartHealth or 200) * 1.10
    end

    local spawnPos = FindFreeSpawnPos(ply, 100, occupied)

    ent:SetPos(spawnPos)
    ent:SetAngles(Angle(0, ply:GetAngles().y, 0))
    ent:SetNWEntity("HordeOwner", ply)
    ent:SetOwner(ply)
    ent.Horde_Owner = ply

    if ply.Horde_AddDropEntity then
        ply:Horde_AddDropEntity(ent:GetClass(), ent)
    end

    ent:Spawn()
    ent:Activate()
    HORDE:FriendlyAlly(ent)
    ent:SetCollisionGroup(COLLISION_GROUP_NPC_ACTOR)

    if ply:Horde_GetPerk("sapper_mutation") then
        ent.Sapper_MutationShield = true
    end

    if occupied then
        table.insert(occupied, spawnPos)
    end

    return ent
end

local function SyncBaseIcon(ply, on)
    if not SERVER then return end
    net.Start("Horde_SyncActivePerk")
        net.WriteUInt(HORDE.Status_Sapper_Base, 8)
        net.WriteUInt(on and 1 or 0, 3)
    net.Send(ply)
end

PERK.Hooks.Horde_UseActivePerk = function(ply)
    if not SERVER then return end
    if not ply:Horde_GetPerk("sapper_base") then return end

    if ply:Horde_GetPerk("sapper_kinship") then return end

    for _, v in ipairs(GetSapperHoundeyes(ply)) do
        if IsValid(v) then v:Remove() end
    end
    SpawnSapperHoundeye(ply, "npc_vj_horde_houndeye", false, {})
    ply:Horde_SetPerkCooldown(30)
end

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if not SERVER then return end
    if perk ~= "sapper_base" then return end

    local id = ply:SteamID64()

    timer.Create("Horde_Sapper_Ammo_" .. id, PARAMS[7].value, 0, function()
        if not IsValid(ply) or not ply:Alive() or not ply:Horde_GetPerk("sapper_base") then
            timer.Remove("Horde_Sapper_Ammo_" .. id) ; return
        end
        if ply:HasWeapon("weapon_sticky_mine") then
            local wep = ply:GetWeapon("weapon_sticky_mine")
            if ply:GetAmmoCount(wep:GetPrimaryAmmoType()) <= 0 then
                ply:GiveAmmo(PARAMS[6].value, wep:GetPrimaryAmmoType())
            end
        elseif HORDE.items and HORDE.items["weapon_sticky_mine"] then
            ply:Give("weapon_sticky_mine")
        end
    end)

    timer.Create("Horde_Sapper_Unstuck_" .. id, 2, 0, function()
        if not IsValid(ply) then
            timer.Remove("Horde_Sapper_Unstuck_" .. id) ; return
        end
        for _, npc in ipairs(GetSapperHoundeyes(ply)) do
            if not IsValid(npc) then continue end

            local mins = npc:OBBMins()
            local maxs = npc:OBBMaxs()
            if mins == maxs then continue end

            local tr = util.TraceHull({
                start  = npc:GetPos(),
                endpos  = npc:GetPos(),
                mins   = mins,
                maxs   = maxs,
                filter = npc,
                mask   = MASK_SOLID_BRUSHONLY,
            })

            if tr.StartSolid or tr.AllSolid then
                local freePos = FindFreeSpawnPos(ply, 80, {})
                npc:SetPos(freePos)
                npc:SetAngles(Angle(0, ply:GetAngles().y, 0))
            end
        end
    end)

    ply:Horde_SetPerkCooldown(0)

    if not ply:Horde_GetPerk("sapper_kinship") then
        SyncBaseIcon(ply, true)
    end
end

PERK.OwnerHooks.Horde_OnPlayerDamageTaken = function(ply, dmginfo, bonus)
    if not ply:Horde_GetPerk("sapper_base") then return end
    if HORDE:IsBlastDamage(dmginfo) then
        bonus.resistance = bonus.resistance + 1.0
    else
        local scale = ply:Horde_GetPerkLevelBonus("sapper_base_vulnerability_scale")
        if scale and scale > 1 then dmginfo:ScaleDamage(scale) end
    end
end

PERK.OwnerHooks.Horde_OnPlayerDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    if not ply:Horde_GetPerk("sapper_base") then return end
    if HORDE:IsBlastDamage(dmginfo) then
        bonus.increase = bonus.increase + ply:Horde_GetPerkLevelBonus("sapper_base_damage")
    end
end

PERK.OwnerHooks.Horde_OnPlayerDebuffApply = function(ply, debuff, bonus, more)
    if not ply:Horde_GetPerk("sapper_base") then return end
    if bonus.apply then bonus.apply = bonus.apply * 1.25 end
end

PERK.Hooks.Horde_PrecomputePerkLevelBonus = function(ply)
    if SERVER then
        ply:Horde_SetPerkLevelBonus(
            "sapper_base_damage",
            math.min(PARAMS[3].value, PARAMS[2].value * ply:Horde_GetLevel("Sapper"))
        )
        local reduction    = math.min(PARAMS[9].value, ply:Horde_GetLevel("Sapper") * PARAMS[8].value)
        local currentScale = PARAMS[5].value - reduction
        ply:Horde_SetPerkLevelBonus("sapper_base_vulnerability_scale", currentScale)
        PARAMS[5].value    = currentScale - 1
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if not SERVER then return end
    if perk ~= "sapper_base" then return end

    SyncBaseIcon(ply, false)
    net.Start("Horde_SyncActivePerk")
        net.WriteUInt(HORDE.Status_Sapper_Kinship, 8)
        net.WriteUInt(0, 3)
    net.Send(ply)

    timer.Simple(0.2, function()
        if not IsValid(ply) then return end
        if ply:Horde_GetClass() ~= "Sapper" then
            local id = ply:SteamID64()
            timer.Remove("Horde_Sapper_Ammo_"   .. id)
            timer.Remove("Horde_Sapper_Unstuck_" .. id)
            for _, ent in pairs(GetSapperHoundeyes(ply)) do
                if IsValid(ent) then ent:Remove() end
            end
        end
    end)
end

hook.Add("PlayerDisconnected", "Sapper_RemovePlayerMineEntities", function(ply)
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.Base == "ent_mine_base" then
            if ent:GetOwner() == ply then ent:Remove() end
        end
    end
end)
