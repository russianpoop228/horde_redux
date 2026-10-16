PERK.PrintName = "Fusion"
PERK.Description = [[
Minions regenerate {1} health per second.
{2} increased minion damage while minion is on full health.]]
PERK.Icon = "materials/perks/fusion.png"
PERK.Params = {
    [1] = {value = 0.02, percent = true},
    [2] = {value = 0.15, percent = true},
}

PERK.Hooks = {}
if SERVER then
    timer.Create("Horde_FusionTick", 1, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Horde_GetPerk("engineer_fusion") then
                local refs = HORDE.player_drop_entities and HORDE.player_drop_entities[ply:SteamID()]
                if refs then
                    for _, ent in pairs(refs) do
                        local class = IsValid(ent) and ent:GetClass() or nil
                        local is_placeholder = class == "horde_engiconstruction" or class == "horde_wardenconstruction"
                        if IsValid(ent) and not ent.Horde_IsConstructing and not is_placeholder
                            and ent.GetMaxHealth and ent.Health and ent.SetHealth then
                            if not (ent.Horde_Debuff_Active and ent.Horde_Debuff_Active[HORDE.Status_Decay]) then
                                local max_hp = ent:GetMaxHealth()
                                if max_hp and max_hp > 0 then
                                    local hp = ent:Health()
                                    if hp < max_hp then
                                        ent:SetHealth(math.min(hp + max_hp * 0.02, max_hp))
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

PERK.OwnerHooks.Horde_OnPlayerMinionDamage = function (ply, npc, bonus, dmginfo)
    if ply:Horde_GetPerk("engineer_fusion") and dmginfo:GetInflictor():Health() >= dmginfo:GetInflictor():GetMaxHealth() then
        bonus.increase = bonus.increase + 0.15
    end
end
