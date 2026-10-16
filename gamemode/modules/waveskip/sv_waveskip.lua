if not SERVER then return end

CreateConVar("horde_waveskip_ratio", 0.67, { FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE },
    "Доля игроков, проголосовавших за пропуск волны, при которой волна пропускается (0-1).")
CreateConVar("horde_waveskip_fine", 100, { FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE },
    "Штраф за пропуск волны на игрока: значение умножается на номер пропущенной волны.")

local cv_fine = GetConVar("horde_waveskip_fine")

local SKIP = {
    Votes      = {},
    Processing = false,
}

local function CleanupEscapeZones()
    local zones = HORDE.horde_active_escapezones
    if not zones then return end

    for _, zone in pairs(zones) do
        if IsValid(zone) then
            zone.Horde_Activated = nil
            net.Start("Horde_SyncEscapeEnd")
            net.Broadcast()
        end
    end
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then ply:Horde_SetEscape(0) end
    end
    HORDE.horde_active_escapezones = nil
end

local function ApplySkipFine()
    local wave = math.max(0, tonumber(HORDE.current_wave) or 0)
    local fine = math.max(0, math.floor(cv_fine:GetFloat())) * wave
    if fine <= 0 then return end

    if HORDE.budget_mode and HORDE.Budget_AddToBank then
        HORDE:Budget_AddToBank(-fine)
    else
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) then
                local money = ply:Horde_GetMoney() or 0
                ply:Horde_AddMoney(-math.min(fine, money))
                ply:Horde_SyncEconomy()
            end
        end
    end

    HORDE:SendNotification(string.format("Wave skip penalty: -$%d.", fine), 1)
end

local function SkipCurrentWave()
    if SKIP.Processing then return end
    SKIP.Processing = true

    HORDE.waveskip_active = true

    ApplySkipFine()

    if HORDE.ForceCompleteObjectives then HORDE:ForceCompleteObjectives() end
    CleanupEscapeZones()

    HORDE:WaveEnd()
    hook.Run("HordeWaveEnd", HORDE.current_wave)

    HORDE.spawned_enemies          = {}
    HORDE.spawned_enemies_count    = {}
    HORDE.alive_enemies_this_wave  = 0
    HORDE.total_enemies_this_wave  = 0
    HORDE.killed_enemies_this_wave = 0

    HORDE.waveskip_active = nil
    SKIP.Votes = {}
    SKIP.Processing = false
end

hook.Add("PlayerSay", "Horde_WaveSkipCommand", function(ply, text)
    if not IsValid(ply) then return end
    local command = string.lower(string.Trim(text or ""))
    if command ~= "!waveskip" and command ~= "!hskip" then return end

    if HORDE:InBreak() then
        HORDE:SkipTraderTime(ply)
        return ""
    end

    if HORDE.current_wave <= 0 then
        HORDE:SendNotification("You can only skip a wave while it's active.", 1, ply)
        return ""
    end

    if IsValid(HORDE.horde_boss) or HORDE.horde_boss_name then
        HORDE:SendNotification("Boss waves cannot be skipped.", 1, ply)
        return ""
    end

    local steamid = ply:SteamID()
    if SKIP.Votes[steamid] then
        HORDE:SendNotification("You have already voted to skip this wave.", 1, ply)
        return ""
    end
    SKIP.Votes[steamid] = true

    local total, votes = 0, 0
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) then
            total = total + 1
            if SKIP.Votes[p:SteamID()] then votes = votes + 1 end
        end
    end

    local ratio = math.Clamp(GetConVar("horde_waveskip_ratio"):GetFloat(), 0.01, 1)
    local required = math.max(1, math.ceil(total * ratio))

    HORDE:SendNotification(
        string.format("%s wants to skip the wave. (%d/%d)", ply:Name(), votes, required), 0)

    if votes >= required then
        HORDE:SendNotification("Wave skipped!", 0)
        SkipCurrentWave()
    end

    return ""
end)

hook.Add("HordeWaveStart", "Horde_WaveSkipResetOnWaveStart", function()
    SKIP.Votes = {}
    SKIP.Processing = false
end)
