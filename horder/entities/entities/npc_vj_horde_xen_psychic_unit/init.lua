AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = {"models/horde/kingpin/kingpin.mdl"}
ENT.StartHealth = 7000
ENT.HullType = HULL_MEDIUM_TALL

ENT.SightDistance = 10000
ENT.SightAngle = 360
ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.BloodColor = "Red"
ENT.Immune_Dissolve = true
ENT.Immune_Physics = true

ENT.CanFlinch = 0
ENT.NextFlinchTime = 2
ENT.AnimTbl_Flinch = {ACT_FLINCH_PHYSICS}

ENT.HasMeleeAttack = true
ENT.AnimTbl_MeleeAttack = {"attack1", "attack2"}
ENT.MeleeAttackDistance = 60
ENT.MeleeAttackDamageDistance = 105
ENT.TimeUntilMeleeAttackDamage = 0.5
ENT.MeleeAttackDamage = 30

ENT.HasRangeAttack = true
ENT.RangeAttackEntityToSpawn = "obj_vj_horde_homing_lightning"
ENT.RangeDistance = 3000
ENT.RangeToMeleeDistance = 180
ENT.NextRangeAttackTime = VJ.SET(6, 8)
ENT.TimeUntilRangeAttackProjectileRelease = 0.1
ENT.RangeAttackPos_Up = 65
ENT.DisableDefaultRangeAttackCode = true
ENT.RangeAttackPos_Forward = 65
ENT.RangeAttackPos_Right = 65

ENT.HasMeleeAttackKnockBack = true
ENT.MeleeAttackKnockBack_Forward1 = 100
ENT.MeleeAttackKnockBack_Forward2 = 100
ENT.MeleeAttackKnockBack_Up1 = 50
ENT.MeleeAttackKnockBack_Up2 = 50
ENT.MeleeAttackKnockBack_Right1 = 0
ENT.MeleeAttackKnockBack_Right2 = 0

ENT.FootStepTimeRun = 1
ENT.FootStepTimeWalk = 1
ENT.PushProps = true

ENT.SoundTbl_FootStep = {"horde/kingpin/kingpin_step01.ogg","horde/kingpin/kingpin_step02.ogg","horde/kingpin/kingpin_step03.ogg"}
ENT.SoundTbl_Breath = {"horde/kingpin/kingpin_breath01.mp3","horde/kingpin/kingpin_breath02.mp3"}
ENT.SoundTbl_Idle = {"horde/kingpin/kingpin_idle01.mp3","horde/kingpin/kingpin_idle02.mp3"}
ENT.SoundTbl_Alert = {"horde/kingpin/kingpin_alert.mp3"}
ENT.SoundTbl_BeforeMeleeAttack = {"horde/kingpin/kingpin_melee.ogg"}
ENT.SoundTbl_MeleeAttackMiss = {"horde/kingpin/kingpin_meleemiss01.ogg","horde/kingpin/kingpin_meleemiss02.ogg"}
ENT.SoundTbl_Pain = {"horde/kingpin/kingpin_injured01.mp3","horde/kingpin/kingpin_injured02.mp3","horde/kingpin/kingpin_injured03.mp3"}
ENT.SoundTbl_Death = {"horde/kingpin/kingpin_death01.mp3"}

ENT.NextChangeTime = CurTime() + 15
ENT.NextChangeCooldown = 15

ENT.Combat_Mode = 0

function ENT:MaintainAlertBehavior(alwaysChase)
	alwaysChase = true
	local curTime = CurTime()
	local selfData = self:GetTable()
	if selfData.NextChaseTime > curTime or selfData.Dead or selfData.VJ_IsBeingControlled or selfData.Flinching or self:GetState() == VJ_STATE_ONLY_ANIMATION_CONSTANT then return end
	local ene = self:GetEnemy()
	local moveType = selfData.MovementType
	if !IsValid(ene) or selfData.TakingCoverT > curTime or (selfData.AttackAnimTime > curTime && moveType != VJ_MOVETYPE_AERIAL && moveType != VJ_MOVETYPE_AQUATIC) then return end

	local eneData = selfData.EnemyData
	if selfData.HasMeleeAttack && eneData.DistanceNearest < selfData.MeleeAttackDistance && eneData.Visible && (self:GetHeadDirection():Dot((ene:GetPos() - self:GetPos()):GetNormalized()) > math_cos(math_rad(selfData.MeleeAttackAngleRadius))) then
		if moveType == VJ_MOVETYPE_AERIAL or moveType == VJ_MOVETYPE_AQUATIC then
			self:AA_StopMoving()
		end
		self:SCHEDULE_IDLE_STAND()
		return
	end

	self:SCHEDULE_ALERT_CHASE()

	if selfData.NextChaseTime > curTime then return end
	selfData.NextChaseTime = curTime + 0.1
end

function ENT:CustomOnInitialize()
    self:SetCollisionBounds(Vector(35, 35, 110),Vector(-35, -35, 0))
    self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
	local shield = ents.Create("prop_dynamic_override")
	shield:SetModel("models/horde/kingpin/kingpin_sphereshield.mdl")
	shield:SetModelScale(0.5)
	shield:SetPos(self:GetPos() + self:OBBCenter())
	shield:SetParent(self)
	shield:DrawShadow(false)
	shield:Spawn()
	shield:Activate()
	self.bShieldActive = true
	self.entShield = shield
	self:DisableShield()
	self.NextChangeTime = CurTime() + 15
end

function ENT:DisableShield()
	if IsValid(self.entShield) then self.entShield:SetNoDraw(true); self.bShieldActive = false end
end

function ENT:EnableShield()
	if IsValid(self.entShield) then self.entShield:SetNoDraw(false); self.bShieldActive = true end
end
ENT.Critical = nil
function ENT:CustomOnTakeDamage_AfterDamage(dmginfo, hitgroup)
    if not self.Critical and (self:Health() < self:GetMaxHealth() * 0.6) then
        self.Critical = true
		self.NextRangeAttackTime = 4
		self.NextRangeAttackTime_DoRand = 6
    end
end

function ENT:CustomRangeAttackCode_AfterProjectileSpawn(projectile)
	projectile:SetEntityOwner(self)
	projectile:SetScale(2)
	projectile.Target = self:GetEnemy()
end

function ENT:OnThinkActive()
	local selfData = self:GetTable()

	if CurTime() > self.NextChangeTime and self.Critical then
		self.Combat_Mode = self.Combat_Mode + 1
		if self.Combat_Mode > 1 then
			self.Combat_Mode = 0
		end

		if self.Combat_Mode == 0 then
			self:DisableShield()
			self.HasRangeAttack = true
		else
			self:EnableShield()
			self.HasRangeAttack = false
		end
		self.NextChangeTime = CurTime() + self.NextChangeCooldown
	end

	if self.Combat_Mode == 1 and self:IsOnGround() then
		self:SetLocalVelocity(self:GetMoveVelocity() * 6)
		self:SetPlaybackRate(1.25)
	end

	if self:IsOnFire() then
		self:Extinguish()
	end
end

function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
    if self.bShieldActive then
		dmginfo:SubtractDamage(5)
        dmginfo:ScaleDamage(0.5)
    end
	if HORDE:IsFireDamage(dmginfo) or HORDE:IsLightningDamage(dmginfo) then
		dmginfo:ScaleDamage(0.75)
	elseif HORDE:IsColdDamage(dmginfo) then
		dmginfo:ScaleDamage(1.25)
	end
end

function ENT:CustomRangeAttackCode()
	local selfData = self:GetTable()
	local p = math.random()
	if p <= 0.5 and not self.Horde_Blasting then
		local projectile = ents.Create(selfData.RangeAttackEntityToSpawn)
		local target_pos = self:GetEnemy():GetPos()
		projectile:SetPos(self:GetPos() + self:GetUp()*selfData.RangeAttackPos_Up + self:GetForward()*selfData.RangeAttackPos_Forward)
		projectile:SetAngles((target_pos - projectile:GetPos()):Angle())
		projectile:SetOwner(self)
		projectile:SetPhysicsAttacker(self)
		projectile:Spawn()
		projectile:Activate()
		local phys = projectile:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			local vel = (self:GetEnemy():GetPos() - projectile:GetPos())
			vel:Normalize()
			vel = vel * 200
			if self.Critical then
				timer.Simple(0.2, function ()
					if !IsValid(self) then return end
					local projectile2 = ents.Create("obj_vj_horde_homing_lightning")
					projectile2:SetPos(self:GetPos() + self:GetUp()*self.RangeAttackPos_Up + self:GetForward()*self.RangeAttackPos_Forward + self:GetRight()*self.RangeAttackPos_Right)
					projectile2:SetAngles((self:GetEnemy():GetPos() - projectile2:GetPos()):Angle())
					projectile2:SetOwner(self)
					projectile2:SetPhysicsAttacker(self)
					projectile2:Spawn()
					projectile2:Activate()
					local phys2 = projectile2:GetPhysicsObject()
					if IsValid(phys2) then
						phys2:Wake()
						local vel2 = (self:GetEnemy():GetPos() - projectile2:GetPos())
						vel2:Normalize()
						vel2 = vel2 * 200
						phys:SetVelocity(vel2)
					end
					self:CustomRangeAttackCode_AfterProjectileSpawn(projectile2)
				end)
			end
			phys:SetVelocity(vel)
			projectile:SetAngles(vel:GetNormal():Angle())
			self:CustomRangeAttackCode_AfterProjectileSpawn(projectile)
		end
	else
        local EnemyDistance = self.EnemyData.Distance
        if self:GetEnemy() and EnemyDistance <= 250 then return end
		local pos = self:GetEnemy():GetPos()
		self.Horde_Blasting = true
		timer.Simple(0.5, function ()
			if !IsValid(self) or !IsValid(self:GetEnemy()) then return end
			local tr = util.TraceLine({
				start = self:GetPos() + self:GetUp() * 60,
				endpos = self:GetEnemy():GetPos(),
				filter = {self}
			})
			pos = tr.HitPos
			util.ParticleTracerEx("Weapon_Combine_Ion_Cannon", self:GetPos() + self:GetUp() * 60, pos, true, self:EntIndex(), -1)
			sound.Play("beams/beamstart5.wav", pos, 100, math.random(90, 110))

			timer.Simple(0.7, function ()
				if !IsValid(self) then return end
				local dmg = DamageInfo()
				dmg:SetDamage(70)
				dmg:SetDamageType(DMG_SHOCK)
				dmg:SetAttacker(self)
				dmg:SetInflictor(self)
				dmg:SetDamagePosition(pos)
				util.BlastDamageInfo(dmg, pos, 200)

				if self.Critical then
					local fire = ents.Create("horde_lightning_homing_fire")
					fire:SetOwner(self)
					fire:SetPos(pos)
					fire:Spawn()
				end

				ParticleEffect("Weapon_Combine_Ion_Cannon_Explosion", pos, Angle(0,0,0), nil)
				sound.Play("ambient/explosions/explode_5.wav", pos, 100, math.random(90, 110))
				self:VJ_ACT_PLAYACTIVITY("run")

				self.Horde_Blasting = nil
			end)
		end)
	end
end

VJ.AddNPC("Xen Psychic Unit","npc_vj_horde_xen_psychic_unit", "Zombies")
