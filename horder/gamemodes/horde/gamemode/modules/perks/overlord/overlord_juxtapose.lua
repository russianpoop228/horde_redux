PERK.PrintName = "Juxtapose"
PERK.Description = [[Dark Energy Blast Perk skill is replaced with Summon Projection Clone.
Summons a Projection Clone with {1} health that uses a pump shotgun.
Projection Clone lasts for {2} seconds and has a {3} second cooldown.]]
PERK.Icon = "materials/perks/overlord/juxtapose.png"
PERK.Params = {
    [1] = { value = 125 },
    [2] = { value = 22.5 },
    [3] = { value = 30 },
}
PERK.Hooks = {}

PERK.FearStackBonus = 1
PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if SERVER and perk == "overlord_juxtapose" then
        ply:Horde_SetPerkCooldown(30)
        ply:Horde_SetPerkInternalCooldown(0)

        net.Start("Horde_SyncActivePerk")
            net.WriteUInt(HORDE.Status_DarkEnergyBlast, 8)
            net.WriteUInt(0, 3)
        net.Send(ply)

        net.Start("Horde_SyncActivePerk")
            net.WriteUInt(HORDE.Status_Juxtapose, 8)
            net.WriteUInt(1, 3)
        net.Send(ply)

        net.Start("Horde_PerkStartCooldown")
            net.WriteUInt(ply:Horde_GetPerkInternalCooldown(), 8)
        net.Send(ply)

    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "overlord_juxtapose" then
        net.Start("Horde_SyncActivePerk")
        net.WriteUInt(HORDE.Status_Juxtapose, 8)
        net.WriteUInt(0, 3)
        net.Send(ply)

        if IsValid(ply.Horde_overlord_juxtapose) then
            ply.Horde_overlord_juxtapose:Remove()
        end
    end
end
PERK.Hooks.Horde_UseActivePerk = function(ply)
    if not SERVER then return end
    if not ply:Horde_GetPerk("overlord_juxtapose") then return end
    if IsValid(ply.Horde_overlord_juxtapose) then return true end

    sound.Play("horde/player/overlord/projection.mp3", ply:GetPos(), 100, math.random(80, 120))

    local perk = HORDE.perks and HORDE.perks["overlord_juxtapose"]
    local lifetime = (perk and perk.Params and perk.Params[2] and perk.Params[2].value) or 22.5
    local cooldown = (perk and perk.Params and perk.Params[3] and perk.Params[3].value) or 30

    ply.Horde_overlord_juxtapose = ents.Create("npc_vj_horde_overlord_projection")
    ply.Horde_overlord_juxtapose:SetPos(ply:GetPos() + ply:GetRight() * 45 + ply:GetForward() * 45 + Vector(0, 0, 20))
    ply.Horde_overlord_juxtapose:SetAngles(ply:GetAngles())
    ply.Horde_overlord_juxtapose.Horde_Projection_Lifetime = lifetime
    HORDE:RegisterMinion(ply.Horde_overlord_juxtapose, ply, { count = false, drop_entity = false, no_collision = false })
    ply.Horde_overlord_juxtapose:Spawn()

    ply:Horde_SetPerkCooldown(cooldown)
end
