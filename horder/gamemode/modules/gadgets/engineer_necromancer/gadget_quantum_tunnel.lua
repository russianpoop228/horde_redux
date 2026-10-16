GADGET.PrintName = "Quantum Tunnel"
GADGET.Description = [[Shift+E teleports you to the construction or minion you are aiming at.
Works through walls — while equipped, your own constructions and minions are highlighted through walls.]]
GADGET.Icon = "items/gadgets/quantum_tunnel.png"
GADGET.Duration = 0
GADGET.Cooldown = 10
GADGET.Params = {
}
GADGET.Active = true
GADGET.Hooks = {}

local MAX_DIST = 6000
local MIN_COS  = 0.85

local function FindAimedOwnUnit(ply)
    local origin = ply:GetShootPos()
    local dir    = ply:GetAimVector()
    local best, best_cos = nil, MIN_COS
    for _, ent in ipairs(HORDE:GetPlayerMinions(ply)) do
        if IsValid(ent) and ent ~= ply then
            local to = ent:WorldSpaceCenter() - origin
            local dist = to:Length()
            if dist > 1 and dist <= MAX_DIST then
                local cosang = to:Dot(dir) / dist
                if cosang > best_cos then
                    best, best_cos = ent, cosang
                end
            end
        end
    end
    return best
end

GADGET.Hooks.Horde_UseActiveGadget = function (ply)
    if CLIENT then return end
    if ply:Horde_GetGadget() ~= "gadget_quantum_tunnel" then return end

    local target = FindAimedOwnUnit(ply)
    if not IsValid(target) then return true end

    local pos = target:GetPos()
    local away = ply:GetPos() - pos
    away.z = 0
    if away:LengthSqr() < 1 then away = Vector(1, 0, 0) else away:Normalize() end
    local dest = pos + away * 48 + vector_up * 16

    util.ParticleTracerEx("vortigaunt_beam", pos + vector_up * 32, dest, true, ply:EntIndex(), -1)
    ply:SetPos(dest)
    ply:SetLocalVelocity(Vector(0, 0, 0))
    sound.Play("weapons/physcannon/physcannon_drop.wav", ply:GetPos())
end

if CLIENT then
    local cached = {}
    local next_scan = 0
    hook.Add("PreDrawHalos", "Horde_QuantumTunnelHalos", function()
        if GetConVarNumber("horde_enable_halo") == 0 then return end
        if not IsValid(MySelf) or MySelf:Horde_GetGadget() ~= "gadget_quantum_tunnel" then return end

        local t = CurTime()
        if t >= next_scan then
            next_scan = t + 0.25
            cached = {}
            for _, ent in ipairs(ents.GetAll()) do
                if IsValid(ent) and HORDE:IsMinionOf(ent, MySelf) then
                    cached[#cached + 1] = ent
                end
            end
        end
        if #cached == 0 then return end

        local list = {}
        for _, ent in ipairs(cached) do
            if IsValid(ent) then list[#list + 1] = ent end
        end
        if #list > 0 then
            halo.Add(list, Color(0, 200, 255), 2, 2, 1, true, true)
        end
    end)
end
