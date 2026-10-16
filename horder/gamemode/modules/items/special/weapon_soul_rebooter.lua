ITEM = {}

ITEM.Category = "Special"
ITEM.Class = "weapon_soul_rebooter"
ITEM.Name = "Soul Rebooter"
ITEM.Price = 500
ITEM.Weight = 3
ITEM.Description = [[Opens the Resurrection menu. Choose 1 fallen ally to bring back to life.

Place a Soul Rebooter pylon on the ground.
When the timer finishes, the ally is revived at the pylon.

If the pylon is destroyed before the timer ends, resurrection fails.

Each placement consumes 1 charge.
Charges are shop-only and cannot be replenished by Ammo Boxes.]]
ITEM.AmmoPrice = 500
ITEM.SecondaryAmmoPrice = -1
ITEM.EntityProperties = { type = HORDE.ENTITY_PROPERTY_GIVE }
ITEM.Whitelist = { Medic = true, Hatcher = true, }
ITEM.Levels = { Medic = 5, Hatcher = 5 }
ITEM.SkullTokens = 3
