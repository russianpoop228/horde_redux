if SERVER then return end

HORDE.Purism_DiseaseActive = HORDE.Purism_DiseaseActive or false

local HEARTBEAT_PATH = "player/heartbeat1.wav"
local HEARTBEAT_MAX_DUR = 1.0
local heartbeat_csound = nil
local heartbeat_stop_token = 0

local MB_ADD_ALPHA  = 0.2 * 0.75
local MB_DRAW_ALPHA = 0.40
local MB_DELAY      = 0.025

local function StopHeartbeat()
    local ply = LocalPlayer()
    if IsValid(ply) then
        ply:StopSound(HEARTBEAT_PATH)
    end
    if heartbeat_csound then
        heartbeat_csound:Stop()
        heartbeat_csound = nil
    end
    heartbeat_stop_token = heartbeat_stop_token + 1
end

local function PlayHeartbeat()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    if not HORDE.Purism_DiseaseActive then return end

    StopHeartbeat()

    heartbeat_csound = CreateSound(ply, HEARTBEAT_PATH)
    if heartbeat_csound then
        heartbeat_csound:SetSoundLevel(0)
        heartbeat_csound:Play()
    else
        ply:EmitSound(HEARTBEAT_PATH, 75, 100, 1, CHAN_STATIC)
    end

    local token = heartbeat_stop_token
    timer.Simple(HEARTBEAT_MAX_DUR, function()
        if token ~= heartbeat_stop_token then return end
        if heartbeat_csound then
            heartbeat_csound:Stop()
            heartbeat_csound = nil
        end
        if IsValid(ply) then
            ply:StopSound(HEARTBEAT_PATH)
        end
    end)
end

net.Receive("Horde_Purism_DiseaseState", function()
    local active = net.ReadBool()
    HORDE.Purism_DiseaseActive = active
    if not active then
        StopHeartbeat()
    end
end)

net.Receive("Horde_Purism_DiseaseTick", function()
    if not HORDE.Purism_DiseaseActive then return end
    PlayHeartbeat()
end)

hook.Add("Think", "Horde_Purism_DiseaseStopSoundDead", function()
    if not HORDE.Purism_DiseaseActive then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then
        HORDE.Purism_DiseaseActive = false
        StopHeartbeat()
    end
end)

local GREEN_MODIFY = {
    ["$pp_colour_addr"] = 0,
    ["$pp_colour_addg"] = 0.06,
    ["$pp_colour_addb"] = 0,
    ["$pp_colour_brightness"] = -0.04,
    ["$pp_colour_contrast"] = 1.0,
    ["$pp_colour_colour"] = 0.75,
    ["$pp_colour_mulr"] = 0,
    ["$pp_colour_mulg"] = 0.08,
    ["$pp_colour_mulb"] = 0,
}

hook.Add("RenderScreenspaceEffects", "Horde_Purism_DiseaseScreen", function()
    if not HORDE.Purism_DiseaseActive then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    DrawColorModify(GREEN_MODIFY)

    DrawMotionBlur(MB_ADD_ALPHA, MB_DRAW_ALPHA, MB_DELAY)
end)

print("[Horde PURISM] cl_purism_mode.lua loaded")
