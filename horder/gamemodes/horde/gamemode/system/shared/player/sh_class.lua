HORDE.classes = {}
HORDE.order_to_class_name = {}
HORDE.Class_Survivor    = "Survivor"
HORDE.Class_Assault     = "Assault"
HORDE.Class_Heavy       = "Heavy"
HORDE.Class_Medic       = "Medic"
HORDE.Class_Demolition  = "Demolition"
HORDE.Class_Ghost       = "Ghost"
HORDE.Class_Engineer    = "Engineer"
HORDE.Class_Berserker   = "Berserker"
HORDE.Class_Warden      = "Warden"
HORDE.Class_Cremator    = "Cremator"

function HORDE:CreateClass(data)
    if not data or not data.name or data.name == "" then return end

    local class = {}
    class.name          = data.name
    class.extra_description = data.description or data.extra_description or ""
    class.max_hp        = data.max_hp    or 100
    class.movespd       = data.movespd   or GetConVar("horde_base_walkspeed"):GetInt()
    class.sprintspd     = data.sprintspd or GetConVar("horde_base_runspeed"):GetInt()
    class.base_perk     = data.base_perk
    class.perks         = data.perks     or {}
    class.order         = data.order     or 0
    class.display_name  = data.display_name or data.name
    class.model         = data.model     or nil
    class.icon          = data.icon      or (data.name .. ".png")
    class.infusions     = data.infusions or {}
    class.skull_tokens  = data.skull_tokens or 0
    class.player_limit  = data.player_limit
    if class.player_limit == nil then class.player_limit = 4 end
    class.starter_weapons = data.starter_weapons or nil
	class.subclasses    = data.subclasses or { data.name }

    HORDE.order_to_class_name[class.order] = class.name
    HORDE.classes[class.name] = class
end

HORDE.RegisterClass = HORDE.CreateClass

HORDE.player_class_changed = {}

function SyncClasses()
    if player then
        for _, ply in pairs(player.GetAll()) do
            net.Start("Horde_SyncClasses")
            net.WriteTable(HORDE.classes)
            net.Send(ply)
        end
    end
end

function HORDE:SetClassData(tbl)
    if SERVER then
        if GetConVar("horde_default_class_config"):GetInt() == 1 then return end
        if not (HORDE.DB and HORDE.DB.IsReady and HORDE.DB.IsReady()) then return end

        HORDE.DB.Query(HORDE.DB.Prepare([[
            INSERT INTO horde_redux_meta (key, value) VALUES ('class_config', ?)
            ON CONFLICT(key) DO UPDATE SET value = excluded.value;
        ]], util.TableToJSON(tbl or HORDE.classes)))
    end
end

local function GetClassData()
    if SERVER then
        if not (HORDE.DB and HORDE.DB.IsReady and HORDE.DB.IsReady()) then return end

        local json = HORDE.DB.QueryValue("SELECT value FROM horde_redux_meta WHERE key = 'class_config';")
        if json then
            local t = util.JSONToTable(json)
            if not t then return end

            for _, class in pairs(t) do
                local dst = HORDE.classes[class.name]
                if not dst then continue end

                if class.display_name then
                    dst.display_name = class.display_name
                end
                if class.extra_description then
                    dst.extra_description = class.extra_description
                end
                if class.model then
                    dst.model = class.model
                end
                if class.base_perk then
                    dst.base_perk = class.base_perk
                end
                if class.perks then
                    dst.perks = class.perks
                end
                if class.icon then
                    dst.icon = class.icon
                end
                if class.skull_tokens ~= nil then
                    dst.skull_tokens = class.skull_tokens
                end
                if class.player_limit ~= nil then
                    dst.player_limit = class.player_limit
                end
                if class.order ~= nil then
                    dst.order = class.order
                end
                if class.starter_weapons ~= nil then
                    dst.starter_weapons = class.starter_weapons
                end
            end
        end
    end
end

function HORDE:GetDefaultClassesData()
    HORDE:CreateClass({
        name        = HORDE.Class_Survivor,
        description = "Has access to all weapons except for exclusive and special weapons.\n\nLimited access to attachments.",
        base_perk   = "survivor_base",
        perks = {
            [1] = { title = "Survival",        choices = { "medic_antibiotics",    "assault_charge"          } },
            [2] = { title = "Improvise",        choices = { "berserker_breathing_technique", "demolition_frag_cluster" } },
            [3] = { title = "Imprinting",       choices = { "heavy_liquid_armor",   "cremator_entropy_shield" } },
            [4] = { title = "Inspired Learning",choices = { "ghost_headhunter",     "specops_flare"           } },
        },
        order         = 0,
        player_limit  = 0,
        subclasses    = { HORDE.Class_Survivor },
    })

    HORDE:CreateClass({
        name        = HORDE.Class_Assault,
        description = "Has full access to assault rifles.",
        base_perk   = "assault_base",
        perks = {
            [1] = { title = "Maneuverability", choices = { "assault_ambush",             "assault_charge"            } },
            [2] = { title = "Adaptability",    choices = { "assault_drain",              "assault_overclock"         } },
            [3] = { title = "Aggression",      choices = { "assault_cardiac_resonance",  "assault_cardiac_overload"  } },
            [4] = { title = "Conditioning",    choices = { "assault_heightened_reflex",  "assault_merciless_assault" } },
        },
        order       = 1,
        subclasses  = { HORDE.Class_Assault },
    })

    HORDE:CreateClass({
        name        = HORDE.Class_Heavy,
        description = "Has full access to machine guns and high weight weapons.",
        base_perk   = "heavy_base",
        perks = {
            [1] = { title = "Suppression",      choices = { "heavy_sticky_compound",  "heavy_crude_casing"     } },
            [2] = { title = "Backup",            choices = { "heavy_repair_catalyst",  "heavy_floating_carrier" } },
            [3] = { title = "Armor Protection",  choices = { "heavy_liquid_armor",     "heavy_reactive_armor"   } },
            [4] = { title = "Technology",        choices = { "heavy_nanomachine",      "heavy_ballistic_shock"  } },
        },
        order       = 2,
        subclasses  = { HORDE.Class_Heavy },
    })

    HORDE:CreateClass({
        name        = HORDE.Class_Medic,
        description = "Has acesss to most light weapons and medical tools.",
        base_perk   = "medic_base",
        perks = {
            [1] = { title = "Medicine",         choices = { "medic_antibiotics",       "medic_painkillers"       } },
            [2] = { title = "Bio-Engineering",  choices = { "medic_berserk",           "medic_fortify"           } },
            [3] = { title = "Enhancement",      choices = { "medic_purify",            "medic_haste"             } },
            [4] = { title = "Natural Selection",choices = { "medic_cellular_implosion", "medic_xcele"            } },
        },
        order       = 3,
        subclasses  = { HORDE.Class_Medic },
    })

    HORDE:CreateClass({
        name        = HORDE.Class_Demolition,
        description = "Has full access to explosive weapons.",
        base_perk   = "demolition_base",
        perks = {
            [1] = { title = "Grenade",    choices = { "demolition_frag_impact",        "demolition_frag_cluster"        } },
            [2] = { title = "Weaponry",   choices = { "demolition_direct_hit",         "demolition_seismic_wave"        } },
            [3] = { title = "Approach",   choices = { "demolition_fragmentation",      "demolition_knockout"            } },
            [4] = { title = "Destruction",choices = { "demolition_chain_reaction",     "demolition_pressurized_warhead" } },
        },
        order       = 4,
        subclasses  = { HORDE.Class_Demolition },
    })

    HORDE:CreateClass({
        name        = HORDE.Class_Ghost,
        description = "Has access to sniper rifles and selected light weapons.\n\nHave access to suppressors and sniper scopes.",
        base_perk   = "ghost_base",
        perks = {
            [1] = { title = "Tactics",    choices = { "ghost_headhunter",    "ghost_sniper"         } },
            [2] = { title = "Reposition", choices = { "ghost_phase_walk",    "ghost_ghost_veil"     } },
            [3] = { title = "Trajectory", choices = { "ghost_brain_snap",    "ghost_kinetic_impact" } },
            [4] = { title = "Disposal",   choices = { "ghost_coup",          "ghost_decapitate"     } },
        },
        order       = 5,
        subclasses  = { HORDE.Class_Ghost },
    })

    HORDE:CreateClass({
        name        = HORDE.Class_Engineer,
        description = "Has access to special weapons and equipment.",
        base_perk   = "engineer_base",
        perks = {
            [1] = { title = "Craftsmanship", choices = { "engineer_tinkerer",         "engineer_pioneer"   } },
            [2] = { title = "Core",          choices = { "engineer_fusion",            "engineer_metabolism"} },
            [3] = { title = "Manipulation",  choices = { "engineer_antimatter_shield", "engineer_displacer" } },
            [4] = { title = "Experimental",  choices = { "engineer_symbiosis",         "engineer_kamikaze"  } },
        },
        order       = 6,
        subclasses  = { HORDE.Class_Engineer },
    })

    HORDE:CreateClass({
        name        = HORDE.Class_Berserker,
        description = "Has access to melee weapons and some ranged equipment.",
        base_perk   = "berserker_base",
        perks = {
            [1] = { title = "Fundamentals", choices = { "berserker_breathing_technique", "berserker_bloodlust"      } },
            [2] = { title = "Technique",    choices = { "berserker_bushido",              "berserker_savagery"       } },
            [3] = { title = "Parry",        choices = { "berserker_graceful_guard",       "berserker_unwavering_guard"} },
            [4] = { title = "Combat Arts",  choices = { "berserker_phalanx",              "berserker_rip_and_tear"   } },
        },
        order       = 7,
        subclasses  = { HORDE.Class_Berserker },
    })

    HORDE:CreateClass({
        name        = HORDE.Class_Warden,
        description = "Has full access to shotguns and Watchtowers, built and managed via the Watchtower Staff (horde_wardenstaff) from Money.",
        base_perk   = "warden_base",
        perks = {
            [1] = { title = "Sustain",               choices = { "warden_bulwark",          "warden_vitality"          } },
            [2] = { title = "Resource Utilization",  choices = { "warden_restock",           "warden_inoculation"       } },
            [3] = { title = "Escort",                choices = { "warden_rejection_pulse",   "warden_energize"          } },
            [4] = { title = "Coverage",              choices = { "warden_ex_machina",        "warden_resonance_cascade" } },
        },
        order       = 8,
        subclasses  = { HORDE.Class_Warden },
    })

    HORDE:CreateClass({
        name        = HORDE.Class_Cremator,
        description = "Has access to heat-based weaponry.",
        base_perk   = "cremator_base",
        perks = {
            [1] = { title = "Chemicals",       choices = { "cremator_methane",         "cremator_napalm"       } },
            [2] = { title = "Energy Absorption",choices = { "cremator_positron_array",  "cremator_entropy_shield"} },
            [3] = { title = "Heat Manipulation",choices = { "cremator_hyperthermia",    "cremator_ionization"   } },
            [4] = { title = "Energy Discharge", choices = { "cremator_firestorm",       "cremator_incineration" } },
        },
        order       = 9,
        subclasses  = { HORDE.Class_Cremator },
    })
end

if SERVER then
    util.AddNetworkString("Horde_SetClassData")
    util.AddNetworkString("Horde_SetSubclassData")
    util.AddNetworkString("Horde_SyncSubclasses")
    util.AddNetworkString("Horde_SetSubclass")
    util.AddNetworkString("Horde_UnlockSubclass")
    util.AddNetworkString("Horde_SubclassUnlocked")
    util.AddNetworkString("Horde_SelectSameSubclass")
    util.AddNetworkString("Horde_SyncSubclassUnlocks")
    HORDE:GetDefaultClassesData()
    if GetConVar("horde_default_class_config"):GetInt() == 1 then
    else
        GetClassData()
    end

    SyncClasses()

    net.Receive("Horde_SetClassData", function (len, ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        if not HORDE:AllowNetRequest(ply, "set_class_data", 2) then return end
        if not HORDE:TableMessageAllowed(len) then return end
        local tbl = net.ReadTable()
        if not istable(tbl) or not HORDE:SanityCheck(tbl) then
            HORDE:SendNotification("Class config rejected: invalid structure.", 1, ply)
            return
        end

        local cv = GetConVar("horde_default_class_config")
        if cv and cv:GetInt() ~= 0 then
            cv:SetInt(0)
        end

        HORDE:SetClassData(tbl)
        local deferred = HORDE:QueueConfigApply("classes", function()
            HORDE.classes = tbl
            SyncClasses()
        end)
        HORDE:SendNotification(deferred and "Class config saved. It will apply on the next wave."
            or "Class config applied.", 0, ply)
    end)

    net.Receive("Horde_SetSubclassData", function (len, ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        if not HORDE:AllowNetRequest(ply, "set_subclass_data", 2) then return end
        if not HORDE:TableMessageAllowed(len) then return end
        local tbl = net.ReadTable()
        if not istable(tbl) or not HORDE:SanityCheck(tbl) then
            HORDE:SendNotification("Subclass config rejected: invalid structure.", 1, ply)
            return
        end

        local cv = GetConVar("horde_default_class_config")
        if cv and cv:GetInt() ~= 0 then
            cv:SetInt(0)
        end

        HORDE:SetSubclassData(tbl)
        local deferred = HORDE:QueueConfigApply("subclasses", function()
            HORDE.subclass_overrides = tbl
            HORDE:ApplySubclassOverrides()
            SyncSubclasses()
        end)
        HORDE:SendNotification(deferred and "Subclass config saved. It will apply on the next wave."
            or "Subclass config applied.", 0, ply)
    end)

    net.Receive("Horde_SetSubclass", function (len, ply)
        if not HORDE:AllowNetRequest(ply, "set_subclass", 1) then return end
        local class_name = net.ReadString()
        local subclass = net.ReadString()
        if not ply.Horde_subclasses_unlocked and not HORDE:LoadSubclassUnlocks(ply) then return end
        local class, reason = HORDE:ValidateClassTransition(ply, class_name, subclass, false)
        if not class then
            if reason then HORDE:SendNotification(reason, 1, ply) end
            return
        end
        if not ply:Horde_SetSubclass(class_name, subclass, true) then return end
        if GetConVar("horde_testing_unlimited_class_change"):GetInt() == 0 then
            HORDE.player_class_changed[ply:SteamID()] = true
        end

        net.Start("Horde_ClearStatus")
        net.Send(ply)

        ply:Horde_ApplyPerksForClass()

        HORDE:RegiveStarterWeapons(ply)

        ply:Horde_SyncEconomy()
    end)

    net.Receive("Horde_UnlockSubclass", function (len, ply)
        if not HORDE:AllowNetRequest(ply, "unlock_subclass", 1) then return end
        if not ply.Horde_Init_Complete then return end
        local subclass_name = net.ReadString()
        local subclass = HORDE.subclasses and HORDE.subclasses[subclass_name]
        if not subclass then return end
        local cost = tonumber(subclass.UnlockCost)
        if not ply.Horde_subclasses_unlocked and not HORDE:LoadSubclassUnlocks(ply) then return end
        if not cost or cost < 0 or cost ~= cost then return end

        if ply:Horde_GetSubclassUnlocked(subclass_name) == true then
            HORDE:SendNotification("Subclass " .. subclass.PrintName .. " is already unlocked!", 1, ply)
            return
        end

        if ply:Horde_GetSkullTokens() >= cost then
            ply:Horde_AddSkullTokens(-cost)
            ply:Horde_SetSubclassUnlocked(subclass_name, true)
            ply:Horde_SyncEconomy()

            HORDE:SendNotification("You unlocked " .. subclass.PrintName .. " subclass.", 0, ply)
        end
    end)

    net.Receive("Horde_SelectSameSubclass", function (len, ply)
        if not HORDE:AllowNetRequest(ply, "select_same_subclass", 1) then return end
        local subclass_name = net.ReadString()
        local subclass = HORDE.subclasses and HORDE.subclasses[subclass_name]
        if not subclass then return end

        if subclass_name == ply:Horde_GetCurrentSubclass() then
            HORDE:SendNotification("You are already this class.", 1, ply)
        end
    end)
end

if CLIENT then
    net.Receive("Horde_SyncClasses", function ()
        HORDE.classes = net.ReadTable()
        for name, c in pairs(HORDE.classes) do
            HORDE.order_to_class_name[c.order] = name
        end
        local class = MySelf:Horde_GetCurrentSubclass() or HORDE.Class_Survivor
    end)

    net.Receive("Horde_SyncSubclassUnlocks", function ()
        local table = net.ReadTable()
        MySelf.Horde_subclasses_unlocked = table
    end)
end

HORDE.subclasses = {}

HORDE.SubclassCategories = HORDE.SubclassCategories or {
    [1] = { name = "Offense", icon = "damagetype/slash.png" },
    [2] = { name = "Defense", icon = "status/armor.png" },
    [3] = { name = "Support", icon = "status/health.png" },
    [4] = { name = "Hybrid",  icon = "status/minion.png" },
}
HORDE.SubclassCategory_Other = 99

HORDE.classes_to_subclasses = {
    [HORDE.Class_Survivor]   = { HORDE.Class_Survivor   },
    [HORDE.Class_Assault]    = { HORDE.Class_Assault     },
    [HORDE.Class_Medic]      = { HORDE.Class_Medic       },
    [HORDE.Class_Heavy]      = { HORDE.Class_Heavy       },
    [HORDE.Class_Demolition] = { HORDE.Class_Demolition  },
    [HORDE.Class_Cremator]   = { HORDE.Class_Cremator    },
    [HORDE.Class_Ghost]      = { HORDE.Class_Ghost       },
    [HORDE.Class_Warden]     = { HORDE.Class_Warden      },
    [HORDE.Class_Berserker]  = { HORDE.Class_Berserker   },
    [HORDE.Class_Engineer]   = { HORDE.Class_Engineer    },
}

HORDE.classes_to_order = {}

hook.Add("Horde_AllModulesLoaded", "Horde_SyncClassOrderTables", function()
    for name, class in pairs(HORDE.classes) do
        HORDE.classes_to_order[name] = class.order
        HORDE.order_to_class_name[class.order] = name
    end
end)

HORDE.subclass_name_to_crc = {}
HORDE.subclasses_to_classes = {}
HORDE.order_to_subclass_name = {}
local prefix = "horde/gamemode/modules/subclasses/"
local function Horde_LoadSubclasses()
    local dev = GetConVar("developer"):GetBool()
    for _, f in ipairs(file.Find(prefix .. "*", "LUA")) do
        SUBCLASS = {}
        AddCSLuaFile(prefix .. f)
        include(prefix .. f)
        if SUBCLASS.Ignore then goto cont end
        SUBCLASS.SortOrder = SUBCLASS.SortOrder or 0
        SUBCLASS.BasePerk = SUBCLASS.BasePerk or (string.lower(SUBCLASS.PrintName).. "_base")

        HORDE.subclasses[SUBCLASS.PrintName] = SUBCLASS
        local crc_val = util.CRC(SUBCLASS.PrintName)
        HORDE.subclass_name_to_crc[SUBCLASS.PrintName] = crc_val
        HORDE.order_to_subclass_name[crc_val] = SUBCLASS.PrintName
        if SUBCLASS.ParentClass then
            table.insert(HORDE.classes_to_subclasses[SUBCLASS.ParentClass], SUBCLASS.PrintName)
            HORDE.subclasses_to_classes[SUBCLASS.PrintName] = SUBCLASS.ParentClass
        else
            HORDE.subclasses_to_classes[SUBCLASS.PrintName] = SUBCLASS.PrintName
    end

        if dev then print("[Horde] Loaded subclass '" .. SUBCLASS.PrintName .. "'.") end
        ::cont::
    end
    PERK = nil
end

HORDE.subclass_overrides = {}
HORDE.subclass_defaults  = {}

HORDE.subclass_override_fields = {
    "Icon", "Description", "BasePerk", "Perks", "UnlockCost", "SortOrder", "Category", "player_limit",
}

local function CopySubclassValue(v)
    if istable(v) then return table.Copy(v) end
    return v
end

function HORDE:SnapshotSubclassDefaults()
    for name, sub in pairs(HORDE.subclasses or {}) do
        if not HORDE.subclass_defaults[name] then
            local snap = {}
            for _, f in ipairs(HORDE.subclass_override_fields) do
                snap[f] = CopySubclassValue(sub[f])
            end
            HORDE.subclass_defaults[name] = snap
        end
    end
end

function HORDE:BuildSubclassOverride(sub)
    if not istable(sub) then return nil end

    local ov = {}
    for _, f in ipairs(HORDE.subclass_override_fields) do
        local v = sub[f]
        if v ~= nil then ov[f] = CopySubclassValue(v) end
    end
    return ov
end

function HORDE:RestoreSubclassDefaults(name)
    local sub = HORDE.subclasses and HORDE.subclasses[name]
    local def = HORDE.subclass_defaults and HORDE.subclass_defaults[name]
    if not sub or not def then return false end

    for _, f in ipairs(HORDE.subclass_override_fields) do
        sub[f] = CopySubclassValue(def[f])
    end
    HORDE.subclass_overrides[name] = nil
    return true
end

function HORDE:RestoreAllSubclassDefaults()
    local names = table.GetKeys(HORDE.subclass_overrides or {})
    for _, name in ipairs(names) do
        HORDE:RestoreSubclassDefaults(name)
    end
    HORDE.subclass_overrides = {}
end

function HORDE:ApplySubclassOverrides()
    for name, ov in pairs(HORDE.subclass_overrides or {}) do
        local sub = HORDE.subclasses and HORDE.subclasses[name]
        if sub and istable(ov) then
            for _, f in ipairs(HORDE.subclass_override_fields) do
                local v = ov[f]
                if v ~= nil then sub[f] = CopySubclassValue(v) end
            end
        end
    end
end

function HORDE:SetSubclassData(tbl)
    if SERVER then
        if GetConVar("horde_default_class_config"):GetInt() == 1 then return end
        if not (HORDE.DB and HORDE.DB.IsReady and HORDE.DB.IsReady()) then return end

        HORDE.DB.Query(HORDE.DB.Prepare([[
            INSERT INTO horde_redux_meta (key, value) VALUES ('subclass_config', ?)
            ON CONFLICT(key) DO UPDATE SET value = excluded.value;
        ]], util.TableToJSON(tbl or HORDE.subclass_overrides)))
    end
end

function SyncSubclasses()
    if player then
        for _, ply in pairs(player.GetAll()) do
            net.Start("Horde_SyncSubclasses")
            net.WriteTable(HORDE.subclass_overrides or {})
            net.Send(ply)
        end
    end
end

local function GetSubclassData()
    if not SERVER then return end
    if not (HORDE.DB and HORDE.DB.IsReady and HORDE.DB.IsReady()) then return end

    local json = HORDE.DB.QueryValue("SELECT value FROM horde_redux_meta WHERE key = 'subclass_config';")
    if not json then return end

    local t = util.JSONToTable(json)
    if not istable(t) then return end

    HORDE.subclass_overrides = t
    HORDE:ApplySubclassOverrides()
end

hook.Add("Horde_AllModulesLoaded", "Horde_SubclassConfig", function()
    HORDE:SnapshotSubclassDefaults()

    if not SERVER then return end

    if GetConVar("horde_default_class_config"):GetInt() ~= 1 then
        GetSubclassData()
    end
    SyncSubclasses()
end)

if CLIENT then
    net.Receive("Horde_SyncSubclasses", function()
        local t = net.ReadTable()
        if not istable(t) then return end

        HORDE.subclass_overrides = t
        HORDE:SnapshotSubclassDefaults()
        HORDE:ApplySubclassOverrides()

        if HORDE.RefreshClassConfigUI then HORDE:RefreshClassConfigUI() end
    end)
end

local plymeta = FindMetaTable("Player")

function HORDE:GetClassPlayerLimit(name)
    if not name then return 4 end
    local sub = HORDE.subclasses and HORDE.subclasses[name]
    if sub and sub.player_limit ~= nil then
        local lim = tonumber(sub.player_limit) or 4
        return lim <= 0 and math.huge or lim
    end
    local class = HORDE.classes and HORDE.classes[name]
    if class then
        local lim = tonumber(class.player_limit)
        if lim == nil then lim = 4 end
        return lim <= 0 and math.huge or lim
    end
    return 4
end

function HORDE:CountClassPlayers(class_name, exclude_ply)
    local count = 0
    for _, p in pairs(player.GetHumans()) do
        if p == exclude_ply or not IsValid(p) then continue end
        local cls = p:Horde_GetClass()
        if cls and cls.name == class_name then
            count = count + 1
        end
    end
    return count
end

function HORDE:CountSubclassPlayers(subclass_name, exclude_ply)
    local count = 0
    for _, p in pairs(player.GetHumans()) do
        if p == exclude_ply or not IsValid(p) then continue end
        if p:Horde_GetCurrentSubclass() == subclass_name then
            count = count + 1
        end
    end
    return count
end

function HORDE:CanTakeClassSlot(ply, class_name, subclass_name)
    local class_limit = HORDE:GetClassPlayerLimit(class_name)
    if class_limit < math.huge then
        local class_count = HORDE:CountClassPlayers(class_name, ply)
        if class_count >= class_limit then
            return false, "Class [" .. class_name .. "] is at its server limit ("
                .. class_count .. "/" .. class_limit .. ")"
        end
    end

    if subclass_name and subclass_name ~= class_name then
        local sub = HORDE.subclasses and HORDE.subclasses[subclass_name]
        if sub and sub.player_limit ~= nil then
            local sub_limit = HORDE:GetClassPlayerLimit(subclass_name)
            if sub_limit < math.huge then
                local sub_count = HORDE:CountSubclassPlayers(subclass_name, ply)
                if sub_count >= sub_limit then
                    return false, "Subclass [" .. subclass_name .. "] is at its server limit ("
                        .. sub_count .. "/" .. sub_limit .. ")"
                end
            end
        end
    end

    return true
end

function HORDE:ValidateClassTransition(ply, class_name, subclass_name, initializing)
    if not IsValid(ply) or not isstring(class_name) or not isstring(subclass_name) then
        return nil, "Invalid class request."
    end
    local class = HORDE.classes and HORDE.classes[class_name]
    local subclass = HORDE.subclasses and HORDE.subclasses[subclass_name]
    if not class or not subclass then return nil, "Unknown class or subclass." end
    local parent = subclass.ParentClass or subclass.PrintName
    if parent ~= class.name then return nil, "That subclass does not belong to the selected class." end
    if subclass.ParentClass and ply:Horde_GetSubclassUnlocked(subclass_name) ~= true then
        return nil, "That subclass is not unlocked."
    end
    if not initializing then
        if not ply.Horde_Init_Complete then return nil, "Player initialization is not complete." end
        if HORDE.start_game and (HORDE.current_break_time or 0) <= 0 and ply:Alive() then
            return nil, "You cannot change class after a wave has started."
        end
        if ply:Horde_GetClass() and ply:Horde_GetClass().name == class_name
            and ply:Horde_GetCurrentSubclass() == subclass_name then
            return nil, "You are already using this subclass."
        end
        if GetConVar("horde_testing_unlimited_class_change"):GetInt() == 0
            and HORDE.player_class_changed and HORDE.player_class_changed[ply:SteamID()] then
            return nil, "You cannot change class more than once per wave."
        end

        local allowed, reason = HORDE:CanTakeClassSlot(ply, class_name, subclass_name)
        if not allowed then
            return nil, reason or "This class hit the server limit!"
        end
    end
    return class, subclass
end

function plymeta:Horde_SetClass(class)
    self.Horde_class = class
    if GetConVarNumber("horde_enable_class_models") == 0 then return end
    self:Horde_SetClassModel(class)
end

function plymeta:Horde_SetSubclass(class_name, subclass_name, validated)
    if SERVER and not validated then
        local class = HORDE:ValidateClassTransition(self, class_name, subclass_name, false)
        if not class then return false end
    end
    local subclass = HORDE.subclasses and HORDE.subclasses[subclass_name]
    if not HORDE.classes[class_name] or not subclass
        or (subclass.ParentClass or subclass.PrintName) ~= class_name then return false end
    if SERVER and subclass.ParentClass and self:Horde_GetSubclassUnlocked(subclass_name) ~= true then return false end
    if not self.Horde_subclasses then self.Horde_subclasses = {} end
    self.Horde_subclasses[class_name] = subclass_name
    if SERVER then
        if self:GetWeapons() then
            for _, wpn in pairs(self:GetWeapons()) do
                if HORDE.items[wpn:GetClass()] then
                    local item = HORDE.items[wpn:GetClass()]
                    if self:Horde_GetCurrentSubclass() == "Gunslinger" and item.category == "Pistol" then
                        continue
                    end
                    if item.whitelist and not item.whitelist[self:Horde_GetCurrentSubclass()] then
                        local wpn_class = wpn:GetClass()
                        timer.Simple(0, function ()
                            if IsValid(self) then self:StripWeapon(wpn_class) end
                        end)
                        continue
                    end
                end
            end
        end

        local gadget = HORDE.items[self:Horde_GetGadget()]
        if gadget and gadget.category == "Gadget" and gadget.whitelist and not gadget.whitelist[self:Horde_GetCurrentSubclass()] then
            self:Horde_UnsetGadget()
            self:Horde_SyncEconomy()
        end

        if self.Horde_subclasses[class_name] == self:Horde_GetCurrentSubclass() then
            self:Horde_RemoveMinionsAndDrops()

            if self.Horde_Special_Upgrades then
                for upgrades in pairs(self.Horde_Special_Upgrades) do
                    self:Horde_UnsetSpecialUpgrade(upgrades)
                end
            end
        end

        HORDE:SendNotification(class_name .. " subclass changed to " .. subclass.PrintName, 0, self)
    end
    if CLIENT then
        net.Start("Horde_SetSubclass")
            net.WriteString(class_name)
            net.WriteString(subclass_name)
        net.SendToServer()
    end
    return true
end

function plymeta:Horde_SetSubclassUnlocked(subclass, unlocked)
    if not self.Horde_subclasses_unlocked then return end
    self.Horde_subclasses_unlocked[subclass] = unlocked
    if SERVER and unlocked == true then
        net.Start("Horde_SubclassUnlocked")
            net.WriteString(subclass)
        net.Send(self)
        HORDE:SaveSubclassUnlocks(self)
    end
end

function plymeta:Horde_SetSubclassChoice(class_name, subclass_name)
    MySelf.Horde_subclass_choices[class_name] = subclass_name
    if CLIENT then
        HORDE:SaveSubclassChoices()
    end
end

function plymeta:Horde_GetClass()
    return self.Horde_class
end

function plymeta:Horde_GetSubclass(class_name)
    if self.Horde_subclasses and self.Horde_subclasses[class_name] then
        return self.Horde_subclasses[class_name]
    else
        return class_name
    end
end

function plymeta:Horde_GetSubclassUnlocked(subclass)
    if not self.Horde_subclasses_unlocked then self.Horde_subclasses_unlocked = {} end
    local definition = HORDE.subclasses and HORDE.subclasses[subclass]
    if not definition then return false end
    if not definition.ParentClass then return true end
    return self.Horde_subclasses_unlocked[subclass] == true
end

function plymeta:Horde_GetCurrentSubclass()
    if not self:Horde_GetClass() then return end
    if self.Horde_subclasses and self.Horde_subclasses[self:Horde_GetClass().name] then
        return self.Horde_subclasses[self:Horde_GetClass().name]
    else
        return self:Horde_GetClass().name
    end
end

function HORDE:SaveSubclassChoices()
    if not HORDE.Prefs then return end
    HORDE.Prefs.SetTable("subclass_choices", MySelf.Horde_subclass_choices or {})
end

function HORDE:LoadSubclassChoices()
    MySelf.Horde_subclass_choices = {}

    local stored = HORDE.Prefs and HORDE.Prefs.GetTable("subclass_choices")

    if not stored and file.Exists("horde/subclass_choices.txt", "DATA") then
        stored = {}
        local f = file.Open("horde/subclass_choices.txt", "rb", "DATA")
        if f then
            while not f:EndOfFile() do
                local class_order    = f:ReadULong()
                local subclass_order = f:ReadULong()
                local class_name     = HORDE.order_to_class_name[class_order]
                local subclass_name  = HORDE.order_to_subclass_name[tostring(subclass_order)]
                if class_name and subclass_name then
                    stored[class_name] = subclass_name
                end
            end
            f:Close()
        end
        HORDE.Prefs.SetTable("subclass_choices", stored)
    end

    if not MySelf.Horde_subclasses then MySelf.Horde_subclasses = {} end

    if stored then
        for class_name, subclass_name in pairs(stored) do
            if HORDE.classes_to_subclasses[class_name] and HORDE.subclasses[subclass_name] then
                MySelf.Horde_subclass_choices[class_name] = subclass_name
                MySelf.Horde_subclasses[class_name]       = subclass_name
            end
        end
    end

    for class_name, _ in pairs(HORDE.classes_to_subclasses) do
        if not MySelf.Horde_subclass_choices[class_name] then
            MySelf.Horde_subclass_choices[class_name] = class_name
        end
    end

    HORDE:SaveSubclassChoices()
end

if CLIENT then
hook.Add("InitPostEntity", "Horde_PlayerInit", function()
    timer.Simple(0, function ()
        HORDE:LoadSubclassChoices()
        local f = HORDE.Prefs and HORDE.Prefs.Get("class_choice")
        if f then
            local class = f
            if not HORDE.subclasses[class] then
                class = HORDE.Class_Survivor
            end

            HORDE:SendSavedPerkChoices(class)
            local parent = HORDE.subclasses[class] and HORDE.subclasses[class].ParentClass
            if parent and HORDE.subclasses[parent] then
                HORDE:SendSavedPerkChoices(parent)
            end

            net.Start("Horde_InitClass")
            net.WriteString(class)
            net.SendToServer()
        else
            HORDE:SendSavedPerkChoices(HORDE.Class_Survivor)
        end
        net.Start("Horde_PlayerInit")
        net.SendToServer()
    end)
end)

net.Receive("Horde_SubclassUnlocked", function ()
    local subclass = net.ReadString()
    MySelf:Horde_SetSubclassUnlocked(subclass, true)
end)
end

if SERVER then
    hook.Add("PlayerInitialSpawn", "Horde_ClassLimit_AutoReassign", function(ply)
        timer.Simple(5, function()
            if not IsValid(ply) then return end
            if not ply.Horde_Init_Complete then return end

            local current_class = ply:Horde_GetClass()
            if not current_class then return end
            if current_class.name == HORDE.Class_Survivor then return end

            local current_subclass = ply:Horde_GetCurrentSubclass()
            local ok = HORDE:CanTakeClassSlot(ply, current_class.name, current_subclass)
            if ok then return end

            local found_class, found_subclass = nil, nil

            for class_name, _ in pairs(HORDE.classes or {}) do
                if class_name == HORDE.Class_Survivor then continue end
                if HORDE:CountClassPlayers(class_name, ply) >= HORDE:GetClassPlayerLimit(class_name) then
                    continue
                end

                local subclass_list = HORDE.classes_to_subclasses and HORDE.classes_to_subclasses[class_name]
                if not subclass_list then continue end

                for _, sc_name in pairs(subclass_list) do
                    if ply:Horde_GetSubclassUnlocked(sc_name) == false then continue end

                    local sub = HORDE.subclasses and HORDE.subclasses[sc_name]
                    if sub and sub.player_limit ~= nil then
                        if HORDE:CountSubclassPlayers(sc_name, ply) >= HORDE:GetClassPlayerLimit(sc_name) then
                            continue
                        end
                    end

                    found_class    = class_name
                    found_subclass = sc_name
                    break
                end
                if found_class then break end
            end

            if found_class and HORDE.classes[found_class] then
                HORDE:SendNotification(
                    "Your class [" .. current_class.name .. "] is full. You have been moved to [" .. found_class .. "].",
                    1, ply
                )
                ply:Horde_SetClass(HORDE.classes[found_class])
                ply:Horde_SetSubclass(found_class, found_subclass, true)
                ply:Horde_ApplyPerksForClass()
                ply:Horde_SyncEconomy()
            elseif HORDE.classes[HORDE.Class_Survivor] then
                HORDE:SendNotification(
                    "All available classes are full. You have been moved to Survivor.",
                    1, ply
                )
                ply:Horde_SetClass(HORDE.classes[HORDE.Class_Survivor])
                ply:Horde_SetSubclass(HORDE.Class_Survivor, HORDE.Class_Survivor, true)
                ply:Horde_ApplyPerksForClass()
                ply:Horde_SyncEconomy()
            end
        end)
    end)
end
