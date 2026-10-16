PERK.PrintName = "Mutation"
PERK.Description = [[Your houndeyes have {1} chance to explode when they'll die.
Applies shield to houndeyes that blocks first hit no matter what.]]
PERK.Icon = "materials/perks/sapper/mutation.png"
PERK.Params = {
    [1] = {value = 0.33, percent = true}
}

PERK.Hooks = {}

hook.Add("EntityTakeDamage", "Sapper_Mutation_Shield", function(target, dmginfo)
    if not IsValid(target) then return end
    local cls = target:GetClass()
    if cls ~= "npc_vj_horde_houndeye" and cls ~= "npc_vj_horde_houndeye_champion" then return end
    if target.Horde_PocketHoundeye then return end
    if not target.Sapper_MutationShield then return end
    if dmginfo:GetDamage() <= 0 then return end

    target.Sapper_MutationShield = nil
    target:SetNWBool("Sapper_ShieldActive", false)
    dmginfo:SetDamage(0)

    local effectdata = EffectData()
    effectdata:SetOrigin(target:GetPos() + target:OBBCenter())
    util.Effect("antimatter_explosion", effectdata)

    target:EmitSound("weapons/physcannon/energy_disintegrate" .. math.random(4, 5) .. ".wav", 75, 150)

    return true
end)
