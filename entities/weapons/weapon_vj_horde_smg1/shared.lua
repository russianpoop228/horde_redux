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
SWEP.ViewModel					= "models/weapons/c_smg1.mdl"
SWEP.WorldModel					= "models/weapons/w_smg1.mdl"
SWEP.HoldType 					= "smg"
SWEP.Spawnable					= true
SWEP.AdminSpawnable				= false
SWEP.NPC_HasSecondaryFire = false
SWEP.NPC_SecondaryFireSound = {"weapons/ar2/ar2_altfire.wav"}
SWEP.NPC_ReloadSound = "vj_base/weapons/smg1/reload.wav"
SWEP.Primary.Damage				= 0
SWEP.Primary.ClipSize			= 30
SWEP.Primary.Delay				= 0.09
SWEP.Primary.Automatic			= true
SWEP.Primary.Ammo				= "SMG1"
SWEP.Primary.Sound				= "VJ.Weapon_SMG1.Single"
SWEP.Primary.DistantSound		= {"Weapon_SMG1.NPC_Single"}
SWEP.NPC_TimeUntilFireExtraTimers = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6}
SWEP.PrimaryEffects_MuzzleAttachment = 1
SWEP.PrimaryEffects_ShellAttachment = 2
SWEP.PrimaryEffects_ShellType = "VJ_Weapon_PistolShell1"
SWEP.NPC_NextPrimaryFire = 5
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = nil
SWEP.HasReloadSound = true
SWEP.ReloadSound = {"weapons/smg1/smg1_reload.wav"}
SWEP.Primary.Tracer = 0
SWEP.Primary.DisableBulletCode = true

function SWEP:OnPrimaryAttack(status, statusData)
	if CLIENT then return end
	if status == "Init" then
		if SERVER then
			local fireSd = VJ.PICK(self.Primary.Sound)
			if fireSd != false then
				self:EmitSound(fireSd, self.Primary.SoundLevel, math.random(self.Primary.SoundPitch.a, self.Primary.SoundPitch.b), self.Primary.SoundVolume, CHAN_WEAPON, 0, 0, VJ_RecipientFilter)
			end
			if self.Primary.HasDistantSound then
				local fireFarSd = VJ.PICK(self.Primary.DistantSound)
				if fireFarSd != false then
					self:EmitSound(fireFarSd, self.Primary.DistantSoundLevel, math.random(self.Primary.DistantSoundPitch.a, self.Primary.DistantSoundPitch.b), self.Primary.DistantSoundVolume, CHAN_AUTO, 0, 0, VJ_RecipientFilter)
				end
			end
		end
		local bullet = ents.Create("obj_vj_horde_bullet")
		local src = self:GetAttachment(self:LookupAttachment("muzzle")).Pos
		bullet:SetPos(src)
		bullet:SetAngles(self:GetOwner():GetAngles())
		bullet:SetOwner(self:GetOwner())
		bullet:Activate()
		bullet:Spawn()
		bullet.DirectDamage = 5

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
		return true
	end
end
