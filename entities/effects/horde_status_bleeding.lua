function EFFECT:Init(effect_data)
    local pos = effect_data:GetOrigin()
    local radius = effect_data:GetRadius()
    if not radius or radius <= 0 then radius = 50 end

    local emitter = ParticleEmitter(pos)
    if not IsValid(emitter) then return end

    local smoke = emitter:Add("effects/blood_puff", pos)
    if not smoke then
        emitter:Finish()
        return
    end

    smoke:SetGravity(Vector(0, 0, -200))
    smoke:SetDieTime(math.Rand(0.5, 1))
    smoke:SetStartAlpha(255)
    smoke:SetEndAlpha(0)
    smoke:SetStartSize(10)
    smoke:SetEndSize(radius)
    smoke:SetRoll(math.Rand(-180, 180))
    smoke:SetRollDelta(math.Rand(-0.2, 0.2))
    smoke:SetColor(100, 0, 0)
    smoke:SetPos(pos)
    smoke:SetLighting(false)
    smoke:SetCollide(true)
    smoke:SetBounce(0)
    emitter:Finish()
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
end
