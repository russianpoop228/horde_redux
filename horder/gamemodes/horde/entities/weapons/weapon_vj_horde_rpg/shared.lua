if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end
if CLIENT then
    killicon.AddAlias("weapon_vj_horde_rpg", "arccw_horde_rpg7")
end
SWEP.Base 						= "weapon_vj_base"
SWEP.PrintName					= "RPG"
SWEP.Purpose					= "This weapon is made for Players and NPCs"
SWEP.Instructions				= "Controls are like a regular weapon."
SWEP.Category					= "VJ Base"
if CLIENT then
SWEP.Slot						= 4
SWEP.SlotPos					= 4
SWEP.UseHands					= true
end
SWEP.NPC_NextPrimaryFire 		= 7
SWEP.NPC_TimeUntilFire	 		= 0.8
SWEP.NPC_ReloadSound			= "vj_base/weapons/reload_rpg.wav"
SWEP.NPC_BulletSpawnAttachment = "missile"
SWEP.NPC_FiringDistanceScale = 2.5
SWEP.NPC_StandingOnly = true
SWEP.ViewModel					= "models/vj_base/weapons/c_rpg7.mdl"
SWEP.WorldModel					= "models/vj_base/weapons/w_rpg7.mdl"
SWEP.WorldModel_UseCustomPosition = true
SWEP.WorldModel_CustomPositionAngle = Vector(-10, 0, 180)
SWEP.WorldModel_CustomPositionOrigin = Vector(-1.5, -0.5, 1)
SWEP.HoldType 					= "rpg"
SWEP.ViewModelFOV				= 60
SWEP.Spawnable					= true
SWEP.AdminSpawnable				= false
SWEP.Primary.Damage				= 5
SWEP.Primary.Force				= 5
SWEP.Primary.ClipSize			= 1
SWEP.Primary.Recoil				= 0.6
SWEP.Primary.Delay				= 0.3
SWEP.Primary.Automatic			= true
SWEP.Primary.Ammo				= "RPG_Round"
SWEP.Primary.Sound				= {"vj_base/weapons/rpg/single.wav"}
SWEP.Primary.DistantSound		= {"vj_base/weapons/rpg/single.wav"}
SWEP.Primary.DisableBulletCode	= true
SWEP.PrimaryEffects_MuzzleAttachment = 1
SWEP.PrimaryEffects_SpawnShells = false
SWEP.HasReloadSound				= true
SWEP.Reload_TimeUntilAmmoIsSet	= 0.8
SWEP.ReloadSound				= "vj_weapons/reload_rpg.wav"
SWEP.Critical = nil
function SWEP:CustomOnPrimaryAttack_BeforeShoot()
	if CLIENT then return end
	local owner = self:GetOwner()
	local proj = ents.Create("obj_vj_horde_platoon_rpg_projectile")
	local ply_Ang = owner:GetAimVector():Angle()
	local ply_Pos = owner:GetShootPos() + ply_Ang:Forward()*-20 + ply_Ang:Up()*-9 + ply_Ang:Right()*10
	if owner:IsPlayer() then proj:SetPos(ply_Pos) else proj:SetPos(self:GetAttachment(1).Pos) end
	if owner:IsPlayer() then proj:SetAngles(ply_Ang) else proj:SetAngles(owner:GetAngles()) end
	proj:SetOwner(owner)
	proj:Activate()
	proj:Spawn()

	local phys = proj:GetPhysicsObject()
	if IsValid(phys) then
		if owner:IsPlayer() then
			phys:SetVelocity(owner:GetAimVector() * 2500)
		else
			phys:SetVelocity(owner:CalculateProjectile("Line", self:GetAttachment(1).Pos, owner:GetEnemy():GetPos() + owner:GetEnemy():OBBCenter(), 2500))
		end
	end

	self:SetBodygroup(1, 1)
end
function SWEP:CustomOnPrimaryAttackEffects()
	ParticleEffectAttach("smoke_exhaust_01a", PATTACH_POINT_FOLLOW, self, 2)
	ParticleEffectAttach("smoke_exhaust_01a", PATTACH_POINT_FOLLOW, self, 2)
	ParticleEffectAttach("smoke_exhaust_01a", PATTACH_POINT_FOLLOW, self, 2)
	timer.Simple(4, function() if IsValid(self) then self:StopParticles() end end)
	return true
end
function SWEP:CustomOnReload_Finish()
	self:SetBodygroup(1, 0)
	return true
end

function SWEP:CustomOnThink()
	if not self.Critical and self:GetOwner() and IsValid(self:GetOwner()) then
		if self:GetOwner().Critical then
			self.NPC_NextPrimaryFire = 5
		end
	end
end
