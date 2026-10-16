AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = {"models/zombie/classic.mdl"}
ENT.StartHealth = 100
ENT.HullType = HULL_HUMAN
ENT.VJ_NPC_Class = {"CLASS_PLAYER_ALLY", "CLASS_COMBINE"}
ENT.FriendlyMinion = true
ENT.FriendsWithAllPlayerAllies = true
ENT.PlayerFriendly = true
ENT.BloodColor = "Red"
ENT.Immune_AcidPoisonRadiation = true
ENT.HasMeleeAttack = true
ENT.AnimTbl_MeleeAttack = {ACT_MELEE_ATTACK1}
ENT.MeleeAttackDistance = 45
ENT.MeleeAttackDamageDistance = 65
ENT.TimeUntilMeleeAttackDamage = 0.8
ENT.MeleeAttackDamage = 30
ENT.DisableDefaultMeleeAttackDamageCode = true
ENT.MeleeAttackBleedEnemy = false
ENT.HasLeapAttack = false
ENT.NextAnyAttackTime_Melee = 1
ENT.FootStepTimeRun = 1
ENT.FootStepTimeWalk = 1
ENT.SoundTbl_FootStep = {"npc/zombie/foot1.wav","npc/zombie/foot2.wav","npc/zombie/foot3.wav"}
ENT.SoundTbl_Idle = {"npc/zombie/zombie_voice_idle1.wav","npc/zombie/zombie_voice_idle2.wav"}
ENT.SoundTbl_Alert = {"npc/zombie/zombie_alert1.wav","npc/zombie/zombie_alert2.wav"}
ENT.SoundTbl_MeleeAttack = {"npc/zombie/zo_attack1.wav","npc/zombie/zo_attack2.wav"}
ENT.SoundTbl_MeleeAttackMiss = {"vj_zombies/slow/miss1.wav", "vj_zombies/slow/miss2.wav", "vj_zombies/slow/miss3.wav", "vj_zombies/slow/miss4.wav"}
ENT.SoundTbl_Pain = {"npc/zombie/zombie_pain1.wav","npc/zombie/zombie_pain2.wav","npc/zombie/zombie_pain3.wav"}
ENT.SoundTbl_Death = {"npc/zombie/zombie_die1.wav","npc/zombie/zombie_die2.wav"}

ENT.GeneralSoundPitch1 = 60
ENT.GeneralSoundPitch2 = 65
ENT.HasAllies = true
ENT.HasWorldShakeOnMove = false
ENT.Horde_Smoke_Radius = 200
ENT.Horde_Smoke_Buildup = 8
ENT.Horde_Smoke_Cooldown = 0.25
ENT.Horde_Frostbite_Mult = 2
ENT.Horde_Smoke_NextT = 0
ENT.Abyssal_Roar = false
function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
	local curTime = CurTime()
	if curTime < self.Horde_Smoke_NextT then return end
	self.Horde_Smoke_NextT = curTime + self.Horde_Smoke_Cooldown

	local e = EffectData()
		e:SetOrigin(self:GetPos())
	util.Effect("blight_mini_explosion", e, true, true)

	local owner = self:GetNWEntity("HordeOwner")
	for _, ent in pairs(ents.FindInSphere(self:GetPos(), self.Horde_Smoke_Radius)) do
		if ent ~= self and HORDE:IsEnemy(ent) then
			ent:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, self.Horde_Smoke_Buildup * self.Horde_Frostbite_Mult, owner)
		end
	end
end
function ENT:CustomOnInitialize()
	self.properties = self.properties or {level = 0}
	self:SetCollisionBounds(Vector(0, 0, 0), Vector(0, 0, 0))
	self:SetBodygroup(1, 1)
	self:SetModelScale(1.5, 0)
	self:ManipulateBoneScale(0, Vector(2,2,2))
	self:ManipulateBoneScale(9, Vector(2,2,4))
	self.AnimTbl_Run = ACT_RUN
	local e = EffectData()
		e:SetOrigin(self:GetPos())
		e:SetNormal(Vector(0,0,1))
		e:SetScale(0.25)
	util.Effect("blight_explosion", e, true, true)
	self:SetRenderMode(RENDERMODE_TRANSCOLOR)
	self:SetColor(Color(30, 50, 30, 220))
	self.MeleeAttackDamage = 1.5 * (30 + 6 * self.properties.level)
	local max_hp = HORDE:GetSpectreHealth("blight", self.properties.level)
	if self.properties.abyssal_health then
		max_hp = max_hp * 1.25
	end
	self:SetMaxHealth(max_hp)
	self:SetHealth(max_hp)
end
function ENT:CustomOnMeleeAttack_AfterChecks(ent, isProp)
	if not IsValid(ent) then return false end
	local owner = self:GetNWEntity("HordeOwner")
	local dmg = DamageInfo()
	dmg:SetDamage(self.MeleeAttackDamage)
	dmg:SetDamageType(self.MeleeAttackDamageType)
	if ent.VJ_ID_Living then dmg:SetDamageForce(self:GetForward() * ((dmg:GetDamage() + 100) * 70)) end
	dmg:SetInflictor(self)
	dmg:SetAttacker(IsValid(owner) and owner or self)
	dmg:SetDamagePosition(ent:GetPos())
	ent:TakeDamageInfo(dmg)
	if HORDE:IsEnemy(ent) then
		ent:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, self.MeleeAttackDamage / 2 * self.Horde_Frostbite_Mult, owner)
	end
	return false
end

VJ.AddNPC("Blight Spectre","npc_vj_horde_blight_spectre", "Horde")
