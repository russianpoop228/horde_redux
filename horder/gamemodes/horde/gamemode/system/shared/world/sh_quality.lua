if not HORDE then return end

if SERVER then
    CreateConVar("horde_auto_price", 1,
        FCVAR_ARCHIVE + FCVAR_SERVER_CAN_EXECUTE + FCVAR_REPLICATED,
        "Автоматически рассчитывать цену/качество оружия, если цена не задана вручную.")
end

function HORDE:IsAutoPriceEnabled()
    local cv = GetConVar("horde_auto_price")
    return (not cv) or cv:GetInt() ~= 0
end

HORDE.Quality = {
    Common    = { id = 1, name = "Common",    color = Color(180, 180, 180), min = 0,    max = 499,  weight_mult = 1.00 },
    Unique    = { id = 2, name = "Unique",    color = Color(80,  200, 120), min = 500,  max = 999,  weight_mult = 1.05 },
    Rare      = { id = 3, name = "Rare",      color = Color(70,  140, 240), min = 1000, max = 1749, weight_mult = 1.10 },
    Epic      = { id = 4, name = "Epic",      color = Color(170, 90,  230), min = 1750, max = 2499, weight_mult = 1.18 },
    Legendary = { id = 5, name = "Legendary", color = Color(240, 170, 40),  min = 2500, max = 3249, weight_mult = 1.28 },
    Mythic    = { id = 6, name = "Mythic",    color = Color(230, 60,  60),  min = 3250, max = 1e9,  weight_mult = 1.40 },
}
HORDE.QualityOrder = { "Common", "Unique", "Rare", "Epic", "Legendary", "Mythic" }

function HORDE:GetQualityInfo(key)
    return self.Quality[key] or self.Quality.Common
end

function HORDE:GetQualityByPrice(price)
    price = tonumber(price) or 0
    for _, key in ipairs(self.QualityOrder) do
        local q = self.Quality[key]
        if price >= q.min and price <= q.max then return key end
    end
    return "Common"
end

function HORDE:GetQualityColor(key)
    return HORDE:GetQualityInfo(key).color
end

function HORDE:GetQualityStars(key)
    return HORDE:GetQualityInfo(key).id or 1
end

local DEFAULTS = {
    damage = 20, num = 1, delay = 0.1, clip = 30,
    range = 50, recoil = 1.0, reload = 2.5, melee = false,
}

local AOE_PATTERNS = {
    { "rpg", 3.0 }, { "law", 3.0 }, { "javelin", 3.0 }, { "apollo", 3.0 },
    { "m79", 2.6 }, { "m32", 2.6 }, { "gl_", 2.6 }, { "launcher", 2.6 },
    { "grenade", 2.4 }, { "nade", 2.4 }, { "sticky", 2.2 }, { "mine", 2.0 },
    { "flare", 1.5 }, { "molotov", 2.0 }, { "incendiary", 2.0 },
}

local function aoeMultiplier(class, dmgtype)
    local lc = string.lower(class or "")
    for _, p in ipairs(AOE_PATTERNS) do
        if string.find(lc, p[1], 1, true) then return p[2] end
    end
    if dmgtype == DMG_BLAST then return 2.4 end
    return 1.0
end

local function firstNumber(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if isnumber(v) and v == v then return v end
    end
    return nil
end

local function reloadFromAnimations(swep)
    local anims = swep.Animations
    if not istable(anims) then return nil end
    local r = anims["reload"] or anims["reload_empty"]
    if istable(r) then
        local t = firstNumber(r.Time)
        if t then return t end
        local fr = firstNumber(r.FrameRate)
        local cps = istable(r.Checkpoints) and r.Checkpoints[#r.Checkpoints] or nil
        if fr and cps then return cps / fr end
    end
    return nil
end

function HORDE:GetWeaponStats(class)
    if not isstring(class) or class == "" then return nil end
    local swep = weapons.GetStored(class) or weapons.Get(class)
    if not swep then return nil end

    local prim = swep.Primary or {}
    local isMelee = (prim.ClipSize == -1) or (swep.MeleeDamage ~= nil) or (swep.PrimaryBash == true)

    local stats = {
        class   = class,
        melee   = isMelee,
        ammo    = prim.Ammo,
        dmgtype = swep.DamageType,
    }

    if isMelee then
        stats.damage = firstNumber(swep.MeleeDamage, swep.Melee2Damage, DEFAULTS.damage)
        stats.num    = 1
        stats.delay  = firstNumber(swep.MeleeTime, swep.MeleeAttackTime, 0.6)
        stats.clip   = 1
        stats.reload = 0
        stats.range  = (firstNumber(swep.MeleeRange, 75) or 75) * 0.025
        stats.recoil = 0
    else
        stats.damage = firstNumber(swep.Damage, prim.Damage, DEFAULTS.damage)
        stats.num    = firstNumber(swep.Num, prim.NumShots, DEFAULTS.num)
        stats.delay  = firstNumber(swep.Delay, prim.Delay, DEFAULTS.delay)
        stats.clip   = firstNumber(prim.ClipSize, DEFAULTS.clip)
        stats.reload = firstNumber(reloadFromAnimations(swep), DEFAULTS.reload)
        stats.range  = firstNumber(swep.Range, DEFAULTS.range)
        stats.recoil = firstNumber(swep.Recoil, DEFAULTS.recoil)
    end

    stats.damage = math.max(stats.damage, 1)
    stats.num    = math.max(stats.num, 1)
    stats.delay  = math.max(stats.delay, 0.01)
    stats.clip   = math.max(stats.clip, 1)
    stats.reload = math.max(stats.reload, 0)
    stats.range  = math.max(stats.range, 1)
    stats.recoil = math.max(stats.recoil, 0)

    stats.aoe = aoeMultiplier(class, stats.dmgtype)
    return stats
end

function HORDE:_NicePrice(v)
    if v >= 1000 then return math.Round(v / 500) * 500 end
    if v >= 200 then return math.Round(v / 50) * 50 end
    return math.Round(v / 25) * 25
end

function HORDE:CalculateWeaponPrice(class)
    local s = self:GetWeaponStats(class)
    if not s then return nil end

    local burst     = s.damage * s.num / s.delay
    local magTime   = s.clip * s.delay
    local sustained = (s.clip * s.damage * s.num) / math.max(magTime + s.reload, 0.01)

    local rangeF = math.Clamp(s.range / 80, 0.45, 1.5)
    local accF   = math.Clamp(1.2 - s.recoil * 0.15, 0.6, 1.2)

    local magCost = s.clip * (self.default_ammo_price or 10)
    local ammoF   = math.Clamp(1.3 - magCost / 500, 0.7, 1.3)

    local E = (0.35 * burst + 0.65 * sustained) * rangeF * accF * ammoF * s.aoe
    local price = math.Clamp(self:_NicePrice(E ^ 0.65 * 60), 50, 4000)
    return price, E, s
end

HORDE._weaponPriceCache = HORDE._weaponPriceCache or {}

function HORDE:CalculateWeaponPriceCached(class)
    local c = self._weaponPriceCache[class]
    if c then return c.price, c.eff, c.stats end
    local price, eff, stats = self:CalculateWeaponPrice(class)
    self._weaponPriceCache[class] = { price = price, eff = eff, stats = stats }
    return price, eff, stats
end

function HORDE:CalculateSkullTokens(price, quality)
    local q = self:GetQualityInfo(quality)
    if q.id < 5 then return 0 end
    local t = math.floor(((tonumber(price) or 0) - 2500) / 500)
    return math.Clamp(t, 1, 10)
end

HORDE.default_weights = {
    Melee = 3, Pistol = 3, SMG = 5, Shotgun = 6, Rifle = 8, MG = 10,
    Explosive = 6, Special = 5, Equipment = 2, Attachment = 1, Gadget = 2,
    ["Combine Issued"] = 5,
}

function HORDE:ComputeItemAutoValues(class, category, manual_price, manual_quality)
    local out = { auto = false }

    local price, eff, stats = self:CalculateWeaponPriceCached(class)
    out.stats = stats
    out.efficiency = eff

    if manual_price ~= nil then
        out.price = manual_price
    elseif price then
        out.price = price
        out.auto = true
    else
        out.price = 0
    end

    if manual_quality ~= nil then
        out.quality = manual_quality
    else
        out.quality = self:GetQualityByPrice(out.price)
    end

    local baseW = self.default_weights[category] or 5
    out.weight = math.max(1, math.Round(baseW * self:GetQualityInfo(out.quality).weight_mult))

    out.skull_tokens = self:CalculateSkullTokens(out.price, out.quality)
    return out
end

function HORDE:GetKnownWeaponClasses()
    local out = {}
    local seen = {}
    local function add(cls)
        if isstring(cls) and cls ~= "" and not seen[cls] then
            seen[cls] = true
            out[#out + 1] = cls
        end
    end

    if CLIENT then
        for cls, _ in pairs(list.Get("Weapon") or {}) do add(cls) end
    end
    for cls, _ in pairs(weapons.GetList() or {}) do add(cls) end

    table.sort(out)
    return out
end

MsgC(Color(220, 30, 56), "[HORDE] ", color_white, "Quality & auto-price system loaded\n")
