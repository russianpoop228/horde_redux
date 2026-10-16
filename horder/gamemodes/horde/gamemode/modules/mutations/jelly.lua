MUTATION.PrintName   = "Jelly"
MUTATION.Description = "90% resistant to bullets above 66% HP, 30% resistant below.\nTakes double damage from all other damage types.\nDoes not apply to bosses."
MUTATION.Wave        = 4

MUTATION.Hooks = {}

MUTATION.Hooks.Horde_OnSetMutation = function(ent, mutation)
    if mutation ~= "jelly" then return end
    if not SERVER then return end
    if not IsValid(ent) then return end
    if ent:GetVar("is_boss") then return end

    ent.Jelly_OriginalMaterial = ent:GetMaterial()
    ent:SetRenderMode(RENDERMODE_TRANSALPHA)
    ent:SetMaterial("models/mutation/slime")
end

MUTATION.Hooks.Horde_OnUnsetMutation = function(ent, mutation)
    if mutation ~= "jelly" then return end
    if not SERVER then return end
    if not IsValid(ent) then return end

    ent:SetRenderMode(RENDERMODE_NORMAL)
    ent:SetMaterial(ent.Jelly_OriginalMaterial or "")
    ent.Jelly_OriginalMaterial = nil
end

MUTATION.Hooks.EntityTakeDamage = function(ent, dmg)
    if not SERVER then return end
    if not IsValid(ent) then return end
    if not ent:IsNPC() then return end
    if not ent:Horde_HasMutation("jelly") then return end

    local maxHP = ent:GetMaxHealth()
    if maxHP <= 0 then return end

    if dmg:IsBulletDamage() then
        local healthRatio = ent:Health() / maxHP
        dmg:ScaleDamage(healthRatio > 0.66 and 0.10 or 0.70)
    else
        dmg:ScaleDamage(2.0)
    end
end
