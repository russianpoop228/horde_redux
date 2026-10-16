-- =============================================================
-- ПРИМЕР: Дебафф из внешнего аддона
-- =============================================================
-- Разложите на два файла:
--
--   addons/my_addon/lua/horde/modules/status/debuff/sh_corrosion.lua
--       — RegisterStatus + Notification / звуки
--
--   addons/my_addon/lua/horde/modules/status/debuff/sv_corrosion.lua
--       — реакция на активацию (когда buildup дошёл до 100)
--
-- Встроенный framework: modules/status/debuff/sv_debuff.lua
--   ent:Horde_AddDebuffBuildup(HORDE.Status_*, amount, inflictor, pos)
-- Начисление buildup из оружия/перка — достаточно вызвать этот API.
-- =============================================================

-- ─── sh_corrosion.lua (shared) ──────────────────────────────
if HORDE and HORDE.RegisterStatus then
    if not HORDE:GetStatusID("Corrosion") then
        HORDE:RegisterStatus({
            Name         = "Corrosion",
            Icon         = "materials/status/decay.png",
            IsDebuff     = true,
            Stackable    = false,
            BuildupSound = "horde/status/bleeding_buildup.ogg",
            TriggerSound = "horde/status/bleeding_trigger.ogg",
            Notification = "You are corroding.\nHealth drains over time.",
        })
    end
end

-- ─── sv_corrosion.lua (server only) ─────────────────────────
if SERVER then
    -- Когда framework активирует дебафф (buildup >= 100), можно
    -- слушать те же точки, что и встроенные debuff-файлы.
    -- Ниже — автономный упрощённый вариант «тикер» после триггера.

    hook.Add("Horde_PostDebuffApply", "MyAddon_CorrosionStart", function(ent, debuff)
        -- Если в вашей версии хука нет — вызывайте логику из места,
        -- где вы сами решаете, что Corrosion «сработал» (buildup == 100).
        if debuff ~= HORDE.Status_Corrosion then return end
        if not IsValid(ent) then return end

        local id = ent:IsPlayer() and ent:SteamID() or ent:EntIndex()
        timer.Create("Horde_CorrosionTick_" .. id, 0.5, 10, function()
            if not IsValid(ent) then return end
            if ent:IsPlayer() and not ent:Alive() then return end
            local dmg = DamageInfo()
            dmg:SetDamage(2)
            dmg:SetDamageType(DMG_ACID)
            dmg:SetAttacker(ent)
            dmg:SetInflictor(ent)
            ent:TakeDamageInfo(dmg)
        end)
    end)

    -- Пример начисления buildup с перка/оружия:
    --   target:Horde_AddDebuffBuildup(HORDE.Status_Corrosion, 15, attacker, hitpos)
end
