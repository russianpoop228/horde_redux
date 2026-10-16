AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = "models/vj_zombies/fast_main.mdl"
ENT.StartHealth = 4000
ENT.HullType = HULL_HUMAN
ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.BloodColor = "Red"

ENT.HasMeleeAttack = false
ENT.HasRangeAttack = false
ENT.DisableWandering = true
ENT.DisableFindEnemy = true

ENT.FootStepTimeRun = 0.25
ENT.FootStepTimeWalk = 0.4

ENT.SoundTbl_FootStep = {"npc/fast_zombie/foot1.wav", "npc/fast_zombie/foot2.wav", "npc/fast_zombie/foot3.wav", "npc/fast_zombie/foot4.wav"}
ENT.SoundTbl_Pain = {"npc/fast_zombie/idle1.wav", "npc/fast_zombie/idle2.wav", "npc/fast_zombie/idle3.wav"}
ENT.SoundTbl_Death = "npc/fast_zombie/wake1.wav"

ENT.Horde_BuildBuster   = true
ENT.RoarSound           = "horde/buildbuster/build_buster_summon.wav"
ENT.SeekLoopSound       = "npc/attack_helicopter/aheli_mine_seek_loop1.wav"
ENT.SeekLoopInterval    = 1.8
ENT.BombModel           = "models/combine_helicopter/helicopter_bomb01.mdl"
ENT.ExplosionRadius     = 256
ENT.ExplosionDamage     = 9999
ENT.ReachDistance       = 80
ENT.TriggerRadius       = 384
ENT.TriggerScanInterval = 0.25
ENT.TargetSearchDelay   = 0.5
ENT.RoarActivity        = "BR2_Roar"
ENT.RoarDuration        = 4
ENT.RoarPlaybackRate    = 0.46875
ENT.RoarSoundPitch      = 100
local function IsPlayerAllyNPC(ent)
    if not IsValid(ent) or ent:IsPlayer() then return false end
    if not (ent:IsNPC() or ent:IsNextBot()) then return false end
    if HORDE:IsFriendlyUnit(ent) then return true end
    local classes = ent.VJ_NPC_Class
    if istable(classes) then
        for _, c in ipairs(classes) do
            if c == "CLASS_PLAYER_ALLY" or c == "CLASS_COMBINE" then return true end
        end
    end
    return false
end

local function IsCarryingBuild(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local wpn = ply:GetActiveWeapon()
    if not IsValid(wpn) or not wpn.GetReadytoBuild then return false end
    return wpn:GetReadytoBuild() == true
end

local function FindNearestBuildable(pos)
    local classes = {}
    for class in pairs(HORDE.EngineerBuildables or {}) do classes[class] = true end
    for class in pairs(HORDE.EngineerBuildableCustom or {}) do classes[class] = true end

    local best, bestDist
    local function consider(ent)
        if not IsValid(ent) or ent:Health() <= 0 then return end
        local d = pos:DistToSqr(ent:GetPos())
        if not bestDist or d < bestDist then
            best, bestDist = ent, d
        end
    end

    for class in pairs(classes) do
        if HORDE:Horde_IsBuildable(class) then
            for _, ent in ipairs(ents.FindByClass(class)) do consider(ent) end
        end
    end
    for _, ply in ipairs(player.GetHumans()) do
        if ply:Alive() and ply:Horde_GetClass()
            and ply:Horde_GetClass().name == HORDE.Class_Engineer and IsCarryingBuild(ply) then
            consider(ply)
        end
    end
    return best
end

local function FindNearestEngineer(pos)
    local best, bestDist
    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply) and ply:Alive() and ply:Horde_GetClass()
            and ply:Horde_GetClass().name == HORDE.Class_Engineer then
            local d = pos:DistToSqr(ply:GetPos())
            if not bestDist or d < bestDist then
                best, bestDist = ply, d
            end
        end
    end
    return best
end
function ENT:CustomOnInitialize()
    self:SetCollisionBounds(Vector(13, 13, 50), Vector(-13, -13, 0))
    self:SetModelScale(1.75, 0)
    self:SetSubMaterial(0, "models/horde/lesion/lesion_sheet")
    self:SetColor(Color(255, 50, 50))

    self:AddRelationship("npc_headcrab_poison D_LI 99")
    self:AddRelationship("npc_headcrab_fast D_LI 99")

    self:AttachBomb()
    self:StartSeekLoop()

    self.NextTargetSearch = CurTime() + self.RoarDuration
    self.NextTriggerScan  = CurTime() + self.RoarDuration
    self.SpawnRoarEndT    = CurTime() + self.RoarDuration
    timer.Simple(0.1, function()
        if IsValid(self) then self:PlayRoar() end
    end)

    self:CallOnRemove("Horde_BuildBusterCleanup", function()
        self:StopSeekLoop()
        if IsValid(self._Bomb) then self._Bomb:Remove() end
    end)
end

function ENT:PlayRoar()
    sound.Play(self.RoarSound, self:GetPos(), 100, self.RoarSoundPitch)
    self:VJ_ACT_PLAYACTIVITY(self.RoarActivity, true, false, false, nil, { PlayBackRate = self.RoarPlaybackRate })
end

function ENT:AttachBomb()
    local bomb = ents.Create("prop_dynamic")
    if not IsValid(bomb) then return end
    bomb:SetModel(self.BombModel)
    bomb:SetPos(self:GetPos())
    bomb:SetAngles(self:GetAngles())
    bomb:Spawn()
    bomb:SetSolid(SOLID_NONE)
    bomb:SetMoveType(MOVETYPE_NONE)
    bomb:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

    local bone = self:LookupBone("ValveBiped.Bip01_Head1")
        or self:LookupBone("head") or self:LookupBone("Head")
    if bone then
        bomb:FollowBone(self, bone)
    else
        bomb:SetParent(self)
    end

    self._Bomb = bomb
end

function ENT:StartSeekLoop()
    local id = self:GetCreationID()
    timer.Remove("Horde_BuildBusterSeek" .. id)
    if self._SeekSound then self._SeekSound:Stop() end

    self._SeekSound = CreateSound(self, self.SeekLoopSound)
    if not self._SeekSound then return end
    self._SeekSound:SetSoundLevel(78)
    self._SeekSound:Play()

    timer.Create("Horde_BuildBusterSeek" .. id, self.SeekLoopInterval, 0, function()
        if not IsValid(self) or self._Detonating or not self._SeekSound then
            timer.Remove("Horde_BuildBusterSeek" .. id)
            return
        end
        self._SeekSound:Stop()
        self._SeekSound:Play()
    end)
end

function ENT:StopSeekLoop()
    local id = self:GetCreationID()
    timer.Remove("Horde_BuildBusterSeek" .. id)
    if self._SeekSound then
        self._SeekSound:Stop()
        self._SeekSound = nil
    end
    self:StopSound(self.SeekLoopSound)
end

function ENT:AcquireTarget()
    return FindNearestBuildable(self:GetPos()) or FindNearestEngineer(self:GetPos())
end

function ENT:Detonate(target)
    if self._Detonating then return end
    self._Detonating = true
    self._Invincible = true
    self._Fooled = IsValid(target) and target:IsPlayer() and IsCarryingBuild(target)

    self:StopSeekLoop()
    self:ClearGoal()
    self:StopMoving()

    self:SetHealth(math.max(self:Health(), 1))

    self:PlayRoar()

    timer.Simple(self.RoarDuration, function()
        if not IsValid(self) then return end
        self:Explode()
    end)
end

function ENT:Explode()
    local pos = self:GetPos()

    ParticleEffect("explosion_huge", pos, Angle(0, 0, 0))
    sound.Play("ambient/explosions/explode_1.wav", pos, 1000)

    if not self._Fooled then
        local dmg = DamageInfo()
        dmg:SetDamage(self.ExplosionDamage)
        dmg:SetAttacker(self)
        dmg:SetInflictor(self)
        dmg:SetDamageType(DMG_BLAST)
        dmg:SetDamagePosition(pos)

        for _, ent in ipairs(ents.FindInSphere(pos, self.ExplosionRadius)) do
            if IsValid(ent) and ent ~= self and ent:Health() > 0 then
                if ent:IsPlayer() then
                    if not HORDE:IsPlayerSpectator(ent) then
                        ent:TakeDamageInfo(dmg)
                    end
                elseif IsPlayerAllyNPC(ent) then
                    ent:TakeDamageInfo(dmg)
                end
            end
        end
    end

    self:Remove()
end

function ENT:FindTriggerTarget()
    local pos = self:GetPos()
    local best, bestDist
    for _, ent in ipairs(ents.FindInSphere(pos, self.TriggerRadius)) do
        if IsValid(ent) and ent ~= self and ent:Health() > 0 then
            local isTarget
            if ent:IsPlayer() then
                isTarget = ent:Horde_GetClass() and ent:Horde_GetClass().name == HORDE.Class_Engineer
            else
                isTarget = HORDE:Horde_IsBuildable(ent:GetClass())
            end
            if isTarget then
                local d = pos:DistToSqr(ent:GetPos())
                if not bestDist or d < bestDist then best, bestDist = ent, d end
            end
        end
    end
    return best
end

function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
    if self._Invincible then
        dmginfo:SetDamage(0)
        return
    end
    if self:Health() - dmginfo:GetDamage() <= 0 then
        dmginfo:SetDamage(0)
        self:Detonate(nil)
    end
end

function ENT:CustomOnThink()
    if self._Detonating or self.Dead then return end

    if CurTime() >= (self.NextTriggerScan or 0) then
        self.NextTriggerScan = CurTime() + self.TriggerScanInterval
        local trigger = self:FindTriggerTarget()
        if IsValid(trigger) then
            self:Detonate(trigger)
            return
        end
    end

    local target = self:GetEnemy()
    if not IsValid(target) or target:Health() <= 0 then
        if CurTime() < (self.NextTargetSearch or 0) then return end
        self.NextTargetSearch = CurTime() + self.TargetSearchDelay
        target = self:AcquireTarget()
        if not IsValid(target) then
            if CurTime() >= (self.SpawnRoarEndT or 0) then
                self:Detonate(nil)
            end
            return
        end
        self:ForceSetEnemy(target)
    end

    if self:GetPos():DistToSqr(target:GetPos()) <= (self.ReachDistance * self.ReachDistance) then
        self:Detonate(target)
    end
end

VJ.AddNPC("Build Buster","npc_vj_horde_build_buster", "Zombies")
