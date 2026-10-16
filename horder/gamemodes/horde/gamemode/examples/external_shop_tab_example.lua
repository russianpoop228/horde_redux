-- =============================================================
-- ПРИМЕР: Новая вкладка магазина
-- Можно положить в любой sh_ файл аддона или systems/
-- =============================================================

hook.Add("Horde_AllModulesLoaded", "MyAddon_RegisterShopTab", function()
    HORDE:RegisterShopTab({
        Name  = "Relics",   -- должно совпадать с ITEM.Category новых предметов
        Order = 50,         -- чем меньше, тем левее
    })
end)

-- Предметы с Category = "Relics" появятся на этой вкладке
-- (cl_shop.lua читает HORDE._shop_tabs).
