-- =============================================================
-- ПРИМЕР: Система Achievements 2.0 — Полностью внешний аддон
-- =============================================================
-- Путь:
--   addons/horde_achievements/lua/horde/modules/systems/achievements/
--   └── sh_achievements.lua   ← этот файл (shared)
--   └── sv_achievements.lua   ← серверная логика
--   └── cl_achievements.lua   ← клиентский UI
--
-- Загрузчик найдёт папку systems/achievements/ и загрузит
-- все sh_/sv_/cl_ файлы с правильным realm.
-- ЯДРО HORDE НЕ ИЗМЕНЯЕТСЯ НИ НА СТРОЧКУ.
-- =============================================================

-- ─── Инициализация таблицы системы ───────────────────────────
HORDE.Achievements = HORDE.Achievements or {}
HORDE.Achievements.definitions = HORDE.Achievements.definitions or {}
HORDE.Achievements.progress = HORDE.Achievements.progress or {}

-- ─── API регистрации достижений ──────────────────────────────
function HORDE.Achievements:Register(tbl)
    assert(tbl.ID, "Achievement must have an ID")
    assert(tbl.Name, "Achievement must have a Name")

    self.definitions[tbl.ID] = {
        ID          = tbl.ID,
        Name        = tbl.Name,
        Description = tbl.Description or "",
        Icon        = tbl.Icon or "horde_default_achievement.png",
        Hidden      = tbl.Hidden or false,
        -- Условие: функция(ply, context) → bool
        Condition   = tbl.Condition,
        -- Награда: функция(ply) вызывается при получении
        Reward      = tbl.Reward,
        -- Категория для UI
        Category    = tbl.Category or "General",
    }

    print("[Horde Achievements] Registered: " .. tbl.ID)
end

-- ─── Регистрируем саму систему в Horde ────────────────────────
-- Это уведомляет ядро об существовании системы (опционально)
hook.Add("Horde_AllModulesLoaded", "Achievements_Init", function()
    if HORDE.RegisterSystem then
        HORDE:RegisterSystem({
            Name    = "Achievements 2.0",
            Version = "1.0.0",
            OnInit  = function()
                print("[Horde Achievements] System initialized!")
            end
        })
    end
end)

-- ─── Несколько встроенных достижений ─────────────────────────
if SERVER then
    -- Хук для отслеживания убийств врагов
    -- Использует СТАНДАРТНЫЕ хуки Horde — без изменений в ядре!
    hook.Add("PostEntityTakeDamage", "Achievements_TrackKills", function(ent, dmginfo, taken)
        if not ent:IsNPC() then return end
        if not ent:IsValid() then return end
        if ent:Health() > 0 then return end

        local attacker = dmginfo:GetAttacker()
        if not IsValid(attacker) or not attacker:IsPlayer() then return end

        -- Увеличиваем счётчик убийств игрока
        attacker.Horde_Ach_Kills = (attacker.Horde_Ach_Kills or 0) + 1

        -- Проверяем условия достижений
        for id, ach in pairs(HORDE.Achievements.definitions) do
            if ach.Condition and ach.Condition(attacker, {
                event = "kill",
                entity = ent,
                kills = attacker.Horde_Ach_Kills
            }) then
                -- Выдать достижение
                HORDE.Achievements:Grant(attacker, id)
            end
        end
    end)

    function HORDE.Achievements:Grant(ply, achievement_id)
        if not IsValid(ply) then return end

        local ach = self.definitions[achievement_id]
        if not ach then return end

        -- Проверить что уже не выдано
        local key = "horde_ach_" .. ply:SteamID() .. "_" .. achievement_id
        if file.Exists(key .. ".txt", "DATA") then return end

        -- Сохранить
        if not file.IsDir("horde/achievements", "DATA") then
            file.CreateDir("horde/achievements")
        end
        file.Write("horde/achievements/" .. ply:SteamID64() .. "_" .. achievement_id .. ".txt", "1")

        -- Уведомить игрока
        net.Start("Horde_Achievement_Grant")
            net.WriteString(achievement_id)
            net.WriteString(ach.Name)
            net.WriteString(ach.Icon)
        net.Send(ply)

        -- Выполнить награду
        if ach.Reward then
            ach.Reward(ply)
        end

        -- Стрельнуть хук (другие аддоны могут слушать)
        hook.Run("Horde_AchievementGranted", ply, achievement_id, ach)

        print("[Horde Achievements] " .. ply:Nick() .. " earned: " .. ach.Name)
    end

    util.AddNetworkString("Horde_Achievement_Grant")
end

-- ─── Примеры достижений ──────────────────────────────────────
-- Эти вызовы происходят в sh_ файле, но достижение само по себе
-- содержит server-only логику Condition/Reward.
-- Либо выноси Condition/Reward в отдельный sv_ файл.

HORDE.Achievements:Register({
    ID          = "first_blood",
    Name        = "First Blood",
    Description = "Kill your first enemy.",
    Icon        = "achievements/first_blood.png",
    Category    = "Kills",
    Condition   = function(ply, ctx)
        return ctx.event == "kill" and ctx.kills == 1
    end,
})

HORDE.Achievements:Register({
    ID          = "centurion",
    Name        = "Centurion",
    Description = "Kill 100 enemies in one game.",
    Icon        = "achievements/centurion.png",
    Category    = "Kills",
    Condition   = function(ply, ctx)
        return ctx.event == "kill" and ctx.kills >= 100
    end,
    Reward      = function(ply)
        -- Дать бонусные деньги
        if SERVER then
            ply:Horde_AddMoney(500)
            HORDE:SendNotification("Achievement bonus: +$500", 0, ply)
        end
    end,
})

HORDE.Achievements:Register({
    ID          = "wave_master",
    Name        = "Wave Master",
    Description = "Survive 20 waves.",
    Icon        = "achievements/wave_master.png",
    Category    = "Survival",
    Condition   = function(ply, ctx)
        return ctx.event == "wave_complete" and ctx.wave >= 20
    end,
})
