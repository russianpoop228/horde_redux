PERK.PrintName = "Symbiosis"
PERK.Description = "Minions have {1} more health on spawn.\n{2} less damage taken for each minion alive (up to {4}).\nMetal regeneration gives {3} of your current Metal per tick."
PERK.Icon = "materials/perks/symbiosis.png"
PERK.Params = {
    [1] = { value = 0.20, percent = true },
    [2] = { value = 0.075, percent = true },
    [3] = { value = 0.04, percent = true },
    [4] = { value = 0.33, percent = true },
}

PERK.Hooks = {}
PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if SERVER and perk == "engineer_symbiosis" then
        if not HORDE.player_drop_entities[ply:SteamID()] then return end
        for id, ent in pairs(HORDE.player_drop_entities[ply:SteamID()]) do
            if ent:IsNPC() and not ent.Horde_Has_Symbiosis then
                ent:SetMaxHealth(ent:GetMaxHealth() * 1.20)
                ent:SetHealth(ent:GetMaxHealth())
                ent.Horde_Has_Symbiosis = true
            end
        end
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "engineer_symbiosis" then
        if not HORDE.player_drop_entities[ply:SteamID()] then return end
        for id, ent in pairs(HORDE.player_drop_entities[ply:SteamID()]) do
            if ent:IsNPC() and ent.Horde_Has_Symbiosis then
                ent:SetMaxHealth(ent:GetMaxHealth() / 1.20)
                ent:SetHealth(ent:GetMaxHealth())
                ent.Horde_Has_Symbiosis = nil
            end
        end
    end
end

PERK.Hooks.OnEntityCreated = function(ent)
    if CLIENT then return end
    if not ent:IsValid() then return end
    timer.Simple(0.1, function()
        if not ent:IsValid() then return end
        local ply = HORDE:GetMinionOwner(ent)
        if IsValid(ply) and ply:Horde_GetPerk("engineer_symbiosis") and ent:IsNPC() and ent.SetMaxHealth and (not ent.Horde_Has_Symbiosis) then
            ent:SetMaxHealth(ent:GetMaxHealth() * 1.20)
            ent:SetHealth(ent:GetMaxHealth())
            ent.Horde_Has_Symbiosis = true
        end
    end)
end

PERK.OwnerHooks.Horde_OnPlayerDamageTaken = function(ply, dmginfo, bonus)
    if not ply:Horde_GetPerk("engineer_symbiosis") then return end
    local resist = 0.075 * ply:Horde_GetMinionCount()
    bonus.resistance = bonus.resistance + math.min(resist, 0.33)
end
