util.AddNetworkString("contextual_ping_all_location_sv")
util.AddNetworkString("contextual_ping_all_entity_sv")
util.AddNetworkString("contextual_ping_all_location_cl")
util.AddNetworkString("contextual_ping_all_entity_cl")

util.AddNetworkString("contextual_ping_team_location_sv")
util.AddNetworkString("contextual_ping_team_entity_sv")
util.AddNetworkString("contextual_ping_team_location_cl")
util.AddNetworkString("contextual_ping_team_entity_cl")

util.AddNetworkString("contextual_ping_entity_ragdoll_cl")

local function IsTraitor(ply)
    if engine.ActiveGamemode() ~= "terrortown" then return false end
    if ROLE_TRAITOR == nil or not isfunction(ply.GetRole) then return false end
    return ply:GetRole() == ROLE_TRAITOR
end

function GetEntityDescription(ent)
    if not IsValid(ent) then return "Something" end

    local description

    if ent:IsPlayer() then
        description = ent:Nick()
    elseif ent:IsWeapon() then
        description = "a Weapon"
    elseif ent:IsRagdoll() then
        if engine.ActiveGamemode() == "terrortown" then
            if CORPSE.GetFound(ent, false) then
                description = "the body of " .. CORPSE.GetPlayerNick(ent, "a Terrorist")
            else
                description = "an unidentified Body"
            end
        else
            description = "a Ragdoll"
        end
    elseif ent:IsNPC() then
        description = "an NPC"
    elseif ent:IsNextBot() then
        description = ent:GetName()
    else
        description = "Something"
    end
    return description
end

net.Receive("contextual_ping_all_location_sv", function(len, ply)
    if not IsValid(ply) then return end
    if not HORDE:AllowNetRequest(ply, "contextual_ping", 0.2) then return end
    local vec = net.ReadVector()

    ply:Say("Pinged at a Location")
    net.Start("contextual_ping_all_location_cl")
        net.WriteVector(vec)
        net.WriteEntity(ply)
    net.Broadcast()
end)

net.Receive("contextual_ping_all_entity_sv", function(len, ply)
    if not IsValid(ply) then return end
    if not HORDE:AllowNetRequest(ply, "contextual_ping", 0.2) then return end
    local ent = net.ReadEntity()

    local sayTxt = "Pinged at " .. GetEntityDescription(ent)
    ply:Say(sayTxt)
    net.Start("contextual_ping_all_entity_cl")
        net.WriteEntity(ent)
        net.WriteEntity(ply)
    net.Broadcast()
end)

net.Receive("contextual_ping_team_location_sv", function(len, ply)
    if not IsValid(ply) then return end
    if not HORDE:AllowNetRequest(ply, "contextual_ping", 0.2) then return end
    local vec = net.ReadVector()
    local recipients = player.GetHumans()
    local traitors = {}

    if IsTraitor(ply) then
        for k, v in pairs(recipients) do
            if v:GetRole() == ROLE_TRAITOR then
                table.insert(traitors, v)
            end
        end

        ply:Say("Pinged at a Location", true)
        net.Start("contextual_ping_team_location_cl")
            net.WriteVector(vec)
            net.WriteEntity(ply)
        net.Send(traitors)
    else
        ply:Say("Pinged at a Location")
        net.Start("contextual_ping_all_location_cl")
            net.WriteVector(vec)
            net.WriteEntity(ply)
        net.Broadcast()
    end
end)

net.Receive("contextual_ping_team_entity_sv", function(len, ply)
    if not IsValid(ply) then return end
    if not HORDE:AllowNetRequest(ply, "contextual_ping", 0.2) then return end
    local ent = net.ReadEntity()
    local recipients = player.GetHumans()
    local traitors = {}

    if IsTraitor(ply) then
        for k, v in pairs(recipients) do
            if v:GetRole() == ROLE_TRAITOR then
                table.insert(traitors, v)
            end
        end

        local sayTxt = "Pinged at " .. GetEntityDescription(ent)
        ply:Say(sayTxt, true)

        net.Start("contextual_ping_team_entity_cl")
            net.WriteEntity(ent)
            net.WriteEntity(ply)
        net.Send(traitors)
    else
        local sayTxt = "Pinged at " .. GetEntityDescription(ent)
        ply:Say(sayTxt)

        net.Start("contextual_ping_all_entity_cl")
            net.WriteEntity(ent)
            net.WriteEntity(ply)
        net.Broadcast()
    end
end)

hook.Add("CreateEntityRagdoll", "ContextualPingEntityRagdoll", function(ent, ragdoll)
    net.Start("contextual_ping_entity_ragdoll_cl")
        net.WriteEntity(ent)
        net.WriteEntity(ragdoll)
    net.Broadcast()
end)

if engine.ActiveGamemode() == "terrortown" then
    hook.Add("TTTOnCorpseCreated", "ContextualPingEntityRagdoll", function(corpse, ply)
        local id = corpse:EntIndex()

        net.Start("contextual_ping_entity_ragdoll_cl")
            net.WriteEntity(ply)
            net.WriteUInt(id, 13)
        net.Broadcast()
    end)
end
