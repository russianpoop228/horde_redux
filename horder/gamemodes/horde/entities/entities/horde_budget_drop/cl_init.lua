include("shared.lua")

local ROTATE_SPEED = 90
local GLOW_MAT     = Material("sprites/light_glow02_add")
local GLOW_COLOR   = Color(90, 255, 110, 60)
local GLOW_SIZE    = 64

function ENT:Draw()
    self:SetAngles(Angle(0, (CurTime() * ROTATE_SPEED) % 360, 0))
    self:DrawModel()
    render.SetMaterial(GLOW_MAT)
    render.DrawSprite(self:GetPos() + Vector(0, 0, 6), GLOW_SIZE, GLOW_SIZE, GLOW_COLOR)
end
