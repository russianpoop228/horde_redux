CreateConVar("horde_default_enemy_config", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Use default enemy wave config settings.")
CreateConVar("horde_default_item_config", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Use default item config settings.")
CreateConVar("horde_default_class_config", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_SERVER_CAN_EXECUTE, "Use default class config settings.")
CreateConVar("horde_max_wave", 10, FCVAR_SERVER_CAN_EXECUTE, "Max waves.")
CreateConVar("horde_break_time", 60, FCVAR_SERVER_CAN_EXECUTE, "Break time between waves.")
CreateConVar("horde_enable_shop", 1, FCVAR_SERVER_CAN_EXECUTE + FCVAR_REPLICATED, "Enables shop menu or not.")
CreateConVar("horde_enable_shop_icons", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Enables shop menu icons or not.")
CreateConVar("horde_enable_perk", 1, FCVAR_SERVER_CAN_EXECUTE + FCVAR_REPLICATED, "Enables perks or not.")
CreateConVar("horde_enable_rank", 1, FCVAR_SERVER_CAN_EXECUTE + FCVAR_REPLICATED, "Enables ranks or not.")
CreateConVar("horde_enable_client_gui", 1, FCVAR_SERVER_CAN_EXECUTE, "Enables client information ui or not.")
CreateConVar("horde_max_spawn_distance", 2000, FCVAR_SERVER_CAN_EXECUTE, "Maximum enenmy respawn distance.")
CreateConVar("horde_min_spawn_distance", 400, FCVAR_SERVER_CAN_EXECUTE, "Minimum enenmy respawn distance.")
CreateConVar("horde_max_spawn_z_distance", 500, FCVAR_SERVER_CAN_EXECUTE, "Maximum enemy respawn height difference with players.")

CreateConVar("horde_start_money", 900, FCVAR_SERVER_CAN_EXECUTE, "Money given at start.")
CreateConVar("horde_round_bonus", 500, FCVAR_SERVER_CAN_EXECUTE, "Round bonus given at the end of the round.")
CreateConVar("horde_enable_ammobox", 1, FCVAR_SERVER_CAN_EXECUTE, "Enable ammobox spawns.")
CreateConVar("horde_npc_cleanup", 1, FCVAR_SERVER_CAN_EXECUTE, "Kills all NPCs after a wave.")
CreateConVar("horde_external_lua_config", "", FCVAR_SERVER_CAN_EXECUTE, "Name of external config to load. This will take over the configs if exists.")

CreateConVar("horde_director_interval", 9, FCVAR_SERVER_CAN_EXECUTE, "Game director execution interval in seconds. Decreasing this increases spawn rate.")
CreateConVar("horde_max_enemies_alive_base", 20, FCVAR_SERVER_CAN_EXECUTE, "Maximum number of living enemies (base).")
CreateConVar("horde_max_enemies_alive_scale_factor", 5, FCVAR_SERVER_CAN_EXECUTE, "Scale factor of the maximum number of living enemies for multiplayer.")
CreateConVar("horde_max_enemies_alive_max", 50, FCVAR_SERVER_CAN_EXECUTE, "Maximum number of maximum living enemies.")
CreateConVar("horde_corpse_cleanup", 0, FCVAR_SERVER_CAN_EXECUTE, "Remove corpses.")
CreateConVar("horde_decal_cleanup_interval", 60, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Seconds between client decal cleanups (r_cleardecals). 0 = off.", 0, 3600)

CreateConVar("horde_base_walkspeed", 180, FCVAR_SERVER_CAN_EXECUTE, "Base walkspeed.")
CreateConVar("horde_base_runspeed", 220, FCVAR_SERVER_CAN_EXECUTE, "Base runspeed.")

CreateConVar("horde_difficulty", 0, FCVAR_SERVER_CAN_EXECUTE, "Difficulty.")
CreateConVar("horde_modifier", 0, FCVAR_SERVER_CAN_EXECUTE, "Difficulty modifier (0 = none), see horde.txt.")
CreateConVar("horde_disable_difficulty_voting", 0, FCVAR_SERVER_CAN_EXECUTE, "Disable difficulty voting.")
CreateConVar("horde_total_enemies_scaling", 0, FCVAR_SERVER_CAN_EXECUTE, "Forces the gamemode to multiply maximum enemy count by this.")

CreateConVar("horde_perk_start_wave", 1, FCVAR_SERVER_CAN_EXECUTE + FCVAR_REPLICATED, "The wave when Tier 1 perks are active.")
CreateConVar("horde_perk_scaling", 2, FCVAR_SERVER_CAN_EXECUTE + FCVAR_REPLICATED, "The multiplier to the level for which wave it is unlocked. e.g. at 1.5, perk level 4 is unlocked at start_wave + 6.", 0)

CreateConVar("horde_enable_starter", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Enables starter weapons.")
CreateConVar("horde_arccw_attinv_free", 1, FCVAR_SERVER_CAN_EXECUTE + FCVAR_REPLICATED, "Free ArcCW attachments.")

CreateConVar("horde_ready_countdown_ratio", 0.5, FCVAR_SERVER_CAN_EXECUTE, "Ratio of players required to start the 60 second countdown (0-1).")

CreateConVar("horde_enable_scoreboard", 1, FCVAR_SERVER_CAN_EXECUTE, "Enables built-in scoreboard.")
CreateConVar("horde_enable_3d2d_icon", 1, FCVAR_SERVER_CAN_EXECUTE, "Enables player icon renders.")

CreateConVar("horde_turret_spread", 0.5, FCVAR_SERVER_CAN_EXECUTE, "Turret spread.")

CreateConVar("horde_testing_unlimited_class_change", 1, FCVAR_SERVER_CAN_EXECUTE, "Unlimited class changes (default). Set to 0 to allow changing class only once per wave.")
CreateConVar("horde_testing_display_damage", 0, FCVAR_ARCHIVE, "Display damage for testing.")
CreateConVar("horde_display_damage", 1, FCVAR_ARCHIVE, "Display damage.")
CreateConVar("horde_enable_health_gui", 1, FCVAR_ARCHIVE, "Enables health UI.")
CreateConVar("horde_enable_ammo_gui", 1, FCVAR_ARCHIVE, "Enables ammo UI.")

CreateConVar("horde_enable_class_models", 1, FCVAR_ARCHIVE, "Enables ammo UI.")
CreateConVar("horde_testing_attachment_copy", 0, FCVAR_SERVER_CAN_EXECUTE + FCVAR_REPLICATED, "Make everything available in attachment menu and right click to copy attachment class")
CreateConVar("horde_testing_render_hitboxes", 0, FCVAR_SERVER_CAN_EXECUTE, "Renders hitboxes for enemies. For testing purposes only.")
CreateClientConVar("horde_disable_default_gadget_use_key", 0, FCVAR_ARCHIVE, "Disable default key bind for active gadgets.")
CreateClientConVar("horde_disable_default_quick_grenade_key", 0, FCVAR_ARCHIVE, "Disable default key bind for quick grenade.")

if SERVER then
util.AddNetworkString("Horde_SideNotification")
util.AddNetworkString("Horde_SideNotificationDebuff")
util.AddNetworkString("Horde_SideNotificationObjective")
util.AddNetworkString("Horde_PlayerInit")
util.AddNetworkString("Horde_SyncItems")
util.AddNetworkString("Horde_SyncEnemies")
util.AddNetworkString("Horde_SyncClasses")
util.AddNetworkString("Horde_SyncStatus")
util.AddNetworkString("Horde_SyncSpecialArmor")
util.AddNetworkString("Horde_PlayerReadySync")
util.AddNetworkString("Horde_AmmoboxCountdown")
util.AddNetworkString("Horde_SyncBossSpawned")
util.AddNetworkString("Horde_SyncBossHealth")
end

HORDE = HORDE or {}
HORDE.__index = HORDE
HORDE.version = "2.1.1"
print("[HORDE] HORDE Version is " .. HORDE.version)

function HORDE:AllowNetRequest(ply, key, interval)
    if not IsValid(ply) then return false end
    ply.Horde_NetRequestTimes = ply.Horde_NetRequestTimes or {}
    local now = CurTime()
    if (ply.Horde_NetRequestTimes[key] or 0) > now then return false end
    ply.Horde_NetRequestTimes[key] = now + (interval or 0.5)
    return true
end

HORDE.pending_config = HORDE.pending_config or {}

function HORDE:ShouldApplyConfigImmediately()
    return not (self.start_game and (self.current_break_time or 0) <= 0)
end

function HORDE:QueueConfigApply(key, fn)
    if type(fn) ~= "function" then return false end

    if self:ShouldApplyConfigImmediately() then
        self.pending_config[key] = nil
        local ok, err = pcall(fn)
        if not ok then
            ErrorNoHalt("[HORDE] Failed to apply config '" .. tostring(key) .. "': " .. tostring(err) .. "\n")
        end
        return false
    end

    self.pending_config[key] = fn
    return true
end

function HORDE:ApplyPendingConfigs()
    if not self.pending_config or table.IsEmpty(self.pending_config) then return end
    local queue = self.pending_config
    self.pending_config = {}
    for key, fn in pairs(queue) do
        local ok, err = pcall(fn)
        if not ok then
            ErrorNoHalt("[HORDE] Failed to apply pending config '" .. tostring(key) .. "': " .. tostring(err) .. "\n")
        end
    end
end

function HORDE:GetWaveExpMultiplier()
    if not (self.hundred_mode or self.unarmed_mode) then return 1 end
    local wave = self.current_wave or 0
    if wave < 10 then return 1 end
    return math.min(1 + 0.25 * math.floor(wave / 10), 3)
end

HORDE.color_crimson = Color(220, 20, 60, 225)
HORDE.color_crimson_dim = Color(200, 0, 40)
HORDE.color_crimson_dark = Color(100,0,0)
HORDE.color_crimson_violet = Color(146, 43, 62)
HORDE.color_gadget_active = HORDE.color_crimson
HORDE.color_gadget_once = Color(238,130,238)
HORDE.color_hollow = Color(40,40,40,225)
HORDE.color_hollow_dim = Color(80, 80, 80, 225)
HORDE.color_config_bar = Color(50, 50, 50, 200)
HORDE.color_config_bg = Color(150, 150, 150, 200)
HORDE.color_config_content_bg = Color(230,230,230)
HORDE.color_none = Color(0,0,0,0)
HORDE.color_config_btn = Color(40,40,40)
HORDE.start_game = false
HORDE.total_enemies_per_wave = {15, 19, 23, 27, 30, 33, 36, 39, 42, 45}

local rng_state = bit.bxor(bit.tobit(os.time() % 4294967296),
    bit.rol(bit.tobit(math.floor(SysTime() * 1000000) % 4294967296), 16))
if rng_state == 0 then rng_state = 0x2545F491 end

function HORDE:Random(a, b)
    local x = rng_state
    x = bit.bxor(x, bit.lshift(x, 13))
    x = bit.bxor(x, bit.rshift(x, 17))
    x = bit.bxor(x, bit.lshift(x, 5))
    rng_state = x
    local f = (x % 4294967296) / 4294967296
    if a == nil then return f end
    if b == nil then a, b = 1, a end
    return a + math.floor(f * (b - a + 1))
end

for _ = 1, 16 do HORDE:Random() end

function HORDE:Shuffle(list)
    for i = #list, 2, -1 do
        local j = HORDE:Random(i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

HORDE.difficulty = 1
HORDE.total_enemies_this_wave = 0
HORDE.alive_enemies_this_wave = 0
HORDE.killed_enemies_this_wave = 0
HORDE.current_wave = 0
HORDE.total_break_time = math.max(10, GetConVarNumber("horde_break_time"))
HORDE.current_break_time = HORDE.total_break_time

HORDE.max_spawn_distance = math.max(100, GetConVarNumber("horde_max_spawn_distance"))
HORDE.min_spawn_distance = math.max(100, GetConVarNumber("horde_min_spawn_distance"))
HORDE.max_enemies_alive = 20
HORDE.spawned_enemies = {}
HORDE.spawned_enemies_count = {}
HORDE.ai_nodes = {}
HORDE.found_ai_nodes = false
HORDE.enemy_spawn_z = 6
HORDE.min_base_enemy_spawns_per_think = 4
HORDE.max_base_enemy_spawns_per_think = 5
HORDE.spawn_radius = 75
HORDE.max_max_waves = 10
HORDE.max_waves = math.min(HORDE.max_max_waves, math.max(1, GetConVarNumber("horde_max_wave")))
HORDE.hundred_mode = false
HORDE.unarmed_mode = false
HORDE.wave666_mode = false
HORDE.WAVE666_ENEMY_WAVE = 666
HORDE.extended_waves = false
HORDE.hundred_scale_per_wave = 0
HORDE.extended_health_multiplier = 1
HORDE.extended_damage_multiplier = 1
HORDE.start_money = math.max(0, GetConVarNumber("horde_start_money"))
HORDE.total_enemies_this_wave_fixed = 0
HORDE.kill_reward_base = 90
HORDE.round_bonus_base = GetConVar("horde_round_bonus"):GetInt()
HORDE.disable_levels_restrictions = 0
if CLIENT then
net.Receive("Horde_Disable_Levels", function ()
    HORDE.disable_levels_restrictions = 1
end)
end

HORDE.SPAWN_PROXIMITY = 0
HORDE.SPAWN_UNIFORM = 1
HORDE.SPAWN_PROXIMITY_NOISY = 2

HORDE.ammobox_max_count_limit = 9
HORDE.ammobox_refresh_interval = 60
HORDE.enable_ammobox = GetConVar("horde_enable_ammobox"):GetInt()

HORDE.player_drop_entities = {}
HORDE.player_ready = {}
HORDE.player_damage = {}
HORDE.player_damage_taken = {}
HORDE.player_heal = {}
HORDE.player_headshots = {}
HORDE.player_elite_kills = {}
HORDE.player_vote_map_change = {}
HORDE.player_kills_weapon = {}

HORDE.render_highlight_disable = 0
HORDE.render_highlight_enemies = 1
HORDE.render_highlight_ammoboxes = 2
HORDE.difficulty_text = {}
HORDE.difficulty_base_name = nil

function HORDE:GetDifficultyLabel(name)
    if not isstring(name) or name == "" then return nil end
    local s = translate.Get("Game_Difficulty_" .. name)
    if isstring(s) and s ~= "" then return s end
    return (string.gsub(name, "_", " "))
end

function HORDE:GetActiveModeLabel()
    return HORDE:GetDifficultyLabel(HORDE.difficulty_text and HORDE.difficulty_text[HORDE.difficulty])
end

function HORDE:GetActiveDifficultyTitle()
    local name = HORDE.difficulty_text and HORDE.difficulty_text[HORDE.difficulty]
    local label = HORDE:GetDifficultyLabel(name)
    if not label then return nil end

    local base = HORDE.difficulty_base_name
    if isstring(base) and base ~= "" and string.upper(base) ~= string.upper(name or "") then
        return (HORDE:GetDifficultyLabel(base) or base) .. " + " .. label
    end
    return label
end

if ArcCWInstalled then
    if GetConVar("horde_arccw_attinv_free"):GetInt() == 0 then
        RunConsoleCommand("arccw_attinv_free", "0")
    else
        RunConsoleCommand("arccw_attinv_free", "1")
    end

    if GetConVar("horde_default_item_config"):GetInt() == 1 then
        ArcCW.AttachmentBlacklistTable["go_perk_headshot"] = true
        ArcCW.AttachmentBlacklistTable["go_perk_ace"] = true
        ArcCW.AttachmentBlacklistTable["go_perk_last"] = true
        ArcCW.AttachmentBlacklistTable["go_perk_refund"] = true
        ArcCW.AttachmentBlacklistTable["go_perk_slow"] = true
        ArcCW.AttachmentBlacklistTable["go_m249_mag_12g_45"] = true
        ArcCW.AttachmentBlacklistTable["go_ammo_tr"] = true
        ArcCW.AttachmentBlacklistTable["go_ammo_blanks"] = true
    end
end

RunConsoleCommand("sbox_godmode", "0")
RunConsoleCommand("vj_npc_ply_frag", "0")
RunConsoleCommand("vj_npc_sight_xray", "1")
RunConsoleCommand("vj_npc_melee_bleed", "0")

function HORDE:GiveAmmo(ply, wpn, count)
    local clip_size = wpn:GetMaxClip1()
    local ammo_id = wpn:GetPrimaryAmmoType()

    if clip_size > 0 then
        ply:GiveAmmo(clip_size * count, ammo_id, false)
        return true
    else
        if ammo_id >= 1 then
            ply:GiveAmmo(count, ammo_id, false)
            return true
        end
    end
    return false
end

function HORDE:Round2(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

function HORDE:GetUpgradePrice(class, ply)
    local level
    if CLIENT then
        level = MySelf:Horde_GetUpgrade(class)
    else
        level = ply:Horde_GetUpgrade(class)
    end
    if HORDE.relic_weapon_subclass[class] then
        local price = 800 + 25 * level
        return price
    else
        local base_price = HORDE.items[class].price
        local price = HORDE:Round2(math.max(100, base_price / 2) + math.max(10, base_price / 64) * level)
        return price
    end
end

HORDE.Stack = {}

function HORDE.Stack:Create()

  local t = {}
  t._et = {}

  function t:push(...)
    if ... then
      local targs = {...}
      for _,v in ipairs(targs) do
        table.insert(self._et, v)
      end
    end
  end

  function t:pop(num)

    local num = num or 1

    local entries = {}

    for i = 1, num do
      if #self._et ~= 0 then
        table.insert(entries, self._et[#self._et])
        table.remove(self._et)
      else
        break
      end
    end
    return unpack(entries)
  end

  function t:getn()
    return #self._et
  end

  function t:list()
    for i,v in pairs(self._et) do
      print(i, v)
    end
  end
  return t
end

HORDE.Queue = {}
function HORDE.Queue:Create()
    local t = {}
    t._et = {}

    local first, last = 0, -1
    function t:push(item)
      last = last + 1
      t._et[last] = item
    end
    function t:pop()
      if first <= last then
        local value = t._et[first]
        t._et[first] = nil
        first = first + 1
        return value
      end
    end

    function t:size()
        return (last-first+1)
    end
    return t
end

local function checkInSight(trace, targetent, advanced)
    if(!advanced) then
        trace.endpos = trace.endpos + targetent:OBBCenter()
        return util.TraceLine(trace).Fraction == 1
    else
        if(util.TraceLine(trace).Fraction == 1) then return true end
        trace.endpos = trace.endpos + targetent:OBBCenter()
        if(util.TraceLine(trace).Fraction == 1) then return true end
        trace.endpos = targetent:GetPos() + Vector(0, 0, targetent:OBBMaxs().z)
        if(util.TraceLine(trace).Fraction == 1) then return true end
        return false
    end
end

function HORDE.IsInSight(data)
    local mode = data.checkmode || 1
    if(mode == 1) then
        local origin = data.originEntity:GetPos()
        if(data.originEntityCenter) then
            origin = origin + data.originEntity:OBBCenter()
        end
        local pos = data.targetEntity:GetPos()
        if(data.maxAngle) then
            local y1 = data.originEntity:GetAngles().y
            local y2 = (pos - origin):Angle().y
            if(math.NormalizeAngle(y1 - y2) > data.maxAngle) then
                return false
            end
        end
        local tr = {
            start = origin,
            endpos = pos,
            mask = MASK_SOLID_BRUSHONLY,
        }
        return checkInSight(tr, data.targetEntity, data.advancedCheck)
    else
        local pos = data.targetEntity:GetPos()
        local tr = {
            start = data.originVector,
            endpos = pos,
            mask = MASK_SOLID_BRUSHONLY,
        }
        return checkInSight(tr, data.targetEntity, data.advancedCheck)
    end
end

if(SERVER) then
    util.AddNetworkString("Horde_ScreenEffect")

    function HORDE.SendBorderEffect(ply, data)
        net.Start("Horde_ScreenEffect")
        net.WriteTable(data)
        net.Send(ply)
    end
else
    HORDE.BorderDefaultMaterial = Material("materials/hud_effects/Rectangle_Effect_01.png")
    net.Receive("Horde_ScreenEffect", function()
        local data = net.ReadTable()
        HORDE:SetBorderEffects(data)
    end)

    HORDE.BorderEffects = {}

    function HORDE:RemoveAllScreenEffects()
        HORDE.BorderEffects = {}
    end

    function HORDE.GetFixedValue(inputNum)
        local target = 0.016666
        return inputNum / (target / RealFrameTime())
    end

    local default = {
        material = HORDE.BorderDefaultMaterial,
        color = Color(255, 255, 255, 255),
        alpha = 255,
        time = 1,
        wait_til_end = false,
        fadeoutspeed = 10,
    }
    function HORDE:SetBorderEffects(data)
        if(!data || !data.id) then return end
        local id = data.id
        local effect = {}
            effect.calpha = 255
        if(data.material) then
            data.material = Material(data.material)
        end
        if(!HORDE.BorderEffects[id]) then
            for index,val in pairs(default) do
                if(data[index]) then
                    effect[index] = data[index]
                else
                    effect[index] = val
                end
                if(index == "time") then
                    effect.endtime = CurTime() + effect[index]
                end
            end
            HORDE.BorderEffects[id] = effect
        else
            for index,val in pairs(data) do
                HORDE.BorderEffects[id][index] = val
                if(index == "time") then
                    HORDE.BorderEffects[id].endtime = CurTime() + val
                end
            end
        end
    end

    hook.Add("HUDPaintBackground", "HORDE_BorderEffect", function()
        if (!LocalPlayer():Alive()) then
            HORDE.BorderEffects = {}
        end
        for k,v in next, HORDE.BorderEffects do
            if(v.endtime <= CurTime()) then
                if(!v.wait_til_end) then
                    HORDE.BorderEffects[k] = nil
                    continue
                else
                    v.calpha = math.Clamp(v.calpha - HORDE.GetFixedValue(v.fadeoutspeed), 0, 255)
                    if(v.calpha <= 0) then
                        HORDE.BorderEffects[k] = nil
                        continue
                    end
                end
            end
            if(!v.wait_til_end) then
                v.calpha = v.alpha * math.Clamp((v.endtime - CurTime()) / v.time, 0, 1)
            end
            surface.SetDrawColor(v.color.r, v.color.g, v.color.b, v.calpha)
            surface.SetMaterial(v.material)
            surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        end
    end)

    local clr = Color(0, 0, 0, 0)
    function HORDE.MaskedSphereRing(pos, radius, steps, thickness, color)
        cam.IgnoreZ(false)
        render.SetStencilEnable(true)
        render.SetStencilCompareFunction(STENCIL_ALWAYS)
        render.SetStencilPassOperation(STENCIL_KEEP)
        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilZFailOperation(STENCIL_KEEP)
        render.SetStencilReferenceValue(1)
        render.SetStencilTestMask(255)
        render.SetStencilWriteMask(255)
        render.ClearStencil()
        render.SetColorMaterial()

        local r1, r2 = radius, radius + thickness

        render.SetStencilCompareFunction(STENCIL_ALWAYS)
        render.SetStencilZFailOperation(STENCIL_INCRSAT)
        render.DrawSphere(pos, -r2, steps, steps, clr)
        render.SetStencilZFailOperation(STENCIL_DECR)
        render.DrawSphere(pos, r2, steps, steps, clr)
        render.SetStencilZFailOperation(STENCIL_INCR)
        render.DrawSphere(pos, -r1, steps, steps, clr)
        render.SetStencilZFailOperation(STENCIL_DECR)
        render.DrawSphere(pos, r1, steps, steps, clr)

        local dir = LocalPlayer():EyeAngles():Forward()

        render.SetStencilCompareFunction( STENCIL_EQUAL )
        render.SetStencilReferenceValue( 1 )
        render.DrawQuadEasy(EyePos() + dir * 10, -dir, 200, 200, color, 0)

        render.SetStencilEnable(false)
    end

    net.Receive("Horde_IsInBuyZone", function()
        local int = net.ReadBool()
        local ply = LocalPlayer()
        if not ply:IsValid() then return end
        ply.Horde_CanBuy = int
    end)

    net.Receive("Horde_IsInBreakTime", function()
        local int = net.ReadBool()
        local ply = LocalPlayer()
        if not ply:IsValid() then return end
        ply.Horde_IsInBreakTime = int
    end)

    hook.Add("PreDrawOpaqueRenderables", "Horde_Circle_Preview_Range", function(depth, skybox, skybox3d)
        hook.Run("PreDraw_ImmersionBreakingCircles")
    end)

end
