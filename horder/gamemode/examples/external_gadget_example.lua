-- =============================================================
-- ПРИМЕР: Гаджет из внешнего аддона
-- =============================================================
-- 1) Определение гаджета (механика):
--    addons/my_addon/lua/horde/modules/gadgets/gadget_stasis_field.lua
-- 2) Запись в магазине (цена/вес/whitelist):
--    addons/my_addon/lua/horde/modules/items/gadget/gadget_stasis_field.lua
--
-- Порядок загрузки: gadgets → items, поэтому PrintName уже доступен.
-- =============================================================

-- ─── 1) GADGET (механика) ───────────────────────────────────
GADGET = {}

GADGET.PrintName   = "Stasis Field"
GADGET.Description = [[
Project a stasis field that slows enemies in {1} units by {2}% for {3}s.
Cooldown: {4}s.
]]
GADGET.Icon        = "items/gadgets/stasis_field.png"
GADGET.Duration    = 0
GADGET.Cooldown    = 25
GADGET.Active      = true

GADGET.Params = {
    [1] = { value = 400 },
    [2] = { value = 50, percent = true },
    [3] = { value = 4 },
    [4] = { value = 25 },
}

GADGET.Hooks = {}

GADGET.Hooks.Horde_UseActiveGadget = function(ply)
    if CLIENT then return end
    if ply:Horde_GetGadget() ~= "gadget_stasis_field" then return end

    local radius = 400
    local pos = ply:GetPos()
    ply:EmitSound("horde/gadgets/stasis.ogg", 75, 100)

    for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
        if IsValid(ent) and ent:IsNPC() then
            ent:Horde_SyncDebuff(HORDE.Status_Hinder, 4, 50)
        end
    end
end

-- ─── 2) ITEM магазина (отдельный файл items/gadget/...) ─────
-- ITEM = {}
-- ITEM.Category = "Gadget"
-- ITEM.Class    = "gadget_stasis_field"
-- ITEM.Name     = ""   -- подставится из GADGET.PrintName
-- ITEM.Price    = 2500
-- ITEM.Weight   = 1
-- ITEM.Description = ""
-- ITEM.AmmoPrice = 10
-- ITEM.SecondaryAmmoPrice = -1
-- ITEM.EntityProperties = { type = HORDE.ENTITY_PROPERTY_GADGET }
-- ITEM.Whitelist = { Survivor = true }
-- ITEM.Levels    = { Survivor = 10 }
