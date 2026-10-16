ENT.Type = "point"

function ENT:Initialize()
    if not SERVER then return end
    self.Horde_DiffCfg = self.Horde_DiffCfg or {}
    if HORDE and HORDE.Horde_RegisterDifficultyEntity then
        HORDE:Horde_RegisterDifficultyEntity(self)
    end
end

function ENT:KeyValue(key, value)
    if HORDE and HORDE.Horde_SetDifficultyKeyValue then
        HORDE:Horde_SetDifficultyKeyValue(self, string.lower(key), value)
    end
end

function ENT:AcceptInput(name, activator, caller, arg)
    if not (HORDE and HORDE.Horde_DifficultyInput) then return end
    if HORDE:Horde_DifficultyInput(self, string.lower(name), arg) then
        return true
    end
end
