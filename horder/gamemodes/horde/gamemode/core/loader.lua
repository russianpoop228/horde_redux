local LOADER_VERSION = "2.1.0"

local GM_PATH  = "horde/gamemode/"
local EXT_PATH = "horde/modules/"

local function _CSLuaFile(path)
    if SERVER then
        local ok, err = pcall(AddCSLuaFile, path)
        if not ok then
            ErrorNoHaltWithStack("[Horde Loader] AddCSLuaFile FAILED: '" .. path .. "'\n" .. tostring(err) .. "\n")
            return false
        end
    end
    return true
end

local function _Include(path)
    local ok, err = pcall(include, path)
    if not ok then
        ErrorNoHaltWithStack("[Horde Loader] include FAILED: '" .. path .. "'\n" .. tostring(err) .. "\n")
        return false
    end
    return true
end

local function LoadFile(full_path, filename)
    local prefix = filename:sub(1, 3)

    _CSLuaFile(full_path)

    if prefix == "sv_" then
        if SERVER then return _Include(full_path) end
    elseif prefix == "cl_" then
        if CLIENT then return _Include(full_path) end
    else
        return _Include(full_path)
    end
    return true
end

local content_hook_cache = {}

local function RegisterContentHooks(hook_id, hooks)
    local previous = content_hook_cache[hook_id]
    if previous then
        for event in pairs(previous) do
            hook.Remove(event, hook_id)
        end
    end
    local registered = {}
    for event, fn in pairs(hooks or {}) do
        hook.Add(event, hook_id, fn)
        registered[event] = true
    end
    content_hook_cache[hook_id] = registered
end

HORDE = HORDE or {}
HORDE.PerkOwnerHooks = HORDE.PerkOwnerHooks or {}
HORDE.PerkHookVersion = HORDE.PerkHookVersion or 0
local owner_dispatchers = {}
local OWNER_DISPATCH_ID = "horde_perk_owner_dispatch"

local function BuildOwnerList(ply, event)
    local handlers = HORDE.PerkOwnerHooks[event]
    local list = {}
    if handlers and ply.Horde_Perks then
        for perk in pairs(ply.Horde_Perks) do
            local fn = handlers[perk]
            if fn then list[#list + 1] = fn end
        end
    end
    return list
end

local function EnsureOwnerDispatcher(event)
    if owner_dispatchers[event] then return end
    owner_dispatchers[event] = true
    hook.Add(event, OWNER_DISPATCH_ID, function(ply, ...)
        if not isentity(ply) or not ply.Horde_Perks then return end
        local cache = ply.Horde_PerkHookCache
        if not cache or cache.__ver ~= HORDE.PerkHookVersion then
            cache = { __ver = HORDE.PerkHookVersion }
            ply.Horde_PerkHookCache = cache
        end
        local list = cache[event]
        if not list then
            list = BuildOwnerList(ply, event)
            cache[event] = list
        end
        for i = 1, #list do
            local r1, r2, r3, r4, r5, r6 = list[i](ply, ...)
            if r1 ~= nil then return r1, r2, r3, r4, r5, r6 end
        end
    end)
end

local function RegisterOwnerHooks(class, hooks)
    for event, map in pairs(HORDE.PerkOwnerHooks) do
        map[class] = nil
    end
    for event, fn in pairs(hooks or {}) do
        HORDE.PerkOwnerHooks[event] = HORDE.PerkOwnerHooks[event] or {}
        HORDE.PerkOwnerHooks[event][class] = fn
        EnsureOwnerDispatcher(event)
    end
    HORDE.PerkHookVersion = HORDE.PerkHookVersion + 1
end

local player_tick_list  = {}
local player_tick_ids   = {}

local function RebuildPlayerTickIndex()
    for i, entry in ipairs(player_tick_list) do player_tick_ids[entry.id] = i end
end

function HORDE:AddPlayerTick(id, fn)
    local idx = player_tick_ids[id]
    if idx then
        player_tick_list[idx].fn = fn
    else
        player_tick_list[#player_tick_list + 1] = { id = id, fn = fn }
        player_tick_ids[id] = #player_tick_list
    end
    HORDE.PlayerTickFns = nil
end

function HORDE:RemovePlayerTick(id)
    local idx = player_tick_ids[id]
    if not idx then return end
    table.remove(player_tick_list, idx)
    player_tick_ids[id] = nil
    RebuildPlayerTickIndex()
    HORDE.PlayerTickFns = nil
end

local flat_tick_fns = {}
local function FlattenPlayerTick()
    flat_tick_fns = {}
    for i, entry in ipairs(player_tick_list) do flat_tick_fns[i] = entry.fn end
    HORDE.PlayerTickFns = flat_tick_fns
end

hook.Add("PlayerTick", "Horde_PlayerTickDispatch", function(ply, mv)
    local fns = HORDE.PlayerTickFns
    if not fns then FlattenPlayerTick() fns = flat_tick_fns end
    for i = 1, #fns do
        fns[i](ply, mv)
    end
end)

local function RegisterGadgetFile(full_path, fname)
    local basename = string.Explode(".", fname)[1]
    GADGET = {}
    LoadFile(full_path, fname)
    if GADGET and not GADGET.Ignore and GADGET.PrintName then
        GADGET.ClassName = string.lower(GADGET.ClassName or basename)
        HORDE.gadgets[GADGET.ClassName] = GADGET
        RegisterContentHooks("horde_gadget_" .. GADGET.ClassName, GADGET.Hooks)
        hook.Run("Horde_OnLoadGadget", GADGET)
        if GetConVar("developer"):GetBool() then print("[Horde Loader]   gadget: " .. GADGET.ClassName) end
    end
    GADGET = nil
end

local function RegisterSpellFile(full_path, fname)
    local basename = string.Explode(".", fname)[1]
    SPELL = {}
    LoadFile(full_path, fname)
    if SPELL and not SPELL.Ignore and SPELL.PrintName then
        SPELL.ClassName = string.lower(SPELL.ClassName or basename)
        HORDE.spells[SPELL.ClassName] = SPELL
        RegisterContentHooks("horde_spell_" .. SPELL.ClassName, SPELL.Hooks)
        if GetConVar("developer"):GetBool() then print("[Horde Loader]   spell: " .. SPELL.ClassName) end
    end
    SPELL = nil
end

local function RegisterMutationFile(full_path, fname)
    local basename = string.Explode(".", fname)[1]
    MUTATION = {}
    LoadFile(full_path, fname)
    if MUTATION and not MUTATION.Ignore and MUTATION.PrintName then
        MUTATION.ClassName = string.lower(MUTATION.ClassName or MUTATION.PrintName or basename)
        HORDE.mutations[MUTATION.ClassName] = MUTATION
        if not MUTATION.NoRand then
            HORDE.mutations_rand[MUTATION.ClassName] = MUTATION
        end
        RegisterContentHooks("horde_mutation_" .. MUTATION.ClassName, MUTATION.Hooks)
        if GetConVar("developer"):GetBool() then print("[Horde Loader]   mutation: " .. MUTATION.ClassName) end
    end
    MUTATION = nil
end

local function RegisterSubclassFile(full_path, fname)
    SUBCLASS = {}
    LoadFile(full_path, fname)
    if SUBCLASS and not SUBCLASS.Ignore and SUBCLASS.PrintName then
        SUBCLASS.SortOrder = SUBCLASS.SortOrder or 0
        SUBCLASS.BasePerk  = SUBCLASS.BasePerk or (string.lower(SUBCLASS.PrintName) .. "_base")
        HORDE.subclasses[SUBCLASS.PrintName] = SUBCLASS
        local crc_val = util.CRC(SUBCLASS.PrintName)
        HORDE.subclass_name_to_crc[SUBCLASS.PrintName] = crc_val
        HORDE.order_to_subclass_name[crc_val]          = SUBCLASS.PrintName
        if SUBCLASS.ParentClass then
            if HORDE.classes_to_subclasses[SUBCLASS.ParentClass] then
                if not table.HasValue(HORDE.classes_to_subclasses[SUBCLASS.ParentClass], SUBCLASS.PrintName) then
                    table.insert(HORDE.classes_to_subclasses[SUBCLASS.ParentClass], SUBCLASS.PrintName)
                end
            end
            HORDE.subclasses_to_classes[SUBCLASS.PrintName] = SUBCLASS.ParentClass
        else
            HORDE.subclasses_to_classes[SUBCLASS.PrintName] = SUBCLASS.PrintName
        end
        if GetConVar("developer"):GetBool() then print("[Horde Loader]   subclass: " .. SUBCLASS.PrintName) end
    end
    SUBCLASS = nil
end

local function RegisterPerkFile(full_path, fname)
    local pbase = string.Explode(".", fname)[1]
    PERK = { OwnerHooks = {} }
    LoadFile(full_path, fname)
    if PERK and not PERK.Ignore and (PERK.PrintName or PERK.ClassName) then
        PERK.ClassName = string.lower(PERK.ClassName or pbase)
        PERK.SortOrder = PERK.SortOrder or 0
        hook.Run("Horde_OnLoadPerk", PERK)
        HORDE.perks[PERK.ClassName] = PERK
        RegisterContentHooks("horde_perk_" .. PERK.ClassName, PERK.Hooks)
        RegisterOwnerHooks(PERK.ClassName, PERK.OwnerHooks)
        if GetConVar("developer"):GetBool() then print("[Horde Loader]   perk: " .. PERK.ClassName) end
    end
    PERK = nil
end

local function RegisterItemFile(full_path, fname)
    ITEM = {}
    LoadFile(full_path, fname)
    if ITEM and not ITEM.Ignore and (ITEM.Class or ITEM.class or ITEM.ClassName) then
        local cat = ITEM.Category or ITEM.category
        local ep = ITEM.EntityProperties or ITEM.entity_properties
        local is_arccw = (cat == "Attachment")
            or (istable(ep) and ep.is_arccw_attachment)
        if is_arccw then
            if ArcCWInstalled ~= true then
                ITEM = nil
                return
            end
            local free_cvar = GetConVar("horde_arccw_attinv_free")
            if free_cvar and free_cvar:GetInt() ~= 0 then
                ITEM = nil
                return
            end
        end
        if HORDE.RegisterItem then
            HORDE:RegisterItem(ITEM)
            if GetConVar("developer"):GetBool() then
                print("[Horde Loader]   item: " .. tostring(ITEM.Class or ITEM.class or ITEM.ClassName))
            end
        end
    end
    ITEM = nil
end

local function RegisterEnemyFile(full_path, fname)
    ENEMY = {}
    LoadFile(full_path, fname)
    if ENEMY and not ENEMY.Ignore and (ENEMY.Name or ENEMY.name) and (ENEMY.Class or ENEMY.class) then
        if HORDE.RegisterEnemy then
            HORDE:RegisterEnemy(ENEMY)
            if GetConVar("developer"):GetBool() then
                print("[Horde Loader]   enemy: " .. tostring(ENEMY.Name or ENEMY.name))
            end
        end
    end
    ENEMY = nil
end

local function RegisterInfusionFile(full_path, fname)
    INFUSION = {}
    LoadFile(full_path, fname)
    if INFUSION and not INFUSION.Ignore and (INFUSION.Key or INFUSION.Name or INFUSION.name) then
        if HORDE.RegisterInfusion then
            HORDE:RegisterInfusion(INFUSION)
            if GetConVar("developer"):GetBool() then
                print("[Horde Loader]   infusion: " .. tostring(INFUSION.Key or INFUSION.Name or INFUSION.name))
            end
        end
    end
    INFUSION = nil
end

local function RegisterConfigFile(full_path, fname)
    HORDE_CONFIG = {}
    LoadFile(full_path, fname)
    if HORDE_CONFIG and not HORDE_CONFIG.Ignore and (HORDE_CONFIG.Difficulty or HORDE_CONFIG.Name) then
        if HORDE.RegisterConfig then
            HORDE:RegisterConfig(HORDE_CONFIG)
            if GetConVar("developer"):GetBool() then
                print("[Horde Loader]   config: " .. tostring(HORDE_CONFIG.Difficulty or HORDE_CONFIG.Name))
            end
        end
    end
    HORDE_CONFIG = nil
end

local MODULE_REGISTRY = {
    difficulties = { desc = "difficulties", register = LoadFile, recursive = true },
    infusions    = { desc = "infusions",    register = RegisterInfusionFile },
    gadgets      = { desc = "gadgets",      register = RegisterGadgetFile, recursive = true },
    spells       = { desc = "spells",       register = RegisterSpellFile,  recursive = true },
    mutations    = { desc = "mutations",    register = RegisterMutationFile },
    subclasses   = { desc = "subclasses",   register = RegisterSubclassFile },
    perks        = { desc = "perks",        register = RegisterPerkFile },
    items        = { desc = "items",        register = RegisterItemFile, recursive = true },
    enemies      = { desc = "enemies",      register = RegisterEnemyFile, recursive = true },
    configs      = { desc = "configs",      register = RegisterConfigFile },
    contextual_ping    = { desc = "contextual_ping",    register = LoadFile, recursive = true },
    quickchat          = { desc = "quickchat",          register = LoadFile, recursive = true },
    waveskip           = { desc = "waveskip",           register = LoadFile, recursive = true },
    playersend         = { desc = "playersend",         register = LoadFile, recursive = true },
    chatbubble         = { desc = "chatbubble",         register = LoadFile, recursive = true },
    strafe_cam         = { desc = "strafe_cam",         register = LoadFile, recursive = true },
    hammer             = { desc = "hammer map entities", register = LoadFile },
}

local FLAT_MODULE_ORDER = { "difficulties", "hammer", "infusions", "gadgets", "spells", "mutations", "subclasses", "items", "enemies", "configs", "contextual_ping", "quickchat", "waveskip", "playersend", "chatbubble", "strafe_cam" }

local function LoadFolder(folder_path, options)
    options = options or {}
    local first_files = options.first_files or {}
    local dev = GetConVar("developer"):GetBool()

    local files, dirs = file.Find(folder_path .. "/*", "LUA")
    if not files then return end

    table.sort(files)

    for _, priority_name in ipairs(first_files) do
        for _, fname in ipairs(files) do
            if fname == priority_name then
                LoadFile(folder_path .. "/" .. fname, fname)
                if dev then print("[Horde Loader]   (priority) " .. fname) end
            end
        end
    end

    for _, fname in ipairs(files) do
        if not fname:EndsWith(".lua") then continue end
        if fname:sub(1, 1) == "_" then continue end

        local already = false
        for _, p in ipairs(first_files) do
            if fname == p then already = true; break end
        end
        if already then continue end

        LoadFile(folder_path .. "/" .. fname, fname)
        if dev then print("[Horde Loader]   " .. fname) end
    end

    if options.recursive and dirs then
        table.sort(dirs)
        for _, dir in ipairs(dirs) do
            if dir:sub(1, 1) ~= "_" then
                LoadFolder(folder_path .. "/" .. dir, options)
            end
        end
    end
end

local SYSTEMS_MANIFEST = {
    { path = "shared/core/sh_horde.lua",       desc = "HORDE table & constants" },
    { path = "shared/core/sh_validate.lua",    desc = "Config validation & net payload limits" },
    { path = "shared/core/sh_database.lua",     desc = "SQLite database wrapper" },
    { path = "shared/core/sh_translate.lua",   desc = "Translations" },
    { path = "shared/core/sh_particles.lua",   desc = "Particle pre-cache" },
    { path = "shared/core/sh_sync.lua",        desc = "Network sync helpers" },
    { path = "shared/core/sh_misc.lua",        desc = "Misc helpers" },
    { path = "shared/core/sh_soul_rebooter.lua", desc = "Soul Rebooter — net strings, menu confirm, ammobox patch" },

    { path = "shared/combat/sh_status.lua",    desc = "Status effect framework" },
    { path = "shared/combat/sh_damage.lua",    desc = "Damage types" },
    { path = "shared/combat/sh_objective.lua", desc = "Objectives" },
    { path = "shared/combat/sh_objectivebar.lua", desc = "Objective progress bar (server: state & progress)" },

    { path = "shared/player/sh_class.lua",     desc = "Class system" },
    { path = "shared/player/sh_minion.lua",    desc = "Minion ownership API (shared)" },
    { path = "shared/player/sh_perk.lua",      desc = "Perk system" },
    { path = "shared/player/sh_gadget.lua",    desc = "Gadget system" },
    { path = "shared/player/sh_spells.lua",    desc = "Spell system" },
    { path = "shared/player/sh_infusion.lua",  desc = "Infusion system" },
    { path = "shared/player/sh_upgrades.lua",  desc = "Upgrade systems registry (universal)" },
    { path = "shared/player/sh_rank.lua",      desc = "Rank system" },
    { path = "shared/player/sh_achievements.lua", desc = "Player achievements (registry + client state)" },

    { path = "shared/world/sh_enemy.lua",      desc = "Enemy registration" },
    { path = "shared/world/sh_mutation.lua",   desc = "Mutation framework" },
    { path = "shared/world/sh_quality.lua",    desc = "Weapon quality & auto-price" },
    { path = "shared/world/sh_item.lua",       desc = "Item/shop framework" },
    { path = "shared/world/sh_maps.lua",       desc = "Map config" },
    { path = "shared/world/sh_specialwaves.lua", desc = "Special Waves data model (presets, sanitize)" },
    { path = "shared/world/sh_gameplayconfig.lua", desc = "Gameplay config (hidden difficulties, default controls)" },
    { path = "shared/world/sh_attachments.lua",desc = "ArcCW attachment config" },
    { path = "shared/world/sh_custom.lua",     desc = "External config hooks" },

    { path = "server/combat/sv_damage.lua",    server_only = true, desc = "Damage processing" },
    { path = "server/combat/sv_heal.lua",      server_only = true, desc = "Healing" },

    { STATUS_PHASE = true },

    { path = "server/core/obj_entity_extend_sv.lua", server_only = true, desc = "VJ NPC extension" },
    { path = "server/core/sv_difficulty.lua",        server_only = true, desc = "Difficulty system" },
    { path = "server/core/sv_hooks.lua",             server_only = true, desc = "Game event hooks" },
    { path = "server/core/sv_nodegraph.lua",         server_only = true, desc = "AI node graph" },
    { path = "server/core/sv_misc.lua",              server_only = true, desc = "Misc server" },
    { path = "server/core/sv_properties.lua",        server_only = true, desc = "Blocked sandbox properties (SHG bugfix)" },
    { path = "server/core/sv_objective_rewards.lua", server_only = true, desc = "Kill rewards tied to objectives" },

    { path = "server/persistence/sv_persistence.lua", server_only = true, desc = "SQLite player persistence" },
    { path = "server/persistence/sv_migration.lua",   server_only = true, desc = "Legacy data/ -> SQLite migration" },

    { path = "server/players/sv_perk.lua",           server_only = true, desc = "Server perk logic" },
    { path = "server/players/sv_rank.lua",           server_only = true, desc = "Rank persistence" },
    { path = "server/players/sv_economy.lua",        server_only = true, desc = "Economy & shop" },
    { path = "server/players/sv_minion.lua",         server_only = true, desc = "Minion registration & spawn (server)" },
    { path = "server/players/sv_commands.lua",       server_only = true, desc = "Console commands" },
    { path = "server/players/sv_playerlifecycle.lua",server_only = true, desc = "Player join/leave/vote" },
    { path = "server/players/sv_leaderboard.lua",    server_only = true, desc = "Leaderboard" },
    { path = "server/players/sv_achievements.lua",   server_only = true, desc = "Player achievements (tracking, SQLite, rewards)" },

    { path = "server/combat/sv_hitnumbers.lua",      server_only = true, desc = "Hit numbers" },
    { path = "server/combat/sv_tip.lua",             server_only = true, desc = "Tip system" },

    { path = "client/core/cl_prefs.lua",       client_only = true, desc = "Client UI preferences (SQLite)" },
    { path = "client/core/cl_economy.lua",     client_only = true, desc = "Client economy" },
    { path = "client/core/cl_achievement.lua", client_only = true, desc = "Achievement display" },
    { path = "client/core/cl_hitnumbers.lua",  client_only = true, desc = "Hit number rendering" },
    { path = "client/core/cl_warden_consumable_ring.lua", client_only = true, desc = "Warden Watchtower consumable ring indicator" },
    { path = "client/core/cl_spectator_ghost.lua", client_only = true, desc = "Spectator ghost sprite (blueflare)" },
    { path = "client/core/cl_init.lua",        client_only = true, desc = "Client init" },

    { path = "server/core/sv_specialwaves.lua", server_only = true, desc = "Special Waves — presets & wave injection" },

    { path = "server/core/sv_horde.lua", server_only = true, desc = "Wave Director — LAST" },
}

local function LoadStatusEffects(base)
    local status_root = GM_PATH .. "modules/status/"

    local sh_files, _ = file.Find(status_root .. "sh_*.lua", "LUA")
    if sh_files then
        table.sort(sh_files)
        for _, f in ipairs(sh_files) do
            LoadFile(status_root .. f, f)
        end
    end

    if file.Exists(status_root .. "sv_barrier.lua", "LUA") then
        if SERVER then
            _CSLuaFile(status_root .. "sv_barrier.lua")
            _Include(status_root .. "sv_barrier.lua")
        end
    end

    LoadFolder(status_root .. "buff", { first_files = { "sv_buff.lua" } })

    LoadFolder(status_root .. "debuff", { first_files = { "sv_debuff.lua" } })
end

local function LoadGUI(base)
    local gui_root = base .. "client/gui/"
    local dev = GetConVar("developer"):GetBool()

    if dev then MsgC(Color(100, 200, 255), "[Horde Loader] Loading GUI...\n") end

    LoadFolder(gui_root .. "npcinfo", {})

    if CLIENT then
        LoadFolder(gui_root .. "scoreboard", {})
    else
        local sb_files, _ = file.Find(gui_root .. "scoreboard/*.lua", "LUA")
        if sb_files then
            for _, f in ipairs(sb_files) do _CSLuaFile(gui_root .. "scoreboard/" .. f) end
        end
    end

    for _, subfolder in ipairs({ "hud", "shop", "config", "class", "summary" }) do
        LoadFolder(gui_root .. subfolder, { client_only = true })
    end
    local files, _ = file.Find(gui_root .. "*.lua", "LUA")
    if files then
        table.sort(files)
        for _, f in ipairs(files) do
            if f:sub(1, 1) ~= "_" then
                LoadFile(gui_root .. f, f)
            end
        end
    end
end

local function LoadCoreSystems()
    local base = GM_PATH .. "system/"
    local dev  = GetConVar("developer"):GetBool()

    for _, entry in ipairs(SYSTEMS_MANIFEST) do

        if entry.STATUS_PHASE then
            LoadStatusEffects(base)
            continue
        end

        local full_path = base .. entry.path

        if entry.server_only then
            _CSLuaFile(full_path)
            if SERVER then _Include(full_path) end
        elseif entry.client_only then
            _CSLuaFile(full_path)
            if CLIENT then _Include(full_path) end
        else
            LoadFile(full_path, entry.path)
        end

        if dev then
            print("[Horde Loader] sys: " .. entry.path .. (entry.desc and (" — " .. entry.desc) or ""))
        end
    end

    LoadGUI(base)
end

local function LoadContentModules(modules_path)
    local dev = GetConVar("developer"):GetBool()

    local function CollectFiles(folder)
        local result = {}
        local files, dirs = file.Find(folder .. "/*", "LUA")
        if files then
            table.sort(files)
            for _, f in ipairs(files) do
                if f:EndsWith(".lua") and f:sub(1,1) ~= "_" then
                    table.insert(result, { path = folder .. "/" .. f, name = f })
                end
            end
        end
        if dirs then
            table.sort(dirs)
            for _, d in ipairs(dirs) do
                if d:sub(1,1) ~= "_" then
                    for _, entry in ipairs(CollectFiles(folder .. "/" .. d)) do
                        table.insert(result, entry)
                    end
                end
            end
        end
        return result
    end

    for _, dir in ipairs(FLAT_MODULE_ORDER) do
        local mt = MODULE_REGISTRY[dir]
        local folder = modules_path .. dir
        local entries
        if mt.recursive then
            entries = CollectFiles(folder)
        else
            local files, _ = file.Find(folder .. "/*.lua", "LUA")
            entries = {}
            if files then
                table.sort(files)
                for _, f in ipairs(files) do
                    if not f:EndsWith(".lua") or f:sub(1,1) == "_" then continue end
                    table.insert(entries, { path = folder .. "/" .. f, name = f })
                end
            end
        end
        if #entries > 0 then
            if dev then MsgC(Color(100, 200, 255), "[Horde Loader] Loading " .. mt.desc .. "...\n") end
            for _, entry in ipairs(entries) do
                local f = entry.name
                local full_path = entry.path
                if f:sub(1, 1) == "_" then continue end
                mt.register(full_path, f)
            end
        end
    end

    if dev then MsgC(Color(100, 200, 255), "[Horde Loader] Loading perks (tree)...\n") end
    local function LoadPerkFolder(folder_path)
        local pfiles, pdirs = file.Find(folder_path .. "/*", "LUA")
        if pfiles then
            table.sort(pfiles)
            for _, pf in ipairs(pfiles) do
                if pf:EndsWith(".lua") and pf:sub(1,1) ~= "_" then
                    MODULE_REGISTRY.perks.register(folder_path .. "/" .. pf, pf)
                end
            end
        end
        if pdirs then
            table.sort(pdirs)
            for _, pd in ipairs(pdirs) do
                if pd:sub(1,1) ~= "_" then
                    LoadPerkFolder(folder_path .. "/" .. pd)
                end
            end
        end
    end
    LoadPerkFolder(modules_path .. "perks")
end

local function LoadArcCWAttachments(modules_path)
    local att_folder = modules_path .. "arccw/attachments"
    local files, _ = file.Find(att_folder .. "/*.lua", "LUA")
    if not files or #files == 0 then return end
    table.sort(files)
    for _, f in ipairs(files) do
        if f:sub(1, 1) ~= "_" then
            LoadFile(att_folder .. "/" .. f, f)
        end
    end
    print("[Horde Loader] ArcCW attachments: " .. #files)
end

local EXTERNAL_INCLUDE_TYPES = {
    "classes",
    "status/buff", "status/debuff",
    "systems", "gui", "arccw/attachments",
}

local EXT_LANG_MAP = {
    english_lan             = { "en",    "English" },
    russian_lan             = { "ru",    "Russian" },
    spanish_lan             = { "es-es", "Spanish" },
    turkish_lan             = { "tr",    "Turkish" },
    chinese_simplified_lan  = { "zh-cn", "Chinese Simplified" },
    chinese_traditional_lan = { "zh-tw", "Chinese Traditional" },
}

local function LoadExternalLanguages(dev)
    local folder = EXT_PATH .. "languages"
    local files = file.Find(folder .. "/*.lua", "LUA")
    if not files then return false end
    local found = false
    table.sort(files)
    for _, fname in ipairs(files) do
        if fname:sub(1, 1) ~= "_" then
            local full = folder .. "/" .. fname
            local base = string.StripExtension(fname)
            local langinfo = EXT_LANG_MAP[base]

            _CSLuaFile(full)
            LANGUAGE = {}
            if langinfo and translate and translate.AddLanguage then
                translate.AddLanguage(langinfo[1], langinfo[2])
            end
            _Include(full)
            if istable(LANGUAGE) and translate and translate.AddTranslation then
                for k, v in pairs(LANGUAGE) do
                    translate.AddTranslation(k, v)
                end
            end
            LANGUAGE = nil
            if dev then MsgC(Color(255, 200, 100), "[Horde Loader] [EXT LANG] " .. full .. "\n") end
            found = true
        end
    end
    return found
end

local function RegisterExternalFile(module_type, full_path, fname)
    local mt = MODULE_REGISTRY[module_type]
    local register = (mt and mt.register) or LoadFile
    register(full_path, fname)
end

local function RegisterExternalFolder(folder, module_type, dev)
    local files, dirs = file.Find(folder .. "/*", "LUA")
    local found = false
    if files then
        table.sort(files)
        for _, fname in ipairs(files) do
            if fname:EndsWith(".lua") and fname:sub(1, 1) ~= "_" then
                if dev then MsgC(Color(255, 200, 100), "[Horde Loader] [EXT] " .. folder .. "/" .. fname .. "\n") end
                RegisterExternalFile(module_type, folder .. "/" .. fname, fname)
                found = true
            end
        end
    end
    if dirs then
        table.sort(dirs)
        for _, dir in ipairs(dirs) do
            if dir:sub(1, 1) ~= "_" then
                if RegisterExternalFolder(folder .. "/" .. dir, module_type, dev) then found = true end
            end
        end
    end
    return found
end

local function LoadExternalModules()
    local dev = GetConVar("developer"):GetBool()
    local found_any = false

    for _, module_type in ipairs({ "perks", "gadgets", "spells", "mutations", "subclasses", "infusions", "items", "enemies", "configs" }) do
        local ext_folder = EXT_PATH .. module_type
        if RegisterExternalFolder(ext_folder, module_type, dev) then found_any = true end
    end

    if LoadExternalLanguages(dev) then found_any = true end

    for _, mtype in ipairs(EXTERNAL_INCLUDE_TYPES) do
        local ext_folder = EXT_PATH .. mtype
        local files, dirs = file.Find(ext_folder .. "/*", "LUA")

        if files and #files > 0 then
            table.sort(files)
            for _, fname in ipairs(files) do
                if fname:EndsWith(".lua") and fname:sub(1, 1) ~= "_" then
                    local full = ext_folder .. "/" .. fname
                    if dev then MsgC(Color(255, 200, 100), "[Horde Loader] [EXT] " .. full .. "\n") end
                    LoadFile(full, fname)
                    found_any = true
                end
            end
        end

        if dirs then
            table.sort(dirs)
            for _, dir in ipairs(dirs) do
                if dir:sub(1, 1) ~= "_" then
                    local module_folder = ext_folder .. "/" .. dir
                    if dev then MsgC(Color(255, 200, 100), "[Horde Loader] [EXT MODULE] " .. module_folder .. "\n") end
                    LoadFolder(module_folder, { recursive = false })
                    found_any = true
                end
            end
        end
    end

    if not found_any and dev then
        print("[Horde Loader] No external addon modules found.")
    end

    hook.Run("Horde_ExternalModulesLoaded")
end

local function RunLoader()
    local t0  = SysTime()
    local dev = GetConVar("developer"):GetBool()

    MsgC(Color(255, 165, 0),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" ..
        " HORDE Modular Loader v" .. LOADER_VERSION .. "\n" ..
        " Realm: " .. (SERVER and "SERVER" or "CLIENT") .. "\n" ..
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    )

    _CSLuaFile(GM_PATH .. "core/compat.lua")
    _Include(GM_PATH .. "core/compat.lua")

    _CSLuaFile(GM_PATH .. "shared.lua")
    _Include(GM_PATH .. "shared.lua")

    if dev then MsgC(Color(100, 200, 255), "[Horde Loader] === PHASE 1: Core Systems ===\n") end
    LoadCoreSystems()

    _CSLuaFile(GM_PATH .. "core/registry.lua")
    _Include(GM_PATH .. "core/registry.lua")

    if dev then MsgC(Color(100, 255, 100), "[Horde Loader] === PHASE 2: Content Modules ===\n") end
    local modules_path = GM_PATH .. "modules/"
    LoadContentModules(modules_path)

    LoadArcCWAttachments(modules_path)

    if dev then MsgC(Color(255, 200, 100), "[Horde Loader] === PHASE 3: External Addon Modules ===\n") end
    LoadExternalModules()

    local elapsed = math.Round((SysTime() - t0) * 1000, 2)
    MsgC(Color(0, 255, 0), "[Horde Loader] ✓ All modules loaded in " .. elapsed .. "ms\n")

    hook.Run("Horde_AllModulesLoaded")
end

if not HORDE_LOADER_INITIALIZED then
    HORDE_LOADER_INITIALIZED = true
    RunLoader()
end
