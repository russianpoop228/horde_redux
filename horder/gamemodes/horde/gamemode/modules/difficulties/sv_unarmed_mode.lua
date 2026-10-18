if CLIENT then return end

local SPAWN_PER_PLAYER   = 4
local MAX_DROPS          = 32
local SPAWN_INTERVAL     = 1
local RESPAWN_TIME       = 45
local CHANCE_AMMOBOX     = 0.25
local CHANCE_PLAYERSPAWN = 0.05
local ENEMY_SPAWN_BLOCK  = 128
local MIN_SEPARATION     = 96
local SPAWN_TIMER        = "Horde_UnarmedWaveSpawn"
local MAX_SPAWN_FAILS    = 5

local QUALITY_WEIGHTS = {
    Common    = 0.35,
    Unique    = 0.25,
    Rare      = 0.10,
    Epic      = 0.15,
    Legendary = 0.10,
    Mythic    = 0.05,
}
local QUALITY_WEIGHT_ORDER = { "Common", "Unique", "Rare", "Epic", "Legendary", "Mythic" }

local WEAPON_CATEGORIES = {
    Melee = true, Pistol = true, SMG = true, Shotgun = true,
    Rifle = true, MG = true, Explosive = true, Special = true,
}

local EXCLUDED = {
    weapon_horde_medkit  = true,
    horde_engiwrench     = true,
    horde_welder         = true,
    horde_carcass        = true,
    horde_void_projector = true,
    horde_solar_seal     = true,
    horde_astral_relic   = true,
    horde_pheropod       = true,
}

local active_drops = {}

local function ItemQuality(item)
    if istable(item) and item.quality and HORDE.Quality and HORDE.Quality[item.quality] then
        return item.quality
    end
    if HORDE.GetQualityByPrice then
        return HORDE:GetQualityByPrice(istable(item) and item.price or nil)
    end
    return "Common"
end

local function CollectWeaponClasses()
    local by_quality, all = {}, {}
    if not HORDE.items then return by_quality, all end
    local wpn_type = HORDE.ENTITY_PROPERTY_WPN or 1
    for class, item in pairs(HORDE.items) do
        if not item or item.hidden or EXCLUDED[class] then continue end
        if HORDE.relic_weapon_subclass and HORDE.relic_weapon_subclass[class] then continue end
        if not WEAPON_CATEGORIES[item.category] then continue end
        local ep = item.entity_properties
        local typ = (ep and ep.type) or wpn_type
        if typ ~= wpn_type then continue end
        local swep = weapons.GetStored(class)
        if not swep then continue end
        if swep.Base == "horde_spell_weapon_base" then continue end
        all[#all + 1] = class
        local quality = ItemQuality(item)
        by_quality[quality] = by_quality[quality] or {}
        table.insert(by_quality[quality], class)
    end
    return by_quality, all
end

local function PickWeaponClass(by_quality, all)
    if #all == 0 then return nil end
    local pool, total = {}, 0
    for _, quality in ipairs(QUALITY_WEIGHT_ORDER) do
        local weight = QUALITY_WEIGHTS[quality]
        local list = by_quality[quality]
        if weight and weight > 0 and list and #list > 0 then
            pool[#pool + 1] = { list = list, weight = weight }
            total = total + weight
        end
    end
    if total <= 0 then return all[math.random(#all)] end
    local roll = math.random() * total
    for _, entry in ipairs(pool) do
        roll = roll - entry.weight
        if roll <= 0 then return entry.list[math.random(#entry.list)] end
    end
    local last = pool[#pool]
    return last.list[math.random(#last.list)]
end

local function GetEnemySpawnPositions()
    local list = {}
    for _, node in ipairs(ents.FindByClass("info_horde_enemy_spawn")) do
        if IsValid(node) and not node.Disabled then list[#list + 1] = node:GetPos() end
    end
    return list
end

local function TooCloseTo(pos, list, dist)
    local r2 = dist * dist
    for _, p in ipairs(list) do
        if pos:DistToSqr(p) < r2 then return true end
    end
    return false
end

local function IsAccessiblePosition(pos)
    if not pos or not util.IsInWorld(pos) then return false end
    local tr_down = util.TraceLine({
        start  = pos + Vector(0, 0, 32),
        endpos = pos - Vector(0, 0, 128),
        mask   = MASK_SOLID_BRUSHONLY,
    })
    if not tr_down.Hit or tr_down.HitNormal.z < 0.7 then return false end
    local floor = tr_down.HitPos + Vector(0, 0, 8)
    local tr_hull = util.TraceHull({
        start  = floor + Vector(0, 0, 8),
        endpos = floor + Vector(0, 0, 40),
        mins   = Vector(-16, -16, 0),
        maxs   = Vector(16, 16, 72),
        mask   = MASK_PLAYERSOLID_BRUSHONLY,
    })
    if tr_hull.Hit then return false end
    return true, floor
end

local function Jitter(pos, r)
    return pos + Vector(math.random(-r, r), math.random(-r, r), 0)
end

local ammo_pool, spawn_pool = {}, {}

local function PickAmmoboxSpot()
    if #ammo_pool == 0 then return nil end
    return ammo_pool[math.random(#ammo_pool)], 48
end

local PLAYER_SPAWN_CLASSES = {
    "info_player_start", "info_player_deathmatch", "info_player_counterterrorist",
    "info_player_terrorist", "info_player_combine", "info_player_rebel",
    "info_player_teamspawn",
}
local function BuildSpotPools()
    ammo_pool, spawn_pool = {}, {}
    if HORDE.ammobox_nodes and not table.IsEmpty(HORDE.ammobox_nodes) then
        for _, pos in pairs(HORDE.ammobox_nodes) do ammo_pool[#ammo_pool + 1] = pos end
    elseif HORDE.ai_nodes then
        for _, node in pairs(HORDE.ai_nodes) do
            if node and node["pos"] then ammo_pool[#ammo_pool + 1] = node["pos"] end
        end
    end
    for _, cls in ipairs(PLAYER_SPAWN_CLASSES) do
        for _, sp in ipairs(ents.FindByClass(cls)) do
            if IsValid(sp) then spawn_pool[#spawn_pool + 1] = sp:GetPos() end
        end
    end
end

local function PickPlayerSpawnSpot()
    local pool = spawn_pool
    if #pool == 0 then
        pool = {}
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Alive() then pool[#pool + 1] = ply:GetPos() end
        end
    end
    if #pool == 0 then return nil end
    return pool[math.random(#pool)], 96
end

local nav_areas_cache
local function PickRandomSpot()
    if nav_areas_cache == nil then
        nav_areas_cache = false
        if navmesh and navmesh.GetAllNavAreas then
            local ok, areas = pcall(navmesh.GetAllNavAreas)
            if ok and areas and #areas > 0 then nav_areas_cache = areas end
        end
    end
    if nav_areas_cache then
        local area = nav_areas_cache[math.random(#nav_areas_cache)]
        if area and area.GetRandomPoint then return area:GetRandomPoint(), 0 end
    end
    if HORDE.ai_nodes and #HORDE.ai_nodes > 0 then
        local node = HORDE.ai_nodes[math.random(#HORDE.ai_nodes)]
        if node and node["pos"] then return node["pos"], 200 end
    end
    return nil
end

local function FindSpawnPosition(taken, enemy_spawns)
    local r = math.random()
    local order
    if r < CHANCE_AMMOBOX then
        order = { PickAmmoboxSpot, PickPlayerSpawnSpot, PickRandomSpot }
    elseif r < CHANCE_AMMOBOX + CHANCE_PLAYERSPAWN then
        order = { PickPlayerSpawnSpot, PickAmmoboxSpot, PickRandomSpot }
    else
        order = { PickRandomSpot, PickAmmoboxSpot, PickPlayerSpawnSpot }
    end
    for _, picker in ipairs(order) do
        for _ = 1, 25 do
            local raw, jitter = picker()
            if not raw then break end
            if jitter and jitter > 0 then raw = Jitter(raw, jitter) end
            if not TooCloseTo(raw, enemy_spawns, ENEMY_SPAWN_BLOCK) then
                local ok, floor = IsAccessiblePosition(raw)
                if ok and floor and not TooCloseTo(floor, taken, MIN_SEPARATION) then
                    return floor
                end
            end
        end
    end
    return nil
end

local function ForgetDrop(eid)
    local info = active_drops[eid]
    if info and info.timer_id and timer.Exists(info.timer_id) then
        timer.Remove(info.timer_id)
    end
    active_drops[eid] = nil
end

local function ClearAllDrops()
    for eid, info in pairs(active_drops) do
        local ent = info.ent
        ForgetDrop(eid)
        if IsValid(ent) and not IsValid(ent:GetOwner()) then ent:Remove() end
    end
end

local function CurrentDropPositions()
    local t = {}
    for _, info in pairs(active_drops) do
        if IsValid(info.ent) then t[#t + 1] = info.ent:GetPos() end
    end
    return t
end

local function ScheduleRespawn(info)
    local id = "Horde_UnarmedRespawn_" .. tostring(info.id)
    info.timer_id = id
    timer.Create(id, RESPAWN_TIME, 1, function()
        if not HORDE.unarmed_mode then return end
        local ent = info.ent
        if not IsValid(ent) or IsValid(ent:GetOwner()) then return end
        local pos = FindSpawnPosition(CurrentDropPositions(), GetEnemySpawnPositions())
        if pos then
            ent:SetPos(pos)
            ent:SetAngles(Angle(0, math.random(0, 359), 0))
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then phys:SetVelocity(vector_origin) phys:Wake() end
        end
        ScheduleRespawn(info)
    end)
end

local function SpawnWeaponDrop(class, pos, quality)
    local ent = ents.Create(class)
    if not IsValid(ent) then
        print("[Horde Unarmed] Failed to create: " .. tostring(class))
        return nil
    end
    ent:SetPos(pos)
    ent:SetAngles(Angle(0, math.random(0, 359), 0))
    ent:Spawn()
    ent:Activate()
    ent.Horde_UnarmedDrop = true
    ent:SetNWBool("Horde_UnarmedDrop", true)
    ent:SetNWString("Horde_UnarmedQuality", quality or "Common")
    local eid = ent:EntIndex()
    local info = { ent = ent, class = class, id = eid }
    active_drops[eid] = info
    ScheduleRespawn(info)
    ent:CallOnRemove("Horde_UnarmedDropRemove", function() ForgetDrop(eid) end)
    return ent
end

local wave_spawn = nil

local function StopWaveSpawn()
    if timer.Exists(SPAWN_TIMER) then timer.Remove(SPAWN_TIMER) end
    wave_spawn = nil
end

function HORDE:Unarmed_SpawnStep()
    local state = wave_spawn
    if not HORDE.unarmed_mode or not state then
        StopWaveSpawn()
        return
    end
    if state.wave ~= HORDE.current_wave or state.spawned >= state.target then
        StopWaveSpawn()
        return
    end

    local class = PickWeaponClass(state.by_quality, state.all)
    local pos = FindSpawnPosition(state.taken, state.enemy_spawns)
    if not class or not pos then
        state.fails = (state.fails or 0) + 1
        if state.fails >= MAX_SPAWN_FAILS then StopWaveSpawn() end
        return
    end

    state.taken[#state.taken + 1] = pos
    local quality = ItemQuality(HORDE.items and HORDE.items[class])
    if SpawnWeaponDrop(class, pos, quality) then
        state.fails = 0
        state.spawned = state.spawned + 1
        if state.spawned == 1 then
            HORDE:SendNotification("Weapons have appeared on the map — go find them!", 0)
        end
    end
end

function HORDE:Unarmed_SpawnWaveWeapons()
    if not HORDE.unarmed_mode then return end
    StopWaveSpawn()
    ClearAllDrops()
    local by_quality, all = CollectWeaponClasses()
    if #all == 0 then
        print("[Horde Unarmed] No weapon classes found in HORDE.items!")
        return
    end
    BuildSpotPools()
    local target = math.min(MAX_DROPS, SPAWN_PER_PLAYER * math.max(1, player.GetCount()))
    wave_spawn = {
        target       = target,
        spawned      = 0,
        wave         = HORDE.current_wave,
        taken        = {},
        enemy_spawns = GetEnemySpawnPositions(),
        by_quality   = by_quality,
        all          = all,
    }
    print(string.format("[Horde Unarmed] Wave %s: spawning up to %d weapons, one per %g s",
        tostring(HORDE.current_wave), target, SPAWN_INTERVAL))

    HORDE:Unarmed_SpawnStep()
    timer.Create(SPAWN_TIMER, SPAWN_INTERVAL, 0, function()
        HORDE:Unarmed_SpawnStep()
    end)
end

function HORDE:Unarmed_OnPickup(wpn, ply)
    if IsValid(wpn) then ForgetDrop(wpn:EntIndex()) end
    local owner = ply
    if not IsValid(owner) then
        owner = IsValid(wpn) and wpn:GetOwner() or nil
    end
    if not IsValid(owner) or not owner:IsPlayer() then return end
    local class = IsValid(wpn) and wpn:GetClass() or nil
    if not class or class == "" then return end
    owner.Horde_UnarmedLooted = owner.Horde_UnarmedLooted or {}
    if not owner.Horde_UnarmedLooted[class] then
        owner.Horde_UnarmedLooted[class] = true
        HORDE:Unarmed_SyncLooted(owner)
    end
end

util.AddNetworkString("Horde_UnarmedSyncLooted")
function HORDE:Unarmed_SyncLooted(ply)
    if not IsValid(ply) then return end
    local looted = ply.Horde_UnarmedLooted or {}
    local list = {}
    for class, _ in pairs(looted) do
        list[#list + 1] = class
    end
    net.Start("Horde_UnarmedSyncLooted")
        net.WriteUInt(#list, 16)
        for _, class in ipairs(list) do
            net.WriteString(class)
        end
    net.Send(ply)
end

function HORDE:Unarmed_HasLooted(ply, class)
    if not IsValid(ply) or not class then return false end
    if not HORDE.unarmed_mode then return true end
    local looted = ply.Horde_UnarmedLooted
    return looted and looted[class] == true
end

hook.Add("HordeWaveStart", "Horde_Unarmed_WaveStart", function()
    if not HORDE.unarmed_mode then return end
    timer.Simple(0.5, function()
        if HORDE.unarmed_mode then HORDE:Unarmed_SpawnWaveWeapons() end
    end)
end)

hook.Add("HordeWaveEnd", "Horde_Unarmed_WaveEnd", function()
    StopWaveSpawn()
end)

local function IsKeptClass(class)
    return (HORDE.unarmed_kept_weapons and HORDE.unarmed_kept_weapons[class])
        or (HORDE.relic_weapon_subclass and HORDE.relic_weapon_subclass[class] ~= nil)
end

hook.Add("PlayerDroppedWeapon", "Horde_Unarmed_DropRemove", function(ply, wpn)
    if not HORDE.unarmed_mode or not IsValid(wpn) then return end
    if IsKeptClass(wpn:GetClass()) then return end
    ForgetDrop(wpn:EntIndex())
    timer.Simple(0, function()
        if IsValid(wpn) and not IsValid(wpn:GetOwner()) then wpn:Remove() end
        if IsValid(ply) then HORDE:WeightSync(ply) end
    end)
end)

hook.Add("CanSell", "Horde_Unarmed_NoSell", function(ply, class)
    if not HORDE.unarmed_mode or not IsValid(ply) then return end
    local wpn = ply:GetWeapon(class)
    if IsValid(wpn) and wpn.Horde_UnarmedLoot then
        return false, "You cannot sell scavenged weapons in Unarmed mode."
    end
end)

hook.Add("DoPlayerDeath", "Horde_Unarmed_DeathStrip", function(victim)
    if not HORDE.unarmed_mode or not IsValid(victim) then return end
    for _, wpn in ipairs(victim:GetWeapons()) do
        if IsValid(wpn) and not IsKeptClass(wpn:GetClass()) then
            victim:StripWeapon(wpn:GetClass())
        end
    end
end)

hook.Add("Horde_OnPlayerSelectClass", "Horde_Unarmed_ClassStrip", function(ply)
    if not HORDE.unarmed_mode or not IsValid(ply) then return end
    for _, wpn in ipairs(ply:GetWeapons()) do
        if IsValid(wpn) and not (HORDE.unarmed_kept_weapons and HORDE.unarmed_kept_weapons[wpn:GetClass()]) then
            ply:StripWeapon(wpn:GetClass())
        end
    end
end)

print("[Horde Unarmed] sv_unarmed_mode.lua loaded")

util.AddNetworkString("Horde_DropWeapon")

local function DropWeaponClass(ply, class)
    if not IsValid(ply) or not ply:Alive() then return end
    if not HORDE.unarmed_mode then
        if class and class ~= "" then
            local wpn = ply:GetWeapon(class)
            if IsValid(wpn) then ply:DropWeapon(wpn) end
        else
            local wpn = ply:GetActiveWeapon()
            if IsValid(wpn) then ply:DropWeapon(wpn) end
        end
        return
    end
    local function is_protected(wpn)
        if not IsValid(wpn) then return true end
        local c = wpn:GetClass()
        if HORDE.unarmed_kept_weapons and HORDE.unarmed_kept_weapons[c] then return true end
        if HORDE.relic_weapon_subclass and HORDE.relic_weapon_subclass[c] then return true end
        return false
    end
    if class and class ~= "" then
        local wpn = ply:GetWeapon(class)
        if not IsValid(wpn) then return end
        if is_protected(wpn) then
            HORDE:SendNotification("You cannot drop this weapon.", 1, ply)
            return
        end
        ply:DropWeapon(wpn)
    else
        local wpn = ply:GetActiveWeapon()
        if not IsValid(wpn) then return end
        if is_protected(wpn) then
            HORDE:SendNotification("You cannot drop this weapon.", 1, ply)
            return
        end
        ply:DropWeapon(wpn)
    end
end

net.Receive("Horde_DropWeapon", function(len, ply)
    if not IsValid(ply) then return end
    if not HORDE:AllowNetRequest(ply, "drop_weapon", 0.25) then return end
    local class = net.ReadString() or ""
    DropWeaponClass(ply, class)
end)

concommand.Add("horde_drop", function(ply, cmd, args)
    if not IsValid(ply) then return end
    local class = args and args[1] or ""
    DropWeaponClass(ply, class)
end)
