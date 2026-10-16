-- =============================================================
-- ПРИМЕР: Система Achievements — Клиентская часть
-- addons/horde_achievements/lua/horde/modules/systems/achievements/cl_achievements.lua
-- =============================================================

-- Получаем уведомление о выданном достижении
net.Receive("Horde_Achievement_Grant", function()
    local id    = net.ReadString()
    local name  = net.ReadString()
    local icon  = net.ReadString()

    -- Показываем всплывающее уведомление (используем стандартный Horde API)
    HORDE:PlayNotification(
        "Achievement Unlocked: " .. name,
        0,  -- type 0 = обычное
        icon,
        Color(255, 215, 0)  -- золотой
    )
end)

-- Панель просмотра достижений (открывается командой horde_achievements)
local function OpenAchievementsPanel()
    if IsValid(HORDE.AchievementsPanel) then
        HORDE.AchievementsPanel:Remove()
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 500)
    frame:Center()
    frame:SetTitle("Achievements")
    frame:MakePopup()
    HORDE.AchievementsPanel = frame

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(5, 5, 5, 5)

    local categories = {}
    for id, ach in pairs(HORDE.Achievements.definitions or {}) do
        local cat = ach.Category or "General"
        categories[cat] = categories[cat] or {}
        table.insert(categories[cat], ach)
    end

    for cat_name, achs in pairs(categories) do
        local cat_label = vgui.Create("DLabel", scroll)
        cat_label:SetText(cat_name)
        cat_label:SetFont("DermaLarge")
        cat_label:Dock(TOP)
        cat_label:DockMargin(5, 10, 5, 5)
        cat_label:SetAutoStretchVertical(true)

        for _, ach in ipairs(achs) do
            local row = vgui.Create("DPanel", scroll)
            row:SetHeight(60)
            row:Dock(TOP)
            row:DockMargin(5, 2, 5, 2)

            local icon_panel = vgui.Create("DImage", row)
            icon_panel:SetSize(48, 48)
            icon_panel:SetPos(8, 6)
            icon_panel:SetImage("materials/" .. (ach.Icon or ""))

            local title = vgui.Create("DLabel", row)
            title:SetText(ach.Name)
            title:SetFont("DermaDefaultBold")
            title:SetPos(64, 10)
            title:SizeToContents()

            local desc = vgui.Create("DLabel", row)
            desc:SetText(ach.Description or "")
            desc:SetPos(64, 30)
            desc:SetSize(400, 20)
        end
    end
end

concommand.Add("horde_achievements", OpenAchievementsPanel)

-- Добавляем кнопку в основное меню Horde (опционально через хук)
hook.Add("Horde_AllModulesLoaded", "Achievements_UI_Init", function()
    print("[Horde Achievements] Client UI loaded!")
end)
