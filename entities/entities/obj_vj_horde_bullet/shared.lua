if CLIENT then
    language.Add("obj_vj_horde_bullet", "Boolet")
    killicon.Add("obj_vj_horde_bullet", "attachments/horde_ammo_sabot.png", color_white)
end

AddCSLuaFile()
if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end

ENT.Type 			= "anim"
ENT.Base 			= "obj_vj_projectile_base"
ENT.PrintName		= "Blaster Rod"
ENT.Information		= "Projectiles for my addons"
ENT.Category		= "Projectiles"
if CLIENT then
	local Name = "Blaster Rod"
	local LangName = "obj_vj_blasterrod"
	language.Add(LangName, Name)
	killicon.Add(LangName,"HUD/killicons/default",Color(255,80,0,255))
	language.Add("#"..LangName, Name)
	killicon.Add("#"..LangName,"HUD/killicons/default",Color(255,80,0,255))
end
if !SERVER then return end

ENT.Model = {"models/items/AR2_Grenade.mdl"}
ENT.DoesDirectDamage = true
ENT.DirectDamage = 5
ENT.DirectDamageType = DMG_BULLET
ENT.TracerColor = Color(255,255,128)
ENT.TracerWidth = 5
ENT.Horde_Plague_Soldier = true
ENT.dt = 0
function ENT:CustomOnInitialize()
	self:DrawShadow(false)
	self:SetRenderMode(RENDERMODE_TRANSCOLOR)
	self:SetColor(Color(255,255,255,1))
	util.SpriteTrail(self, 0, self.TracerColor, false, self.TracerWidth, self.TracerWidth, 0.1, 1/(8+8)*0.5, "vj_base/sprites/trail.vmt")
    self.dt = CurTime() + 4
end

function ENT:Think()
    if SERVER then
        if CurTime() >= self.dt then
            self:Remove()
        end
    end
end

function ENT:CustomOnDoDamage_Direct(data, phys, hitEnt)
	if not hitEnt then
		return
	end
	if self.Weaken then
		hitEnt:Horde_AddWeaken(self, 3, 1)
	elseif self.Hinder then
		hitEnt:Horde_AddHinder(self, 3, 1)
	end
end
