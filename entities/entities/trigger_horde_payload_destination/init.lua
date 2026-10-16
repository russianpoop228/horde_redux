ENT.Type = "brush"
ENT.LastThink = CurTime()

function ENT:Initialize()
    self.Horde_Activated = nil
    self.Horde_Payload_Destination_Id = self:GetCreationID()
end

function ENT:StartTouch(ent)
    if HORDE.game_end or not self.Horde_Activated or self.Disabled then return end
    if ent:IsPlayer() and ent:Horde_HasPayload() and ent:Alive() then
        ent:Horde_DeliverPayload()
        self:TriggerOutput("OnDelivered", ent)
    end
end

function ENT:KeyValue(key, value)
    key = string.lower(key)
    if key == "wave" then
        self.Horde_Active_Wave = tonumber(value) or -1
        if self.Horde_Active_Wave == -1 then
            self.Horde_Active_Wave = 0
        end
    elseif key == "group" then
        self.Horde_Payload_Destination_Group = tonumber(value) or 0
    elseif key == "combine" or key == "merge" then
        self.Horde_Payload_Combine = (tonumber(value) or 0) ~= 0
    elseif key == "disabled" then
        self.Disabled = (tonumber(value) or 0) ~= 0
    elseif key == "ondelivered" then
        self:StoreOutput(key, value)
    end
end

function ENT:AcceptInput(name, activator, caller, arg)
    if not SERVER then return end
    name = string.lower(name)
    if name == "enable" or name == "unhide" then
        self.Disabled = false
        return true
    elseif name == "disable" or name == "hide" then
        self.Disabled = true
        return true
    elseif name == "toggle" then
        self.Disabled = not self.Disabled
        return true
    end
end
