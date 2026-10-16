if not SERVER then return end

local MAX_AMOUNT = 1000000000

local function Transfer(ply, kind, amount)
    local trace = ply:GetEyeTrace()
    local target = trace.Entity

    if not IsValid(target) or not target:IsPlayer() then
        HORDE:SendNotification("Player not found!", 1, ply)
        return
    end
    if target == ply then
        HORDE:SendNotification("You cannot send to yourself!", 1, ply)
        return
    end

    if kind == "money" then
        if HORDE.budget_mode then
            HORDE:SendNotification("Money is shared in Budget mode. Transfers are disabled.", 1, ply)
            return
        end
        if (ply:Horde_GetMoney() or 0) < amount then
            HORDE:SendNotification("Not enough money!", 1, ply)
            return
        end
        ply:Horde_AddMoney(-amount)
        target:Horde_AddMoney(amount)
        ply:Horde_SyncEconomy()
        target:Horde_SyncEconomy()
        HORDE:SendNotification(string.format("Sent %d money to %s", amount, target:Nick()), 0, ply)
        HORDE:SendNotification(string.format("Received %d money from %s", amount, ply:Nick()), 0, target)
        return
    end

    if (ply:Horde_GetSkullTokens() or 0) < amount then
        HORDE:SendNotification("Not enough skull tokens!", 1, ply)
        return
    end
    ply:Horde_AddSkullTokens(-amount)
    target:Horde_AddSkullTokens(amount)
    ply:Horde_SyncEconomy()
    target:Horde_SyncEconomy()
    HORDE:SendNotification(string.format("Sent %d skulls to %s", amount, target:Nick()), 0, ply)
    HORDE:SendNotification(string.format("Received %d skulls from %s", amount, ply:Nick()), 0, target)
end

hook.Add("PlayerSay", "Horde_SendCommand", function(ply, text)
    if not IsValid(ply) then return end

    local args = {}
    for word in string.gmatch(string.lower(text or ""), "%S+") do
        args[#args + 1] = word
    end

    if args[1] ~= "!hsend" and args[1] ~= "!send" then return end

    local amount = math.floor(tonumber(args[3]) or 0)
    if amount ~= amount or amount <= 0 or amount > MAX_AMOUNT then
        HORDE:SendNotification("Invalid amount!", 1, ply)
        return ""
    end

    local kind = tostring(args[2] or "")
    if kind == "m" or kind == "money" then
        Transfer(ply, "money", amount)
    elseif kind == "s" or kind == "skull" or kind == "skulls" then
        Transfer(ply, "skull", amount)
    else
        HORDE:SendNotification("Usage: !hsend <m/s> <amount>", 1, ply)
    end

    return ""
end)
