if not CLIENT then return end

local UI = HORDE.ShopUI
local C = UI.C
local S, SB = UI.S, UI.SB

local COLS = 8

local function ep_of(item) return item.entity_properties or {} end

local function is_unarmed_active()
    return HORDE.difficulty_text and HORDE.difficulty_text[HORDE.difficulty] == "UNARMED"
end

local function is_weapon_item(item)
    return item.entity_properties and item.entity_properties.type == HORDE.ENTITY_PROPERTY_WPN
end

local function is_purism()
    return HORDE.IsPurismMode and HORDE:IsPurismMode()
end

local function is_spell_class(name)
    name = name or (IsValid(MySelf) and MySelf:Horde_GetCurrentSubclass())
    return HORDE:IsSpellcasterClass(name)
end

local function is_spell_item(item)
    return item and item._is_spell == true
end

local function spell_as_item(spell)
    local name = spell.PrintName or spell.ClassName
    local upg = MySelf:Horde_GetSpellUpgrade(spell.ClassName) or 0
    if spell.Upgrades and upg > 0 then
        name = name .. " +" .. tostring(upg)
    end
    return {
        class = spell.ClassName,
        name = name,
        price = spell.Price or 0,
        skull_tokens = 0,
        weight = 0,
        description = spell.Description or "",
        levels = spell.Levels,
        shop_icon = spell.Icon,
        entity_properties = {},
        _is_spell = true,
        _spell = spell,
        Upgrades = spell.Upgrades,
        Slot = spell.Slot,
    }
end

local function is_owned(item)
    if is_spell_item(item) then
        return MySelf:Horde_HasSpell(item.class)
    end
    local ep = ep_of(item)
    if MySelf:HasWeapon(item.class) then return true end
    if ep.type == HORDE.ENTITY_PROPERTY_GADGET and MySelf:Horde_GetGadget() == item.class then return true end
    if MySelf.Horde_Special_Upgrades and MySelf.Horde_Special_Upgrades[item.class] then return true end
    return false
end

local function level_ok(item)
    local levels = item.levels or (is_spell_item(item) and item._spell and item._spell.Levels)
    if levels and (HORDE.disable_levels_restrictions == 0) then
        for class, level in pairs(levels) do
            if MySelf:Horde_GetLevel(class) < level then return false end
        end
    end
    return true
end

local function can_afford(item)
    if is_spell_item(item) then
        return MySelf:Horde_GetMoney() >= (item.price or 0)
    end
    return MySelf:Horde_GetMoney() >= item.price
        and MySelf:Horde_GetSkullTokens() >= (item.skull_tokens or 0)
        and MySelf:Horde_GetWeight() >= item.weight
end

local function drop_count(item)
    if is_spell_item(item) then return nil end
    local de = MySelf:Horde_GetDropEntities()
    return de and de[item.class] or nil
end

local function item_loc_name(item)
    if is_spell_item(item) then
        local base = UI.T("Spell_" .. (item._spell and item._spell.PrintName or item.class), item.name)
        local upg = MySelf:Horde_GetSpellUpgrade(item.class) or 0
        if item.Upgrades and upg > 0 then
            return base .. " +" .. tostring(upg)
        end
        return base
    end
    local ep = ep_of(item)
    if ep.type == HORDE.ENTITY_PROPERTY_GADGET then
        local g = HORDE.gadgets and HORDE.gadgets[item.class]
        return UI.T("Gadget_" .. item.class, (g and g.PrintName) or item.name)
    end
    if ep.is_arccw_attachment then return item.name end
    return UI.T("Item_" .. tostring(item.name), item.name)
end

local function build_item_text(item)
    local ep = ep_of(item)
    local name = item_loc_name(item)
    local desc

    if is_spell_item(item) then
        local spell = item._spell
        desc = UI.T("Spell_Desc_" .. item.class, spell and spell.Description or item.description or "")
        if spell and spell.Upgrades then
            local upg = MySelf:Horde_GetSpellUpgrade(item.class) or 0
            desc = desc .. "\n\n" .. UI.T("Shop_UI_SpellLevel", "Spell Level") .. ": " .. tostring(upg) .. "/" .. tostring(spell.Upgrades)
            local stats = HORDE.GetSpellUpgradeStats and HORDE:GetSpellUpgradeStats(spell, upg)
            if stats then
                desc = desc .. "\n" .. stats
            end
        end
        return name, desc
    end

    if ep.is_arccw_attachment then
        desc = item.description or ""
        local atttbl = ArcCW and ArcCW.AttachmentTable and ArcCW.AttachmentTable[item.class]
        if atttbl and atttbl.Description then
            desc = atttbl.Description
            local ok, pros, cons = pcall(ArcCW.GetProsCons, ArcCW, nil, atttbl, nil)
            if ok and pros and cons then
                desc = desc .. "\n\n" .. UI.T("Shop_UI_Pros", "Pros:") .. "\n"
                for _, pro in pairs(pros) do desc = desc .. pro .. "\n" end
                desc = desc .. "\n" .. UI.T("Shop_UI_Cons", "Cons:") .. "\n"
                for _, con in pairs(cons) do desc = desc .. con .. "\n" end
            end
            desc = desc .. "\n" .. UI.T("Shop_UI_EquipC", "Equip by Pressing C.")
        end
        return name, desc
    end

    if ep.type == HORDE.ENTITY_PROPERTY_GADGET then
        local g = HORDE.gadgets and HORDE.gadgets[item.class]
        desc = UI.T("Gadget_Desc_" .. item.class, (g and g.Description) or (item.description or ""))
        if g and g.Active then
            desc = UI.T("Gadget_Activation", "Press T to activate.") .. "\n\n" .. desc
            if g.Once then
                desc = UI.T("Gadget_Consumed", "This gadget is CONSUMED after activation.") .. "\n" .. desc
            end
            desc = desc .. "\n\n"
            local seconds_loc = UI.T("Gadget_Seconds", "seconds")
            if g.Duration and g.Duration > 0 then
                desc = desc .. "\n" .. UI.T("Gadget_Duration", "Duration") .. ": " .. tostring(g.Duration) .. " " .. seconds_loc .. "."
            end
            if g.Cooldown and g.Cooldown > 0 then
                desc = desc .. "\n" .. UI.T("Gadget_Cooldown", "Cooldown") .. ": " .. tostring(g.Cooldown) .. " " .. seconds_loc .. "."
            end
        end
        desc = desc .. "\n\n" .. UI.T("Gadget_Owned_Warning", "Only 1 Gadget can be OWNED!")
        if g and g.Params then
            for i, v in pairs(g.Params) do
                local token = "{" .. i .. "}"
                if string.find(desc, token, 1, true) then
                    local value, percent
                    if type(v) == "table" then value, percent = v.value, v.percent else value = v end
                    local shown = value
                    if percent and type(value) == "number" then shown = math.Round(value * 100) .. "%" end
                    desc = string.Replace(desc, token, tostring(shown))
                end
            end
        end
        return name, desc
    end

    desc = UI.T("Item_Desc_" .. tostring(item.name), item.description or "")
    return name, desc
end

local function sort_items(items)
    table.sort(items, function(a, b)
        if a._cmp ~= b._cmp then return a._cmp < b._cmp end
        local sa, sb = a.skull_tokens or 0, b.skull_tokens or 0
        if sa ~= sb then return sa < sb end
        if a.weight ~= b.weight then return a.weight < b.weight end
        local la, lb = a.total_levels or 0, b.total_levels or 0
        if la ~= lb then return la < lb end
        return a.name < b.name
    end)
end

local function build_spell_sections()
    local sections = {}
    if not HORDE.spells then return sections end

    local spell_weapon = (isfunction(MySelf.Horde_GetSpellWeapon) and MySelf:Horde_GetSpellWeapon()) or nil
    local buckets = {
        [HORDE.Spell_Slot_LMB] = {},
        [HORDE.Spell_Slot_RMB] = {},
        [HORDE.Spell_Slot_Utility] = {},
        [HORDE.Spell_Slot_Reload] = {},
    }

    for _, spell in pairs(HORDE.spells) do
        local ok = false
        if spell.Weapon == nil then
            ok = true
        elseif spell_weapon then
            for _, wpn in pairs(spell.Weapon) do
                if wpn == spell_weapon:GetClass() then ok = true break end
            end
        end
        if ok and spell.Slot and buckets[spell.Slot] then
            local it = spell_as_item(spell)
            if is_owned(it) then
                it._cmp = -1
            else
                it._cmp = it.price or 0
            end
            table.insert(buckets[spell.Slot], it)
        end
    end

    local order = {
        { HORDE.Spell_Slot_LMB, "LMB" },
        { HORDE.Spell_Slot_RMB, "RMB" },
        { HORDE.Spell_Slot_Utility, "F" },
        { HORDE.Spell_Slot_Reload, "R" },
    }
    for _, entry in ipairs(order) do
        local slot, key = entry[1], entry[2]
        local list = buckets[slot]
        if list and #list > 0 then
            sort_items(list)
            local label = (HORDE.Spell_Slots and HORDE.Spell_Slots[slot]) or key
            sections[#sections + 1] = {
                key = "Spell:" .. tostring(slot),
                label = UI.T("Shop_Spell_" .. label, "Spell · " .. label),
                items = list,
            }
        end
    end
    return sections
end

local function build_sections()
    local class = MySelf:Horde_GetCurrentSubclass()
    local sections = {}
    local attachments = {}
    local mage = is_spell_class(class)

    if mage then
        for _, sec in ipairs(build_spell_sections()) do
            sections[#sections + 1] = sec
        end
    end

    local categories = {}
    if mage then
        categories = { "Equipment", "Gadget" }
    elseif HORDE._shop_tabs and #HORDE._shop_tabs > 0 then
        for _, tab in ipairs(HORDE._shop_tabs) do
            if tab.Name then table.insert(categories, tab.Name) end
        end
    else
        categories = table.Copy(HORDE.categories) or {}
    end
    if is_unarmed_active() then table.insert(categories, 1, "Unarmed") end

    for _, category in ipairs(categories) do
        local items = {}
        for _, item in pairs(HORDE.items) do
            local match = false
            local skip = false
            if is_unarmed_active() and is_weapon_item(item) then
                if category ~= "Unarmed" then
                    skip = true
                else
                    local looted = MySelf.Horde_UnarmedLooted and MySelf.Horde_UnarmedLooted[item.class]
                    if looted or MySelf:HasWeapon(item.class) then match = true end
                end
            elseif item.category == category and ((item.whitelist == nil) or (item.whitelist and item.whitelist[class])
                or (class == "Gunslinger" and item.category == "Pistol")) then
                match = true
            end

            if match and not skip then
                local blocked = HORDE.IsPurismBlockedShopItem and HORDE:IsPurismBlockedShopItem(item)
                if not blocked then
                    local owned_now = (item.category == "Gadget" and MySelf:Horde_GetGadget() == item.class) or MySelf:HasWeapon(item.class)
                    local show = true
                    if owned_now then
                        item._cmp = -1
                    else
                        if item.hidden == true then show = false end
                        item._cmp = item.price
                    end
                    if class == "Overlord" and string.match(item.class, "watchtower") then show = false end
                    if show then table.insert(items, item) end
                end
            end
        end

        if #items > 0 then
            sort_items(items)
            if category == "Attachment" then
                for _, item in ipairs(items) do
                    local ep = item.entity_properties
                    if ep and ep.is_arccw_attachment then
                        local t = ep.arccw_attachment_type
                        attachments[t] = attachments[t] or {}
                        table.insert(attachments[t], item)
                    end
                end
            else
                local filtered = {}
                for _, item in ipairs(items) do
                    if category == "Unarmed" or item.category == category then table.insert(filtered, item) end
                end
                if #filtered > 0 then
                    sections[#sections + 1] = {
                        key = category,
                        label = UI.T("Shop_" .. category, category),
                        items = filtered,
                    }
                end
            end
        end
    end
    return sections, attachments
end

local function attachment_sections(attachments)
    local out = {}
    local free = GetConVar("horde_arccw_attinv_free")
    if not ArcCWInstalled or (free and free:GetInt() ~= 0) then return out end
    for _, att_cat in ipairs(HORDE.arccw_attachment_categories or {}) do
        local list = {}
        for _, item in ipairs(attachments[att_cat] or {}) do
            local wpn = item.entity_properties.arccw_attachment_wpn
            if not wpn or MySelf:HasWeapon(wpn) then table.insert(list, item) end
        end
        if #list > 0 then
            out[#out + 1] = { key = "Attachment:" .. att_cat, label = att_cat, items = list }
        end
    end
    return out
end

local function quick_action_kind(item, desc)
    if not item then return nil end
    local ep = ep_of(item)
    if not is_owned(item) then
        if is_spell_item(item) or ep.type ~= HORDE.ENTITY_PROPERTY_WPN then return nil end
        if not can_afford(item) or not level_ok(item) then return nil end
        return "buy"
    end
    if item.category == "Equipment" or ep.type ~= HORDE.ENTITY_PROPERTY_WPN then return nil end
    local wpn = MySelf:GetWeapon(item.class)
    if item.ammo_price and item.ammo_price >= 0 and IsValid(wpn) and wpn:GetPrimaryAmmoType() > 0 then
        return "ammo_primary"
    end
    if (item.secondary_ammo_price or 0) > 0 then return "ammo_secondary" end
    if desc and desc:IsUpgradable(item) then return "upgrade" end
    return nil
end

local function quick_action_hint(kind)
    if kind == "buy" then return UI.T("Shop_DoubleClick_Buy", "Double-click to buy") end
    if kind == "upgrade" then return UI.T("Shop_DoubleClick_Upgrade", "Double-click to upgrade") end
    if kind then return UI.T("Shop_DoubleClick_Ammo", "Double-click to buy ammo") end
    return nil
end

local GRID = {}

function GRID:Init()
    UI.VScrollInit(self)
    self.tw = {}
    self.base, self.att_raw = {}, {}
    self.att = {}
    self.selected = nil
    self.dirty = true
    self.att_sig = nil
    self.next_sig = 0
    self.last_item, self.last_click = nil, nil
end

function GRID:Build()
    self.base, self.att_raw = build_sections()
    self.att = attachment_sections(self.att_raw)
    self.att_sig = self:WeaponSig()
    self.dirty = true
end

function GRID:WeaponSig()
    local list = MySelf:GetWeapons()
    local names = {}
    for _, w in ipairs(list) do names[#names + 1] = w:GetClass() end
    table.sort(names)
    return table.concat(names, ",")
end

function GRID:Sections()
    if not self.merged or self.dirty then
        local m = {}
        for _, s in ipairs(self.base) do m[#m + 1] = s end
        for _, s in ipairs(self.att) do m[#m + 1] = s end
        self.merged = m
    end
    return self.merged
end

function GRID:FirstItem()
    local s = self:Sections()[1]
    return s and s.items[1] or nil
end

function GRID:Layout(cw)
    if self.lay_w == cw and not self.dirty then return end
    self.lay_w = cw
    self.dirty = false
    self.merged = nil
    local gap = S(5)
    local slot = (cw - gap * (COLS - 1)) / COLS
    self.gap, self.slot = gap, slot
    local y = 0
    for i, sec in ipairs(self:Sections()) do
        if i > 1 then y = y + S(12) end
        sec.y = y
        y = y + S(30) + S(8)
        sec.gy = y
        local rows = math.ceil(#sec.items / COLS)
        sec.rows = rows
        y = y + rows * slot + (rows - 1) * gap
    end
    self.total_h = y
    self:SetContentHeight(y)
end

function GRID:ItemAt(cx, cy)
    if not cx or not self.slot then return nil end
    local step = self.slot + self.gap
    for _, sec in ipairs(self:Sections()) do
        if sec.gy and cy >= sec.gy and cy < sec.gy + sec.rows * step then
            local col = math.floor(cx / step)
            local row = math.floor((cy - sec.gy) / step)
            local inx = cx - col * step
            local iny = (cy - sec.gy) - row * step
            if col >= 0 and col < COLS and inx <= self.slot and iny <= self.slot then
                return sec.items[row * COLS + col + 1], sec, col, row
            end
            return nil
        end
    end
    return nil
end

function GRID:Tw(item)
    local t = self.tw[item.class]
    if not t then
        t = { hov = UI.Tween(0, 0.15), act = UI.Tween(0, 0.15) }
        self.tw[item.class] = t
    end
    return t
end

local function icons_enabled()
    local cv = GetConVar("horde_enable_shop_icons")
    return (not cv) or cv:GetInt() ~= 0
end

function GRID:DrawSlot(item, x, y, s, hovered)
    local t = self:Tw(item)
    local sel = (self.selected == item)
    t.hov:Set(hovered and 1 or 0)
    t.act:Set(sel and 1 or 0)

    local col = UI.Mix(UI.Mix(C.CARD, C.CARD_H, t.hov:Get()), C.RED, t.act:Get())
    UI.Rect(S(6), x, y, s, s, col)

    local owned = is_owned(item)
    local locked = (not owned) and (not level_ok(item))
    local unavail = locked or ((not owned) and (not can_afford(item)))

    local pad = S(6)
    if icons_enabled() then
        local icon = UI.GetItemIcon(item)
        if icon then
            UI.DrawItemIcon(icon, x + pad, y + pad, s - pad * 2, s - pad * 2)
        else
            UI.DrawPlaceholder(x + pad + S(6), y + pad + S(6), s - pad * 2 - S(12), s - pad * 2 - S(12))
        end
    else
        local f = UI.Font(10, false)
        local txt = UI.Ellipsis(item_loc_name(item), f, s - pad)
        UI.Text(txt, f, x + s / 2, y + s / 2, C.WH, TEXT_ALIGN_CENTER)
    end

    if owned then
        local m = UI.Mat("ok.png")
        if m then
            local cs = S(13)
            UI.DrawMat(m, x + s - cs - S(3), y + S(3), cs, cs, sel and C.WH or C.GREEN)
        end
    end

    if unavail then
        UI.Rect(S(6), x, y, s, s, locked and Color(0, 0, 0, 200) or Color(0, 0, 0, 150))
    end

    if HORDE.GetQualityStars and item.quality then
        local stars = HORDE:GetQualityStars(item.quality)
        local ss = S(9)
        local gap = S(0.8)
        local total = stars * ss + (stars - 1) * gap
        local sx = x + (s - total) / 2
        local sy = y + s - ss - S(3)
        for i = 1, stars do
            local m = UI.Mat("star.png")
            if m then
                UI.DrawMat(m, sx + (i - 1) * (ss + gap), sy, ss, ss, C.WH)
            else
                UI.Rect(1, sx + (i - 1) * (ss + gap), sy, ss, ss, C.WH)
            end
        end
    end

    if unavail then
        local lm = UI.Mat("locked.png")
        if lm then
            local ls = S(17)
            UI.DrawMat(lm, x + (s - ls) / 2, y + (s - ls) / 2, ls, ls, C.WH)
        end
    end
end

function GRID:PaintContent(cw, h, ox, oy)
    self:Layout(cw)
    local secs = self:Sections()

    if #secs == 0 then
        UI.Text(UI.T("Shop_UI_NoItems", "Nothing here yet."), UI.Font(13.5, false), ox + cw / 2, h / 2, C.DIM, TEXT_ALIGN_CENTER)
        return
    end

    local hover = self.hover_item
    local step = self.slot + self.gap
    local f_banner = UI.Font(13.5, true)

    for _, sec in ipairs(secs) do
        local by = oy + sec.y
        local gy = oy + sec.gy
        local sec_h = S(30) + S(8) + sec.rows * step
        if by + sec_h >= 0 and by <= h then
            local bh = S(30)
            UI.Rect(S(3), ox, by, cw, bh, C.RED)
            surface.SetDrawColor(C.RED)
            surface.DrawRect(ox, by, cw, bh / 2)
            UI.Text(sec.label, f_banner, ox + cw / 2, by + bh / 2, C.WH, TEXT_ALIGN_CENTER)

            for i, item in ipairs(sec.items) do
                local row = math.floor((i - 1) / COLS)
                local col = (i - 1) % COLS
                local sy = gy + row * step
                if sy + self.slot >= 0 and sy <= h then
                    self:DrawSlot(item, ox + math.floor(col * step), sy, math.ceil(self.slot), hover == item)
                end
            end
        end
    end
end

function GRID:OnThink()
    local item, sec, col, row = self:ItemAt(self.hx, self.hy)
    self.hover_item = item
    self:SetCursor(item and "hand" or "arrow")

    if item and item ~= self.last_hover then
        surface.PlaySound("UI/buttonrollover.wav")
    end
    self.last_hover = item

    local shop = self.shop
    if item and IsValid(shop) and shop.SetTip then
        local lines = { item_loc_name(item) }
        local price = tostring(item.price) .. "$"
        if (item.skull_tokens or 0) > 0 then
            price = (item.price > 0) and (price .. "  " .. item.skull_tokens .. " " .. UI.T("Shop_UI_Skulls", "Skulls")) or (item.skull_tokens .. " " .. UI.T("Shop_UI_Skulls", "Skulls"))
        end
        lines[2] = price
        local hint = quick_action_hint(quick_action_kind(item, self.desc))
        if hint then lines[3] = hint end
        local step = self.slot + self.gap
        local sx = col * step + self.slot / 2 + self:ContentX()
        local sy = (sec.gy + row * step + self.slot) - self:Scroll()
        local gx, gy = self:LocalToScreen(sx, sy)
        shop:SetTip(lines, gx, gy + S(6), "below")
    end

    if SysTime() >= self.next_sig then
        self.next_sig = SysTime() + 0.25
        if self.att_raw and next(self.att_raw) ~= nil then
            local sig = self:WeaponSig()
            if sig ~= self.att_sig then
                self.att_sig = sig
                self.att = attachment_sections(self.att_raw)
                self.dirty = true
            end
        end
    end
end

function GRID:ContentPressed(cx, cy, code)
    if code ~= MOUSE_LEFT then return end
    local item = self:ItemAt(cx, cy)
    if not item then
        self.last_item, self.last_click = nil, nil
        return
    end
    surface.PlaySound("UI/buttonclick.wav")
    if self.OnSelect then self.OnSelect(item) end

    local now = SysTime()
    if self.last_item == item and (now - (self.last_click or 0)) < 0.3 then
        self.last_item, self.last_click = nil, nil
        if self.OnDoubleClick then self.OnDoubleClick(item) end
    else
        self.last_item, self.last_click = item, now
    end
end

vgui.Register("HordeShopGrid", GRID, "HordeUIVScroll")

local DTEXT = {}

function DTEXT:Init()
    UI.VScrollInit(self)
    self.text = ""
    self.lines = nil
end

function DTEXT:SetText(text)
    self.text = text or ""
    self.lines = nil
    self:ScrollTo(0, true)
end

function DTEXT:PaintContent(cw, h, ox, oy)
    local font = UI.Font(13, false)
    if not self.lines or self.lines_w ~= cw then
        self.lines_w = cw
        self.lines = UI.Wrap(self.text, font, cw - S(2))
        local lh = S(18)
        self.lh = lh
        local y = 0
        self.ys = {}
        for i, l in ipairs(self.lines) do
            self.ys[i] = y
            y = y + ((l == "") and math.floor(lh * 0.6) or lh)
        end
        self:SetContentHeight(y)
    end
    for i, l in ipairs(self.lines) do
        local y = oy + self.ys[i]
        if l ~= "" and y + self.lh >= 0 and y <= h then
            if self.center then
                UI.Text(l, font, ox + cw / 2, y + self.lh / 2, C.WH, TEXT_ALIGN_CENTER)
            else
                UI.Text(l, font, ox, y + self.lh / 2, C.WH)
            end
        end
    end
end

vgui.Register("HordeShopDescText", DTEXT, "HordeUIVScroll")

local DESC = {}

local function net_item(msg, class, bits, count)
    net.Start(msg)
    net.WriteString(class)
    if bits then net.WriteUInt(count, bits) end
    net.SendToServer()
end

function DESC:Init()
    self.fade = UI.Tween(1, 0.18)
    self.mode = "info"
    self.mode_t = UI.Tween(0, 0.2)
    self.btn_tw = {}
    self.rows = {}
    self.blocks = {}
    self.inf_sel = HORDE.Infusion_None or 0
    self.inf_rects = {}

    self.preview = vgui.Create("HordeUIPreview", self)
    self.text = vgui.Create("HordeShopDescText", self)
end

function DESC:SetItem(item)
    self.item = item
    self.mode = "info"
    self.mode_t:Set(0)
    self.fade:Snap(0.2)
    self.fade:Set(1)
    self.preview:SetItem(item)
    if item then
        self.name, self.desc = build_item_text(item)
        self.text:SetText(self.desc)
        self.desc_sig = self:UpgradeSignature()
        local cur = MySelf:Horde_GetInfusion(item.class)
        self.inf_sel = cur or HORDE.Infusion_None
    end
end

function DESC:UpgradeSignature()
    local item = self.item
    if not item then return nil end
    if is_spell_item(item) then
        return "spell:" .. tostring(MySelf:Horde_GetSpellUpgrade(item.class))
    end
    return "item:" .. tostring(self:UpgradeLevel(item))
end

function DESC:Buy()
    local item = self.item
    if not item or not MySelf:Alive() then return end
    if is_spell_item(item) then
        if MySelf:Horde_GetMoney() < (item.price or 0) or not level_ok(item) then return end
        net.Start("Horde_BuySpell")
        net.WriteString(item.class)
        net.SendToServer()
        return
    end
    if MySelf:Horde_GetMoney() < item.price or MySelf:Horde_GetWeight() < item.weight or not level_ok(item) then return end
    net_item("Horde_BuyItem", item.class)
end

function DESC:Sell()
    local item = self.item
    if not item or not MySelf:Alive() then return end
    local ep = ep_of(item)
    local sellable = MySelf:HasWeapon(item.class) or ep.type == HORDE.ENTITY_PROPERTY_DROP
        or ep.type == HORDE.ENTITY_PROPERTY_GADGET or ep.type == HORDE.ENTITY_PROPERTY_SPECIAL_UPGRADE
    if not sellable or not IsValid(self.shop) then return end

    local unarmed = HORDE.unarmed_mode == true
    if unarmed and MySelf:HasWeapon(item.class) then
        UI.OpenModal(self.shop, {
            title = UI.T("Shop_UI_Drop", "Drop"),
            heading = self.name,
            lines = { UI.T("Shop_UI_DropAsk", "Drop this weapon?") },
            confirm = UI.T("Shop_UI_Drop", "Drop"),
            on_confirm = function()
                net.Start("Horde_DropWeapon")
                    net.WriteString(item.class)
                net.SendToServer()
            end,
        })
        return
    end

    local count = (ep.type == HORDE.ENTITY_PROPERTY_DROP) and drop_count(item) or 1
    local value = math.floor(item.price * 0.75 * (count or 1))
    UI.OpenModal(self.shop, {
        title = UI.T("Shop_UI_Sell", "Sell"),
        heading = self.name,
        lines = { UI.T("Shop_UI_SellAsk", "Sell this item?") },
        row = { label = UI.T("Shop_UI_SellFor", "Sell for:"), value = tostring(value) .. "$" },
        confirm = UI.T("Shop_UI_Sell", "Sell"),
        on_confirm = function() net_item("Horde_SellItem", item.class) end,
    })
end

function DESC:Ammo(count)
    local item = self.item
    if not item or not MySelf:Alive() then return end
    if (item.ammo_price or 0) < 0 then
        net_item("Horde_BuyItemUpgrade", item.class)
        return
    end
    if count <= -1 then
        if (item.secondary_ammo_price or 0) <= 0 or MySelf:Horde_GetMoney() < item.secondary_ammo_price then return end
        net_item("Horde_BuyItemAmmoSecondary", item.class, 4, -count)
        return
    end
    local price = (item.ammo_price and item.ammo_price or HORDE.default_ammo_price) * count
    if MySelf:Horde_GetMoney() < price then return end
    net_item("Horde_BuyItemAmmoPrimary", item.class, 4, count)
end

function DESC:Upgrade()
    local item = self.item
    if not item or not MySelf:Alive() then return end
    if is_spell_item(item) then
        net.Start("Horde_BuySpellUpgrade")
        net.WriteString(item.class)
        net.SendToServer()
        return
    end
    net_item("Horde_BuyItemUpgrade", item.class)
end

function DESC:QuickBuy()
    if not MySelf:Alive() then return end
    local kind = quick_action_kind(self.item, self)
    if kind == "buy" then
        self:Buy()
    elseif kind == "ammo_primary" then
        self:Ammo(1)
    elseif kind == "ammo_secondary" then
        self:Ammo(-1)
    elseif kind == "upgrade" then
        self:Upgrade()
    end
end

function DESC:SetMode(mode)
    self.mode = mode
    self.mode_t:Set(mode == "infusion" and 1 or 0)
end

function DESC:UpgradeLevel(item)
    item = item or self.item
    if not item then return 0 end
    local level = MySelf:Horde_GetUpgrade(item.class) or 0
    if HORDE.IsWave666Mode and HORDE:IsWave666Mode() then
        if HORDE.relic_weapon_subclass and HORDE.relic_weapon_subclass[item.class] then
            return math.max(level, 10)
        end
    end
    return level
end

function DESC:SupportsUpgrade(item)
    item = item or self.item
    if not item then return false end
    if HORDE.relic_no_upgrade and HORDE.relic_no_upgrade[item.class] then return false end
    if MySelf:Horde_GetCurrentSubclass() == "Gunslinger" and item.category == "Pistol" then return true end
    if HORDE.relic_weapon_subclass and HORDE.relic_weapon_subclass[item.class] then return true end
    if item.OnUpgrade then return true end
    return false
end

function DESC:IsUpgraded()
    return self.item and MySelf:HasWeapon(self.item.class) and self:SupportsUpgrade() and self:UpgradeLevel() > 0
end

function DESC:IsUpgradable(item)
    item = item or self.item
    if not item or not MySelf:HasWeapon(item.class) then return false end
    if HORDE.IsWave666Mode and HORDE:IsWave666Mode() then return false end
    if self:UpgradeLevel() >= 10 then return false end
    return self:SupportsUpgrade()
end

local function cell(id, text, kind, fn)
    return { id = id, text = text, kind = kind, fn = fn }
end

function DESC:BuildRows()
    local item = self.item
    local rows = {}
    if not item then return rows end
    local ep = ep_of(item)
    local T = UI.T

    if self.mode == "infusion" then
        local sel = self.inf_sel
        local price = 100 + item.price / 5
        local main
        if sel == HORDE.Infusion_None then
            main = cell("inf_do", T("Shop_UI_NoInfusion", "No infusion selected."), "error")
        elseif MySelf:Horde_HasInfusion(item.class, sel) == true then
            main = cell("inf_do", T("Game_Infused", "Infused"), "error")
        elseif MySelf:Horde_GetMoney() < price then
            main = cell("inf_do", string.format(T("Shop_UI_InfNeed", "Not enough money (Need %s$)"), tostring(price)), "error")
        else
            local nm = T("Infusion_" .. tostring(HORDE.Infusion_Names[sel]), tostring(HORDE.Infusion_Names[sel]))
            main = cell("inf_do", string.format(T("Shop_UI_InfApply", "Apply %s (%s$)"), nm, tostring(price)), "primary", function()
                net.Start("Horde_BuyInfusion")
                net.WriteString(item.class)
                net.WriteUInt(sel, 5)
                net.SendToServer()
            end)
        end
        rows[#rows + 1] = { main }
        if MySelf:Horde_GetInfusion(item.class) ~= HORDE.Infusion_None then
            rows[#rows + 1] = { cell("inf_rm", T("Shop_UI_RemoveInfusion", "Remove Infusion"), "ghost", function()
                net_item("Horde_SellInfusion", item.class)
            end) }
        end
        rows[#rows + 1] = { cell("inf_back", T("Shop_UI_Back", "Back"), "ghost", function() self:SetMode("info") end) }
        return rows
    end

    local alive = MySelf:Alive()

    if is_spell_item(item) then
        if is_owned(item) then
            local spell = item._spell
            local max_upg = spell and spell.Upgrades
            local cur_upg = MySelf:Horde_GetSpellUpgrade(item.class) or 0
            if max_upg and max_upg > 0 and cur_upg < max_upg then
                local price = HORDE.GetSpellUpgradePrice and HORDE:GetSpellUpgradePrice(item.class, MySelf)
                if price and price > 0 then
                    if MySelf:Horde_GetMoney() >= price and alive then
                        rows[#rows + 1] = { cell("upg", string.format(T("Shop_UI_UpgradeTo", "Upgrade to +%s (%s$)"), tostring(cur_upg + 1), tostring(price)), "gold", function() self:Upgrade() end) }
                    else
                        rows[#rows + 1] = { cell("upg", string.format(T("Shop_UI_UpgradeTo", "Upgrade to +%s (%s$)"), tostring(cur_upg + 1), tostring(price)), "error") }
                    end
                end
            end
            rows[#rows + 1] = { cell("main", T("Shop_OWNED", "OWNED"), "owned") }
            return rows
        end

        local main
        if not level_ok(item) then
            main = cell("main", T("Shop_UI_RankNotMet", "Rank Requirement(s) Not Met"), "error")
        elseif not alive or not can_afford(item) then
            main = cell("main", not alive and T("Shop_UI_Dead", "You are dead.") or T("Shop_Not_Enough_Money_Or_Carrying_Capacity", "Not enough money or capacity!"), "error")
        else
            main = cell("main", T("Shop_Buy_Item", "Buy Item"), "primary", function() self:Buy() end)
        end
        rows[#rows + 1] = { main }
        return rows
    end

    if is_owned(item) then
        if item.category ~= "Equipment" and ep.type == HORDE.ENTITY_PROPERTY_WPN then
            local wpn = MySelf:GetWeapon(item.class)
            if item.ammo_price and item.ammo_price >= 0 and IsValid(wpn) and wpn:GetPrimaryAmmoType() > 0 then
                local price = item.ammo_price or HORDE.default_ammo_price
                local lab = T("Shop_Buy_Ammo_Clip", "Buy Ammo")
                rows[#rows + 1] = {
                    cell("ammo1", lab .. " x 1 (" .. price .. "$)", "gray", function() self:Ammo(1) end),
                    cell("ammo10", lab .. " x 10 (" .. price * 10 .. "$)", "gray", function() self:Ammo(10) end),
                }
            end
            if item.secondary_ammo_price and item.secondary_ammo_price > 0 then
                local lab = T("Shop_Buy_Secondary_Ammo", "Buy Secondary Ammo")
                rows[#rows + 1] = {
                    cell("sec1", lab .. " x 1 (" .. item.secondary_ammo_price .. "$)", "gray", function() self:Ammo(-1) end),
                    cell("sec10", lab .. " x 10 (" .. item.secondary_ammo_price * 10 .. "$)", "gray", function() self:Ammo(-10) end),
                }
            end
            if self:IsUpgradable() then
                local price = HORDE:GetUpgradePrice(item.class)
                rows[#rows + 1] = { cell("upg", string.format(T("Shop_UI_UpgradeTo", "Upgrade to +%s (%s$)"), tostring((MySelf:Horde_GetUpgrade(item.class) or 0) + 1), tostring(price)), "gold", function() self:Upgrade() end) }
            end
        end
        if item.infusions and not table.IsEmpty(item.infusions) and not is_purism() then
            local inf = MySelf:Horde_GetInfusion(item.class)
            local nm = (inf == HORDE.Infusion_None) and T("Infusion_None", "None") or T("Infusion_" .. tostring(HORDE.Infusion_Names[inf]), tostring(HORDE.Infusion_Names[inf]))
            rows[#rows + 1] = { cell("inf", T("Game_Infusion", "Infusion") .. ": " .. nm, "ghost", function() self:SetMode("infusion") end) }
        end
        if HORDE.unarmed_mode then
            rows[#rows + 1] = { cell("sell", T("Shop_UI_Drop", "Drop"), "ghost", function() self:Sell() end) }
        else
            rows[#rows + 1] = { cell("sell", T("Shop_Sell_For", "Sell for") .. " " .. math.floor(item.price * 0.75) .. "$", "ghost", function() self:Sell() end) }
        end
        rows[#rows + 1] = { cell("main", T("Shop_OWNED", "OWNED"), "owned") }
        return rows
    end

    local main
    local drops = (ep.type == HORDE.ENTITY_PROPERTY_DROP) and drop_count(item) or nil
    local limit_hit = ep.limit and ep.limit > 0 and ep.type == HORDE.ENTITY_PROPERTY_DROP and drops and drops >= ep.limit

    if not level_ok(item) then
        main = cell("main", T("Shop_UI_RankNotMet", "Rank Requirement(s) Not Met"), "error")
    elseif not alive or not can_afford(item) then
        main = cell("main", not alive and T("Shop_UI_Dead", "You are dead.") or T("Shop_Not_Enough_Money_Or_Carrying_Capacity", "Not enough money or capacity!"), "error")
    elseif limit_hit then
        main = cell("main", T("Shop_UI_Limit", "Limit reached") .. " " .. drops .. "/" .. ep.limit, "error")
    else
        local txt = T("Shop_Buy_Item", "Buy Item")
        if drops then txt = txt .. " " .. drops .. "/" .. tostring(ep.limit) end
        main = cell("main", txt, "primary", function() self:Buy() end)
    end

    if drops and level_ok(item) then
        rows[#rows + 1] = { cell("sell", T("Shop_Sell_All_For", "Sell all for") .. " " .. math.floor(item.price * 0.75 * drops) .. "$", "ghost", function() self:Sell() end) }
    end
    rows[#rows + 1] = { main }
    return rows
end

function DESC:BuildBlocks()
    local item = self.item
    local blocks = {}
    if not item or self.mode ~= "info" then return blocks end
    local ep = ep_of(item)

    if not is_owned(item) and not level_ok(item) and item.levels then
        blocks[#blocks + 1] = { kind = "req", h = S(30) }
    end
    if is_owned(item) and item.category ~= "Equipment" and ep.type == HORDE.ENTITY_PROPERTY_WPN then
        local wpn = MySelf:GetWeapon(item.class)
        if IsValid(wpn) and wpn:GetPrimaryAmmoType() > 0 then
            blocks[#blocks + 1] = { kind = "ammo", h = S(20), wpn = wpn }
        end
    end
    if item.dmgtype and not table.IsEmpty(item.dmgtype) then
        blocks[#blocks + 1] = { kind = "dmg", h = S(26) }
    end
    blocks[#blocks + 1] = { kind = "price", h = S(26) }
    return blocks
end

function DESC:Metrics()
    local W, H = self:GetWide(), self:GetTall()
    local m = { W = W, H = H }
    m.banner_h = S(30)
    m.body_y = S(42)
    m.row_h = S(114)
    m.text_y = m.body_y + m.row_h + S(6)
    m.btn_h, m.btn_gap = S(40), S(6)
    local n = #self.rows
    m.btn_top = H - (n * (m.btn_h + m.btn_gap) - m.btn_gap)
    local bh = 0
    for _, b in ipairs(self.blocks) do bh = bh + b.h end
    m.blocks_h = bh
    m.blocks_top = m.btn_top - S(8) - bh
    m.text_h = math.max(S(30), m.blocks_top - S(6) - m.text_y)
    return m
end

function DESC:PerformLayout(w, h)
    local m = self:Metrics()
    self.preview:SetPos(w - S(110), m.body_y - S(6))
    self.preview:SetSize(S(110), S(120))
    self.text:SetPos(0, m.text_y)
    self.text:SetSize(w, m.text_h)
end

function DESC:Think()
    local sig = self:UpgradeSignature()
    if self.item and sig ~= self.desc_sig then
        self.desc_sig = sig
        self.name, self.desc = build_item_text(self.item)
        self.text:SetText(self.desc)
    end

    self.rows = self:BuildRows()
    self.blocks = self:BuildBlocks()

    local m = self:Metrics()
    local key = m.W .. "|" .. m.H .. "|" .. m.text_h
    if key ~= self.layout_key then
        self.layout_key = key
        self:InvalidateLayout(true)
    end

    local mt = self.mode_t:Get()
    local a = self.fade:Get()
    self.text:SetAlpha(math.floor(255 * math.Clamp((1 - mt) * a, 0, 1)))
    self.text:SetMouseInputEnabled(self.mode == "info")
    self.text:SetVisible((1 - mt) > 0.01)
end

local function pill_button(x, y, w, h, kind, hov, text, font)
    local col_text = C.WH
    if kind == "primary" then
        UI.Pill(x, y, w, h, UI.Mix(C.RED, C.RED_H, hov))
    elseif kind == "owned" then
        UI.Pill(x, y, w, h, C.BTN)
        col_text = C.DIM
    elseif kind == "error" then
        UI.Pill(x, y, w, h, C.RED_DARK)
        col_text = UI.Alpha(C.WH, 0.65)
    elseif kind == "gray" then
        UI.Pill(x, y, w, h, UI.Mix(C.BTN, C.BTN_H, hov))
    else
        local th = SB(1.5)
        local border = (kind == "gold") and C.GOLD or C.RED
        UI.Pill(x, y, w, h, border)
        UI.Pill(x + th, y + th, w - th * 2, h - th * 2, UI.Mix(C.WIN, C.CARD, hov))
        if kind == "gold" then col_text = C.GOLD end
    end
    local t = UI.Ellipsis(text, font, w - S(24))
    UI.Text(t, font, x + w / 2, y + h / 2, col_text, TEXT_ALIGN_CENTER)
end

function DESC:DrawTitleBlock(m, a)
    local item = self.item
    local w = m.W
    local f_title = UI.Font(21, true)
    local maxw = w - S(110) - S(10)

    local title = self.name or ""
    if self:IsUpgraded() then title = title .. " +" .. tostring(self:UpgradeLevel()) end
    local lines = UI.Wrap(title, f_title, maxw)
    if #lines > 2 then
        lines = { lines[1], UI.Ellipsis(lines[2] .. " " .. lines[3], f_title, maxw) }
    end
    local lh = S(25)
    local name_col = C.RED_TXT
    if HORDE.GetQualityColor and item and item.quality then
        name_col = HORDE:GetQualityColor(item.quality)
    end
    for i, l in ipairs(lines) do
        UI.Text(l, f_title, 0, m.body_y + (i - 0.5) * lh, UI.Alpha(name_col, a))
    end
end

function DESC:DrawBlocks(m, alpha)
    local y = m.blocks_top
    local W = m.W
    for _, b in ipairs(self.blocks) do
        local cy = y + b.h / 2
        if b.kind == "dmg" then
            local f = UI.Font(13, true)
            local lab = UI.T("Shop_UI_DamageType", "Damage Type:") .. " "
            UI.Text(lab, f, 0, cy, UI.Alpha(C.RED_TXT, alpha))
            surface.SetFont(f)
            local x = surface.GetTextSize(lab) + S(2)
            local keys = {}
            for _, d in pairs(self.item.dmgtype) do keys[#keys + 1] = d end
            table.sort(keys)
            local is = S(18)
            for _, d in ipairs(keys) do
                local path = HORDE.DMG_TYPE_ICON and HORDE.DMG_TYPE_ICON[d]
                local m2 = path and UI.Mat(path)
                if m2 then
                    local col = (HORDE.DMG_COLOR and HORDE.DMG_COLOR[d]) or C.WH
                    UI.DrawMat(m2, x, cy - is / 2, is, is, UI.Alpha(col, alpha))
                    x = x + is + S(4)
                end
            end
        elseif b.kind == "price" then
            local item = self.item
            local f = UI.Font(13.5, true)
            local col = UI.Alpha(C.WH, alpha)
            local x = 0
            surface.SetFont(f)
            if item.price and item.price > 0 then
                local s = tostring(item.price) .. "$"
                UI.Text(s, f, x, cy, col)
                x = x + surface.GetTextSize(s) + S(16)
            end
            if (item.skull_tokens or 0) > 0 then
                local sm = UI.Mat("skull.png")
                local is = S(15)
                if sm then UI.DrawMat(sm, x, cy - is / 2, is, is, col) end
                local s = tostring(item.skull_tokens)
                UI.Text(s, f, x + is + S(4), cy, col)
                x = x + is + S(4) + surface.GetTextSize(s) + S(16)
            end
            if item.weight and item.weight > 0 then
                local wm = UI.Mat("weight.png")
                local is = S(15)
                if wm then UI.DrawMat(wm, x, cy - is / 2, is, is, col) end
                UI.Text(tostring(item.weight), f, x + is + S(4), cy, col)
            end
        elseif b.kind == "ammo" then
            local wpn = b.wpn
            if IsValid(wpn) then
                local pa = wpn:GetPrimaryAmmoType()
                local txt = UI.T("Shop_Primary_Ammo", "Primary Ammo") .. ": " .. tostring(wpn:Clip1()) .. " / " .. tostring(MySelf:GetAmmoCount(pa))
                if wpn:GetSecondaryAmmoType() > 0 then
                    txt = txt .. "  |  " .. UI.T("Shop_Secondary_Ammo", "Secondary Ammo") .. ": " .. tostring(MySelf:GetAmmoCount(wpn:GetSecondaryAmmoType()))
                end
                UI.Text(UI.Ellipsis(txt, UI.Font(12, false), W), UI.Font(12, false), 0, cy, UI.Alpha(C.DIM, alpha))
            end
        elseif b.kind == "req" then
            local f = UI.Font(12, false)
            local lab = UI.T("Shop_UI_Requires", "Requires:") .. " "
            UI.Text(lab, f, 0, cy, UI.Alpha(C.RED_TXT, alpha))
            surface.SetFont(f)
            local x = surface.GetTextSize(lab) + S(4)
            local names = {}
            for k in pairs(self.item.levels) do names[#names + 1] = k end
            table.sort(names)
            for _, cname in ipairs(names) do
                local lvl = self.item.levels[cname]
                local sub = HORDE.subclasses and HORDE.subclasses[cname]
                if lvl and lvl > 0 and sub then
                    local rank, rl = HORDE:LevelToRank(lvl)
                    local rc = (HORDE.Rank_Colors and HORDE.Rank_Colors[rank]) or C.WH
                    local txt = UI.T("Rank_" .. tostring(rank), tostring(rank)) .. " " .. tostring(rl)
                    local tw = surface.GetTextSize(txt)
                    local is = S(20)
                    if x + is + S(4) + tw > W then break end
                    local im = UI.Mat(sub.Icon)
                    if im then UI.DrawMat(im, x, cy - is / 2, is, is, UI.Alpha(rc, alpha)) end
                    UI.Text(txt, f, x + is + S(4), cy, UI.Alpha(rc, alpha))
                    x = x + is + S(4) + tw + S(12)
                end
            end
        end
        y = y + b.h
    end
end

function DESC:DrawInfusion(m, alpha)
    local item = self.item
    self.inf_rects = {}
    if not item.infusions then return end
    local W = m.W
    local colw = math.floor((W - S(6)) / 2)
    local th = S(40)
    local price = 100 + item.price / 5
    local f = UI.Font(13.5, false)
    local f_b = UI.Font(12, true)
    local ids = {}
    for _, inf in pairs(item.infusions) do
        if inf ~= HORDE.Infusion_None and HORDE:IsInfusionRegistered(inf) then ids[#ids + 1] = inf end
    end
    table.sort(ids)

    local y0 = m.text_y
    for i, inf in ipairs(ids) do
        local row, col = math.floor((i - 1) / 2), (i - 1) % 2
        local x = col * (colw + S(6))
        local y = y0 + row * (th + S(6))
        local id = "inf_tile_" .. inf
        local tw = self.btn_tw[id]
        if not tw then tw = UI.Tween(0, 0.15); self.btn_tw[id] = tw end
        local hovered = self.hover_id == id
        tw:Set(hovered and 1 or 0)
        local active = (self.inf_sel == inf)
        local bg = UI.Mix(UI.Mix(C.CARD, C.CARD_H, tw:Get()), C.RED, active and 1 or 0)
        UI.Rect(S(6), x, y, colw, th, UI.Alpha(bg, alpha))
        self.inf_rects[#self.inf_rects + 1] = { id = id, inf = inf, x = x, y = y, w = colw, h = th }

        local col = (HORDE.Infusion_Colors and HORDE.Infusion_Colors[inf]) or C.WH
        local base = UI.Mat("infusion/infusion.png")
        local is = S(30)
        if base then UI.DrawMat(base, x + S(6), y + (th - is) / 2, is, is, UI.Alpha(col, alpha)) end
        if inf ~= HORDE.Infusion_None and HORDE.Infusion_Icons and HORDE.Infusion_Icons[inf] then
            local im = UI.Mat(HORDE.Infusion_Icons[inf])
            local s2 = S(20)
            if im then UI.DrawMat(im, x + S(6) + (is - s2) / 2, y + (th - s2) / 2, s2, s2, UI.Alpha(col, alpha)) end
        end
        local nm = UI.T("Infusion_" .. tostring(HORDE.Infusion_Names[inf]), tostring(HORDE.Infusion_Names[inf]))
        UI.Text(UI.Ellipsis(nm, f, colw - S(110)), f, x + S(44), y + th / 2, UI.Alpha(C.WH, alpha))
        if MySelf:Horde_HasInfusion(item.class, inf) == true then
            UI.Text(string.upper(UI.T("Game_Infused", "Infused")), f_b, x + colw - S(10), y + th / 2, UI.Alpha(active and C.WH or C.RED_TXT, alpha), TEXT_ALIGN_RIGHT)
        elseif inf ~= HORDE.Infusion_None then
            UI.Text(tostring(price) .. "$", f_b, x + colw - S(10), y + th / 2, UI.Alpha(C.WH, alpha), TEXT_ALIGN_RIGHT)
        end
    end

    local rows = math.ceil(#ids / 2)
    local dy = y0 + rows * (th + S(6)) + S(6)
    local nm = HORDE.Infusion_Names and HORDE.Infusion_Names[self.inf_sel]
    if nm then
        local desc = UI.T("Infusion_Description_" .. nm, HORDE.Infusion_Description and HORDE.Infusion_Description[self.inf_sel] or "")
        local lines = UI.Wrap(desc, UI.Font(13, false), W - S(4))
        local lh = S(18)
        for i, l in ipairs(lines) do
            local yy = dy + (i - 0.5) * lh
            if yy + lh / 2 < m.btn_top - S(6) then
                UI.Text(l, UI.Font(13, false), 0, yy, UI.Alpha(C.DIM, alpha))
            end
        end
    end
end

function DESC:Paint(w, h)
    local m = self:Metrics()
    local item = self.item

    local bh = m.banner_h
    UI.Rect(S(3), 0, 0, w, bh, C.RED)
    surface.SetDrawColor(C.RED)
    surface.DrawRect(0, 0, w, bh / 2)
    UI.Text(UI.T("Shop_UI_Description", "Description"), UI.Font(13.5, true), w / 2, bh / 2, C.WH, TEXT_ALIGN_CENTER)

    if not item then
        UI.Text(UI.T("Shop_UI_SelectItem", "Select an item"), UI.Font(13.5, false), w / 2, h / 2, C.DIM, TEXT_ALIGN_CENTER)
        return true
    end

    local a = math.Clamp(self.fade:Get(), 0, 1)
    local mt = self.mode_t:Get()

    self:DrawTitleBlock(m, a)
    if mt < 0.99 then self:DrawBlocks(m, (1 - mt) * a) end
    if mt > 0.01 then self:DrawInfusion(m, mt) end

    self.cells = {}
    local y = m.btn_top
    for _, row in ipairs(self.rows) do
        local n = #row
        local cw = (w - m.btn_gap * (n - 1)) / n
        for j, c in ipairs(row) do
            local x = (j - 1) * (cw + m.btn_gap)
            local tw = self.btn_tw[c.id]
            if not tw then tw = UI.Tween(0, 0.15); self.btn_tw[c.id] = tw end
            local active = c.fn ~= nil
            tw:Set((self.hover_id == c.id and active) and 1 or 0)
            pill_button(math.floor(x), y, math.floor(cw), m.btn_h, c.kind, tw:Get(), c.text, UI.Font(14.5, true))
            self.cells[#self.cells + 1] = { id = c.id, fn = c.fn, x = x, y = y, w = cw, h = m.btn_h }
        end
        y = y + m.btn_h + m.btn_gap
    end
    return true
end

function DESC:HitTest()
    local mx, my = self:CursorPos()
    if vgui.GetHoveredPanel() ~= self then return nil end
    for _, c in ipairs(self.cells or {}) do
        if mx >= c.x and mx <= c.x + c.w and my >= c.y and my <= c.y + c.h then
            return c.id, c
        end
    end
    if self.mode == "infusion" then
        for _, r in ipairs(self.inf_rects or {}) do
            if mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h then
                return r.id, r
            end
        end
    end
    return nil
end

function DESC:OnCursorMoved()
    local id, c = self:HitTest()
    if id ~= self.hover_id then
        self.hover_id = id
        if id and (c.fn or c.inf) then surface.PlaySound("UI/buttonrollover.wav") end
    end
    self:SetCursor((id and (c.fn or c.inf)) and "hand" or "arrow")
end

function DESC:OnCursorExited()
    self.hover_id = nil
end

function DESC:OnMousePressed(code)
    if code ~= MOUSE_LEFT then return end
    local id, c = self:HitTest()
    if not id then return end
    if c.inf then
        surface.PlaySound("UI/buttonclick.wav")
        self.inf_sel = c.inf
    elseif c.fn then
        surface.PlaySound("UI/buttonclick.wav")
        c.fn()
    end
end

vgui.Register("HordeShopDesc", DESC, "DPanel")

local VIEW = {}

function VIEW:Init()
    self.grid = vgui.Create("HordeShopGrid", self)
    self.desc = vgui.Create("HordeShopDesc", self)
    self.grid.OnSelect = function(item) self:Select(item) end
    self.grid.OnDoubleClick = function(item) self:QuickBuy(item) end
    self.grid.desc = self.desc
    self.grid:Build()
    local first = self.grid:FirstItem()
    if first then self:Select(first) end
end

function VIEW:SetShop(shop)
    self.shop = shop
    self.grid.shop = shop
    self.desc.shop = shop
end

function VIEW:Select(item)
    self.grid.selected = item
    self.desc:SetItem(item)
end

function VIEW:QuickBuy(item)
    if self.desc.item ~= item then self:Select(item) end
    self.desc:QuickBuy()
end

function VIEW:PerformLayout(w, h)
    local gap = S(14)
    local colw = math.floor((w - gap) / 2)
    self.grid:SetPos(0, 0)
    self.grid:SetSize(colw, h)
    self.desc:SetPos(colw + gap, 0)
    self.desc:SetSize(w - colw - gap, h)
end

function VIEW:Paint() return true end

vgui.Register("HordeShopItemsView", VIEW, "DPanel")
