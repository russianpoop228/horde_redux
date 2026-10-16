function EFFECT:Init(data)
    local radius = data:GetRadius()
    local pos = data:GetOrigin()
	local redcolor = data:GetColor()

    local emitter = ParticleEmitter(pos, true)
    emitter:SetNearClip(24, 32)

    local normal = Vector(0,0,1)
    local ringstart = pos + normal * 10
    local particle
    for i=1, 2 do
		particle = emitter:Add("effects/select_ring", ringstart)
		particle:SetDieTime(0.35 + (i*0.45) * 0.1)
		particle:SetColor(redcolor, 50, 50)
		particle:SetStartAlpha(255)
		particle:SetEndAlpha(0)
		particle:SetStartSize(4 * (radius * 0.6))
		particle:SetEndSize(radius * 0.5)
		particle:SetAngles(normal:Angle())
    end

    emitter:Finish()
end

function EFFECT:Think()
return false
end

function EFFECT:Render()
end
