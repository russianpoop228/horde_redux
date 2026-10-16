if SERVER then
util.AddNetworkString("Horde_SetSpell")
util.AddNetworkString("Horde_UnsetSpell")
util.AddNetworkString("Horde_SetSpellUpgrades")
end

HORDE.spells = {}

HORDE.Spell_Slot_LMB = 0
HORDE.Spell_Slot_RMB = 1
HORDE.Spell_Slot_Utility = 2
HORDE.Spell_Slot_Reload = 3

HORDE.Spell_Slots = {
    [HORDE.Spell_Slot_LMB] = "LMB",
    [HORDE.Spell_Slot_RMB] = "RMB",
    [HORDE.Spell_Slot_Utility] = "F",
    [HORDE.Spell_Slot_Reload] = "R",
}

HORDE.Spell_Type_Projectile = 0
HORDE.Spell_Type_Hitscan = 1
HORDE.Spell_Type_AOE = 2
HORDE.Spell_Type_Minion = 3
HORDE.Spell_Type_Guard = 4
HORDE.Spell_Type_Displacement = 5
HORDE.Spell_Type_Utility = 6

HORDE.Spell_Type_Strings = {
    [HORDE.Spell_Type_Projectile] = "Projectile",
    [HORDE.Spell_Type_Hitscan] = "Hitscan",
    [HORDE.Spell_Type_AOE] = "Area of Effect",
    [HORDE.Spell_Type_Minion] = "Minion",
    [HORDE.Spell_Type_Guard] = "Guard",
    [HORDE.Spell_Type_Displacement] = "Displacement",
    [HORDE.Spell_Type_Utility] = "Utility",
}

local prefix = "horde/gamemode/modules/spells/"
local function Horde_LoadSpells()
    local dev = GetConVar("developer"):GetBool()
    for _, f in ipairs(file.Find(prefix .. "*", "LUA")) do
        SPELL = {}
        AddCSLuaFile(prefix .. f)
        include(prefix .. f)
        if SPELL.Ignore then goto cont end
        SPELL.ClassName = string.lower(SPELL.ClassName or string.Explode(".", f)[1])

        hook.Run("Horde_OnLoadSpell", SPELL)

        HORDE.spells[SPELL.ClassName] = SPELL

        for k, v in pairs(SPELL.Hooks or {}) do
            hook.Add(k, "horde_spell_" .. SPELL.ClassName, v)
        end

        if dev then print("[Horde] Loaded spell '" .. SPELL.ClassName .. "'.") end
        ::cont::
    end
    SPELL = nil
end

local plymeta = FindMetaTable("Player")

function plymeta:Horde_HasSpell(spell_name)
    if not self.Horde_PlayerSpells then return false end
    local spell = HORDE.spells and HORDE.spells[spell_name]
    if not spell or not isnumber(spell.Slot) then return false end
    if not self.Horde_PlayerSpells[spell.Slot] then return end
    return self.Horde_PlayerSpells[spell.Slot].ClassName == spell.ClassName
end

function plymeta:Horde_SetSpell(spell_name)
    local spell = HORDE.spells and HORDE.spells[spell_name]
    if not spell or not isnumber(spell.Slot) then return false end
    if not self.Horde_PlayerSpells then self.Horde_PlayerSpells = {} end
    if SERVER and spell.Slot == HORDE.Spell_Slot_Reload then
        local prev = self.Horde_PlayerSpells[spell.Slot]
        if prev and prev.ClassName ~= spell.ClassName then
            HORDE:DismissSummons(self, prev.ClassName)
        end
    end
    self.Horde_PlayerSpells[spell.Slot] = spell
    if SERVER then
        local weapon = self:Horde_GetSpellWeapon()
        if IsValid(weapon) then weapon:Horde_SetSpell(spell_name) end
        net.Start("Horde_SetSpell")
            net.WriteString(spell_name)
        net.Send(self)
    end
    return true
end

function plymeta:Horde_UnsetSpell(spell_name)
    if not self.Horde_PlayerSpells then return end
    local spell = HORDE.spells and HORDE.spells[spell_name]
    if not spell or not isnumber(spell.Slot) then return false end
    if SERVER and spell.Slot == HORDE.Spell_Slot_Reload then
        HORDE:DismissSummons(self, spell.ClassName)
    end
    self.Horde_PlayerSpells[spell.Slot] = nil
    if SERVER then
        local weapon = self:Horde_GetSpellWeapon()
        if IsValid(weapon) then weapon:Horde_UnsetSpell(spell_name) end
        net.Start("Horde_UnsetSpell")
            net.WriteString(spell_name)
        net.Send(self)
    end
    return true
end

function plymeta:Horde_UnsetSpellWeapon()
    if self.Horde_SpellWeapon and self.Horde_SpellWeapon:IsValid() then
        self.Horde_SpellWeapon:Remove()
        self.Horde_SpellWeapon = nil
    end
end

function plymeta:Horde_GetSpellWeapon()
    if not self.Horde_SpellWeapon then
        for _, wpn in pairs(self:GetWeapons()) do
            if wpn.Base == "horde_spell_weapon_base" then
                self.Horde_SpellWeapon = wpn
                return wpn
            end
        end
        return nil
    else
        if self.Horde_SpellWeapon:IsValid() then
            return self.Horde_SpellWeapon
        else
            self.Horde_SpellWeapon = nil
            return self:Horde_GetSpellWeapon()
        end
    end
end

function HORDE:IsSpellcasterClass(name)
    if not name or name == "" then return false end
    local subclass = HORDE.subclasses and HORDE.subclasses[name]
    return subclass ~= nil and subclass.IsSpellcaster == true
end

function HORDE:IsPlayerSpellcaster(ent)
    if not IsValid(ent) or not ent:IsPlayer() then return false end
    local wpn = ent.Horde_GetSpellWeapon and ent:Horde_GetSpellWeapon() or nil
    if IsValid(wpn) then return true end
    if not ent.Horde_GetCurrentSubclass then return false end
    return HORDE:IsSpellcasterClass(ent:Horde_GetCurrentSubclass())
end

function plymeta:Horde_GetPrimarySpell()
    if not self.Horde_PlayerSpells then return end
    return self.Horde_PlayerSpells[HORDE.Spell_Slot_LMB]
end

function plymeta:Horde_GetSecondarySpell()
    if not self.Horde_PlayerSpells then return end
    return self.Horde_PlayerSpells[HORDE.Spell_Slot_RMB]
end

function plymeta:Horde_GetUtilitySpell()
    if not self.Horde_PlayerSpells then return end
    return self.Horde_PlayerSpells[HORDE.Spell_Slot_Utility]
end

function plymeta:Horde_GetUltimateSpell()
    if not self.Horde_PlayerSpells then return end
    return self.Horde_PlayerSpells[HORDE.Spell_Slot_Reload]
end

function plymeta:Horde_GetPrimarySpellCooldown()
    if not self.Horde_PlayerSpells then return end
    return self:Horde_GetSpellWeapon():GetNextPrimaryFire() - CurTime()
end

function plymeta:Horde_GetSecondarySpellCooldown()
    if not self.Horde_PlayerSpells then return end
    return self:Horde_GetSpellWeapon():GetNextSecondaryFire() - CurTime()
end

function plymeta:Horde_GetUtilitySpellCooldown()
    if not self.Horde_PlayerSpells then return end
    return self:Horde_GetSpellWeapon():GetNextUtilityFire() - CurTime()
end

function plymeta:Horde_GetUltimateSpellCooldown()
    if not self.Horde_PlayerSpells then return end
    return self:Horde_GetSpellWeapon():GetNextUltimateFire() - CurTime()
end

function plymeta:Horde_GetSpellUpgrade(spell_name)
    if not self.Horde_SpellUpgrades then self.Horde_SpellUpgrades = {} end
    return self.Horde_SpellUpgrades[spell_name] or 0
end

function plymeta:Horde_SetSpellUpgrade(spell_name, level)
    if not self.Horde_SpellUpgrades then self.Horde_SpellUpgrades = {} end
    if SERVER then
        net.Start("Horde_SetSpellUpgrades")
            net.WriteString(spell_name)
            net.WriteUInt(level, 8)
        net.Send(self)
    end
    self.Horde_SpellUpgrades[spell_name] = level
end

if CLIENT then
net.Receive("Horde_SetSpellUpgrades", function(len, ply)
    local spell = net.ReadString()
    local level = net.ReadUInt(8)
    MySelf:Horde_SetSpellUpgrade(spell, level)
end)
end

function HORDE:GetSpellUpgradePrice(spell_name, ply)
    local spell = HORDE.spells and HORDE.spells[spell_name]
    if not spell or not IsValid(ply) then return nil end
    local level = ply:Horde_GetSpellUpgrade(spell_name)
    if spell.Upgrade_Prices then
        if not isfunction(spell.Upgrade_Prices) then return nil end
        return spell.Upgrade_Prices(level)
    end
    if spell.Price then
        return spell.Price / 2 + 100 * level
    else
        return 1000
    end
end

function HORDE:GetSpellUpgradeStats(spell, level)
    if not spell or not spell.Upgrade_Stats then return nil end
    local ok, text = pcall(spell.Upgrade_Stats, level or 0)
    if ok and text and text ~= "" then return text end
    return nil
end

function HORDE:GetSpellUpgradeText(spell, level)
    if not spell then return nil end
    local stats = self:GetSpellUpgradeStats(spell, level)
    if not stats then return spell.Upgrade_Description end
    if spell.Upgrade_Description then
        return spell.Upgrade_Description .. "\n" .. stats
    end
    return stats
end

if CLIENT then
net.Receive("Horde_SetSpell", function ()
    MySelf:Horde_SetSpell(net.ReadString())
end)
net.Receive("Horde_UnsetSpell", function ()
    MySelf:Horde_UnsetSpell(net.ReadString())
end)
end

HORDE.SPECTRE_HEALTH = {
    spectre = {start = 256,  max = 1024, spell = "raise_spectre"},
    greater = {start = 512,  max = 2048, spell = "raise_greater_spectre"},
    hulk    = {start = 1024, max = 4096, spell = "raise_hulk_spectre"},
    blight  = {start = 768,  max = 3072, spell = "raise_blight_spectre"},
    scorcher  = {start = 1024, max = 1024, spell = "raise_scorcher_spectre"},
    screecher = {start = 2048, max = 2048, spell = "raise_screecher_spectre"},
}

function HORDE:GetSpectreMaxLevel(kind)
    local info = self.SPECTRE_HEALTH[kind]
    if not info then return 0 end
    local spell = self.spells and self.spells[info.spell]
    return (spell and spell.Upgrades) or 0
end

function HORDE:GetSpectreHealth(kind, level)
    local info = self.SPECTRE_HEALTH[kind]
    if not info then return 0 end
    local max_level = self:GetSpectreMaxLevel(kind)
    if max_level <= 0 then return info.start end
    level = math.Clamp(level or 0, 0, max_level)
    return math.floor(info.start + (info.max - info.start) * (level / max_level) + 0.5)
end

HORDE.SPECTRE_CLASSES = {
    "npc_vj_horde_spectre",
    "npc_vj_horde_shadow_hulk",
    "npc_vj_horde_blight_spectre",
}

function HORDE:GetSpectreCount(ply)
    local total = 0
    for _, class in ipairs(self.SPECTRE_CLASSES) do
        local count = ply.Horde_drop_entities and ply.Horde_drop_entities[class]
        if count then total = total + count end
    end
    return total
end

HORDE.SPECTRE_IMMUNE_STATUS_NAMES = {
    "Status_Break",
    "Status_Bleeding",
}

function HORDE:MakeStatusImmune(ent, status_names)
    if not IsValid(ent) then return end
    ent.Horde_Immune_Status = ent.Horde_Immune_Status or {}
    for _, name in ipairs(status_names) do
        local id = self[name]
        if id then ent.Horde_Immune_Status[id] = true end
    end
end

HORDE.SPECTRE_TYPE_LIMITS = {
    npc_vj_horde_shadow_hulk        = 2,
    npc_vj_horde_blight_spectre     = 2,
    npc_vj_horde_scorcher_spectre   = 2,
    npc_vj_horde_screecher_spectre  = 1,
}

HORDE.SPECTRE_TYPE_NAMES = {
    npc_vj_horde_shadow_hulk       = "Hulk Spectre",
    npc_vj_horde_blight_spectre    = "Blight Spectre",
    npc_vj_horde_scorcher_spectre  = "Fire God",
    npc_vj_horde_screecher_spectre = "Lightning God",
}

HORDE.SPECTRE_INDEPENDENT_CLASSES = {
    npc_vj_horde_scorcher_spectre  = true,
    npc_vj_horde_screecher_spectre = true,
}

function HORDE:GetSpectreTypeLimit(class)
    return self.SPECTRE_TYPE_LIMITS[class]
end

function HORDE:GetSpectreTypeCount(ply, class)
    return (ply.Horde_drop_entities and ply.Horde_drop_entities[class]) or 0
end

function HORDE:SpectreTypeLimitReached(ply, class)
    local limit = self.SPECTRE_TYPE_LIMITS[class]
    if not limit then return false end
    return self:GetSpectreTypeCount(ply, class) >= limit
end

if SERVER then
HORDE.SUMMON_SPELL_CLASSES = {
    raise_spectre           = "npc_vj_horde_spectre",
    raise_greater_spectre   = "npc_vj_horde_spectre",
    raise_hulk_spectre      = "npc_vj_horde_shadow_hulk",
    raise_blight_spectre    = "npc_vj_horde_blight_spectre",
    raise_scorcher_spectre  = "npc_vj_horde_scorcher_spectre",
    raise_screecher_spectre = "npc_vj_horde_screecher_spectre",
}

function HORDE:DismissSummons(ply, spell_name)
    if not IsValid(ply) then return end
    local class = self.SUMMON_SPELL_CLASSES[spell_name]
    if not class then return end

    local summons, seen = {}, {}
    local function Collect(ent)
        if seen[ent] then return end
        if IsValid(ent) and ent.Horde_Summon_Spell == spell_name and self:IsMinionOf(ent, ply) then
            seen[ent] = true
            summons[#summons + 1] = ent
        end
    end

    local drops = self.player_drop_entities[ply:SteamID()]
    if drops then
        for _, ent in pairs(drops) do Collect(ent) end
    end
    for _, ent in ipairs(ents.FindByClass(class)) do Collect(ent) end

    for _, ent in ipairs(summons) do
        ent:Remove()
    end
end

net.Receive("Horde_BuySpellUpgrade", function (len, ply)
    if not HORDE:AllowNetRequest(ply, "buy_spell_upgrade", 0.25) then return end
    if HORDE.UnarmedShopBlocked and HORDE:UnarmedShopBlocked(ply) then return end
    if not ply:IsValid() or not ply:Alive() or not ply.Horde_Init_Complete then return end
    local class = net.ReadString()
    local spell = HORDE.spells and HORDE.spells[class]
    if not spell or not isnumber(spell.Slot) then return end
    if not ply:Horde_HasSpell(class) then
        HORDE:SendNotification("You don't have this spell!")
        return
    end

    local upgrades = tonumber(spell.Upgrades)
    if not upgrades or upgrades < 0 or ply:Horde_GetSpellUpgrade(class) >= upgrades then return end

    local price = tonumber(HORDE:GetSpellUpgradePrice(class, ply))
    if not price or price < 0 or price ~= price then return end
    if ply:Horde_GetMoney() >= price then
        ply:Horde_AddMoney(-price)
        ply:Horde_SetSpellUpgrade(class, ply:Horde_GetSpellUpgrade(class) + 1)
        ply:Horde_SyncEconomy()
        sound.Play("items/battery_pickup.wav", ply:GetPos())
    end
end)

function HORDE:RaiseSpectre(ply, param, p2)
    local spell_name = "raise_spectre"
    local ent_class = "npc_vj_horde_spectre"
    if param and param.hulk_spectre then
        spell_name = "raise_hulk_spectre"
        ent_class = "npc_vj_horde_shadow_hulk"
    elseif param and param.blight_spectre then
        spell_name = "raise_blight_spectre"
        ent_class = "npc_vj_horde_blight_spectre"
    elseif param and param.scorcher_spectre then
        spell_name = "raise_scorcher_spectre"
        ent_class = "npc_vj_horde_scorcher_spectre"
    elseif param and param.screecher_spectre then
        spell_name = "raise_screecher_spectre"
        ent_class = "npc_vj_horde_screecher_spectre"
    elseif param and param.greater_spectre then
        spell_name = "raise_greater_spectre"
    end
    local level = ply:Horde_GetSpellUpgrade(spell_name)
    local p = {level = level}
    hook.Run("Horde_OnRaiseSpectre", ply, p)
    if self:SpectreTypeLimitReached(ply, ent_class) then
        HORDE:SendNotification(self.SPECTRE_TYPE_NAMES[ent_class] .. " limit reached ("
            .. self:GetSpectreTypeLimit(ent_class) .. ").", 1, ply)
        return true
    end
    if not self.SPECTRE_INDEPENDENT_CLASSES[ent_class] then
        local spectres_count = self:GetSpectreCount(ply)
        ply:Horde_RecalcSpectreMaxCount()
        if spectres_count >= ply.Horde_Spectre_Max_Count then
            HORDE:SendNotification("Spectre limit reached (" .. spectres_count .. "/" .. tostring(ply.Horde_Spectre_Max_Count) .. "). Perks can increase it.", 1, ply)
            return true
        end
    end
    ply:EmitSound("horde/spells/raise.ogg")
    local ent = ents.Create(ent_class)
    HORDE:MakeStatusImmune(ent, HORDE.SPECTRE_IMMUNE_STATUS_NAMES)
    ent.properties = p
    ent.Horde_Summon_Spell = spell_name
    local pos = ply:GetPos()
    local dir = (ply:GetEyeTrace().HitPos - pos)
    dir:Normalize()
    local drop_pos = pos + dir * 50
    drop_pos.z = pos.z + 24
    ent:SetPos(drop_pos)
    if p2 then
        ent:SetPos(p2)
    end
    ent:SetAngles(Angle(0, ply:GetAngles().y, 0))

    HORDE:RegisterMinion(ent, ply, {
        no_collision = false,
        on_remove = function(removed, owner)
            if IsValid(owner) then owner:Horde_SyncEconomy() end
        end,
    })

    ent:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)

    ent:Spawn()

    if param and param.greater_spectre then
        timer.Simple(0.1, function ()
            if IsValid(ent) then ent:Horde_SetGreaterSpectre() end
        end)
    end
end

function HORDE:RemoveSpectres(ply)
    if HORDE.player_drop_entities[ply:SteamID()] then
        for id, ent in pairs(HORDE.player_drop_entities[ply:SteamID()]) do
            if ent:IsNPC() and table.HasValue(self.SPECTRE_CLASSES, ent:GetClass()) then
                ent:Remove()
            end
        end
    end
end
end
