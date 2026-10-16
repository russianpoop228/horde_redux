AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = {"models/hordeshg/TankSentry.mdl"}
ENT.StartHealth = 800
ENT.SightDistance = 8000
ENT.HullType = HULL_HUMAN
ENT.MovementType = VJ_MOVETYPE_STATIONARY
ENT.SightAngle = 360
ENT.Immune_Physics = true
ENT.Immune_AcidPoisonRadiation = true
ENT.Horde_Immune_Status_All = true
ENT.CanTurnWhileStationary = true
ENT.HasPoseParameterLooking = true
ENT.PoseParameterLooking_TurningSpeed = 30
ENT.PoseParameterLooking_CanReset = true
ENT.FindEnemy_UseSphere = true

ENT.HasRangeAttack = true
ENT.RangeDistance = 1500
ENT.RangeAttackAngleRadius = 360
ENT.NextRangeAttackTime = 1.5
ENT.NextAnyAttackTime_Range = 0.1
ENT.DisableDefaultRangeAttackCode = true
ENT.DisableRangeAttackAnimation = true
ENT.TimeUntilRangeAttackProjectileRelease = 0

ENT.VJ_NPC_Class = {"CLASS_PLAYER_ALLY", "CLASS_COMBINE"}
ENT.FriendlyMinion = true
ENT.PlayerFriendly = true
ENT.HasDeathCorpse = false

ENT.HasSounds = true
ENT.SoundTbl_Idle = {"npc/turret_floor/ping.wav"}
ENT.SoundTbl_Alert = {"npc/turret_floor/deploy.wav"}

ENT.NextRegenT = 0
ENT.NextTowerLinkT = 0
ENT.NextShockTimeT = 0
ENT.Sentry_NextAlarmT = 0
ENT.Sentry_AttackDelay = 2
ENT.TowerConnectionsCount = 0

function ENT:CustomOnInitialize()
	self:SetCollisionBounds(Vector(15, 15, 60), Vector(-15, -15, 0))

	timer.Simple(0.1, function()
		if IsValid(self) then
			HORDE:DropTurret(self)
			self:SetMaxHealth(800)
			self:SetHealth(800)
		end
	end)
end

function ENT:CustomOnThink_AIEnabled()
	if self.Dead then return end
	local curTime = CurTime()

    local regenInterval = math.max(1, 5 - (self.TowerConnectionsCount or 0))
    if curTime >= (self.NextRegenT or 0) then
        if self:Health() < self:GetMaxHealth() then
            self:SetHealth(math.min(self:GetMaxHealth(), self:Health() + 10))
            VJ_EmitSound(self, "items/suitchargeok1.wav", 65, 100)
        end
        self.NextRegenT = curTime + regenInterval
    end

    if curTime >= (self.NextTowerLinkT or 0) then
        self:ConnectToWardenNetwork()
        self.NextTowerLinkT = curTime + 0.1
    end

	self:MeleeShockAttack()

local enemy = self:GetEnemy()
	if IsValid(enemy) then
		if curTime >= (self.Sentry_NextAttackT or 0) then
			if self:Visible(enemy) then
				self:CustomRangeAttackCode()

				self.Sentry_NextAttackT = curTime + self.Sentry_AttackDelay
			end
		end

		if curTime > (self.Sentry_NextAlarmT or 0) then
			local glow = ents.Create("env_sprite")
			glow:SetKeyValue("model","vj_base/sprites/vj_glow1.vmt")
			glow:SetKeyValue("scale", "0.15")
			glow:SetKeyValue("rendermode","5")
			glow:SetKeyValue("rendercolor","255 0 0")
			glow:SetParent(self)
			glow:Fire("SetParentAttachment", "circles")
			glow:Spawn()
			glow:Fire("Kill", "", 0.1)
			self.Sentry_NextAlarmT = curTime + 1
		end
	else
		self:SetPoseParameter("aim_yaw", self:GetPoseParameter("aim_yaw") + 2)
	end
end

function ENT:ConnectToWardenNetwork()
    local myOwner = self:GetNWEntity("HordeOwner")
    if !IsValid(myOwner) then self.TowerConnectionsCount = 0 return end

    local myPos = self:GetPos()
    local attach_id = self:LookupAttachment("muzzle")
    local startPos = (attach_id != 0 and self:GetAttachment(attach_id).Pos) or (myPos + self:OBBCenter())

    local count = 0
    for _, ent in pairs(ents.FindInSphere(myPos, 500)) do
        if IsValid(ent) and ent != self and ent.Horde_WatchTower and ent:GetNWEntity("HordeOwner") == myOwner then
            local endPos = ent:GetPos() + ent:OBBCenter()

            local tr = util.TraceLine({start = startPos, endpos = endPos, filter = {self, ent}, mask = MASK_SHOT_HULL})
            if !tr.HitWorld then
                count = count + 1
                local effectdata = EffectData()
                effectdata:SetOrigin(endPos)
                effectdata:SetStart(startPos)
                effectdata:SetEntity(self)
                util.Effect("horde_laser_turret_laser", effectdata)

                local enemies = ents.FindInBox(startPos, endPos)
                for _, ene in pairs(enemies) do
                    if HORDE:IsEnemy(ene) then
                        local dmg = DamageInfo()
                        dmg:SetAttacker(myOwner)
                        dmg:SetInflictor(self)
                        dmg:SetDamageType(DMG_BLAST)
                        dmg:SetDamage(2)
                        ene:TakeDamageInfo(dmg)
                    end
                end
            end
        end
    end
    self.TowerConnectionsCount = count
end

function ENT:MeleeShockAttack()
    if CurTime() < (self.NextShockTimeT or 0) then return end
    local myPos = self:GetPos()
    local hit = false
    for _, ent in pairs(ents.FindInSphere(myPos, 200)) do
        if (ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer()) and ent != self then
            if self:Disposition(ent) == D_HT then
                hit = true
                local dmg = DamageInfo()
                dmg:SetAttacker(self)
                dmg:SetInflictor(self)
                dmg:SetDamageType(DMG_SHOCK)
                dmg:SetDamage(50)
                ent:TakeDamageInfo(dmg)
                if ent.Horde_AddDebuffBuildup then
                    ent:Horde_AddDebuffBuildup(HORDE.Status_Shock, 4, self)
                end
            end
        end
    end
    if hit then
        local e = EffectData()
        e:SetOrigin(myPos + self:GetUp())
        e:SetNormal(Vector(0,0,1))
        e:SetAngles(Angle(-90, 0, 0))
        util.Effect("screecher_blast", e)
        VJ_EmitSound(self, "ambient/energy/zap9.wav", 80, 100)
        self.NextShockTimeT = CurTime() + 2
    end
end

function ENT:CustomRangeAttackCode()
	local enemy = self:GetEnemy()
	if !IsValid(enemy) then return end

	local attach_id = self:LookupAttachment("muzzle")
	local attach_pos = (attach_id != 0 and self:GetAttachment(attach_id).Pos) or (self:GetPos() + self:GetUp())

	VJ_EmitSound(self, {"npc/assassin/ball_zap1.wav"}, 100, 100)

	local bullet = {}
	bullet.Num = 1
	bullet.Src = attach_pos
	bullet.Dir = (enemy:GetPos() + enemy:OBBCenter()) - attach_pos
	bullet.Spread = Vector(0.01, 0.01, 0)
	bullet.Tracer = 1
	bullet.TracerName = "Tracer"
	bullet.Damage = 150
	bullet.IgnoreEntity = self
	self:FireBullets(bullet)

	local muz = ents.Create("env_sprite_oriented")
	muz:SetKeyValue("model","vj_hl/sprites/muzzleflash3.vmt")
	muz:SetKeyValue("scale", 3)
	muz:SetKeyValue("rendermode","3")
	muz:SetParent(self)
	muz:Fire("SetParentAttachment", "muzzle")
	muz:Spawn()
	muz:Activate()
	muz:Fire("Kill","",0.08)
end

function ENT:CustomOnTakeDamage_BeforeDamageWasApplied(dmginfo, hitgroup)
	if dmginfo:IsDamageType(DMG_CRUSH) then
		dmginfo:SetDamage(0)
		return true
	end
end

VJ.AddNPC("Tank Turret","npc_vj_horde_tank_turret", "Horde")
ENT.Horde_TurretMinion = true

function ENT:Follow(ply)
	if self:GetNWEntity("HordeOwner") == ply then
		self:PhysicsInit(SOLID_VPHYSICS)
        ply:PickupObject(self)
		self:GetPhysicsObject():EnableMotion(true)
		self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
		self.Horde_Pickedup = true
		timer.Simple(0.2, function () if IsValid(self) then self.Horde_Pickedup = nil end end)
    end
end
