if CLIENT then return end

function HORDE:Wave666_GrantExp(ply, amount)
    if not IsValid(ply) or not amount or amount <= 0 then return end
    local class_name = ply:Horde_GetCurrentSubclass()
    if not class_name then return end

    local level = ply:Horde_GetLevel(class_name)
    local exp = ply:Horde_GetExp(class_name) + amount
    while level < HORDE.max_level do
        local needed = HORDE:GetExpToNextLevel(level + 1)
        if exp < needed then break end
        exp = exp - needed
        level = level + 1
        ply:Horde_SetLevel(class_name, level)
    end
    ply:Horde_SetExp(class_name, exp)
end

function HORDE:Wave666_KillQuota(player_count)
    local count = math.max(1, tonumber(player_count) or 1)
    return (HORDE.wave666_kills_base or 1024) + (HORDE.wave666_kills_per_player or 256) * (count - 1)
end

function HORDE:Wave666_PrepMetalAmount(ply, default_amount)
    if not IsValid(ply) or not HORDE:Wave666_IsPrep() then return default_amount end
    HORDE.wave666_metal_granted = HORDE.wave666_metal_granted or {}
    local sid = ply:SteamID()
    if HORDE.wave666_metal_granted[sid] then return default_amount end
    HORDE.wave666_metal_granted[sid] = true
    return HORDE.wave666_engineer_metal or 10000
end

function HORDE:Wave666_MaxPlayerUpgrades(ply)
    if not IsValid(ply) or not HORDE.wave666_mode then return end
    if not HORDE.MaxAllUpgrades then return end
    HORDE:MaxAllUpgrades(ply)
end

hook.Add("Horde_OnPlayerSelectClass", "Horde_Wave666_MaxUpgrades", function(ply)
    HORDE:Wave666_MaxPlayerUpgrades(ply)
end)

HORDE.wave666_prep_paid = HORDE.wave666_prep_paid or {}
HORDE.wave666_prep_left = HORDE.wave666_prep_left or {}

function HORDE:Wave666_IsPrep()
    if not HORDE.wave666_mode then return false end
    if (HORDE.current_wave or 0) >= 1 then return false end
    if not HORDE.start_game then return true end
    return (HORDE.current_break_time or 0) > 0
end

function HORDE:Wave666_PrepBonus()
    if not HORDE:Wave666_IsPrep() then return 0 end
    return (HORDE.wave666_money_per_player or 0) * math.max(1, player.GetCount())
end

function HORDE:Wave666_Reconcile(skip)
    local per = HORDE.wave666_money_per_player or 0
    local count = math.max(1, player.GetCount())
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() and ply ~= skip then
            local sid = ply:SteamID()
            local paid = HORDE.wave666_prep_paid[sid]
            if paid and paid ~= count then
                local delta = per * (count - paid)
                HORDE.wave666_prep_paid[sid] = count
                if delta ~= 0 then
                    ply:Horde_SetMoney(math.max(0, (ply:Horde_GetMoney() or 0) + delta))
                    ply:Horde_SyncEconomy()
                end
            end
        end
    end
end

function HORDE:Wave666_OnPrepInit(ply, restored_money)
    if not IsValid(ply) or not HORDE:Wave666_IsPrep() then return end
    local sid = ply:SteamID()
    if restored_money then
        HORDE.wave666_prep_paid[sid] = HORDE.wave666_prep_left[sid] or 0
        HORDE.wave666_prep_left[sid] = nil
        HORDE:Wave666_Reconcile()
    else
        HORDE.wave666_prep_paid[sid] = math.max(1, player.GetCount())
        HORDE:Wave666_Reconcile(ply)
    end
end

hook.Add("PlayerDisconnected", "Horde_Wave666_PrepLeave", function(ply)
    if not IsValid(ply) or not HORDE.wave666_mode then return end
    local sid = ply:SteamID()
    local counted = HORDE.wave666_prep_paid[sid]
    HORDE.wave666_prep_paid[sid] = nil
    if not HORDE:Wave666_IsPrep() then return end
    HORDE.wave666_prep_left[sid] = counted
    if not counted then return end
    HORDE:Wave666_Reconcile(ply)
end)

hook.Add("HordeWaveStart", "Horde_Wave666_MaxUpgrade", function()
    if not HORDE.wave666_mode then return end
    for _, ply in ipairs(player.GetAll()) do
        HORDE:Wave666_MaxPlayerUpgrades(ply)
    end
end)

hook.Add("HordeWaveStart", "Horde_Wave666_Announce", function()
    if not HORDE.wave666_mode then return end
    timer.Simple(1, function()
        if not HORDE.wave666_mode then return end
        HORDE:SendNotification(string.format(
            "WAVE 666: Good luck!",
            HORDE.wave666_kill_quota or HORDE:Wave666_KillQuota(player.GetCount())
        ), 0)
    end)
end)

print("[Horde WAVE 666] sv_wave666_mode.lua loaded")
