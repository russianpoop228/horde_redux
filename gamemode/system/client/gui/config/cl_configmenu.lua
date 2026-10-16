if not CLIENT then return end

local PANEL = {}

local CONFIG_BUTTONS = {
    { text = "Items",          cmd = "horde_item_config" },
    { text = "Enemies",        cmd = "horde_enemy_config" },
    { text = "Classes",        cmd = "horde_class_config" },
    { text = "Maps",           cmd = "horde_map_config" },
    { text = "Builder Units",  cmd = "horde_builder_config", visible = function() return LocalPlayer():IsSuperAdmin() end },
    { text = "Warden Units",   cmd = "horde_warden_config",  visible = function() return LocalPlayer():IsSuperAdmin() end },
    { text = "Gameplay",       cmd = "horde_gameplay_config", visible = function() return LocalPlayer():IsSuperAdmin() end },
    { text = "Special Waves",  cmd = "horde_specialwaves_config", visible = function() return LocalPlayer():IsSuperAdmin() end },
    { text = "Player Info",    cmd = "horde_stats" },
}

local COLS       = 3
local WINDOW_W   = 624
local WINDOW_H   = 298
local HEADER_H   = 44
local BUTTON_W   = 171
local BUTTON_H   = 41
local GAP_X      = 18
local GAP_Y      = 13
local PAD_LEFT   = 34
local PAD_TOP    = 23
local BORDER     = 2

local RED         = Color(220, 0, 43)
local RED_BRIGHT = Color(222, 8, 49)
local BG          = Color(31, 31, 31)
local BUTTON     = Color(78, 78, 78)
local BUTTON_HOV = Color(91, 91, 91)
local WHITE      = Color(245, 245, 245)

local function CollectVisibleButtons()
    local list = {}

    for _, entry in ipairs(CONFIG_BUTTONS) do
        local show = true

        if entry.visible ~= nil then
            if isfunction(entry.visible) then
                show = entry.visible() and true or false
            else
                show = entry.visible and true or false
            end
        end

        if show then
            list[#list + 1] = entry
        end
    end

    return list
end

local function DrawButton(self, w, h)
    local hovered = self:IsHovered()
    draw.RoundedBox(4, 0, 0, w, h, hovered and BUTTON_HOV or BUTTON)
end

function PANEL:Init()
    local buttons = CollectVisibleButtons()
    local rows = math.max(1, math.ceil(#buttons / COLS))

    local width = math.min(WINDOW_W, ScrW() - 32)
    local height = math.min(WINDOW_H, ScrH() - 32)

    self:SetSize(width, height)
    self:SetPos(math.floor((ScrW() - width) * 0.5), math.floor((ScrH() - height) * 0.5))
    self:MakePopup()

    local close_btn = vgui.Create("DButton", self)
    close_btn:SetText("X")
    close_btn:SetFont("Trebuchet24")
    close_btn:SetTextColor(WHITE)
    close_btn:SetSize(38, HEADER_H)
    close_btn:SetPos(width - 48, 0)
    close_btn.Paint = function() end
    close_btn.DoClick = function()
        HORDE:ToggleConfigMenu()
    end

    local grid = vgui.Create("DPanel", self)
    grid:SetPaintBackground(false)

    local content_w = COLS * BUTTON_W + (COLS - 1) * GAP_X
    local grid_x = math.floor((width - content_w) * 0.5)
    local grid_y = HEADER_H + PAD_TOP
    local grid_h = rows * BUTTON_H + math.max(0, rows - 1) * GAP_Y
    grid:SetPos(grid_x, grid_y)
    grid:SetSize(content_w, grid_h)

    if width ~= WINDOW_W then
        local tile_w = math.floor((width - 2 * BORDER - 2 * 18 - (COLS - 1) * 10) / COLS)
        tile_w = math.max(48, tile_w)
        content_w = COLS * tile_w + (COLS - 1) * 10
        grid_x = math.floor((width - content_w) * 0.5)
        grid:SetPos(grid_x, grid_y)
        grid:SetSize(content_w, grid_h)
    end

    local tile_w = math.floor(content_w / COLS)
    if width == WINDOW_W then
        tile_w = BUTTON_W
    else
        tile_w = math.floor((content_w - (COLS - 1) * 10) / COLS)
    end
    local gap_x = width == WINDOW_W and GAP_X or 10

    for i, entry in ipairs(buttons) do
        local col = (i - 1) % COLS
        local row = math.floor((i - 1) / COLS)

        local btn = vgui.Create("DButton", grid)
        btn:SetSize(tile_w, BUTTON_H)
        btn:SetPos(col * (tile_w + gap_x), row * (BUTTON_H + GAP_Y))
        btn:SetFont("Trebuchet24")
        btn:SetText("")
        btn.Paint = function(self, w, h)
            DrawButton(self, w, h)
            draw.SimpleText(
                entry.text,
                "Trebuchet24",
                w * 0.5,
                h * 0.5,
                WHITE,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        local cmd = entry.cmd
        btn.DoClick = function()
            if entry.action then
                entry.action()
            else
                RunConsoleCommand(cmd)
                HORDE:ToggleConfigMenu()
            end
        end
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, RED)
    draw.RoundedBox(6, BORDER, BORDER, w - BORDER * 2, h - BORDER * 2, BG)

    draw.RoundedBoxEx(6, BORDER, BORDER, w - BORDER * 2, HEADER_H, RED, true, true, false, false)
    draw.SimpleText("Config Menu", "Trebuchet24", 11, HEADER_H * 0.5 + 1, WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

vgui.Register("HordeConfigMenu", PANEL, "Panel")
