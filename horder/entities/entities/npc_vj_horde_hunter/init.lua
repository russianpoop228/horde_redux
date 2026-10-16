AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = {"models/hunter.mdl"}
ENT.StartHealth = 4000
ENT.HullType = HULL_HUMAN

ENT.VJ_NPC_Class = {"CLASS_ZOMBIE"}
ENT.AnimTbl_WeaponAttack = {ACT_RANGE_ATTACK2}
ENT.FindEnemy_UseSphere = true

ENT.DistanceToRunFromEnemy = 200
ENT.FindEnemy_CanSeeThroughWalls = true

ENT.LastSeenEnemyTimeUntilReset = 105
ENT.NextProcessTime = 1

ENT.WeaponSpread = 1
ENT.BloodColor = "White"
ENT.SightDistance = 10000
ENT.BecomeEnemyToPlayer = true
ENT.BecomeEnemyToPlayerLevel = 2
ENT.HasMeleeAttack = true
ENT.HasFootStepSound = true

ENT.ShootDistance = 1200
ENT.Weapon_FiringDistanceFar = 1200

ENT.MeleeAttackDamage = 40
ENT.SquadName = "combine"
ENT.FootStepTimeRun = 0.4
ENT.FootStepTimeWalk = 0.5

ENT.HasRangeAttack = true
ENT.DisableDefaultRangeAttackCode = true
ENT.DisableRangeAttackAnimation = false
ENT.AnimTbl_RangeAttack = {ACT_RANGE_ATTACK2}
ENT.RangeToMeleeDistance = 0.1
ENT.RangeAttackAngleRadius = 100

ENT.RangeDistance = 1100
ENT.RangeAttackMinDistance = 200
ENT.RangeAttackMaxDistance = 1100

ENT.RangeAttackAnimationDelay = 0
ENT.RangeAttackAnimationFaceEnemy = true

ENT.NextRangeAttackTime = VJ.SET(1, 3)
ENT.NextAnyAttackTime_Range = 0.5

ENT.RangeAttackReps = 1
ENT.TimeUntilRangeAttackProjectileRelease = 0

ENT.HasLeapAttack = true
ENT.AnimTbl_LeapAttack = {ACT_RUN}
ENT.LeapDistance = 2048
ENT.LeapToMeleeDistance = 0
ENT.TimeUntilLeapAttackDamage = 0.50
ENT.NextLeapAttackTime = 8
ENT.NextLeapAttackTime_DoRand = false
ENT.NextAnyAttackTime_Leap = 1
ENT.LeapAttackReps = 1
ENT.StopLeapAttackAfterFirstHit = true
ENT.TimeUntilLeapAttackVelocity = 0.1
ENT.LeapAttackUseCustomVelocity = true
ENT.LeapAttackVelocityForward = 800
ENT.LeapAttackVelocityUp = 250
ENT.LeapAttackVelocityRight = 0
ENT.LeapAttackDamage = 60
ENT.LeapAttackDamageDistance = 80
ENT.LeapAttackDamageType = DMG_SLASH
ENT.DisableLeapAttackAnimation = false

ENT.SoundTbl_FootStep = {"npc/ministrider/ministrider_footstep1.wav","npc/ministrider/ministrider_footstep2.wav","npc/ministrider/ministrider_footstep3.wav","npc/ministrider/ministrider_footstep4.wav","npc/ministrider/ministrider_footstep5.wav"}
ENT.SoundTbl_LeapAttackJump = {"npc/ministrider/hunter_charge3.wav","npc/ministrider/hunter_charge4.wav"}
ENT.SoundTbl_LeapAttackDamage = {"npc/ministrider/body_medium_impact_hard1.wav","npc/ministrider/body_medium_impact_hard2.wav"}

ENT.Hunter_PhaseTwoTriggered = false

function ENT:CustomInitialize()
    self.Hunter_PhaseTwoTriggered = false
end

function ENT:CustomOnTakeDamage_AfterDamage(dmginfo, hitgroup)
    if self.Hunter_PhaseTwoTriggered then return end

    if self:Health() <= (self:GetMaxHealth() * 0.50) then
        self:TriggerPhaseTwo()
    end
end

function ENT:TriggerPhaseTwo()
    self.Hunter_PhaseTwoTriggered = true

    self:EmitSound("npc/ministrider/hunter_pain3.wav", 100, 100)
    self:EmitSound("npc/ministrider/hunter_prestrike1.wav", 100, 100)

    self:VJ_ACT_PLAYACTIVITY(ACT_RANGE_ATTACK2, true, 1.5, false)

    timer.Simple(0.6, function()
        if IsValid(self) and IsValid(self:GetEnemy()) then
            local currentSpawnPos = self:GetShootPos()
            local currentAtt = self:GetAttachment(self:LookupAttachment("minigun"))
            if currentAtt then currentSpawnPos = currentAtt.Pos end

            local targetPos = self:GetEnemy():BodyTarget(currentSpawnPos)
            local vecDir = (targetPos - currentSpawnPos):GetNormal()

            local shot = ents.Create("obj_vj_horde_cball")
            if IsValid(shot) then
                shot:SetPos(currentSpawnPos + (vecDir * 60))
                shot:SetAngles(vecDir:Angle())
                shot:SetOwner(self)
                shot:Spawn()
                shot:Activate()

                local phys = shot:GetPhysicsObject()
                if IsValid(phys) then
                    phys:SetVelocity(vecDir * 1024)
                end
                self:EmitSound("npc/ministrider/ministrider_preflechette.wav", 100, 80)
            end
        end
    end)

timer.Simple(1.5, function()
        if IsValid(self) then
            self.HasRangeAttack = false
            self.DistanceToRunFromEnemy = 0
            self.NextLeapAttackTime = 6
            self:EmitSound("npc/dog/dog_angry1.wav", 100, 100)
            self:SetColor(Color(255, 0, 0))
            self:SetRenderMode(RENDERMODE_NORMAL)
            self.AnimationPlaybackRate = 2
			self.FootStepTimeRun = 0.25
            self.FootStepTimeWalk = 0.3
		end
    end)
end

function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
    if self.Hunter_PhaseTwoTriggered then
        dmginfo:ScaleDamage(0.5)
        if dmginfo:GetDamage() > 1 then
             self:EmitSound("physics/metal/metal_box_impact_bullet3.wav", 70, 150)
        end
    end
end

function ENT:CustomRangeAttackCode()
    if self.Hunter_PhaseTwoTriggered then return end

    local enemy = self:GetEnemy()
    if not IsValid(enemy) then return end

    self:VJ_ACT_PLAYACTIVITY(ACT_RANGE_ATTACK2, true, 0.6, false)

    local burstCount = 5
    local burstDelay = 0.05

    timer.Create("Hunter_Burst_"..self:EntIndex(), burstDelay, burstCount, function()
        if IsValid(self) and IsValid(self:GetEnemy()) then
            local currentSpawnPos = self:GetShootPos()
            local currentAtt = self:GetAttachment(self:LookupAttachment("minigun"))
            if currentAtt then currentSpawnPos = currentAtt.Pos end

            local targetPos = self:GetEnemy():BodyTarget(currentSpawnPos)
            local vecDir = (targetPos - currentSpawnPos):GetNormal()

            local shot = ents.Create("obj_vj_horde_bullet")
            if IsValid(shot) then
                shot:SetPos(currentSpawnPos)
                shot:SetAngles(vecDir:Angle())
                shot:SetOwner(self)
                shot.DirectDamage = 6
                shot:Spawn()
                shot:Activate()

                local phys = shot:GetPhysicsObject()
                if IsValid(phys) then
                    phys:Wake()

                    local spread = VectorRand() * 0.02
                    local finalDir = (vecDir + spread):GetNormal()

                    phys:SetVelocity(finalDir * 512)
                end
            end

            self:EmitSound("weapons/airboat/airboat_gun_energy1.wav", 90, 100, 0.6)

            local effectdata = EffectData()
            effectdata:SetOrigin(currentSpawnPos)
            effectdata:SetScale(1)
            util.Effect("AirboatMuzzleFlash", effectdata)
        end
    end)
end

VJ.AddNPC("Hunter","npc_vj_horde_hunter", "Zombies")
