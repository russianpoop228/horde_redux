if not SERVER then return end

HORDE = HORDE or {}

local plymeta = FindMetaTable("Player")

function HORDE:AssignMinionOwner(ent, owner)
    if not IsValid(ent) then return ent end
    if not IsValid(owner) or not owner:IsPlayer() then return ent end
    ent:SetNWEntity("HordeOwner", owner)
    ent:SetOwner(owner)
    ent.Horde_Owner = owner
    return ent
end

function HORDE:RegisterMinion(ent, owner, opts)
    if not IsValid(ent) then return ent end
    if not IsValid(owner) or not owner:IsPlayer() then return ent end
    opts = opts or {}

    if ent.Horde_MinionRegistered then return ent end
    ent.Horde_MinionRegistered = true

    local do_count   = opts.count       ~= false
    local do_drop    = opts.drop_entity ~= false
    local weightless = opts.weightless  == true
    local do_nocol   = opts.no_collision ~= false

    ent:SetNWEntity("HordeOwner", owner)
    ent:SetOwner(owner)
    ent.Horde_Owner = owner

    self:FriendlyAlly(ent)

    if do_drop then
        owner:Horde_AddDropEntity(ent:GetClass(), ent)
    end

    local id = ent:GetCreationID()

    if do_nocol then
        ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
        timer.Create("Horde_MinionCollision" .. id, 1, 0, function()
            if not IsValid(ent) then
                timer.Remove("Horde_MinionCollision" .. id)
                return
            end
            ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
        end)
    end

    if do_count then
        owner:Horde_SetMinionCount(owner:Horde_GetMinionCount() + 1)
    end

    ent:CallOnRemove("Horde_MinionRemoved", function(removed)
        timer.Remove("Horde_MinionCollision" .. id)
        local o = HORDE:GetMinionOwner(removed) or owner
        if IsValid(o) then
            if do_drop then
                o:Horde_RemoveDropEntity(removed:GetClass(), id, weightless)
                o:Horde_SyncEconomy()
            end
            if do_count then
                o:Horde_SetMinionCount(o:Horde_GetMinionCount() - 1)
            end
        end
        if opts.on_remove then
            opts.on_remove(removed, o)
        end
    end)

    return ent
end

function HORDE:UnregisterMinion(ent)
    if not IsValid(ent) then return end
    ent.Horde_MinionRegistered = nil
    ent:SetNWEntity("HordeOwner", NULL)
    ent.Horde_Owner = nil
end

HORDE.FriendlyMinions = HORDE.FriendlyMinions or {}

local FRIENDLY_FACTION = { "CLASS_PLAYER_ALLY", "CLASS_COMBINE" }

function HORDE:IsFriendlyMinion(ent)
    if not IsValid(ent) then return false end
    if ent.FriendlyMinion == true or self.FriendlyMinions[ent] then return true end
    return self:IsPlayerBuildable(ent)
end

local function LikeEntity(a, b)
    if not a.AddEntityRelationship then return end
    a:AddEntityRelationship(b, D_LI, 99)
    local enemy = a.GetEnemy and a:GetEnemy()
    if IsValid(enemy) and enemy == b then
        if a.ResetEnemy then
            a:ResetEnemy(false)
        elseif a.ClearEnemyMemory then
            a:ClearEnemyMemory()
        end
    end
end

local function ApplyFriendlyRelationships(ent)
    if not IsValid(ent) then return end
    if ent.AddRelationship then
        ent:AddRelationship("player D_LI 99")
        ent:AddRelationship("ally D_LI 99")
        if HORDE.GetPlayerBuildableClasses then
            for class in pairs(HORDE:GetPlayerBuildableClasses()) do
                ent:AddRelationship(class .. " D_LI 99")
            end
        end
    end
    for other in pairs(HORDE.FriendlyMinions) do
        if not IsValid(other) then
            HORDE.FriendlyMinions[other] = nil
        elseif other ~= ent then
            LikeEntity(ent, other)
            LikeEntity(other, ent)
        end
    end
end

function HORDE:FriendlyAlly(ent)
    if not IsValid(ent) then return ent end
    ent.FriendlyMinion = true
    if not (ent:IsNPC() or ent:IsNextBot()) then return ent end
    if ent.Horde_FriendlyApplied then return ent end
    ent.Horde_FriendlyApplied = true

    ent.VJ_NPC_Class = { FRIENDLY_FACTION[1], FRIENDLY_FACTION[2] }

    self.FriendlyMinions[ent] = true
    ent:CallOnRemove("Horde_FriendlyMinionRemoved", function(removed)
        HORDE.FriendlyMinions[removed] = nil
    end)

    timer.Simple(0.1, function()
        ApplyFriendlyRelationships(ent)
    end)
    return ent
end

function HORDE:ApplyMinionRelationship(ent)
    return self:FriendlyAlly(ent)
end

hook.Add("OnEntityCreated", "Horde_FriendlyMinionFlag", function(ent)
    if not IsValid(ent) or not (ent:IsNPC() or ent:IsNextBot()) then return end
    timer.Simple(0, function()
        if IsValid(ent) and ent.FriendlyMinion == true then
            HORDE:FriendlyAlly(ent)
        end
    end)
end)

function HORDE:SpawnGodGlow(ent)
    if not IsValid(ent) then return end
    timer.Simple(0.25, function ()
        if not IsValid(ent) then return end
        local e = EffectData()
            e:SetEntity(ent)
        util.Effect("horde_god_glow", e, true, true)
    end)
end
function HORDE:SetupBuiltMinion(ent, owner)
    if not IsValid(ent) or not IsValid(owner) then return end
    ent:SetOwner(owner)
    self:ApplyMinionRelationship(ent)

    local class = ent:GetClass()
    if HORDE:Horde_IsBuildable(class) then
        HORDE:Horde_ApplyBuildableUpgradeBonus(ent, class, owner:Horde_GetUpgrade(class))
    end

    if class == "npc_manhack" then
        ent.Horde_Minion_Respawn = true

        local id = ent:GetCreationID()
        timer.Create("Horde_ManhackRepos" .. id, 30, 0, function()
            if IsValid(ent) and IsValid(owner) and owner:Alive() then
                ent:SetPos(owner:GetPos() + VectorRand())
            else
                timer.Remove("Horde_ManhackRepos" .. id)
            end
        end)

        ent:CallOnRemove("Horde_ManhackRespawnSchedule", function()
            timer.Remove("Horde_ManhackRepos" .. id)
            if not ent.Horde_Minion_Respawn then return end
            if not IsValid(owner) then return end
            timer.Create("Horde_ManhackRespawn" .. id, 30, 1, function()
                if IsValid(owner) then
                    HORDE:SpawnEngiManhack(owner)
                end
            end)
        end)
    end
end

function HORDE:SpawnEngiManhack(owner)
    if not IsValid(owner) or not owner:Alive() then return end
    if not owner:Horde_GetPerk("engineer_base") then return end

    local class = "npc_manhack"
    local limit = (HORDE.Horde_GetBuildableLimit and HORDE:Horde_GetBuildableLimit(class)) or 3
    if HORDE.GetPlayerMinionCountByClass and HORDE:GetPlayerMinionCountByClass(owner, class) >= limit then
        return
    end

    local ent = ents.Create(class)
    if not IsValid(ent) then return end
    ent:SetPos(owner:GetPos() + VectorRand() + vector_up * 16)
    self:AssignMinionOwner(ent, owner)
    ent:Spawn()
    ent:SetAngles(Angle(0, owner:GetAngles().y + 180, 0))
    ent.Horde_NoPickup = true
    ent.FalldamageImmune = true
    ent.Immune_AcidPoisonRadiation = true
    ent.Horde_Immune_Bleeding = true
    ent.Horde_Immune_Status_All = true
    ent:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)

    owner:Horde_AddDropEntity(class, ent)
    owner:Horde_SyncEconomy()
    owner:Horde_SetMinionCount(owner:Horde_GetMinionCount() + 1)

    ent:CallOnRemove("Horde_EntityRemoved", function(removed)
        if not IsValid(owner) then return end
        owner:Horde_RemoveDropEntity(removed:GetClass(), removed:GetCreationID(), true)
        owner:Horde_SyncEconomy()
        owner:Horde_SetMinionCount(owner:Horde_GetMinionCount() - 1)
    end)

    self:SetupBuiltMinion(ent, owner)
end

function HORDE:GetPlayerMinions(ply, filter)
    local out = {}
    if not IsValid(ply) then return out end

    local seen = {}
    local drops = HORDE.player_drop_entities[ply:SteamID()]
    if drops then
        for _, ent in pairs(drops) do
            if IsValid(ent) and self:IsMinionOf(ent, ply) then
                if (not filter) or filter(ent) then
                    out[#out + 1] = ent
                    seen[ent] = true
                end
            end
        end
    end

    return out
end

function HORDE:GetPlayerMinionCountByClass(ply, class)
    local n = 0
    if not IsValid(ply) then return 0 end
    local drops = HORDE.player_drop_entities[ply:SteamID()]
    if not drops then return 0 end
    for _, ent in pairs(drops) do
        if IsValid(ent) and ent:GetClass() == class and self:IsMinionOf(ent, ply) then
            n = n + 1
        end
    end
    return n
end

function HORDE:GetAntlionMinionsCount(ply)
    return self:GetPlayerMinionCountByClass(ply, "npc_vj_horde_antlion")
end

local TURRET_CLASSES = {
    ["npc_turret_floor"] = true,
    ["npc_vj_horde_rebel_turret"] = true,
    ["npc_vj_horde_shotgun_turret"] = true,
    ["npc_vj_horde_rocket_turret"] = true,
    ["npc_vj_horde_laser_turret"] = true,
    ["npc_vj_horde_sniper_turret"] = true,
    ["npc_vj_horde_tank_turret"] = true,
}

hook.Add("OnNPCKilled", "Horde_TurretForceCleanup", function(victim, attacker, inflictor)
    if not IsValid(victim) then return end
    if not TURRET_CLASSES[victim:GetClass()] then return end
    local owner = victim:GetNWEntity("HordeOwner")
    if not IsValid(owner) then return end
    local ent = victim
    timer.Simple(1.5, function()
        if IsValid(ent) then
            ent:Remove()
        end
    end)
end)

timer.Create("Horde_TurretCleanupScan", 3, 0, function()
    for _, ent in ipairs(ents.FindByClass("npc_turret_floor")) do
        if not IsValid(ent) then continue end
        if not IsValid(ent:GetNWEntity("HordeOwner")) then continue end
        local dead = false
        if ent.Health and ent:Health() <= 0 then dead = true end
        if ent.GetInternalVariable then
            local state = ent:GetInternalVariable("m_iOn")
        end
        if ent:GetSequenceName(ent:GetSequence()) == "idleenemy" then
        end
        if dead then
            ent:Remove()
        end
    end
end)
