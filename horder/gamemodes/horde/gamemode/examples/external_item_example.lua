-- =============================================================
-- ПРИМЕР: Предмет магазина из внешнего аддона
-- Путь: addons/my_addon/lua/horde/modules/items/equipment/field_medkit.lua
-- =============================================================

ITEM = {}

ITEM.Category    = "Equipment"
ITEM.Name        = "Field Medkit"
ITEM.Class       = "item_healthkit"
ITEM.Price       = 50
ITEM.Weight      = 0
ITEM.Description = "Restores a portion of health on use."
ITEM.AmmoPrice   = 10
ITEM.SecondaryAmmoPrice = -1
ITEM.EntityProperties = { type = HORDE.ENTITY_PROPERTY_GIVE }

-- Опциональные callback-поля (§3.5) — поведение без правок core:
-- ITEM.CanPurchase = function(ply, item)
--     if ply:Health() >= ply:GetMaxHealth() then
--         return false, "You are already at full health."
--     end
--     return true
-- end
-- ITEM.CanSell  = function(ply, item) return true end
-- ITEM.OnPickup = function(ply, item) end
-- ITEM.OnUpgrade = function(ply, item) end
