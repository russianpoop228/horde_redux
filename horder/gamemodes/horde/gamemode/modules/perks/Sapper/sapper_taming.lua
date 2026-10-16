PERK.PrintName = "Taming"
PERK.Description = [[Your houndeyes regen their health for {1} each 10 seconds.]]
PERK.Icon = "materials/perks/sapper/taming.png"
local PARAMS = {
     [1] = {value = 0.15, percent = true}
}

PERK.Params = PARAMS

PERK.Hooks = {}

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if SERVER and perk == "sapper_taming" then
        local timerName = "Horde_Sapper_Taming_" .. ply:SteamID()

        timer.Create(timerName, 10, 0, function()
            if not IsValid(ply) then timer.Remove(timerName) return end

            local minions = {}
            for _, ent in ipairs(ents.FindByClass("npc_vj_horde_houndeye*")) do
                local owner = ent:GetNWEntity("HordeOwner")
                if not IsValid(owner) then owner = ent:GetOwner() end
                if owner == ply and not ent.Horde_PocketHoundeye then
                    table.insert(minions, ent)
                end
            end
            if #minions == 0 then return end

            for _, npc in ipairs(minions) do
                if not IsValid(npc) or npc:Health() <= 0 then continue end

                if npc:Health() < npc:GetMaxHealth() then
                    local healPercent = PARAMS[1].value
                    local healAmount = npc:GetMaxHealth() * healPercent

                    npc:SetHealth(math.min(npc:GetMaxHealth(), npc:Health() + healAmount))
                end
            end
        end)
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "sapper_taming" then
        timer.Remove("Horde_Sapper_Taming_" .. ply:SteamID())
    end
end

hook.Add("EntityTakeDamage", "Horde_Sapper_Taming_Protect", function(target, dmginfo)
    if not IsValid(target) or not string.match(target:GetClass(), "npc_vj_horde_houndeye") then return end
    if target.Horde_PocketHoundeye then return end

    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() then return end

    local owner = target:GetNWEntity("HordeOwner")
    if not IsValid(owner) then owner = target:GetOwner() end
    if owner ~= attacker then return end

    if attacker:Horde_GetPerk("sapper_taming") and HORDE:IsBlastDamage(dmginfo) then
        dmginfo:SetDamage(0)
        return true
    end
end)
