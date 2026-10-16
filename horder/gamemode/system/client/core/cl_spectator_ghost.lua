if SERVER then return end

local GHOST_MAT = Material("sprites/blueflare1")
local GHOST_COLOR = Color(140, 190, 255, 255)
local GHOST_SIZE = 32

local SMOOTH_SPEED  = 20
local SNAP_DIST_SQR = 160 * 160

local ghostPos = {}
local lastGhostFrame = RealTime()

hook.Add("PostDrawTranslucentRenderables", "Horde_SpectatorGhost", function(depth, skybox)
    if skybox then return end
    if not IsValid(MySelf) then return end
    if not GHOST_MAT or GHOST_MAT:IsError() then return end

    local now = RealTime()
    local dt = math.Clamp(now - lastGhostFrame, 0, 0.1)
    lastGhostFrame = now
    local t = 1 - math.exp(-SMOOTH_SPEED * dt)

    render.SuppressEngineLighting(true)
    render.OverrideBlend(true,
        BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD,
        BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD)

    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then
            ghostPos[ply] = nil
            continue
        end
        if ply:Alive() or ply == MySelf then
            ghostPos[ply] = nil
            continue
        end

        local target = ply:EyePos()
        if not target or target:IsZero() then
            target = ply:GetPos() + Vector(0, 0, 36)
        end

        local cur = ghostPos[ply]
        if not cur or cur:DistToSqr(target) > SNAP_DIST_SQR then
            cur = target
        elseif t > 0 then
            cur = LerpVector(t, cur, target)
        end
        ghostPos[ply] = cur

        render.SetMaterial(GHOST_MAT)
        render.DrawSprite(cur, GHOST_SIZE, GHOST_SIZE, GHOST_COLOR)
    end

    render.OverrideBlend(false)
    render.SuppressEngineLighting(false)
end)

hook.Add("EntityRemoved", "Horde_SpectatorGhostCleanup", function(ent)
    ghostPos[ent] = nil
end)
