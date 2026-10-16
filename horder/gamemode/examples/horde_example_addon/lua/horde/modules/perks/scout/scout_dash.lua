PERK.PrintName   = "Dash"
PERK.Description = [[
Press Shift+E to dash in the direction you are looking.
Cooldown: {1} seconds.]]
PERK.Icon        = "materials/abilities/quickstep.png"
PERK.Params      = {
    [1] = { value = 8 },
}

if not HORDE:GetStatusID("ScoutDash") then
    HORDE:RegisterStatus({ Name = "ScoutDash", Icon = "materials/abilities/quickstep.png", IsSkill = true })
end

PERK.Hooks = {}

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if SERVER and perk == "scout_dash" then
        ply:Horde_SetPerkCooldown(8)
        net.Start("Horde_SyncActivePerk")
            net.WriteUInt(HORDE.Status_ScoutDash, 8)
            net.WriteUInt(1, 3)
        net.Send(ply)
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "scout_dash" then
        net.Start("Horde_SyncActivePerk")
            net.WriteUInt(HORDE.Status_ScoutDash, 8)
            net.WriteUInt(0, 3)
        net.Send(ply)
    end
end

PERK.OwnerHooks.Horde_UseActivePerk = function(ply)
    if not ply:OnGround() then return true end
    ply:SetVelocity(ply:GetAimVector() * 700 + Vector(0, 0, 150))
    ply:EmitSound("horde/player/quickstep.ogg")
end
