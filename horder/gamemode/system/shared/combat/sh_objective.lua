if SERVER then
util.AddNetworkString("Horde_SyncHoldProgress")
util.AddNetworkString("Horde_SyncHoldLocation")
util.AddNetworkString("Horde_SyncHoldEnd")

util.AddNetworkString("Horde_SyncPayloadIcon")
util.AddNetworkString("Horde_SyncPayloadLocation")
util.AddNetworkString("Horde_SyncPayloadDestinationLocation")
util.AddNetworkString("Horde_SyncPayloadSpawnEnd")
util.AddNetworkString("Horde_SyncPayloadEnd")

util.AddNetworkString("Horde_SyncEscapeStart")
util.AddNetworkString("Horde_SyncEscapeLocation")
util.AddNetworkString("Horde_SyncEscapeEnd")

util.AddNetworkString("Horde_RenderObjectives")
end

HORDE.OBJECTIVE_HOLD = 0
HORDE.OBJECTIVE_PAYLOAD = 1
HORDE.OBJECTIVE_ESCAPE = 2

HORDE.Objective_Icon = {
    [HORDE.OBJECTIVE_HOLD] = "status/hold.png",
    [HORDE.OBJECTIVE_PAYLOAD] = "status/objective.png",
    [HORDE.OBJECTIVE_ESCAPE] = "status/escape.png",
}

HORDE.Payload_Icon = {
    [0] = "status/objective.png",
    [1] = "status/payload/key.png",
    [2] = "status/payload/card.png",
    [3] = "status/payload/chemical.png",
}

HORDE.OBJECTIVE_MIXED = 3
HORDE.Objective_Icon[HORDE.OBJECTIVE_MIXED] = "status/objective.png"

HORDE.ZONE_SHAPE_BOX = 0
HORDE.ZONE_SHAPE_CYLINDER = 1

HORDE.OBJ_BAR_ESCAPE_ID = 15
HORDE.MAX_OBJECTIVE_SETS = 14

if SERVER then
local plymeta = FindMetaTable("Player")

function plymeta:Horde_SetEscape(can)
    self.Horde_EscapeProgress = can
    net.Start("Horde_SyncStatus")
        net.WriteUInt(HORDE.Status_CanEscape, 8)
        net.WriteUInt(can, 8)
    net.Send(self)
end

function plymeta:Horde_SetPayloadSpawn(payload)
    self.Horde_Payload_Spawn = payload
    HORDE:SendNotificationObjective(HORDE.OBJECTIVE_PAYLOAD, self:Name():sub(1,20) .. " picked up " .. (payload.Horde_Payload_Label or "the payload") .."!")
    sound.Play("horde/objective/gunpickup2.wav", self:GetPos())

    net.Start("Horde_SyncStatus")
        net.WriteUInt(HORDE.Status_HasPayload, 8)
        net.WriteUInt(1, 8)
    net.Send(self)
end

HORDE:AddPlayerTick("Horde_PayloadTrack", function(ply, mv)
    if not ply.Horde_Payload_Spawn then return end
    local now = CurTime()
    if (ply.Horde_PayloadNextSync or 0) > now then return end
    ply.Horde_PayloadNextSync = now + 0.1
    net.Start("Horde_SyncPayloadLocation")
        net.WriteUInt(ply.Horde_Payload_Spawn.Horde_Payload_Spawn_Id, 4)
        net.WriteVector(ply:GetPos())
    net.Broadcast()
end)

hook.Add("DoPlayerDeath", "Horde_DeathRemovePayload", function(victim)
    if victim:IsPlayer() and victim:Horde_HasPayload() then
        victim:Horde_LostPayload()
    end
end)

hook.Add("PlayerDisconnected", "Horde_DisconnectReturnPayload", function(ply)
    if IsValid(ply) and ply:Horde_HasPayload() then
        ply:Horde_LostPayload()
    end
end)

function plymeta:Horde_HasPayload()
    return self.Horde_Payload_Spawn
end

function plymeta:Horde_LostPayload()
    if not self.Horde_Payload_Spawn then return end
    self.Horde_Payload_Spawn:Horde_SpawnPayload()
    HORDE:SendNotificationObjective(HORDE.OBJECTIVE_PAYLOAD, self:Name():sub(1,20) .. " lost " .. (self.Horde_Payload_Spawn.Horde_Payload_Label or "the payload") .."!")
    self.Horde_Payload_Spawn = nil

    net.Start("Horde_SyncStatus")
        net.WriteUInt(HORDE.Status_HasPayload, 8)
        net.WriteUInt(0, 8)
    net.Send(self)
end

function plymeta:Horde_DeliverPayload()
    if not self.Horde_Payload_Spawn then return end
    HORDE:EndObjective(HORDE.OBJECTIVE_PAYLOAD, {spawn=self.Horde_Payload_Spawn})
    HORDE:SendNotificationObjective(HORDE.OBJECTIVE_PAYLOAD, self:Name():sub(1,20) .. " delivered " .. (self.Horde_Payload_Spawn.Horde_Payload_Label or "the payload") .."!")
    self.Horde_Payload_Spawn = nil
    sound.Play("horde/objective/fin" .. tonumber(math.random(1,3)) .. ".wav", self:GetPos())

    net.Start("Horde_SyncStatus")
        net.WriteUInt(HORDE.Status_HasPayload, 8)
        net.WriteUInt(0, 8)
    net.Send(self)
end

function HORDE:GetPayloadPosition(spawn)
    if not IsValid(spawn) then return nil end
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) and ply.Horde_Payload_Spawn == spawn then
            return ply:GetPos()
        end
    end
    local ent = spawn.Horde_SpawnedPayload
    if IsValid(ent) then return ent:GetPos() end
    return nil
end

function HORDE:GetPayloadDeliveryDistance(spawn)
    local pos = HORDE:GetPayloadPosition(spawn)
    if not pos then return nil end
    local best
    for _, dest in pairs(HORDE.horde_active_payload_destinations or {}) do
        if IsValid(dest) then
            local d = pos:Distance(dest:NearestPoint(pos))
            if not best or d < best then best = d end
        end
    end
    return best
end

function HORDE:LoadObjectives()
    HORDE.escape_zones = ents.FindByClass("trigger_horde_escapezone")
    HORDE.has_escape_zones = not table.IsEmpty(HORDE.escape_zones)

    local hold_zones = ents.FindByClass("trigger_horde_holdzone")
    if not table.IsEmpty(hold_zones) then
        HORDE.hold_zones = {}
        HORDE.hold_zones_all_waves = {}
        HORDE.has_hold_zones = true
        local next_zone_id = 0
        for _, hold_zone in pairs(hold_zones) do
            hold_zone.Horde_Zone_Id = next_zone_id
            next_zone_id = next_zone_id + 1
            if next_zone_id > 15 then
                ErrorNoHalt("[HORDE] trigger_horde_holdzone: more than 16 hold zones; extra ids wrap\n")
                next_zone_id = 0
            end
            if hold_zone.Horde_Active_Wave <= 0 then
                table.insert(HORDE.hold_zones_all_waves, hold_zone)
            else
                if not HORDE.hold_zones[hold_zone.Horde_Active_Wave] then
                    HORDE.hold_zones[hold_zone.Horde_Active_Wave] = {}
                end
                table.insert(HORDE.hold_zones[hold_zone.Horde_Active_Wave], hold_zone)
            end
        end
    end

    local payload_spawns = ents.FindByClass("info_horde_payload_spawn")
    if not table.IsEmpty(payload_spawns) then
        HORDE.payload_spawns = {}
        HORDE.payload_spawns_all_waves = {}
        HORDE.has_payload_spawns = true
        for _, spawn in pairs(payload_spawns) do
            if spawn.Horde_Active_Wave <= 0 then
                table.insert(HORDE.payload_spawns_all_waves, spawn)
            else
                if not HORDE.payload_spawns[spawn.Horde_Active_Wave] then
                    HORDE.payload_spawns[spawn.Horde_Active_Wave] = {}
                end
                table.insert(HORDE.payload_spawns[spawn.Horde_Active_Wave], spawn)
            end
        end
    end

    local payload_destinations = ents.FindByClass("trigger_horde_payload_destination")
    if not table.IsEmpty(payload_destinations) then
        HORDE.payload_destinations = {}
        HORDE.payload_destinations_all_waves = {}
        HORDE.has_payload_destinations = true
        for _, destination in pairs(payload_destinations) do
            if destination.Horde_Active_Wave <= 0 then
                table.insert(HORDE.payload_destinations_all_waves, destination)
            else
                if not HORDE.payload_destinations[destination.Horde_Active_Wave] then
                    HORDE.payload_destinations[destination.Horde_Active_Wave] = {}
                end
                table.insert(HORDE.payload_destinations[destination.Horde_Active_Wave], destination)
            end
        end
    end
end

function HORDE:GetEscapeZones()
    if not HORDE.has_escape_zones then return end
    local zones = {}
    if not table.IsEmpty(HORDE.escape_zones) then
        for _, zone in pairs(HORDE.escape_zones) do
            if not zone.Horde_Disabled then
                if not zones[zone.Horde_Zone_Group] then
                    zones[zone.Horde_Zone_Group] = {}
                end
                table.insert(zones[zone.Horde_Zone_Group], zone)
            end
        end
    end

    local final_zones = {}
    for group, zs in pairs(zones) do
        if #zs == 1 then
            final_zones[zs[1].Horde_Zone_Id] = zs[1]
        else
            local p = math.random(1, #zs)
            final_zones[zs[p].Horde_Zone_Id] = zs[p]
        end
    end
    return final_zones
end

function HORDE:GetWaveHoldZones(wave)
    local out = {}
    for _, zone in pairs(HORDE.hold_zones_all_waves or {}) do
        if not zone.Horde_Disabled then out[#out + 1] = zone end
    end
    for _, zone in pairs((HORDE.hold_zones or {})[wave] or {}) do
        if not zone.Horde_Disabled then out[#out + 1] = zone end
    end
    table.sort(out, function(a, b) return a:EntIndex() < b:EntIndex() end)
    return out
end

function HORDE:GetWavePayloadSpawns(wave)
    local out = {}
    for _, spawn in pairs(HORDE.payload_spawns_all_waves or {}) do
        if not spawn.Disabled then out[#out + 1] = spawn end
    end
    for _, spawn in pairs((HORDE.payload_spawns or {})[wave] or {}) do
        if not spawn.Disabled then out[#out + 1] = spawn end
    end
    table.sort(out, function(a, b) return a:EntIndex() < b:EntIndex() end)
    return out
end

function HORDE:GetWavePayloadDestinations(wave)
    local out = {}
    for _, dest in pairs(HORDE.payload_destinations_all_waves or {}) do
        if not dest.Disabled then out[#out + 1] = dest end
    end
    for _, dest in pairs((HORDE.payload_destinations or {})[wave] or {}) do
        if not dest.Disabled then out[#out + 1] = dest end
    end
    table.sort(out, function(a, b) return a:EntIndex() < b:EntIndex() end)
    return out
end

local function GroupBy(list, field)
    local groups, order = {}, {}
    for _, ent in ipairs(list) do
        local g = tonumber(ent[field]) or 0
        if not groups[g] then
            groups[g] = {}
            order[#order + 1] = g
        end
        table.insert(groups[g], ent)
    end
    table.sort(order)
    return groups, order
end

local function PickCandidates(list, combine)
    if combine or #list <= 1 then
        local out = {}
        for i, ent in ipairs(list) do out[i] = ent end
        return out
    end
    return { list[math.random(1, #list)] }
end

local function SameLabel(list, field)
    local label
    for _, ent in ipairs(list or {}) do
        local l = ent[field] or ""
        if label == nil then
            label = l
        elseif label ~= l then
            return nil
        end
    end
    return label
end

function HORDE:MakeObjectiveSetLabel(hold_list, payload_list)
    local hl = SameLabel(hold_list, "Horde_Zone_Label")
    local pl = SameLabel(payload_list, "Horde_Payload_Label")
    if hl and pl then return hl .. " + " .. pl end
    return hl or pl or ""
end

function HORDE:BuildObjectiveSets(wave)
    local sets = {}
    local zones  = HORDE:GetWaveHoldZones(wave)
    local spawns = HORDE:GetWavePayloadSpawns(wave)

    local linked_hold, linked_payload = {}, {}
    local plain_zones, plain_spawns = {}, {}
    for _, zone in ipairs(zones) do
        local link = tonumber(zone.Horde_Obj_Link) or 0
        if link > 0 then
            linked_hold[link] = linked_hold[link] or {}
            table.insert(linked_hold[link], zone)
        else
            plain_zones[#plain_zones + 1] = zone
        end
    end
    for _, spawn in ipairs(spawns) do
        local link = tonumber(spawn.Horde_Payload_Link) or 0
        if link > 0 then
            linked_payload[link] = linked_payload[link] or {}
            table.insert(linked_payload[link], spawn)
        else
            plain_spawns[#plain_spawns + 1] = spawn
        end
    end

    local link_list = {}
    for link in pairs(linked_hold) do link_list[#link_list + 1] = link end
    for link in pairs(linked_payload) do
        if not linked_hold[link] then link_list[#link_list + 1] = link end
    end
    table.sort(link_list)

    for _, link in ipairs(link_list) do
        local hz, ps = linked_hold[link], linked_payload[link]
        local kind = HORDE.OBJECTIVE_PAYLOAD
        if hz and ps then
            kind = HORDE.OBJECTIVE_MIXED
        elseif hz then
            kind = HORDE.OBJECTIVE_HOLD
        end
        sets[#sets + 1] = {
            kind    = kind,
            link    = link,
            hold    = hz or {},
            payload = ps or {},
            label   = HORDE:MakeObjectiveSetLabel(hz, ps),
        }
    end

    local run_hold, run_payload = true, true
    if #link_list == 0 and #plain_zones > 0 and #plain_spawns > 0 then
        if math.random() <= 0.5 then
            run_hold = false
        else
            run_payload = false
        end
    end

    if run_hold then
        local groups, order = GroupBy(plain_zones, "Horde_Zone_Group")
        for _, g in ipairs(order) do
            local list = groups[g]
            local combine = false
            for _, zone in ipairs(list) do
                if zone.Horde_Obj_Combine then combine = true break end
            end
            local picked = PickCandidates(list, combine)
            sets[#sets + 1] = {
                kind    = HORDE.OBJECTIVE_HOLD,
                hold    = picked,
                payload = {},
                label   = HORDE:MakeObjectiveSetLabel(picked, nil),
            }
        end
    end

    if run_payload then
        local groups, order = GroupBy(plain_spawns, "Horde_Payload_Spawn_Group")
        for _, g in ipairs(order) do
            local list = groups[g]
            local combine = false
            for _, spawn in ipairs(list) do
                if spawn.Horde_Payload_Combine then combine = true break end
            end
            local picked = PickCandidates(list, combine)
            sets[#sets + 1] = {
                kind    = HORDE.OBJECTIVE_PAYLOAD,
                hold    = {},
                payload = picked,
                label   = HORDE:MakeObjectiveSetLabel(nil, picked),
            }
        end
    end

    while #sets > HORDE.MAX_OBJECTIVE_SETS do
        table.remove(sets)
    end

    return sets
end

function HORDE:GetHoldZones(wave)
    if not HORDE.has_hold_zones then return end
    local zones = {}
    local total_progress = 90
    local groups = GroupBy(HORDE:GetWaveHoldZones(wave), "Horde_Zone_Group")

    local final_zones = {}
    for _, zs in pairs(groups) do
        local combine = false
        for _, zone in ipairs(zs) do
            if zone.Horde_Obj_Combine then combine = true break end
        end
        for _, zone in ipairs(PickCandidates(zs, combine)) do
            final_zones[zone.Horde_Zone_Id] = zone
        end
    end

    local count = table.Count(final_zones)
    if count == 0 then return final_zones end
    local progress = total_progress / count
    for _, zone in pairs(final_zones) do
        zone.Horde_Total_Progress = progress / count
    end

    return final_zones
end

function HORDE:GetPayloadSpawns(wave)
    if not HORDE.payload_spawns or not HORDE.has_payload_destinations then return end
    local final_payload_spawns = {}
    local groups = GroupBy(HORDE:GetWavePayloadSpawns(wave), "Horde_Payload_Spawn_Group")
    for _, list in pairs(groups) do
        local combine = false
        for _, spawn in ipairs(list) do
            if spawn.Horde_Payload_Combine then combine = true break end
        end
        for _, spawn in ipairs(PickCandidates(list, combine)) do
            final_payload_spawns[spawn.Horde_Payload_Spawn_Id] = spawn
        end
    end
    return final_payload_spawns
end

function HORDE:GetPayloadDestinations(wave)
    if not HORDE.payload_spawns or not HORDE.has_payload_destinations then return end
    local final_payload_destinations = {}
    local groups = GroupBy(HORDE:GetWavePayloadDestinations(wave), "Horde_Payload_Destination_Group")
    for _, list in pairs(groups) do
        local combine = false
        for _, dest in ipairs(list) do
            if dest.Horde_Payload_Combine then combine = true break end
        end
        for _, dest in ipairs(PickCandidates(list, combine)) do
            final_payload_destinations[dest.Horde_Payload_Destination_Id] = dest
        end
    end
    return final_payload_destinations
end

function HORDE:GetZoneShapeData(zone)
    local shape = tonumber(zone.Horde_Shape) or HORDE.ZONE_SHAPE_BOX
    local mins, maxs = zone:OBBMins(), zone:OBBMaxs()
    local center = zone:GetPos() + Vector(0, 0, (mins.z + maxs.z) * 0.5)
    local radius = tonumber(zone.Horde_Radius) or 0
    if radius <= 0 then
        radius = math.max(maxs.x - mins.x, maxs.y - mins.y) * 0.5
    end
    local height = math.max(0, maxs.z - mins.z)
    local custom_height = tonumber(zone.Horde_Height) or 0
    if shape == HORDE.ZONE_SHAPE_CYLINDER and custom_height > 0 then
        height = custom_height
    end
    return shape, center, radius, height
end

function HORDE:IsInsideZone(zone, pos)
    if not IsValid(zone) or not pos then return false end
    local shape, _, radius, height = HORDE:GetZoneShapeData(zone)
    local lp = zone:WorldToLocal(pos)
    local mins, maxs = zone:OBBMins(), zone:OBBMaxs()

    if shape == HORDE.ZONE_SHAPE_CYLINDER then
        local dz = lp.z - (mins.z + maxs.z) * 0.5
        if dz < -height * 0.5 or dz > height * 0.5 then return false end
        return lp.x * lp.x + lp.y * lp.y <= radius * radius
    end

    return lp.x >= mins.x and lp.x <= maxs.x
        and lp.y >= mins.y and lp.y <= maxs.y
        and lp.z >= mins.z and lp.z <= maxs.z
end

function HORDE:SyncHoldZoneProgress(id, progress)
    net.Start("Horde_SyncHoldProgress")
        net.WriteUInt(id, 4)
        net.WriteUInt(progress, 8)
    net.Broadcast()
    HORDE:RefreshObjectiveBar()
end

local function HasUnfinishedParts()
    local hold = HORDE.horde_active_holdzones
    if hold and not table.IsEmpty(hold) then return true end
    local payload = HORDE.horde_active_payload_spawns
    if payload and not table.IsEmpty(payload) then return true end
    return false
end

local function IsPartActive(set, kind, id)
    local list = (kind == HORDE.OBJECTIVE_HOLD) and HORDE.horde_active_holdzones
        or HORDE.horde_active_payload_spawns
    if not list then return false end
    return list[id] ~= nil
end

function HORDE:CalcObjectiveSetProgress(set)
    local total = #set.hold + #set.payload
    if total <= 0 then return 0 end

    local sum = 0
    for _, zone in ipairs(set.hold) do
        if IsPartActive(set, HORDE.OBJECTIVE_HOLD, zone.Horde_Zone_Id) then
            sum = sum + math.Clamp(tonumber(zone.Horde_Hold_Progress) or 0, 0, 100) / 100
        else
            sum = sum + 1
        end
    end

    for _, spawn in ipairs(set.payload) do
        if IsPartActive(set, HORDE.OBJECTIVE_PAYLOAD, spawn.Horde_Payload_Spawn_Id) then
            local dist = HORDE:GetPayloadDeliveryDistance(spawn)
            local start_dist = tonumber(spawn.Horde_Payload_Start_Distance) or 0
            if dist and start_dist > 0 then
                sum = sum + math.Clamp(1 - dist / start_dist, 0, 1)
            end
        else
            sum = sum + 1
        end
    end

    return math.Clamp(sum / total * 100, 0, 100)
end

function HORDE:UpdateObjectiveSets()
    for _, set in ipairs(HORDE.horde_objectives or {}) do
        if not set.finished then
            local done = true
            for _, zone in ipairs(set.hold) do
                if IsPartActive(set, HORDE.OBJECTIVE_HOLD, zone.Horde_Zone_Id) then done = false break end
            end
            if done then
                for _, spawn in ipairs(set.payload) do
                    if IsPartActive(set, HORDE.OBJECTIVE_PAYLOAD, spawn.Horde_Payload_Spawn_Id) then done = false break end
                end
            end
            set.finished = done or nil
        end
    end
    HORDE:RefreshObjectiveBar()
end

function HORDE:CheckObjectivesCompleted()
    if HasUnfinishedParts() then
        HORDE:UpdateObjectiveSets()
        return false
    end

    HORDE:UpdateObjectiveSets()
    HORDE.horde_has_active_objective = nil
    HORDE.horde_objectives = {}
    HORDE:EndObjectiveBar()
    HORDE:SendNotificationObjective(HORDE.OBJECTIVE_PAYLOAD, "All objectives have been completed!")
    HORDE:BroadcastEnemiesCountMessage(false,
        tostring(HORDE.current_wave) .. " / " .. tostring(HORDE.max_waves),
        HORDE.total_enemies_this_wave_fixed - HORDE.killed_enemies_this_wave)
    return true
end

function HORDE:StartObjectiveSets(wave)
    local sets = HORDE:BuildObjectiveSets(wave)

    local destinations
    if #sets > 0 then
        destinations = HORDE:GetPayloadDestinations(wave)
    end

    if next(sets) then
        local usable = {}
        for _, set in ipairs(sets) do
            if next(set.payload) and (not destinations or table.IsEmpty(destinations)) then
                set.payload = {}
                set.kind = next(set.hold) and HORDE.OBJECTIVE_HOLD or nil
                set.label = HORDE:MakeObjectiveSetLabel(set.hold, nil)
            end
            if next(set.hold) or next(set.payload) then
                usable[#usable + 1] = set
            end
        end
        sets = usable
    end

    HORDE.max_objs = 0
    HORDE.finished_objs = 0
    HORDE.horde_objectives = {}
    HORDE.horde_active_holdzones = nil
    HORDE.horde_active_payload_spawns = nil
    HORDE.horde_active_payload_destinations = nil

    if not next(sets) then
        HORDE.horde_has_active_objective = nil
        HORDE:EndObjectiveBar()
        return false
    end

    local hold_total = 0
    for _, set in ipairs(sets) do hold_total = hold_total + #set.hold end
    local per_zone_progress = 0
    if hold_total > 0 then
        per_zone_progress = (90 / hold_total) / hold_total
    end

    for idx, set in ipairs(sets) do
        set.id = idx
        HORDE.horde_objectives[idx] = set

        for _, zone in ipairs(set.hold) do
            zone.Horde_Obj_Set = set
            zone.Horde_Total_Progress = per_zone_progress
            HORDE.horde_active_holdzones = HORDE.horde_active_holdzones or {}
            HORDE.horde_active_holdzones[zone.Horde_Zone_Id] = zone
            zone:Horde_SetActivated(true)
            HORDE:StartObjective(HORDE.OBJECTIVE_HOLD, { zone = zone })
        end
    end

    local has_payload = false
    for _, set in ipairs(sets) do
        for _, spawn in ipairs(set.payload) do
            has_payload = true
            spawn.Horde_Obj_Set = set
            spawn.Horde_Activated = true
            HORDE.horde_active_payload_spawns = HORDE.horde_active_payload_spawns or {}
            HORDE.horde_active_payload_spawns[spawn.Horde_Payload_Spawn_Id] = spawn
            HORDE:StartObjective(HORDE.OBJECTIVE_PAYLOAD, { spawn = spawn })
        end
    end

    if has_payload and destinations and not table.IsEmpty(destinations) then
        HORDE.horde_active_payload_destinations = destinations
        for _, dest in pairs(destinations) do
            dest.Horde_Activated = true
            HORDE:StartPayloadDestination(dest)
        end
    end

    HORDE.horde_has_active_objective = true
    HORDE:RefreshObjectiveBar()
    return true
end

function HORDE:StartObjective(objective, param, ply)
    if objective == HORDE.OBJECTIVE_HOLD then
        local zone = param.zone
        local shape, _, radius = HORDE:GetZoneShapeData(zone)
        net.Start("Horde_SyncHoldLocation")
            net.WriteUInt(zone.Horde_Zone_Id, 4)
            net.WriteVector(zone:GetPos())
            net.WriteAngle(zone:GetAngles())
            net.WriteVector(zone:OBBMins())
            net.WriteVector(zone:OBBMaxs())
            net.WriteUInt(shape, 1)
            net.WriteFloat(radius)
        if ply then
            net.Send(ply)
        else
            net.Broadcast()
        end
        HORDE:SendNotificationObjective(HORDE.OBJECTIVE_HOLD, "Defend and hold " .. (zone.Horde_Zone_Label or "the area") .. "!")
        HORDE.max_objs = HORDE.max_objs + 1
    elseif objective == HORDE.OBJECTIVE_PAYLOAD then
        local spawn = param.spawn
        net.Start("Horde_SyncPayloadLocation")
            net.WriteUInt(spawn.Horde_Payload_Spawn_Id, 4)
            net.WriteVector(spawn:GetPos())
        if ply then
            net.Send(ply)
        else
            net.Broadcast()
        end

        net.Start("Horde_SyncPayloadIcon")
            net.WriteUInt(spawn.Horde_Payload_Spawn_Id, 4)
            net.WriteUInt(spawn.Horde_Payload_Icon, 4)
        if ply then
            net.Send(ply)
        else
            net.Broadcast()
        end

        spawn:Horde_SpawnPayload()
        spawn.Horde_Payload_Start_Distance = HORDE:GetPayloadDeliveryDistance(spawn) or 0
        HORDE:SendNotificationObjective(HORDE.OBJECTIVE_PAYLOAD, "Collect and deliver " .. (spawn.Horde_Payload_Label or "the payload") .. "!")
        HORDE.max_objs = HORDE.max_objs + 1
    elseif objective == HORDE.OBJECTIVE_ESCAPE then
        local zones = param.zones
        for _, zone in pairs(zones) do
            net.Start("Horde_SyncEscapeLocation")
            net.WriteUInt(zone.Horde_Zone_Id, 4)
            net.WriteVector(zone:GetPos())
            net.WriteVector(zone:OBBMins())
            net.WriteVector(zone:OBBMaxs())
            if ply then
                net.Send(ply)
            else
                net.Broadcast()
            end
        end
        net.Start("Horde_SyncEscapeStart")
        net.Broadcast()
        HORDE:SendNotificationObjective(HORDE.OBJECTIVE_ESCAPE, "Escape to the exit!")
        HORDE.max_objs = HORDE.max_objs + 1
        return
    end

    net.Start("Horde_RenderObjectives")
    net.WriteUInt(HORDE.finished_objs, 4)
    net.WriteUInt(HORDE.max_objs, 4)
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

function HORDE:StartPayloadDestination(dest, ply)
    net.Start("Horde_SyncPayloadDestinationLocation")
        net.WriteUInt(dest.Horde_Payload_Destination_Id, 4)
        net.WriteVector(dest:GetPos())
        net.WriteVector(dest:OBBMins())
        net.WriteVector(dest:OBBMaxs())
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

function HORDE:EndObjective(objective, param, ply)
    if objective == HORDE.OBJECTIVE_HOLD then
        local zone = param.zone
        net.Start("Horde_SyncHoldEnd")
        net.WriteUInt(zone.Horde_Zone_Id, 4)
        if ply then
            net.Send(ply)
        else
            net.Broadcast()
        end
        zone:TriggerOutput("OnCompleted", zone)

        HORDE.horde_active_holdzones[zone.Horde_Zone_Id] = nil
        HORDE.horde_has_active_objective = nil
        HORDE:SendNotificationObjective(HORDE.OBJECTIVE_PAYLOAD, "You have defended " .. (zone.Horde_Zone_Label or "the area") .."!")
        HORDE.finished_objs = HORDE.finished_objs + 1
        sound.Play("horde/objective/fin" .. tonumber(math.random(1,3)) .. ".wav", zone:GetPos())

        if table.IsEmpty(HORDE.horde_active_holdzones) then
            HORDE.horde_active_holdzones = nil
            if HORDE:CheckObjectivesCompleted() then return end
        end
    elseif objective == HORDE.OBJECTIVE_PAYLOAD then
        local spawn = param.spawn
        spawn:Horde_RemovePayload()
        net.Start("Horde_SyncPayloadSpawnEnd")
        net.WriteUInt(spawn.Horde_Payload_Spawn_Id, 4)
        if ply then
            net.Send(ply)
        else
            net.Broadcast()
        end
        spawn:TriggerOutput("OnCompleted", spawn)

        HORDE.horde_active_payload_spawns[spawn.Horde_Payload_Spawn_Id].Horde_Activated = nil
        HORDE.horde_active_payload_spawns[spawn.Horde_Payload_Spawn_Id] = nil
        HORDE.finished_objs = HORDE.finished_objs + 1
        if table.IsEmpty(HORDE.horde_active_payload_spawns) then
            for _, dest in pairs(HORDE.horde_active_payload_destinations or {}) do
                dest.Horde_Activated = nil
            end

            net.Start("Horde_SyncPayloadEnd")
            if ply then
                net.Send(ply)
            else
                net.Broadcast()
            end

            HORDE.horde_active_payload_spawns = nil
            HORDE.horde_has_active_objective = nil
            if HORDE:CheckObjectivesCompleted() then return end
        end
    end

    net.Start("Horde_RenderObjectives")
    net.WriteUInt(HORDE.finished_objs, 4)
    net.WriteUInt(HORDE.max_objs, 4)
    net.Broadcast()
end

end

function HORDE:ForceCompleteObjectives()
    if not SERVER then return end
    if HORDE.horde_active_holdzones then
        local zones = {}
        for id, zone in pairs(HORDE.horde_active_holdzones) do
            zones[#zones + 1] = zone
        end
        for _, zone in ipairs(zones) do
            if IsValid(zone) then
                HORDE:EndObjective(HORDE.OBJECTIVE_HOLD, { zone = zone })
            end
        end
    end
    if HORDE.horde_active_payload_spawns then
        local spawns = {}
        for id, spawn in pairs(HORDE.horde_active_payload_spawns) do
            spawns[#spawns + 1] = spawn
        end
        for _, spawn in ipairs(spawns) do
            if IsValid(spawn) then
                HORDE:EndObjective(HORDE.OBJECTIVE_PAYLOAD, { spawn = spawn })
            end
        end
    end
    HORDE.horde_has_active_objective = nil
    HORDE.horde_objectives = {}
    HORDE:EndObjectiveBar()
    HORDE.finished_objs = HORDE.max_objs or HORDE.finished_objs
    net.Start("Horde_RenderObjectives")
        net.WriteUInt(HORDE.finished_objs or 0, 4)
        net.WriteUInt(HORDE.max_objs or 0, 4)
    net.Broadcast()
end
