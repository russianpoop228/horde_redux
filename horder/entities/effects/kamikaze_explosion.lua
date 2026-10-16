if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end
function EFFECT:Init(data)
	self.Pos = data:GetOrigin()
	sound.Play("weapons/explode4.wav", self.Pos, 80, math.random(70, 90))
	local radius = data:GetRadius()
	local Emitter = ParticleEmitter(self.Pos)
	if Emitter == nil then return end

	for _ = 1, 3 do
		local EffectCode = Emitter:Add("particles/flamelet1",self.Pos)
		EffectCode:SetVelocity(Vector(math.random(-30,30),math.random(-30,30),math.random(30,40)))
		EffectCode:SetDieTime(0.2)
		EffectCode:SetStartAlpha(math.Rand(90,100))
		EffectCode:SetStartSize(radius / 1.5)
		EffectCode:SetEndSize(radius)
		EffectCode:SetRoll(math.Rand(480,540))
		EffectCode:SetRollDelta(math.Rand(0,0))
		EffectCode:SetColor(255,255,255)
		EffectCode:SetGravity(Vector(0,0,math.random(-30,-10)))
	end

	for _ = 1, 5 do
		local EffectCode = Emitter:Add("particles/smokey",self.Pos)
		EffectCode:SetVelocity(Vector(math.random(-40,40),math.random(-40,40),math.random(5,15)))
		EffectCode:SetDieTime(0.5)
		EffectCode:SetStartAlpha(math.Rand(200,230))
		EffectCode:SetStartSize(radius / 2)
		EffectCode:SetEndSize(radius)
		EffectCode:SetRoll(math.Rand(480,540))
		EffectCode:SetRollDelta(math.Rand(-0.2,0.2))
		EffectCode:SetColor(50,50,50)
		EffectCode:SetGravity(Vector(0, 0, 0))
		EffectCode:SetAirResistance(15)
	end

	for _ = 1, 5 do
		local EffectCode = Emitter:Add("particles/smokey",self.Pos)
		EffectCode:SetVelocity(Vector(math.random(-60,70),math.random(-60,70),math.random(70,100)))
		EffectCode:SetDieTime(0.5)
		EffectCode:SetStartAlpha(math.Rand(150,190))
		EffectCode:SetStartSize(radius / 2)
		EffectCode:SetEndSize(radius)
		EffectCode:SetRoll(math.Rand(480,540))
		EffectCode:SetRollDelta(math.Rand(-1,1))
		EffectCode:SetColor(50,50,50)
		EffectCode:SetGravity(Vector(0,0,math.random(-30,-10)))
	end

	for i=1, 10 do
		local EffectCode = Emitter:Add("effects/spark", self.Pos)
		EffectCode:SetDieTime(0.3)
		EffectCode:SetColor(245, 250, 255)
		EffectCode:SetStartAlpha(255)
		EffectCode:SetEndAlpha(0)
		EffectCode:SetStartSize(0)
		EffectCode:SetEndSize(10)
		EffectCode:SetStartLength(0)
		EffectCode:SetEndLength(10)
		EffectCode:SetVelocity(VectorRand():GetNormal() * 220)
	end
	Emitter:Finish()
end
function EFFECT:Think()
	return false
end
function EFFECT:Render()
end
