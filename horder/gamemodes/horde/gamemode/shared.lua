GM.Name = "Horde: REDUX"
GM.Author = "\"Horde\" Made by Gorlami & \"Horde: REDUX\" Made by SHG"
GM.Email = "N/A"
GM.Website = "N/A"

CreateConVar("horde_enable_sandbox", 0, FCVAR_SERVER_CAN_EXECUTE + FCVAR_REPLICATED, "Enables sandbox/cheat features.")
CreateConVar("horde_enable_player_collision", 0, { FCVAR_SERVER_CAN_EXECUTE, FCVAR_REPLICATED },
    "Enables player collision.")

DeriveGamemode("sandbox")

function GM:Initialize()
    game.AddAmmoType({
        name = "arccw_nade_medic_ubgl"
    })
    game.AddAmmoType({
        name = "horde_arccw_knives"
    })
    game.AddAmmoType({
        name = "horde_mine",
    })
    if SERVER then
        HORDE.NPCS = list.Get("NPC")
    end
end

function GM:PlayerLoadout(ply) return true end

if CLIENT then
    AllowSandbox = false

    net.Receive("Horde_SyncSBox", function()
        AllowSandbox = net.ReadBool()
    end)
end

local function CheckAllowHook(hook_name)
    if AllowSandbox then
        hook.Call(hook_name)
        return true
    else
        return false
    end
end

if SERVER then
    util.AddNetworkString("Horde_SyncSBox")
    net.Start("Horde_SyncSBox")
    local EnableSBox = false
    if (GetConVar("horde_enable_sandbox"):GetInt() == 0) then
        EnableSBox = false
    else
        EnableSBox = true
    end
    net.WriteBool(EnableSBox)
    net.Broadcast()
end

local function CheckAllowFeature()
    if GetConVar("horde_enable_sandbox"):GetBool() then
        return true
    else
        return false
    end
end

hook.Add("SpawnMenuOpen", "Horde_SpawnMenu", CheckAllowFeature)

function GM:ContextMenuOpen() return CheckAllowHook("ContextMenuOpen") end

function GM:PlayerNoClip(ply, desiredState)
    return false
end

function GM:PlayerDeathSound() return true end

function GM:PlayerSpawnVehicle(ply, model, name, table) return CheckAllowFeature() end

function GM:PlayerSpawnSWEP(ply, weapon, info) return CheckAllowFeature() end

function GM:PlayerSpawnSENT(ply, class) return CheckAllowFeature() end

function GM:PlayerSpawnRagdoll(ply, model) return CheckAllowFeature() end

function GM:PlayerSpawnProp(ply, model) return CheckAllowFeature() end

function GM:PlayerSpawnObject(ply, model, skin) return CheckAllowFeature() end

function GM:PlayerSpawnNPC(ply, npc_type, weapon) return CheckAllowFeature() end

function GM:PlayerSpawnEffect(ply, model) return CheckAllowFeature() end

function GM:PlayerGiveSWEP(ply, weapon, swep) return CheckAllowFeature() end

function GM:HUDAmmoPickedUp(item, amount) return CheckAllowFeature() end

CreateConVar("horde_disable_f1", 0, FCVAR_ARCHIVE, "Disables F1 hotkey for stats menu.")

if GetConVar("horde_disable_f1"):GetInt() == 0 then
    function GM:ShowHelp(ply)
        if GetConVar("horde_enable_sandbox"):GetBool() then
            ply:SendLua("hook.Run( 'StartSearch' )")
        end
    end
end

local groups = { "group01", "group03" }
local sex = { "female", "male" }
local nums = { "_01", "_02", "_03", "_04", "_05", "_06" }

function GM:PlayerSetModel(ply)
    local class = ply:Horde_GetClass()
    if class and class.model and class.model ~= nil then
        return ply:Horde_SetClassModel(class)
    end
    return ply:SetModel("models/player/" ..
        table.Random(groups) .. "/" .. table.Random(sex) .. table.Random(nums) .. ".mdl")
end

function GM:ShouldCollide(ent1, ent2)
    if not IsValid(ent1) or not IsValid(ent2) then return true end

    if ent1:GetClass() == "prop_combine_ball" or ent2:GetClass() == "prop_combine_ball" then
        return false
    end

    if ent1:IsPlayer() or ent2:IsPlayer() then
        if GetConVar("horde_enable_player_collision"):GetInt() == 0 and ent1:IsPlayer() and ent2:IsPlayer() then
            return false
        end
        local res = hook.Run("Horde_ShouldCollide", ent1, ent2)
        if res ~= nil then return res end
    elseif (ent1:IsNPC() or ent1:IsNextBot()) and (ent2:IsNPC() or ent2:IsNextBot()) then
        local res = hook.Run("Horde_ShouldCollide", ent1, ent2)
        if res ~= nil then return res end
    end

    return true
end

if SERVER then
    concommand.Add("+horde_utility_spell", function(ply)
        if IsValid(ply) and ply:Horde_GetMaxMind() > 0 then
            ply.Horde_UseSpellUtlity = true
        end
    end)

    concommand.Add("-horde_utility_spell", function(ply)
        if IsValid(ply) then
            ply.Horde_UseSpellUtlity = nil
        end
    end)
end
