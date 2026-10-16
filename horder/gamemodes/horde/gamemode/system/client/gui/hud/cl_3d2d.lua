surface.CreateFont("Icon", { font = "arial", size = 64 })
surface.CreateFont("Rank", { font = "arial", size = 32 })

net.Receive("Horde_OnEnemyDebuffRemove", function ()
    local ent = net.ReadEntity()
    local debuffs = net.ReadTable()
    ent.Horde_Debuffs = debuffs
end)

local holdout_mat = Material("status/hold.png")
local hold_zones = {}

net.Receive("Horde_SyncHoldLocation", function ()
    local zone_id = net.ReadUInt(4)
    local holdoutzone_pos = net.ReadVector()
    local holdoutzone_ang = net.ReadAngle()
    local obbmins = net.ReadVector()
    local obbmaxs = net.ReadVector()
    local shape = net.ReadUInt(1)
    local radius = net.ReadFloat()
    local indicator_pos

    local tr = util.TraceLine({
        start = holdoutzone_pos,
        endpos = holdoutzone_pos + Vector(0,0,-1) * 1000,
        mask = MASK_NPCWORLDSTATIC
    })

    if tr.Hit then
        indicator_pos = tr.HitPos + Vector(0,0,75)
    else
        indicator_pos = holdoutzone_pos
    end

    local prev = hold_zones[zone_id]
    hold_zones[zone_id] = {
        IndicatorPos = indicator_pos,
        Pos = holdoutzone_pos,
        Ang = holdoutzone_ang,
        OBBMins = obbmins,
        OBBMaxs = obbmaxs,
        Shape = shape,
        Radius = radius,
        Progress = prev and prev.Progress or 0,
    }
    hook.Run("Horde_HoldZoneAdded", zone_id)
end)

net.Receive("Horde_SyncHoldEnd", function ()
    local zone_id = net.ReadUInt(4)
    hold_zones[zone_id] = nil
    hook.Run("Horde_HoldZoneRemoved", zone_id)
end)

net.Receive("Horde_SyncHoldProgress", function ()
    local zone_id = net.ReadUInt(4)
    local progress = net.ReadUInt(8)
    local zone = hold_zones[zone_id]
    if not zone then return end
    zone.Progress = progress
    hook.Run("Horde_HoldZoneProgress", zone_id, progress)
end)

local obj_mat = Material("status/objective.png")
local payloads = {}
local payload_destinations = {}

net.Receive("Horde_SyncPayloadEnd", function ()
    payloads = {}
    payload_destinations = {}
end)

net.Receive("Horde_SyncPayloadSpawnEnd", function ()
    local spawn_id = net.ReadUInt(4)
    payloads[spawn_id] = nil
end)

net.Receive("Horde_SyncPayloadLocation", function ()
    local id = net.ReadUInt(4)
    if not payloads[id] then
        payloads[id] = {}
    end
    payloads[id].Pos = net.ReadVector()
    if not payloads[id].Icon then
        payloads[id].Icon = Material(HORDE.Payload_Icon[0])
    end
end)

net.Receive("Horde_SyncPayloadDestinationLocation", function ()
    local id = net.ReadUInt(4)
    local pos = net.ReadVector()
    local obbmins = net.ReadVector()
    local obbmaxs = net.ReadVector()
    local indicator_pos

    local tr = util.TraceLine({
        start = pos,
        endpos = pos + Vector(0,0,-1) * 1000,
        mask = MASK_NPCWORLDSTATIC
    })

    if tr.Hit then
        indicator_pos = tr.HitPos + Vector(0,0,75)
    else
        indicator_pos = pos
    end

    payload_destinations[id] = {IndicatorPos = indicator_pos, Pos = pos, OBBMins = obbmins, OBBMaxs = obbmaxs, Progress = 0}
end)

net.Receive("Horde_SyncPayloadIcon", function ()
    local id = net.ReadUInt(4)
    local mat = net.ReadUInt(4)
    payloads[id].Icon = Material(HORDE.Payload_Icon[mat])
end)

local escape_mat = Material("status/escape.png")
local escape_zones = {}
net.Receive("Horde_SyncEscapeLocation", function ()
    local zone_id = net.ReadUInt(4)
    local pos = net.ReadVector()
    local obbmins = net.ReadVector()
    local obbmaxs = net.ReadVector()
    local indicator_pos

    local tr = util.TraceLine({
        start = pos,
        endpos = pos + Vector(0,0,-1) * 500,
        mask = MASK_NPCWORLDSTATIC
    })

    if tr.Hit then
        indicator_pos = tr.HitPos + Vector(0,0,75)
    else
        indicator_pos = pos
    end

    escape_zones[zone_id] = {IndicatorPos = indicator_pos, Pos = pos, OBBMins = obbmins, OBBMaxs = obbmaxs, Progress = 0}
end)

net.Receive("Horde_SyncEscapeEnd", function ()
    escape_zones = {}
end)

local buy_zones = {}
local buy_zones_shop_open = false
net.Receive("Horde_SyncBuyZones", function ()
    buy_zones_shop_open = net.ReadBool()
    local count = net.ReadUInt(4)
    buy_zones = {}
    for i = 1, count do
        buy_zones[i] = net.ReadVector()
    end
end)

local ZONE_EDGE = Color(0, 255, 0)

local function DrawZoneBox(pos, ang, mins, maxs)
    if not pos or not mins or not maxs then return end
    cam.IgnoreZ(true)
    render.SetColorMaterial()
    render.DrawWireframeBox(pos, ang or Angle(0, 0, 0), mins, maxs, ZONE_EDGE)
    cam.IgnoreZ(false)
end

local CYLINDER_SEGMENTS = 24
local function DrawZoneCylinder(pos, ang, mins, maxs, radius)
    if not pos or not mins or not maxs or not radius then return end
    ang = ang or Angle(0, 0, 0)
    cam.IgnoreZ(true)
    render.SetColorMaterial()
    local center_local = Vector(0, 0, (mins.z + maxs.z) * 0.5)
    local center = LocalToWorld(center_local, Angle(0, 0, 0), pos, ang)
    local half_h = math.max(0, maxs.z - mins.z) * 0.5
    local prev_bottom, prev_top
    for i = 0, CYLINDER_SEGMENTS do
       local a = (i / CYLINDER_SEGMENTS) * math.pi * 2
       local point = Vector(math.cos(a) * radius, math.sin(a) * radius, 0)
       local bottom = LocalToWorld(center_local + point - Vector(0, 0, half_h), Angle(0, 0, 0), pos, ang)
       local top = LocalToWorld(center_local + point + Vector(0, 0, half_h), Angle(0, 0, 0), pos, ang)
       if prev_bottom then
           render.DrawLine(prev_bottom, bottom, ZONE_EDGE)
           render.DrawLine(prev_top, top, ZONE_EDGE)
           if i % 6 == 0 then render.DrawLine(bottom, top, ZONE_EDGE) end
       end
       prev_bottom, prev_top = bottom, top
    end
    cam.IgnoreZ(false)
end

local function DrawHoldZone(param)
    if not param then return end
    local ang = param.Ang or Angle(0, 0, 0)
    if param.Shape == HORDE.ZONE_SHAPE_CYLINDER then
       DrawZoneCylinder(param.Pos, ang, param.OBBMins, param.OBBMaxs, param.Radius)
    else
       DrawZoneBox(param.Pos, ang, param.OBBMins, param.OBBMaxs)
    end
end

local shop_mat = Material("status/canbuy.png", "mips smooth")
local star = Material("star.png", "mips smooth")
local function Render(bdepth, bskybox)
    if bskybox then return end

    for _, ply in pairs(player.GetAll()) do
        if not IsValid(ply) or (ply == MySelf) or (not ply:Alive()) then
            goto cont
        end

        local attachment_id = ply:LookupAttachment("anim_attachment_head") or 0
        local attachment = ply:GetAttachment(attachment_id)

        local base_pos = Vector()

        if attachment and attachment.Pos then
            base_pos = attachment.Pos
        else
            base_pos = (ply:LocalToWorld(ply:OBBCenter()) + ply:GetUp() * 24)
        end

        local render_pos = base_pos + ply:GetUp() * 15

        local render_mindist = 500
        local render_maxdist = render_mindist + 80

        local dist = (render_pos - EyePos()):Length()
        local dist_clamped = math.Clamp(dist, render_mindist, render_maxdist)
        local dist_alpha = math.Remap(dist_clamped, render_mindist, render_maxdist, 200, 0)

        if dist_alpha == 0 then goto cont end

        local fade_white = Color(255, 255, 255, dist_alpha)

        local render_ang = EyeAngles()
        render_ang:RotateAroundAxis(render_ang:Right(),90)
        render_ang:RotateAroundAxis(-render_ang:Up(),90)

        local subclass_name = ply:Horde_GetCurrentSubclass()
        if not subclass_name then goto cont end
        local subclass = HORDE.subclasses[subclass_name]
        if not subclass then subclass = HORDE.subclasses["Survivor"] end
        local mat = Material(subclass.Icon, "mips smooth")
        local loc_class = translate.Get("Class_" .. subclass.PrintName) or subclass.PrintName
        local len = string.len(loc_class) * 6
        local rank = ply:Horde_GetRank(subclass.PrintName) or HORDE.Rank_Novice
        local rank_level = ply:Horde_GetRankLevel(subclass.PrintName)
        local loc_rank = "[" .. translate.Get("Rank_" .. rank) .. "]"

        cam.Start3D2D(render_pos, render_ang, 0.1)
            surface.SetMaterial(mat)
            surface.SetDrawColor(HORDE.Rank_Colors[rank])
            local pos = - 64 - len - 20
            surface.DrawTexturedRect(pos, -64 / 2, 64, 64)

            if rank == HORDE.Rank_Master then
                draw.SimpleText(rank_level, "Trebuchet24", pos - 5, -32 + 15, HORDE.Rank_Colors[rank], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(loc_class, "Icon", len + 8, 0, HORDE.Rank_Colors[rank], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                if rank_level > 0 then
                    surface.SetMaterial(star)
                    local y_pos = 15
                    for i = 0, rank_level - 1 do
                        surface.DrawTexturedRect(pos - 10, y_pos, 10, 10)
                        y_pos = y_pos - 7
                    end
                end
                draw.SimpleText(loc_class, "Icon", len + 8, 0, fade_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            draw.SimpleText(loc_rank, "Rank", 0, -54, HORDE.Rank_Colors[rank], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        cam.End3D2D()
        ::cont::
    end

    if HORDE.Player_Looking_At_Minion then
        local npc = HORDE.Player_Looking_At_Minion
        if not npc:IsValid() or npc:Health() <= 0 then goto minion_end end
        local base_pos = Vector()
        base_pos = (npc:LocalToWorld(npc:OBBCenter()) + npc:GetUp() * 24)

        local render_pos = base_pos

        local render_mindist = 800
        local render_maxdist = render_mindist + 80

        local dist = (render_pos - EyePos()):Length()
        local dist_clamped = math.Clamp(dist, render_mindist, render_maxdist)
        local dist_alpha = math.Remap(dist_clamped, render_mindist, render_maxdist, 200, 0)

        if dist_alpha == 0 then goto minion_end end

        local render_ang = EyeAngles()
        render_ang:RotateAroundAxis(render_ang:Right(),90)
        render_ang:RotateAroundAxis(-render_ang:Up(),90)

        cam.IgnoreZ(true)
        cam.Start3D2D(render_pos, render_ang, 0.35)
            draw.SimpleTextOutlined(tostring(npc:Health()) .. "/" .. tostring(npc:GetMaxHealth()), "DermaDefault", 0, 0, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
            local ammo_cur = npc:GetNWInt("Horde_AmmoCurrent", -1)
            local ammo_max = npc:GetNWInt("Horde_AmmoMax", -1)
            if ammo_cur >= 0 and ammo_max > 0 then
                local ammo_col = Color(255, 220, 80)
                if ammo_cur <= 0 then
                    ammo_col = Color(255, 80, 80)
                elseif ammo_cur / ammo_max < 0.25 then
                    ammo_col = Color(255, 160, 60)
                end
                draw.SimpleTextOutlined(tostring(ammo_cur) .. "/" .. tostring(ammo_max) .. " ammo", "DermaDefault", 0, 16, ammo_col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
            end
        cam.End3D2D()
        cam.IgnoreZ(false)
        ::minion_end::
    end

    if not table.IsEmpty(hold_zones) then
        local render_ang = EyeAngles()
        render_ang:RotateAroundAxis(render_ang:Right(),90)
        render_ang:RotateAroundAxis(-render_ang:Up(),90)

        for id, param in pairs(hold_zones) do
            cam.IgnoreZ(true)
            cam.Start3D2D(param.IndicatorPos, render_ang, 0.35)
                surface.SetMaterial(holdout_mat)
                surface.SetDrawColor(Color(0, 255, 0))
                surface.DrawTexturedRect(-32, 0, 64, 64)

                if hold_zones[id].Progress > 0 then
                    draw.RoundedBox(0, -100, 70, 200, 10, HORDE.color_hollow)
                    draw.RoundedBox(0, -100, 70, hold_zones[id].Progress * 2, 10, Color(0, 255, 0))
                    draw.SimpleText("Hold Progress", "Trebuchet18", 0, 95, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 5)
                end
            cam.End3D2D()
            cam.IgnoreZ(false)

            DrawHoldZone(param)
        end
    end

    if not table.IsEmpty(payloads) and not table.IsEmpty(payload_destinations) then
        local render_ang = EyeAngles()
        render_ang:RotateAroundAxis(render_ang:Right(),90)
        render_ang:RotateAroundAxis(-render_ang:Up(),90)

        for id, param in pairs(payloads) do
            cam.IgnoreZ(true)
            cam.Start3D2D(param.Pos, render_ang, 0.35)
                surface.SetMaterial(param.Icon)
                surface.SetDrawColor(Color(255, 255, 255))
                surface.DrawTexturedRect(-32, 0, 64, 64)

                draw.SimpleText("Collect", "Trebuchet18", 0, 80, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 5)
            cam.End3D2D()
            cam.IgnoreZ(false)
        end

        for id, param in pairs(payload_destinations) do
            cam.IgnoreZ(true)
            cam.Start3D2D(param.IndicatorPos, render_ang, 0.35)
                surface.SetMaterial(obj_mat)
                surface.SetDrawColor(Color(0, 255, 0))
                surface.DrawTexturedRect(-32, 0, 64, 64)

                draw.SimpleText("Deliver", "Trebuchet18", 0, 80, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 5)
            cam.End3D2D()
            cam.IgnoreZ(false)

            DrawZoneBox(param.Pos, Angle(0,0,0), param.OBBMins, param.OBBMaxs)
        end
    end

    if not table.IsEmpty(escape_zones) then
        local render_ang = EyeAngles()
        render_ang:RotateAroundAxis(render_ang:Right(),90)
        render_ang:RotateAroundAxis(-render_ang:Up(),90)

        for id, param in pairs(escape_zones) do
            cam.IgnoreZ(true)
            cam.Start3D2D(param.IndicatorPos, render_ang, 0.35)
                surface.SetMaterial(escape_mat)
                surface.SetDrawColor(Color(0, 255, 0))
                surface.DrawTexturedRect(-32, 0, 64, 64)

                draw.SimpleText("Escape", "Trebuchet18", 0, 80, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 5)
            cam.End3D2D()
            cam.IgnoreZ(false)

            DrawZoneBox(param.Pos, Angle(0,0,0), param.OBBMins, param.OBBMaxs)
        end
    end

    if buy_zones_shop_open and not table.IsEmpty(buy_zones) then
        local render_ang = EyeAngles()
        render_ang:RotateAroundAxis(render_ang:Right(), 90)
        render_ang:RotateAroundAxis(-render_ang:Up(), 90)

        local label = (translate and translate.Get and translate.Get("Shop_UI_Shop")) or "Shop"

        for _, pos in ipairs(buy_zones) do
            cam.IgnoreZ(true)
            cam.Start3D2D(pos, render_ang, 0.35)
                surface.SetMaterial(shop_mat)
                surface.SetDrawColor(color_white)
                surface.DrawTexturedRect(-32, -32, 64, 64)
                draw.SimpleText(label, "Trebuchet18", 0, 42, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 5)
            cam.End3D2D()
            cam.IgnoreZ(false)
        end
    end
end

if GetConVar("horde_enable_3d2d_icon"):GetInt() == 1 then
    hook.Add("PostDrawTranslucentRenderables", "Horde_RenderClassIcon", Render)

end
