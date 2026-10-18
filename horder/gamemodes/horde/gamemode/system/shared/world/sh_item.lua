HORDE.items = {}

HORDE.items_defaults = HORDE.items_defaults or {}
HORDE.ItemsCustom = HORDE.ItemsCustom or {}
HORDE.ItemsRemoved = HORDE.ItemsRemoved or {}
HORDE.ItemOverrides = HORDE.ItemOverrides or {}

HORDE.ENTITY_PROPERTY_WPN = 1
HORDE.ENTITY_PROPERTY_GIVE = 2
HORDE.ENTITY_PROPERTY_DROP = 3
HORDE.ENTITY_PROPERTY_ARMOR = 4
HORDE.ENTITY_PROPERTY_GADGET = 5

HORDE.categories = { "Melee", "Pistol", "SMG", "Shotgun", "Rifle", "MG", "Explosive", "Special", "Equipment",
    "Attachment", "Gadget", "Combine Issued" }
HORDE.entity_categories = { "Special", "Equipment" }
HORDE.arccw_attachment_categories = { "Optic", "Underbarrel", "Tactical", "Barrel", "Muzzle", "Magazine", "Stock",
    "Slide", "Ammo Type", "Perk" }
HORDE.starter_weapons = {}

local _items_dirty = false
local _items_debounce_pending = false

HORDE.relic_weapon_subclass = {
    horde_void_projector = "Necromancer",
    horde_solar_seal     = "Artificer",
    horde_astral_relic   = "Warlock",
    horde_carcass        = "Carcass",
    horde_pheropod       = "Hatcher",
    horde_engiwrench     = "Engineer",
    horde_wardenstaff    = "Warden",
    horde_ghoul_claws    = "Ghoul" }

HORDE.unarmed_kept_weapons = {
    weapon_horde_medkit = true,
    horde_welder        = true }

HORDE.relic_no_upgrade = {
    horde_engiwrench   = true,
    horde_wardenstaff  = true,
    horde_ghoul_claws  = true }

HORDE.subclass_unsellable_weapons = {
    Necromancer = { "horde_void_projector" },
    Artificer   = { "horde_solar_seal" },
    Warlock     = { "horde_astral_relic" },
    Carcass     = { "horde_carcass" },
    Hatcher     = { "horde_pheropod" },
    Engineer    = { "horde_engiwrench" },
    Warden      = { "horde_wardenstaff" },
    Ghoul       = { "horde_ghoul_claws" } }

HORDE.max_weight = 15
HORDE.default_ammo_price = 10

function HORDE:GetItemField(class, field, fallback)
    if HORDE.ItemsRemoved[class] then return fallback end
    local base = HORDE.items[class] or HORDE.ItemsCustom[class] or HORDE.items_defaults[class]
    if not base then return fallback end
    local ov = HORDE.ItemOverrides[class]
    if ov and ov[field] ~= nil then return ov[field] end
    if base[field] ~= nil then return base[field] end
    return fallback
end

function HORDE:RegisterItem(tbl)
    if not tbl or type(tbl) ~= "table" then
        ErrorNoHaltWithStack("[Horde Items] RegisterItem: expected table\n")
        return
    end

    local class = tbl.class or tbl.Class or tbl.ClassName
    if not class or class == "" then
        ErrorNoHaltWithStack("[Horde Items] RegisterItem: no Class\n")
        return
    end
    tbl.class = class

    local category = tbl.category or tbl.Category
    local name = tbl.name or tbl.Name or tbl.PrintName
    local price = tbl.price or tbl.Price
    local weight = tbl.weight or tbl.Weight
    local description = tbl.description or tbl.Description

    if category == "Gadget" and HORDE.gadgets and HORDE.gadgets[class] then
        local g = HORDE.gadgets[class]
        if (not name or name == "") and g.PrintName then
            name = g.PrintName
        end
        if (not description or description == "") and g.Description then
            description = description or ""
        end
        if not (tbl.entity_properties or tbl.EntityProperties) then
            tbl.entity_properties = { type = HORDE.ENTITY_PROPERTY_GADGET }
        end
    end

    local quality = tbl.quality or tbl.Quality
    local manual_price   = (price ~= nil)
    local manual_quality = (quality ~= nil)
    local auto_values    = nil

    if HORDE.ComputeItemAutoValues and (price == nil or quality == nil or weight == nil) then
        auto_values = HORDE:ComputeItemAutoValues(class, category, price, quality)
        if auto_values then
            if price   == nil then price   = auto_values.price end
            if quality == nil then quality = auto_values.quality end
            if weight  == nil then weight  = auto_values.weight end
        end
    end

    if category == nil or name == nil or name == "" or price == nil or weight == nil or description == nil then
        ErrorNoHaltWithStack("[Horde Items] RegisterItem: missing required fields for '" .. tostring(class) .. "'\n")
        return
    end
    if name == "" or class == "" then
        ErrorNoHaltWithStack("[Horde Items] RegisterItem: empty name/class\n")
        return
    end
    if not table.HasValue(HORDE.categories, category) then
        ErrorNoHaltWithStack("[Horde Items] RegisterItem: unknown category '" .. tostring(category) .. "' for '" .. class .. "'\n")
        return
    end
    if price < 0 or weight < 0 then
        ErrorNoHaltWithStack("[Horde Items] RegisterItem: negative price/weight for '" .. class .. "'\n")
        return
    end

    local item = {}
    item.category = category
    item.name = name
    item.class = class
    item.price = price
    item.skull_tokens = tbl.skull_tokens or tbl.SkullTokens or 0
    item.weight = weight
    item.description = description
    item.quality = quality or (HORDE.GetQualityByPrice and HORDE:GetQualityByPrice(price)) or nil
    local pm = tbl.price_manual
    if pm == nil then pm = tbl.PriceManual end
    if pm == nil then pm = manual_price end
    item.price_manual = pm
    item.whitelist = tbl.whitelist or tbl.Whitelist
    item.ammo_price = tbl.ammo_price or tbl.AmmoPrice or -1
    item.secondary_ammo_price = tbl.secondary_ammo_price or tbl.SecondaryAmmoPrice or -1

    if tbl.entity_properties or tbl.EntityProperties then
        item.entity_properties = tbl.entity_properties or tbl.EntityProperties
    else
        item.entity_properties = { type = HORDE.ENTITY_PROPERTY_WPN }
    end
    if item.class == "_horde_armor_100" then
        item.entity_properties = { type = HORDE.ENTITY_PROPERTY_ARMOR, armor = 100 }
    end
    local shop_icon = tbl.shop_icon or tbl.ShopIcon
    if shop_icon and shop_icon ~= "" then
        item.shop_icon = shop_icon
    end
    item.total_levels = 0
    local levels = tbl.levels or tbl.Levels
    if levels then
        item.levels = levels
        local total_levels = 0
        for _, level in pairs(levels) do
            total_levels = total_levels + level
        end
        item.total_levels = total_levels
    end
    item.dmgtype = tbl.dmgtype or tbl.Dmgtype or nil
    item.infusions = tbl.infusions or tbl.Infusions or nil
    item.starter_classes = tbl.starter_classes or tbl.StarterClasses or nil
    item.hidden = tbl.hidden or tbl.Hidden or nil

    item.CanPurchase = tbl.CanPurchase
    item.CanSell = tbl.CanSell
    item.OnPickup = tbl.OnPickup
    item.OnUpgrade = tbl.OnUpgrade

    if HORDE.items[item.class] then
        MsgC(Color(255, 255, 0), "[Horde Items] Item overridden: " .. item.class .. "\n")
    end

    HORDE.items[item.class] = item
    if not HORDE.items_defaults[item.class] then
        HORDE.items_defaults[item.class] = item
    end

    hook.Run("Horde_OnItemRegistered", item)
    HORDE:SetItemsData()
end

function HORDE:CreateItem(category, name, class, price, weight, description, whitelist, ammo_price, secondary_ammo_price,
                          entity_properties, shop_icon, levels, skull_tokens, dmgtype, infusions, starter_classes, hidden,
                          quality, price_manual)
    return self:RegisterItem({
        category = category,
        name = name,
        class = class,
        price = price,
        weight = weight,
        description = description,
        whitelist = whitelist,
        ammo_price = ammo_price,
        secondary_ammo_price = secondary_ammo_price,
        entity_properties = entity_properties,
        shop_icon = shop_icon,
        levels = levels,
        skull_tokens = skull_tokens,
        dmgtype = dmgtype,
        infusions = infusions,
        starter_classes = starter_classes,
        hidden = hidden,
        quality = quality,
        price_manual = price_manual })
end

function HORDE:CreateGadgetItem(class, price, weight, whitelist, levels, dmgtype, hidden)
    local gadget = HORDE.gadgets[class]
    HORDE:CreateItem("Gadget", gadget.PrintName, class, price, weight, "", whitelist, 10, -1,
        { type = HORDE.ENTITY_PROPERTY_GADGET }, nil, levels, nil, dmgtype, nil, nil, hidden)
end

HORDE.InvalidateHordeItemCache = 1
HORDE.CachedHordeItems = nil
HORDE.GetCachedHordeItems = function()
    if HORDE.InvalidateHordeItemCache == 1 then
        local tab = util.TableToJSON(HORDE.items)
        local str = util.Compress(tab)
        HORDE.CachedHordeItems = str
        HORDE.InvalidateHordeItemCache = 0
    end
    return HORDE.CachedHordeItems
end

function HORDE:SyncItems()
    local str = HORDE.GetCachedHordeItems()
    if player then
        for _, ply in pairs(player.GetAll()) do
            net.Start("Horde_SyncItems")
            net.WriteUInt(string.len(str), 32)
            net.WriteData(str, string.len(str))
            net.Send(ply)
        end
    end
end

function HORDE:SetItemsData(force)
    if not SERVER then return end
    if GetConVarNumber("horde_default_item_config") == 1 then return end

    if not force then
        _items_dirty = true
        if _items_debounce_pending then return end
        _items_debounce_pending = true
        timer.Simple(0, function()
            _items_debounce_pending = false
            if not _items_dirty then return end
            _items_dirty = false
            HORDE:SetItemsData(true)
        end)
        return
    end

    _items_dirty = false
    if not file.IsDir("horde", "DATA") then
        file.CreateDir("horde")
    end

    file.Write("horde/items.txt", util.TableToJSON(HORDE.items))
    HORDE.InvalidateHordeItemCache = 1
    HORDE:SyncItems()
end

function HORDE:PersistItemsConfig(tbl)
    if not SERVER or not istable(tbl) then return end
    if not file.IsDir("horde", "DATA") then
        file.CreateDir("horde")
    end
    file.Write("horde/items.txt", util.TableToJSON(tbl))
end

local function GetStarterWeapons()
    HORDE.starter_weapons = {}
    for class, item in pairs(HORDE.items) do
        if item.starter_classes then
            for _, starter_subclass in pairs(item.starter_classes) do
                if not HORDE.starter_weapons[starter_subclass] then HORDE.starter_weapons[starter_subclass] = {} end
                table.insert(HORDE.starter_weapons[starter_subclass], class)
            end
        end
    end
end

local function GetItemsData()
    if not SERVER then return end
    if not file.IsDir("horde", "DATA") then
        file.CreateDir("horde")
    end

    HORDE._registering_default_items = true
    HORDE:GetDefaultItemsData()
    HORDE._registering_default_items = false

    local raw = file.Read("horde/items.txt", "DATA")
    if raw then
        local t = util.JSONToTable(raw)
        if istable(t) then
            for _, item in pairs(t) do
                if istable(item) then
                    if item.ammo_price == nil then item.ammo_price = -1 end
                    if item.secondary_ammo_price == nil then item.secondary_ammo_price = -1 end
                    if item.quality == nil and HORDE.GetQualityByPrice then
                        item.quality = HORDE:GetQualityByPrice(item.price)
                    end
                    if item.price_manual == nil then item.price_manual = true end
                end
            end
            local ok, verr = HORDE.Validate.Items(t)
            if not ok then
                print("[HORDE] - Item config file validation failed: " .. tostring(verr))
                HORDE:SendNotification("Item config file validation failed! Please update your file or delete it.", 1)
            else
                local preserve_fns = { "CanPurchase", "CanSell", "OnPickup", "OnUpgrade" }
                for class, item in pairs(t) do
                    local base = HORDE.items[class] or HORDE.items_defaults[class]
                    if istable(base) then
                        for _, fn in ipairs(preserve_fns) do
                            if type(base[fn]) == "function" and item[fn] == nil then
                                item[fn] = base[fn]
                            end
                        end
                    end
                    HORDE.items[class] = item
                end
                print("[HORDE] - Loaded custom item config (merged with defaults).")
            end
        end
    end

    GetStarterWeapons()
    HORDE.InvalidateHordeItemCache = 1
    HORDE:SyncItems()
end

function HORDE:GetDefaultGadgets()
end

function HORDE:GetDefaultItemInfusions()
    local melee_blunt_infusions = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE.Infusion_Concussive, HORDE
        .Infusion_Quality, HORDE.Infusion_Quicksilver, HORDE.Infusion_Rejuvenating }
    local melee_slash_infusions = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE.Infusion_Hemo, HORDE
        .Infusion_Quality, HORDE.Infusion_Quicksilver, HORDE.Infusion_Rejuvenating }
    HORDE.items["arccw_horde_stunstick"].infusions = melee_blunt_infusions
    HORDE.items["arccw_horde_crowbar"].infusions = melee_blunt_infusions
    HORDE.items["arccw_horde_knife"].infusions = melee_slash_infusions
    HORDE.items["arccw_horde_machete"].infusions = melee_slash_infusions
    HORDE.items["arccw_horde_axe"].infusions = melee_slash_infusions
    HORDE.items["arccw_horde_katana"].infusions = { HORDE.Infusion_Chrono, HORDE.Infusion_Hemo, HORDE.Infusion_Flaming,
        HORDE.Infusion_Arctic, HORDE.Infusion_Galvanizing, HORDE.Infusion_Septic, HORDE.Infusion_Quality, HORDE
        .Infusion_Quicksilver, HORDE.Infusion_Rejuvenating }
    HORDE.items["arccw_horde_bat"].infusions = melee_blunt_infusions
    HORDE.items["arccw_horde_chainsaw"].infusions = melee_slash_infusions
    HORDE.items["arccw_horde_jotuun"].infusions = { HORDE.Infusion_Chrono, HORDE.Infusion_Arctic, HORDE.Infusion_Septic,
        HORDE.Infusion_Quality, HORDE.Infusion_Quicksilver, HORDE.Infusion_Rejuvenating }
    HORDE.items["arccw_horde_inferno_blade"].infusions = { HORDE.Infusion_Chrono, HORDE.Infusion_Flaming, HORDE
        .Infusion_Quality, HORDE.Infusion_Quicksilver, HORDE.Infusion_Rejuvenating }
    HORDE.items["arccw_horde_mjollnir"].infusions = { HORDE.Infusion_Chrono, HORDE.Infusion_Galvanizing, HORDE
        .Infusion_Quality, HORDE.Infusion_Quicksilver, HORDE.Infusion_Rejuvenating }
    HORDE.items["arccw_horde_zweihander"].infusions = { HORDE.Infusion_Chrono, HORDE.Infusion_Quality, HORDE
        .Infusion_Quicksilver, HORDE.Infusion_Rejuvenating }

    local ballistic_infusions_light = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE.Infusion_Impaling, HORDE
        .Infusion_Quality, HORDE.Infusion_Quicksilver }
    HORDE.items["arccw_horde_9mm"].infusions = ballistic_infusions_light
    HORDE.items["arccw_horde_medic_9mm"].infusions = ballistic_infusions_light
    HORDE.items["arccw_horde_357"].infusions = ballistic_infusions_light
    HORDE.items["arccw_go_glock"].infusions = ballistic_infusions_light
    HORDE.items["arccw_go_usp"].infusions = ballistic_infusions_light
    HORDE.items["arccw_go_p2000"].infusions = ballistic_infusions_light
    HORDE.items["arccw_go_p250"].infusions = ballistic_infusions_light
    HORDE.items["arccw_go_r8"].infusions = ballistic_infusions_light
    HORDE.items["arccw_go_deagle"].infusions = ballistic_infusions_light
    HORDE.items["arccw_horde_m1911"].infusions = ballistic_infusions_light
    HORDE.items["arccw_horde_anaconda"].infusions = ballistic_infusions_light
    HORDE.items["arccw_go_cz75"].infusions = ballistic_infusions_light
    HORDE.items["arccw_go_m9"].infusions = ballistic_infusions_light
    HORDE.items["arccw_go_fiveseven"].infusions = ballistic_infusions_light
    HORDE.items["arccw_horde_tec9"].infusions = ballistic_infusions_light
    HORDE.items["arccw_horde_tmp"].infusions = ballistic_infusions_light
    HORDE.items["arccw_horde_akimbo_glock17"].infusions = ballistic_infusions_light
    HORDE.items["arccw_horde_akimbo_m9"].infusions = ballistic_infusions_light
    HORDE.items["arccw_horde_akimbo_deagle"].infusions = ballistic_infusions_light

    local ballistic_infusions_smgs = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE.Infusion_Impaling, HORDE
        .Infusion_Quality, HORDE.Infusion_Quicksilver }
    HORDE.items["arccw_horde_smg1"].infusions = ballistic_infusions_light
    HORDE.items["arccw_go_mac10"].infusions = ballistic_infusions_smgs
    HORDE.items["arccw_horde_mp40"].infusions = ballistic_infusions_smgs
    HORDE.items["arccw_horde_uzi"].infusions = ballistic_infusions_smgs
    HORDE.items["arccw_go_mp5"].infusions = ballistic_infusions_smgs
    HORDE.items["arccw_go_ump"].infusions = ballistic_infusions_smgs
    HORDE.items["arccw_go_bizon"].infusions = ballistic_infusions_smgs
    HORDE.items["arccw_go_p90"].infusions = ballistic_infusions_smgs

    local infusions_medic = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE.Infusion_Impaling, HORDE
        .Infusion_Quality, HORDE.Infusion_Rejuvenating, HORDE.Infusion_Septic }
    HORDE.items["arccw_horde_mp5k"].infusions = infusions_medic
    HORDE.items["arccw_horde_mp9m"].infusions = infusions_medic
    HORDE.items["arccw_horde_mp7m"].infusions = infusions_medic
    HORDE.items["arccw_horde_vector"].infusions = infusions_medic
    HORDE.items["arccw_horde_medic_acr"].infusions = infusions_medic

    HORDE.items["arccw_horde_shotgun"].infusions = ballistic_infusions_light
    HORDE.items["arccw_horde_nova"].infusions = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE.Infusion_Impaling,
        HORDE.Infusion_Quality, HORDE.Infusion_Quicksilver, HORDE.Infusion_Hemo, HORDE
        .Infusion_Concussive, HORDE.Infusion_Arctic, HORDE.Infusion_Galvanizing, HORDE.Infusion_Septic, HORDE
        .Infusion_Flaming }
    HORDE.items["arccw_horde_870"].infusions = ballistic_infusions_light
    HORDE.items["arccw_horde_mag7"].infusions = ballistic_infusions_light
    HORDE.items["arccw_horde_m1014"].infusions = ballistic_infusions_light
    HORDE.items["arccw_horde_doublebarrel"].infusions = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE
        .Infusion_Impaling, HORDE.Infusion_Quality, HORDE.Infusion_Concussive}
    HORDE.items["arccw_horde_trenchgun"].infusions = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE
        .Infusion_Impaling, HORDE.Infusion_Quality, HORDE.Infusion_Flaming}
    HORDE.items["arccw_horde_spas12"].infusions = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE
        .Infusion_Impaling, HORDE.Infusion_Quality}
    HORDE.items["arccw_horde_striker"].infusions = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE
        .Infusion_Impaling, HORDE.Infusion_Quality}
    HORDE.items["arccw_horde_aa12"].infusions = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE
        .Infusion_Impaling, HORDE.Infusion_Quality}
    HORDE.items["arccw_horde_lockpick"].infusions = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE
        .Infusion_Impaling, HORDE.Infusion_Quality}

    local ballistic_infusions_rifles = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE.Infusion_Impaling, HORDE
        .Infusion_Quality, HORDE.Infusion_Quicksilver}
    HORDE.items["arccw_horde_ar15"].infusions = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE
        .Infusion_Impaling, HORDE.Infusion_Quality, HORDE.Infusion_Quicksilver, HORDE
        .Infusion_Hemo, HORDE.Infusion_Concussive, HORDE.Infusion_Arctic, HORDE.Infusion_Galvanizing, HORDE
        .Infusion_Septic, HORDE.Infusion_Flaming }
    HORDE.items["arccw_horde_famas"].infusions = ballistic_infusions_rifles
    HORDE.items["arccw_horde_ace"].infusions = ballistic_infusions_rifles
    HORDE.items["arccw_horde_ak47"].infusions = ballistic_infusions_rifles
    HORDE.items["arccw_horde_m4"].infusions = ballistic_infusions_rifles
    HORDE.items["arccw_horde_sg556"].infusions = ballistic_infusions_rifles
    HORDE.items["arccw_horde_aug"].infusions = ballistic_infusions_rifles
    HORDE.items["arccw_horde_f2000"].infusions = ballistic_infusions_rifles
    HORDE.items["arccw_horde_tavor"].infusions = ballistic_infusions_rifles
    HORDE.items["arccw_horde_scarl"].infusions = ballistic_infusions_rifles
    HORDE.items["arccw_horde_ar2"].infusions = ballistic_infusions_rifles

    local ballistic_infusions_sniper_rifles = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE.Infusion_Impaling,
        HORDE.Infusion_Quality, HORDE.Infusion_Quicksilver}
    HORDE.items["arccw_horde_winchester"].infusions = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE
        .Infusion_Impaling, HORDE.Infusion_Quality, HORDE.Infusion_Quicksilver, HORDE
        .Infusion_Hemo, HORDE.Infusion_Concussive, HORDE.Infusion_Arctic, HORDE.Infusion_Galvanizing, HORDE
        .Infusion_Septic, HORDE.Infusion_Flaming }
    HORDE.items["arccw_horde_m200"].infusions = ballistic_infusions_sniper_rifles
    HORDE.items["arccw_horde_ssg08"].infusions = ballistic_infusions_sniper_rifles
    HORDE.items["arccw_horde_awp"].infusions = ballistic_infusions_sniper_rifles
    HORDE.items["arccw_horde_scarh"].infusions = ballistic_infusions_sniper_rifles
    HORDE.items["arccw_horde_g3"].infusions = ballistic_infusions_sniper_rifles
    HORDE.items["arccw_horde_fal"].infusions = ballistic_infusions_sniper_rifles
    HORDE.items["arccw_horde_barret"].infusions = ballistic_infusions_sniper_rifles

    HORDE.items["arccw_horde_heat_crossbow"].infusions = ballistic_infusions_sniper_rifles

    HORDE.items["arccw_horde_medic_rifle"].infusions = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE
        .Infusion_Impaling, HORDE.Infusion_Quality, HORDE.Infusion_Quicksilver, HORDE.Infusion_Septic, HORDE.Infusion_Rejuvenating }
    HORDE.items["arccw_horde_m16m203"].infusions = ballistic_infusions_rifles

    local ballistic_infusions_mg_rifles = { HORDE.Infusion_Ruination, HORDE.Infusion_Chrono, HORDE.Infusion_Impaling,
        HORDE.Infusion_Quality, HORDE.Infusion_Titanium}
    HORDE.items["arccw_horde_negev"].infusions = ballistic_infusions_mg_rifles
    HORDE.items["arccw_horde_m249"].infusions = ballistic_infusions_mg_rifles
    HORDE.items["arccw_horde_l86"].infusions = ballistic_infusions_mg_rifles
    HORDE.items["arccw_horde_mg4"].infusions = ballistic_infusions_mg_rifles
    HORDE.items["arccw_horde_m240"].infusions = ballistic_infusions_mg_rifles
    HORDE.items["arccw_horde_rpd"].infusions = ballistic_infusions_mg_rifles
    HORDE.items["arccw_horde_aug_hbar"].infusions = ballistic_infusions_mg_rifles
    HORDE.items["arccw_horde_gau"].infusions = ballistic_infusions_mg_rifles

    local projectile_infusions = {}
    HORDE.items["weapon_frag"].infusions = {}
    HORDE.items["weapon_rpg"].infusions = {}
    HORDE.items["arccw_horde_m79"].infusions = { HORDE.Infusion_Quality, HORDE.Infusion_Quicksilver, HORDE
        .Infusion_Chrono, HORDE.Infusion_Ruination, HORDE.Infusion_Flaming, HORDE.Infusion_Arctic, HORDE
        .Infusion_Galvanizing }
    HORDE.items["horde_sticky_launcher"].infusions = {}
    HORDE.items["arccw_horde_m32"].infusions = {}
    HORDE.items["arccw_horde_rpg7"].infusions = {}
    HORDE.items["arccw_horde_law"].infusions = {}
    HORDE.items["arccw_horde_apollo"].infusions = { HORDE.Infusion_Quality }
end

function HORDE:GetDefaultItemsData()
    HORDE:GetDefaultGadgets()
    HORDE:GetDefaultItemInfusions()

    local n = table.Count(HORDE.items)
    print("[HORDE] - Loaded default item config (" .. n .. " items).")
end

HORDE.GetArcCWAttachments = function()
    if ArcCWInstalled == true then
        local free_cvar = GetConVar("horde_arccw_attinv_free")
        if not free_cvar or free_cvar:GetInt() == 0 then
            print("[HORDE] ArcCW attachments are loaded from modules/items/attachment/ (loader).")
        end
    end
end

function HORDE:IsWatchTower(ent)
    return ent:IsValid() and ent.Horde_WatchTower
end

hook.Add("Horde_AllModulesLoaded", "Horde_RegisterDefaultShopTabs", function()
    if not HORDE.RegisterShopTab then return end
    local have = {}
    for _, tab in ipairs(HORDE._shop_tabs or {}) do have[tab.Name] = true end
    for i, cat in ipairs(HORDE.categories or {}) do
        if not have[cat] then
            HORDE:RegisterShopTab({ Name = cat, Order = i })
        end
    end
end)

if SERVER then
    util.AddNetworkString("Horde_SetItemsData")

    hook.Add("Horde_AllModulesLoaded", "Horde_InitItems", function()
        if GetConVar("horde_external_lua_config"):GetString() and GetConVar("horde_external_lua_config"):GetString() ~= "" then
        else
            if GetConVarNumber("horde_default_item_config") == 0 then
                GetItemsData()
            else
                HORDE._registering_default_items = true
                HORDE:GetDefaultItemsData()
                HORDE._registering_default_items = false
                GetStarterWeapons()
                HORDE.InvalidateHordeItemCache = 1
                HORDE:SyncItems()
            end
        end
    end)

    hook.Add("PlayerInitialSpawn", "Horde_SyncItemsOnJoin", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                local str = HORDE.GetCachedHordeItems and HORDE.GetCachedHordeItems()
                if str then
                    net.Start("Horde_SyncItems")
                    net.WriteUInt(string.len(str), 32)
                    net.WriteData(str, string.len(str))
                    net.Send(ply)
                end
            end
        end)
    end)

    net.Receive("Horde_SetItemsData", function(len, ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        if not HORDE:AllowNetRequest(ply, "set_items_data", 2) then return end
        local tbl, err = HORDE:ReadCompressedJSON()
        if not tbl then
            HORDE:SendNotification("Item config rejected: " .. tostring(err), 1, ply)
            return
        end
        local ok, verr = HORDE.Validate.Items(tbl)
        if not ok then
            HORDE:SendNotification("Item config rejected: " .. tostring(verr), 1, ply)
            return
        end

        local cv = GetConVar("horde_default_item_config")
        if cv and cv:GetInt() ~= 0 then
            cv:SetInt(0)
        end

        HORDE:PersistItemsConfig(tbl)
        local deferred = HORDE:QueueConfigApply("items", function()
            local preserve_fns = { "CanPurchase", "CanSell", "OnPickup", "OnUpgrade" }
            local prev = HORDE.items
            for class, item in pairs(tbl) do
                local base = (prev and prev[class]) or HORDE.items_defaults[class]
                if istable(base) then
                    for _, fn in ipairs(preserve_fns) do
                        if type(base[fn]) == "function" and item[fn] == nil then
                            item[fn] = base[fn]
                        end
                    end
                end
            end
            HORDE.items = tbl
            HORDE.InvalidateHordeItemCache = 1
            HORDE:SyncItems()
        end)
        HORDE:SendNotification(deferred and "Item config saved. It will apply on the next wave."
            or "Item config applied.", 0, ply)

        HORDE:LogItemConfigChange(ply, tbl)
    end)
end

function HORDE:LogItemConfigChange(ply, tbl)
    if not SERVER then return end
    local count = 0
    for _ in pairs(tbl or {}) do count = count + 1 end
    local who = IsValid(ply) and (ply:Nick() .. " (" .. ply:SteamID() .. ")") or "console"
    local line = string.format("[%s] %s saved item config (%d items)\n",
        os.date("%Y-%m-%d %H:%M:%S"), who, count)
    if not file.IsDir("horde", "DATA") then file.CreateDir("horde") end
    file.Append("horde/itemconfig_log.txt", line)
    print("[HORDE] " .. line)
end

if SERVER then
    util.AddNetworkString("Horde_SetUpgrades")
end

if CLIENT then
    net.Receive("Horde_SetUpgrades", function(len, ply)
        local class = net.ReadString()
        local level = net.ReadUInt(8)
        MySelf:Horde_SetUpgrade(class, level)
    end)
end

local plymeta = FindMetaTable("Player")

function plymeta:Horde_GetUpgrade(class)
    if not self.Horde_Upgrades then self.Horde_Upgrades = {} end
    return self.Horde_Upgrades[class] or 0
end

function plymeta:Horde_SetUpgrade(class, level)
    if not self.Horde_Upgrades then self.Horde_Upgrades = {} end
    if SERVER then
        net.Start("Horde_SetUpgrades")
        net.WriteString(class)
        net.WriteUInt(level, 8)
        net.Send(self)
    end
    self.Horde_Upgrades[class] = level
end

function HORDE:IsMeleeItem(class)
    return HORDE.items[class] and HORDE.items[class].category == "Melee"
end

function HORDE:IsPistolItem(class)
    return HORDE.items[class] and HORDE.items[class].category == "Pistol"
end

function HORDE:IsSMGItem(class)
    return HORDE.items[class] and HORDE.items[class].category == "SMG"
end

function HORDE:IsRifleItem(class)
    return HORDE.items[class] and HORDE.items[class].category == "Rifle"
end

function HORDE:IsShotgunItem(class)
    return HORDE.items[class] and HORDE.items[class].category == "Shotgun"
end

function HORDE:IsMGItem(class)
    return HORDE.items[class] and HORDE.items[class].category == "MG"
end

function HORDE:IsExplosiveItem(class)
    return HORDE.items[class] and HORDE.items[class].category == "Explosive"
end

function HORDE:IsSpecialItem(class)
    return HORDE.items[class] and HORDE.items[class].category == "Special"
end

function HORDE:IsEquipmentItem(class)
    return HORDE.items[class] and HORDE.items[class].category == "Equipment"
end

function HORDE:IsAttachmentItem(class)
    return HORDE.items[class] and HORDE.items[class].category == "Attachment"
end

function HORDE:IsGadgetItem(class)
    return HORDE.items[class] and HORDE.items[class].category == "Gadget"
end
