if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end
SWEP.Base 						= "weapon_vj_base"
SWEP.PrintName					= "SMG1"
SWEP.Purpose					= "This weapon is made for Players and NPCs"
SWEP.Instructions				= "Controls are like a regular weapon."
SWEP.Category					= "VJ Base"
if CLIENT then
SWEP.Slot						= 2
SWEP.SlotPos					= 4
SWEP.UseHands					= true
end
SWEP.ViewModel					= "models/weapons/arccw_go/v_mach_m249para.mdl"
SWEP.WorldModel					= "models/weapons/arccw_go/v_mach_m249para.mdl"
SWEP.WorldModel_UseCustomPosition = true
SWEP.WorldModel_CustomPositionAngle = Vector(0, 0, 180)
SWEP.WorldModel_CustomPositionOrigin = Vector(-8, -15, 13)
SWEP.WorldModel_CustomPositionBone = "ValveBiped.Bip01_R_Hand"
SWEP.WorldModel_Invisible = false
SWEP.WorldModel_NoShadow = false
SWEP.HoldType 					= "ar2"
SWEP.Spawnable					= true
SWEP.AdminSpawnable				= false
SWEP.NPC_HasSecondaryFire = false
SWEP.NPC_SecondaryFireSound = {"weapons/ar2/ar2_altfire.wav"}
SWEP.Primary.Damage				= 0
SWEP.Primary.ClipSize			= 100
SWEP.Primary.Delay				= 0.09
SWEP.Primary.Automatic			= true
SWEP.Primary.Ammo				= "SMG1"
SWEP.Primary.Sound				= {"arccw_go/m249/m249-1.wav"}
SWEP.Primary.DistantSound		= {"arccw_go/m249/m249-1-distant.wav"}
SWEP.NPC_TimeUntilFireExtraTimers = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0}
SWEP.PrimaryEffects_MuzzleAttachment = 1
SWEP.PrimaryEffects_ShellAttachment = 2
SWEP.PrimaryEffects_ShellType = "VJ_Weapon_PistolShell1"
SWEP.NPC_NextPrimaryFire = 5
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = nil
SWEP.HasReloadSound = false
SWEP.ReloadSound = {"weapons/smg1/smg1_reload.wav"}
SWEP.Primary.Tracer = 0
SWEP.Primary.DisableBulletCode = true
function SWEP:CustomOnPrimaryAttack_BeforeShoot()
	if CLIENT then return end
	local bullet = ents.Create("obj_vj_horde_bullet")
	local src = self:GetAttachment(1).Pos
	bullet:SetPos(src)
	bullet:SetAngles(self:GetOwner():GetAngles())
	bullet:SetOwner(self:GetOwner())
	bullet:Activate()
	bullet:Spawn()
	bullet.DirectDamage = 6
	if self.Owner.Weaken then
		bullet.Weaken = true
	elseif self.Owner.Hinder then
		bullet.Hinder = true
	end

	local phy = bullet:GetPhysicsObject()
	if phy:IsValid() then
		local enemy = self:GetOwner():GetEnemy()
		if IsValid(enemy) then
			local dir = (enemy:WorldSpaceCenter() - src)
			dir:Normalize()
			dir = dir + VectorRand() * 0.03
			dir:Normalize()
			phy:ApplyForceCenter(dir * 1000)
		end
	end
end

function SWEP:CustomOnThink()
	if not self.Critical and self:GetOwner() and IsValid(self:GetOwner()) then
		if self:GetOwner().Critical then
			self.NPC_NextPrimaryFire = 3
		end
	end
end
