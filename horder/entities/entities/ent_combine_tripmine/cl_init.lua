include('shared.lua')

ENT.RenderGroup = RENDERGROUP_BOTH

local MAT_LASER = Material("sprites/bluelaser1")
local COL_LASER = Color(0, 255, 255, 200)

function ENT:Initialize()
    self:SetRenderBounds(Vector(-128,-128,-128), Vector(128,128,128))
end

function ENT:Draw()
    self:DrawModel()
end

function ENT:DrawTranslucent()
    if not self:GetDrawLaser() then return end

    local startPos = self:GetPos() + self:GetUp() * 5
    local endPos = self:GetBeamEnd()

    if endPos:IsZero() then return end

    self:SetRenderBoundsWS(startPos, endPos, Vector(16,16,16))

    local texScroll = CurTime() * 10
    render.SetMaterial(MAT_LASER)
    render.DrawBeam(startPos, endPos, 4, texScroll, texScroll + 1, COL_LASER)

    render.SetMaterial(Material("sprites/glow04_noz"))
    render.DrawSprite(endPos, 16, 16, COL_LASER)
end
