AddCSLuaFile("shared.lua")
include('shared.lua')
ENT.Model = "models/police.mdl"
ENT.StartHealth = 5000
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
ENT.HasAllies = true
ENT.HasMeleeAttack = true
ENT.Weapon_MaxDistance  = 80
ENT.ThrowGrenadeChance = 1
ENT.GrenadeAttackThrowDistance = 1000
ENT.GrenadeAttackThrowDistanceClose = 500
ENT.FootStepTimeRun = 0.3
ENT.FootStepTimeWalk = 0.5
ENT.CallForBackUpOnDamage = false
ENT.CanDetectDangers = false
ENT.MoveOrHideOnDamageByEnemy = false
ENT.WeaponSpread = 1.5
ENT.Weapon_FiringDistanceFar = 2500
ENT.WeaponReload_FindCover = false
ENT.Horde_Plague_Soldier = true

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
ENT.DisableCritical = nil
ENT.EntitiesToNoCollide = {"npc_vj_horde_platoon_heavy", "npc_vj_horde_platoon_berserker", "npc_vj_horde_platoon_demolitionist"}

function ENT:Init()
	self:SetModelScale(1.25)
	self:AddRelationship("npc_headcrab_poison D_LI 99")
	self:AddRelationship("npc_headcrab_fast D_LI 99")
	self:SetColor(Color(150,100,100))

	local p = math.random()
	self:Give("weapon_vj_horde_katana")
	local pos = Vector()
	local ang = Angle()
	local attach_id = self:LookupAttachment("eyes")
	local attach = self:GetAttachment(attach_id)
	pos = attach.Pos
	ang = attach.Ang
	pos.x = pos.x
	pos.z = pos.z - 25
	pos.y = pos.y
	self.model = ents.Create("prop_dynamic")
	self.model:SetModel("models/headcrab.mdl")
	self.model:SetColor(Color(150, 100, 100))
	self.model:SetSequence("idle01")
	self.model:SetPos(pos)
	self.model:SetAngles(ang)
	self.model:Spawn()
	self.model:SetParent(self, attach_id)
	self.model:SetModelScale(1.5)
	timer.Create("Equip", 0.5, 0, function() self.Weapon_MaxDistance = 80 end)

	self:EmitSound("npc/combine_gunship/see_enemy.wav", 3000, 100, 2, CHAN_STATIC)
end

function ENT:OnDamaged(dmginfo, hitgroup, status)
	if status == "Init" then
		dmginfo:ScaleDamage(0.9)
		local p = math.random()
		if HORDE:IsPhysicalDamage(dmginfo) and p <= 0.25 then
			local e = EffectData()
			if dmginfo:GetDamagePosition() ~= Vector(0,0,0) then
				e:SetOrigin(dmginfo:GetDamagePosition())
			else
				e:SetOrigin(self:GetPos() + self:OBBCenter() + self:GetForward() * 25)
			end
			dmginfo:ScaleDamage(0.75)
			util.Effect("horde_platoon_parry", e, true, true)
			sound.Play("horde/gadgets/guard" .. tostring(math.random(1,2)) ..".ogg", self:GetPos(), 125, 100, 1, CHAN_AUTO)
		end

		if (not self.DisableCritical) and self:Health() <= self:GetMaxHealth() * 0.5 then
			self.Critical = true
		end
	end
end

function ENT:CustomOnThink()
	if self:IsOnGround() then
		if self.Critical then
			self:SetLocalVelocity(self:GetMoveVelocity() * 0.5)
		else
			self:SetLocalVelocity(self:GetMoveVelocity() * 0.25)
		end
	else
	end
end

VJ.AddNPC("Platoon Berserker","npc_vj_horde_platoon_berserker", "Zombies")
