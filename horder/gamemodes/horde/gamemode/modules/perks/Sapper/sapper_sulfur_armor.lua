PERK.PrintName = "Sulfur Armor"
PERK.Description = [[If you take non-blast damage while wearing armor, 
it detonates, dealing damage equal to your armor value.
{1} increased Blast damage. Regenerates 1 armor per second (up to 30%)]]
PERK.Icon = "materials/perks/sapper/reactive_armor.png"
PERK.Params = {
     [1] = {value = 0.15, percent = true},
     [2] = {value = 0.75, percent = true}
}

PERK.Hooks = {}

PERK.Hooks.Horde_OnSetPerk = function(ply)
    if not SERVER then return end
    if not ply:Horde_GetPerk("sapper_sulfur_armor") then return end

    local tname = "ArmorRegen_" .. ply:SteamID()
    timer.Remove(tname)

    timer.Create(tname, 1, 0, function()
        if not IsValid(ply) then
            timer.Remove(tname)
            return
        end

        if not ply:Alive() then return end

        if ply:Armor() >= 30 then
            return
        end

        ply:SetArmor(math.min(ply:Armor() + 1, 30))
    end)
end

PERK.Hooks.Horde_OnPlayerDamageTaken = function (ply, dmginfo, bonus)
    if HORDE:IsBlastDamage(dmginfo) then return end
    if not ply:Horde_GetPerk("sapper_sulfur_armor") then return end
    if dmginfo:GetDamage() > 0 and ply:Armor() > 0 then
        local pos = ply:GetPos()
        timer.Simple(0.45, function()
            if !IsValid(ply) then return end
            local d = DamageInfo()
            d:SetAttacker(ply)
            d:SetInflictor(ply)
            d:SetDamageType(DMG_BLAST)
            d:SetDamage(ply:Armor())
            util.BlastDamageInfo(d, pos, 256)
            local e = EffectData()
                e:SetNormal(Vector(0,0,1))
                e:SetOrigin(pos)
                e:SetRadius(math.min(256, 512))
            util.Effect("seismic_wave", e, true, true)
        end)
    end
end

PERK.OwnerHooks.Horde_OnPlayerDamage = function (ply, npc, bonus, hitgroup, dmginfo)
    if not ply:Horde_GetPerk("sapper_sulfur_armor") then return end
    if HORDE:IsBlastDamage(dmginfo) then
        bonus.increase = bonus.increase + 0.15
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if not SERVER then return end
    if perk ~= "sapper_sulfur_armor" then return end

    local tname = "ArmorRegen_" .. ply:SteamID()
    timer.Remove(tname)
end
