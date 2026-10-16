AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = {"models/horde/gargantua/gargantua.mdl"}
ENT.StartHealth = 8000
ENT.HullType = HULL_HUMAN

ENT.SightDistance = 10000
ENT.SightAngle = 100
ENT.TurningSpeed = 40
ENT.MaxJumpLegalDistance = VJ_Set(400, 550)

ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.AttackProps = true
ENT.PushProps = true
ENT.PropAP_MaxSize = 2
ENT.FindEnemy_CanSeeThroughWalls = true

ENT.BloodColor = "Red"
ENT.Immune_Dissolve = true
ENT.Immune_Physics = true

ENT.CanFlinch = 0
ENT.NextFlinchTime = 2
ENT.AnimTbl_Flinch = {ACT_FLINCH_PHYSICS}
ENT.RunAwayOnUnknownDamage = false
ENT.CallForBackUpOnDamage = false

ENT.HasMeleeAttack = true
ENT.TimeUntilMeleeAttackDamage = 0.8
ENT.MeleeAttackDamage = 30
ENT.MeleeAttackDamageType = DMG_CLUB
ENT.MeleeAttackDistance = 65
ENT.MeleeAttackDamageDistance = 120
ENT.SlowPlayerOnMeleeAttack = false
ENT.SlowPlayerOnMeleeAttack_WalkSpeed = 100
ENT.SlowPlayerOnMeleeAttack_RunSpeed = 100
ENT.MeleeAttackBleedEnemy = false
ENT.HasExtraMeleeAttackSounds = true
ENT.MeleeAttackWorldShakeOnMiss = true
ENT.MeleeAttackWorldShakeOnMissAmplitude = 8

ENT.HasRangeAttack = true
ENT.RangeAttackEntityToSpawn = "obj_vj_horde_gonome_acid_cold"
ENT.RangeDistance = 2000
ENT.RangeToMeleeDistance = 250
ENT.NextRangeAttackTime = 5
ENT.TimeUntilRangeAttackProjectileRelease = 0.1
ENT.RangeAttackPos_Up = 10
ENT.RangeAttackPos_Forward = 50
ENT.RangeAttackPos_Right = -20

ENT.HasMeleeAttackKnockBack = true
ENT.MeleeAttackKnockBack_Forward1 = 100
ENT.MeleeAttackKnockBack_Forward2 = 100
ENT.MeleeAttackKnockBack_Up1 = 250
ENT.MeleeAttackKnockBack_Up2 = 260
ENT.MeleeAttackKnockBack_Right1 = 0
ENT.MeleeAttackKnockBack_Right2 = 0

ENT.FootStepTimeRun = 1
ENT.FootStepTimeWalk = 1
ENT.PushProps = true

ENT.SoundTbl_FootStep = {"horde/gargantua/gar_step1.ogg","horde/gargantua/gar_step1.ogg"}
ENT.SoundTbl_Breath = {"horde/gargantua/gar_breathe1.ogg","horde/gargantua/gar_breathe2.ogg","horde/gargantua/gar_breathe3.ogg"}
ENT.SoundTbl_Idle = {"horde/gargantua/gar_idle1.ogg","horde/gargantua/gar_idle2.ogg","horde/gargantua/gar_idle3.ogg"}
ENT.SoundTbl_Alert = {"horde/gargantua/gar_alert1.ogg","horde/gargantua/gar_alert2.ogg","horde/gargantua/gar_alert3.ogg"}
ENT.SoundTbl_BeforeMeleeAttack = ""
ENT.SoundTbl_MeleeAttackMiss = {"vj_zombies/slow/miss1.wav", "vj_zombies/slow/miss2.wav", "vj_zombies/slow/miss3.wav", "vj_zombies/slow/miss4.wav"}
ENT.SoundTbl_Pain = {"horde/gargantua/gar_pain1.ogg","horde/gargantua/gar_pain2.ogg","horde/gargantua/gar_pain3.ogg"}
ENT.SoundTbl_Death = {"horde/gargantua/gar_die1.ogg"}

ENT.Garg_CanFlame = false
ENT.Garg_FlameLevel = 0
ENT.Garg_NextFlameT = 0
ENT.Garg_MeleeLargeKnockback = false
ENT.NextFlashTime = CurTime()
ENT.NextFlashCooldown = 30
ENT.Garg_NextStompAttackT = CurTime()

function ENT:PreInit()
	self.TimersToRemove[#self.TimersToRemove + 1] = "garg_flame_reset"
end

function ENT:Init()
    self:SetCollisionBounds(Vector(70,70,210), Vector(-70,-70,0))
    self:SetModelScale(0.5)
    self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")

    local glow1 = ents.Create("env_sprite")
	glow1:SetKeyValue("model","models/horde/gargantua/gargeye1.vmt")
	glow1:SetKeyValue("GlowProxySize","2.0")
	glow1:SetKeyValue("renderfx","14")
	glow1:SetKeyValue("rendermode","3")
	glow1:SetKeyValue("disablereceiveshadows","0")
	glow1:SetKeyValue("spawnflags","0")
	glow1:SetParent(self)
	glow1:Fire("SetParentAttachment","head")
	glow1:Spawn()
	glow1:Activate()
	self:DeleteOnRemove(glow1)
end
ENT.Critical = nil

function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
    if HORDE:IsLightningDamage(dmginfo) or HORDE:IsBlastDamage(dmginfo) then
        dmginfo:ScaleDamage(1.25)
    end
    if HORDE:IsPhysicalDamage(dmginfo) then
        dmginfo:ScaleDamage(0.75)
    end
end

function ENT:CustomOnTakeDamage_AfterDamage(dmginfo, hitgroup)
    if not self.Critical and (self:Health() < self:GetMaxHealth() * 0.6) then
        self.Critical = true
        local light = ents.Create("light_dynamic")
        light:SetKeyValue("brightness", "5")
        light:SetKeyValue("distance", "200")
        light:Fire("Color", "255 0 0")
        light:SetParent(self)
        light:Fire("SetParentAttachment","head")
        light:Spawn()
        light:Activate()
        light:Fire("TurnOn", "", 0)
        self:DeleteOnRemove(light)
		self.light = light

		self:FlashBang()
		self.NextFlareTime = CurTime() + self.NextFlashCooldown
    end
end

function ENT:FlashBang()
    if !self:IsValid() then return end
    self:EmitSound("arccw_go/flashbang/flashbang_explode1.wav", 100, 100, 1, CHAN_ITEM)
    self:EmitSound("arccw_go/flashbang/flashbang_explode1_distant.wav", 140, 100, 1, CHAN_WEAPON)

    local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )

    util.Effect( "arccw_flashexplosion", effectdata)

    local flashorigin = self:GetPos()

    local flashpower = 2000
    local targets = ents.FindInSphere(flashorigin, flashpower)

    for _, k in pairs(targets) do
        if k:IsPlayer() then
            local dist = k:EyePos():Distance(flashorigin)
            local dp = (k:EyePos() - flashorigin):Dot(k:EyeAngles():Forward())

            local time = Lerp( dp, 2.5, 0.25 )

            time = Lerp( dist / flashpower, time, 0 )

            if k:VisibleVec( flashorigin ) then
                k:ScreenFade( SCREENFADE.IN, Color( 255, 0, 0, 255 ), 2.5, time )
            end

            k:SetDSP( 37, false )
		end
    end
end

function ENT:Garg_ResetFlame()
	if self.Garg_CanFlame then
		self:ResetTurnTarget()
	end
	self.Garg_CanFlame = false
	self.Garg_FlameLevel = 0
	self.DisableChasingEnemy = false
	VJ.STOPSOUND(self.Garg_FlameSd)
	self:StopParticles()
end

function ENT:OnMeleeAttack(status, enemy)
	if status == "Init" then
		local randMelee = math.random(1, 3)
		if randMelee == 1 then
			self.AnimTbl_MeleeAttack = "vjseq_smash"
			self.HasMeleeAttackKnockBack = false
			self.Garg_MeleeLargeKnockback = false
		elseif randMelee == 2 then
			self.AnimTbl_MeleeAttack = "vjseq_attack"
			self.HasMeleeAttackKnockBack = true
			self.Garg_MeleeLargeKnockback = false
		elseif randMelee == 3 then
			self.AnimTbl_MeleeAttack = "vjseq_kickcar"
			self.HasMeleeAttackKnockBack = true
			self.Garg_MeleeLargeKnockback = true
		end
	end
end

function ENT:RangeAttackProjPos(projectile)
	return self:GetPos() + self:GetUp() * 20 + self:GetForward() * 50 + self:GetRight() * -20
end
function ENT:RangeAttackProjVel(projectile)
	return VJ.CalculateTrajectory(self, self:GetEnemy(), "Line", projectile:GetPos(), 1, 200)
end

function ENT:OnThinkActive()
	if self.Garg_CanFlame && self.Garg_NextFlameT < CurTime() && self.AttackType == VJ.ATTACK_TYPE_NONE then
		self.DisableChasingEnemy = true
		self:StopMoving()

		if self.Garg_FlameLevel == 0 then
			self:PlayAnim("shootflames1", "LetAttacks", false)
			self.Garg_FlameLevel = 1
			self.Garg_NextFlameT = CurTime() + 0.8
			timer.Simple(0.5, function()
				if IsValid(self) && self.Garg_CanFlame then
					VJ.EmitSound(self, "horde/gargantua/gar_flamerun1.ogg", 80)
				end
			end)
			return
		end

		self.Garg_FlameLevel = 2
		self.Garg_NextFlameT = CurTime() + 0.2

		local range = 550
		VJ.ApplyRadiusDamage(self, self, self:GetPos() + self:OBBCenter() + self:GetForward()*50, range, 2, DMG_BURN, true, true, {UseConeDegree = 35}, function(ent) if HORDE:IsPlayerOrMinion(ent) then ent:Horde_AddDebuffBuildup(HORDE.Status_Necrosis, 7, self) end end)

		self.Garg_FlameSd = VJ_CreateSound(self, "horde/gargantua/gar_flamerun1.ogg")
		self:StopParticles()
		ParticleEffectAttach("xen_destroyer_flame", PATTACH_POINT_FOLLOW, self, 2)
		ParticleEffectAttach("xen_destroyer_flame", PATTACH_POINT_FOLLOW, self, 3)
		local startPos1 = self:GetAttachment(2).Pos
		local startPos2 = self:GetAttachment(3).Pos
		local tr1 = util.TraceLine({start = startPos1, endpos = startPos1 + self:GetForward()*range, filter = self})
		local tr2 = util.TraceLine({start = startPos2, endpos = startPos2 + self:GetForward()*range, filter = self})
		local hitPos1 = tr1.HitPos
		local hitPos2 = tr2.HitPos
		sound.EmitHint(SOUND_DANGER, (hitPos1 + startPos1) / 2, 300, 1, self)
		sound.EmitHint(SOUND_DANGER, (hitPos2 + startPos2) / 2, 300, 1, self)
	end

	if self.Critical then
		local p = 30 - (self.NextFlashTime - CurTime())
		if self.NextFlashTime < CurTime() then
			self.light:SetKeyValue("brightness", "15")
        	self.light:SetKeyValue("distance", "800")
			self:VJ_ACT_PLAYACTIVITY("bitehead", true, 1.5, false)
			self.Flashing = true
			self:EmitSound("horde/gargantua/gar_die2.ogg", 2000, 75, 1, CHAN_STATIC)
			timer.Simple(2, function ()
				if not self:IsValid() then return end
				self:FlashBang()
				self.Flashing = nil
				for _, k in pairs(ents.FindInSphere(self:GetPos(), 100)) do
					if k:IsPlayer() then
						local dmg = DamageInfo()
						dmg:SetDamage(k:Health())
						dmg:SetDamageType(DMG_SONIC)
						dmg:SetAttacker(self)
						dmg:SetInflictor(self)
						k:TakeDamageInfo(dmg)
					end
				end
				for _, k in pairs(ents.FindInSphere(self:GetPos(), 800)) do
					if k:IsPlayer() then
						local dmg = DamageInfo()
						dmg:SetDamage(50)
						dmg:SetDamageType(DMG_SONIC)
						dmg:SetAttacker(self)
						dmg:SetInflictor(self)
						k:TakeDamageInfo(dmg)
					elseif k:IsNPC() and k:GetClass() ~= "npc_vj_horde_xen_destroyer_unit" then
						local dmg = DamageInfo()
						dmg:SetDamage(100)
						dmg:SetDamageType(DMG_SONIC)
						dmg:SetAttacker(self)
						dmg:SetInflictor(self)
						k:TakeDamageInfo(dmg)
					end
				end
				self:VJ_ACT_PLAYACTIVITY("run")
				self.light:SetKeyValue("brightness", "2")
        		self.light:SetKeyValue("distance", "200")
			end)
			self.NextFlashTime = CurTime() + self.NextFlashCooldown
		elseif self.Flashing then
		elseif p <= 30 then
			self.light:SetKeyValue("brightness", tostring(0.5 * p))
        	self.light:SetKeyValue("distance", tostring(200 + 20 * p))
		end

		if self:IsOnGround() then
			self:SetLocalVelocity(self:GetMoveVelocity() * 2)
		end
	else
		self:SetLocalVelocity(self:GetMoveVelocity() * 1.5)
	end
	ParticleEffectAttach("vj_rocket_idle1_flare", PATTACH_POINT_FOLLOW, self, 1)
end

ENT.FlamethrowerCD = 0
function ENT:OnThinkAttack(isAttacking, enemy)
    local eneData = self.EnemyData
    local eneVisible = eneData.Visible
    local range = 550
    if eneVisible && self.AttackType == VJ.ATTACK_TYPE_NONE && eneData.DistanceNearest <= range && eneData.DistanceNearest > self.RangeToMeleeDistance && self.FlamethrowerCD < CurTime() then
        self.Garg_CanFlame = true
        self.HasRangeAttack = false
        self:SetTurnTarget(enemy, -1)
        local id = self:EntIndex()
        if self.Garg_FlameLevel == 2 then
            timer.Create("garg_flame_reset" .. id, 1, 0, function()
                if not self:IsValid() then timer.Remove("garg_flame_reset" .. id) return end
                self:Garg_ResetFlame()
                self.HasRangeAttack = true
                self.FlamethrowerCD = CurTime() + 5
                timer.Remove("garg_flame_reset" .. id)
            end)
        end
    else
        self:Garg_ResetFlame()
    end
end

ENT.DisableDefaultRangeAttackCode = true
function ENT:CustomRangeAttackCode()
	local range = 400
    local eneData = self.EnemyData
	local selfData = self:GetTable()
	if self.Garg_NextStompAttackT < CurTime() and eneData.DistanceNearest > self.RangeToMeleeDistance then
		selfData.RangeDistance = 2000
		selfData.AnimTbl_RangeAttack = {"stomp"}
		selfData.SoundTbl_BeforeRangeAttack = {}
		selfData.SoundTbl_RangeAttack = {"horde/gargantua/gar_stomp1.ogg"}

		local enemy_pos = self:GetEnemy():GetPos()
		local dist = enemy_pos:Distance(self:GetPos())
		local dir = enemy_pos - self:GetPos()
		dir:Normalize()
		local start = 0
		local i = 0
		timer.Simple(1.5, function ()
			if !IsValid(self) or !IsValid(self:GetEnemy()) then return end
			local tr = util.TraceLine({
				start = self:GetPos(),
				endpos = self:GetEnemy():GetPos(),
				filter = {self}
			})

			dir = tr.HitPos - self:GetPos()
			dir:Normalize()

			while (start < dist + 300) do
				local pos = self:GetPos() + dir * start
				timer.Simple(0.25 + i * 0.1, function()
					if !IsValid(self) then return end
					ParticleEffect("vj_explosionfire2", pos, Angle(0,0,0), nil)
					ParticleEffect("vj_explosion_rocks1", pos, Angle(0,0,0), nil)
					sound.Play("horde/gargantua/hit_large.ogg", pos)
					local dmg = DamageInfo()
					dmg:SetAttacker(self)
					dmg:SetInflictor(self)
					dmg:SetDamage(50)
					dmg:SetDamageType(DMG_CRUSH)
					util.BlastDamageInfo(dmg, pos, 175)
				end)
				i = i + 1
				start = start + 150
			end
		end)

		self.Garg_NextStompAttackT = CurTime() + 5
	end
end

function ENT:CustomOnRemove()
	VJ_STOPSOUND(self.Garg_FlameSd)
end

VJ.AddNPC("Xen Destroyer Unit","npc_vj_horde_xen_destroyer_unit", "Zombies")
