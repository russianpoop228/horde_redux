AddCSLuaFile()
if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end

ENT.Type 			= "anim"
ENT.Base 			= "obj_vj_projectile_base"
ENT.PrintName		= "Tank Shell"
ENT.Information		= "Projectiles for my addons"
ENT.Category		= "Projectiles"

ENT.VJ_IsDetectableDanger = true

if CLIENT then
	local Name = "Tank Shell"
	local LangName = "obj_vj_tank_shell"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))

	function ENT:Think()
	end
end
if !SERVER then return end

ENT.Model = {"models/weapons/w_missile_launch.mdl"}
ENT.DoesRadiusDamage = false
ENT.RadiusDamageRadius = 250
ENT.RadiusDamage = 40
ENT.RadiusDamageUseRealisticRadius = true
ENT.RadiusDamageType = DMG_BLAST
ENT.RadiusDamageForce = 90
ENT.DecalTbl_DeathDecals = {"Scorch"}
ENT.SoundTbl_Idle = {"weapons/rpg/rocket1.wav"}
ENT.SoundTbl_OnCollide = {"ambient/explosions/explode_8.wav"}
function ENT:CustomOnInitialize()
	ParticleEffectAttach("vj_rocket_idle1", PATTACH_ABSORIGIN_FOLLOW, self, 0)
	ParticleEffectAttach("vj_rocket_idle2", PATTACH_ABSORIGIN_FOLLOW, self, 0)

end
local defAngle = Angle(0, 0, 0)
function ENT:DeathEffects(data, phys)
	util.ScreenShake(data.HitPos, 16, 200, 1, 3000)
	ParticleEffect("vj_explosion3", self:GetPos(), defAngle, nil)

	local effectData = EffectData()
	effectData:SetOrigin(data.HitPos)
	util.Effect("Explosion", effectData)

	local expLight = ents.Create("light_dynamic")
	expLight:SetKeyValue("brightness", "4")
	expLight:SetKeyValue("distance", "300")
	expLight:SetLocalPos(data.HitPos)
	expLight:SetLocalAngles(self:GetAngles())
	expLight:Fire("Color", "255 150 0")
	expLight:SetParent(self)
	expLight:Spawn()
	expLight:Activate()
	expLight:Fire("TurnOn", "", 0)
	self:DeleteOnRemove(expLight)
end

function ENT:CustomOnPhysicsCollide(data, phys)
    if self.Dead then return end
    if not self.Owner:IsValid() then self:Remove() return end
    self.Dead = true
    local dmg = DamageInfo()
    PrintTable(data)
	local gunPos = self.Owner:GetShootPos()
	local hitPos = data.HitPos

	local x = (gunPos.x - hitPos.x)^2;
	local y = (gunPos.y - hitPos.y)^2;
	local z = (gunPos.z - hitPos.z)^2;
	local distance = math.sqrt(x + y + z);

	local max_distance = 1500
    local scaled_dmg = self.RadiusDamage * 0.5 * (1 + math.min(distance, max_distance) / max_distance)

    dmg:SetAttacker(self.Owner)
    dmg:SetInflictor(self)
    dmg:SetDamageType(self.RadiusDamageType)
    dmg:SetDamage(scaled_dmg)
    util.BlastDamageInfo(dmg, self:GetPos(), self.RadiusDamageRadius)

    self:Remove()
end
