function EFFECT:Init(effectdata)
    local pos = effectdata:GetOrigin()

    local emitter = ParticleEmitter(pos)
    emitter:SetNearClip(24, 32)

    for i = 1, 10 do
        local particle = emitter:Add("particles/smokey",
            pos + Vector(math.Rand(-30, 30), math.Rand(-30, 30), math.Rand(0, 40)))

        particle:SetVelocity(VectorRand():GetNormal() * 60)
        particle:SetDieTime(math.Rand(2.5, 4.0))
        particle:SetStartAlpha(160)
        particle:SetEndAlpha(0)
        particle:SetStartSize(math.Rand(40, 80))
        particle:SetEndSize(math.Rand(128, 256))
        particle:SetRoll(math.Rand(-360, 360))
        particle:SetRollDelta(math.Rand(-0.8, 0.8))
        particle:SetColor(255, 255, 255)
        particle:SetGravity(Vector(0, 0, 20))
        particle:SetAirResistance(150)
        particle:SetLighting(false)
        particle:SetCollide(false)
    end

    emitter:Finish()
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
end
