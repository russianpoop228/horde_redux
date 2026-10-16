function EFFECT:Init(data)
    local radius = data:GetRadius()
	local pos = data:GetOrigin()
	local redcolor = data:GetColor()

    local emitter = ParticleEmitter(pos)
    local emitter2 = ParticleEmitter(pos, true)
    emitter2:SetNearClip(24, 32)
    for i = 1,10 do
        local smoke = emitter:Add("particles/smokey", pos)
        smoke:SetGravity(Vector(0,0,-200))
        smoke:SetDieTime(radius/225)
        smoke:SetStartAlpha(100)
        smoke:SetEndAlpha(0)
        smoke:SetStartSize(10)
        smoke:SetEndSize(radius * math.random(0.5,1))
        smoke:SetRoll(math.Rand(-180, 180) )
        smoke:SetRollDelta(math.Rand(-0.2,0.2) )
        smoke:SetColor(redcolor, 50, 50)
        smoke:SetAirResistance(0)
        local p = VectorRand() * 50
        p.z = 35
        smoke:SetPos( pos + p)
        smoke:SetLighting( false )
        smoke:SetCollide(true)
        smoke:SetBounce(0)
    end
    emitter:Finish()

    local normal = Vector(0,0,1)
    local ringstart = pos + normal * 10
    local particle
    for i=1, 5 do
        particle = emitter2:Add("effects/select_ring", ringstart)
        particle:SetDieTime(0.3 + (i*0.45) * 0.1)
        particle:SetColor(redcolor, 50, 50)
        particle:SetStartAlpha(255)
        particle:SetEndAlpha(10)
        particle:SetStartSize(0)
        particle:SetEndSize(5 * (radius * 0.6))
        particle:SetAngles(normal:Angle())
    end
    emitter2:Finish()
end

function EFFECT:Think()
return false
end

function EFFECT:Render()
end
