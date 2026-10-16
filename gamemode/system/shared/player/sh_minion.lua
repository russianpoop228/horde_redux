HORDE = HORDE or {}

HORDE.MinionKinds = HORDE.MinionKinds or {
    ["npc_turret_floor"]          = { turret = true },
    ["npc_vj_horde_sniper_turret"]= { turret = true },
    ["npc_vj_horde_shotgun_turret"]= { turret = true },
    ["npc_vj_horde_rocket_turret"]= { turret = true, physgun_straighten = true },
    ["npc_vj_horde_laser_turret"] = { turret = true, physgun_straighten = true },
    ["horde_watchtower"]          = { turret = true, structure = true },
    ["horde_engi_dispenser"]      = { turret = true, structure = true },
}

function HORDE:RegisterMinionKind(class, data)
    self.MinionKinds = self.MinionKinds or {}
    self.MinionKinds[class] = data or {}
end

function HORDE:GetMinionKind(ent)
    if not IsValid(ent) then return nil end
    return self.MinionKinds[ent:GetClass()]
end

function HORDE:IsTurretMinion(ent)
    if not IsValid(ent) then return false end
    local kind = self.MinionKinds[ent:GetClass()]
    if kind and kind.turret then return true end
    return ent.Horde_TurretMinion == true
end

local function RawOwner(ent)
    if not IsValid(ent) then return nil end
    local owner = ent:GetNWEntity("HordeOwner")
    if IsValid(owner) and owner:IsPlayer() then
        return owner
    end
    if SERVER then
        if IsValid(ent.Horde_Owner) and ent.Horde_Owner:IsPlayer() then
            return ent.Horde_Owner
        end
        local o = ent:GetOwner()
        if IsValid(o) and o:IsPlayer() then
            return o
        end
    end
    return nil
end

function HORDE:GetMinionOwner(ent)
    return RawOwner(ent)
end

function HORDE:IsMinion(ent)
    return RawOwner(ent) ~= nil
end

function HORDE:GetMapBuildableRelation(ent)
    if not IsValid(ent) then return nil end
    if not (self.IsMapBuildable and self:IsMapBuildable(ent)) then return nil end
    return ent.Horde_MapRelation
end

function HORDE:IsMinionOf(ent, ply)
    if not IsValid(ply) then return false end
    return RawOwner(ent) == ply
end

function HORDE:IsFriendlyUnit(ent)
    if not IsValid(ent) then return false end
    if ent:IsPlayer() then return ent:Alive() end
    local relation = self:GetMapBuildableRelation(ent)
    if relation ~= nil then
        return relation ~= (self.HammerRelation and self.HammerRelation.ENEMY)
    end
    return RawOwner(ent) ~= nil
end

function HORDE:IsEnemy(ent)
    if not IsValid(ent) then return false end
    if ent:IsPlayer() then return false end
    if not (ent:IsNPC() or ent:IsNextBot()) then return false end
    local relation = self:GetMapBuildableRelation(ent)
    if relation ~= nil then
        return relation == (self.HammerRelation and self.HammerRelation.ENEMY)
    end
    return RawOwner(ent) == nil
end

function HORDE:IsPlayerOrMinion(ent)
    return self:IsFriendlyUnit(ent)
end

function HORDE:IsPlayerMinion(ent)
    return self:IsMinion(ent)
end
