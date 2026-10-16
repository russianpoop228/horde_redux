if SERVER then AddCSLuaFile() end

SWEP.PrintName				= "Ghoul Claws"
SWEP.Purpose				= "Just Ghoul Claws."

SWEP.Slot					= 0
SWEP.SlotPos				= 4

SWEP.Spawnable				= true

SWEP.ViewModel				= Model( "models/weapons/v_knife_t.mdl" )
SWEP.WorldModel				= ""
SWEP.ViewModelFOV			= 75
SWEP.UseHands				= false
SWEP.Category = "HORDE: Ghoul"

SWEP.AttackSpeedMultiplier	= 2.5
SWEP.Horde_HandlesAttackSpeed = true

SWEP.FastDamageMin			= 20
SWEP.FastDamageMax			= 40

SWEP.SlowDamageMin			= 60
SWEP.SlowDamageMax			= 100

SWEP.SlowAttackPlaybackRate	= 0.75
SWEP.SlowCooldownMultiplier	= 1.8

SWEP.FastHitTime			= 0.2
SWEP.SlowHitTime			= 0.28

SWEP.CamouflageDuration		= 5
SWEP.CamouflageCooldown		= 7

SWEP.BoneBurstRadius		= 350
SWEP.BoneBurstCooldown		= 15
SWEP.BoneBurstHPMult		= 1.25

SWEP.AppetiteDuration		= 30
SWEP.AppetiteCooldown		= 90
SWEP.AppetiteAttackSpeed	= 6.0

SWEP.NecrosisThreshold		= -25
SWEP.NecrosisRate			= 10
SWEP.NecrosisTickTime		= 0.25

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"

SWEP.DrawAmmo				= false
SWEP.HitDistance			= 80

local SwingSound = Sound( "npc/zombie/claw_miss1.wav" )
local HitSound = Sound("npc/zombie/claw_strike1.wav")

local CamouflageSound	= Sound( "npc/zombie/zombie_alert1.wav" )
local BoneBurstSound	= Sound( "npc/zombie/zombie_die1.wav" )
local AppetiteScream	= Sound( "npc/zombie/zombie_die3.wav" )

local function TimerID( prefix, ply )
	return prefix .. ply:UserID()
end

local function EndCamouflageForPlayer( ply )
	if not IsValid(ply) then return end
	timer.Remove( TimerID( "GhoulClaws_Camouflage_", ply ) )

	if ply.Ghoul_Camouflaged then
		ply.Ghoul_Camouflaged = nil
		ply:SetRenderMode( RENDERMODE_NORMAL )
		ply:SetColor( Color(255, 255, 255, 255) )
		ply:SetMaterial( "" )
		ply:DrawShadow( true )
		ply:RemoveFlags( FL_NOTARGET )
	end
end

local function NecrosisID()
	return HORDE and HORDE.Status_Necrosis
end

local function AddAppetiteNecrosis( ply, amount )
	local id = NecrosisID()
	if not SERVER or not id or not IsValid(ply) or not ply:Alive() then return end

	ply.Horde_Debuff_Active  = ply.Horde_Debuff_Active  or {}
	ply.Horde_Debuff_Buildup = ply.Horde_Debuff_Buildup or {}

	if ply.Horde_Debuff_Active[id] then return end
	local cur = ply.Horde_Debuff_Buildup[id] or 0
	if cur >= 100 then return end

	local target = cur + amount
	local value  = math.min( 99, target )
	ply.Horde_Debuff_Buildup[id] = value
	ply.Ghoul_NecrosisDebt = ( ply.Ghoul_NecrosisDebt or 0 ) + ( value - cur )

	net.Start( "Horde_SyncStatus" )
		net.WriteUInt( id, 8 )
		net.WriteUInt( math.floor( value ), 8 )
	net.Send( ply )

	timer.Remove( "Horde_RemoveBuildup_" .. tostring( id ) .. "_" .. ply:SteamID() )

	if target >= 100 then
		ply:Horde_AddDebuffBuildup( id, 100, ply )
	end
end

local function ClearAppetiteNecrosis( ply )
	if not SERVER or not IsValid(ply) then return end

	local debt = ply.Ghoul_NecrosisDebt
	ply.Ghoul_NecrosisDebt = nil
	local id = NecrosisID()
	if not debt or not id or not ply.Horde_Debuff_Buildup then return end
	if ply.Horde_Debuff_Active and ply.Horde_Debuff_Active[id] then return end

	local take = math.min( debt, ply.Horde_Debuff_Buildup[id] or 0 )
	if take > 0 then
		ply:Horde_ReduceDebuffBuildup( id, take )
	end
end

local function EndAppetiteForPlayer( ply )
	if not IsValid(ply) then return end
	timer.Remove( TimerID( "GhoulClaws_Appetite_", ply ) )
	timer.Remove( TimerID( "GhoulClaws_Necrosis_", ply ) )
	ply.Ghoul_AppetiteInvincible = nil
	ply.Ghoul_RageHPSnap = nil
	ClearAppetiteNecrosis( ply )
end

local function ResolveAppetiteDebt( ply )
	if SERVER and IsValid(ply) and ply:Alive() and ply:Health() <= 0 then
		ply:Kill()
	end
end

function SWEP:Initialize()
	self:SetWeaponHoldType("melee2")

	self.NextCamouflage		= 0
	self.NextBoneBurst		= 0
	self.NextAppetite		= 0

	self.OriginalAttackSpeed = self.AttackSpeedMultiplier
end

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 0, "NextMeleeAttack" )
	self:NetworkVar( "Float", 1, "NextIdle" )
	self:NetworkVar( "Int", 2, "Combo" )

	self:NetworkVar( "Float", 3, "CamouflageEnd" )
	self:NetworkVar( "Float", 4, "AppetiteEnd" )
	self:NetworkVar( "Bool", 0, "IsCamouflaged" )
	self:NetworkVar( "Bool", 1, "IsAppetiteActive" )

	self:NetworkVar( "Float", 5, "CamouflageCDEnd" )
	self:NetworkVar( "Float", 6, "BoneBurstCDEnd" )
	self:NetworkVar( "Float", 7, "AppetiteCDEnd" )
end

function SWEP:GetAbilityOwner()
	if IsValid(self.Owner) then return self.Owner end
	if IsValid(self.Ghoul_LastOwner) then return self.Ghoul_LastOwner end
end

function SWEP:RestoreCooldowns( ply )
	if not SERVER or not IsValid(ply) then return end

	if ply.Ghoul_NextCamouflage then
		self.NextCamouflage = ply.Ghoul_NextCamouflage
		self:SetCamouflageCDEnd( ply.Ghoul_NextCamouflage )
	end
	if ply.Ghoul_NextBoneBurst then
		self.NextBoneBurst = ply.Ghoul_NextBoneBurst
		self:SetBoneBurstCDEnd( ply.Ghoul_NextBoneBurst )
	end
	if ply.Ghoul_NextAppetite then
		self.NextAppetite = ply.Ghoul_NextAppetite
		self:SetAppetiteCDEnd( ply.Ghoul_NextAppetite )
	end
end

function SWEP:Equip( newOwner )
	self.Ghoul_LastOwner = newOwner
	self:RestoreCooldowns( newOwner )
end

function SWEP:UpdateNextIdle()
	local vm = self.Owner:GetViewModel()
	if not IsValid(vm) then return end
	local rate = vm:GetPlaybackRate()
	if rate <= 0 then rate = 1 end
	self:SetNextIdle( CurTime() + vm:SequenceDuration() / rate )
end

function SWEP:GetUpgradeLevel()
	local ply = self.Owner
	if not IsValid(ply) or not ply.Horde_GetUpgrade then return 0 end
	return ply:Horde_GetUpgrade( self:GetClass() ) or 0
end

function SWEP:GetPerkSpeedMult()
	if HORDE and HORDE.GetGhoulAttackSpeedMult then
		return HORDE:GetGhoulAttackSpeedMult( self.Owner )
	end
	return 1
end

function SWEP:GetAttackSpeed()
	return self.AttackSpeedMultiplier * self:GetPerkSpeedMult()
end

function SWEP:PrimaryAttack()
	if not IsValid(self.Owner) then return end

	local speed = self:GetAttackSpeed()

	self.Owner:SetAnimation( PLAYER_ATTACK1 )

	local anim = math.random(1, 2) == 1 and "midslash1" or "midslash2"

	local vm = self.Owner:GetViewModel()
	if IsValid(vm) then
		vm:SendViewModelMatchingSequence( vm:LookupSequence( anim ) )
		vm:SetPlaybackRate( speed )
	end

	self:SetNWInt("AttackMode", 1)
	self:EmitSound( SwingSound )
	self:UpdateNextIdle()
	self:SetNextMeleeAttack( CurTime() + self.FastHitTime / speed )

	local cooldown = 0.9 / speed
	self:SetNextPrimaryFire( CurTime() + cooldown )
	self:SetNextSecondaryFire( CurTime() + cooldown )
end

function SWEP:SecondaryAttack()
	if not IsValid(self.Owner) then return end

	local speed     = self:GetAttackSpeed()
	local slowRate  = self.SlowAttackPlaybackRate * self:GetPerkSpeedMult()

	self.Owner:SetAnimation( PLAYER_ATTACK1 )

	local anim = "midslash2"
	local vm = self.Owner:GetViewModel()
	if IsValid(vm) then
		vm:SendViewModelMatchingSequence( vm:LookupSequence( anim ) )
		vm:SetPlaybackRate( slowRate )
	end

	self:SetNWInt("AttackMode", 2)
	self:EmitSound( SwingSound )
	self:UpdateNextIdle()
	self:SetNextMeleeAttack( CurTime() + self.SlowHitTime / slowRate )

	local fastCooldown = 0.9 / speed
	local slowCooldown = fastCooldown * self.SlowCooldownMultiplier

	self:SetNextPrimaryFire( CurTime() + slowCooldown )
	self:SetNextSecondaryFire( CurTime() + slowCooldown )
end

function SWEP:DealDamage()
	if not IsValid(self.Owner) then return end

	self.Owner:LagCompensation( true )

	local tr = util.TraceLine( {
		start = self.Owner:GetShootPos(),
		endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.HitDistance,
		filter = self.Owner,
		mask = MASK_SHOT_HULL
	} )

	if ( !IsValid( tr.Entity ) ) then
		tr = util.TraceHull( {
			start = self.Owner:GetShootPos(),
			endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * self.HitDistance,
			filter = self.Owner,
			mins = Vector( -10, -10, -8 ),
			maxs = Vector( 10, 10, 8 ),
			mask = MASK_SHOT_HULL
		} )
	end

	if ( tr.Hit && !( game.SinglePlayer() && CLIENT ) ) then
		self:EmitSound( HitSound )
	end

	local hit = false

	local isFriendly = HORDE and HORDE.IsPlayerOrMinion and IsValid( tr.Entity ) and HORDE:IsPlayerOrMinion( tr.Entity )

	if ( SERVER && IsValid( tr.Entity ) && !isFriendly && ( tr.Entity:IsNPC() || tr.Entity:IsNextBot() || tr.Entity:Health() > 0 ) ) then
		local dmginfo = DamageInfo()

		local attacker = self.Owner
		if ( !IsValid( attacker ) ) then attacker = self end
		dmginfo:SetAttacker( attacker )
		dmginfo:SetInflictor( self )

		local mode = self:GetNWInt("AttackMode", 1)
		local baseDmg
		if mode == 1 then
			baseDmg = math.random( self.FastDamageMin, self.FastDamageMax )
		else
			baseDmg = math.random( self.SlowDamageMin, self.SlowDamageMax )
		end

		local level = self:GetUpgradeLevel()
		if level > 0 then
			baseDmg = baseDmg * (1 + 0.03 * level)
		end

		dmginfo:SetDamage( baseDmg )

		dmginfo:SetDamageType( DMG_SLASH )
		dmginfo:SetDamagePosition( tr.HitPos )
		dmginfo:SetDamageForce( self.Owner:GetForward() * 9000 )

		tr.Entity:TakeDamageInfo( dmginfo )
		hit = true
	end

	if ( SERVER && IsValid( tr.Entity ) ) then
		local phys = tr.Entity:GetPhysicsObject()
		if ( IsValid( phys ) ) then
			phys:ApplyForceOffset( self.Owner:GetAimVector() * 80 * phys:GetMass(), tr.HitPos )
		end
	end

	if ( SERVER ) then
		if ( hit ) then
			self:SetCombo( self:GetCombo() + 1 )
		else
			self:SetCombo( 0 )
		end
	end

	self.Owner:LagCompensation( false )
end

function SWEP:Reload()
	if not IsValid(self.Owner) or CLIENT or not self.Owner:Alive() then return end

	local ply = self.Owner
	if CurTime() >= (ply.Ghoul_NextBoneBurst or self.NextBoneBurst or 0) then
		self:ActivateBoneBurst()
	end
end

function SWEP:ActivateCorpseCamouflage()
	local ply = self.Owner
	if not IsValid(ply) then return end

	local cd = CurTime() + self.CamouflageCooldown
	ply.Ghoul_NextCamouflage = cd
	self.NextCamouflage = cd
	self:SetCamouflageCDEnd( cd )
	self:SetCamouflageEnd( CurTime() + self.CamouflageDuration )
	self:SetIsCamouflaged( true )

	ply.Ghoul_Camouflaged = true
	ply:SetRenderMode( RENDERMODE_TRANSALPHA )
	ply:SetColor( Color(120, 180, 255, 90) )
	ply:SetMaterial( "models/props_combine/stasisshield_sheet" )
	ply:DrawShadow( false )
	ply:AddFlags( FL_NOTARGET )

	ply:EmitSound( CamouflageSound, 70, 90 )

	local wep = self
	timer.Create( TimerID( "GhoulClaws_Camouflage_", ply ), self.CamouflageDuration, 1, function()
		if not IsValid(ply) then return end
		if IsValid(wep) then
			wep:EndCorpseCamouflage()
		else
			EndCamouflageForPlayer( ply )
		end
	end )
end

function SWEP:EndCorpseCamouflage()
	self:SetIsCamouflaged( false )
	self:SetCamouflageEnd( 0 )

	EndCamouflageForPlayer( self:GetAbilityOwner() )
end

function SWEP:ActivateBoneBurst()
	local ply = self.Owner
	if not IsValid(ply) then return end

	local cd = CurTime() + self.BoneBurstCooldown
	ply.Ghoul_NextBoneBurst = cd
	self.NextBoneBurst = cd
	self:SetBoneBurstCDEnd( cd )

	local pos = ply:GetPos() + Vector(0, 0, 40)
	local radius = self.BoneBurstRadius
	local damage = math.max(20, ply:Health() * self.BoneBurstHPMult)

	ply:EmitSound(BoneBurstSound, 100, 80)
	ply:EmitSound("physics/flesh/flesh_bloody_break.wav", 95, 85)
	ply:EmitSound("ambient/levels/canals/toxic_slime_sizzle3.wav", 70, 120)

	local effectdata = EffectData()
	effectdata:SetOrigin(pos)
	effectdata:SetScale(18)
	effectdata:SetMagnitude(12)
	util.Effect("BloodImpact", effectdata, true, true)

	for i = 1, 16 do
		local offset = VectorRand() * math.random(40, 110)
		offset.z = math.abs(offset.z) * 0.6

		local ed = EffectData()
		ed:SetOrigin(pos + offset)
		ed:SetScale(math.random(5, 9))
		ed:SetMagnitude(6)
		util.Effect("BloodImpact", ed, true, true)
	end

	for i = 1, 6 do
		local groundPos = pos + Vector(math.Rand(-80, 80), math.Rand(-80, 80), 0)
		util.Decal("Blood", groundPos + Vector(0,0,20), groundPos - Vector(0,0,60))
	end

	ParticleEffect("blood_impact_red_01", pos, Angle(0,0,0), nil)

	for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
		if IsValid(ent) and (ent:IsNPC() or ent:IsNextBot()) and ent:Health() > 0 then
			if ent:GetNWEntity("HordeOwner"):IsValid() then continue end

			local dmginfo = DamageInfo()
			dmginfo:SetAttacker(ply)
			dmginfo:SetInflictor(self)
			dmginfo:SetDamage(damage)
			dmginfo:SetDamageType(DMG_SLASH)
			dmginfo:SetDamagePosition(ent:GetPos() + ent:OBBCenter())
			ent:TakeDamageInfo(dmginfo)

			local ed = EffectData()
			ed:SetOrigin(ent:GetPos() + ent:OBBCenter())
			ed:SetScale(5)
			util.Effect("BloodImpact", ed, true, true)
		end
	end

	util.ScreenShake(pos, 12, 10, 0.8, 400)
end

function SWEP:ActivateDeadlyAppetite()
	local ply = self.Owner
	if not IsValid(ply) then return end

	local cd = CurTime() + self.AppetiteCooldown
	ply.Ghoul_NextAppetite = cd
	self.NextAppetite = cd
	self:SetAppetiteCDEnd( cd )
	self:SetAppetiteEnd( CurTime() + self.AppetiteDuration )
	self:SetIsAppetiteActive( true )

	ply:EmitSound( AppetiteScream, 110, 70 )
	ply:EmitSound( "npc/zombie/zombie_voice_idle" .. math.random(1,14) .. ".wav", 90, 60 )

	self.OriginalAttackSpeed = self.AttackSpeedMultiplier
	self.AttackSpeedMultiplier = self.AppetiteAttackSpeed

	ply.Ghoul_AppetiteInvincible = true

	local necroID, tick = TimerID( "GhoulClaws_Necrosis_", ply ), self.NecrosisTickTime
	local threshold, perTick = self.NecrosisThreshold, self.NecrosisRate * self.NecrosisTickTime
	timer.Create( necroID, tick, 0, function()
		if not IsValid(ply) or not ply.Ghoul_AppetiteInvincible then timer.Remove( necroID ) return end
		if not ply:Alive() then return end

		local hp = ply:Health()
		if hp > 0 then
			ClearAppetiteNecrosis( ply )
		elseif hp <= threshold then
			AddAppetiteNecrosis( ply, perTick )
		end
	end )

	local wep = self
	timer.Create( TimerID( "GhoulClaws_Appetite_", ply ), self.AppetiteDuration, 1, function()
		if not IsValid(ply) then return end
		if IsValid(wep) then
			wep:EndDeadlyAppetite()
		else
			EndAppetiteForPlayer( ply )
			ResolveAppetiteDebt( ply )
		end
	end)
end

function SWEP:EndDeadlyAppetite()
	self:SetIsAppetiteActive( false )
	self:SetAppetiteEnd( 0 )

	self.AttackSpeedMultiplier = self.OriginalAttackSpeed or 2.5

	local ply = self:GetAbilityOwner()
	local wasActive = IsValid(ply) and ply.Ghoul_AppetiteInvincible
	EndAppetiteForPlayer( ply )

	if wasActive then ResolveAppetiteDebt( ply ) end
end

if SERVER then
	util.AddNetworkString( "GhoulClaws_RequestAbility" )

	net.Receive( "GhoulClaws_RequestAbility", function( len, ply )
		if not IsValid(ply) or not ply:Alive() then return end
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or not wep.ActivateCorpseCamouflage then return end

		local ability = net.ReadUInt(2)
		local ct = CurTime()

		if ability == 0 and ct >= (ply.Ghoul_NextCamouflage or wep.NextCamouflage or 0) then
			wep:ActivateCorpseCamouflage()
		elseif ability == 1 and ct >= (ply.Ghoul_NextBoneBurst or wep.NextBoneBurst or 0) then
			wep:ActivateBoneBurst()
		elseif ability == 2 and ct >= (ply.Ghoul_NextAppetite or wep.NextAppetite or 0) then
			wep:ActivateDeadlyAppetite()
		end
	end )

	local function ClearGhoulAbilities( ply )
		if not IsValid(ply) then return end
		EndCamouflageForPlayer( ply )
		EndAppetiteForPlayer( ply )

		for _, w in ipairs( ply:GetWeapons() ) do
			if IsValid(w) and w.ActivateCorpseCamouflage then
				w:SetIsCamouflaged( false )
				w:SetCamouflageEnd( 0 )
				w:SetIsAppetiteActive( false )
				w:SetAppetiteEnd( 0 )
				w.AttackSpeedMultiplier = w.OriginalAttackSpeed or w.AttackSpeedMultiplier
			end
		end
	end

	hook.Add( "PlayerDeath",        "GhoulClaws_ClearOnDeath",      ClearGhoulAbilities )
	hook.Add( "PlayerSilentDeath",  "GhoulClaws_ClearOnSilentDeath", ClearGhoulAbilities )
	hook.Add( "PlayerSpawn",        "GhoulClaws_ClearOnSpawn",      ClearGhoulAbilities )
	hook.Add( "PlayerDisconnected", "GhoulClaws_ClearOnDisconnect", ClearGhoulAbilities )

	hook.Add( "Horde_OnPlayerDamageTaken", "GhoulClaws_AppetiteInvincible", function( ply, dmginfo, bonus )
		if ply.Ghoul_AppetiteInvincible then
			return true
		end
	end )

	hook.Add( "EntityTakeDamage", "GhoulClaws_AppetiteInvincibleFallback", function( target, dmginfo )
		if IsValid(target) and target:IsPlayer() and target.Ghoul_AppetiteInvincible then
			return true
		end
	end )

	hook.Add( "PlayerShouldTakeDamage", "GhoulClaws_AppetiteInvincibleRules", function( ply, attacker )
		if IsValid(ply) and ply.Ghoul_AppetiteInvincible then
			return false
		end
	end )

	hook.Add( "EntityTakeDamage", "GhoulClaws_RageHPSnapshot", function( target, dmginfo )
		if IsValid(target) and target:IsPlayer() and target.Ghoul_AppetiteInvincible then
			target.Ghoul_RageHPSnap = target:Health()
		end
	end )

	hook.Add( "PostEntityTakeDamage", "GhoulClaws_RageHPRestore", function( target, dmginfo, took )
		if not IsValid(target) or not target:IsPlayer() then return end
		local snap = target.Ghoul_RageHPSnap
		target.Ghoul_RageHPSnap = nil
		if snap and snap < 0 and target:Alive() and target.Ghoul_AppetiteInvincible and target:Health() ~= snap then
			target:SetHealth( snap )
		end
	end )
end

hook.Add( "CalcMainActivity", "GhoulClaws_ZombieAnims", function( ply, velocity )
	if not IsValid(ply) then return end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or not wep.ActivateCorpseCamouflage then return end

	if not ply:OnGround() then return end

	local len2d = velocity:Length2D()

	if len2d > 150 then
		return ACT_HL2MP_RUN_ZOMBIE_FAST, -1
	elseif len2d > 10 then
		return ACT_HL2MP_WALK_ZOMBIE_06, -1
	else
		return ACT_HL2MP_IDLE_ZOMBIE, -1
	end
end )

local oldPrimary = SWEP.PrimaryAttack
function SWEP:PrimaryAttack()
	local ply = self.Owner
	if IsValid(ply) then
		ply:AnimResetGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD )
		ply:AnimRestartGesture( GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_RANGE_ZOMBIE, true )
	end
	return oldPrimary( self )
end

local oldSecondary = SWEP.SecondaryAttack
function SWEP:SecondaryAttack()
	local ply = self.Owner
	if IsValid(ply) then
		ply:AnimResetGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD )
		ply:AnimRestartGesture( GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL, true )
	end
	return oldSecondary( self )
end

function SWEP:OnDrop()
	if SERVER then
		self:EndCorpseCamouflage()
		self:EndDeadlyAppetite()
	end
	self:Remove()
end

function SWEP:Holster()
	if SERVER then
		self:EndCorpseCamouflage()
	end
	return true
end

function SWEP:Deploy()
	local ply = self.Owner
	if IsValid(ply) then self.Ghoul_LastOwner = ply end
	local vm = IsValid(ply) and ply:GetViewModel() or nil
	if IsValid(vm) then
		vm:SendViewModelMatchingSequence( vm:LookupSequence( "draw" ) )
		vm:SetPlaybackRate( 1 )
	end

	self:UpdateNextIdle()

	if SERVER and IsValid(ply) then
		self:SetCombo( 0 )
		self:SetNWInt("AttackMode", 0)

		self:RestoreCooldowns( ply )
	end

	return true
end

function SWEP:Think()
	local ply = self.Owner
	if not IsValid(ply) then return end

	local vm = ply:GetViewModel()
	local idletime = self:GetNextIdle()

	if idletime > 0 and CurTime() > idletime then
		if IsValid(vm) then
			vm:SendViewModelMatchingSequence( vm:LookupSequence( "idle_cycle" ) )
			vm:SetPlaybackRate( 1 )
		end
		self:UpdateNextIdle()
	end

	local meleetime = self:GetNextMeleeAttack()
	if meleetime > 0 and CurTime() > meleetime then
		self:DealDamage()
		self:SetNextMeleeAttack( 0 )
	end

	if SERVER and CurTime() > self:GetNextPrimaryFire() + 0.1 then
		self:SetCombo( 0 )
	end

	if SERVER then
		if self:GetIsCamouflaged() and CurTime() > self:GetCamouflageEnd() then
			self:EndCorpseCamouflage()
		end
		if self:GetIsAppetiteActive() and CurTime() > self:GetAppetiteEnd() then
			self:EndDeadlyAppetite()
		end
	end

	end

if CLIENT then
	local nextKeySend = 0
	local keyHeld = {}

	local function KeyPressed( id, key )
		local down = input.IsButtonDown( key )
		local was = keyHeld[id]
		keyHeld[id] = down
		return down and not was
	end

	local function SendAbility( id )
		nextKeySend = CurTime() + 0.25
		net.Start( "GhoulClaws_RequestAbility" )
			net.WriteUInt( id, 2 )
		net.SendToServer()
	end

	local STATUS_NAMES = { "Ghoul_Camouflage", "Ghoul_BoneBurst", "Ghoul_Appetite" }
	local function SyncStatusIcons( ply, show )
		if not ply.SetStatus then return end
		local tbl = ply.GetStatusTable and ply:GetStatusTable() or {}
		for _, name in ipairs( STATUS_NAMES ) do
			local id = HORDE:GetStatusID( name )
			if id and ( ( tbl[id] or 0 ) > 0 ) ~= show then
				ply:SetStatus( id, show and 1 or 0 )
			end
		end
	end

	hook.Add( "Think", "GhoulClaws_AbilityKeys", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end

		local hasClaws = ply:Alive() and ply:HasWeapon( "horde_ghoul_claws" )
		SyncStatusIcons( ply, hasClaws )
		if not hasClaws then
			keyHeld.camouflage, keyHeld.appetite = false, false
			return
		end

		local keys = HORDE.GhoulClaws and HORDE.GhoulClaws.Keys
		if not keys then return end

		local wep = ply:GetActiveWeapon()
		local holding = IsValid(wep) and wep:GetClass() == "horde_ghoul_claws"
		local blocked = not holding
			or gui.IsGameUIVisible() or gui.IsConsoleVisible()
			or vgui.CursorVisible() or ply:IsTyping()

		local camPressed = KeyPressed( "camouflage", keys.camouflage.key )
		local appPressed = KeyPressed( "appetite",   keys.appetite.key )

		if blocked or CurTime() < nextKeySend then return end

		if camPressed then
			SendAbility( 0 )
		elseif appPressed then
			SendAbility( 2 )
		end
	end )

	local VIGNETTE = Material( "gui/vignette.png", "smooth" )

	local FX = {
		camouflage = {
			col = Color( 30, 110, 255 ),
			spriteAlpha = 235,
			washAlpha   = 0,
			fadeIn      = 0.7,
			fadeOut     = 1.2,
			isActive    = "GetIsCamouflaged",
			endTime     = "GetCamouflageEnd",
			a = 0,
		},
		appetite = {
			col = Color( 255, 12, 12 ),
			spriteAlpha = 220,
			washAlpha   = 38,
			fadeIn      = 0.35,
			fadeOut     = 1.0,
			isActive    = "GetIsAppetiteActive",
			endTime     = "GetAppetiteEnd",
			a = 0,
		},
	}

	local function Ease( t ) return t * t * ( 3 - 2 * t ) end

	local function FXTarget( def, ply, wep )
		if not ply:Alive() or not IsValid( wep ) then return 0 end
		local isActive, endTime = wep[def.isActive], wep[def.endTime]
		if not isActive or not endTime or not isActive( wep ) then return 0 end
		return ( endTime( wep ) - CurTime() ) > def.fadeOut and 1 or 0
	end

	local function DrawFX( def, w, h )
		local e = Ease( def.a )
		if e <= 0.004 then return end

		local c = def.col

		if def.washAlpha > 0 then
			surface.SetDrawColor( c.r, c.g, c.b, def.washAlpha * e )
			surface.DrawRect( 0, 0, w, h )
		end

		if not VIGNETTE:IsError() then
			surface.SetMaterial( VIGNETTE )
			surface.SetDrawColor( c.r, c.g, c.b, def.spriteAlpha * e )
			surface.DrawTexturedRect( 0, 0, w, h )
		end
	end

	hook.Add( "HUDPaintBackground", "GhoulClaws_ScreenFX", function()
		local ply = LocalPlayer()
		if not IsValid( ply ) then return end

		local wep = ply:GetWeapon( "horde_ghoul_claws" )
		local dt  = RealFrameTime()
		local w, h = ScrW(), ScrH()

		for _, def in pairs( FX ) do
			local target = FXTarget( def, ply, wep )
			local rate   = dt / ( target > def.a and def.fadeIn or def.fadeOut )
			def.a = math.Approach( def.a, target, rate )
		end

		DrawFX( FX.camouflage, w, h )
		DrawFX( FX.appetite,   w, h )
	end )
end
