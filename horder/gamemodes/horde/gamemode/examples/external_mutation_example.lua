-- =============================================================
-- ПРИМЕР: Мутация врага из внешнего аддона
-- Путь: addons/my_addon/lua/horde/modules/mutations/frenzy.lua
-- =============================================================

MUTATION = {}

MUTATION.PrintName   = "Frenzy"
MUTATION.ClassName   = "frenzy"
MUTATION.Description = "Enemy moves and attacks faster."
MUTATION.NoRand      = false  -- true = не в случайном пуле

MUTATION.Hooks = {}

MUTATION.Hooks.Horde_OnSetMutation = function(ent, mutation)
    if mutation ~= "frenzy" then return end
    if not IsValid(ent) then return end
    -- ent:SetPlaybackRate(1.25) и т.п.
end
