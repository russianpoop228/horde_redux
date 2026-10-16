if not CLIENT then return end

surface.CreateFont("Horde_ChatBubble", {
    font = "Arial",
    size = 20,
    weight = 700,
    antialias = true,
})

local BUBBLE_LIFETIME = 8
local MAX_DIST_SQR    = 512 * 512
local FADE_START_SQR  = 300 * 300

local bubbles = {}

local function ParseEasyChatText(text)
    if not EasyChat or not EasyChat.MacroProcessor or not ec_markup then return nil end
    local ok, markup = pcall(function()
        local processed = EasyChat.MacroProcessor:ProcessString(text)
        return ec_markup.AdvancedParse(processed, {
            maxwidth = 400,
            default_font = "Horde_ChatBubble",
            no_shadow = false,
        })
    end)
    return ok and markup or nil
end

net.Receive("ChatBubble_Add", function()
    local ply = net.ReadEntity()
    local text = net.ReadString()
    if not IsValid(ply) or text == "" then return end

    bubbles[ply] = {
        text = text,
        markup = ParseEasyChatText(text),
        expire = CurTime() + BUBBLE_LIFETIME,
    }
end)

hook.Add("HUDPaint", "Horde_ChatBubbles_Draw", function()
    local local_ply = LocalPlayer()

    for ply, data in pairs(bubbles) do
        if not IsValid(ply) or not ply:Alive() or data.expire < CurTime() then
            bubbles[ply] = nil
            continue
        end

        local dist_sqr = local_ply:GetPos():DistToSqr(ply:GetPos())
        if dist_sqr > MAX_DIST_SQR then continue end

        local alpha = 255
        if dist_sqr > FADE_START_SQR then
            local fade = 1 - ((math.sqrt(dist_sqr) - math.sqrt(FADE_START_SQR)) /
                (math.sqrt(MAX_DIST_SQR) - math.sqrt(FADE_START_SQR)))
            alpha = math.Clamp(fade * 255, 0, 255)
        end

        local screen = (ply:EyePos() + Vector(0, 0, 20)):ToScreen()

        if data.markup then
            local w, h = data.markup:GetWide(), data.markup:GetTall()
            draw.RoundedBox(6, screen.x - w / 2 - 6, screen.y - h / 2 - 4, w + 12, h + 8,
                Color(0, 0, 0, alpha * 0.75))

            data.markup.DrawContext.Alpha = alpha
            surface.SetDrawColor(255, 255, 255, alpha)
            surface.SetTextColor(255, 255, 255, alpha)
            data.markup.DrawContext:UpdateColor(Color(255, 255, 255, alpha))
            data.markup:Draw(screen.x - w / 2, screen.y - h / 2)
        else
            surface.SetFont("Horde_ChatBubble")
            local tw, th = surface.GetTextSize(data.text)
            draw.RoundedBox(6, screen.x - tw / 2 - 6, screen.y - th / 2 - 4, tw + 12, th + 8,
                Color(0, 0, 0, alpha * 0.75))
            draw.SimpleText(data.text, "Horde_ChatBubble", screen.x, screen.y,
                Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end)

hook.Add("PlayerDisconnected", "Horde_ChatBubbles_Cleanup", function(ply)
    bubbles[ply] = nil
end)
