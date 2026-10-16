AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
ENT.CleanupPriority = 2

function ENT:Initialize()
    self:SetModel("models/props_combine/combine_light001b.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)

    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
        phys:EnableGravity(true)
        phys:SetMass(10)
    end

    self.Horde_NextThink = CurTime()
    self.Horde_Owner = self:GetNWEntity("HordeOwner")
    self.Horde_ThinkInterval = 30
    self.Horde_EnableShockwave = nil
    self.Horde_NextShockWave = CurTime()
    self.Horde_ShockwaveInterval = 2
    self.Horde_WatchTower = true
    self.Horde_NextShockAttack = CurTime()
    self.Horde_ShockAttackInterval = 1
    self:SetColor(Color(0, 255, 0))
    self._BeaconReviving = false
    self._BeaconUsed = false

    if not HORDE:Horde_BuildableOwnerReady(self) then return end
    if HORDE:Horde_BuildableHasPerk(self, "warden_restock") then
        self.Horde_ThinkInterval = 15
    end

    if HORDE:Horde_BuildableHasPerk(self, "warden_rejection_pulse") then
        self.Horde_EnableShockwave = true
    end

    if HORDE:Horde_BuildableHasPerk(self, "warden_ex_machina") then
        timer.Simple(0.1, function()
            if IsValid(self) then self:Horde_AddWardenAura() end
        end)
    end

    local hook_id = "Horde_BeaconRevive_" .. self:EntIndex()
    self._BeaconDeathHook = hook_id
    hook.Add("PlayerDeath", hook_id, function(victim)
        if not IsValid(self) then
            hook.Remove("PlayerDeath", hook_id)
            return
        end
        local owner = self.Horde_Owner or self:GetNWEntity("HordeOwner")
        if victim ~= owner then return end
        self:Horde_BeaconScheduleRevive(victim)
    end)
    hook.Add("PlayerSilentDeath", hook_id .. "_Silent", function(victim)
        if not IsValid(self) then
            hook.Remove("PlayerSilentDeath", hook_id .. "_Silent")
            return
        end
        local owner = self.Horde_Owner or self:GetNWEntity("HordeOwner")
        if victim ~= owner then return end
        self:Horde_BeaconScheduleRevive(victim)
    end)

    self:CallOnRemove("Horde_BeaconReviveCleanup", function(ent)
        if ent._BeaconDeathHook then
            hook.Remove("PlayerDeath", ent._BeaconDeathHook)
            hook.Remove("PlayerSilentDeath", ent._BeaconDeathHook .. "_Silent")
        end
    end)
end

function ENT:Horde_BeaconCanRevive()
    if self._BeaconReviving then return true end
    if self._BeaconUsed then return false end
    if not self._BeaconDeathHook then return false end
    local owner = self.Horde_Owner
    if not IsValid(owner) or not owner:IsPlayer() then return false end
    if owner:Alive() or owner:Team() == TEAM_SPECTATOR then return false end
    if not HORDE.start_game or (HORDE.current_break_time or 0) > 0 then return false end
    return true
end

hook.Add("Horde_OnPlayerShouldRespawnDuringWave", "Horde_BeaconRespawnAllowed", function(ply)
    if IsValid(ply) and ply.Horde_BeaconRespawning then return true end
end)

function ENT:Horde_BeaconScheduleRevive(ply)
    if not SERVER then return end
    if self._BeaconUsed or self._BeaconReviving then return end
    if not IsValid(ply) then return end
    if not HORDE.start_game or (HORDE.current_break_time or 0) > 0 then return end

    self._BeaconReviving = true
    self._BeaconUsed = true

    timer.Simple(0.75, function()
        if not IsValid(self) then return end
        self:Horde_BeaconResurrect(ply)
    end)
end

function ENT:Horde_BeaconResurrect(ply)
    if not SERVER then return end
    if not IsValid(ply) then
        self._BeaconReviving = false
        self:Horde_BeaconDestroySelf()
        timer.Simple(0, function() HORDE:CheckAlivePlayers() end)
        return
    end
    if ply:Alive() then
        self._BeaconReviving = false
        self:Horde_BeaconDestroySelf()
        return
    end
    if ply:Team() == TEAM_SPECTATOR then
        self._BeaconReviving = false
        self:Horde_BeaconDestroySelf()
        timer.Simple(0, function() HORDE:CheckAlivePlayers() end)
        return
    end

    local pos = self:GetPos() + Vector(0, 0, 16)
    local ang = Angle(0, self:GetAngles().y, 0)

    local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
    local tr = util.TraceHull({
        start  = pos + Vector(0, 0, 16),
        endpos = pos,
        mins   = mins,
        maxs   = maxs,
        filter = {self, ply},
        mask   = MASK_PLAYERSOLID,
    })
    if tr.Hit then
        local found = false
        for r = 32, 96, 32 do
            for a = 0, 315, 45 do
                local test = pos + Vector(math.cos(math.rad(a)) * r, math.sin(math.rad(a)) * r, 8)
                local tr2 = util.TraceHull({
                    start  = test + Vector(0, 0, 32),
                    endpos = test,
                    mins   = mins,
                    maxs   = maxs,
                    filter = {self, ply},
                    mask   = MASK_PLAYERSOLID,
                })
                if not tr2.Hit then
                    pos = test
                    found = true
                    break
                end
            end
            if found then break end
        end
    end

    ply.Horde_BeaconRespawning = true
    ply:Spawn()
    ply.Horde_BeaconRespawning = nil

    if IsValid(ply) then
        ply:SetPos(pos)
        ply:SetAngles(ang)
        ply:SetVelocity(vector_origin)
        ply:SetObserverMode(OBS_MODE_NONE)
        ply:UnSpectate()

        if ply.Horde_SetGivenStarterWeapons then
            ply:Horde_SetGivenStarterWeapons(nil)
        end
        if HORDE and HORDE.GiveStarterWeapons then
            HORDE:GiveStarterWeapons(ply)
        end

        sound.Play("horde/gadgets/heal_beam.ogg", pos, 75, 100)
        if HORDE and HORDE.SendNotification then
            HORDE:SendNotification("Beacon Watchtower: you have been respawned.", 0, ply)
        end
    end

    self._BeaconReviving = false
    self:Horde_BeaconDestroySelf()
end

function ENT:Horde_BeaconDestroySelf()
    if not IsValid(self) then return end
    if self.Horde_Expiring then return end
    if self.Horde_ExpireConsumable then
        self:Horde_ExpireConsumable()
    else
        self:Remove()
    end
end

function ENT:Think()
    if not HORDE:Horde_BuildableOwnerReady(self) then return end
    if HORDE:Horde_BuildableIsSubclass(self, "Overlord") then return end
    if CurTime() >= self.Horde_NextThink + self.Horde_ThinkInterval then
        if SERVER then
            if HORDE:Horde_GetBuildableOwner(self) then
                hook.Run("Horde_WardenWatchtower", HORDE:Horde_GetBuildableOwner(self), self)
            end
        end
        self.Horde_NextThink = CurTime()
    end

    if self.Horde_EnableShockwave then
        if CurTime() >= self.Horde_NextShockWave + self.Horde_ShockwaveInterval then
            local dmg = DamageInfo()
            HORDE:Horde_BuildableApplyAttacker(dmg, self)
            dmg:SetInflictor(self)
            dmg:SetDamageType(DMG_SHOCK)
            dmg:SetDamage(50)
            local e = EffectData()
            e:SetOrigin(self:GetPos())
            util.Effect("explosion_shock", e, true, true)
            util.BlastDamageInfo(dmg, self:GetPos(), 160)
            self.Horde_NextShockWave = CurTime()
        end
    end
end
