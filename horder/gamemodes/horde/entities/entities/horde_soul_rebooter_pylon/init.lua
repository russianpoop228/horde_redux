AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local CFG = HordeSoulRebooterConfig or {}
local START_HP    = CFG.BuildHealth      or 100
local START_TIME  = CFG.InitialTimer     or 40
local RESET_TIME  = CFG.DamageResetTimer or 5
local MODEL_PITCH = CFG.ModelPitchFix    or 0

ENT.Model = {"models/props_lab/tpplugholder_single.mdl"}
ENT.StartHealth = START_HP
ENT.SightDistance = 1
ENT.HullType = HULL_HUMAN
ENT.MovementType = VJ_MOVETYPE_STATIONARY
ENT.SightAngle = 0
ENT.LastSeenEnemyTimeUntilReset = 9999

ENT.VJ_NPC_Class = {"CLASS_PLAYER_ALLY", "CLASS_COMBINE"}
ENT.FriendlyMinion = true
ENT.PlayerFriendly = true
ENT.HasMeleeAttack = false
ENT.HasRangeAttack = false
ENT.RunAwayOnUnknownDamage = false
ENT.HasFootStepSound = false
ENT.HasSounds = false
ENT.DisableWandering = true
ENT.DisableChasingEnemy = true
ENT.FindEnemy_CanSeeThroughWalls = false
ENT.CanTurnWhileStationary = false
ENT.HasOnPlayerSight = false
ENT.HasDeathRagdoll = false
ENT.HasDeathAnimation = false
ENT.GodMode = false
ENT.Horde_NoPickup = true

function ENT:AlignToSoulAnchor()
    if not IsValid(self) or not self._SoulAnchorPos then return end

    local ang = self._SoulAnchorAng or Angle(MODEL_PITCH, 0, 0)
    self:SetAngles(ang)
    self:SetPos(self._SoulAnchorPos)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:Sleep()
    end
end

function ENT:CustomOnInitialize()
    self:SetMaxHealth(START_HP)
    self:SetHealth(START_HP)
    self:SetCollisionGroup(COLLISION_GROUP_PLAYER)

    local dieAt = CurTime() + START_TIME
    self:SetNWFloat("HordeSoulDieTime", dieAt)
    self._SoulDieTime = dieAt
    self._SoulRemoving = false

    timer.Simple(0, function() if IsValid(self) then self:AlignToSoulAnchor() end end)
    timer.Simple(0.1, function() if IsValid(self) then self:AlignToSoulAnchor() end end)
    timer.Simple(0.5, function() if IsValid(self) then self:AlignToSoulAnchor() end end)

    local id = "Horde_SoulRebooter_Pylon_" .. self:EntIndex()
    self._SoulTimerId = id
    timer.Create(id, 0.25, 0, function()
        if not IsValid(self) then
            timer.Remove(id)
            return
        end
        self:SoulThink()
    end)
end

function ENT:DoRelationshipCheck(ent)
    if not IsValid(ent) then return false end
    if ent:IsPlayer() then return false end
    if ent:GetNWEntity("HordeOwner") == self:GetNWEntity("HordeOwner") then return false end
    return true
end

function ENT:Use(ply) end

function ENT:ResetSoulTimer()
    local remaining = math.max(0, (self._SoulDieTime or CurTime()) - CurTime())
    remaining = math.min(START_TIME, remaining + RESET_TIME)

    local dieAt = CurTime() + remaining
    self._SoulDieTime = dieAt
    self:SetNWFloat("HordeSoulDieTime", dieAt)
end

function ENT:OnTakeDamage(dmginfo)
    if self._SoulRemoving then return 0 end

    local dmg = dmginfo:GetDamage()
    if dmg <= 0 then return 0 end

    self:ResetSoulTimer()

    local hp = self:Health() - dmg
    self:SetHealth(hp)

    if hp <= 0 then
        self:SoulDestroy()
    end

    return 0
end

function ENT:SoulThink()
    if self._SoulRemoving then return end

    local target = self:GetNWEntity("HordeSoulTarget")
    if not IsValid(target) or target:Alive() or target:Team() == TEAM_SPECTATOR then
        self:SoulCleanup(false)
        return
    end

    local remaining = (self._SoulDieTime or 0) - CurTime()
    if remaining <= 0 then
        self:SoulResurrect()
    end
end

hook.Add("Horde_OnPlayerShouldRespawnDuringWave", "Horde_SoulRebooterRespawnAllowed", function(ply)
    if IsValid(ply) and ply.Horde_SoulRebooterRespawning then return true end
end)

function ENT:SoulResurrect()
    if self._SoulRemoving then return end
    local target = self:GetNWEntity("HordeSoulTarget")
    if not IsValid(target) or target:Alive() then
        self:SoulCleanup(false)
        return
    end

    self._SoulRemoving = true

    local pos = self:GetPos() + Vector(0, 0, 8)
    local ang = Angle(0, self:GetAngles().y, 0)

    local mins, maxs = target:OBBMins(), target:OBBMaxs()
    local tr = util.TraceHull({
        start  = pos + Vector(0, 0, 16),
        endpos = pos,
        mins   = mins,
        maxs   = maxs,
        filter = {self, target},
        mask   = MASK_PLAYERSOLID
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
                    filter = {self, target},
                    mask   = MASK_PLAYERSOLID
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

    target:UnSpectate()
    target.Horde_SoulRebooterRespawning = true
    target:Spawn()
    target.Horde_SoulRebooterRespawning = nil

    if IsValid(target) and target:Alive() then
        target:SetPos(pos)
        target:SetAngles(ang)
        target:SetVelocity(vector_origin)

        if target.Horde_SetGivenStarterWeapons then
            target:Horde_SetGivenStarterWeapons(nil)
        end
        if HORDE and HORDE.GiveStarterWeapons then
            HORDE:GiveStarterWeapons(target)
        end

        sound.Play("horde/gadgets/heal_beam.ogg", pos, 75, 100)

        local owner = self:GetNWEntity("HordeOwner")
        if HORDE and HORDE.SendNotification then
            if IsValid(owner) then
                HORDE:SendNotification("Soul Rebooter: " .. target:Nick() .. " has been resurrected.", 0, owner)
            end
            HORDE:SendNotification("You have been resurrected by Soul Rebooter.", 0, target)
        end
    end

    self:SoulCleanup(true)
end

function ENT:SoulDestroy()
    if self._SoulRemoving then return end
    self._SoulRemoving = true

    local pos = self:GetPos()
    local effect = EffectData()
    effect:SetOrigin(pos)
    effect:SetScale(1.5)
    util.Effect("Explosion", effect)
    util.BlastDamage(self, self:GetNWEntity("HordeOwner") or self, pos, 120, 40)

    sound.Play("weapons/explode3.wav", pos, 80, 100)

    self:SoulCleanup(false)
end

function ENT:SoulCleanup(success)
    self._SoulRemoving = true

    if self._SoulTimerId then
        timer.Remove(self._SoulTimerId)
        self._SoulTimerId = nil
    end

    self:SetNWEntity("HordeSoulTarget", NULL)
    self:SetNWString("HordeSoulTargetName", "")
    self:SetNWFloat("HordeSoulDieTime", 0)

    if IsValid(self) then
        self:Remove()
    end
end

function ENT:OnRemove()
    if self._SoulTimerId then
        timer.Remove(self._SoulTimerId)
        self._SoulTimerId = nil
    end
end

if VJ then
    VJ.AddNPC("Soul Rebooter", "horde_soul_rebooter_pylon", "Horde")
end
