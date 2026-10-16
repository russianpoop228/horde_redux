ENT.Type = "point"

local function EnsureCfg(ent)
    ent.Horde_TokenCfg = ent.Horde_TokenCfg or {}
    return ent.Horde_TokenCfg
end

function ENT:Initialize()
    if not SERVER then return end
    local cfg = EnsureCfg(self)
    if cfg.spawn_on_start == true then
        self:Horde_ScheduleSpawn()
    end
end

function ENT:Horde_ScheduleSpawn()
    if self.Horde_SpawnPending then return end
    self.Horde_SpawnPending = true
    timer.Simple(0, function()
        if not IsValid(self) then return end
        self.Horde_SpawnPending = nil
        self:Horde_SpawnToken()
    end)
end

function ENT:Horde_SpawnToken()
    local cfg = EnsureCfg(self)
    local ent, err = HORDE:Horde_SpawnMapToken(cfg.token, self:GetPos(), self:GetAngles(), {
        amount   = cfg.amount,
        lifetime = cfg.lifetime,
    })
    if not ent then
        print("[HORDE] info_horde_token_spawn: " .. tostring(err))
        return false
    end
    self.Horde_SpawnedToken = ent
    self:TriggerOutput("onspawn", ent)
    return true
end

function ENT:Horde_KillToken()
    if IsValid(self.Horde_SpawnedToken) then
        self.Horde_SpawnedToken:Remove()
    end
    self.Horde_SpawnedToken = nil
end

function ENT:KeyValue(key, value)
    key = string.lower(key)
    local cfg = EnsureCfg(self)

    if key == "onspawn" then
        self:StoreOutput(key, value)
        return
    end

    if key == "token" or key == "type" or key == "kind" then
        cfg.token = HORDE:Horde_ParseHammerToken(value, HORDE.HammerToken.MONEY)
    elseif key == "amount" or key == "value" then
        local n = HORDE:Horde_KeyNumber(value, nil)
        cfg.amount = (n and n > 0) and n or nil
    elseif key == "lifetime" then
        cfg.lifetime = HORDE:Horde_KeyNumber(value, nil)
    elseif key == "spawn_on_start" then
        cfg.spawn_on_start = HORDE:Horde_KeyBool(value, false)
    elseif key == "disabled" then
        cfg.disabled = HORDE:Horde_KeyBool(value, false)
    elseif key == "active" then
        cfg.disabled = not HORDE:Horde_KeyBool(value, true)
    end
end

function ENT:AcceptInput(name, activator, caller, arg)
    name = string.lower(name)
    local cfg = EnsureCfg(self)

    if name == "spawn" then
        self:Horde_SpawnToken()
        return true
    elseif name == "kill" or name == "remove" then
        self:Horde_KillToken()
        return true
    elseif name == "setamount" then
        local n = HORDE:Horde_KeyNumber(arg, nil)
        if n and n > 0 then cfg.amount = n end
        return true
    elseif name == "enable" or name == "unhide" then
        cfg.disabled = false
        return true
    elseif name == "disable" or name == "hide" then
        cfg.disabled = true
        return true
    elseif name == "toggle" then
        cfg.disabled = not cfg.disabled
        return true
    end
    return false
end

function ENT:OnRemove()
    self:Horde_KillToken()
end
