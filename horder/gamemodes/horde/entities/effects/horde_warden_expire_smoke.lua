function EFFECT:Init(data)
    local pos = data:GetOrigin()
    local scale = data:GetScale()
    if not scale or scale <= 0 then scale = 0.6 end

    local emitter = ParticleEmitter(pos)
    if not emitter then return end

    for i = 1, 4 do
        local smoke = emitter:Add("particles/smokey", pos + VectorRand() * 6 * scale)
        if smoke then
            smoke:SetVelocity(Vector(math.Rand(-30, 30), math.Rand(-30, 30), math.Rand(20, 50)) * scale)
            smoke:SetGravity(Vector(0, 0, 40))
            smoke:SetDieTime(math.Rand(0.35, 0.65))
            smoke:SetStartAlpha(140)
            smoke:SetEndAlpha(0)
            smoke:SetStartSize(8 * scale)
            smoke:SetEndSize(36 * scale)
            smoke:SetRoll(math.Rand(-180, 180))
            smoke:SetRollDelta(math.Rand(-0.3, 0.3))
            smoke:SetColor(160, 160, 160)
            smoke:SetAirResistance(80)
            smoke:SetLighting(false)
            smoke:SetCollide(false)
        end
    end

    emitter:Finish()
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
end
