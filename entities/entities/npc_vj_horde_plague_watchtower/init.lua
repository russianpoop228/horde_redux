AddCSLuaFile("shared.lua")
include('shared.lua')

local HEAD_SCALE   = 0.1
local TOWER_ATTACH = "eyes"
local TOWER_SCALE  = 0.9
local TOWER_DROP   = 8
local TOWER_RADIUS = 128
local TOWER_ANGLE  = Angle(0, 180, 0)

local DAMAGE_SCALE  = 0.25
local MIN_ATTACK_INTERVAL = 3
local TOWER_ENGAGE  = 700

local HIT_ANIMS = { ACT_MELEE_ATTACK1, "swing", "seq_meleeattack01" }
local HIT_LAYER_RATE = 1.5

local WEAPON_MODEL  = "models/horde/weapons/c_machete.mdl"
local WEAPON_BONE   = "ValveBiped.Bip01_R_Hand"
local WEAPON_OFFSET = Vector(-9, -15, 10)
local WEAPON_ANGLE  = Vector(0, 0, 180)

local CHASE_DISTANCE = 200
local CHASE_RETRY    = 1
local CHASE_ACTIVITY = ACT_RUN

local DAMAGE_TYPES = {
    SHOCK     = { dmg = DMG_SHOCK,            effect = "explosion_shock",               color = Color(140, 200, 255) },
    BLAST     = { dmg = DMG_BLAST,            effect = "Explosion",                     color = Color(255, 120, 60) },
    BURN      = { dmg = DMG_BURN,             effect = "horde_blaster_flame_explosion", color = Color(255, 140, 40) },
    NERVEGAS  = { dmg = DMG_NERVEGAS,         effect = "corruption",                    color = Color(164, 0, 164) },
    COLD      = { dmg = DMG_REMOVENORAGDOLL,  effect = "cold_explosion",                color = Color(150, 220, 255) },
    BALLISTIC = { dmg = DMG_BULLET,           effect = nil,                             color = Color(180, 180, 180) },
}
local DEFAULT_DAMAGE_TYPE = "SHOCK"

local AIR_ANIMS = { ACT_CROUCHIDLE, ACT_COWER, ACT_IDLE_ANGRY, ACT_HOP }

ENT.Model = "models/police.mdl"
ENT.StartHealth = 1050
ENT.VJ_NPC_Class = {"CLASS_ZOMBIE", "CLASS_XEN"}
ENT.MeleeAttackDamage = 30
ENT.MoveType = MOVETYPE_STEP
ENT.HullType = HULL_HUMAN
ENT.SightDistance = 10000
ENT.SightAngle = 80
ENT.TurningSpeed = 20
ENT.Bleeds = true
ENT.BloodColor = "Red"
ENT.HasBloodParticle = true
ENT.HasBloodDecal = true
ENT.HasBloodPool = false
ENT.Flinches = 1
ENT.FlinchingChance = 12
ENT.FlinchingSchedules = {SCHED_FLINCH_PHYSICS}
ENT.MoveWhenDamagedByEnemy = false
ENT.MoveWhenDamagedByEnemySCHED1 = SCHED_FORCED_GO_RUN
ENT.MoveWhenDamagedByEnemySCHED2 = SCHED_FORCED_GO_RUN
ENT.NextMoveWhenDamagedByEnemy1 = 3
ENT.NextMoveWhenDamagedByEnemy2 = 3.5
ENT.HasAllies = true
ENT.Horde_Plague_Soldier = true

ENT.Weapon_UnarmedBehavior = false
ENT.HasMeleeAttack = true
ENT.AnimTbl_MeleeAttack = false
ENT.TimeUntilMeleeAttackDamage = 0.05
ENT.MeleeAttackDamage = 30
ENT.MeleeAttackDistance = 60
ENT.MeleeAttackDamageDistance = 110
ENT.MeleeAttackDamageAngleRadius = 180
ENT.MeleeAttackBleedEnemy = false
ENT.MeleeAttackAnimationStopAttacks = false
ENT.NextAnyAttackTime_Melee = 0.5
ENT.HasMeleeAttackKnockBack = true
ENT.MeleeAttackKnockBack_Forward1 = 60
ENT.MeleeAttackKnockBack_Forward2 = 90

ENT.HasGrenadeAttack = false
ENT.CallForBackUpOnDamage = false
ENT.CanDetectDangers = false
ENT.MoveOrHideOnDamageByEnemy = false
ENT.CallForHelp = false
ENT.CanInvestigate = false
ENT.FootStepTimeRun = 0.3
ENT.FootStepTimeWalk = 0.5
ENT.EntitiesToNoCollide = {"npc_vj_horde_zombine", "npc_vj_horde_plague_soldier"}

ENT.HasItemDropsOnDeath = false
ENT.DropWeaponOnDeath = false

ENT.SoundTbl_Pain = {
"npc/combine_soldier/pain1.wav",
"npc/combine_soldier/pain2.wav",
"npc/combine_soldier/pain3.wav"}

ENT.SoundTbl_FootStep = {
	"npc/combine_soldier/gear1.wav",
	"npc/combine_soldier/gear2.wav",
	"npc/combine_soldier/gear3.wav",
	"npc/combine_soldier/gear4.wav",
	"npc/combine_soldier/gear5.wav",
	"npc/combine_soldier/gear6.wav"}
ENT.SoundTbl_Idle = {"vj_zombies/zombine/idle1.wav", "vj_zombies/zombine/idle2.wav", "vj_zombies/zombine/idle3.wav", "vj_zombies/zombine/idle4.wav", "vj_zombies/zombine/idle5.wav"}
ENT.SoundTbl_Alert = {"vj_zombies/zombine/alert1.wav", "vj_zombies/zombine/alert2.wav", "vj_zombies/zombine/alert3.wav", "vj_zombies/zombine/alert4.wav", "vj_zombies/zombine/alert5.wav", "vj_zombies/zombine/alert6.wav"}

ENT.UseTheSameGeneralSoundPitch = true
ENT.GeneralSoundPitch1 = 75
ENT.GeneralSoundPitch2 = 75
function ENT:FindHeadBone()
	for i = 0, self:GetBoneCount() - 1 do
		local name = self:GetBoneName(i)
		if name and string.find(string.lower(name), "head", 1, true) then
			return i
		end
	end
	return nil
end

function ENT:ShrinkHead()
	if HEAD_SCALE >= 1 then return end
	local head = self:FindHeadBone()
	if not head then return end
	self.Horde_HeadBone = head
	self:ManipulateBoneScale(head, Vector(HEAD_SCALE, HEAD_SCALE, HEAD_SCALE))
end

local function GetDefenseTowers()
	local out = {}

	local by_category = HORDE.Horde_GetWardenBuildablesByCategory
		and HORDE:Horde_GetWardenBuildablesByCategory("defense")
	if istable(by_category) then
		for _, entry in ipairs(by_category) do
			if isstring(entry.ClassName) then out[#out + 1] = entry.ClassName end
		end
	end

	if #out == 0 and istable(HORDE.WardenBuildables) then
		for class, def in pairs(HORDE.WardenBuildables) do
			if istable(def) and def.Category == "defense" then out[#out + 1] = class end
		end
	end

	table.sort(out)
	return out
end

function ENT:SpawnWatchtower()
	local classes = GetDefenseTowers()
	if #classes == 0 then return end

	local class = classes[math.random(#classes)]
	self.WatchtowerClass = class

	local data = HORDE:Horde_GetWardenBuildableData(class)
	local damage_type = HORDE:Horde_GetWardenBuildableDamageType(class)
	self.WatchtowerDamageType = isstring(damage_type) and damage_type or DEFAULT_DAMAGE_TYPE
	local spec = DAMAGE_TYPES[self.WatchtowerDamageType] or DAMAGE_TYPES[DEFAULT_DAMAGE_TYPE]

	local rate = tonumber(HORDE:Horde_GetWardenBuildableFireRate(class)) or 1
	rate = math.max(0.1, rate)
	self.WatchtowerAttackInterval = math.max(MIN_ATTACK_INTERVAL, 1 / rate)

	local model = (istable(data) and isstring(data.Model) and data.Model) or "models/props_combine/combine_light001a.mdl"

	local tower = ents.Create("prop_dynamic")
	if not IsValid(tower) then return end
	tower:SetModel(model)
	tower:SetColor(spec.color)
	tower:SetRenderMode(RENDERMODE_TRANSCOLOR)
	tower:SetPos(self:GetPos() + Vector(0, 0, 90 - TOWER_DROP))
	tower:SetAngles(self:GetAngles() + TOWER_ANGLE)
	tower:Spawn()
	tower:SetModelScale(TOWER_SCALE)
	tower:SetSolid(SOLID_NONE)
	tower:SetMoveType(MOVETYPE_NONE)
	tower:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	tower:SetParent(self)

	self.WatchtowerMount = tower
	self.WatchtowerAttach = self:LookupAttachment(TOWER_ATTACH)
	self:DeleteOnRemove(tower)
	self:UpdateWatchtower()
end

function ENT:SpawnHandWeapon()
	local bone = self:LookupBone(WEAPON_BONE)
	if not bone then return end
	self.Horde_WeaponBone = bone

	local wep = ents.Create("prop_dynamic")
	if not IsValid(wep) then return end
	wep:SetModel(WEAPON_MODEL)
	wep:SetPos(self:GetPos() + Vector(0, 0, 40))
	wep:Spawn()
	wep:SetSolid(SOLID_NONE)
	wep:SetMoveType(MOVETYPE_NONE)
	wep:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	wep:SetModelScale(self:GetModelScale())
	wep:SetParent(self)

	self.FireAxe = wep
	self:DeleteOnRemove(wep)
	self:UpdateHandWeapon()
end

function ENT:UpdateHandWeapon()
	local wep = self.FireAxe
	if not IsValid(wep) then return end

	local bone = self.Horde_WeaponBone
	if not bone then return end

	local pos, ang = self:GetBonePosition(bone)
	ang:RotateAroundAxis(ang:Right(), WEAPON_ANGLE.x)
	ang:RotateAroundAxis(ang:Up(), WEAPON_ANGLE.y)
	ang:RotateAroundAxis(ang:Forward(), WEAPON_ANGLE.z)
	pos = pos + (WEAPON_OFFSET.x * ang:Right() + WEAPON_OFFSET.y * ang:Forward() + WEAPON_OFFSET.z * ang:Up())

	wep:SetLocalPos(self:WorldToLocal(pos))
	wep:SetLocalAngles(ang - self:GetAngles())
end

function ENT:UpdateWatchtower()
	local tower = self.WatchtowerMount
	if not IsValid(tower) then return end

	local pos
	local attach_id = self.WatchtowerAttach
	if attach_id and attach_id > 0 then
		local attach = self:GetAttachment(attach_id)
		if attach then pos = attach.Pos end
	end

	if not pos then
		tower:SetLocalPos(Vector(0, 0, 58 - TOWER_DROP))
		tower:SetLocalAngles(TOWER_ANGLE)
		return
	end

	pos.z = pos.z - TOWER_DROP
	tower:SetLocalPos(self:WorldToLocal(pos))
	tower:SetLocalAngles(TOWER_ANGLE)
end

function ENT:WatchtowerReach()
	local spec = DAMAGE_TYPES[self.WatchtowerDamageType] or DAMAGE_TYPES[DEFAULT_DAMAGE_TYPE]
	if spec.effect then return TOWER_RADIUS end
	return TOWER_ENGAGE
end

function ENT:FindWatchtowerTarget(radius)
	local tower = self.WatchtowerMount
	if not IsValid(tower) then return nil end
	local best, best_dist
	for _, ent in ipairs(ents.FindInSphere(tower:GetPos(), radius)) do
		if HORDE:IsPlayerOrMinion(ent) == true and not HORDE:IsPlayerSpectator(ent) then
			local dist = tower:GetPos():DistToSqr(ent:GetPos())
			if not best_dist or dist < best_dist then
				best, best_dist = ent, dist
			end
		end
	end
	return best
end

function ENT:WatchtowerAttack()
	local tower = self.WatchtowerMount
	if not IsValid(tower) then return end

	local class = self.WatchtowerClass
	local spec = DAMAGE_TYPES[self.WatchtowerDamageType] or DAMAGE_TYPES[DEFAULT_DAMAGE_TYPE]
	local base = HORDE:Horde_GetWardenBuildableDamage(class)
	local amount = math.max(1, math.floor((tonumber(base) or 20) * DAMAGE_SCALE))
	local origin = tower:GetPos() + Vector(0, 0, 10)

	local dealt = false

	if spec.effect == nil then
		local target = self:FindWatchtowerTarget(self:WatchtowerReach())
		if not target then return end
		local src = tower:GetPos() + tower:GetUp() * 20
		self:FireBullets({
			Num = 1,
			Src = src,
			Dir = (target:WorldSpaceCenter() - src),
			Spread = Vector(0.04, 0.04, 0.04),
			Tracer = 1,
			TracerName = "arccw_tracer",
			Damage = amount,
			AmmoType = "SMG1",
			Force = 3,
			Attacker = self,
			Inflictor = tower,
		})
		dealt = true
	else
		for _, ent in ipairs(ents.FindInSphere(origin, TOWER_RADIUS)) do
			if HORDE:IsPlayerOrMinion(ent) == true and not HORDE:IsPlayerSpectator(ent) then
				local dmg = DamageInfo()
				dmg:SetAttacker(self)
				dmg:SetInflictor(tower)
				dmg:SetDamageType(spec.dmg)
				dmg:SetDamage(amount)
				dmg:SetDamagePosition(ent:WorldSpaceCenter())
				ent:TakeDamageInfo(dmg)
				dealt = true
			end
		end

		local e = EffectData()
		e:SetOrigin(origin)
		util.Effect(spec.effect, e, true, true)
	end

	if dealt then
		tower:EmitSound("npc/turret_floor/shoot.wav", 90, math.random(95, 110))
	end
end

function ENT:ResolveHitAnim()
	for _, anim in ipairs(HIT_ANIMS) do
		if VJ.AnimExists(self, anim) then return anim end
	end
	return nil
end

function ENT:PlayHitAnim()
	local anim = self.Horde_HitAnim
	if not anim then return end

	local gesture
	if isnumber(anim) then
		if self:IsPlayingGesture(anim) then self:RemoveGesture(anim) end
		gesture = self:AddGesture(anim)
	else
		local seq = self:LookupSequence(anim)
		if seq != -1 then gesture = self:AddGestureSequence(seq) end
	end

	if gesture and gesture > 0 then
		self:SetLayerPriority(gesture, 1)
		self:SetLayerPlaybackRate(gesture, HIT_LAYER_RATE)
	end
end

function ENT:CustomOnMeleeAttack_BeforeStartTimer(seed)
	self:PlayHitAnim()
end

function ENT:CustomOnInitialize()
	self:SetModelScale(1.25)
	self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
	self:SetColor(Color(50,50,50))

	self:ShrinkHead()
	self:SpawnWatchtower()
	self:SpawnHandWeapon()
	self.Horde_HitAnim = self:ResolveHitAnim()

	self:CapabilitiesAdd(CAP_MOVE_JUMP)

	self:EmitSound("npc/combine_gunship/see_enemy.wav", 3000, 100, 2, CHAN_STATIC)
end

function ENT:AirActivity()
	for _, act in ipairs(AIR_ANIMS) do
		if VJ.AnimExists(self, act) then return act end
	end
	return nil
end

function ENT:TranslateActivity(act)
	if not self:IsOnGround() and (act == ACT_IDLE or act == ACT_WALK or act == ACT_RUN or act == ACT_JUMP) then
		local air = self:AirActivity()
		if air then return air end
	end
	return self.BaseClass.TranslateActivity(self, act)
end

function ENT:CustomOnThink_AIEnabled()
	self:UpdateWatchtower()
	self:UpdateHandWeapon()

	local target = self:FindWatchtowerTarget(self:WatchtowerReach())
	if IsValid(target) and CurTime() >= (self.Horde_NextTowerAttack or 0) then
		self.Horde_NextTowerAttack = CurTime() + (self.WatchtowerAttackInterval or 1)
		self:WatchtowerAttack()
	end

	local ene = self:GetEnemy()
	if IsValid(ene) and not self.AttackType
		and self:GetPos():DistToSqr(ene:GetPos()) > CHASE_DISTANCE * CHASE_DISTANCE then
		self:MaintainAlertBehavior(true)

		if not self:IsMoving() and CurTime() >= (self.Horde_NextChaseT or 0) then
			self.Horde_NextChaseT = CurTime() + CHASE_RETRY
			self:SetLastPosition(ene:GetPos())
			self:SetMovementActivity(CHASE_ACTIVITY)
			self:SCHEDULE_GOTO_POSITION("TASK_RUN_PATH", function(schedule)
				schedule:EngTask("TASK_FACE_ENEMY", 0)
				schedule.CanShootWhenMoving = true
				schedule.TurnData = { Type = VJ.FACE_ENEMY }
			end)
		end
	end
end

VJ.AddNPC("Plague Watchtower","npc_vj_horde_plague_watchtower", "Zombies")
