-- =============================================================
-- ПРИМЕР: Новая инфузия из внешнего аддона
-- Путь: addons/my_addon/lua/horde/modules/infusions/my_vampiric.lua
--
-- Встроенные id 0..14 зафиксированы (сейвы/net.ReadUInt(5)).
-- Новые инфузии получают id 15+ автоматически.
--
-- Чтобы инфузия появилась на оружии — добавьте её id в
-- ITEM.Infusions предмета (modules/items/...) или через
-- GetDefaultItemInfusions / хук после загрузки.
-- =============================================================

INFUSION = {}

INFUSION.Key  = "Vampiric"           -- → HORDE.Infusion_Vampiric
INFUSION.Name = "Vampiric"
INFUSION.Icon = "infusion/siphoning.png"
INFUSION.Color = Color(180, 20, 60)
INFUSION.Description = [[
Heal for 5% of damage dealt.

15% less weapon damage.
]]

-- OnDamage вызывается из Horde_OnPlayerDamagePre / builder minion damage
INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    bonus.more = bonus.more * 0.85
    if SERVER and IsValid(ply) and ply:Alive() then
        local heal = math.max(1, math.floor(dmginfo:GetDamage() * 0.05))
        local healinfo = HealInfo:New({ amount = heal, healer = ply })
        HORDE:OnPlayerHeal(ply, healinfo)
    end
end

-- После регистрации можно выдать оружию:
-- hook.Add("Horde_AllModulesLoaded", "MyAddon_VampiricOnKnife", function()
--     local item = HORDE.items and HORDE.items["arccw_horde_knife"]
--     if item then
--         item.infusions = item.infusions or {}
--         local id = HORDE:GetInfusionID("Vampiric")
--         if id and not table.HasValue(item.infusions, id) then
--             table.insert(item.infusions, id)
--         end
--     end
-- end)
