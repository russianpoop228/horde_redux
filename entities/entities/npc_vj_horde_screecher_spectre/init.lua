AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = "models/horde/infected_stalker/infected_stalker.mdl"
ENT.StartHealth = 100
ENT.HullType = HULL_HUMAN
ENT.VJ_NPC_Class = {"CLASS_PLAYER_ALLY", "CLASS_COMBINE"}
ENT.FriendlyMinion = true
ENT.FriendsWithAllPlayerAllies = true
ENT.PlayerFriendly = true
ENT.BloodColor = "Red"
ENT.Immune_AcidPoisonRadiation = true
ENT.HasMeleeAttack = false
ENT.AnimTbl_MeleeAttack = {}
ENT.HasLeapAttack = false
ENT.FootStepTimeRun = 0.2
ENT.FootStepTimeWalk = 0.3
ENT.AnimTbl_Run = {ACT_WALK}
ENT.FootStepSoundLevel = 55
ENT.SoundTbl_FootStep = {"npc/stalker/stalker_footstep_left1.wav", "npc/stalker/stalker_footstep_left2.wav", "npc/stalker/stalker_footstep_right1.wav", "npc/stalker/stalker_footstep_right2.wav"}
ENT.SoundTbl_Breath = "npc/stalker/breathing3.wav"
ENT.SoundTbl_Idle = {"vj_zombies/special/zmisc_idle1.wav", "vj_zombies/special/zmisc_idle2.wav", "vj_zombies/special/zmisc_idle3.wav", "vj_zombies/special/zmisc_idle4.wav", "vj_zombies/special/zmisc_idle5.wav", "vj_zombies/special/zmisc_idle6.wav"}
ENT.SoundTbl_Alert = ""
ENT.SoundTbl_MeleeAttack = {"npc/zombie/claw_strike1.wav", "npc/zombie/claw_strike2.wav", "npc/zombie/claw_strike3.wav"}
ENT.SoundTbl_MeleeAttackMiss = {"vj_zombies/slow/miss1.wav", "vj_zombies/slow/miss2.wav", "vj_zombies/slow/miss3.wav", "vj_zombies/slow/miss4.wav"}
ENT.SoundTbl_Pain = {"vj_zombies/special/zmisc_pain1.wav", "vj_zombies/special/zmisc_pain2.wav", "vj_zombies/special/zmisc_pain3.wav", "vj_zombies/special/zmisc_pain4.wav", "vj_zombies/special/zmisc_pain5.wav", "vj_zombies/special/zmisc_pain6.wav"}
ENT.SoundTbl_Death = {"vj_zombies/special/zmisc_die1.wav", "vj_zombies/special/zmisc_die2.wav", "vj_zombies/special/zmisc_die3.wav"}

ENT.HasAllies = true
ENT.HasWorldShakeOnMove = false
ENT.Horde_Shock_Radius = 300
ENT.Horde_Shock_Cooldown = 4
ENT.Horde_Shock_Damage = 30
ENT.Horde_Shock_Buildup = 4
ENT.Horde_NextShockT = 0
function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
	if HORDE:IsLightningDamage(dmginfo) then
		dmginfo:ScaleDamage(0.5)
	elseif HORDE:IsBlastDamage(dmginfo) then
		dmginfo:ScaleDamage(1.25)
	end
end
function ENT:CustomOnInitialize()
	self.properties = self.properties or {}
	self:SetCollisionBounds(Vector(0, 0, 0), Vector(0, 0, 0))
	self:SetRenderMode(RENDERMODE_TRANSCOLOR)
	self:SetColor(Color(120, 160, 255, 200))
	self:SetMaterial("models/effects/comball_tape")
	local max_hp = HORDE:GetSpectreHealth("screecher")
	if self.properties.abyssal_health then
		max_hp = max_hp * 1.25
	end
	self:SetMaxHealth(max_hp)
	self:SetHealth(max_hp)
	HORDE:SpawnGodGlow(self)
end
function ENT:ShockAttack(delay)
	timer.Simple(delay, function ()
		if not IsValid(self) then return end
		local pos = self:GetPos()
		for _, ent in pairs(ents.FindInSphere(pos, self.Horde_Shock_Radius)) do
			if ent ~= self and HORDE:IsEnemy(ent) then
				local dmg = DamageInfo()
				dmg:SetAttacker(self)
				dmg:SetInflictor(self)
				dmg:SetDamageType(DMG_SHOCK)
				dmg:SetDamage(self.Horde_Shock_Damage)
				dmg:SetDamagePosition(ent:GetPos())
				ent:TakeDamageInfo(dmg)
				ent:Horde_AddDebuffBuildup(HORDE.Status_Shock, self.Horde_Shock_Buildup, self)
			end
		end

		local e = EffectData()
			e:SetOrigin(pos)
			e:SetNormal(Vector(0, 0, 1))
		util.Effect("screecher_blast", e, true, true)
	end)
end

function ENT:CustomOnThink()
	local enemy = self:GetEnemy()
	if not IsValid(enemy) then return end
	if not self.EnemyData or self.EnemyData.Distance >= self.Horde_Shock_Radius then return end
	if CurTime() < self.Horde_NextShockT then return end
	self.Horde_NextShockT = CurTime() + self.Horde_Shock_Cooldown

	sound.Play("npc/stalker/go_alert2.wav", self:GetPos())
	self:VJ_ACT_PLAYACTIVITY("podconvulse", true, 1.5, false)
	self:ShockAttack(1.5)
	self:ShockAttack(1.7)
	self:ShockAttack(1.9)
	timer.Simple(2.1, function ()
		if not IsValid(self) then return end
		self:VJ_ACT_PLAYACTIVITY("walk")
	end)
end

VJ.AddNPC("Lightning God","npc_vj_horde_screecher_spectre", "Horde")
