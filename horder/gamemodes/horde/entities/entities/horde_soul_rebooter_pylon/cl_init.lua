include("shared.lua")

local CFG = HordeSoulRebooterConfig or {}
local START_TIME = CFG.InitialTimer or 40

local SKELETON_MODEL = "models/player/skeleton.mdl"
local SKELETON_MAT   = "models/props_combine/portalball001_sheet"

local BOB_AMPLITUDE = 1.5
local BOB_SPEED     = 2.5

local SKEL_FEET_ABOVE = 8
local SKEL_HEAD_H     = 72

ENT._Seen = false
ENT._Lerp = 0
ENT._Ler2 = 0

local RingMat = Material("particle/particle_ring_wave_addnofog")

function ENT:Initialize()
    self:CreateDisplayModel()
    self:CreateSkeleton()
end

function ENT:CreateDisplayModel()
    if IsValid(self.SoulDisplayModel) then
        self.SoulDisplayModel:Remove()
        self.SoulDisplayModel = nil
    end

    local mdl = ClientsideModel("models/props_lab/tpplugholder_single.mdl", RENDERGROUP_OPAQUE)
    if not IsValid(mdl) then return end
    mdl:SetNoDraw(true)
    self.SoulDisplayModel = mdl
end

function ENT:CreateSkeleton()
    if IsValid(self.SoulSkeleton) then
        self.SoulSkeleton:Remove()
        self.SoulSkeleton = nil
    end

    local skel = ClientsideModel(SKELETON_MODEL, RENDERGROUP_TRANSLUCENT)
    if not IsValid(skel) then return end

    skel:SetNoDraw(true)
    skel:SetMaterial(SKELETON_MAT)
    skel:SetModelScale(1, 0)
    self.SoulSkeleton = skel
end

function ENT:GetSoulPercent()
    local dieAt = self:GetNWFloat("HordeSoulDieTime", 0)
    if dieAt <= 0 then return 0 end
    local remaining = math.Clamp(dieAt - CurTime(), 0, START_TIME)
    return math.Clamp((START_TIME - remaining) / START_TIME * 100, 0, 100)
end

function ENT:GetSoulTopPoint()
    if not IsValid(self.SoulDisplayModel) then return self:GetPos() end

    local mins, maxs = self.SoulDisplayModel:GetRenderBounds()
    local origin, angles = self.SoulDisplayModel:GetPos(), self.SoulDisplayModel:GetAngles()
    local corners = {}
    for ix = 0, 1 do
        for iy = 0, 1 do
            for iz = 0, 1 do
                local localPoint = Vector(
                    ix == 0 and mins.x or maxs.x,
                    iy == 0 and mins.y or maxs.y,
                    iz == 0 and mins.z or maxs.z
                )
                corners[#corners + 1] = LocalToWorld(localPoint, angle_zero, origin, angles)
            end
        end
    end

    local highestZ = -math.huge
    for _, point in ipairs(corners) do
        highestZ = math.max(highestZ, point.z)
    end

    local top = vector_origin
    local count = 0
    for _, point in ipairs(corners) do
        if math.abs(point.z - highestZ) < 0.01 then
            top = top + point
            count = count + 1
        end
    end
    if count > 0 then top = top / count else top = origin end
    return top + Vector(0, 0, SKEL_FEET_ABOVE)
end

function ENT:BeingLookedAtByLocalPlayer()
    local ply = LocalPlayer()
    if not IsValid(ply) then return false end

    local myPos = IsValid(self.SoulDisplayModel)
        and self.SoulDisplayModel:WorldSpaceCenter()
        or self:GetPos()
    if ply:GetPos():DistToSqr(myPos) > (350 * 350) then
        return false
    end

    local tr = util.TraceLine({
        start  = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * 350,
        filter = ply,
        mask   = MASK_SOLID
    })
    if IsValid(tr.Entity) and tr.Entity == self then
        return true
    end

    local scr = myPos:ToScreen()
    if scr.visible == false then return false end
    local dx = scr.x - ScrW() * 0.5
    local dy = scr.y - ScrH() * 0.5
    return (dx * dx + dy * dy) < (120 * 120)
end

function ENT:Think()
    local looking = self:BeingLookedAtByLocalPlayer()
    if self._Seen ~= looking then
        self._Seen = looking
        self._Lerp = SysTime() + 0.2
    end
    self._Ler2 = Lerp(0.1, self._Ler2, self:GetSoulPercent())
end

function ENT:Draw()
    if not IsValid(self.SoulDisplayModel) then
        self:CreateDisplayModel()
    end
    if IsValid(self.SoulDisplayModel) then
        self.SoulDisplayModel:SetPos(self:GetPos())
        self.SoulDisplayModel:SetAngles(self:GetAngles())
        self.SoulDisplayModel:DrawModel()
    end

    local bob = math.sin(RealTime() * BOB_SPEED) * BOB_AMPLITUDE
    local cycle = (RealTime() * 5) % 360

    local liveCFG = HordeSoulRebooterConfig or {}
    local skeletonOffset = liveCFG.SkeletonOffset or Vector(12, 12, 10)
    local timerOffset = liveCFG.TimerOffset or Vector(12, 12, 128)
    local timerFollowsSkeleton = liveCFG.TimerFollowsSkeleton == true
    local basePos = IsValid(self.SoulDisplayModel)
        and self.SoulDisplayModel:GetPos()
        or self:GetPos()
    local baseAng = IsValid(self.SoulDisplayModel)
        and self.SoulDisplayModel:GetAngles()
        or self:GetAngles()
    local skelPos = LocalToWorld(
        skeletonOffset + Vector(bob, 0, 0),
        angle_zero,
        basePos,
        baseAng
    )
    local overlayPos
    if timerFollowsSkeleton then
        overlayPos = skelPos + Vector(0, 0, SKEL_HEAD_H)
    else
        overlayPos = LocalToWorld(timerOffset, angle_zero, basePos, baseAng)
    end

    if not IsValid(self.SoulSkeleton) then
        self:CreateSkeleton()
    end
    if IsValid(self.SoulSkeleton) then
        self.SoulSkeleton:SetRenderOrigin(skelPos)
        self.SoulSkeleton:SetRenderAngles(Angle(0, cycle, 0))
        self.SoulSkeleton:SetupBones()
        self.SoulSkeleton:DrawModel()
    end

    if not (self._Seen or self._Lerp > SysTime()) then return end

    local ler = math.Clamp((self._Lerp - SysTime()) / 0.2, 0, 1)
    if self._Seen then ler = 1 - ler end

    local scr = overlayPos:ToScreen()
    if scr.visible == false then return end

    local x, y = math.Round(scr.x), math.Round(scr.y)
    local radius = ler * 40
    local seg = 360
    local per = self._Ler2 / 100
    if not isnumber(per) then per = 1 end

    cam.Start2D()
    render.OverrideDepthEnable(true, false)

    for i = 1, 6 do
        surface.DrawCircle(x, y, radius - 7 + i, Color(0, 0, 0, 192 * ler))
    end

    local cir = { { x = x, y = y, u = 0.5, v = 0.5 } }
    for i = 0, seg do
        if i > math.ceil(seg * per) then break end
        local a = math.rad((i / seg) * -360 + 180)
        table.insert(cir, {
            x = x + math.sin(a) * radius,
            y = y + math.cos(a) * radius,
            u = math.sin(a) / 2 + 0.5,
            v = math.cos(a) / 2 + 0.5
        })
    end
    surface.SetMaterial(RingMat)
    surface.SetDrawColor(255, 200, 25, 255 * ler)
    surface.DrawPoly(cir)

    draw.TextShadow({
        text = math.Clamp(math.Round(self._Ler2), 0, 100) .. "%",
        pos = { x, y },
        font = "Trebuchet24",
        xalign = TEXT_ALIGN_CENTER,
        yalign = TEXT_ALIGN_CENTER,
        color = Color(255, 200, 25, ler * 255)
    }, 1, ler * 255)

    draw.TextShadow({
        text = self:GetNWString("HordeSoulTargetName", ""),
        pos = { x, y - ler * 52 },
        font = "TargetID",
        xalign = TEXT_ALIGN_CENTER,
        yalign = TEXT_ALIGN_CENTER,
        color = Color(255, 200, 25, ler * 255)
    }, 1, ler * 255)

    render.OverrideDepthEnable(false)
    cam.End2D()
end

function ENT:OnRemove()
    if IsValid(self.SoulDisplayModel) then
        self.SoulDisplayModel:Remove()
        self.SoulDisplayModel = nil
    end
    if IsValid(self.SoulSkeleton) then
        self.SoulSkeleton:Remove()
        self.SoulSkeleton = nil
    end
end
