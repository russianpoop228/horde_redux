if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end
if CLIENT then
    killicon.AddAlias("weapon_vj_horde_katana", "arccw_horde_katana")
end
SWEP.Base = "weapon_vj_base"
SWEP.PrintName = "Katana"
SWEP.Purpose = "This weapon is made for Players and NPCs"
SWEP.Instructions = "Controls are like a regular weapon."
SWEP.Category = "VJ Base"
SWEP.MadeForNPCsOnly = true
SWEP.NPC_NextPrimaryFire = 1
SWEP.NPC_TimeUntilFire = 0.5
SWEP.WorldModel = "models/horde/weapons/c_katana.mdl"
SWEP.WorldModel_UseCustomPosition = true
SWEP.WorldModel_CustomPositionAngle = Vector(0, 0, 180)
SWEP.WorldModel_CustomPositionOrigin = Vector(-7, -15, 10)
SWEP.WorldModel_CustomPositionBone = "ValveBiped.Bip01_R_Hand"
SWEP.WorldModel_Invisible = false
SWEP.WorldModel_NoShadow = false
SWEP.HoldType = "melee"
SWEP.Primary.Damage = 40
SWEP.IsMeleeWeapon = true
SWEP.MeleeWeaponDistance = 85
SWEP.MeleeWeaponSound_Hit = {"horde/weapons/katana/melee_katana_01.ogg",
"horde/weapons/katana/melee_katana_02.ogg",
"horde/weapons/katana/melee_katana_03.ogg"}
SWEP.MeleeWeaponSound_Miss = {"weapons/iceaxe/iceaxe_swing1.wav"}
SWEP.MeleeAttackDamageAngleRadius = 75
SWEP.HoldType = "melee"

function SWEP:CustomOnPrimaryAttack_BeforeShoot()
    local meleeHitEnt = false
    local owner = self:GetOwner()
		for _,v in ipairs(ents.FindInSphere(owner:GetPos(), self.MeleeWeaponDistance)) do
			if ((v:IsNPC() or (v:IsPlayer() && v:Alive())) && (owner:Disposition(v) != D_LI) && (v != owner) && (v:GetClass() != owner:GetClass()) or (v:GetClass() == "prop_physics") or v:GetClass() == "func_breakable_surf" or v:GetClass() == "func_breakable" && (owner:GetForward():Dot((v:GetPos() -owner:GetPos()):GetNormalized()) > math.cos(math.rad(owner.MeleeAttackDamageAngleRadius)))) then
                local dmginfo = DamageInfo()
				dmginfo:SetDamage(self.Primary.Damage)
				if v:IsNPC() or v:IsPlayer() then dmginfo:SetDamageForce(owner:GetForward() * ((dmginfo:GetDamage() + 100) * 70)) end
				dmginfo:SetInflictor(owner)
				dmginfo:SetAttacker(owner)
				dmginfo:SetDamageType(DMG_SLASH)
				v:TakeDamageInfo(dmginfo, owner)
				if v:IsPlayer() then
					v:ViewPunch(Angle(math.random(-1, 1)*10, math.random(-1, 1)*10, math.random(-1, 1)*10))
                    v:Horde_AddDebuffBuildup(HORDE.Status_Bleeding, 30, owner)
                end
				VJ_DestroyCombineTurret(owner, v)
				meleeHitEnt = true
			end
		end
		if meleeHitEnt == true then
			local meleeSd = VJ_PICK(self.MeleeWeaponSound_Hit)
			if meleeSd != false then
				self:EmitSound(meleeSd, 100, math.random(90, 100))
			end
		else
			local meleeSd = VJ_PICK(self.MeleeWeaponSound_Miss)
			if meleeSd != false then
				self:EmitSound(meleeSd, 100, math.random(90, 100))
			end
		end
    return true
end
