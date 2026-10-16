if not CLIENT then return end

surface.CreateFont("HM_Title",  {font = "Trebuchet MS",        size = 24, weight = 700})
surface.CreateFont("HM_Header", {font = "Trebuchet MS",        size = 22, weight = 700})
surface.CreateFont("HM_Body",   {font = "CloseCaption_Normal", size = 18, weight = 500})
surface.CreateFont("HM_Small",  {font = "CloseCaption_Normal", size = 15, weight = 500})

local RED      = Color(220, 30,  56)
local RED_H    = Color(240, 50,  76)
local RED_DARK = Color(150, 20,  40)
local WIN      = Color(31,  31,  31)
local CARD     = Color(60,  64,  70)
local CARD_H   = Color(72,  77,  84)
local BTN      = Color(66,  70,  78)
local BTN_H    = Color(80,  85,  94)
local TRACK    = Color(24,  25,  28)
local WH       = Color(255, 255, 255)
local DIM      = Color(150, 152, 158)

local function StyleScroll(scroll)
    local vb = scroll:GetVBar()
    vb:SetWide(8)
    vb:SetHideButtons(true)
    vb.Paint = function(_, w, h)
        draw.RoundedBox(4, 0, 0, w, h, TRACK)
    end
    vb.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and RED_H or RED)
    end
    vb.btnUp.Paint   = function() end
    vb.btnDown.Paint = function() end
end

local function StyledEntry(ent, placeholder)
    ent:SetFont("HM_Body")
    function ent:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, BTN)
        self:DrawTextEntryText(WH, RED, WH)
        if placeholder and self:GetValue() == "" then
            draw.SimpleText(placeholder, "HM_Body", 8, h / 2, DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end

local function FlatButton(parent, label, x, y, w, h, col, colHover, cb)
    local b = vgui.Create("DButton", parent)
    b:SetPos(x, y)
    b:SetSize(w, h)
    b:SetText("")
    b.Paint = function(s, bw, bh)
        draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and colHover or col)
        draw.SimpleText(label, "HM_Body", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.DoClick = cb
    return b
end

local function Modal(parent, w, h, title)
    local ovl = vgui.Create("DButton", parent)
    ovl:SetText("")
    ovl:SetSize(parent:GetWide(), parent:GetTall())
    ovl:SetPos(0, 0)
    ovl:MoveToFront()
    ovl.Paint = function(_, pw, ph)
        draw.RoundedBox(8, 0, 0, pw, ph, Color(0, 0, 0, 180))
    end
    ovl.DoClick = function() end

    local box = vgui.Create("DPanel", ovl)
    box:SetSize(w, h)
    box:Center()
    box:SetMouseInputEnabled(true)
    box.Paint = function(_, bw, bh)
        draw.RoundedBox(8, 0, 0, bw, bh, RED)
        draw.RoundedBox(6, 2, 2, bw - 4, bh - 4, WIN)
        draw.RoundedBoxEx(8, 0, 0, bw, 36, RED, true, true, false, false)
        draw.SimpleText(title, "HM_Header", 14, 18, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local xb = vgui.Create("DButton", box)
    xb:SetText("")
    xb:SetSize(28, 28)
    xb:SetPos(w - 32, 4)
    xb.Paint = function(s, bw, bh)
        draw.SimpleText("r", "Marlett", bw / 2, bh / 2, s:IsHovered() and DIM or WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    xb.DoClick = function() ovl:Remove() end

    return ovl, box
end

local PANEL = {}

function PANEL:Init()
    local sw, sh = ScrW(), ScrH()
    local w = math.Clamp(math.floor(sw * 0.25), 360, 440)
    local h = math.Clamp(math.floor(sh * 0.68), 540, 680)

    self:SetSize(w, h)
    self:SetPos((sw - w) / 2, (sh - h) / 2)
    self:MakePopup()

    self.activeTab    = "whitelist"
    self.selectedMap  = nil
    self.search       = ""
    self.debounceT    = 0
    self.lastWCount   = -1
    self.lastBCount   = -1

    self:_BuildUI()
    self:Refresh()
end

function PANEL:_BuildUI()
    local w, h = self:GetWide(), self:GetTall()
    local M = 12
    local cw = w - M * 2

    local q_btn = vgui.Create("DButton", self)
    q_btn:SetSize(28, 28)
    q_btn:SetPos(w - M - 28 - 32, 8)
    q_btn:SetText("")
    q_btn:SetTooltip("Wiki Guide")
    q_btn.Paint = function(s, bw, bh)
        draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and BTN_H or BTN)
        draw.SimpleText("?", "HM_Header", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    q_btn.DoClick = function() gui.OpenURL("https://github.com/tpan496/Horde/wiki/Map-Config") end

    local close_btn = vgui.Create("DButton", self)
    close_btn:SetSize(28, 28)
    close_btn:SetPos(w - M - 28, 8)
    close_btn:SetText("")
    close_btn.Paint = function(s, bw, bh)
        draw.RoundedBox(6, 0, 0, bw, bh, s:IsHovered() and RED or BTN)
        draw.SimpleText("r", "Marlett", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    close_btn.DoClick = function() HORDE:ToggleMapConfig() end

    local tabY = 40
    local tabW = math.floor((cw - 10) / 2)
    local tabH = 36

    local btnWL = vgui.Create("DButton", self)
    btnWL:SetPos(M, tabY)
    btnWL:SetSize(tabW, tabH)
    btnWL:SetText("")
    btnWL.Paint = function(s, bw, bh)
        local act = (self.activeTab == "whitelist")
        draw.RoundedBox(6, 0, 0, bw, bh, act and RED or (s:IsHovered() and BTN_H or BTN))
        draw.SimpleText("Whitelist", "HM_Body", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnWL.DoClick = function()
        if self.activeTab ~= "whitelist" then
            self.activeTab   = "whitelist"
            self.selectedMap = nil
            self:Refresh()
        end
    end
    self.tabWL = btnWL

    local btnBL = vgui.Create("DButton", self)
    btnBL:SetPos(M + tabW + 10, tabY)
    btnBL:SetSize(tabW, tabH)
    btnBL:SetText("")
    btnBL.Paint = function(s, bw, bh)
        local act = (self.activeTab == "blacklist")
        draw.RoundedBox(6, 0, 0, bw, bh, act and RED or (s:IsHovered() and BTN_H or BTN))
        draw.SimpleText("Blacklist", "HM_Body", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnBL.DoClick = function()
        if self.activeTab ~= "blacklist" then
            self.activeTab   = "blacklist"
            self.selectedMap = nil
            self:Refresh()
        end
    end
    self.tabBL = btnBL

    local bannerY = tabY + tabH + 8
    local bannerH = 34
    local banner = vgui.Create("DPanel", self)
    banner:SetPos(M, bannerY)
    banner:SetSize(cw, bannerH)
    banner.Paint = function(_, bw, bh)
        draw.RoundedBox(4, 0, 0, bw, bh, RED)
        draw.SimpleText("Current list", "HM_Header", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local btnGridH = 36 * 2 + 8
    local searchH  = 32
    local bottomTotalH = searchH + 10 + btnGridH
    local bottomY = h - M - bottomTotalH

    local srch = vgui.Create("DTextEntry", self)
    srch:SetPos(M, bottomY)
    srch:SetSize(cw, searchH)
    StyledEntry(srch, "Search...")
    srch.OnChange = function(s)
        local q = string.lower(s:GetValue() or "")
        if q ~= self.search then
            self.search    = q
            self.debounceT = CurTime() + 0.15
        end
    end
    self.searchEntry = srch

    local bY1 = bottomY + searchH + 10
    local bY2 = bY1 + 36 + 8
    local halfW = math.floor((cw - 10) / 2)

    FlatButton(self, "Add", M, bY1, halfW, 36, BTN, BTN_H, function()
        self:OpenAddMapModal()
    end)

    FlatButton(self, "Delete", M + halfW + 10, bY1, halfW, 36, BTN, RED_DARK, function()
        self:DoDeleteSelected()
    end)

    FlatButton(self, "Delete All", M, bY2, halfW, 36, BTN, RED_DARK, function()
        self:DoDeleteAll()
    end)

    FlatButton(self, "Move to", M + halfW + 10, bY2, halfW, 36, BTN, BTN_H, function()
        self:OpenMoveToModal()
    end)

    local listY = bannerY + bannerH + 8
    local listH = bottomY - listY - 8

    local scroll = vgui.Create("DScrollPanel", self)
    scroll:SetPos(M, listY)
    scroll:SetSize(cw, listH)
    StyleScroll(scroll)
    self.scroll = scroll

    local list = vgui.Create("DPanel", scroll)
    list:SetSize(cw - 10, 10)
    list.Paint = function() end
    self.listPanel = list
end

function PANEL:Refresh()
    if not IsValid(self.listPanel) then return end
    local lp = self.listPanel
    lp:Clear()

    local mapTable = (self.activeTab == "whitelist") and HORDE.map_whitelist or HORDE.map_blacklist
    mapTable = mapTable or {}

    self.lastWCount = table.Count(HORDE.map_whitelist or {})
    self.lastBCount = table.Count(HORDE.map_blacklist or {})

    local maps = {}
    for _, map in pairs(mapTable) do
        if self.search == "" or string.find(string.lower(map), self.search, 1, true) then
            table.insert(maps, map)
        end
    end
    table.sort(maps)

    local w = lp:GetWide()
    local itemH = 34
    local gap = 6
    local curY = 0

    for _, map in ipairs(maps) do
        local btn = vgui.Create("DButton", lp)
        btn:SetPos(0, curY)
        btn:SetSize(w, itemH)
        btn:SetText("")
        btn._map = map

        btn.Paint = function(s, bw, bh)
            local sel = (self.selectedMap == map)
            draw.RoundedBox(6, 0, 0, bw, bh, sel and RED or (s:IsHovered() and CARD_H or CARD))
            draw.SimpleText(map, "HM_Body", bw / 2, bh / 2, WH, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        btn.DoClick = function()
            self.selectedMap = (self.selectedMap == map) and nil or map
        end

        btn.DoRightClick = function()
            self.selectedMap = map
            local m = DermaMenu()
            m:AddOption("Move to...", function()
                self:OpenMoveToModal()
            end)
            m:AddSpacer()
            local del = m:AddOption("Delete", function()
                self:DoDeleteSelected()
            end)
            del:SetIcon("icon16/delete.png")
            m:Open()
        end

        curY = curY + itemH + gap
    end

    lp:SetTall(math.max(curY, self.scroll:GetTall()))
end

function PANEL:SaveWhitelist()
    net.Start("Horde_SetMapsWhitelistData")
        net.WriteTable(HORDE.map_whitelist or {})
    net.SendToServer()
    HORDE:PlayNotification("Your changes have been saved.")
end

function PANEL:SaveBlacklist()
    net.Start("Horde_SetMapsBlacklistData")
        net.WriteTable(HORDE.map_blacklist or {})
    net.SendToServer()
    HORDE:PlayNotification("Your changes have been saved.")
end

function PANEL:OpenMoveToModal()
    if not self.selectedMap or self.selectedMap == "" then
        notification.AddLegacy("Select a map from the list first!", NOTIFY_ERROR, 3)
        return
    end

    local map = self.selectedMap
    local ovl, box = Modal(self, 340, 160, "Move Map")

    local prompt = vgui.Create("DLabel", box)
    prompt:SetPos(16, 46)
    prompt:SetSize(box:GetWide() - 32, 24)
    prompt:SetFont("HM_Body")
    prompt:SetTextColor(WH)
    prompt:SetText("Move '" .. map .. "' to:")

    local btnW = (box:GetWide() - 32 - 10) / 2
    local btnY = 86

    FlatButton(box, "Whitelist", 16, btnY, btnW, 36, BTN, BTN_H, function()
        HORDE.map_blacklist[map] = nil
        HORDE.map_whitelist[map] = map
        self:SaveBlacklist()
        self:SaveWhitelist()
        self.selectedMap = map
        ovl:Remove()
        self:Refresh()
    end)

    FlatButton(box, "Blacklist", 16 + btnW + 10, btnY, btnW, 36, BTN, BTN_H, function()
        HORDE.map_whitelist[map] = nil
        HORDE.map_blacklist[map] = map
        self:SaveWhitelist()
        self:SaveBlacklist()
        self.selectedMap = map
        ovl:Remove()
        self:Refresh()
    end)
end

function PANEL:OpenAddMapModal()
    local targetName = (self.activeTab == "whitelist") and "Whitelist" or "Blacklist"
    local ovl, box = Modal(self, math.min(380, self:GetWide() - 20), 460, "Add Map to " .. targetName)

    local bw = box:GetWide()
    local bh = box:GetTall()

    local entry = vgui.Create("DTextEntry", box)
    entry:SetPos(14, 46)
    entry:SetSize(bw - 28, 32)
    StyledEntry(entry, "Search or enter map name...")

    local sY = 86
    local sH = bh - sY - 54

    local sScroll = vgui.Create("DScrollPanel", box)
    sScroll:SetPos(14, sY)
    sScroll:SetSize(bw - 28, sH)
    StyleScroll(sScroll)

    local sList = vgui.Create("DPanel", sScroll)
    sList:SetSize(bw - 28 - 10, 10)
    sList.Paint = function() end

    local allMaps = {}
    local synced = HORDE.installed_maps
    if istable(synced) and #synced > 0 then
        for _, mName in ipairs(synced) do
            allMaps[#allMaps + 1] = mName
        end
    else
        local found = file.Find("maps/*.bsp", "GAME")
        for _, f in ipairs(found) do
            if string.sub(f, -4) == ".bsp" then
                table.insert(allMaps, string.sub(f, 1, -5))
            end
        end
    end
    table.sort(allMaps)

    local function Populate(filter)
        sList:Clear()
        filter = string.lower(filter or "")
        local curY = 0
        local itemW = sList:GetWide()

        for _, mName in ipairs(allMaps) do
            if filter == "" or string.find(string.lower(mName), filter, 1, true) then
                local b = vgui.Create("DButton", sList)
                b:SetPos(0, curY)
                b:SetSize(itemW, 30)
                b:SetText("")
                b.Paint = function(s, iw, ih)
                    local isCur = (entry:GetValue() == mName)
                    draw.RoundedBox(4, 0, 0, iw, ih, isCur and RED or (s:IsHovered() and CARD_H or CARD))
                    draw.SimpleText(mName, "HM_Body", 8, ih / 2, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                b.DoClick = function()
                    entry:SetValue(mName)
                end
                curY = curY + 30 + 4
            end
        end
        sList:SetTall(math.max(curY, sScroll:GetTall()))
    end

    Populate("")

    entry.OnChange = function(s)
        Populate(s:GetValue())
    end

    local btnW = (bw - 28 - 10) / 2
    local by = bh - 44

    FlatButton(box, "Add Map", 14, by, btnW, 34, RED, RED_H, function()
        local mapToAdd = string.Trim(entry:GetValue() or "")
        if mapToAdd == "" then
            notification.AddLegacy("Enter or pick a map name!", NOTIFY_ERROR, 3)
            return
        end

        if self.activeTab == "whitelist" then
            HORDE.map_whitelist = HORDE.map_whitelist or {}
            HORDE.map_whitelist[mapToAdd] = mapToAdd
            self:SaveWhitelist()
        else
            HORDE.map_blacklist = HORDE.map_blacklist or {}
            HORDE.map_blacklist[mapToAdd] = mapToAdd
            self:SaveBlacklist()
        end

        self.selectedMap = mapToAdd
        ovl:Remove()
        self:Refresh()
    end)

    FlatButton(box, "Cancel", 14 + btnW + 10, by, btnW, 34, BTN, BTN_H, function()
        ovl:Remove()
    end)
end

function PANEL:DoDeleteSelected()
    if not self.selectedMap or self.selectedMap == "" then
        notification.AddLegacy("Select a map to delete!", NOTIFY_ERROR, 3)
        return
    end

    local map = self.selectedMap
    local target = self.activeTab

    Derma_Query("Delete '" .. map .. "' from " .. target .. "?", "Confirm Delete",
        "Delete", function()
            if target == "whitelist" then
                HORDE.map_whitelist[map] = nil
                self:SaveWhitelist()
            else
                HORDE.map_blacklist[map] = nil
                self:SaveBlacklist()
            end
            self.selectedMap = nil
            self:Refresh()
        end,
        "Cancel", function() end
    )
end

function PANEL:DoDeleteAll()
    local target = self.activeTab

    Derma_Query("Delete ALL maps from " .. target .. "?", "Confirm Delete All",
        "Delete All", function()
            if target == "whitelist" then
                HORDE.map_whitelist = {}
                self:SaveWhitelist()
            else
                HORDE.map_blacklist = {}
                self:SaveBlacklist()
            end
            self.selectedMap = nil
            self:Refresh()
        end,
        "Cancel", function() end
    )
end

function PANEL:Think()
    if self.debounceT ~= 0 and CurTime() > self.debounceT then
        self.debounceT = 0
        self:Refresh()
    end

    local wc = table.Count(HORDE.map_whitelist or {})
    local bc = table.Count(HORDE.map_blacklist or {})
    if wc ~= self.lastWCount or bc ~= self.lastBCount then
        self:Refresh()
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, RED)
    draw.RoundedBox(6, 2, 2, w - 4, h - 4, WIN)
    draw.SimpleText("Map Config", "HM_Title", 14, 22, WH, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

vgui.Register("HordeMapConfig", PANEL, "EditablePanel")

if IsValid(HORDE.MapConfigGUI) then
    HORDE.MapConfigGUI:Remove()
    HORDE.MapConfigGUI = nil
    gui.EnableScreenClicker(false)
end

MsgC(Color(220, 30, 56), "[HORDE] ", color_white, "Map Config redesign loaded\n")
