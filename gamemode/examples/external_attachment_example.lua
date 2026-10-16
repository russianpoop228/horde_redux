-- =============================================================
-- ПРИМЕР: ArcCW-аттачмент в магазине
-- Путь: addons/my_addon/lua/horde/modules/items/attachment/my_optic.lua
-- Регистрируется только при ArcCWInstalled и horde_arccw_attinv_free == 0
-- =============================================================

ITEM = {}

ITEM.Category    = "Attachment"
ITEM.Name        = "My Custom RDS"
ITEM.Class       = "my_optic_custom"
ITEM.Price       = 100
ITEM.Weight      = 0
ITEM.Description = "RDS"
ITEM.AmmoPrice   = 10
ITEM.SecondaryAmmoPrice = -1
ITEM.EntityProperties = {
    type = HORDE.ENTITY_PROPERTY_GIVE,
    is_arccw_attachment = true,
    arccw_attachment_type = "Optic",
}
