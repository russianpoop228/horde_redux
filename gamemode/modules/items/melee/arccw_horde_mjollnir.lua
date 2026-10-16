ITEM = {}

ITEM.Category = "Melee"
ITEM.Name = "Mjolnir"
ITEM.Class = "arccw_horde_mjollnir"
ITEM.Price = 3000
ITEM.Weight = 8
ITEM.Description = translate.Get("Item_Desc_Mjolnir")
ITEM.Whitelist = { Berserker = true, Samurai = true, }
ITEM.AmmoPrice = 10
ITEM.SecondaryAmmoPrice = -1
ITEM.Levels = { Berserker = 3 }
ITEM.Dmgtype = { HORDE.DMG_BLUNT, HORDE.DMG_LIGHTNING }
ITEM.Infusions = { HORDE.Infusion_Chrono, HORDE.Infusion_Galvanizing, HORDE
        .Infusion_Quality, HORDE.Infusion_Quicksilver, HORDE.Infusion_Rejuvenating }
