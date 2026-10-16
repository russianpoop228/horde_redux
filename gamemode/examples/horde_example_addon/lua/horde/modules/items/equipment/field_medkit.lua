ITEM = {}

ITEM.Category    = "Relics"
ITEM.Name        = "Field Medkit"
ITEM.Class       = "item_healthkit"
ITEM.Price       = 50
ITEM.Weight      = 0
ITEM.Description = "Restores a portion of health on use."
ITEM.AmmoPrice   = 10
ITEM.SecondaryAmmoPrice = -1
ITEM.EntityProperties = { type = HORDE.ENTITY_PROPERTY_GIVE }

ITEM.CanPurchase = function(ply, item)
    if ply:Health() >= ply:GetMaxHealth() then
        return false, "You are already at full health."
    end
    return true
end
