hook.Add("Horde_PostEnemyDebuffApply", "Example_Corrosion", function(ent, inflictor, debuff, pos)
    if debuff ~= HORDE.Status_Corrosion then return end

    local id = "Horde_Corrosion" .. ent:EntIndex()
    timer.Create(id, 0.5, 10, function()
        if not IsValid(ent) or ent:Health() <= 0 then timer.Remove(id) return end
        local dmg = DamageInfo()
        dmg:SetAttacker(IsValid(inflictor) and inflictor or ent)
        dmg:SetInflictor(ent)
        dmg:SetDamageType(DMG_ACID)
        dmg:SetDamageCustom(HORDE.DMG_CALCULATED)
        dmg:SetDamagePosition(ent:GetPos())
        dmg:SetDamage(math.Clamp(ent:GetMaxHealth() * 0.01, 2, 20))
        ent:TakeDamageInfo(dmg)
    end)
end)
