local ring_mat = Material("particle/particle_ring_wave_addnofog")

local ring_state = {}

local LOOK_DIST = 400

local function GetRatio(ctype, max, remaining, spawn_time)
    if max <= 0 then return 1 end
    if ctype == "wave_limited" then
        return 1
    end
    return math.Clamp(remaining / max, 0, 1)
end

local function IsLookingAt(ply, ent)
    if not IsValid(ply) or not IsValid(ent) then return false end
    if ent.BeingLookedAtByLocalPlayer and ent:BeingLookedAtByLocalPlayer() then
        return true
    end

    local eye = ply:EyePos()
    local center = ent:WorldSpaceCenter()
    if eye:DistToSqr(center) > LOOK_DIST * LOOK_DIST then return false end

    local tr = ply:GetEyeTrace()
    if IsValid(tr.Entity) and tr.Entity == ent then return true end

    local dir = (center - eye):GetNormalized()
    local aim = ply:GetAimVector()
    if aim:Dot(dir) >= 0.978 then
        return true
    end
    return false
end

hook.Add("HUDPaint", "Horde_WardenConsumableRing", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    for _, ent in ipairs(ents.FindByClass("horde_watchtower*")) do
        if not IsValid(ent) then continue end

        local ctype = ent:GetNWString("Horde_ConsumableType", "")
        if ctype == "" then continue end

        local max = ent:GetNWFloat("Horde_ConsumableMax", 0)
        local remaining = ent:GetNWFloat("Horde_ConsumableRemaining", 0)
        local spawn_time = ent:GetNWFloat("Horde_ConsumableSpawnTime", 0)

        local state = ring_state[ent]
        if not state then
            state = { seen = false, lerp = 0, smooth_ratio = 1 }
            ring_state[ent] = state
        end

        local seen_now = IsLookingAt(ply, ent)
        if state.seen ~= seen_now then
            state.seen = seen_now
            state.lerp = SysTime() + 0.2
        end

        local target_ratio = GetRatio(ctype, max, remaining, spawn_time)
        state.smooth_ratio = Lerp(0.15, state.smooth_ratio, target_ratio)

        if not (state.seen or state.lerp > SysTime()) then continue end

        local ler = math.Clamp((state.lerp - SysTime()) / 0.2, 0, 1)
        if state.seen then ler = 1 - ler end
        if ler <= 0.01 then continue end

        local pos = ent:WorldSpaceCenter():ToScreen()
        if not pos.visible then continue end

        local x, y = math.Round(pos.x), math.Round(pos.y)
        local radius = ler * 40
        local seg = 360
        local per = state.smooth_ratio

        for i = 1, 6 do
            surface.DrawCircle(x, y, radius - 7 + i, Color(0, 0, 0, 192 * ler))
        end

        local cir = {}
        table.insert(cir, { x = x, y = y, u = 0.5, v = 0.5 })
        for i = 0, seg do
            if i > math.ceil(seg * per) then break end
            local a = math.rad((i / seg) * -360 + 180)
            table.insert(cir, {
                x = x + math.sin(a) * radius,
                y = y + math.cos(a) * radius,
                u = math.sin(a) / 2 + 0.5,
                v = math.cos(a) / 2 + 0.5,
            })
        end

        local ring_color
        if per > 0.5 then
            ring_color = Color(90, 200, 120, 255 * ler)
        elseif per > 0.2 then
            ring_color = Color(230, 200, 60, 255 * ler)
        else
            ring_color = Color(230, 60, 60, 255 * ler)
        end

        surface.SetMaterial(ring_mat)
        surface.SetDrawColor(ring_color)
        surface.DrawPoly(cir)

        local label
        if ctype == "damage_charges" then
            label = math.max(0, math.Round(remaining)) .. "/" .. math.max(1, math.Round(max))
        elseif ctype == "lifetime" then
            label = math.max(0, math.Round(remaining)) .. "s"
        else
            label = "WAVE"
        end

        draw.TextShadow({
            text = label,
            pos = { x, y },
            font = "Trebuchet24",
            xalign = TEXT_ALIGN_CENTER,
            yalign = TEXT_ALIGN_CENTER,
            color = Color(ring_color.r, ring_color.g, ring_color.b, ler * 255),
        }, 1, ler * 255)
    end
end)

hook.Add("EntityRemoved", "Horde_WardenConsumableRingCleanup", function(ent)
    ring_state[ent] = nil
end)
