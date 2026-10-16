ITEM = {}

ITEM.Category = "Melee"
ITEM.Name = "Inferno Blade"
ITEM.Class = "arccw_horde_inferno_blade"
ITEM.Price = 2500
ITEM.Weight = 7
ITEM.Description = translate.Get("Item_Desc_Inferno")
ITEM.Whitelist = { Berserker = true, Samurai = true, Cremator = true }
ITEM.AmmoPrice = 10
ITEM.SecondaryAmmoPrice = -1
ITEM.Levels = { Berserker = 2, Cremator = 2 }
ITEM.Dmgtype = { HORDE.DMG_SLASH, HORDE.DMG_FIRE }
ITEM.Infusions = { HORDE.Infusion_Chrono, HORDE.Infusion_Flaming, HORDE
        .Infusion_Quality, HORDE.Infusion_Quicksilver, HORDE.Infusion_Rejuvenating }
