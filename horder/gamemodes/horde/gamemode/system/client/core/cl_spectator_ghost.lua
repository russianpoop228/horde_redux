if SERVER then return end

local GHOST_MAT = Material("sprites/blueflare1")
local GHOST_COLOR = Color(140, 190, 255, 255)
local GHOST_SIZE = 32
local INTERVAL = 0.1
local STALE = 0.5

local ghosts = {}

net.Receive("Horde_SpectatorGhosts", function()
    local now = RealTime()
    local seen = {}
    for _ = 1, net.ReadUInt(8) do
        local idx = net.ReadUInt(8)
        local pos = net.ReadVector()
        seen[idx] = true
        local g = ghosts[idx]
        if not g then
            ghosts[idx] = { prev = pos, cur = pos, t = now }
        else
            g.prev = g.prev and LerpVector(math.Clamp((now - g.t) / INTERVAL, 0, 1), g.prev, g.cur) or pos
            g.cur = pos
            g.t = now
        end
    end
    for idx in pairs(ghosts) do
        if not seen[idx] then ghosts[idx] = nil end
    end
end)

hook.Add("PostDrawTranslucentRenderables", "Horde_SpectatorGhost", function(depth, skybox)
    if skybox or next(ghosts) == nil then return end
    if not IsValid(MySelf) then return end
    if not GHOST_MAT or GHOST_MAT:IsError() then return end

    local now = RealTime()
    local my_idx = MySelf:EntIndex()

    render.SuppressEngineLighting(true)
    render.OverrideBlend(true,
        BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD,
        BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD)
    render.SetMaterial(GHOST_MAT)

    for idx, g in pairs(ghosts) do
        if idx ~= my_idx and now - g.t < STALE then
            local pos = LerpVector(math.Clamp((now - g.t) / INTERVAL, 0, 1), g.prev, g.cur)
            render.DrawSprite(pos, GHOST_SIZE, GHOST_SIZE, GHOST_COLOR)
        end
    end

    render.OverrideBlend(false)
    render.SuppressEngineLighting(false)
end)
