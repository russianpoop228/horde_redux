AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = "models/antlion.mdl"
ENT.StartHealth = 125
ENT.MoveType = MOVETYPE_STEP
ENT.HullType = HULL_LARGE

ENT.SightDistance = 10000
ENT.SightAngle = 360
ENT.EnemyXRayDetection = true

ENT.VJ_NPC_Class = {"CLASS_PLAYER_ALLY", "CLASS_COMBINE"}
ENT.FriendlyMinion = true
ENT.CustomBlood_Particle = {}
ENT.BloodDecal = {"YellowBlood"}
ENT.HasMeleeAttack = false
ENT.AnimTbl_MeleeAttack =  {ACT_MELEE_ATTACK1}
ENT.MeleeAttackDistance = 100
ENT.MeleeAttackDamageDistance = 120
ENT.TimeUntilMeleeAttackDamage = 0.8
ENT.NextAnyAttackTime_Melee = false
ENT.MeleeAttackDamage = 30
ENT.MeleeAttackDamageType = DMG_SLASH

ENT.Immune_CombineBall = false
ENT.HasDeathAnimation = false
ENT.HasExtraMeleeAttackSounds = true
ENT.SlowPlayerOnMeleeAttack = false
ENT.SlowPlayerOnMeleeAttack_WalkSpeed = 50
ENT.SlowPlayerOnMeleeAttack_RunSpeed = 70
ENT.SlowPlayerOnMeleeAttackTime = 10
ENT.FootStepTimeRun = 0.2
ENT.FootStepTimeWalk = 0.4
ENT.HasLeapAttack = false
ENT.AnimTbl_LeapAttack = {ACT_JUMP}
ENT.StopLeapAttackAfterFirstHit = true
ENT.LeapAttackAnimationDelay = 0
ENT.LeapDistance = 2000
ENT.LeapToMeleeDistance = 10
ENT.TimeUntilLeapAttackDamage = 1
ENT.NextLeapAttackTime = 5
ENT.NextAnyAttackTime_Leap = 0
ENT.LeapAttackAnimationDecreaseLengthAmount = 0
ENT.LeapAttackDamageDistance = 100
ENT.LeapAttackDamageType = DMG_SLASH
ENT.LeapAttackDamage = 35
ENT.LeapAttackVelocityForward = 100
ENT.LeapAttackVelocityUp = 300
ENT.LeapAttackVelocityRight = 0
ENT.IsGuard = false
ENT.DisableChasingEnemy = true
ENT.DisableWandering = true
ENT.ConstantlyFaceEnemy = true
ENT.ConstantlyFaceEnemy_IfVisible = true
ENT.ConstantlyFaceEnemy_IfAttacking = true

ENT.HasRangeAttack = true
ENT.AnimTbl_RangeAttack = {"vjseq_charge_end"}
ENT.RangeAttackEntityToSpawn = "projectile_horde_antlion_bile"
ENT.RangeDistance = 2000
ENT.RangeToMeleeDistance = 0
ENT.TimeUntilRangeAttackProjectileRelease = 0.3
ENT.NextRangeAttackTime = 3
ENT.NextAnyAttackTime_Range = 0.4
ENT.RangeAttackPos_Up = 75

ENT.CanFlinch = 0
ENT.SoundTbl_FootStep = {"npc/antlion/foot1.wav","npc/antlion/foot2.wav","npc/antlion/foot3.wav","npc/antlion/foot4.wav"}
ENT.SoundTbl_Idle = {"npc/antlion/idle1.wav","npc/antlion/idle2.wav","npc/antlion/idle3.wav","npc/antlion/idle4.wav","npc/antlion/idle5.wav"}
ENT.SoundTbl_Alert = {"npc/antlion/attack_double1.wav","npc/antlion/attack_double2.wav","npc/antlion/attack_double3.wav"}
ENT.SoundTbl_MeleeAttackMiss = {""}
ENT.SoundTbl_MeleeAttack = {"npc/antlion/attack_double1.wav"}
ENT.SoundTbl_Pain = {"npc/antlion/pain1.wav"}
ENT.SoundTbl_Death = {"npc/antlion/pain1.wav","npc/antlion/pain2.wav"}
ENT.SoundTbl_LeapAttack = {"npc/antlion/fly.wav"}
ENT.SoundTbl_Impact = {"npc/antlion/shell_impact1.wav","npc/antlion/shell_impact2.wav","npc/antlion/shell_impact3.wav","npc/antlion/shell_impact4.wav"}
ENT.PulseInterval = 5
ENT.LastPulse = CurTime()

ENT.FollowMinDistance = 150
ENT.NextFollowUpdateTime = 0.2
ENT.FollowPlayer = false
ENT.TurningSpeed = 40
ENT.CanChatMessage = false

ENT.AnimTbl_Walk = {ACT_RUN}
ENT.AnimTbl_Run = {ACT_RUN}
ENT.Evolve_Stage = 1
ENT.Base_Health = 100
ENT.Evolve_Health = 0
ENT.Evolve_Health_Max = 100

ENT.LastEvolve = CurTime()
ENT.Horde_Immune_Status_All = true
function ENT:CustomOnInitialize()
	self:SetSkin(0)
	self.NextRangeAttackTime = 2
	self.LastPulse = CurTime()
	self.Owner = self:GetNWEntity("HordeOwner")
	self.properties = self.properties or {level = 1}
	self.level = self.properties.level or 1
	self:SetMaxHealth(self.Base_Health + self.level * 5)
	self:SetModelScale(0.5)
    self:SetModel(self.Model)
    self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
	self:SetHealth(self:GetMaxHealth())
	self.MeleeAttackDamage = 30 + self.level * 2
	self.RangeAttackDamage = 25 + self.level
	hook.Run("Horde_OnRaiseAntlion", self.Owner, self)
    timer.Simple(0.5, function()
        if not self:IsValid() then return end
        self:Follow(self.Owner)
    end)
    if self.evolutionmaximum then
        local max_stage = 2
        if self.Owner:Horde_GetPerk("hatcher_metamorphosis") then
            max_stage = 3
        end
        self.Evolve_Stage = max_stage
        self.Evolve_Health = 100
    end
end

function ENT:Horde_Evolve(health)
    local max_stage = 3
    if self.Owner:IsValid() and self.Owner:Horde_GetPerk("hatcher_metamorphosis") then
        max_stage = 4
    end
    if self.Evolve_Stage == max_stage then return end

    self.Evolve_Health = self.Evolve_Health + health

    if self.Evolve_Health < self.Evolve_Health_Max then return end
    self.Evolve_Stage = math.min(max_stage, self.Evolve_Stage + 1)

	if self.Evolve_Stage == 2 then
		self:SetSkin(1)
		self:SetMaxHealth(self.Base_Health * 1.5 + self.level * 9)
		self:SetHealth(self:GetMaxHealth())
		self:SetModelScale(0.75)
        self:SetModel(self.Model)
        self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
		self.MeleeAttackDamage = 45 + self.level * 6
		self.RangeAttackDamage = 35 + self.level * 4
		self.NextRangeAttackTime = 2
	elseif self.Evolve_Stage == 3 then
		self:SetSkin(3)
		self:SetMaxHealth(self.Base_Health * 2 + self.level * 25)
		self:SetHealth(self:GetMaxHealth())
		self:SetModelScale(1)
        self:SetModel(self.Model)
        self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
		self.MeleeAttackDamage = 60 + self.level * 10
		self.RangeAttackDamage = 45 + self.level * 8
		self.Horde_Immune_Break = true
		self.NextRangeAttackTime = 1
	elseif self.Evolve_Stage == 4 then
		self:SetSkin(0)
		self:SetModelScale(1)
		self.Model = "models/antlion_guard.mdl"
		self:SetModel(self.Model)
        self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
		self:SetMaxHealth(self.Base_Health * 4 + self.level * 50)
		self:SetHealth(self:GetMaxHealth())
		self.MeleeAttackDamage = 70 + self.level * 15
		self.RangeAttackDamage = 45 + self.level * 8
		self.NextRangeAttackTime = 1
		self.Horde_Immune_Status_All = true
		self:StopMoving()
		self.NextWanderTime = CurTime() + 2
		if !self:BusyWithActivity() then
			self:VJ_TASK_FACE_X("TASK_FACE_TARGET")
		end
		self:Activate()

		self.SoundTbl_Idle = {"npc/antlion_guard/growl_idle.wav"}
		self.SoundTbl_Alert = {"npc/antlion_guard/angry1.wav","npc/antlion_guard/angry2.wav","npc/antlion_guard/angry3.wav"}
		self.SoundTbl_MeleeAttack = {"npc/antlion_guard/shove1.wav"}
		self.SoundTbl_MeleeAttackMiss = {""}
		self.SoundTbl_RangeAttack = {"npc/antlion_guard/angry1.wav"}
		self.SoundTbl_Pain = {""}
		self.SoundTbl_Death = {"npc/antlion_guard/antlion_guard_die1.wav","npc/antlion_guard/antlion_guard_die2.wav"}
		self.SoundTbl_FootStep = {"npc/antlion_guard/foot_heavy1.wav","npc/antlion_guard/foot_heavy2.wav"}
	end
	self.Evolve_Health = self.Evolve_Health - self.Evolve_Health_Max
end

function ENT:Horde_IsStage(x)
	return self.Evolve_Stage >= x
end
local attackTimers = {
	[VJ.ATTACK_TYPE_MELEE] = function(self, skipStopAttacks)
		if !skipStopAttacks then
			timer.Create("attack_melee_reset" .. self:EntIndex(), self:GetAttackTimer(self.NextAnyAttackTime_Melee, self.TimeUntilMeleeAttackDamage, self.AttackAnimDuration), 1, function()
				self:StopAttacks()
				self:MaintainAlertBehavior()
			end)
		end
		timer.Create("attack_melee_reset_able" .. self:EntIndex(), self:GetAttackTimer(self.NextMeleeAttackTime), 1, function()
			self.IsAbleToMeleeAttack = true
		end)
	end,
	[VJ.ATTACK_TYPE_RANGE] = function(self, skipStopAttacks)
		if !skipStopAttacks then
			timer.Create("attack_range_reset" .. self:EntIndex(), self:GetAttackTimer(self.NextAnyAttackTime_Range, self.TimeUntilRangeAttackProjectileRelease, self.AttackAnimDuration), 1, function()
				self:StopAttacks()
				self:MaintainAlertBehavior()
			end)
		end
		timer.Create("attack_range_reset_able" .. self:EntIndex(), self:GetAttackTimer(self.NextRangeAttackTime), 1, function()
			self.IsAbleToRangeAttack = true
		end)
	end,
	[VJ.ATTACK_TYPE_LEAP] = function(self, skipStopAttacks)
		if !skipStopAttacks then
			timer.Create("attack_leap_reset" .. self:EntIndex(), self:GetAttackTimer(self.NextAnyAttackTime_Leap, self.TimeUntilLeapAttackDamage, self.AttackAnimDuration), 1, function()
				self:StopAttacks()
				self:MaintainAlertBehavior()
			end)
		end
		timer.Create("attack_leap_reset_able" .. self:EntIndex(), self:GetAttackTimer(self.NextLeapAttackTime), 1, function()
			self.IsAbleToLeapAttack = true
		end)
	end
}

function ENT:BugPulse()
	local r = {190, 190 * 1.5, 190 * 2, 190 * 2}
	for _, ent in pairs(ents.FindInSphere(self:GetPos(), r[self.Evolve_Stage])) do
		if ent:IsPlayer() then
			local healer = self.Owner
			if not healer then
				healer = self
			else
				hook.Run("Horde_OnAntlionPulse", healer, self, ent)
			end
			local healinfo = HealInfo:New({amount=ent:GetMaxHealth() * 0.05, healer=healer})
			HORDE:OnPlayerHeal(ent, healinfo)
			self:SetHealth(math.min(self:GetMaxHealth(), self:Health() + self:GetMaxHealth() * 0.05))
		end
	end

	local effectdata = EffectData()
	effectdata:SetOrigin(self:GetPos())
	effectdata:SetRadius(r[self.Evolve_Stage])
	util.Effect("horde_antlion_pulse", effectdata)
	self:EmitSound("horde/weapons/spore_launcher/splauncher_impact.ogg", SNDLVL_NORM, 150, VOL_NORM, CHAN_ITEM)
end

function ENT:CustomOnMeleeAttack_BeforeChecks()
	timer.Simple(2, function ()
		if self:IsValid() then
			attackTimers[VJ.ATTACK_TYPE_MELEE](self)
		end
	end)
end

ENT.NextUnstuckCheck = 0
function ENT:OverrideMove(inv)
    if(self.NextUnstuckCheck < CurTime() && self:GetMoveVelocity() == vector_origin) then
        local origin = self:GetPos()
        local result = util.TraceHull({
            start = origin,
            endpos = origin,
            mins = self:OBBMins(),
            maxs = self:OBBMaxs(),
            filter = self,
            ignoreworld = true,
        })
        local ent = result.Entity
        if(IsValid(ent) && ent:GetClass() == self:GetClass() && ent:GetMoveVelocity() == vector_origin) then
            self:SetPos(self:GetOwner():GetPos())
            ent.NextUnstuckCheck = CurTime() + 1
        end
        self.NextUnstuckCheck = CurTime() + 0.2
    end
end

function ENT:CustomOnThink()
	if self.LastPulse <= CurTime() then
		local d = self:GetPos():DistToSqr(self.Owner:GetPos())
		if d >= 640000 then
			local v = VectorRand() * 20
			v.z = 0
			self:SetPos(self.Owner:GetPos() + v)
		end
		self:BugPulse()
		local t = 5
		if self.Evolve_Stage == 2 then
			t = 4
		elseif self.Evolve_Stage == 3 then
			t = 3
		end
		self.LastPulse = CurTime() + t
	end

	if self.LastEvolve <= CurTime() then
		self.LastEvolve = CurTime() + 1
		local bonus = {increase = 0}
		hook.Run("Horde_OnAntlionSelfEvolve", self.Owner, self, bonus)
		self:Horde_Evolve(10 * (1 + bonus.increase))
	end
end

function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
    if HORDE:IsPoisonDamage(dmginfo) then
		if self.Evolve_Stage == 2 then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.5)
		elseif self.Evolve_Stage >= 3 then
			dmginfo:SetDamage(0)
		end
    end
end

function ENT:RangeAttackLocation(pos)
	local selfData = self:GetTable()
	selfData.AttackType = VJ.ATTACK_TYPE_RANGE
	selfData.AttackState = VJ.ATTACK_STATE_STARTED
	self:OnRangeAttack("Init", ene)
	self:PlaySoundSystem("BeforeRangeAttack")
	local seed = CurTime()
	selfData.AttackSeed = seed
	local anim, animDur, animType = self:PlayAnim(selfData.AnimTbl_RangeAttack, false, 0, false, selfData.RangeAttackAnimationDelay)
	timer.Create("attack_range_start" .. self:EntIndex(), selfData.TimeUntilRangeAttackProjectileRelease / selfData.AnimPlaybackRate, selfData.RangeAttackReps, function() if selfData.AttackSeed == seed then self:ExecuteRangeAttack() end end)
	if anim != ACT_INVALID then
		selfData.AttackAnim = anim
		selfData.AttackAnimDuration = animDur - (selfData.RangeAttackAnimationDecreaseLengthAmount / selfData.AnimPlaybackRate)
		if animType != ANIM_TYPE_GESTURE then
			selfData.AttackAnimTime = CurTime() + selfData.AttackAnimDuration
		end
	end
	if !selfData.TimeUntilRangeAttackProjectileRelease then
		attackTimers[VJ_ATTACK_RANGE](self)
	else
		timer.Create("timer_range_start"..self:EntIndex(), selfData.TimeUntilRangeAttackProjectileRelease / self:GetPlaybackRate(), selfData.RangeAttackReps, function() self:RangeAttackP(pos) end)
	end
end

function ENT:CustomRangeAttackCode_BeforeProjectileSpawn(projectile)
	projectile.Owner = self
	projectile.BaseDamage = self.RangeAttackDamage
end

function ENT:RangeAttackP(pos)
	local selfData = self:GetTable()
	if selfData.Dead or selfData.PauseAttacks or selfData.Flinching or selfData.AttackType == VJ.ATTACK_TYPE_MELEE then return end
	local ene = self:GetEnemy()
	local eneValid = IsValid(ene)
	selfData.AttackType = VJ.ATTACK_TYPE_RANGE
	if !self:OnRangeAttackExecute("Init", ene) then
		local projectile = ents.Create(self.RangeAttackEntityToSpawn)
		local target_pos = pos + Vector(0, 0, 10)
		projectile.Owner = self
		projectile.BaseDamage = self.RangeAttackDamage
		projectile:SetPos(self:GetPos() + self:GetUp()*self.RangeAttackPos_Up)
		projectile:SetAngles((target_pos - projectile:GetPos()):Angle())
		projectile:SetOwner(self)
		projectile:SetPhysicsAttacker(self)
		projectile:Spawn()
		projectile:Activate()
		local phys = projectile:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			local vel = (target_pos - self:GetAttachment(1).Pos) * 1.5
			phys:SetVelocity(vel)
			projectile:SetAngles(vel:GetNormalized():Angle())
		else
			local vel = self:RangeAttackProjVel(projectile)
			projectile:SetVelocity(vel)
			projectile:SetAngles(vel:GetNormalized():Angle())
		end
		self:OnRangeAttackExecute("PostSpawn", ene, projectile)
	end
	if selfData.AttackState < VJ.ATTACK_STATE_EXECUTED then
		if eneValid then
			self:PlaySoundSystem("RangeAttack")
		end
		selfData.AttackState = VJ.ATTACK_STATE_EXECUTED
		if selfData.TimeUntilRangeAttackProjectileRelease then
			attackTimers[VJ.ATTACK_TYPE_RANGE](self)
		end
	end
end
