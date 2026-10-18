if not SERVER then return end
if not HORDE then return end

local map_buildables = {}

function HORDE:Horde_BuildableOwnerReady(ent)
    if not IsValid(ent) then return false end
    local own = ent.Horde_Owner
    if IsValid(own) and own:IsPlayer() then return true end
    return HORDE:IsMapBuildable(ent)
end

function HORDE:Horde_BuildableHasPerk(ent, perk)
    if not IsValid(ent) then return false end
    local own = ent.Horde_Owner
    if not IsValid(own) or not own:IsPlayer() then return false end
    return own:Horde_GetPerk(perk) and true or false
end

function HORDE:Horde_BuildableIsSubclass(ent, subclass)
    if not IsValid(ent) then return false end
    local own = ent.Horde_Owner
    if not IsValid(own) or not own:IsPlayer() then return false end
    return own:Horde_GetCurrentSubclass() == subclass
end

function HORDE:Horde_BuildableLevel(ent, class)
    if not IsValid(ent) then return 0 end
    local own = ent.Horde_Owner
    if IsValid(own) and own:IsPlayer() and own.Horde_GetUpgrade then
        return own:Horde_GetUpgrade(class) or 0
    end
    return ent.Horde_MapLevel or 0
end

function HORDE:Horde_BuildableApplyAttacker(dmg, ent)
    if not dmg then return end
    local own = ent and ent.Horde_Owner
    if IsValid(own) and own:IsPlayer() then
        dmg:SetAttacker(own)
    elseif IsValid(ent) then
        dmg:SetAttacker(ent)
    end
    if IsValid(ent) then
        dmg:SetInflictor(ent)
    end
end

function HORDE:Horde_GetBuildableOwner(ent)
    if not IsValid(ent) then return nil end
    local own = ent.Horde_Owner
    if IsValid(own) and own:IsPlayer() then return own end
    own = ent:GetNWEntity("HordeOwner")
    if IsValid(own) and own:IsPlayer() then return own end
    return nil
end

function HORDE:Horde_ApplyMapBuildableRelation(ent, relation)
    if not IsValid(ent) then return end
    relation = relation or HORDE.HammerRelation.FRIENDLY
    ent.Horde_MapRelation = relation

    local isEnemy   = (relation == HORDE.HammerRelation.ENEMY)
    local isNeutral = (relation == HORDE.HammerRelation.NEUTRAL)

    ent.PlayerFriendly = not isEnemy

    if relation == HORDE.HammerRelation.FRIENDLY then
        HORDE:FriendlyAlly(ent)
        return
    end

    ent.FriendlyMinion = isNeutral and true or nil
    if not ent.AddRelationship then return end

    local rel = isEnemy and "D_HT" or "D_NU"
    timer.Simple(0.1, function()
        if not IsValid(ent) then return end
        ent:AddRelationship("player " .. rel .. " 99")
        ent:AddRelationship("ally " .. rel .. " 99")
    end)
end

local function InstallThinkDriver(ent)
    if not IsValid(ent) then return end
    if ent:IsNPC() or ent:IsNextBot() then return end
    if ent.Horde_ConsumableThinkWrapped or ent.Horde_MapThinkDriven then return end
    local oldThink = ent.Think
    if not oldThink then return end
    ent.Horde_MapThinkDriven = true

    local id = "Horde_MapBuildableThink_" .. ent:EntIndex()
    timer.Create(id, 0.1, 0, function()
        if not IsValid(ent) then
            if timer.Exists(id) then timer.Remove(id) end
            return
        end
        if HORDE.Horde_IsWatchtowerConsumableTicking
            and not HORDE:Horde_IsWatchtowerConsumableTicking() then return end
        oldThink(ent)
    end)
    ent:CallOnRemove("Horde_MapBuildableThinkCleanup", function()
        if timer.Exists(id) then timer.Remove(id) end
    end)
    ent.Think = function(s)
        if IsValid(s) then s:NextThink(CurTime() + 1) end
        return true
    end
    ent:NextThink(CurTime() + 1)
end

hook.Add("EntityTakeDamage", "Horde_Hammer_MapBuildableInvincible", function(target, dmginfo)
    if not IsValid(target) then return end
    if not target.Horde_MapInvincible then return end
    dmginfo:SetDamage(0)
    return true
end)

if SERVER then
    local function BlockMapBuildablePickup(ply, ent)
        if IsValid(ent) and ent.Horde_MapBuildable then return false end
    end
    hook.Add("PhysgunPickup", "Horde_Hammer_NoPickupMapBuildable", BlockMapBuildablePickup)
    hook.Add("GravGunPickupAllowed", "Horde_Hammer_NoPickupMapBuildable", BlockMapBuildablePickup)
    hook.Add("AllowPlayerPickup", "Horde_Hammer_NoPickupMapBuildable", BlockMapBuildablePickup)
    hook.Add("PlayerUse", "Horde_Hammer_NoPickupMapBuildable", function(ply, ent)
        if IsValid(ent) and ent.Horde_MapBuildable then return false end
    end)
end

function HORDE:Horde_SetMapBuildableHealth(ent, health)
    if not IsValid(ent) then return end
    health = tonumber(health) or 0
    if health <= 0 then
        ent.Horde_MapInvincible = true
        ent:SetNWBool("Horde_MapInvincible", true)
        return
    end
    ent.Horde_MapInvincible = nil
    ent:SetNWBool("Horde_MapInvincible", false)
    ent:SetMaxHealth(math.floor(health))
    ent:SetHealth(math.floor(health))
end

function HORDE:Horde_SetMapBuildableAmmo(ent, amount)
    if not IsValid(ent) then return end
    if not HORDE:Horde_IsAmmoTrackedBuildable(ent:GetClass()) then return end
    amount = tonumber(amount)
    if amount == nil then return end
    amount = math.floor(amount)
    if amount < 0 then
        ent:SetNWInt("Horde_AmmoMax", 0)
        ent:SetNWInt("Horde_AmmoCurrent", -1)
        return
    end
    local max_ammo = ent:GetNWInt("Horde_AmmoMax", 0)
    if max_ammo <= 0 then max_ammo = amount end
    ent:SetNWInt("Horde_AmmoMax", max_ammo)
    ent:SetNWInt("Horde_AmmoCurrent", amount)
end

function HORDE:Horde_KillMapBuildable(ent)
    if not IsValid(ent) then return false end
    if not ent.Horde_MapBuildable then return false end
    local spawner = ent.Horde_MapSpawner
    if IsValid(spawner) then map_buildables[spawner:EntIndex()] = nil end
    ent:Remove()
    return true
end

function HORDE:Horde_GetMapBuildable(spawner)
    if not IsValid(spawner) then return nil end
    local ent = map_buildables[spawner:EntIndex()]
    if IsValid(ent) then return ent end
    map_buildables[spawner:EntIndex()] = nil
    return nil
end

function HORDE:Horde_GetMapBuildables()
    local out = {}
    for eid, ent in pairs(map_buildables) do
        if IsValid(ent) then
            out[#out + 1] = ent
        else
            map_buildables[eid] = nil
        end
    end
    return out
end

function HORDE:Horde_GetBuildableRegistryData(class)
    if HORDE.Horde_GetBuildableData then
        local data = HORDE:Horde_GetBuildableData(class)
        if data then return data, "engineer" end
    end
    if HORDE.Horde_GetWardenBuildableData then
        local data = HORDE:Horde_GetWardenBuildableData(class)
        if data then return data, "warden" end
    end
    return nil, nil
end

function HORDE:Horde_SpawnMapBuildable(class, pos, angles, cfg)
    cfg = cfg or {}
    if not isstring(class) or class == "" then return nil, "buildable class is not set" end

    local data, system = HORDE:Horde_GetBuildableRegistryData(class)
    if not data then return nil, "unknown buildable class: " .. tostring(class) end
    if data.IsMinion then
        return nil, class .. " is a minion unit — it needs an owner and cannot be a map buildable"
    end

    local ent = ents.Create(class)
    if not IsValid(ent) then return nil, "ents.Create failed for " .. class end

    if data.Model and data.Model ~= "" then
        ent:SetModel(data.Model)
    end
    ent:SetPos(pos)
    ent:SetAngles(angles or angle_zero)
    ent.Horde_MapBuildable = true

    ent:Spawn()
    ent:Activate()

    HORDE:Horde_MarkMapBuildable(ent, true)

    ent:SetNWEntity("HordeOwner", NULL)
    ent:SetOwner(NULL)
    ent.Horde_Owner = nil
    ent.Horde_MapLevel = math.max(0, math.floor(tonumber(cfg.level) or 0))

    ent.Horde_NoPickup = true
    ent:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:SetMass(50000)
        phys:Wake()
    end

    ent.Immune_AcidPoisonRadiation = true
    ent.Horde_Immune_Bleeding = true
    ent.Horde_Immune_Status_All = true
    ent.FalldamageImmune = true

    if system == "engineer" and HORDE.Horde_ApplyBuildableUpgradeBonus then
        HORDE:Horde_ApplyBuildableUpgradeBonus(ent, class, ent.Horde_MapLevel)
    end

    HORDE:Horde_SetMapBuildableHealth(ent, cfg.health)

    if HORDE:Horde_IsAmmoTrackedBuildable(class) then
        if cfg.infinite_ammo then
            HORDE:Horde_SetMapBuildableAmmo(ent, -1)
        else
            local ammo = tonumber(cfg.ammo)
            if ammo == nil then
                ammo = (HORDE.Horde_GetBuildableAmmoMax and HORDE:Horde_GetBuildableAmmoMax(class)) or 0
            end
            HORDE:Horde_SetMapBuildableAmmo(ent, ammo)
        end
    end

    HORDE:Horde_ApplyMapBuildableRelation(ent, cfg.relationship)

    InstallThinkDriver(ent)

    if IsValid(cfg.spawner) then
        ent.Horde_MapSpawner = cfg.spawner
        map_buildables[cfg.spawner:EntIndex()] = ent
        ent:CallOnRemove("Horde_MapBuildableRemove", function()
            local sp = cfg.spawner
            if IsValid(sp) then map_buildables[sp:EntIndex()] = nil end
        end)
    end

    print(string.format("[HORDE] Map buildable '%s' (%s) spawned at %s",
        class, tostring(system), tostring(pos)))
    return ent
end
