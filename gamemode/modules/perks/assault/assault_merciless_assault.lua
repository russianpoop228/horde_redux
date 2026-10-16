PERK.PrintName = "Merciless Assault"
PERK.Description = "{1} chance to add 1 Adrenaline stack on headshot.\nAdds {2} maximum Adrenaline stacks."
PERK.Icon = "materials/perks/merciless_assault.png"
PERK.Params = {
    [1] = {value = 0.25, percent = true},
    [2] = {value = 2},
}

PERK.Hooks = {}

PERK.AdrenalineStackBonus = 2

PERK.Hooks.ScaleNPCDamage = function(npc, hitgroup, dmginfo)
    local attacker = dmginfo:GetAttacker()
    if not attacker:IsValid() or not attacker:IsPlayer() then return end
    if not attacker:Horde_GetPerk("assault_merciless_assault")  then return end
    if hitgroup == HITGROUP_HEAD then
        local p = math.random()
        if p <= 0.25 then
            attacker:Horde_AddAdrenalineStack()
        end
    end
end
