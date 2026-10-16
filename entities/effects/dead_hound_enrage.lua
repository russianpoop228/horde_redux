function EFFECT:Init(effectdata)
	local pos = effectdata:GetOrigin()
	local normal = Vector(0,0,1)
	local scale = 1.5

	local particle

	sound.Play("ambient/explosions/citadel_end_explosion1.wav", pos, 80, 100)

	local emitter = ParticleEmitter(pos)
	local emitter2 = ParticleEmitter(pos, true)
	emitter:SetNearClip(24, 32)
	emitter2:SetNearClip(24, 32)

	for i=1, 3 do
		local ringstart = pos + normal * 10
		particle = emitter2:Add("effects/select_ring", ringstart)
		particle:SetDieTime(0.1 + 2 * 0.1)
		particle:SetColor(50, 50, 50)
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(0)
		particle:SetStartSize(0)
		particle:SetEndSize(500 * scale)
		particle:SetAngles(normal:Angle())
		particle = emitter2:Add("effects/select_ring", ringstart)
		particle:SetDieTime(0.2 + 2 * 0.1)
		particle:SetColor(50, 50, 50)
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(0)
		particle:SetStartSize(0)
		particle:SetEndSize(650 * scale)
		particle:SetAngles(normal:Angle())
	end

	ParticleEffect("dh_sonicboom", pos, Angle(0, 0, 0))

	for i=1, 2 do
		local smoke = emitter:Add("particles/smokey", pos)
		smoke:SetGravity( Vector(0, 0, 1500) )
		smoke:SetDieTime( math.Rand(1, 2) )
		smoke:SetStartAlpha(255)
		smoke:SetEndAlpha(0)
		smoke:SetStartSize(10)
		smoke:SetEndSize(450 * scale)
		smoke:SetRoll( math.Rand(-180, 180) )
		smoke:SetRollDelta( math.Rand(-0.2,0.2) )
		smoke:SetColor(20, 20, 40)
		smoke:SetAirResistance(1000)
		smoke:SetLighting(false)
		smoke:SetCollide(true)
		smoke:SetBounce(0)
	end

	emitter:Finish()
	emitter2:Finish()

end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
