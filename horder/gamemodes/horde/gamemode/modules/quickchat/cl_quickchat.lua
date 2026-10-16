QuickChat = {}

local isMenuOpen = false
local zWasDown = false
local pressedKeys = {}

local frameColor = Color(30, 30, 30, 220)
local textColor = Color(255, 255, 255)
local highlightColor = Color(70, 130, 180, 180)

function QuickChat.GetPhrase(id)
    return translate.Get("QuickChat_Phrase_" .. id)
end

surface.CreateFont("QuickChatFont", {
    font = "Roboto",
    size = 20,
    weight = 600,
    extended = true,
})

hook.Add("Think", "QuickChat_ToggleZ", function()
    if gui.IsGameUIVisible() or vgui.CursorVisible() then return end

    if input.IsKeyDown(KEY_Z) then
        if not zWasDown then
            isMenuOpen = not isMenuOpen
            zWasDown = true
            surface.PlaySound("buttons/button14.wav")
        end
    else
        zWasDown = false
    end
end)

hook.Add("HUDPaint", "QuickChat_DrawMenu", function()
    if not isMenuOpen then return end

    local width = 350
    local height = 320
    local x = 20
    local y = ScrH() / 2 - height / 2

    draw.RoundedBox(10, x, y, width, height, frameColor)
    draw.SimpleText(translate.Get("QuickChat_MenuTitle"), "QuickChatFont", x + 15, y - 30, textColor, TEXT_ALIGN_LEFT)

    for i = 1, 9 do
        local phrase = QuickChat.GetPhrase(i)
        if phrase then
            local lineY = y + (i - 1) * 35 + 10

            if input.IsKeyDown(KEY_0 + i) then
                draw.RoundedBox(6, x + 10, lineY - 4, width - 20, 30, highlightColor)
            end

            draw.SimpleText(i .. ". " .. phrase, "QuickChatFont", x + 20, lineY, textColor, TEXT_ALIGN_LEFT)
        end
    end
end)

hook.Add("Think", "QuickChat_HandleKeys", function()
    if not isMenuOpen then return end

    for i = 1, 9 do
        local key = KEY_0 + i

        if input.IsKeyDown(key) and not pressedKeys[i] then
            pressedKeys[i] = true
            local phrase = QuickChat.GetPhrase(i)
            if phrase then
                RunConsoleCommand("say", phrase)
                surface.PlaySound("buttons/button15.wav")
            end
            isMenuOpen = false
        elseif not input.IsKeyDown(key) then
            pressedKeys[i] = false
        end
    end
end)
