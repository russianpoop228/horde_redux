local plymeta = FindMetaTable("Player")

function plymeta:Horde_AddHysteriaStack()
    if not self:IsValid() or not self:IsPlayer() then return end
    if self:Horde_GetHysteriaStack() < self:Horde_GetMaxHysteriaStack() then
        self.Horde_HysteriaStack = self.Horde_HysteriaStack + 1
    end

    local id = self:SteamID()
    timer.Remove("Horde_HysteriaTracker" .. id)
    timer.Create("Horde_HysteriaTracker" .. id, self:Horde_GetHysteriaStackDuration(), 1, function()
        if not self:IsValid() then return end
        self:Horde_RemoveHysteriaStack()
    end)

    net.Start("Horde_SyncStatus")
        net.WriteUInt(HORDE.Status_Hysteria, 8)
        net.WriteUInt(self.Horde_HysteriaStack, 8)
    net.Send(self)
end

function plymeta:Horde_RemoveHysteriaStack()
    if not self:IsValid() then return end
    if self:Horde_GetHysteriaStack() <= 0 then return end
    self.Horde_HysteriaStack = math.max(0, self.Horde_HysteriaStack - 1)

    net.Start("Horde_SyncStatus")
        net.WriteUInt(HORDE.Status_Hysteria, 8)
        net.WriteUInt(self.Horde_HysteriaStack, 8)
    net.Send(self)
    local id = self:SteamID()
    timer.Create("Horde_HysteriaTracker" .. id, self:Horde_GetHysteriaStackDuration(), 1, function()
        self:Horde_RemoveHysteriaStack()
        self.Horde_HysteriaGainedRecently = 0
    end)
end

function plymeta:Horde_GetHysteriaStack()
    return self.Horde_HysteriaStack or 0
end

function plymeta:Horde_GetMaxHysteriaStack()
    return 5
end

function plymeta:Horde_GetHysteriaStackDuration()
    return 5
end
function plymeta:Horde_GetHysteriaEnabled()
    return self.Horde_HysteriaEnabled
end

hook.Add("Horde_OnPlayerDebuffApply", "Horde_HysteriaBuildupResist", function (ply, debuff, bonus, inflictor)
    if ply:Horde_GetHysteriaStack() > 0 then
        bonus.less = bonus.less * math.max(0, (1 - (0.1 * ply:Horde_GetHysteriaStack())))
    end
end)

hook.Add("Horde_ResetStatus", "Horde_HysteriaReset", function(ply)
    ply.Horde_HysteriaStack = 0
    ply.Horde_HysteriaGainedRecently = 0
end)
