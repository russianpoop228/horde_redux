if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end
SWEP.Base = "weapon_vj_base"
SWEP.PrintName = "DANK-12"
SWEP.Purpose = "Overlord's Clone Weapons."
SWEP.Instructions = "Use on Overlord's Clone."
SWEP.Category = "VJ Base"
if CLIENT then
	SWEP.Slot = 3
	SWEP.SlotPos = 4
	SWEP.UseHands = true
end
SWEP.NPC_NextPrimaryFire = 0.8
SWEP.NPC_CustomSpread = 2.5
SWEP.NPC_ExtraFireSound = {"weapons/shotgun/shotgun_cock.wav"}
SWEP.NPC_FiringDistanceScale = 0.08
SWEP.ViewModel = "models/weapons/c_shotgun.mdl"
SWEP.WorldModel = "models/weapons/w_shotgun.mdl"
SWEP.HoldType = "shotgun"
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.Primary.Damage = 20
SWEP.Primary.PlayerDamage = "Double"
SWEP.Primary.Force = 1
SWEP.Primary.NumberOfShots = 8
SWEP.Primary.ClipSize = 18
SWEP.Primary.Cone = 12
SWEP.Primary.Delay = 0.8
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "Buckshot"
SWEP.Primary.Sound = {"weapons/shotgun/shotgun_fire6.wav", "weapons/shotgun/shotgun_fire7.wav"}
SWEP.Primary.DistantSound = "arccw_go/sawedoff/sawedoff-1-distant.wav"
SWEP.PrimaryEffects_MuzzleAttachment = 1
SWEP.PrimaryEffects_ShellAttachment = 2
SWEP.PrimaryEffects_ShellType = "VJ_Weapon_ShotgunShell1"
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "Buckshot"
SWEP.HasReloadSound = true
SWEP.ReloadSound = {"weapons/shotgun/shotgun_reload1.wav","weapons/shotgun/shotgun_reload2.wav","weapons/shotgun/shotgun_reload3.wav"}
SWEP.Reload_TimeUntilAmmoIsSet = 0
SWEP.Primary.Tracer = 0
SWEP.Primary.DisableBulletCode = false

function SWEP:CustomOnInitialize()
    local owner = self:GetOwner():GetNWEntity("HordeOwner")
    if owner.Horde_Special_Upgrades and owner.Horde_Special_Upgrades["module_paranoia"] then
        self.NPC_FiringDistanceScale = 0.08 * 1.5
        self.NPC_CustomSpread = 2.5 / 1.5
    end
end
