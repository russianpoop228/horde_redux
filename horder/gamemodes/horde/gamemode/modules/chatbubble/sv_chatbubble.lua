if not SERVER then return end

util.AddNetworkString("ChatBubble_Add")

hook.Add("PlayerSay", "Horde_ChatBubbles", function(ply, text)
    if not IsValid(ply) or text == "" then return end
    local first = text:sub(1, 1)
    if first == "!" or first == "/" then return end

    net.Start("ChatBubble_Add")
        net.WriteEntity(ply)
        net.WriteString(text)
    net.Broadcast()
end)
