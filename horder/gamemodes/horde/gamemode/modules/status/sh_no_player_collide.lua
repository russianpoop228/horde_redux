local WATCHTOWER_CLASS_PREFIX = "horde_watchtower"

local NO_PLAYER_COLLIDE_CLASSES = {
    ["ent_mine_base"]        = true,
    ["ent_tank_mine"]        = true,
    ["ent_sticky_mine"]      = true,
    ["ent_shock_mine"]       = true,
    ["ent_magma_mine"]       = true,
    ["ent_frosty_mine"]      = true,
    ["ent_super_mine"]       = true,
    ["ent_combine_tripmine"] = true,
    ["ent_trap"]             = true,
}

local function Horde_ShouldIgnorePlayerCollision(ent)
    if not IsValid(ent) then return false end
    local class = ent:GetClass()
    if NO_PLAYER_COLLIDE_CLASSES[class] then return true end
    return string.StartWith(class, WATCHTOWER_CLASS_PREFIX)
end

hook.Add("Horde_ShouldCollide", "Horde_NoPlayerCollide", function(ent1, ent2)
    if not IsValid(ent1) or not IsValid(ent2) then return end
    if ent2:IsPlayer() and Horde_ShouldIgnorePlayerCollision(ent1) then return false end
    if ent1:IsPlayer() and Horde_ShouldIgnorePlayerCollision(ent2) then return false end
end)
