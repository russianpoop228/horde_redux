if not CLIENT then return end

local COLOR_BG       = Color(40, 40, 40, 225)
local COLOR_FILL     = Color(50, 200, 80, 220)
local COLOR_GLOW     = Color(100, 255, 130, 55)
local COLOR_LABEL_SH = Color(0, 0, 0, 170)
local COLOR_LABEL    = Color(255, 255, 255, 255)
local COLOR_PCT      = Color(200, 240, 200, 210)

local BAR_H = 35
local BAR_STEP = BAR_H + 40

local bars = {}
local bar_order = {}

local icon_cache = {}
local function ObjIcon(obj_type)
    local path = HORDE.Objective_Icon and (HORDE.Objective_Icon[obj_type] or HORDE.Objective_Icon[HORDE.OBJECTIVE_PAYLOAD])
    if not path then return nil end
    if icon_cache[path] == nil then
        icon_cache[path] = Material(path, "mips smooth")
    end
    return icon_cache[path]
end

local function SortBars()
    local ids = {}
    for id in pairs(bars) do ids[#ids + 1] = id end
    table.sort(ids)
    bar_order = ids
end

net.Receive("Horde_SyncObjectiveBar", function()
    local mode = net.ReadUInt(2)

    if mode == HORDE.OBJ_BAR_CLEAR then
        for _, bar in pairs(bars) do bar.hiding = true end
        return
    end

    if mode == HORDE.OBJ_BAR_END then
        local bar = bars[net.ReadUInt(4)]
        if bar then bar.hiding = true end
        return
    end

    if mode == HORDE.OBJ_BAR_PROGRESS then
        local bar = bars[net.ReadUInt(4)]
        if bar then bar.target = net.ReadFloat() else net.ReadFloat() end
        return
    end

    local id = net.ReadUInt(4)
    local obj_type = net.ReadUInt(3)
    local arg = net.ReadString()
    local progress = net.ReadFloat()

    local bar = bars[id]
    if not bar then
        bar = { id = id, anim_in = 0, anim_out = 1, hiding = false, displayed = progress }
        bars[id] = bar
        SortBars()
    end
    bar.obj_type, bar.arg = obj_type, arg
    bar.target, bar.displayed = progress, progress
    bar.hiding, bar.anim_out, bar.anim_in = false, 1, 0
end)

local function LabelText(bar)
    local T = function(key, fallback) return translate.Get(key) or fallback end
    if bar.obj_type == HORDE.OBJECTIVE_HOLD then
        if bar.arg == "" then return T("Game_Obj_DefendAll", "Defend All Objectives") end
        return string.format(T("Game_Obj_Defend", "Defend: %s"), bar.arg)
    elseif bar.obj_type == HORDE.OBJECTIVE_PAYLOAD then
        if bar.arg == "" then return T("Game_Obj_DeliverAll", "Deliver All Payloads") end
        return string.format(T("Game_Obj_Deliver", "Deliver: %s"), bar.arg)
    elseif bar.obj_type == HORDE.OBJECTIVE_ESCAPE then
        return T("Game_Obj_Escape", "Escape to Safety!")
    elseif bar.obj_type == HORDE.OBJECTIVE_MIXED then
        if bar.arg == "" then return T("Game_Obj_Mixed", "Objective") end
        return string.format(T("Game_Obj_MixedArg", "Defend and deliver: %s"), bar.arg)
    end
    return T("Game_Obj_Multiple", "Objectives")
end

local function AnimateOut(bar, ft)
    bar.anim_out = math.max(0, bar.anim_out - ft * 2.5)
    if bar.anim_out <= 0 then return true end
    return false
end

local panel = vgui.Create("DPanel")
panel:SetPos(0, 25)
panel.Paint = function(self, w, h)
    if next(bars) == nil or GetConVarNumber("horde_enable_client_gui") == 0 then return end

    local ft = FrameTime()
    local removed = false
    local slot = 0

    for _, id in ipairs(bar_order) do
        local bar = bars[id]
        if bar then
            if bar.hiding then
                if AnimateOut(bar, ft) then
                    bars[id] = nil
                    removed = true
                    continue
                end
            else
                bar.anim_in = math.min(1, bar.anim_in + ft * 3)
            end

            local diff = bar.target - bar.displayed
            if math.abs(diff) > 0.1 then
                local speed = (diff > 0) and 10 or 20
                bar.displayed = bar.displayed + diff * math.min(1, ft * speed)
            else
                bar.displayed = bar.target
            end

            local mul = bar.anim_in * bar.anim_out
            local function AC(col)
                return Color(col.r, col.g, col.b, math.floor(col.a * mul))
            end

            local oy = (1 - mul) * -18 + slot * BAR_STEP
            draw.RoundedBox(10, 0, oy, w, BAR_H, AC(COLOR_BG))

            if bar.displayed > 0.3 then
                local fill = w * bar.displayed / 100
                draw.RoundedBox(10, 0, oy, fill, BAR_H, AC(COLOR_FILL))
                draw.RoundedBox(6, 2, oy + 2, math.max(0, fill - 4), BAR_H * 0.4, AC(COLOR_GLOW))
            end

            local label = LabelText(bar)
            local font = "Info"
            surface.SetFont(font)
            local text_w = surface.GetTextSize(label)
            local icon = ObjIcon(bar.obj_type)
            local icon_size = icon and 14 or 0
            local gap = icon and 6 or 0
            local total_w = text_w + icon_size + gap
            local text_x = w / 2 - total_w / 2 + icon_size + gap
            local label_y = oy + BAR_H + 14

            if icon then
                surface.SetMaterial(icon)
                surface.SetDrawColor(255, 255, 255, math.floor(220 * mul))
                surface.DrawTexturedRect(w / 2 - total_w / 2, label_y - icon_size / 2, icon_size, icon_size)
            end

            draw.SimpleText(label, font, text_x + 1, label_y + 1, AC(COLOR_LABEL_SH), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(label, font, text_x, label_y, AC(COLOR_LABEL), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            local pct = math.floor(bar.target + 0.5) .. "%"
            draw.SimpleText(pct, font, w - 6, oy + BAR_H / 2 + 1, AC(COLOR_LABEL_SH), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            draw.SimpleText(pct, font, w - 6, oy + BAR_H / 2, AC(COLOR_PCT), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

            slot = slot + 1
        end
    end

    if removed then SortBars() end
end

local function Resize()
    local side = ScreenScale(100)
    panel:SetSize(ScrW() - (side + ScreenScale(10)) * 2, ScrH())
    panel:SetPos(ScrW() / 2 - panel:GetWide() / 2, 25)
end

Resize()
hook.Add("OnScreenSizeChanged", "Horde_ObjectiveBar_Resize", Resize)
