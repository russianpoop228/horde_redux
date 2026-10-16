MUTATION.PrintName   = "Giant"
MUTATION.Description = "25% larger, 50% more health."
MUTATION.NoRand      = false

MUTATION.Hooks = {}

MUTATION.Hooks.Horde_OnSetMutation = function(ent, mutation)
    if mutation ~= "giant" or not SERVER then return end
    ent:SetModelScale(ent:GetModelScale() * 1.25, 0)
    ent:SetMaxHealth(ent:GetMaxHealth() * 1.5)
    ent:SetHealth(ent:Health() * 1.5)
end

MUTATION.Hooks.Horde_OnUnsetMutation = function(ent, mutation)
    if mutation ~= "giant" or not SERVER or not IsValid(ent) then return end
    ent:SetModelScale(ent:GetModelScale() / 1.25, 0)
end
