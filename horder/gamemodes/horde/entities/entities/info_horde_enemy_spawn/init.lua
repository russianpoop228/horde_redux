ENT.Type = "point"

local function EnsureNode(ent)
    ent.Horde_Node = ent.Horde_Node or {}
    return ent.Horde_Node
end

local function RefreshNodes()
    if HORDE and HORDE.RecomputeSpawnNodes then
        HORDE:RecomputeSpawnNodes()
    end
end

function ENT:Initialize()
end

function ENT:KeyValue(key, value)
    key = string.lower(key)
    local node = EnsureNode(self)

    if key == "disabled" then
        self.Disabled = HORDE:Horde_KeyBool(value, false)
    elseif key == "active" then
        self.Disabled = not HORDE:Horde_KeyBool(value, true)
    elseif key == "weight" then
        node.weight = math.max(0, HORDE:Horde_KeyNumber(value, 1))
    elseif key == "group" then
        node.group = HORDE:Horde_KeyNumber(value, 0)
    elseif key == "wave" then
        node.wave = HORDE:Horde_KeyNumber(value, 0)
    elseif key == "lastwave" then
        node.lastwave = HORDE:Horde_KeyNumber(value, 0)
    elseif key == "max" then
        node.max = math.max(0, HORDE:Horde_KeyNumber(value, 0))
    elseif key == "cooldown" then
        node.cooldown = math.max(0, HORDE:Horde_KeyNumber(value, 0))
    elseif key == "forced" then
        node.forced = HORDE:Horde_KeyBool(value, false)
    elseif key == "zoffset" then
        node.zoffset = HORDE:Horde_KeyNumber(value, 0)
    end
end

function ENT:AcceptInput(name, activator, caller, arg)
    name = string.lower(name)
    if name == "enable" or name == "unhide" then
        self.Disabled = false
        RefreshNodes()
        return true
    elseif name == "disable" or name == "hide" then
        self.Disabled = true
        RefreshNodes()
        return true
    elseif name == "toggle" then
        self.Disabled = not self.Disabled
        RefreshNodes()
        return true
    end
end
