PERK.PrintName = "Displacer"
PERK.Description = [[
Shift+E while looking at one of your own constructions packs it up
(health and ammo % preserved) and lets you place it again elsewhere.
{1} second cooldown.]]
PERK.Params = {
    [1] = {value = 5},
}
PERK.Icon = "materials/perks/displacer.png"

PERK.Hooks = {}
PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if SERVER and perk == "engineer_displacer" then
        ply:Horde_SetPerkCooldown(5)

        ply:Horde_SyncStatus(HORDE.Status_Displacer, 1)
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "engineer_displacer" then
        ply:Horde_SyncStatus(HORDE.Status_Displacer, 0)
    end
end

PERK.OwnerHooks.Horde_UseActivePerk = function(ply)
    if not ply:Horde_GetPerk("engineer_displacer") then return end

    local tr = util.TraceLine(util.GetPlayerTrace(ply))
    local ent = tr.Entity

    if not IsValid(ent) or ent:IsWorld() then return true end
    if ent:GetPos():DistToSqr(ply:GetPos()) > (500 * 500) then return true end
    if not HORDE:IsMinionOf(ent, ply) then return true end

    local class = ent:GetClass()
    if not HORDE:Horde_IsBuildable(class) then return true end

    local wpn = ply:GetWeapon("horde_engiwrench")
    if not IsValid(wpn) then return true end

    local hp_ratio = ent:Health() / math.max(1, ent:GetMaxHealth())
    local ammo_ratio = nil
    if HORDE:Horde_IsAmmoTrackedBuildable(class) then
        local ammo_max = ent:GetNWInt("Horde_AmmoMax", 0)
        if ammo_max > 0 then
            ammo_ratio = ent:GetNWInt("Horde_AmmoCurrent", 0) / ammo_max
        end
    end

    ent.Horde_Minion_Respawn = nil
    timer.Remove("Horde_ManhackRespawn" .. ent:GetCreationID())
    ent:Remove()

    ply:SelectWeapon("horde_engiwrench")
    wpn:Horde_StartPlacement(class, { HealthRatio = hp_ratio, AmmoRatio = ammo_ratio })

    sound.Play("weapons/physcannon/physcannon_pickup.wav", ply:GetPos())
    HORDE:SendNotification("Construction packed up — aim and click to place it again.", 0, ply)
end
