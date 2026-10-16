include("shared.lua")

local ROTATE_SPEED = 90
local GLOW_MAT     = Material("sprites/light_glow02_add")
local GLOW_COLOR   = Color(90, 255, 110, 60)
local GLOW_SIZE    = 150
local LIGHT_COLOR  = { r = 40, g = 255, b = 80 }
local LIGHT_SIZE   = 320

function ENT:Draw()
    self:SetAngles(self:GetAngles() + Angle(0, ROTATE_SPEED * FrameTime(), 0))
    self:DrawModel()

    local pos = self:GetPos()

    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        dlight.pos = pos
        dlight.r, dlight.g, dlight.b = LIGHT_COLOR.r, LIGHT_COLOR.g, LIGHT_COLOR.b
        dlight.brightness = 3
        dlight.Decay = 400
        dlight.Size = LIGHT_SIZE
        dlight.DieTime = CurTime() + 1
    end

    render.SetMaterial(GLOW_MAT)
    render.DrawSprite(pos, GLOW_SIZE, GLOW_SIZE, GLOW_COLOR)
end
