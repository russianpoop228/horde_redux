ENT.Type = "point"

local function EnsureCfg(ent)
    ent.Horde_BuildCfg = ent.Horde_BuildCfg or {}
    return ent.Horde_BuildCfg
end

function ENT:Initialize()
    if not SERVER then return end
    local cfg = EnsureCfg(self)
    if cfg.spawn_on_start ~= false then
        self:Horde_ScheduleSpawn()
    end
end

function ENT:Horde_ScheduleSpawn()
    if self.Horde_SpawnPending then return end
    self.Horde_SpawnPending = true
    timer.Simple(0, function()
        if not IsValid(self) then return end
        self.Horde_SpawnPending = nil
        self:Horde_Spawn()
    end)
end

function ENT:Horde_Spawn()
    local cfg = EnsureCfg(self)
    if not cfg.buildable or cfg.buildable == "" then
        print("[HORDE] info_horde_buildable: 'Buildable' property is not set")
        return false
    end

    if IsValid(self.Horde_SpawnedBuildable) then
        self.Horde_SpawnedBuildable:Remove()
    end

    local ent, err = HORDE:Horde_SpawnMapBuildable(cfg.buildable, self:GetPos(), self:GetAngles(), {
        health        = cfg.health,
        ammo          = cfg.ammo,
        infinite_ammo = cfg.infinite_ammo,
        relationship  = cfg.relationship,
        level         = cfg.level,
        spawner       = self,
    })
    if not ent then
        print("[HORDE] info_horde_buildable: " .. tostring(err))
        return false
    end

    self.Horde_SpawnedBuildable = ent
    self:TriggerOutput("onspawn", ent)
    return true
end

function ENT:Horde_Kill()
    if not IsValid(self.Horde_SpawnedBuildable) then return false end
    self.Horde_SpawnedBuildable:Remove()
    self.Horde_SpawnedBuildable = nil
    return true
end

function ENT:KeyValue(key, value)
    key = string.lower(key)
    local cfg = EnsureCfg(self)

    if key == "onspawn" then
        self:StoreOutput(key, value)
        return
    end

    if key == "buildable" or key == "class" or key == "classname" then
        cfg.buildable = value
    elseif key == "health" then
        cfg.health = HORDE:Horde_KeyNumber(value, 0)
    elseif key == "ammo" then
        local n = HORDE:Horde_KeyNumber(value, nil)
        cfg.ammo = (n and n > 0) and n or nil
    elseif key == "infinite_ammo" then
        cfg.infinite_ammo = HORDE:Horde_KeyBool(value, false)
    elseif key == "relationship" or key == "relation" then
        cfg.relationship = HORDE:Horde_ParseHammerRelation(value, HORDE.HammerRelation.FRIENDLY)
    elseif key == "level" or key == "upgrade" then
        cfg.level = HORDE:Horde_KeyNumber(value, 0)
    elseif key == "spawn_on_start" then
        cfg.spawn_on_start = HORDE:Horde_KeyBool(value, true)
    elseif key == "disabled" then
        local off = HORDE:Horde_KeyBool(value, false)
        cfg.spawn_on_start = not off
    elseif key == "active" then
        cfg.spawn_on_start = HORDE:Horde_KeyBool(value, true)
    end
end

function ENT:AcceptInput(name, activator, caller, arg)
    name = string.lower(name)
    local cfg = EnsureCfg(self)

    if name == "spawn" then
        self:Horde_Spawn()
        return true
    elseif name == "kill" or name == "remove" then
        self:Horde_Kill()
        return true
    elseif name == "sethealth" then
        cfg.health = HORDE:Horde_KeyNumber(arg, cfg.health)
        if IsValid(self.Horde_SpawnedBuildable) then
            HORDE:Horde_SetMapBuildableHealth(self.Horde_SpawnedBuildable, cfg.health)
        end
        return true
    elseif name == "setammo" then
        cfg.ammo = HORDE:Horde_KeyNumber(arg, cfg.ammo)
        cfg.infinite_ammo = false
        if IsValid(self.Horde_SpawnedBuildable) then
            HORDE:Horde_SetMapBuildableAmmo(self.Horde_SpawnedBuildable, cfg.ammo)
        end
        return true
    elseif name == "setrelationship" then
        cfg.relationship = HORDE:Horde_ParseHammerRelation(arg, cfg.relationship)
        if IsValid(self.Horde_SpawnedBuildable) then
            HORDE:Horde_ApplyMapBuildableRelation(self.Horde_SpawnedBuildable, cfg.relationship)
        end
        return true
    elseif name == "enable" or name == "unhide" then
        cfg.spawn_on_start = true
        self:Horde_Spawn()
        return true
    elseif name == "disable" or name == "hide" then
        cfg.spawn_on_start = false
        self:Horde_Kill()
        return true
    elseif name == "toggle" then
        cfg.spawn_on_start = not cfg.spawn_on_start
        if cfg.spawn_on_start then
            self:Horde_Spawn()
        else
            self:Horde_Kill()
        end
        return true
    end
    return false
end

function ENT:OnRemove()
    self:Horde_Kill()
end
