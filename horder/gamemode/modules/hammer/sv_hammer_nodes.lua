if not SERVER then return end
if not HORDE then return end

local NODE_ATTRIB_RADIUS = 128

local node_state = {}

function HORDE:Horde_ResetNodeState()
    node_state = {}
end

local function NodeState(id)
    local st = node_state[id]
    if not st then
        st = { spawned = 0, next_spawn = 0 }
        node_state[id] = st
    end
    return st
end

local function EnsureNodegraphNodes()
    if HORDE.nodegraph_nodes then return HORDE.nodegraph_nodes end
    if not isfunction(ParseFile) then
        HORDE.nodegraph_nodes = {}
        return HORDE.nodegraph_nodes
    end

    local saved_nodes   = HORDE.ai_nodes
    local saved_found   = HORDE.found_ai_nodes
    local saved_horde   = HORDE.found_horde_nodes
    local saved_attempt = HORDE._nodegraph_parse_attempted

    HORDE.ai_nodes = {}
    HORDE.found_ai_nodes = false
    HORDE._nodegraph_parse_attempted = nil
    ParseFile()
    HORDE.nodegraph_nodes = HORDE.ai_nodes or {}

    HORDE.ai_nodes = saved_nodes
    HORDE.found_ai_nodes = saved_found
    HORDE.found_horde_nodes = saved_horde
    HORDE._nodegraph_parse_attempted = saved_attempt or (#HORDE.nodegraph_nodes > 0)
    return HORDE.nodegraph_nodes
end

function HORDE:Horde_BuildNodeRecord(ent)
    local cfg = ent.Horde_Node or {}
    return {
        pos      = ent:GetPos() + Vector(0, 0, cfg.zoffset or 0),
        ent      = ent,
        id       = ent:EntIndex(),
        weight   = cfg.weight,
        group    = cfg.group,
        wave     = cfg.wave,
        lastwave = cfg.lastwave,
        max      = cfg.max,
        cooldown = cfg.cooldown,
        forced   = cfg.forced,
        zoffset  = cfg.zoffset,
    }
end

function HORDE:Horde_BuildBossNodeRecord(ent)
    local cfg = ent.Horde_Node or {}
    return {
        pos      = ent:GetPos() + Vector(0, 0, cfg.zoffset or 0),
        ent      = ent,
        id       = ent:EntIndex(),
        boss     = cfg.boss,
        group    = cfg.group,
        wave     = cfg.wave,
        lastwave = cfg.lastwave,
        weight   = cfg.weight,
        zoffset  = cfg.zoffset,
    }
end

function HORDE:IsNodeActive(node)
    if not istable(node) then return false end

    local ent = node.ent
    if ent ~= nil then
        if not IsValid(ent) then return false end
        if ent.Disabled then return false end
    end

    local wave = HORDE.current_wave or 0
    if wave > 0 then
        if node.wave and node.wave > 0 and wave < node.wave then return false end
        if node.lastwave and node.lastwave > 0 and wave > node.lastwave then return false end
    end

    if node.id then
        local st = node_state[node.id]
        if st then
            if node.max and node.max > 0 and (st.spawned or 0) >= node.max then return false end
            if node.cooldown and node.cooldown > 0 and (st.next_spawn or 0) > CurTime() then return false end
        end
    end
    return true
end

function HORDE:GetNodeWeight(node)
    if not istable(node) then return 0 end
    local w = tonumber(node.weight)
    if w == nil then return 1 end
    return math.max(0, math.floor(w))
end

function HORDE:Horde_IsSpawnNodeEnabled(ent)
    if ent == nil then return true end
    if not IsValid(ent) then return false end
    return not ent.Disabled
end

function HORDE:RecomputeSpawnNodes()
    local spawn_ents = ents.FindByClass("info_horde_enemy_spawn")

    HORDE.has_horde_spawn_entities = (#spawn_ents > 0)

    local records = {}
    for _, ent in ipairs(spawn_ents) do
        if IsValid(ent) and not ent.Disabled then
            records[#records + 1] = HORDE:Horde_BuildNodeRecord(ent)
        end
    end

    if HORDE.has_horde_spawn_entities then
        HORDE.ai_nodes = records
        HORDE.found_horde_nodes = true
        HORDE.found_ai_nodes = (#records > 0)
    else
        HORDE.ai_nodes = EnsureNodegraphNodes()
        HORDE.found_horde_nodes = false
        HORDE.found_ai_nodes = (#HORDE.ai_nodes > 0)
    end

    return HORDE.ai_nodes
end

function HORDE:RecomputeBossNodes()
    local records = {}
    for _, ent in ipairs(ents.FindByClass("info_horde_boss_spawn")) do
        if IsValid(ent) and not ent.Disabled then
            records[#records + 1] = HORDE:Horde_BuildBossNodeRecord(ent)
        end
    end

    HORDE.boss_nodes = records
    HORDE.boss_spawns = {}
    for _, rec in ipairs(records) do
        HORDE.boss_spawns[#HORDE.boss_spawns + 1] = rec.pos
    end
    return records
end

function HORDE:RecomputeAmmoboxNodes()
    HORDE.ammobox_nodes = {}
    for _, ent in ipairs(ents.FindByClass("info_horde_ammobox_spawn")) do
        if IsValid(ent) and not ent.Disabled then
            HORDE.ammobox_nodes[#HORDE.ammobox_nodes + 1] = ent:GetPos()
        end
    end
    return HORDE.ammobox_nodes
end

function HORDE:RecomputeMapNodes()
    HORDE:RecomputeSpawnNodes()
    HORDE:RecomputeBossNodes()
    HORDE:RecomputeAmmoboxNodes()
    return #(HORDE.ai_nodes or {})
end

local function NearestNodeTo(pos, nodes)
    if not pos or not nodes then return nil end
    local best, best_d2 = nil, nil
    for i = 1, #nodes do
        local node = nodes[i]
        if node.ent and node.pos then
            local d2 = node.pos:DistToSqr(pos)
            if best_d2 == nil or d2 < best_d2 then
                best, best_d2 = node, d2
            end
        end
    end
    if best and best_d2 and best_d2 <= (NODE_ATTRIB_RADIUS * NODE_ATTRIB_RADIUS) then
        return best
    end
    return nil
end

function HORDE:Horde_NotifyNodeSpawn(pos)
    local node = NearestNodeTo(pos, HORDE.ai_nodes)
    if not node or not node.id then return end
    local st = NodeState(node.id)
    st.spawned = (st.spawned or 0) + 1
    if node.cooldown and node.cooldown > 0 then
        st.next_spawn = CurTime() + node.cooldown
    end
end

if isfunction(HORDE.SpawnEnemy) and not HORDE._hammer_spawn_wrapped then
    HORDE._hammer_spawn_wrapped = true
    local base_spawn_enemy = HORDE.SpawnEnemy
    function HORDE:SpawnEnemy(enemy, pos)
        local spawned = base_spawn_enemy(self, enemy, pos)
        if IsValid(spawned) and pos then
            HORDE:Horde_NotifyNodeSpawn(pos)
        end
        return spawned
    end
end

function HORDE:Horde_IsBossNodeActive(node, boss_name)
    if not HORDE:IsNodeActive(node) then return false end
    if node.boss and node.boss ~= "" and boss_name then
        if string.upper(node.boss) ~= string.upper(tostring(boss_name)) then return false end
    end
    return true
end

function HORDE:Horde_GetBossSpawnPositions(boss_name)
    local out = {}
    for _, rec in ipairs(HORDE.boss_nodes or {}) do
        if HORDE:Horde_IsBossNodeActive(rec, boss_name) then
            out[#out + 1] = rec.pos
        end
    end
    return out
end

function HORDE:Horde_InitMapEntities()
    HORDE.spawned_enemies = {}
    HORDE.found_ai_nodes = false
    HORDE.found_horde_nodes = false

    HORDE:RecomputeSpawnNodes()
    HORDE:RecomputeBossNodes()
    HORDE:RecomputeAmmoboxNodes()

    HORDE.has_buy_zone = not table.IsEmpty(ents.FindByClass("trigger_horde_buyzone"))

    HORDE.spawn_distribution = HORDE.SPAWN_PROXIMITY
    if not table.IsEmpty(ents.FindByClass("info_horde_spawn_distribution_uniform")) then
        HORDE.spawn_distribution = HORDE.SPAWN_UNIFORM
    elseif not table.IsEmpty(ents.FindByClass("info_horde_spawn_distribution_proximity_noisy")) then
        HORDE.spawn_distribution = HORDE.SPAWN_PROXIMITY_NOISY
    end

    for _, ent in pairs(ents.FindByClass("logic_horde_economy")) do
        ent:KeyValue("startingmoney", ent:GetInternalVariable("startingmoney"))
        ent:KeyValue("killrewardbase", ent:GetInternalVariable("killrewardbase"))
        ent:KeyValue("roundbonusbase", ent:GetInternalVariable("roundbonusbase"))
    end

    HORDE:LoadObjectives()

    if #(HORDE.ai_nodes or {}) == 0 then
        print("[HORDE] Map has no spawn nodes (info_horde_enemy_spawn / .ain).")
    end
    print(string.format("[HORDE] Map entities: %d enemy node(s), %d boss node(s), %d ammobox node(s), distribution=%d",
        #(HORDE.ai_nodes or {}), #(HORDE.boss_nodes or {}), #(HORDE.ammobox_nodes or {}),
        HORDE.spawn_distribution or 0))
end

hook.Add("InitPostEntity", "Horde_Hammer_InitMapEntities", function()
    HORDE:Horde_InitMapEntities()
end)

hook.Add("HordeWaveStart", "Horde_Hammer_NodeStateReset", function()
    HORDE:Horde_ResetNodeState()
end)

function HORDE:AddAINode(pos)
    HORDE.ai_nodes = HORDE.ai_nodes or {}
    for _, node in ipairs(HORDE.ai_nodes) do
        if node.pos == pos then return end
    end
    HORDE.ai_nodes[#HORDE.ai_nodes + 1] = { pos = pos }
end

function HORDE:RemoveAINode(pos)
    HORDE.ai_nodes = HORDE.ai_nodes or {}
    for i = #HORDE.ai_nodes, 1, -1 do
        if HORDE.ai_nodes[i].pos == pos then
            table.remove(HORDE.ai_nodes, i)
        end
    end
end

function HORDE:AddBossNode(pos)
    HORDE.boss_spawns = HORDE.boss_spawns or {}
    for _, node_pos in ipairs(HORDE.boss_spawns) do
        if node_pos == pos then return end
    end
    HORDE.boss_spawns[#HORDE.boss_spawns + 1] = pos
end

function HORDE:RemoveBossNode(pos)
    HORDE.boss_spawns = HORDE.boss_spawns or {}
    for i = #HORDE.boss_spawns, 1, -1 do
        if HORDE.boss_spawns[i] == pos then
            table.remove(HORDE.boss_spawns, i)
        end
    end
end
