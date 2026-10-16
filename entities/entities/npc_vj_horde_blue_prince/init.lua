AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include('shared.lua')
ENT.Model = "models/vj_zombies/fast_main.mdl"
ENT.StartHealth = 2000
ENT.HullType = HULL_HUMAN
ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.BloodColor = "Red"

ENT.HasMeleeAttack = true
ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
ENT.MeleeAttackDistance = 32
ENT.MeleeAttackDamageDistance = 85
ENT.TimeUntilMeleeAttackDamage = 0.4
ENT.MeleeAttackDamage = 40
ENT.MeleeAttackBleedEnemy = false
ENT.HasMeleeAttackKnockBack = true
ENT.MeleeAttackKnockBack_Forward1 = 100
ENT.MeleeAttackKnockBack_Forward2 = 130
ENT.NextAnyAttackTime_Melee = 0.6

ENT.HasLeapAttack = false

ENT.FootStepTimeRun = 0.25
ENT.FootStepTimeWalk = 0.4

ENT.SoundTbl_FootStep = {"npc/fast_zombie/foot1.wav", "npc/fast_zombie/foot2.wav", "npc/fast_zombie/foot3.wav", "npc/fast_zombie/foot4.wav"}
ENT.SoundTbl_Breath = "npc/fast_zombie/breathe_loop1.wav"
ENT.SoundTbl_Alert = {"npc/fast_zombie/fz_alert_close1.wav", "npc/fast_zombie/fz_alert_far1.wav"}
ENT.SoundTbl_MeleeAttack = {"npc/zombie/claw_strike1.wav", "npc/zombie/claw_strike2.wav", "npc/zombie/claw_strike3.wav"}
ENT.SoundTbl_MeleeAttackExtra = {"npc/zombie/claw_strike1.wav", "npc/zombie/claw_strike2.wav", "npc/zombie/claw_strike3.wav"}
ENT.SoundTbl_MeleeAttackMiss = {"vj_zombies/slow/miss1.wav", "vj_zombies/slow/miss2.wav", "vj_zombies/slow/miss3.wav", "vj_zombies/slow/miss4.wav"}
ENT.SoundTbl_Pain = {"npc/fast_zombie/idle1.wav", "npc/fast_zombie/idle2.wav", "npc/fast_zombie/idle3.wav"}
ENT.SoundTbl_Death = "npc/fast_zombie/wake1.wav"

ENT.GeneralSoundPitch1 = 50
ENT.GeneralSoundPitch2 = 50
ENT.HasSoundTrack = false

ENT.HasWorldShakeOnMove = true
ENT.WorldShakeOnMoveAmplitude = 6
ENT.WorldShakeOnMoveRadius = 200
ENT.WorldShakeOnMoveDuration = 0.4
ENT.WorldShakeOnMoveFrequency = 100
ENT.PrinceScale         = 1.75
ENT.PrinceColor         = Color(70, 140, 255)
ENT.HatModel            = "models/player/items/demo/crown.mdl"
ENT.HatScale            = 0.6
ENT.HatOffset           = Vector(2, -2, 1)
ENT.HatAngles           = Angle(90, 45, 0)
ENT.SummonHealthRatio   = 0.5
ENT.SummonClass         = "npc_fastzombie"
ENT.SummonName          = "Fast Zombie"
ENT.SummonDistance      = 56
ENT.RoarActivity        = "BR2_Roar"
ENT.RoarSound           = "horde/lesion/lesion_enrage.ogg"
ENT.RoarSoundPitch      = 75
ENT.ShieldDuration      = 0
ENT.ShieldMaxCap        = 300
ENT.ShieldMaxRatio      = 0.05

local SUMMON_DISTANCE_MULT = {1, 1.6, 2.2}
local SUMMON_ANGLE_OFFSET  = {0, 35, -35, 70, -70, 110, -110, 180}
local SUMMON_HULL_MINS     = Vector(-16, -16, 0)
local SUMMON_HULL_MAXS     = Vector(16, 16, 72)
local SUMMON_PLAYER_GAP    = 48
local GUARD_CHECK_INTERVAL = 1.0
local GUARD_CHECK_RETRY    = 3.0

local SUMMON_EFFECTS         = {"vj_aurora_floaters", "vj_aurora_shockwave"}
local SUMMON_EFFECT_LIFETIME = 2

local function SpawnSummonEffect(pos)
    for _, particle in ipairs(SUMMON_EFFECTS) do
        local fx = HORDE:SimpleParticleSystem(particle, pos, Angle(0, 0, 0))
        if IsValid(fx) then
            timer.Simple(SUMMON_EFFECT_LIFETIME, function()
                if not IsValid(fx) then return end
                fx:Fire("stop", "", 0)
                fx:Remove()
            end)
        end
    end
end

local function KillGuard(guard)
    if not IsValid(guard) or guard:Health() <= 0 then return end
    guard:TakeDamage(guard:Health() + guard:GetMaxHealth(), Entity(0), Entity(0))
end

hook.Add("EntityTakeDamage", "Horde_BluePrinceShield", function(target, dmg)
    if not IsValid(target) then return end
    local shield = target._PrinceShield
    if not shield or shield <= 0 then return end

    target._PrinceShield = shield - dmg:GetDamage()
    if target._PrinceShield <= 0 then
        target:SetNWBool("Horde_PrinceShield", false)
    end
    return true
end)
local function AttachHat(npc, model, offset, angles, scale)
    if not IsValid(npc) then return end
    local bone = npc:LookupBone("ValveBiped.Bip01_Head1")
        or npc:LookupBone("head") or npc:LookupBone("Head")
    if not bone then return end

    local hat = ents.Create("prop_dynamic")
    if not IsValid(hat) then return end
    hat:SetModel(model)
    hat:Spawn()
    hat:SetSolid(SOLID_NONE)
    hat:SetMoveType(MOVETYPE_NONE)
    hat:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    if scale and scale > 0 then
        hat:SetModelScale(scale)
    end

    local bone_pos, bone_ang = npc:GetBonePosition(bone)
    local off = offset or Vector(0, 0, 0)
    local hat_ang = bone_ang
    if angles ~= nil then
        hat_ang = bone_ang + angles
    end
    hat:SetPos(bone_pos + bone_ang:Forward() * off.x + bone_ang:Right() * off.y + bone_ang:Up() * off.z)
    hat:SetAngles(hat_ang)
    hat:FollowBone(npc, bone)

    npc:CallOnRemove("Horde_BluePrinceHatCleanup", function()
        if IsValid(hat) then hat:Remove() end
    end)
    return hat
end

local function IsSummonSpotFree(npc, pos, ignore_players)
    if not util.IsInWorld(pos) then return false end
    local tr = util.TraceHull({
        start  = pos + Vector(0, 0, 4),
        endpos = pos + Vector(0, 0, 4),
        mins   = SUMMON_HULL_MINS,
        maxs   = SUMMON_HULL_MAXS,
        filter = npc,
        mask   = MASK_NPCSOLID,
    })
    if tr.Hit or tr.StartSolid then return false end

    if not ignore_players then
        for _, ply in ipairs(player.GetHumans()) do
            if IsValid(ply) and ply:Alive() and pos:Distance(ply:GetPos()) < SUMMON_PLAYER_GAP then
                return false
            end
        end
    end
    return true
end
function ENT:CustomOnInitialize()
    self:SetCollisionBounds(Vector(13, 13, 50), Vector(-13, -13, 0))
    self:SetModelScale(self.PrinceScale, 0)
    self:SetSubMaterial(0, "models/horde/lesion/lesion_sheet")
    self:SetColor(self.PrinceColor)
    self.HasLeapAttack = false

    self:AddRelationship("npc_headcrab_poison D_LI 99")
    self:AddRelationship("npc_headcrab_fast D_LI 99")

    AttachHat(self, self.HatModel, self.HatOffset, self.HatAngles, self.PrinceScale * self.HatScale)

    self:CallOnRemove("Horde_BluePrinceGuardCleanup", function()
        for _, guard in ipairs(self._Guards or {}) do
            KillGuard(guard)
        end
    end)

    self:EmitSound("horde/lesion/lesion_roar.ogg", 1500, 80, 1, CHAN_STATIC)
end

function ENT:TranslateActivity(act)
    if act == ACT_RUN or act == ACT_WALK then
        return ACT_RUN
    end
    return self.BaseClass.TranslateActivity(self, act)
end

function ENT:PlayRoar()
    sound.Play(self.RoarSound, self:GetPos(), 100, self.RoarSoundPitch)
    self:VJ_ACT_PLAYACTIVITY(self.RoarActivity, true, 1.5, false)
end

function ENT:ApplyShield()
    local amount = math.min(self.ShieldMaxCap, self:Health() * self.ShieldMaxRatio)
    if amount <= 0 then return end

    self._PrinceShield = amount
    self:SetNWBool("Horde_PrinceShield", true)

    local id = self:GetCreationID()
    timer.Remove("Horde_BluePrinceShield" .. id)
    if self.ShieldDuration and self.ShieldDuration > 0 then
        timer.Create("Horde_BluePrinceShield" .. id, self.ShieldDuration, 1, function()
            if not IsValid(self) then return end
            self._PrinceShield = 0
            self:SetNWBool("Horde_PrinceShield", false)
        end)
    end
end

function ENT:FindSummonSpot(dir, ignore_players)
    local baseAngle = math.atan2(dir.y, dir.x)
    local origin = self:GetPos()

    for _, distanceMul in ipairs(SUMMON_DISTANCE_MULT) do
        local distance = self.SummonDistance * distanceMul
        for _, angleOffset in ipairs(SUMMON_ANGLE_OFFSET) do
            local angle = baseAngle + math.rad(angleOffset)
            local pos = origin + Vector(math.cos(angle) * distance, math.sin(angle) * distance, 0)
            if IsSummonSpotFree(self, pos, ignore_players) then
                return pos
            end
        end
    end
    return nil
end

function ENT:BuildSummonConfig()
    local wave_config = HORDE.enemies and HORDE.enemies[self.SummonName .. tostring(HORDE.current_wave or 0)]
    local config
    if istable(wave_config) then
        config = table.Copy(wave_config)
        config.class = self.SummonClass
        config.name = self.SummonName
    else
        config = {
            class = self.SummonClass,
            name = self.SummonName,
            health_scale = 0.75,
            damage_scale = 1,
            reward_scale = 1,
            model_scale = 1,
        }
    end
    config.color = self.PrinceColor
    return config
end

function ENT:SummonGuards()
    local forward = self:GetForward()
    local right = self:GetRight()

    local guards = {}
    for _, dir in ipairs({forward, -forward, right, -right}) do
        local pos = self:FindSummonSpot(dir) or self:FindSummonSpot(dir, true)
        if pos then
            local spawn_pos = pos + Vector(0, 0, HORDE.enemy_spawn_z or 0)
            local guard = HORDE:SpawnEnemy(self:BuildSummonConfig(), spawn_pos)

            if IsValid(guard) then
                guards[#guards + 1] = guard

                HORDE.spawned_enemies[guard:EntIndex()] = nil
                guard.Horde_NoReward = true

                SpawnSummonEffect(spawn_pos)
            end
        end
    end

    self._Guards = guards
    if #guards > 0 then
        self:PlayRoar()
        self:ApplyShield()
    end
    return #guards
end

function ENT:AliveGuardCount()
    local alive = 0
    for _, guard in ipairs(self._Guards or {}) do
        if IsValid(guard) and guard:Health() > 0 then
            alive = alive + 1
        end
    end
    return alive
end

function ENT:CustomOnTakeDamage_AfterDamage(dmginfo, hitgroup)
    if self._Summoning then return end
    local maxHealth = self:GetMaxHealth()
    if maxHealth <= 0 then return end
    local health = self:Health()
    if health <= 0 then return end
    if health > maxHealth * self.SummonHealthRatio then return end
    self._Summoning = true
    self._NextGuardCheck = CurTime() + GUARD_CHECK_INTERVAL

    timer.Simple(0, function()
        if IsValid(self) then self:SummonGuards() end
    end)
end

function ENT:CustomOnThink()
    if not self._Summoning or self:Health() <= 0 then return end

    local now = CurTime()
    if (self._NextGuardCheck or 0) > now then return end

    if self:AliveGuardCount() > 0 then
        self._NextGuardCheck = now + GUARD_CHECK_INTERVAL
        return
    end

    local spawned = self:SummonGuards()
    self._NextGuardCheck = now + (spawned > 0 and GUARD_CHECK_INTERVAL or GUARD_CHECK_RETRY)
end

VJ.AddNPC("Blue Prince","npc_vj_horde_blue_prince", "Zombies")
