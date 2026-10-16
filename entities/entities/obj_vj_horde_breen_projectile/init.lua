AddCSLuaFile("shared.lua")
include("shared.lua")
ENT.Model = {"effects/combineball.mdl"}
ENT.DoesRadiusDamage = false
ENT.RadiusDamageRadius = 140
ENT.RadiusDamage = 60
ENT.RadiusDamageUseRealisticRadius = true
ENT.RadiusDamageType = DMG_BLAST
ENT.RadiusDamageForce = 90
ENT.ShakeWorldOnDeath = true
ENT.ShakeWorldOnDeathAmplitude = 16
ENT.ShakeWorldOnDeathRadius = 3000
ENT.ShakeWorldOnDeathtDuration = 1
ENT.ShakeWorldOnDeathFrequency = 200
ENT.SoundTbl_Idle = {"weapons/physcannon/energy_sing_flyby1.wav","weapons/physcannon/energy_sing_flyby2.wav"}
ENT.SoundTbl_OnCollide = {"weapons/physcannon/energy_sing_explosion2.wav"}

function ENT:Initialize()
	self:SetModel("models/dav0r/hoverball.mdl")
	self:SetMaterial("models/props_combine/portalball001_sheet")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetMoveCollide(COLLISION_GROUP_PROJECTILE)
	self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
	self:SetSolid(SOLID_CUSTOM)
	self:SetOwner(self:GetOwner())
	self:SetNoDraw(true)

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(1)
		phys:EnableGravity(false)
		phys:EnableDrag(false)
		phys:SetBuoyancyRatio(0)
	end

	self.StartGlow1 = ents.Create( "env_sprite" )
	self.StartGlow1:SetKeyValue( "rendercolor","255 255 255" )
	self.StartGlow1:SetKeyValue( "GlowProxySize","2.0" )
	self.StartGlow1:SetKeyValue( "HDRColorScale","1.0" )
	self.StartGlow1:SetKeyValue( "renderfx","14" )
	self.StartGlow1:SetKeyValue( "rendermode","3" )
	self.StartGlow1:SetKeyValue( "renderamt","255" )
	self.StartGlow1:SetKeyValue( "disablereceiveshadows","0" )
	self.StartGlow1:SetKeyValue( "mindxlevel","0" )
	self.StartGlow1:SetKeyValue( "maxdxlevel","0" )
	self.StartGlow1:SetKeyValue( "framerate","10.0" )
	self.StartGlow1:SetKeyValue( "model","sprites/blueflare1.spr" )
	self.StartGlow1:SetKeyValue( "spawnflags","0" )
	self.StartGlow1:SetKeyValue( "scale","0.75" )
	self.StartGlow1:SetPos( self.Entity:GetPos() )
	self.StartGlow1:Spawn()
	self.StartGlow1:SetParent( self.Entity )
	self:DeleteOnRemove(self.StartGlow1)

	self.StartLight1 = ents.Create("light_dynamic")
	self.StartLight1:SetKeyValue("brightness", "1")
	self.StartLight1:SetKeyValue("distance", "200")
	self.StartLight1:SetLocalPos(self:GetPos())
	self.StartLight1:SetLocalAngles( self:GetAngles() )
	self.StartLight1:Fire("Color", "255 150 0")
	self.StartLight1:SetParent(self)
	self.StartLight1:Spawn()
	self.StartLight1:Activate()
	self.StartLight1:Fire("TurnOn", "", 0)
	self:DeleteOnRemove(self.StartLight1)

	timer.Simple(10, function ()
		if !IsValid(self) then return end
		self:Remove()
	end)
end
function ENT:DeathEffects(data,phys)
	local effectdata = EffectData()
	effectdata:SetOrigin(data.HitPos)
	util.Effect( "HelicopterMegaBomb", effectdata )
	util.Effect( "ThumperDust", effectdata )
	util.Effect( "Explosion", effectdata )
	util.Effect( "energy_explosion", effectdata )
	ParticleEffect("vj_explosion_shockwave1", data.HitPos, Angle(0,0,0))

	self.ExplosionLight1 = ents.Create("light_dynamic")
	self.ExplosionLight1:SetKeyValue("brightness", "4")
	self.ExplosionLight1:SetKeyValue("distance", "300")
	self.ExplosionLight1:SetLocalPos(data.HitPos)
	self.ExplosionLight1:SetLocalAngles(self:GetAngles())
	self.ExplosionLight1:Fire("Color", "255 150 0")
	self.ExplosionLight1:SetParent(self)
	self.ExplosionLight1:Spawn()
	self.ExplosionLight1:Activate()
	self.ExplosionLight1:Fire("TurnOn", "", 0)
	self:DeleteOnRemove(self.ExplosionLight1)
end

function ENT:OnCollision(data, phys)
	if not self.Owner:IsValid() then self:Remove() return true end
	local dmg = DamageInfo()
	dmg:SetAttacker(self.Owner)
	dmg:SetInflictor(self)
	dmg:SetDamageType(DMG_BLAST)
	dmg:SetDamage(30)
	util.BlastDamageInfo(dmg, self:GetPos(), 150)
	dmg2 = DamageInfo()
	dmg2:SetAttacker(self.Owner)
	dmg2:SetInflictor(self)
	dmg2:SetDamageType(DMG_CLUB)
	dmg2:SetDamage(30)
	util.BlastDamageInfo(dmg2, self:GetPos(), 150)

    local breen = self.Owner
	local self_pos = self:GetPos()

    local eff = EffectData()
        eff:SetOrigin(self_pos)
    util.Effect("explosion", eff, true, true)

	if self.OwnerCritical then
		for i =0,10 do
            timer.Simple(0.5 + i * 0.2, function ()
                local rand = VectorRand()
                if rand.z < 0 then rand.z = -rand.z end
                local pos = self_pos + rand * math.Rand(10, 50)
                for _, e1 in pairs(ents.FindInSphere(pos, 150)) do
                    if (HORDE:IsPlayerOrMinion(e1) == true) then
                        if not breen:IsValid() then
                            breen = Entity(0)
                        end
                        local dmginfo = DamageInfo()
                        dmginfo:SetDamage(math.max(10, 0.1 * e1:GetMaxHealth()))
                        dmginfo:SetAttacker(breen)
                        dmginfo:SetInflictor(breen)
                        dmginfo:SetDamagePosition(pos)
                        dmginfo:SetDamageType(DMG_BLAST)
                        e1:TakeDamageInfo(dmginfo)
                    end
                end
                local e = EffectData()
                    e:SetOrigin(pos)
                util.Effect("explosion", e, true, true)
            end)
        end
    end
	return false
end
