-- =============================================================
-- ПРИМЕР: Skill-статус с per-status cooldown / charges + кастомный Draw
-- =============================================================
-- Кладёте в аддон, например:
--   addons/my_addon/lua/horde/modules/status/buff/sh_my_skill.lua   (shared)
--   addons/my_addon/lua/horde/modules/status/buff/sv_my_skill.lua   (server)
--
-- Порядок загрузки: core sh_status → внешние status/* → ваши файлы.
-- =============================================================

-- ─── sh_my_skill.lua (shared) ────────────────────────────────
if HORDE and HORDE.RegisterStatus then
    if not HORDE:GetStatusID("MyCustomSkill") then
        HORDE:RegisterStatus({
            Name             = "MyCustomSkill",
            Icon             = "materials/status/minion.png",  -- замените на свою иконку
            IsSkill          = true,          -- появляется в верхнем левом ряду
            IsStackableSkill = true,          -- разрешает показывать charge
            UsePerkCooldown  = false,         -- НЕ брать глобальный perk CD — только per-status
            -- Опционально: полностью свой рендер (верните true, чтобы пропустить стандартный)
            -- Draw = function(status, stack, displacement)
            --     -- displacement — уже ScreenScale-смещение по X
            --     local s = ScreenScale(15)
            --     draw.RoundedBox(10, ScreenScale(displacement), 0, s, s, Color(20, 60, 20, 220))
            --     surface.SetMaterial(Material(HORDE.Status_Icon[status], "mips smooth"))
            --     surface.SetDrawColor(color_white)
            --     surface.DrawTexturedRect(ScreenScale(1 + displacement), ScreenScale(1.25), ScreenScale(13), ScreenScale(13))
            --     local cd = LocalPlayer():Horde_GetStatusCooldown(status)
            --     if cd > 0 then
            --         draw.SimpleText(cd, "Horde_Cd", ScreenScale(displacement + 7.5), ScreenScale(7), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            --     end
            --     local ch = LocalPlayer():Horde_GetStatusCharges(status)
            --     if ch >= 0 then
            --         draw.SimpleText(ch, "Horde_Cd", ScreenScale(displacement + 12), ScreenScale(2.5), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            --     end
            --     return true
            -- end,
        })
    end
end

-- ─── sv_my_skill.lua (server only) ───────────────────────────
if SERVER then
    -- Включение иконки (stack = 1) и выставление charges/cooldown
    local function ActivateMySkill(ply)
        if not IsValid(ply) then return end

        -- Показать иконку (через обычный SyncStatus)
        ply:Horde_SyncStatus(HORDE.Status_MyCustomSkill, 1)

        -- Per-status charges (например, 3 заряда)
        ply:Horde_SetStatusCharges(HORDE.Status_MyCustomSkill, 3)

        -- Per-status cooldown 15 секунд (после использования)
        -- ply:Horde_SetStatusCooldown(HORDE.Status_MyCustomSkill, 15)
    end

    local function DeactivateMySkill(ply)
        if not IsValid(ply) then return end
        ply:Horde_SyncStatus(HORDE.Status_MyCustomSkill, 0)
        ply:Horde_SetStatusCharges(HORDE.Status_MyCustomSkill, -1)
        ply:Horde_SetStatusCooldown(HORDE.Status_MyCustomSkill, 0)
    end

    -- Пример: при выдаче перка
    hook.Add("Horde_OnSetPerk", "MyAddon_MyCustomSkill_OnSet", function(ply, perk)
        if perk == "my_custom_perk" then   -- замените на свой perk id
            ActivateMySkill(ply)
        end
    end)

    hook.Add("Horde_OnUnsetPerk", "MyAddon_MyCustomSkill_OnUnset", function(ply, perk)
        if perk == "my_custom_perk" then
            DeactivateMySkill(ply)
        end
    end)

    -- Пример использования способности (уменьшаем charge + ставим CD)
    -- Вызывайте из своего Horde_UseActivePerk или любого другого места:
    --
    -- local status = HORDE.Status_MyCustomSkill
    -- local charges = ply:Horde_GetStatusCharges(status)
    -- if charges > 0 then
    --     ply:Horde_SetStatusCharges(status, charges - 1)
    --     ply:Horde_SetStatusCooldown(status, 8)   -- 8 сек CD
    --     -- ... ваша логика
    -- end

    hook.Add("Horde_ResetStatus", "MyAddon_MyCustomSkill_Reset", function(ply)
        if IsValid(ply) then
            ply.Horde_StatusCooldown = ply.Horde_StatusCooldown or {}
            ply.Horde_StatusCharges = ply.Horde_StatusCharges or {}
            ply.Horde_StatusCooldown[HORDE.Status_MyCustomSkill] = nil
            ply.Horde_StatusCharges[HORDE.Status_MyCustomSkill] = nil
        end
    end)
end

--[[
Краткая шпаргалка API (после этих правок):

  HORDE:RegisterStatus{ ... }          -- расширенная регистрация
  HORDE:GetStatusID("Name")            -- id по имени
  HORDE:IsSkillStatus(id)
  HORDE:IsStackableSkillStatus(id)
  HORDE:StatusUsesPerkCooldown(id)

  ply:Horde_SyncStatus(status, stack)  -- показать/скрыть (stack > 0 / 0)
  ply:Horde_SetStatusCooldown(status, durationSeconds)
  ply:Horde_GetStatusCooldown(status)     -- оставшиеся секунды (ceil)
  ply:Horde_SetStatusCharges(status, n)  -- -1 = не показывать
  ply:Horde_GetStatusCharges(status)

  -- Кастомный рендер:
  RegisterStatus{ Draw = function(status, stack, displacement) ... return true end }
]]
