PERK.PrintName = "Warden Base"
PERK.Description = [[
The Warden is a support class that uses aura effects and structures to buff teammates.
Complexity: MEDIUM

{1} increased Warden Aura radius. ({2} per level, up to {3}).

Players near you are affected by Warden Aura.
Warden Aura blocks {4} damage.

Shift+E while looking at one of your own Watchtowers packs it up
(remaining Lifetime/Charges % preserved) and lets you place it again
elsewhere — instantly, with no cooldown.]]
PERK.Params = {
    [1] = {percent = true, level = 0.01, max = 0.25, classname = HORDE.Class_Warden},
    [2] = {value = 0.01, percent = true},
    [3] = {value = 0.25, percent = true},
    [4] = {value = 2}
}

PERK.Hooks = {}
PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if SERVER and perk == "warden_base" then
        timer.Simple(0.1, function()
            ply:Horde_AddWardenAura()
        end)
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "warden_base" then
        ply:Horde_RemoveWardenAura()
    end
end

PERK.Hooks.Horde_PrecomputePerkLevelBonus = function (ply)
    if SERVER then
        ply:Horde_SetPerkLevelBonus("warden_base", 1 + math.min(0.25, 0.01 * ply:Horde_GetLevel(HORDE.Class_Warden)))
    end
end

PERK.OwnerHooks.DoPlayerDeath = function (ply)
    if not ply:Horde_GetPerk("warden_base") then return end
    if not HORDE.player_drop_entities[ply:SteamID()] then return end
    for _, ent in pairs(HORDE.player_drop_entities[ply:SteamID()])  do
        if HORDE:IsWatchTower(ent) then
            ent:Horde_RemoveWardenAura()
        end
    end

    if ply.Horde_Extra_Watchtower and ply.Horde_Extra_Watchtower:IsValid() then
        ply.Horde_Extra_Watchtower:Horde_RemoveWardenAura()
    end
end

PERK.OwnerHooks.Horde_UseActivePerk = function(ply)
    if not ply:Horde_GetPerk("warden_base") then return end

    local tr = util.TraceLine(util.GetPlayerTrace(ply))
    local ent = tr.Entity

    if not IsValid(ent) or ent:IsWorld() then return end
    if ent:GetPos():DistToSqr(ply:GetPos()) > (500 * 500) then return end
    if not HORDE:IsMinionOf(ent, ply) then return end

    local class = ent:GetClass()
    if not HORDE:Horde_IsWardenBuildable(class) then return end

    local wpn = ply:GetWeapon("horde_wardenstaff")
    if not IsValid(wpn) then return end
    if wpn:GetReadytoBuild() then return end

    local consumable_ratio = ent.Horde_GetConsumableRatio and ent:Horde_GetConsumableRatio() or 1

    ent:Remove()

    ply:SelectWeapon("horde_wardenstaff")
    wpn:Horde_StartPlacement(class, { ConsumableRatio = consumable_ratio })

    sound.Play("weapons/physcannon/physcannon_pickup.wav", ply:GetPos())
    HORDE:SendNotification("Watchtower packed up — aim and click to place it again.", 0, ply)

    ply:Horde_SetSpamPerkCooldown(CurTime() + 0.2)

    return true
end
