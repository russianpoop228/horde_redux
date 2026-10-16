surface.CreateFont("WCfg_Body", { font = "CloseCaption_Normal", size = 18, weight = 500 })
surface.CreateFont("WCfg_Small", { font = "CloseCaption_Normal", size = 13, weight = 400 })

local COL_RED            = Color(220, 30, 56)
local COL_RED_TEXT       = Color(232, 39, 73)
local COL_PURPLE         = Color(164, 30, 219)
local COL_CARD           = Color(60, 64, 70)
local COL_CARD_HOVER     = Color(72, 77, 84)
local COL_INPUT_BG       = Color(66, 70, 76)
local COL_BTN_GRAY       = Color(66, 70, 78)
local COL_BTN_GRAY_HOVER = Color(80, 85, 94)
local COL_WINDOW_BG      = Color(31, 31, 31)
local COL_WHITE          = color_white

local function StyleConfigScrollBar(scroll, width)
    if not IsValid(scroll) or not IsValid(scroll.VBar) then return end

    local bar = scroll.VBar
    width = width or 8
    bar:SetWide(width)
    bar:DockMargin(6, 0, 0, 0)

    for _, btn in ipairs({ bar.btnUp, bar.btnDown }) do
        if IsValid(btn) then
            btn:SetVisible(false)
            btn:SetSize(0, 0)
            btn.Paint = function() end
        end
    end

    function bar:Paint(w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(24, 25, 28))
    end

    function bar.btnGrip:Paint(w, h)
        local col = self:IsHovered() and Color(240, 50, 76) or COL_RED
        draw.RoundedBox(0, 0, 0, w, h, col)
    end
end

local CATEGORY_LABELS = { defense = "Defense", support = "Support" }
local CATEGORY_ORDER  = { "defense", "support" }

local GRID_PER_ROW, GRID_CARD, GRID_GAP = 3, 100, 10
local GRID_WIDE = GRID_PER_ROW * GRID_CARD + (GRID_PER_ROW - 1) * GRID_GAP

local PANEL_INSTANCE

local function MakeField(parent, label_text)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, 6)
    row:SetTall(38)
    row:SetPaintBackground(false)

    local label = vgui.Create("DLabel", row)
    label:Dock(TOP)
    label:SetTall(16)
    label:SetFont("WCfg_Small")
    label:SetTextColor(COL_WHITE)
    label:SetText(label_text)

    local entry = vgui.Create("DTextEntry", row)
    entry:Dock(TOP)
    entry:SetTall(22)
    entry:SetFont("WCfg_Small")
    entry.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, COL_INPUT_BG)
        self:DrawTextEntryText(COL_WHITE, Color(150, 170, 255), COL_WHITE)
    end

    return entry
end

local function ParseValue(text, original)
    local n = tonumber(text)
    if n ~= nil and (isnumber(original) or original == nil) then return n end
    return text
end

local PANEL = {}

function PANEL:Init()
    if ScrW() < 1000 then
        self:SetSize(ScrW() - 40, ScrH() - 40)
    else
        self:SetSize(830, 640)
    end
    self:SetPos((ScrW() / 2) - (self:GetWide() / 2), (ScrH() / 2) - (self:GetTall() / 2))
    self:MakePopup()

    self.State = { tab = "defense", selected = nil }
    PANEL_INSTANCE = self

    local header = vgui.Create("DPanel", self)
    header:Dock(TOP)
    header:SetTall(40)
    function header:Paint(w, h)
        draw.RoundedBoxEx(8, 0, 0, w, h, COL_RED, true, true, false, false)
        draw.SimpleText("Warding Units", "Trebuchet24", 16, h / 2, COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("Config Mode", "Trebuchet24", 16 + 130, h / 2, Color(26, 8, 11), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local close_btn = vgui.Create("DButton", header)
    close_btn:SetText("")
    close_btn:SetSize(24, 24)
    function close_btn:PerformLayout() self:SetPos(header:GetWide() - 16 - 24, 8) end
    function close_btn:Paint(w, h)
        draw.SimpleText("r", "Marlett", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close_btn.DoClick = function() HORDE:ToggleWardenConfig() end

    local body = vgui.Create("DPanel", self)
    body:Dock(FILL)
    body:DockMargin(20, 16, 20, 18)
    body:SetPaintBackground(false)

    local left = vgui.Create("DPanel", body)
    left:Dock(LEFT)
    left:SetWide(330)
    left:SetPaintBackground(false)

    local right = vgui.Create("DPanel", body)
    right:Dock(FILL)
    right:DockMargin(30, 0, 0, 0)
    right:SetPaintBackground(false)

    local tabs_row = vgui.Create("DPanel", left)
    tabs_row:Dock(TOP)
    tabs_row:SetTall(26)
    tabs_row:DockMargin(4, 0, 0, 12)
    tabs_row:SetPaintBackground(false)

    local x_cursor = 0
    for _, cat in ipairs(CATEGORY_ORDER) do
        local btn = vgui.Create("DButton", tabs_row)
        btn:SetText("")
        surface.SetFont("Trebuchet24")
        local tw = surface.GetTextSize(CATEGORY_LABELS[cat])
        btn:SetPos(x_cursor, 0)
        btn:SetSize(tw + 4, 26)
        x_cursor = x_cursor + tw + 4 + 22
        btn.category = cat
        function btn:Paint(w, h)
            local col = COL_WHITE
            if self.category == PANEL_INSTANCE.State.tab then col = COL_RED_TEXT
            elseif self:IsHovered() then col = Color(187, 187, 188) end
            draw.SimpleText(CATEGORY_LABELS[self.category], "Trebuchet24", 0, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function()
            PANEL_INSTANCE.State.tab = btn.category
            PANEL_INSTANCE:RebuildGrid()
        end
    end

    local grid_scroll = vgui.Create("DScrollPanel", left)
    grid_scroll:Dock(FILL)
    StyleConfigScrollBar(grid_scroll, 10)

    local grid_canvas = vgui.Create("DPanel", grid_scroll)
    grid_canvas:SetPaintBackground(false)
    grid_canvas:SetWide(GRID_WIDE)

    local footer = vgui.Create("DPanel", right)
    footer:Dock(BOTTOM)
    footer:SetTall(42)
    footer:DockMargin(0, 8, 0, 0)
    footer:SetPaintBackground(false)

    local scroll = vgui.Create("DScrollPanel", right)
    scroll:Dock(FILL)
    StyleConfigScrollBar(scroll, 10)

    local form = vgui.Create("DPanel", scroll)
    form:Dock(TOP)
    form:DockMargin(0, 0, 6, 0)
    form:SetPaintBackground(false)
    form:SetTall(640)

    self.f_name    = MakeField(form, "Name:")
    self.f_desc    = MakeField(form, "Description:")
    self.f_damage  = MakeField(form, "Attack Damage:")
    self.f_speed   = MakeField(form, "Attack Speed (hits/sec):")
    self.f_type    = MakeField(form, "Damage Type:")
    self.f_cost    = MakeField(form, "Money Cost:")
    self.f_limit   = MakeField(form, "Build Limit:")
    self.f_deploy  = MakeField(form, "Deploy Time (sec):")
    self.f_minlvl  = MakeField(form, "Min. Warden Level:")
    self.f_lifetime = MakeField(form, "Lifetime (sec, if consumable=lifetime):")
    self.f_charges  = MakeField(form, "Damage Charges (if consumable=damage_charges):")

    local ctype_row = vgui.Create("DPanel", form)
    ctype_row:Dock(TOP)
    ctype_row:DockMargin(0, 0, 0, 6)
    ctype_row:SetTall(38)
    ctype_row:SetPaintBackground(false)

    local ctype_label = vgui.Create("DLabel", ctype_row)
    ctype_label:Dock(TOP)
    ctype_label:SetTall(16)
    ctype_label:SetFont("WCfg_Small")
    ctype_label:SetTextColor(COL_WHITE)
    ctype_label:SetText("Consumable Type:")

    local ctype_buttons_row = vgui.Create("DPanel", ctype_row)
    ctype_buttons_row:Dock(TOP)
    ctype_buttons_row:SetTall(22)
    ctype_buttons_row:SetPaintBackground(false)

    local CTYPE_ORDER = { "lifetime", "damage_charges", "wave_limited" }
    local CTYPE_LABELS = { lifetime = "Lifetime", damage_charges = "Charges", wave_limited = "Wave" }
    self.ctype_buttons = {}
    local cx = 0
    for _, ctype in ipairs(CTYPE_ORDER) do
        local b = vgui.Create("DButton", ctype_buttons_row)
        b:SetText("")
        surface.SetFont("WCfg_Small")
        local tw = surface.GetTextSize(CTYPE_LABELS[ctype])
        b:SetPos(cx, 0)
        b:SetSize(tw + 16, 22)
        cx = cx + tw + 16 + 6
        function b:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, self.active and COL_RED or COL_INPUT_BG)
            draw.SimpleText(CTYPE_LABELS[ctype], "WCfg_Small", w/2, h/2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function()
            self.selected_ctype = ctype
            for _, btn in pairs(PANEL_INSTANCE.ctype_buttons) do
                btn.active = (btn.ctype == ctype)
            end
        end
        b.ctype = ctype
        self.ctype_buttons[ctype] = b
    end

    local cat_row = vgui.Create("DPanel", form)
    cat_row:Dock(TOP)
    cat_row:DockMargin(0, 0, 0, 6)
    cat_row:SetTall(38)
    cat_row:SetPaintBackground(false)

    local cat_label = vgui.Create("DLabel", cat_row)
    cat_label:Dock(TOP)
    cat_label:SetTall(16)
    cat_label:SetFont("WCfg_Small")
    cat_label:SetTextColor(COL_WHITE)
    cat_label:SetText("Category:")

    local cat_buttons_row = vgui.Create("DPanel", cat_row)
    cat_buttons_row:Dock(TOP)
    cat_buttons_row:SetTall(22)
    cat_buttons_row:SetPaintBackground(false)

    self.cat_buttons = {}
    local ccx = 0
    for _, cat in ipairs(CATEGORY_ORDER) do
        local b = vgui.Create("DButton", cat_buttons_row)
        b:SetText("")
        surface.SetFont("WCfg_Small")
        local tw = surface.GetTextSize(CATEGORY_LABELS[cat])
        b:SetPos(ccx, 0)
        b:SetSize(tw + 16, 22)
        ccx = ccx + tw + 16 + 6
        function b:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, self.active and COL_RED or COL_INPUT_BG)
            draw.SimpleText(CATEGORY_LABELS[cat], "WCfg_Small", w/2, h/2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function()
            self.selected_category = cat
            for _, btn in pairs(PANEL_INSTANCE.cat_buttons) do
                btn.active = (btn.cat == cat)
            end
        end
        b.cat = cat
        self.cat_buttons[cat] = b
    end

    local actions = vgui.Create("DPanel", form)
    actions:Dock(TOP)
    actions:SetTall(32)
    actions:DockMargin(0, 6, 0, 6)
    actions:SetPaintBackground(false)

    local function MakeSmallButton(parent, bg, bg_hover, text, icon_path)
        local b = vgui.Create("DButton", parent)
        b:SetText("")
        b.IconMaterial = icon_path and Material(icon_path) or nil
        function b:Paint(w, h)
            draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and bg_hover or bg)

            local text_x = w / 2
            if self.IconMaterial then
                surface.SetMaterial(self.IconMaterial)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.DrawTexturedRect(10, h / 2 - 9, 18, 18)
                text_x = (w + 18) / 2 + 4
            end

            draw.SimpleText(text, "WCfg_Body", text_x, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return b
    end

    local btn_upgrades  = MakeSmallButton(actions, COL_PURPLE, Color(184,50,239), "Upgrades", "perks/pioneer.png")
    local btn_infusions = MakeSmallButton(actions, COL_BTN_GRAY, COL_BTN_GRAY_HOVER, "Infusions", "infusion/infusion.png")
    function actions:PerformLayout(w, h)
        local cw = (w - 10) / 2
        btn_upgrades:SetPos(0, 0)       btn_upgrades:SetSize(cw, h)
        btn_infusions:SetPos(cw+10, 0)  btn_infusions:SetSize(cw, h)
    end
    btn_upgrades.DoClick = function() if PANEL_INSTANCE.State.selected then OpenWardenUpgradesModal(PANEL_INSTANCE, PANEL_INSTANCE.State.selected) end end
    btn_infusions.DoClick = function() if PANEL_INSTANCE.State.selected then OpenWardenInfusionsPoolModal(PANEL_INSTANCE, PANEL_INSTANCE.State.selected) end end

    local save_btn = vgui.Create("DButton", footer)
    save_btn:Dock(FILL)
    save_btn:SetText("")
    function save_btn:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(240,50,76) or COL_RED)
        draw.SimpleText("Save Changes", "WCfg_Body", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    save_btn.DoClick = function() PANEL_INSTANCE:SaveCurrent() end

    self.grid_canvas = grid_canvas
    self.form = form

    self:RebuildGrid()
end

function PANEL:SaveCurrent()
    local class = self.State.selected
    if not class then return end
    local base = HORDE:Horde_GetWardenBuildableData(class)
    local existing = HORDE.WardenBuildableOverrides[class] or {}

    local override = {
        PrintName    = self.f_name:GetValue(),
        Description  = self.f_desc:GetValue(),
        Damage       = ParseValue(self.f_damage:GetValue(), base.Damage),
        FireRate     = ParseValue(self.f_speed:GetValue(), base.FireRate),
        DamageType   = self.f_type:GetValue(),
        Cost         = tonumber(self.f_cost:GetValue()) or base.Cost,
        Limit        = math.floor(tonumber(self.f_limit:GetValue()) or base.Limit),
        DeployTime   = tonumber(self.f_deploy:GetValue()) or base.DeployTime,
        MinLevel     = math.floor(tonumber(self.f_minlvl:GetValue()) or base.MinLevel or 0),
        Lifetime     = tonumber(self.f_lifetime:GetValue()) or base.Lifetime,
        DamageCharges = math.floor(tonumber(self.f_charges:GetValue()) or base.DamageCharges or 50),
        ConsumableType = self.selected_ctype or base.ConsumableType,
        Category     = self.selected_category or base.Category,
        Bonus_Lifetime       = existing.Bonus_Lifetime,
        Bonus_DamageCharges  = existing.Bonus_DamageCharges,
        Bonus_Damage         = existing.Bonus_Damage,
        Bonus_FireRate       = existing.Bonus_FireRate,
        Lvl5_Bonus_Lifetime      = existing.Lvl5_Bonus_Lifetime,
        Lvl5_Bonus_DamageCharges = existing.Lvl5_Bonus_DamageCharges,
        Lvl5_Bonus_Damage        = existing.Lvl5_Bonus_Damage,
        Lvl5_Bonus_FireRate      = existing.Lvl5_Bonus_FireRate,
        Lvl10_Bonus_Lifetime      = existing.Lvl10_Bonus_Lifetime,
        Lvl10_Bonus_DamageCharges = existing.Lvl10_Bonus_DamageCharges,
        Lvl10_Bonus_Damage        = existing.Lvl10_Bonus_Damage,
        Lvl10_Bonus_FireRate      = existing.Lvl10_Bonus_FireRate,
        UpgradePricePercent  = existing.UpgradePricePercent,
        InfusionPool         = existing.InfusionPool,
    }

    HORDE.WardenBuildableOverrides[class] = override
    net.Start("Horde_SetWardenConfigData")
        net.WriteString(class)
        net.WriteTable(override)
    net.SendToServer()

    self:RebuildGrid()
end

function PANEL:LoadIntoForm(class)
    self.State.selected = class
    self.f_name:SetValue(HORDE:Horde_GetWardenBuildablePrintName(class))
    self.f_desc:SetValue(HORDE:Horde_GetWardenBuildableDescription(class))
    self.f_damage:SetValue(tostring(HORDE:Horde_GetWardenBuildableDamage(class)))
    self.f_speed:SetValue(tostring(HORDE:Horde_GetWardenBuildableFireRate(class)))
    self.f_type:SetValue(tostring(HORDE:Horde_GetWardenBuildableDamageType(class)))
    self.f_cost:SetValue(tostring(HORDE:Horde_GetWardenBuildableCost(class)))
    self.f_limit:SetValue(tostring(HORDE:Horde_GetWardenBuildableLimit(class)))
    self.f_deploy:SetValue(tostring(HORDE:Horde_GetWardenBuildableDeployTime(class)))
    self.f_minlvl:SetValue(tostring(HORDE:Horde_GetWardenBuildableMinLevel(class)))
    self.f_lifetime:SetValue(tostring(HORDE:Horde_GetWardenBuildableLifetime(class)))
    self.f_charges:SetValue(tostring(HORDE:Horde_GetWardenBuildableDamageCharges(class)))

    local ctype = HORDE:Horde_GetWardenBuildableConsumableType(class)
    self.selected_ctype = ctype
    for _, btn in pairs(self.ctype_buttons) do
        btn.active = (btn.ctype == ctype)
    end

    local data = HORDE:Horde_GetWardenBuildableData(class) or {}
    local cat = data.Category or "support"
    self.selected_category = cat
    for _, btn in pairs(self.cat_buttons) do
        btn.active = (btn.cat == cat)
    end
end

function PANEL:RebuildGrid()
    self.grid_canvas:Clear()
    local list = HORDE:Horde_GetWardenBuildablesByCategory(self.State.tab)
    local per_row, size, gap = GRID_PER_ROW, GRID_CARD, GRID_GAP
    self.grid_canvas:SetTall(math.ceil((#list + 1) / per_row) * (size + gap))

    local function PosForIndex(i)
        local col = (i - 1) % per_row
        local row = math.floor((i - 1) / per_row)
        return col * (size + gap), row * (size + gap)
    end

    local first
    for i, data in ipairs(list) do
        local x, y = PosForIndex(i)
        local card = vgui.Create("DButton", self.grid_canvas)
        card:SetText("")
        card:SetPos(x, y)
        card:SetSize(size, size)
        card.data = data

        function card:Paint(w, h)
            local bg = COL_CARD
            if PANEL_INSTANCE.State.selected == data.ClassName then bg = COL_RED
            elseif self:IsHovered() then bg = COL_CARD_HOVER end
            draw.RoundedBox(6, 0, 0, w, h, bg)
            if data.Icon and file.Exists("materials/" .. data.Icon, "GAME") then
                surface.SetMaterial(Material(data.Icon))
                surface.SetDrawColor(255, 255, 255, 255)
                surface.DrawTexturedRect(w / 2 - 48, 18, 95, 48)
            end
            draw.SimpleText(data.PrintName, "WCfg_Small", w/2, h - 14, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        card.DoClick = function() PANEL_INSTANCE:LoadIntoForm(data.ClassName) end

        local del_btn = vgui.Create("DButton", card)
        del_btn:SetText("")
        del_btn:SetSize(18, 18)
        del_btn:SetPos(size - 4 - 18, 4)
        function del_btn:Paint(w, h)
            local bg = self:IsHovered() and Color(255, 34, 68) or Color(0, 0, 0, 90)
            draw.RoundedBox(4, 0, 0, w, h, bg)
            draw.SimpleText("r", "Marlett", w/2, h/2, Color(255, 255, 255, self:IsHovered() and 255 or 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        del_btn.DoClick = function()
            Derma_Query(
                "Remove \"" .. data.PrintName .. "\" from the Warding Units menu?\nAlready built units keep working — only NEW ones stop being offered.",
                "Remove Buildable",
                "Remove", function()
                    net.Start("Horde_RemoveWardenBuildable")
                        net.WriteString(data.ClassName)
                    net.SendToServer()
                    if PANEL_INSTANCE.State.selected == data.ClassName then
                        PANEL_INSTANCE.State.selected = nil
                    end
                    timer.Simple(0.1, function() if IsValid(PANEL_INSTANCE) then PANEL_INSTANCE:RebuildGrid() end end)
                end,
                "Cancel", function() end
            )
        end

        if not first then first = data end
    end

    local add_x, add_y = PosForIndex(#list + 1)
    local add_card = vgui.Create("DButton", self.grid_canvas)
    add_card:SetText("")
    add_card:SetTooltip("Add a new buildable")
    add_card:SetPos(add_x, add_y)
    add_card:SetSize(size, size)
    function add_card:Paint(w, h)
        local bg = self:IsHovered() and COL_CARD_HOVER or Color(38, 40, 44)
        local col = self:IsHovered() and Color(136, 141, 152) or Color(88, 92, 100)
        draw.RoundedBox(6, 0, 0, w, h, bg)
        surface.SetDrawColor(col)
        surface.DrawLine(w/2 - 14, h/2, w/2 + 14, h/2)
        surface.DrawLine(w/2, h/2 - 14, w/2, h/2 + 14)
    end
    add_card.DoClick = function()
        OpenAddWardenBuildableModal(PANEL_INSTANCE, PANEL_INSTANCE.State.tab)
    end

    if first and (not self.State.selected or not HORDE:Horde_IsWardenBuildable(self.State.selected)) then
        self:LoadIntoForm(first.ClassName)
    elseif self.State.selected then
        self:LoadIntoForm(self.State.selected)
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, COL_WINDOW_BG)
    surface.SetDrawColor(COL_RED)
    surface.DrawOutlinedRect(0, 0, w, h, 2)
end

vgui.Register("HordeWardenConfig", PANEL, "EditablePanel")

net.Receive("Horde_SyncWardenBuildableSource", function()
    local class = net.ReadString()
    local ok = net.ReadBool()
    local content = net.ReadString()
    local path = net.ReadString()

    if not IsValid(WardenCfgUpgradesModal) or WardenCfgUpgradesModal.lua_class ~= class then return end
    local box = WardenCfgUpgradesModal.lua_box
    if not IsValid(box) then return end

    if ok then
        box:SetText("-- " .. path .. "\n\n" .. content)
    else
        box:SetText("-- " .. content)
    end
end)

function OpenAddWardenBuildableModal(parent_panel, default_category)
    if not IsValid(parent_panel) then return end
    if IsValid(parent_panel.AddBuildableModal) then parent_panel.AddBuildableModal:Remove() end

    local overlay = vgui.Create("DButton", parent_panel)
    overlay:SetPos(0, 0)
    overlay:SetSize(parent_panel:GetWide(), parent_panel:GetTall())
    overlay:SetText("")
    parent_panel.AddBuildableModal = overlay
    function overlay:Paint(w, h)
        surface.SetDrawColor(0, 0, 0, 160)
        surface.DrawRect(0, 0, w, h)
    end
    overlay.DoClick = function() overlay:Remove() end

    local frame = vgui.Create("DPanel", overlay)
    frame:SetSize(420, 560)
    frame:Center()
    frame:SetMouseInputEnabled(true)
    frame.category = default_category or "support"
    frame.ctype = frame.category == "defense" and "damage_charges" or "lifetime"

    function frame:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, COL_WINDOW_BG)
        surface.SetDrawColor(COL_RED)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    local header = vgui.Create("DPanel", frame)
    header:Dock(TOP)
    header:SetTall(32)
    function header:Paint(w, h)
        draw.RoundedBoxEx(8, 0, 0, w, h, COL_RED, true, true, false, false)
        draw.SimpleText("Add New Warding Unit", "WCfg_Body", 14, h/2, COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local close_btn = vgui.Create("DButton", header)
    close_btn:SetText("")
    close_btn:SetSize(20, 20)
    function close_btn:PerformLayout() self:SetPos(header:GetWide() - 14 - 20, 6) end
    function close_btn:Paint(w, h)
        draw.SimpleText("r", "Marlett", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close_btn.DoClick = function() overlay:Remove() end

    local body = vgui.Create("DScrollPanel", frame)
    body:Dock(FILL)
    body:DockMargin(16, 12, 16, 12)
    StyleConfigScrollBar(body, 10)

    local e_class = MakeField(body, "Class Name (existing entity):")
    local e_name  = MakeField(body, "Print Name:")

    local cat_row = vgui.Create("DPanel", body)
    cat_row:Dock(TOP)
    cat_row:DockMargin(0, 0, 0, 6)
    cat_row:SetTall(38)
    cat_row:SetPaintBackground(false)

    local cat_label = vgui.Create("DLabel", cat_row)
    cat_label:Dock(TOP)
    cat_label:SetTall(16)
    cat_label:SetFont("WCfg_Small")
    cat_label:SetTextColor(COL_WHITE)
    cat_label:SetText("Category:")

    local cat_buttons_row = vgui.Create("DPanel", cat_row)
    cat_buttons_row:Dock(TOP)
    cat_buttons_row:SetTall(22)
    cat_buttons_row:SetPaintBackground(false)

    local cat_buttons = {}
    local function RefreshCatButtons()
        for cat, b in pairs(cat_buttons) do
            b.active = (frame.category == cat)
        end
    end
    local cx = 0
    for _, cat in ipairs(CATEGORY_ORDER) do
        local b = vgui.Create("DButton", cat_buttons_row)
        b:SetText("")
        surface.SetFont("WCfg_Small")
        local tw = surface.GetTextSize(CATEGORY_LABELS[cat])
        b:SetPos(cx, 0)
        b:SetSize(tw + 16, 22)
        cx = cx + tw + 16 + 6
        function b:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, self.active and COL_RED or COL_INPUT_BG)
            draw.SimpleText(CATEGORY_LABELS[cat], "WCfg_Small", w/2, h/2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function()
            frame.category = cat
            RefreshCatButtons()
        end
        cat_buttons[cat] = b
    end
    RefreshCatButtons()

    local ctype_row = vgui.Create("DPanel", body)
    ctype_row:Dock(TOP)
    ctype_row:DockMargin(0, 0, 0, 6)
    ctype_row:SetTall(38)
    ctype_row:SetPaintBackground(false)

    local ctype_label = vgui.Create("DLabel", ctype_row)
    ctype_label:Dock(TOP)
    ctype_label:SetTall(16)
    ctype_label:SetFont("WCfg_Small")
    ctype_label:SetTextColor(COL_WHITE)
    ctype_label:SetText("Consumable Type:")

    local ctype_buttons_row = vgui.Create("DPanel", ctype_row)
    ctype_buttons_row:Dock(TOP)
    ctype_buttons_row:SetTall(22)
    ctype_buttons_row:SetPaintBackground(false)

    local CTYPE_ORDER = { "lifetime", "damage_charges", "wave_limited" }
    local CTYPE_LABELS = { lifetime = "Lifetime", damage_charges = "Charges", wave_limited = "Wave" }
    local ctype_buttons = {}
    local function RefreshCtypeButtons()
        for ctype, b in pairs(ctype_buttons) do
            b.active = (frame.ctype == ctype)
        end
    end
    local ctx = 0
    for _, ctype in ipairs(CTYPE_ORDER) do
        local b = vgui.Create("DButton", ctype_buttons_row)
        b:SetText("")
        surface.SetFont("WCfg_Small")
        local tw = surface.GetTextSize(CTYPE_LABELS[ctype])
        b:SetPos(ctx, 0)
        b:SetSize(tw + 16, 22)
        ctx = ctx + tw + 16 + 6
        function b:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, self.active and COL_RED or COL_INPUT_BG)
            draw.SimpleText(CTYPE_LABELS[ctype], "WCfg_Small", w/2, h/2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function()
            frame.ctype = ctype
            RefreshCtypeButtons()
        end
        ctype_buttons[ctype] = b
    end
    RefreshCtypeButtons()

    local e_model = MakeField(body, "Model Path:")
    e_model:SetValue("models/props_combine/combine_light001a.mdl")
    local e_icon  = MakeField(body, "Icon Path (materials/...):")
    e_icon:SetValue("items/horde_watchtower.png")
    local e_cost   = MakeField(body, "Money Cost:")
    e_cost:SetValue("1000")
    local e_limit  = MakeField(body, "Build Limit:")
    e_limit:SetValue("1")
    local e_deploy = MakeField(body, "Deploy Time (sec):")
    e_deploy:SetValue("20")
    local e_lifetime = MakeField(body, "Lifetime (sec, if Consumable=Lifetime):")
    e_lifetime:SetValue("300")
    local e_charges = MakeField(body, "Damage Charges (if Consumable=Charges):")
    e_charges:SetValue("50")
    local e_damage = MakeField(body, "Damage (Defense only, blank = N/A):")
    local e_firerate = MakeField(body, "Fire Rate hits/sec (Defense only):")
    e_firerate:SetValue("1")
    local e_dmgtype = MakeField(body, "Damage Type (Defense only):")
    e_dmgtype:SetValue("BULLET")

    local note = vgui.Create("DLabel", body)
    note:Dock(TOP)
    note:DockMargin(0, 4, 0, 0)
    note:SetTall(50)
    note:SetFont("WCfg_Small")
    note:SetTextColor(Color(160, 160, 160))
    note:SetWrap(true)
    note:SetText("Class Name must be an entity that already exists in the game (this tool does not write new Lua code) — it just registers it as a Warden buildable. Damage/Fire Rate/Damage Type only apply if Category=Defense. Infusions can be configured afterwards.")

    local create_btn = vgui.Create("DButton", frame)
    create_btn:Dock(BOTTOM)
    create_btn:SetTall(34)
    create_btn:DockMargin(16, 0, 16, 12)
    create_btn:SetText("")
    function create_btn:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(240,50,76) or COL_RED)
        draw.SimpleText("Create", "WCfg_Body", w/2, h/2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    create_btn.DoClick = function()
        local class = string.Trim(e_class:GetValue() or "")
        if class == "" then
            Derma_Message("Class Name can't be empty.", "Add New Warding Unit", "OK")
            return
        end

        net.Start("Horde_AddWardenBuildable")
            net.WriteString(class)
            net.WriteTable({
                PrintName     = e_name:GetValue(),
                Category      = frame.category,
                ConsumableType = frame.ctype,
                Model         = e_model:GetValue(),
                Icon          = e_icon:GetValue(),
                Cost          = tonumber(e_cost:GetValue()),
                Limit         = tonumber(e_limit:GetValue()),
                DeployTime    = tonumber(e_deploy:GetValue()),
                Lifetime      = tonumber(e_lifetime:GetValue()),
                DamageCharges = tonumber(e_charges:GetValue()),
                Damage        = tonumber(e_damage:GetValue()),
                FireRate      = tonumber(e_firerate:GetValue()),
                DamageType    = e_dmgtype:GetValue(),
            })
        net.SendToServer()

        overlay:Remove()
        if IsValid(parent_panel) then
            parent_panel.State.tab = frame.category
            timer.Simple(0.15, function()
                if IsValid(parent_panel) then parent_panel:RebuildGrid() end
            end)
        end
    end
end

function OpenWardenUpgradesModal(parent_panel, class)
    if not IsValid(parent_panel) then return end
    if IsValid(parent_panel.UpgradesModal) then parent_panel.UpgradesModal:Remove() end

    local overlay = vgui.Create("DButton", parent_panel)
    overlay:SetPos(0, 0)
    overlay:SetSize(parent_panel:GetWide(), parent_panel:GetTall())
    overlay:SetText("")
    parent_panel.UpgradesModal = overlay
    function overlay:Paint(w, h)
        surface.SetDrawColor(0, 0, 0, 160)
        surface.DrawRect(0, 0, w, h)
    end
    overlay.DoClick = function() overlay:Remove() end

    local frame = vgui.Create("DPanel", overlay)
    WardenCfgUpgradesModal = frame
    frame:SetSize(560, 480)
    frame:Center()
    frame:SetMouseInputEnabled(true)
    frame.tab = "lvl5"

    function frame:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, COL_WINDOW_BG)
        surface.SetDrawColor(COL_RED)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    local header = vgui.Create("DPanel", frame)
    header:Dock(TOP)
    header:SetTall(32)
    function header:Paint(w, h)
        draw.RoundedBoxEx(8, 0, 0, w, h, COL_RED, true, true, false, false)
        draw.SimpleText("Unit Upgrades Config", "WCfg_Body", 14, h/2, COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local close_btn = vgui.Create("DButton", header)
    close_btn:SetText("")
    close_btn:SetSize(20, 20)
    function close_btn:PerformLayout() self:SetPos(header:GetWide() - 14 - 20, 6) end
    function close_btn:Paint(w, h)
        draw.SimpleText("r", "Marlett", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close_btn.DoClick = function() overlay:Remove() end

    local body = vgui.Create("DPanel", frame)
    body:Dock(FILL)
    body:DockMargin(16, 12, 16, 12)
    body:SetPaintBackground(false)

    local tabs_row = vgui.Create("DPanel", body)
    tabs_row:Dock(TOP)
    tabs_row:SetTall(24)
    tabs_row:SetPaintBackground(false)

    local pane_lvl5 = vgui.Create("DPanel", body)
    pane_lvl5:Dock(FILL)
    pane_lvl5:SetPaintBackground(false)

    local pane_lvl10 = vgui.Create("DPanel", body)
    pane_lvl10:Dock(FILL)
    pane_lvl10:SetPaintBackground(false)
    pane_lvl10:SetVisible(false)

    local pane_lua = vgui.Create("DPanel", body)
    pane_lua:Dock(FILL)
    pane_lua:SetPaintBackground(false)
    pane_lua:SetVisible(false)

    local function MakeTabBtn(label, key, x)
        local btn = vgui.Create("DButton", tabs_row)
        btn:SetText("")
        surface.SetFont("WCfg_Body")
        local tw = surface.GetTextSize(label)
        btn:SetPos(x, 0)
        btn:SetSize(tw + 4, 24)
        function btn:Paint(w, h)
            local col = frame.tab == key and COL_RED_TEXT or COL_WHITE
            draw.SimpleText(label, "WCfg_Body", 0, h/2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function()
            frame.tab = key
            pane_lvl5:SetVisible(key == "lvl5")
            pane_lvl10:SetVisible(key == "lvl10")
            pane_lua:SetVisible(key == "lua")
        end
        return tw
    end
    local w1 = MakeTabBtn("Level 5", "lvl5", 0)
    local w2 = MakeTabBtn("Level 10", "lvl10", w1 + 24)
    MakeTabBtn("Lua", "lua", w1 + 24 + w2 + 24)

    local override = HORDE.WardenBuildableOverrides[class] or {}
    local ctype = HORDE:Horde_GetWardenBuildableConsumableType(class)
    local has_combat = isnumber(HORDE:Horde_GetWardenBuildableDamage(class))

    local function DefaultAtLevel(field, level)
        return HORDE:Horde_GetWardenBuildableBonus(class, field) * level
    end

    local function MakeBonusRow(parent, label, field_key, suffix, default_val)
        local row = vgui.Create("DPanel", parent)
        row:Dock(TOP)
        row:SetTall(30)
        row:DockMargin(0, 4, 0, 0)
        row:SetPaintBackground(false)

        local lbl = vgui.Create("DLabel", row)
        lbl:Dock(LEFT)
        lbl:SetWide(150)
        lbl:SetFont("WCfg_Body")
        lbl:SetTextColor(COL_WHITE)
        lbl:SetText(label)

        local plus = vgui.Create("DLabel", row)
        plus:Dock(LEFT)
        plus:SetWide(14)
        plus:SetFont("WCfg_Body")
        plus:SetTextColor(COL_RED_TEXT)
        plus:SetText("+")

        local entry = vgui.Create("DTextEntry", row)
        entry:Dock(LEFT)
        entry:SetWide(90)
        entry:SetFont("WCfg_Small")
        local val = override[field_key]
        if val == nil then val = default_val end
        entry:SetValue(tostring(val or 0))
        entry.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, COL_INPUT_BG)
            self:DrawTextEntryText(COL_WHITE, Color(150,170,255), COL_WHITE)
        end

        local suf = vgui.Create("DLabel", row)
        suf:Dock(LEFT)
        suf:DockMargin(6, 0, 0, 0)
        suf:SetWide(80)
        suf:SetFont("WCfg_Small")
        suf:SetTextColor(Color(150,150,150))
        suf:SetText(suffix)

        return entry
    end

    local e5_lifetime, e5_charges, e5_damage, e5_speed
    if ctype == "lifetime" then
        e5_lifetime = MakeBonusRow(pane_lvl5, "Lifetime Bonus:", "Lvl5_Bonus_Lifetime", "sec total", override.Lvl5_Bonus_Lifetime or DefaultAtLevel("Bonus_Lifetime", 5))
    elseif ctype == "damage_charges" then
        e5_charges = MakeBonusRow(pane_lvl5, "Charges Bonus:", "Lvl5_Bonus_DamageCharges", "charges total", override.Lvl5_Bonus_DamageCharges or DefaultAtLevel("Bonus_DamageCharges", 5))
    end
    if has_combat then
        e5_damage = MakeBonusRow(pane_lvl5, "Damage Bonus:", "Lvl5_Bonus_Damage", "DMG total", override.Lvl5_Bonus_Damage or DefaultAtLevel("Bonus_Damage", 5))
        e5_speed  = MakeBonusRow(pane_lvl5, "Fire Rate Bonus:", "Lvl5_Bonus_FireRate", "hits/sec total", override.Lvl5_Bonus_FireRate or DefaultAtLevel("Bonus_FireRate", 5))
    end

    local note5 = vgui.Create("DLabel", pane_lvl5)
    note5:Dock(TOP)
    note5:DockMargin(0, 10, 0, 0)
    note5:SetTall(40)
    note5:SetFont("WCfg_Small")
    note5:SetTextColor(Color(160, 160, 160))
    note5:SetWrap(true)
    note5:SetText("Total bonuses at Level 5. Levels 1-4 are filled automatically (linear from 0).")

    local e10_lifetime, e10_charges, e10_damage, e10_speed
    if ctype == "lifetime" then
        e10_lifetime = MakeBonusRow(pane_lvl10, "Lifetime Bonus:", "Lvl10_Bonus_Lifetime", "sec total", override.Lvl10_Bonus_Lifetime or DefaultAtLevel("Bonus_Lifetime", 10))
    elseif ctype == "damage_charges" then
        e10_charges = MakeBonusRow(pane_lvl10, "Charges Bonus:", "Lvl10_Bonus_DamageCharges", "charges total", override.Lvl10_Bonus_DamageCharges or DefaultAtLevel("Bonus_DamageCharges", 10))
    end
    if has_combat then
        e10_damage = MakeBonusRow(pane_lvl10, "Damage Bonus:", "Lvl10_Bonus_Damage", "DMG total", override.Lvl10_Bonus_Damage or DefaultAtLevel("Bonus_Damage", 10))
        e10_speed  = MakeBonusRow(pane_lvl10, "Fire Rate Bonus:", "Lvl10_Bonus_FireRate", "hits/sec total", override.Lvl10_Bonus_FireRate or DefaultAtLevel("Bonus_FireRate", 10))
    end

    local note10 = vgui.Create("DLabel", pane_lvl10)
    note10:Dock(TOP)
    note10:DockMargin(0, 10, 0, 0)
    note10:SetTall(40)
    note10:SetFont("WCfg_Small")
    note10:SetTextColor(Color(160, 160, 160))
    note10:SetWrap(true)
    note10:SetText("Total bonuses at Level 10 (max). Levels 6-9 interpolate between Level 5 and Level 10.")

    local e_up_pct = MakeBonusRow(pane_lvl5, "Upgrade Cost:", "UpgradePricePercent", "% of Money", math.floor((override.UpgradePricePercent or HORDE:Horde_GetWardenBuildableUpgradePricePercent(class) or 0.10) * 100))

    local note_pct = vgui.Create("DLabel", pane_lvl5)
    note_pct:Dock(TOP)
    note_pct:DockMargin(0, 4, 0, 0)
    note_pct:SetTall(30)
    note_pct:SetFont("WCfg_Small")
    note_pct:SetTextColor(Color(160, 160, 160))
    note_pct:SetWrap(true)
    note_pct:SetText("Each Upgrade+1 costs this % of the player's CURRENT Money (not a fixed amount).")

    local lua_box = vgui.Create("DTextEntry", pane_lua)
    lua_box:Dock(FILL)
    lua_box:SetMultiline(true)
    lua_box:SetEnabled(false)
    lua_box:SetFont("DermaDefault")
    lua_box.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(11, 12, 14))
        self:DrawTextEntryText(Color(201, 209, 217), Color(80,80,80), Color(201,209,217))
    end

    frame.lua_class = class
    frame.lua_box = lua_box
    lua_box:SetText("Loading " .. class .. "...")

    net.Start("Horde_RequestWardenBuildableSource")
        net.WriteString(class)
    net.SendToServer()

    local save_btn = vgui.Create("DButton", body)
    save_btn:Dock(BOTTOM)
    save_btn:SetTall(30)
    save_btn:DockMargin(0, 8, 0, 0)
    save_btn:SetText("")
    function save_btn:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(184,50,239) or COL_PURPLE)
        draw.SimpleText("Save Changes", "WCfg_Body", w/2, h/2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    save_btn.DoClick = function()
        local existing = HORDE.WardenBuildableOverrides[class] or {}
        if e5_lifetime then existing.Lvl5_Bonus_Lifetime = tonumber(e5_lifetime:GetValue()) or 0 end
        if e5_charges  then existing.Lvl5_Bonus_DamageCharges = tonumber(e5_charges:GetValue()) or 0 end
        if e5_damage   then existing.Lvl5_Bonus_Damage = tonumber(e5_damage:GetValue()) or 0 end
        if e5_speed    then existing.Lvl5_Bonus_FireRate = tonumber(e5_speed:GetValue()) or 0 end
        if e10_lifetime then existing.Lvl10_Bonus_Lifetime = tonumber(e10_lifetime:GetValue()) or 0 end
        if e10_charges  then existing.Lvl10_Bonus_DamageCharges = tonumber(e10_charges:GetValue()) or 0 end
        if e10_damage   then existing.Lvl10_Bonus_Damage = tonumber(e10_damage:GetValue()) or 0 end
        if e10_speed    then existing.Lvl10_Bonus_FireRate = tonumber(e10_speed:GetValue()) or 0 end
        local pct_ui = tonumber(e_up_pct:GetValue()) or 10
        existing.UpgradePricePercent = math.Clamp(pct_ui / 100, 0.01, 1)
        HORDE.WardenBuildableOverrides[class] = existing

        net.Start("Horde_SetWardenConfigData")
            net.WriteString(class)
            net.WriteTable(existing)
        net.SendToServer()
        overlay:Remove()
    end
end

function OpenWardenInfusionsPoolModal(parent_panel, class)
    if not IsValid(parent_panel) then return end
    if IsValid(parent_panel.InfusionsModal) then parent_panel.InfusionsModal:Remove() end

    local overlay = vgui.Create("DButton", parent_panel)
    overlay:SetPos(0, 0)
    overlay:SetSize(parent_panel:GetWide(), parent_panel:GetTall())
    overlay:SetText("")
    parent_panel.InfusionsModal = overlay
    function overlay:Paint(w, h)
        surface.SetDrawColor(0, 0, 0, 160)
        surface.DrawRect(0, 0, w, h)
    end
    overlay.DoClick = function() overlay:Remove() end

    local frame = vgui.Create("DPanel", overlay)
    frame:SetSize(560, 340)
    frame:Center()
    frame:SetMouseInputEnabled(true)

    local existing = HORDE.WardenBuildableOverrides[class] or {}
    local pool = {}
    if existing.InfusionPool then
        for _, id in ipairs(existing.InfusionPool) do pool[id] = true end
    else
        for id in pairs(HORDE.Infusion_Names) do
            if id ~= HORDE.Infusion_None then pool[id] = true end
        end
    end
    frame.selected = nil

    function frame:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, COL_WINDOW_BG)
        surface.SetDrawColor(COL_RED)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    local header = vgui.Create("DPanel", frame)
    header:Dock(TOP)
    header:SetTall(32)
    function header:Paint(w, h)
        draw.RoundedBoxEx(8, 0, 0, w, h, COL_RED, true, true, false, false)
        draw.SimpleText("Unit Infusions Pool", "WCfg_Body", 14, h/2, COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local close_btn = vgui.Create("DButton", header)
    close_btn:SetText("")
    close_btn:SetSize(20, 20)
    function close_btn:PerformLayout() self:SetPos(header:GetWide() - 14 - 20, 6) end
    function close_btn:Paint(w, h)
        draw.SimpleText("r", "Marlett", w / 2, h / 2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close_btn.DoClick = function() overlay:Remove() end

    local body = vgui.Create("DPanel", frame)
    body:Dock(FILL)
    body:DockMargin(16, 12, 16, 12)
    body:SetPaintBackground(false)

    local grid_scroll = vgui.Create("DScrollPanel", body)
    grid_scroll:Dock(LEFT)
    grid_scroll:SetWide(248)
    StyleConfigScrollBar(grid_scroll, 10)

    local right_col = vgui.Create("DPanel", body)
    right_col:Dock(FILL)
    right_col:DockMargin(10, 0, 0, 0)
    right_col:SetPaintBackground(false)

    local inf_name = vgui.Create("DLabel", right_col)
    inf_name:Dock(TOP)
    inf_name:SetTall(24)
    inf_name:SetFont("Trebuchet24")
    inf_name:SetTextColor(COL_RED_TEXT)

    local inf_desc = vgui.Create("DLabel", right_col)
    inf_desc:Dock(TOP)
    inf_desc:SetTall(140)
    inf_desc:SetFont("WCfg_Small")
    inf_desc:SetTextColor(COL_WHITE)
    inf_desc:SetWrap(true)

    local toggle_btn = vgui.Create("DButton", right_col)
    toggle_btn:Dock(BOTTOM)
    toggle_btn:SetTall(30)
    toggle_btn:SetText("")

    local canvas = vgui.Create("DPanel", grid_scroll)
    canvas:SetPaintBackground(false)
    canvas:SetWide(248 - 16)

    local ids = {}
    for id in pairs(HORDE.Infusion_Names) do
        if id ~= HORDE.Infusion_None then table.insert(ids, id) end
    end
    table.sort(ids, function(a, b) return HORDE.Infusion_Names[a] < HORDE.Infusion_Names[b] end)

    local per_row, size, gap = 3, 72, 8
    canvas:SetTall(math.ceil(#ids / per_row) * (size + gap))

    local function RefreshToggleBtn()
        local id = frame.selected
        if not id then toggle_btn:SetVisible(false) return end
        toggle_btn:SetVisible(true)
        local in_pool = pool[id] == true
        function toggle_btn:Paint(w, h)
            draw.RoundedBox(6, 0, 0, w, h, in_pool and COL_RED or Color(80, 180, 90))
            draw.SimpleText(in_pool and "Remove from Pool" or "Add to Pool", "WCfg_Body", w/2, h/2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    local function SelectInfusion(id)
        frame.selected = id
        inf_name:SetText(HORDE.Infusion_Names[id] or "?")
        inf_desc:SetText(HORDE.Infusion_Description[id] or "")
        RefreshToggleBtn()
    end

    for i, id in ipairs(ids) do
        local col = (i - 1) % per_row
        local row = math.floor((i - 1) / per_row)
        local card = vgui.Create("DButton", canvas)
        card:SetText("")
        card:SetPos(col * (size + gap), row * (size + gap))
        card:SetSize(size, size)
        function card:Paint(w, h)
            local bg = pool[id] and COL_CARD or Color(40, 40, 42)
            if frame.selected == id then bg = COL_RED end
            draw.RoundedBox(6, 0, 0, w, h, bg)
            local icon = HORDE.Infusion_Icons[id]
            if icon then
                surface.SetMaterial(Material(icon))
                surface.SetDrawColor(255, 255, 255, pool[id] and 255 or 120)
                surface.DrawTexturedRect(w/2 - 18, h/2 - 18, 36, 36)
            end
            if pool[id] then
                draw.RoundedBox(3, w - 16, 4, 12, 10, COL_RED)
            end
        end
        card.DoClick = function() SelectInfusion(id) end
    end

    toggle_btn.DoClick = function()
        local id = frame.selected
        if not id then return end
        pool[id] = not pool[id] or nil
        RefreshToggleBtn()
    end

    SelectInfusion(ids[1])

    local save_btn = vgui.Create("DButton", body)
    save_btn:Dock(BOTTOM)
    save_btn:SetTall(30)
    save_btn:DockMargin(0, 8, 0, 0)
    save_btn:SetText("")
    function save_btn:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(184,50,239) or COL_PURPLE)
        draw.SimpleText("Save Changes", "WCfg_Body", w/2, h/2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    save_btn.DoClick = function()
        local list = {}
        local all_selected = true
        for _, id in ipairs(ids) do
            if pool[id] then table.insert(list, id) else all_selected = false end
        end
        local existing2 = HORDE.WardenBuildableOverrides[class] or {}
        existing2.InfusionPool = all_selected and nil or list
        HORDE.WardenBuildableOverrides[class] = existing2

        net.Start("Horde_SetWardenConfigData")
            net.WriteString(class)
            net.WriteTable(existing2)
        net.SendToServer()
        overlay:Remove()
    end
end
