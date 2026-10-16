if not CLIENT then return end

HORDE = HORDE or {}
local SW = HORDE.SpecialWaves
if not SW then return end

local function CreateFonts()
    surface.CreateFont("Horde_SW_Title", {
        font = "Roboto Bold", size = ScreenScale(15), weight = 900, extended = true,
    })
    surface.CreateFont("Horde_SW_Sub", {
        font = "Roboto", size = ScreenScale(9), weight = 400, extended = true,
    })
end
CreateFonts()
hook.Add("OnScreenSizeChanged", "Horde_SpecialWaves_Fonts", CreateFonts)

local waveData  = nil
local bannerPnl = nil
local shownWave = nil

HORDE.specialwaves_presets = HORDE.specialwaves_presets or {}
HORDE.specialwaves_version = HORDE.specialwaves_version or 0

local function ShowBanner(data)
    if IsValid(bannerPnl) then bannerPnl:Remove() end

    local col = (istable(data.color) and Color(data.color.r, data.color.g, data.color.b))
        or Color(SW.DEFAULT_BANNER.r, SW.DEFAULT_BANNER.g, SW.DEFAULT_BANNER.b)

    if IsValid(HORDE.WaveNotifPanel) then
        HORDE.WaveNotifPanel:Remove()
    end
    HORDE.WaveNotifPanel = nil

    local h       = ScreenScale(52)
    local yAnchor = ScrH() / 4

    local pnl = vgui.Create("DPanel")
    pnl:SetSize(ScrW(), 0)
    pnl:SetPos(0, yAnchor)
    pnl:SetAlpha(0)
    bannerPnl = pnl

    local title = "✦  " .. string.upper(data.name or "SPECIAL WAVE") .. "  ✦"
    local sub   = (isstring(data.enemies) and data.enemies ~= "") and ("[ " .. data.enemies .. " ]") or ""

    pnl.Paint = function(_, w, hh)
        surface.SetDrawColor(15, 15, 15, 220)
        surface.DrawRect(0, 0, w, hh)
        surface.SetDrawColor(col)
        surface.DrawRect(0, 2, w, 2)
        surface.DrawRect(0, hh - 4, w, 2)
        draw.SimpleText(title, "Horde_SW_Title", w / 2, hh * 0.36, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if sub ~= "" then
            draw.SimpleText(sub, "Horde_SW_Sub", w / 2, hh * 0.72, Color(210, 210, 210), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    local animIn = Derma_Anim("Linear", pnl, function(p, _, delta)
        p:SetTall(h * delta)
        p:SetPos(0, yAnchor - h / 2 * delta)
        p:SetAlpha(delta * 255)
    end)
    pnl.Think = function() if animIn:Active() then animIn:Run() end end
    animIn:Start(0.4)
    if animIn:Active() then animIn:Run() end

    timer.Simple(5, function()
        if not IsValid(pnl) then return end
        local animOut = Derma_Anim("Linear", pnl, function(p, _, delta)
            p:SetTall(h * (1 - delta))
            p:SetPos(0, yAnchor - h / 2 + h / 2 * delta)
            p:SetAlpha(255 - delta * 255)
        end)
        animOut:Start(0.4)
        if animOut:Active() then animOut:Run() end
        pnl.Think = function() if animOut:Active() then animOut:Run() end end
        timer.Simple(0.45, function()
            if IsValid(pnl) then pnl:Remove() end
            if bannerPnl == pnl then bannerPnl = nil end
        end)
    end)
end

net.Receive("Horde_SpecialWave", function()
    local t = net.ReadTable()
    if not istable(t) then return end
    waveData  = { name = t.name, enemies = t.enemies or "", color = t.color }
    shownWave = HORDE.current_wave
    if not IsValid(bannerPnl) then ShowBanner(waveData) end
end)

net.Receive("Horde_SpecialWaveNormal", function()
    waveData  = nil
    shownWave = nil
end)

net.Receive("Horde_SyncSpecialWaves", function()
    local t = net.ReadTable()
    if not istable(t) then return end
    HORDE.specialwaves_presets = SW.SanitizeList(t.presets)
    HORDE.specialwaves_version = (HORDE.specialwaves_version or 0) + 1
    hook.Run("Horde_SpecialWavesConfigSynced")
end)

net.Receive("Horde_ToggleSpecialWaves", function()
    if HORDE.ToggleSpecialWavesConfig then HORDE:ToggleSpecialWavesConfig() end
end)

hook.Add("Horde_OverrideWaveNotification", "Horde_SpecialWaves_Banner", function(wave)
    if not waveData then return nil end
    if shownWave == wave then return true end
    shownWave = wave
    if not IsValid(bannerPnl) then ShowBanner(waveData) end
    return true
end)
