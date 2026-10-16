AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = {"models/horde/bloodsquid/bloodsquid.mdl"}
ENT.StartHealth = 100
ENT.HullType = HULL_HUMAN
ENT.VJ_NPC_Class = {"CLASS_PLAYER_ALLY", "CLASS_COMBINE"}
ENT.FriendlyMinion = true
ENT.FriendsWithAllPlayerAllies = true
ENT.PlayerFriendly = true
ENT.BloodColor = "Red"
ENT.Immune_AcidPoisonRadiation = true
ENT.CanFlinch = 1
ENT.HasMeleeAttack = true
ENT.AnimTbl_MeleeAttack = {"bite"}
ENT.MeleeAttackDistance = 45
ENT.MeleeAttackDamageDistance = 85
ENT.TimeUntilMeleeAttackDamage = 0.8
ENT.MeleeAttackDamage = 50
ENT.MeleeAttackBleedEnemy = false
ENT.NextAnyAttackTime_Melee = 1
ENT.HasLeapAttack = false
ENT.FootStepTimeRun = 0.5
ENT.FootStepTimeWalk = 0.5
ENT.AnimTbl_Walk = {ACT_WALK}
ENT.AnimTbl_Run = {ACT_WALK}
ENT.SoundTbl_FootStep = {"npc/zombie/foot1.wav","npc/zombie/foot2.wav","npc/zombie/foot3.wav"}
ENT.SoundTbl_Alert = {"horde/bloodsquid/bc_attackgrowl1.ogg","horde/bloodsquid/bc_attackgrowl2.ogg","horde/bloodsquid/bc_attackgrowl3.ogg"}
ENT.SoundTbl_MeleeAttack = {"npc/zombie/claw_strike1.wav","npc/zombie/claw_strike2.wav","npc/zombie/claw_strike3.wav"}
ENT.SoundTbl_MeleeAttackMiss = {"vj_zombies/slow/miss1.wav", "vj_zombies/slow/miss2.wav", "vj_zombies/slow/miss3.wav", "vj_zombies/slow/miss4.wav"}
ENT.SoundTbl_Pain = {"horde/bloodsquid/bc_pain1.ogg","horde/bloodsquid/bc_pain2.ogg","horde/bloodsquid/bc_pain3.ogg"}
ENT.SoundTbl_Death = {"horde/bloodsquid/bc_die1.ogg","horde/bloodsquid/bc_die2.ogg"}

ENT.GeneralSoundPitch1 = 100
ENT.GeneralSoundPitch2 = 100
ENT.HasAllies = true
ENT.HasWorldShakeOnMove = false
ENT.Horde_Flame_Range = 400
ENT.Horde_Flame_Cooldown = 6
ENT.Horde_Flame_Damage = 20
ENT.Horde_Flame_Buildup = 3
ENT.Horde_NextFlameT = 0
function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
	if HORDE:IsFireDamage(dmginfo) then
		dmginfo:ScaleDamage(0.75)
	elseif HORDE:IsColdDamage(dmginfo) or HORDE:IsMeleeDamage(dmginfo) then
		dmginfo:ScaleDamage(1.25)
	end
end
function ENT:CustomOnInitialize()
	self.properties = self.properties or {}
	self:SetCollisionBounds(Vector(0, 0, 0), Vector(0, 0, 0))
	self:SetRenderMode(RENDERMODE_TRANSCOLOR)
	self:SetColor(Color(255, 90, 20, 200))
	self:SetMaterial("models/effects/comball_tape")
	self:SetModelScale(1.25, 0)
	local max_hp = HORDE:GetSpectreHealth("scorcher")
	if self.properties.abyssal_health then
		max_hp = max_hp * 1.25
	end
	self:SetMaxHealth(max_hp)
	self:SetHealth(max_hp)
	HORDE:SpawnGodGlow(self)
end
function ENT:FlameBurst()
	if not IsValid(self) then return end
	local pos = self:GetPos() + self:OBBCenter() + self:GetForward() * 50
	util.VJ_SphereDamage(self, self, pos, self.Horde_Flame_Range, self.Horde_Flame_Damage, DMG_BURN, true, true,
		{UseCone = true, UseConeDegree = 40},
		function (ent)
			if HORDE:IsEnemy(ent) then
				ent:Horde_AddDebuffBuildup(HORDE.Status_Ignite, self.Horde_Flame_Buildup, self)
			end
		end)
end

function ENT:CustomOnThink()
	local enemy = self:GetEnemy()
	if not IsValid(enemy) then return end
	if not self.EnemyData or self.EnemyData.Distance > self.Horde_Flame_Range then return end
	if CurTime() < self.Horde_NextFlameT then return end
	self.Horde_NextFlameT = CurTime() + self.Horde_Flame_Cooldown

	self:StopMoving()
	self:VJ_ACT_PLAYACTIVITY("shootflames2", true, 1.5, false)
	self:EmitSound("horde/gargantua/gar_flameon1.ogg")
	ParticleEffectAttach("scorcher_flame", PATTACH_POINT_FOLLOW, self, 1)
	for i = 1, 5 do
		timer.Simple(i * 0.2, function ()
			if not IsValid(self) then return end
			self:FlameBurst()
		end)
	end
	timer.Simple(1.2, function ()
		if not IsValid(self) then return end
		self:StopParticles()
	end)
end

VJ.AddNPC("Fire God","npc_vj_horde_scorcher_spectre", "Horde")
