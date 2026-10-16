if SERVER then
    AddCSLuaFile()
    AddCSLuaFile("sh_soul_rebooter_config.lua")
end

include("sh_soul_rebooter_config.lua")

if SERVER then
    util.AddNetworkString("Horde_SoulRebooterSWEP_OpenMenu")
    util.AddNetworkString("Horde_SoulRebooterSWEP_Confirm")
    util.AddNetworkString("Horde_SoulRebooterSWEP_Close")

    local WEAPON_CLASS = "weapon_soul_rebooter"

    local function SoulRebooterNotify(ply, key, fallback, isErr)
        if not IsValid(ply) then return end
        local msg = fallback
        if translate and translate.ClientGet then
            local ok, value = pcall(translate.ClientGet, ply, key)
            if ok and isstring(value) and value ~= "" and value ~= key then
                msg = value
            end
        end
        if HORDE and HORDE.SendNotification then
            HORDE:SendNotification(msg, isErr and 1 or 0, ply)
        end
    end

    local function PatchSoulRebooterAmmoBox()
        local stored = scripted_ents.GetStored("horde_ammobox")
        local entTable = stored and stored.t
        if not entTable or not entTable.StartTouch then return false end
        if entTable._SoulRebooterAmmoBoxPatched then return true end

        local originalStartTouch = entTable.StartTouch
        entTable.StartTouch = function(self, entity)
            if not IsValid(entity) or not entity:IsPlayer() then
                return originalStartTouch(self, entity)
            end

            local wpn = entity:GetWeapon(WEAPON_CLASS)
            if not IsValid(wpn) then
                return originalStartTouch(self, entity)
            end

            local oldPrimary = wpn.Primary
            if istable(oldPrimary) then
                wpn.Primary = table.Copy(oldPrimary)
                wpn.Primary.MaxAmmo = entity:GetAmmoCount(wpn:GetPrimaryAmmoType())
            end

            local ok, err = pcall(originalStartTouch, self, entity)
            wpn.Primary = oldPrimary

            if not ok then
                ErrorNoHalt("[Soul Rebooter] horde_ammobox compatibility error: " .. tostring(err) .. "\n")
            end
        end

        entTable._SoulRebooterAmmoBoxPatched = true
        return true
    end

    hook.Add("InitPostEntity", "Horde_SoulRebooter_PatchAmmoBox", function()
        timer.Simple(0, PatchSoulRebooterAmmoBox)
        timer.Simple(1, PatchSoulRebooterAmmoBox)
    end)
    hook.Add("PostGamemodeLoaded", "Horde_SoulRebooter_PatchAmmoBox", function()
        timer.Simple(0, PatchSoulRebooterAmmoBox)
        timer.Simple(1, PatchSoulRebooterAmmoBox)
    end)

    function HORDE_FindSoulRebooterWeapon(ply)
        if not IsValid(ply) then return nil end

        local stored = ply._SoulRebooterWeapon
        if IsValid(stored) and stored:GetOwner() == ply then
            return stored
        end

        local active = ply:GetActiveWeapon()
        if IsValid(active) and active:GetClass() == WEAPON_CLASS then
            return active
        end

        local wpn = ply:GetWeapon(WEAPON_CLASS)
        if IsValid(wpn) then return wpn end

        for _, wep in ipairs(ply:GetWeapons()) do
            if IsValid(wep) and wep:GetClass() == WEAPON_CLASS then
                return wep
            end
        end

        return nil
    end

    net.Receive("Horde_SoulRebooterSWEP_Confirm", function(len, ply)
        if not IsValid(ply) or not ply:Alive() then return end

        local count = net.ReadUInt(8)
        local target = NULL
        if count >= 1 then
            target = net.ReadEntity()
        end

        net.Start("Horde_SoulRebooterSWEP_Close")
        net.Send(ply)

        if count < 1 then
            SoulRebooterNotify(ply, "SoulRebooter_NoTarget", "No target selected.", true)
            return
        end

        local wpn = HORDE_FindSoulRebooterWeapon(ply)
        if not IsValid(wpn) then
            SoulRebooterNotify(ply, "SoulRebooter_Equip", "Equip Soul Rebooter and try again.", true)
            return
        end

        if wpn.GetPlacing and wpn:GetPlacing() then
            SoulRebooterNotify(ply, "SoulRebooter_AlreadyPlacing", "Already placing a pylon.", true)
            return
        end

        if wpn.EnsureCharges then wpn:EnsureCharges() end
        if wpn:Ammo1() <= 0 then
            SoulRebooterNotify(ply, "SoulRebooter_NoCharges", "No charges left.", true)
            return
        end

        if not IsValid(target)
            or not target:IsPlayer()
            or target:Team() == TEAM_SPECTATOR
            or target == ply
        then
            SoulRebooterNotify(ply, "SoulRebooter_InvalidTarget", "Invalid resurrection target.", true)
            return
        end

        if not wpn.StartPlacement then
            SoulRebooterNotify(ply, "SoulRebooter_InternalError", "Internal error (StartPlacement missing).", true)
            return
        end

        wpn:StartPlacement(target)
    end)
end
