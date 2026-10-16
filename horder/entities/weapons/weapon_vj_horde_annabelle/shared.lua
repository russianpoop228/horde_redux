if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end
SWEP.Base 						= "weapon_vj_base"
SWEP.PrintName					= "SPAS-12"
SWEP.Purpose					= "This weapon is made for Players and NPCs"
SWEP.Instructions				= "Controls are like a regular weapon."
SWEP.Category					= "VJ Base"
if (CLIENT) then
SWEP.Slot						= 3
SWEP.SlotPos					= 4
SWEP.UseHands					= true
end
SWEP.NPC_NextPrimaryFire 		= 2
SWEP.NPC_CustomSpread	 		= 2
SWEP.NPC_ExtraFireSound			= {}
SWEP.ViewModel					= "models/weapons/c_shotgun.mdl"
SWEP.WorldModel					= "models/weapons/w_annabelle.mdl"
SWEP.HoldType 					= "shotgun"
SWEP.Spawnable					= true
SWEP.AdminSpawnable				= false
SWEP.Primary.Damage				= 15
SWEP.Primary.PlayerDamage		= 15
SWEP.Primary.Force				= 3
SWEP.Primary.NumberOfShots		= 1
SWEP.Primary.ClipSize			= 2
SWEP.Primary.Cone				= 2
SWEP.Primary.Delay				= 5
SWEP.Primary.Automatic			= false
SWEP.Primary.Ammo				= "Buckshot"
SWEP.Primary.Sound				= {"Weapon_Shotgun.Single"}
SWEP.Primary.HasDistantSound	= true
SWEP.Primary.DistantSound		= {"Weapon_Shotgun.NPC_Single"}
SWEP.Primary.DistantSoundVolume	= 0.55
SWEP.PrimaryEffects_MuzzleAttachment = 1
SWEP.PrimaryEffects_ShellAttachment = 2
SWEP.PrimaryEffects_ShellType = "VJ_Weapon_ShotgunShell1"
SWEP.HasReloadSound				= true
SWEP.ReloadSound				= {"weapons/shotgun/shotgun_reload1.wav","weapons/shotgun/shotgun_reload2.wav","weapons/shotgun/shotgun_reload3.wav"}
SWEP.Reload_TimeUntilAmmoIsSet	= 0.5
SWEP.Reload_TimeUntilFinished	= 0.5
SWEP.HasIdleAnimation			= true
SWEP.AnimTbl_Idle				= {ACT_VM_IDLE}
SWEP.NextIdle_Deploy			= 0.5
SWEP.NextIdle_PrimaryAttack		= 1.8

SWEP.FirstTimeShotShotgun = false

function SWEP:CustomOnThink()

if self.Owner.SquadName == "resistance" then

if self.Owner.FollowingPlayer == false then
self.Owner.AnimTbl_IdleStand = {ACT_IDLE_SHOTGUN}
self.Owner.AnimTbl_Run = {ACT_RUN_RIFLE}

self.Owner.AnimTbl_Walk = {ACT_WALK_RIFLE}
end
if self.Owner.FollowingPlayer == true then
self.Owner.AnimTbl_IdleStand = {ACT_IDLE_SHOTGUN_AGITATED}
self.Owner.AnimTbl_Run = {ACT_RUN_RIFLE}
self.Owner.AnimTbl_Walk = {ACT_WALK_RIFLE}
end
end
if self.Owner.SquadName == "metrocop" then
self.HoldType 					= "smg"
self.Primary.Damage				= 10
self.Primary.ClipSize			= 1
self.Owner.WeaponSpread = 0
if self.Owner.FollowingPlayer == false then
self.Owner.AnimTbl_IdleStand = {ACT_IDLE}
self.Owner.AnimTbl_Run = {ACT_RUN}
self.Owner.AnimTbl_WeaponReload = {ACT_RELOAD_SMG1}
self.Owner.AnimTbl_Walk = {ACT_WALK}
end
if self.Owner.FollowingPlayer == true then
self.Owner.AnimTbl_IdleStand = {ACT_IDLE_SMG1}
self.Owner.AnimTbl_Run = {ACT_RUN_RIFLE}
self.Owner.AnimTbl_WeaponReload = {ACT_RELOAD_SMG1}
self.Owner.AnimTbl_Walk = {ACT_WALK_RIFLE}
end
end
if self.Owner.SquadName == "combine" then

if self.Owner.FollowingPlayer == false then
self.Owner.AnimTbl_IdleStand = {ACT_IDLE_SMG1}
self.Owner.AnimTbl_Run = {ACT_RUN_RIFLE}

self.Owner.AnimTbl_Walk = {ACT_WALK_RIFLE}
end
if self.Owner.FollowingPlayer == true then
self.Owner.AnimTbl_IdleStand = {ACT_IDLE_ANGRY_SHOTGUN}
self.Owner.AnimTbl_Run = {ACT_RUN_AIM_SHOTGUN}
self.Owner.AnimTbl_Walk = {ACT_WALK_AIM_SHOTGUN}
end
end
if self.Owner.SquadName == "combine_nova" then

if self.Owner.FollowingPlayer == false then
self.Owner.AnimTbl_IdleStand = {ACT_IDLE_SMG1}
self.Owner.AnimTbl_Run = {ACT_RUN_RIFLE}

self.Owner.AnimTbl_Walk = {ACT_IDLE_SMG1}
end
if self.Owner.FollowingPlayer == true then
self.Owner.AnimTbl_IdleStand = {ACT_IDLE_ANGRY_SHOTGUN}
self.Owner.AnimTbl_Run = {ACT_RUN_AIM_SHOTGUN}
self.Owner.AnimTbl_Walk = {ACT_WALK_AIM_SHOTGUN}
end
end
if self.Owner.SquadName == "metrocops" then
self.HoldType 					= "smg"
if self.Owner.FollowingPlayer == false then

self.Owner.AnimTbl_Run = {ACT_RUN}
self.Owner.AnimTbl_IdleStand = {ACT_IDLE}
self.Owner.AnimTbl_Walk = {ACT_IDLE}
end
if self.Owner.FollowingPlayer == true then
self.Owner.AnimTbl_IdleStand = {ACT_IDLE_SMG1}
self.Owner.AnimTbl_Run = {ACT_RUN_RIFLE}
self.Owner.AnimTbl_Walk = {ACT_WALK_RIFLE}
end
end
end
function SWEP:CustomOnPrimaryAttack_AfterShoot()
	timer.Simple(0.2,function()
		if IsValid(self) && IsValid(self.Owner) && self.Owner:IsPlayer() then
			self.Weapon:EmitSound(Sound("weapons/shotgun/shotgun_empty.wav"),80,100)
			self.Weapon:SendWeaponAnim(ACT_SHOTGUN_PUMP)
		end
	end)
end
