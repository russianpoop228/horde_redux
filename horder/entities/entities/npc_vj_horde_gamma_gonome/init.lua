AddCSLuaFile("shared.lua")
include('shared.lua')
include('autorun/vj_controls.lua')

ENT.Model = {"models/horde/gonome/gonome.mdl"}
ENT.StartHealth = 7500
ENT.HullType = HULL_MEDIUM_TALL
ENT.KnockbackImmune = true

ENT.SightDistance = 10000
ENT.SightAngle = 100
ENT.TurningSpeed = 40
ENT.MaxJumpLegalDistance = VJ_Set(400, 550)

ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.ConstantlyFaceEnemy = true
ENT.ConstantlyFaceEnemy_IfAttacking = true
ENT.ConstantlyFaceEnemy_Postures = "Standing"
ENT.ConstantlyFaceEnemyDistance = 2000
ENT.NoChaseAfterCertainRange = false
ENT.NoChaseAfterCertainRange_FarDistance = "UseRangeDistance"
ENT.NoChaseAfterCertainRange_CloseDistance = "UseRangeDistance"
ENT.NoChaseAfterCertainRange_Type = "OnlyRange"
ENT.InvestigateSoundDistance = 100

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
ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
ENT.MeleeAttackDistance = 35
ENT.MeleeAttackDamageDistance = 90
ENT.TimeUntilMeleeAttackDamage = 0.6
ENT.NextAnyAttackTime_Melee = 0.8
ENT.MeleeAttackDamage = 40
ENT.SlowPlayerOnMeleeAttack = true
ENT.SlowPlayerOnMeleeAttack_WalkSpeed = 100
ENT.SlowPlayerOnMeleeAttack_RunSpeed = 100
ENT.MeleeAttackBleedEnemy = false
ENT.HasExtraMeleeAttackSounds = true
ENT.MeleeAttackWorldShakeOnMiss = true
ENT.MeleeAttackWorldShakeOnMissAmplitude = 8

ENT.HasRangeAttack = true
ENT.AnimTbl_RangeAttack = {ACT_RANGE_ATTACK1}
ENT.RangeAttackEntityToSpawn = "obj_vj_horde_gonome_acid_cold"
ENT.RangeDistance = 2000
ENT.RangeToMeleeDistance = 150
ENT.RangeUseAttachmentForPos = false
ENT.RangeUseAttachmentForPosID = "Mouth"
ENT.TimeUntilRangeAttackProjectileRelease = 1.5
ENT.NextRangeAttackTime = 5
ENT.NextAnyAttackTime_Range = 0.5

ENT.HasLeapAttack = false
ENT.AnimTbl_LeapAttack = {ACT_RANGE_ATTACK2}
ENT.LeapAttackAnimationDelay = 0
ENT.NextLeapAttackTime = 15
ENT.LeapAttackVelocityForward = 400
ENT.LeapAttackVelocityUp = 0
ENT.LeapAttackDamageDistance = 150

ENT.HasMeleeAttackKnockBack = true
ENT.MeleeAttackKnockBack_Forward1 = 100
ENT.MeleeAttackKnockBack_Forward2 = 100
ENT.MeleeAttackKnockBack_Up1 = 10
ENT.MeleeAttackKnockBack_Up2 = 10
ENT.MeleeAttackKnockBack_Right1 = 0
ENT.MeleeAttackKnockBack_Right2 = 0

ENT.FootStepTimeRun = 0.3
ENT.FootStepTimeWalk = 0.3

ENT.SoundTbl_FootStep = {"horde/gonome/gonome_step1.ogg","horde/gonome/gonome_step2.ogg","horde/gonome/gonome_step3.ogg","horde/gonome/gonome_step4.ogg"}
ENT.SoundTbl_Idle = {"horde/gonome/gonome_idle1.ogg","horde/gonome/gonome_idle2.ogg"}
ENT.SoundTbl_MeleeAttack = {"horde/gonome/gonome_melee1.ogg","horde/gonome/gonome_melee2.ogg"}
ENT.SoundTbl_MeleeAttackMiss = {"horde/gonome/gonome_melee1.ogg","horde/gonome/gonome_melee2.ogg"}
ENT.SoundTbl_BeforeLeapAttack = nil
ENT.SoundTbl_LeapAttackJump = {"horde/gonome/gonome_jumpattack.ogg"}
ENT.SoundTbl_Pain = {"horde/gonome/gonome_pain1.ogg","horde/gonome/gonome_pain2.ogg","horde/gonome/gonome_pain3.ogg","horde/gonome/gonome_pain4.ogg"}
ENT.SoundTbl_Death = {"horde/gonome/gonome_death.ogg"}

ENT.NextBlastTime = CurTime()
ENT.NextBlastCooldown = 15
ENT.InvisBreakDmg = 0
ENT.InvisBreakDmgMax = 0
function ENT:CustomOnInitialize()
    self:SetCollisionBounds(Vector(20, 20, 85), Vector(-20, -20, 0))
    self:SetSkin(1)
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetColor(Color(0, 150, 255, 150))
    self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
end

function ENT:GoInvis()
    self:SetColor(Color(0, 150, 255, 50))
    self.Horde_Gamma_Invis = true
end

function ENT:UnInvis()
    self:SetColor(Color(0, 150, 255, 255))
    self.Horde_Gamma_Invis = nil
end

function ENT:RangeAttackCode_GetShootPos(TheProjectile)
    return (self:GetEnemy():GetPos() - self:LocalToWorld(Vector(math.random(-30,30),math.random(-30,30),math.random(20,30))))*2 + self:GetUp()*300
end

function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
    if dmginfo:GetAttacker() == self then dmginfo:SetDamage(0) return true end
	if HORDE:IsColdDamage(dmginfo) then
		dmginfo:ScaleDamage(0.5)
    elseif HORDE:IsFireDamage(dmginfo) then
        dmginfo:ScaleDamage(1.25)
    end

    if self.InvisBreakDmg >= 500 then
        self:UnInvis()
        local id = self:GetCreationID()
        timer.Remove("Horde_GammaGoInvis" .. id)
        timer.Create("Horde_GammaGoInvis" .. id, 5, 1, function ()
            if not self:IsValid() then timer.Remove("Horde_GammaGoInvis" .. id) return end
            self:GoInvis()
        end)
        self.InvisBreakDmg = 0
    else
        self.InvisBreakDmg = self.InvisBreakDmg + dmginfo:GetDamage()
    end
end

function ENT:CustomOnMeleeAttack_BeforeChecks()
    self:UnInvis()
    local id = self:GetCreationID()
    timer.Remove("Horde_GammaGoInvis" .. id)
    timer.Create("Horde_GammaGoInvis" .. id, 5, 1, function ()
        if not self:IsValid() then timer.Remove("Horde_GammaGoInvis" .. id) return end
        self:GoInvis()
    end)
end

function ENT:ColdAttack(delay, dir)
    timer.Simple(delay - 1, function()
		if not self:IsValid() then return end
        local rand = VectorRand()
        rand.z = 0
        local pos = self:GetPos() + dir

        local e = EffectData()
			e:SetOrigin(pos)
			e:SetScale(1)
		util.Effect("horde_ring_effect", e, true, true)
	end)
	timer.Simple(delay, function()
		if not self:IsValid() then return end
        local rand = VectorRand()
        rand.z = 0
        local pos = self:GetPos() + dir

		local dmg = DamageInfo()
		dmg:SetAttacker(self)
		dmg:SetInflictor(self)
		dmg:SetDamageType(DMG_REMOVENORAGDOLL)
		dmg:SetDamage(25)
		util.BlastDamageInfo(dmg, pos, 200)

		for _, ent in pairs(ents.FindInSphere(pos, 200)) do
			if ent:IsPlayer() then
				ent:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 4, self)
			end
		end

        local e = EffectData()
			e:SetOrigin(pos)
			e:SetScale(1)
		util.Effect("weeper_blast", e, true, true)
        sound.Play("horde/status/cold_explosion.ogg", pos, 80, math.random(70, 90))
	end)
end

function ENT:Horde_SpawnIce(right)
    local projectile = ents.Create(self.RangeAttackEntityToSpawn)
    projectile:SetPos(self:GetPos() + self:GetUp()*(self.RangeAttackPos_Up or 20) + self:GetForward()*(self.RangeAttackPos_Forward or 0) + self:GetRight()*(self.RangeAttackPos_Right or 0))
    projectile:SetOwner(self)
    projectile:SetPhysicsAttacker(self)
    projectile:Spawn()
    projectile.RadiusDamageRadius = 150
    projectile:Activate()
    local phys = projectile:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        local vel = self:RangeAttackCode_GetShootPos(projectile)
        local ang = vel:Angle()
        local right_vec = ang:Right()
        local v2
        if right then
            v2 = vel:Length() * (vel:GetNormal() * 0.7 + right_vec:GetNormal() * 0.3)
        else
            v2 = vel:Length() * (vel:GetNormal() * 0.7 - right_vec:GetNormal() * 0.3)
        end

        phys:SetVelocity(v2)
        projectile:SetAngles(v2:GetNormal():Angle())
    end
end

ENT.RangeAttackCooldown = 0
function ENT:CustomRangeAttackCode_BeforeProjectileSpawn(projectile2)
    if true then
        if not self.Critical then
            self:Horde_SpawnIce(true)
            self:Horde_SpawnIce()
        end
		self.RangeAttackCooldown = CurTime() + self.NextRangeAttackTime
		self.HasRangeAttack = false
    end
end

function ENT:CustomOnThink()
	if self.Critical then
        if not self:GetEnemy() then return end
        local EnemyDistance = self.EnemyData.Distance
        if EnemyDistance < 800 then
            if CurTime() > self.NextBlastTime then
                sound.Play("horde/gonome/gonome_jumpattack.ogg", self:GetPos(), 100, 30)
                self:VJ_ACT_PLAYACTIVITY("big_flinch", true, 5, false)
                local p = math.random()
                local p2 = math.random()
                for i = 1, 20 do
                    self:ColdAttack(2, self:GetForward() * i * 100)
                    self:ColdAttack(2, -self:GetForward() * i * 100)
                    self:ColdAttack(2, self:GetRight() * i * 100)
                    self:ColdAttack(2, -self:GetRight() * i * 100)

                    local k1 = self:GetForward() + self:GetRight()
                    k1:Normalize()
                    local k2 = self:GetForward() - self:GetRight()
                    k2:Normalize()
                    self:ColdAttack(4, k1 * i * 100)
                    self:ColdAttack(4, -k1 * i * 100)
                    self:ColdAttack(4, k2 * i * 100)
                    self:ColdAttack(4, -k2 * i * 100)

                    if p <= 0.5 then
                        if p2 <= 0.5 then
                            self:ColdAttack(6, self:GetForward() * i * 100)
                            self:ColdAttack(6, -self:GetForward() * i * 100)
                            self:ColdAttack(6, self:GetRight() * i * 100)
                            self:ColdAttack(6, -self:GetRight() * i * 100)
                        else
                            self:ColdAttack(6, k1 * i * 100)
                            self:ColdAttack(6, -k1 * i * 100)
                            self:ColdAttack(6, k2 * i * 100)
                            self:ColdAttack(6, -k2 * i * 100)
                        end
                    end
                end
                self.NextBlastTime = CurTime() + self.NextBlastCooldown
                self:GoInvis()
                local id = self:GetCreationID()
                timer.Remove("Horde_GammaUnInvis" .. id)
                timer.Create("Horde_GammaUnInvis" .. id, 30, 1, function ()
                    if not self:IsValid() then timer.Remove("Horde_GammaUnInvis" .. id) return end
                    self:UnInvis()
                end)
            end
        end
	else
		if self.RangeAttackCooldown < CurTime() then
			self.HasRangeAttack = true
		end
	end

    if self:IsOnGround() and self.Horde_Gamma_Invis == true then
        if self.Critical then
            self:SetLocalVelocity(self:GetMoveVelocity() * 3)
        else
            self:SetLocalVelocity(self:GetMoveVelocity() * 2)
        end
	end
end
ENT.Critical = nil
function ENT:CustomOnTakeDamage_AfterDamage(dmginfo, hitgroup)
    if not self.Critical and (self:Health() < self:GetMaxHealth() * 0.6) then
        self.Critical = true
        self:SetColor(Color(0, 150, 255, 255))
    end
end

VJ.AddNPC("Gamma Gonome","npc_vj_horde_gamma_gonome", "Zombies")
