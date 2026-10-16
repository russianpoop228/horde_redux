if SERVER then
    util.AddNetworkString("Horde_SyncObjectiveBar")
end

HORDE.OBJ_BAR_START    = 0
HORDE.OBJ_BAR_PROGRESS = 1
HORDE.OBJ_BAR_END      = 2
HORDE.OBJ_BAR_CLEAR    = 3

if SERVER then

HORDE.objective_bars = {}

function HORDE:CalcEscapeProgress()
    local escape = HORDE.horde_active_escapezones
    if not escape or not next(escape) then return 0 end

    local at_exit = 0
    for _, zone in pairs(escape) do
        if IsValid(zone) and zone.Horde_Players_In_Zone then
            for _, ply in pairs(zone.Horde_Players_In_Zone) do
                if IsValid(ply) and ply:Alive() then at_exit = at_exit + 1 end
            end
        end
    end

    local alive = 0
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then alive = alive + 1 end
    end
    return (alive > 0) and math.Clamp(at_exit / alive * 100, 0, 100) or 0
end

function HORDE:GetActiveObjectiveBars()
    local bars = {}

    for _, set in ipairs(HORDE.horde_objectives or {}) do
        if not set.finished then
            bars[set.id] = {
                kind     = set.kind,
                label    = set.label or "",
                progress = HORDE:CalcObjectiveSetProgress(set),
            }
        end
    end

    if HORDE.horde_active_escapezones then
        bars[HORDE.OBJ_BAR_ESCAPE_ID] = {
            kind     = HORDE.OBJECTIVE_ESCAPE,
            label    = "",
            progress = HORDE:CalcEscapeProgress(),
        }
    end

    return bars
end

function HORDE:EndObjectiveBar()
    if not next(HORDE.objective_bars) then return end
    HORDE.objective_bars = {}
    net.Start("Horde_SyncObjectiveBar")
        net.WriteUInt(HORDE.OBJ_BAR_CLEAR, 2)
    net.Broadcast()
end

function HORDE:RefreshObjectiveBar()
    local current = HORDE:GetActiveObjectiveBars()
    local bars = HORDE.objective_bars

    for id in pairs(bars) do
        if not current[id] then
            bars[id] = nil
            net.Start("Horde_SyncObjectiveBar")
                net.WriteUInt(HORDE.OBJ_BAR_END, 2)
                net.WriteUInt(id, 4)
            net.Broadcast()
        end
    end

    for id, data in pairs(current) do
        local prev = bars[id]
        if not prev then
            bars[id] = data
            net.Start("Horde_SyncObjectiveBar")
                net.WriteUInt(HORDE.OBJ_BAR_START, 2)
                net.WriteUInt(id, 4)
                net.WriteUInt(data.kind, 3)
                net.WriteString(data.label)
                net.WriteFloat(data.progress)
            net.Broadcast()
        elseif prev.kind ~= data.kind or prev.label ~= data.label then
            bars[id] = data
            net.Start("Horde_SyncObjectiveBar")
                net.WriteUInt(HORDE.OBJ_BAR_START, 2)
                net.WriteUInt(id, 4)
                net.WriteUInt(data.kind, 3)
                net.WriteString(data.label)
                net.WriteFloat(data.progress)
            net.Broadcast()
        elseif math.abs(prev.progress - data.progress) >= 0.05 then
            prev.progress = data.progress
            net.Start("Horde_SyncObjectiveBar")
                net.WriteUInt(HORDE.OBJ_BAR_PROGRESS, 2)
                net.WriteUInt(id, 4)
                net.WriteFloat(data.progress)
            net.Broadcast()
        end
    end
end

function HORDE:SendObjectiveBar(ply)
    if not IsValid(ply) then return end
    for id, data in pairs(HORDE:GetActiveObjectiveBars()) do
        net.Start("Horde_SyncObjectiveBar")
            net.WriteUInt(HORDE.OBJ_BAR_START, 2)
            net.WriteUInt(id, 4)
            net.WriteUInt(data.kind, 3)
            net.WriteString(data.label)
            net.WriteFloat(data.progress)
        net.Send(ply)
    end
end

hook.Add("PlayerInitialSpawn", "Horde_ObjectiveBar_Sync", function(ply)
    if not next(HORDE.objective_bars) then return end
    timer.Simple(1, function()
        if IsValid(ply) then HORDE:SendObjectiveBar(ply) end
    end)
end)

timer.Create("Horde_ObjectiveBarWatch", 0.25, 0, function()
    if HORDE.game_end then
        HORDE:EndObjectiveBar()
        return
    end
    if not next(HORDE.objective_bars) and not HORDE.horde_has_active_objective then return end
    HORDE:RefreshObjectiveBar()
end)

end
