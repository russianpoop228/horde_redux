util.AddNetworkString("Horde_ForceCloseShop")
util.AddNetworkString("Horde_ToggleShop")
util.AddNetworkString("Horde_ToggleStats")
util.AddNetworkString("Horde_ToggleConfigMenu")
util.AddNetworkString("Horde_TogglePlayerMenu")
util.AddNetworkString("Horde_ToggleItemConfig")
util.AddNetworkString("Horde_ToggleEnemyConfig")
util.AddNetworkString("Horde_ToggleClassConfig")
util.AddNetworkString("Horde_ToggleMapConfig")
util.AddNetworkString("Horde_RenderCenterText")
util.AddNetworkString("Horde_RenderPlayersReady")
util.AddNetworkString("Horde_RenderBreakCountDown")
util.AddNetworkString("Horde_RenderEnemiesCount")
util.AddNetworkString("Horde_RenderGameResult")
util.AddNetworkString("Horde_Console_Commands")
util.AddNetworkString("Horde_Disable_Levels")

function HORDE:BroadcastPlayersReadyMessage(str)
    net.Start("Horde_RenderPlayersReady")
        net.WriteString(str)
    net.Broadcast()
end

function HORDE:BroadcastBreakCountDownMessage(wave, is_end_message, hold)
    net.Start("Horde_RenderBreakCountDown")
        net.WriteInt(math.max(0, wave), 8)
        net.WriteBool(is_end_message)
        net.WriteBool(hold == true)
    net.Broadcast()
end

function HORDE:BroadcastEnemiesCountMessage(is_boss, wave_str, count)
    net.Start("Horde_RenderEnemiesCount")
        net.WriteBool(is_boss)
        net.WriteString(wave_str)
        net.WriteInt(count, 32)
    net.Broadcast()
end

function HORDE:BroadcastGameResultMessage(status, wave)
    net.Start("Horde_RenderGameResult")
        net.WriteString(status)
        net.WriteUInt(wave, 32)
    net.Broadcast()
end

function HORDE:Start(ply)
    if ply:IsAdmin() then
        if not HORDE.start_game then
            HORDE.start_game = true
        else
            ply:PrintMessage(HUD_PRINTTALK, "Game has already started!")
        end
    else
        HORDE:SendNotificationDenyAccess(ply)
        return
    end
end

function HORDE:Ready(ply)
    if HORDE.current_wave > 0 then HORDE:SkipTraderTime(ply) return end
    if HORDE.current_break_time <= 10 then
        HORDE:SendNotification(translate.Get("Game_F4_Starting"), 1, ply)
        return
    end
    if HORDE.player_ready[ply] == 1 then
        HORDE:SendNotification(translate.Get("Game_F4_Readied"), 1, ply)
        return
    end
    if not ply:Alive() then
        HORDE:SendNotification("You can't get ready when you are dead!", 1, ply)
        return
    end

    HORDE.player_ready[ply] = 1
    local ready_count = 0
    local total_player = 0
    for _, ready_ply in pairs(player.GetAll()) do
        if HORDE.player_ready[ready_ply] == 1 then
            ready_count = ready_count + 1
        end
        total_player = total_player + 1
    end

    if ready_count >= total_player then
        HORDE.start_game = true
        HORDE.current_break_time = math.min(HORDE.current_break_time, 10)
        if not HORDE.start_timer_immediately then
            HORDE.start_timer_immediately = true
            timer.Adjust("Horde_Main", 0, nil, nil)
        end
    elseif ready_count >= HORDE:Round2(total_player * GetConVar("horde_ready_countdown_ratio"):GetFloat()) then
        HORDE.start_game = true
        HORDE.current_break_time = math.min(HORDE.current_break_time, HORDE.total_break_time)
        if not HORDE.start_timer_immediately then
            HORDE.start_timer_immediately = true
            timer.Adjust("Horde_Main", 0, nil, nil)
        end
    end

    net.Start("Horde_PlayerReadySync")
    local _ready_sync = {}
    for _ply, _status in pairs(HORDE.player_ready) do
        if IsValid(_ply) then _ready_sync[_ply:SteamID()] = _status end
    end
    net.WriteTable(_ready_sync)
    net.Broadcast()

    if HORDE.start_game and HORDE.current_wave > 0 then return end
    HORDE:BroadcastPlayersReadyMessage(tostring(ready_count) .. "/" .. tostring(total_player))
end

function HORDE:SkipTraderTime(ply)
    if HORDE.current_wave <= 0 then return end
    if not HORDE:InBreak() then
        HORDE:SendNotification(translate.Get("Game_F4_CannotSkip"), 1, ply)
        return
    end
    if HORDE.current_break_time <= 10 and not HORDE.hundred_hold_break then
        HORDE:SendNotification(translate.Get("Game_F4_Starting"), 1, ply)
        return
    end
    if HORDE.player_ready[ply] == 1 then
        HORDE:SendNotification(translate.Get("Game_F4_Readied"), 1, ply)
        return
    end
    if not ply:Alive() then
        HORDE:SendNotification("You can't dab when you are dead!", 1, ply)
        return
    end

    HORDE.player_ready[ply] = 1
    local skip_count = 0
    local total_player = 0
    for _, skip_ply in pairs(player.GetAll()) do
        if HORDE.player_ready[skip_ply] == 1 then
            skip_count = skip_count + 1
        end
        total_player = total_player + 1
    end

    if skip_count >= total_player then
        HORDE.Skip_Wave_Timer = true
        if HORDE.hundred_hold_break then
            timer.Adjust("Horde_Main", 0, nil, nil)
        end
    end

    if HORDE.hundred_hold_break then
        HORDE:BroadcastPlayersReadyMessage(tostring(skip_count) .. "/" .. tostring(total_player))
    end

    net.Start("Horde_PlayerReadySync")
        local _ready_sync = {}
    for _ply, _status in pairs(HORDE.player_ready) do
        if IsValid(_ply) then _ready_sync[_ply:SteamID()] = _status end
    end
    net.WriteTable(_ready_sync)
    net.Broadcast()
end

function HORDE:End(ply)
    if not ply:IsAdmin() then
        HORDE:SendNotificationDenyAccess(ply)
        return
    end
    HORDE.start_game = false
    HORDE.player_ready = {}
    ply:PrintMessage(HUD_PRINTTALK, "Stopping game...")
end

function HORDE:Shop(ply)
    if GetConVar("horde_enable_shop"):GetInt() == 0 then
        HORDE:SendNotification("Shop has been disabled.", 1, ply)
    end

    if HORDE:UnarmedShopBlocked(ply) then return end

    if ply:Alive() then
        local res = hook.Run("Horde_OnPlayerOpenShop", ply)
        if res ~= true then
            if HORDE.has_buy_zone and (not ply:Horde_GetInBuyZone()) then
                return
            end

            if HORDE.current_break_time <= 0 then
                HORDE:SendNotification("You cannot shop after a wave has started.", 1, ply)
                return
            end
        end
    end
    ply:Horde_RecalcWeight()
    net.Start("Horde_ToggleShop")
    net.Send(ply)
    for _, wpn in pairs(ply:GetWeapons()) do
        if wpn.IsHordeMelee then
            wpn:SetNWFloat("HORDE_Durability", wpn.MaximumDurability)
        end
    end
end

function HORDE:ItemConfig(ply)
    if ply:IsSuperAdmin() then
        net.Start("Horde_ToggleItemConfig")
        net.Send(ply)
    else
        HORDE:SendNotificationDenyAccess(ply)
    end
end

function HORDE:EnemyConfig(ply)
    if ply:IsSuperAdmin() then
        HORDE:SyncEnemiesTo(ply)
        HORDE:SyncMutationsTo(ply)
        net.Start("Horde_ToggleEnemyConfig")
        net.Send(ply)
    else
        HORDE:SendNotificationDenyAccess(ply)
    end
end

function HORDE:ClassConfig(ply)
    if ply:IsSuperAdmin() then
        net.Start("Horde_ToggleClassConfig")
        net.Send(ply)
    else
        HORDE:SendNotificationDenyAccess(ply)
    end
end

function HORDE:MapConfig(ply)
    if ply:IsSuperAdmin() then
        HORDE:SyncMapsTo(ply)
        net.Start("Horde_ToggleMapConfig")
        net.Send(ply)
    else
        HORDE:SendNotificationDenyAccess(ply)
    end
end

function HORDE:BuilderConfig(ply)
    if ply:IsSuperAdmin() then
        HORDE:Horde_SyncBuilderConfigTo(ply)
        net.Start("Horde_ToggleBuilderConfig")
        net.Send(ply)
    else
        HORDE:SendNotificationDenyAccess(ply)
    end
end

function HORDE:WardenConfig(ply)
    if ply:IsSuperAdmin() then
        HORDE:Horde_SyncWardenConfigTo(ply)
        net.Start("Horde_ToggleWardenConfig")
        net.Send(ply)
    else
        HORDE:SendNotificationDenyAccess(ply)
    end
end

function HORDE:ConfigMenu(ply)
    if not ply:IsSuperAdmin() then
        net.Start("Horde_TogglePlayerMenu")
        net.Send(ply)
        return
    end

    net.Start("Horde_ToggleConfigMenu")
    net.Send(ply)
end

function HORDE:StatsMenu(ply)
    net.Start("Horde_ToggleStats")
    net.Send(ply)
end

hook.Add("PlayerSay", "Horde_Commands", function(ply, input, public)
    if not ply:IsValid() then return end
    local text = {}

    for str in string.gmatch(string.lower(input), "([^".."%s".."]+)") do
       table.insert(text, str)
    end

    if text[1] == "!help" then
        ply:PrintMessage(HUD_PRINTTALK, "'!ready' - Get ready")
        ply:PrintMessage(HUD_PRINTTALK, "'!shop' - Open shop")
        ply:PrintMessage(HUD_PRINTTALK, "'!hskip' - Skip trader time, or vote to skip the current wave")
        ply:PrintMessage(HUD_PRINTTALK, "'!hsend <m/s> <amount>' - Send money/skulls to the player you look at")
        ply:PrintMessage(HUD_PRINTTALK, "'!drop' - Drop weapon")
        ply:PrintMessage(HUD_PRINTTALK, "'!throwmoney <amount>' - Drop money")
        ply:PrintMessage(HUD_PRINTTALK, "'!rtv' -Initiate a map change vote")
    elseif text[1] == "!start" then
        HORDE:Start(ply)
    elseif text[1] == "!ready" then
        HORDE:Ready(ply)
    elseif text[1] == "!end" then
        HORDE:End(ply)
    elseif text[1] == "!shop" then
        HORDE:Shop(ply)
    elseif text[1] == "!itemconfig" then
        HORDE:ItemConfig(ply)
    elseif text[1] == "!enemyconfig" then
        HORDE:EnemyConfig(ply)
    elseif text[1] == "!classconfig" then
        HORDE:ClassConfig(ply)
    elseif text[1] == "!mapconfig" then
        HORDE:MapConfig(ply)
    elseif text[1] == "!drop" then
        ply:ConCommand("horde_drop_weapon")
    elseif text[1] == "!throwmoney" then
        ply:Horde_DropMoney(text[2])
    elseif text[1] == "!rtv" then
        HORDE.VoteChangeMap(ply)
    elseif text[1] == "!stats" then
        HORDE:StatsMenu(ply)
    end
end)

concommand.Add("horde_start", function (ply, cmd, args)
    HORDE:Start(ply)
end)

concommand.Add("horde_ready", function (ply, cmd, args)
    HORDE:Ready(ply)
end)

concommand.Add("horde_skip_trader", function (ply, cmd, args)
    HORDE:SkipTraderTime(ply)
end)

concommand.Add("horde_end", function (ply, cmd, args)
    HORDE:End(ply)
end)

concommand.Add("horde_shop", function (ply, cmd, args)
    HORDE:Shop(ply)
end)

concommand.Add("horde_item_config", function (ply, cmd, args)
    HORDE:ItemConfig(ply)
end)

concommand.Add("horde_enemy_config", function (ply, cmd, args)
    HORDE:EnemyConfig(ply)
end)

concommand.Add("horde_class_config", function (ply, cmd, args)
    HORDE:ClassConfig(ply)
end)

concommand.Add("horde_map_config", function (ply, cmd, args)
    HORDE:MapConfig(ply)
end)

concommand.Add("horde_builder_config", function (ply, cmd, args)
    HORDE:BuilderConfig(ply)
end)

concommand.Add("horde_warden_config", function (ply, cmd, args)
    HORDE:WardenConfig(ply)
end)

concommand.Add("horde_stats", function (ply, cmd, args)
    HORDE:StatsMenu(ply)
end)

local TEST_ADMIN, TEST_SUPERADMIN = 1, 2

local function TestingAccess(ply, level)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not GetConVar("horde_enable_sandbox"):GetBool() then
        HORDE:SendNotificationSandboxOnly(ply)
        return false
    end
    local allowed
    if level == TEST_SUPERADMIN then
        allowed = ply:IsSuperAdmin()
    else
        allowed = ply:IsAdmin()
    end
    if not allowed then
        HORDE:SendNotificationDenyAccess(ply)
        return false
    end
    return true
end

local TEST_AMOUNT_LIMIT = 1000000000
local function TestingAmount(args)
    local n = tonumber(args and args[1])
    if not n or n ~= n or n == math.huge or n == -math.huge then return nil end
    return math.Clamp(math.floor(n), -TEST_AMOUNT_LIMIT, TEST_AMOUNT_LIMIT)
end

local function TestingApplyFreePerks()
    RunConsoleCommand("horde_perk_start_wave", 0)
    RunConsoleCommand("horde_perk_scaling", 0)
end

local function TestingApplyDisableLevels()
    HORDE.disable_levels_restrictions = 1
    net.Start("Horde_Disable_Levels")
    net.Broadcast()
end

concommand.Add("horde_testing_gorlami", function (ply, cmd, args)
    if not TestingAccess(ply, TEST_SUPERADMIN) then return end
    TestingApplyFreePerks()
    ply:Horde_AddSkullTokens(500)
    ply:Horde_SyncEconomy()
    TestingApplyDisableLevels()
end)

concommand.Add("horde_testing_give_money", function (ply, cmd, args)
    if not TestingAccess(ply, TEST_ADMIN) then return end
    local amount = TestingAmount(args)
    if not amount then
        HORDE:SendNotification("Usage: horde_testing_give_money <amount>", 1, ply)
        return
    end

    if (ply:Horde_GetMoney() + amount) < 0 then
        ply:Horde_AddMoney(-(ply:Horde_GetMoney()))
        ply:Horde_SyncEconomy()
        return
    end

    ply:Horde_AddMoney(amount)
    ply:Horde_SyncEconomy()
end)

concommand.Add("horde_testing_free_perks", function (ply, cmd, args)
    if not TestingAccess(ply, TEST_ADMIN) then return end
    TestingApplyFreePerks()
end)

concommand.Add("horde_give_test", function (ply, cmd, args)
    if not TestingAccess(ply, TEST_ADMIN) then return end
    local cls = args and args[1]
    if not cls or cls == "" then
        HORDE:SendNotification("Usage: horde_give_test <class>", 1, ply)
        return
    end
    if not (HORDE.items and HORDE.items[cls]) then
        HORDE:SendNotification("Unknown item: " .. cls, 1, ply)
        return
    end
    ply:Give(cls)
    HORDE:SendNotification("Given: " .. cls, 0, ply)
end)

concommand.Add("horde_testing_wave_goto", function (ply, cmd, args)
    if not TestingAccess(ply, TEST_ADMIN) then return end

    local target_wave = tonumber(args[1])
    if not target_wave or target_wave ~= target_wave or target_wave < 1 then
        HORDE:SendNotification("Usage: horde_testing_wave_goto <wave number>", 1, ply)
        return
    end
    target_wave = math.floor(math.min(target_wave, HORDE.max_waves))

    HORDE.current_wave = target_wave - 1

    HORDE:WaveEnd()
    hook.Run("HordeWaveEnd", HORDE.current_wave)

    HORDE:SendNotification("Going to wave " .. target_wave .. " after break...", 0, ply)
end)

concommand.Add("horde_testing_disable_level_restrictions", function (ply, cmd, args)
    if not TestingAccess(ply, TEST_SUPERADMIN) then return end
    TestingApplyDisableLevels()
end)

concommand.Add("horde_testing_give_skull_tokens", function (ply, cmd, args)
    if not TestingAccess(ply, TEST_ADMIN) then return end
    local amount = TestingAmount(args)
    if not amount then
        HORDE:SendNotification("Usage: horde_testing_give_skull_tokens <amount>", 1, ply)
        return
    end
    ply:Horde_AddSkullTokens(amount)
    ply:Horde_SyncEconomy()
end)

concommand.Add("horde_testing_give_metal", function (ply, cmd, args)
    if not TestingAccess(ply, TEST_ADMIN) then return end

    local amount = TestingAmount(args)
    if not amount or amount == 0 then
        HORDE:SendNotification("Usage: horde_testing_give_metal <amount>", 1, ply)
        return
    end

    if (ply:Horde_GetMetal() + amount) < 0 then
        ply:Horde_SetMetal(0)
        return
    end

    ply:Horde_AddMetal(amount)
end)

concommand.Add("horde_use_gadget", function (ply, cmd, args)
    HORDE:UseGadget(ply)
end)

concommand.Add("horde_use_perk_skill", function (ply, cmd, args)
    HORDE:UsePerkSkill(ply)
end)

concommand.Add("horde_use_quick_grenade", function (ply, cmd, args)
    HORDE:UseQuickGrenade(ply)
end)

concommand.Add("horde_arccw_secondary_ammo", function (ply, cmd, args)
    if not IsValid(ply) then return end
    local wpn = ply:GetActiveWeapon()
    if not IsValid(wpn) then return end
    if isfunction(wpn.ChangeFiremode) then
        wpn:ChangeFiremode(false)
    elseif isfunction(wpn.SecondaryAttack) then
        wpn:SecondaryAttack()
    end
end)

concommand.Add("horde_testing_spawn_enemy", function (ply, cmd, args)
    if not TestingAccess(ply, TEST_SUPERADMIN) then return end
    local name = args[1]
    local wave = args[2]
    local mutation = args[3]
    local player_count = tonumber(args[4])
    local enemy = name and HORDE.enemies[name .. tostring(wave)]
    if not enemy then
        HORDE:SendNotification("Usage: horde_testing_spawn_enemy <name> <wave> [mutation] [player_count]", 1, ply)
        return
    end
    local npc_info = list.Get("NPC")[enemy.class]
    if not npc_info then
        print("[HORDE] NPC does not exist in the NPC list: " .. tostring(enemy.class))
        return
    end

    local trace = ply:GetEyeTrace()
    if not trace.Hit then return end
    local spawned_enemy = ents.Create(enemy.class)
    if not IsValid(spawned_enemy) then return end
    spawned_enemy:SetPos(trace.HitPos)
    timer.Simple(0, function() spawned_enemy:SetAngles(Angle(0, math.random(0, 360), 0)) end)
    spawned_enemy:Spawn()

    spawned_enemy:Horde_SetName(enemy.name)

    if npc_info["Model"] then
        spawned_enemy:SetModel(npc_info["Model"])
    end

    if npc_info["SpawnFlags"] then
        spawned_enemy:SetKeyValue("spawnflags", bit.bor(npc_info["SpawnFlags"], SF_NPC_FADE_CORPSE))
    end

    if npc_info["KeyValues"] then
        for k, v in pairs(npc_info["KeyValues"]) do
            spawned_enemy:SetKeyValue(k, v)
        end
    end

    spawned_enemy:Fire("StartPatrolling")
    spawned_enemy:Fire("SetReadinessHigh")
    if spawned_enemy:IsNPC() then
        spawned_enemy:SetNPCState(NPC_STATE_COMBAT)
    end

    if enemy.model_scale and enemy.model_scale ~= 1 then
        timer.Simple(0, function()
            if not spawned_enemy:IsValid() then return end
            local scale = spawned_enemy:GetModelScale()
            spawned_enemy:SetModelScale(enemy.model_scale * scale)
        end)
    end

    if enemy.boss_properties and enemy.boss_properties.is_boss == true then
        spawned_enemy:Horde_SetBossProperties(enemy.boss_properties)
    end

    local horde_players_count = player_count or table.Count(player.GetAll())
    if enemy.is_elite and enemy.is_elite == true then
        spawned_enemy:Horde_SetElite()
        local scale
        local add
        if enemy.boss_properties and enemy.boss_properties.is_boss == true then
            scale = horde_players_count
            add = 0.75
        else
            scale = math.min(8, horde_players_count)
            add = 0.60
            if scale > 4 then
                add = 0.55
            end
        end
        spawned_enemy:SetMaxHealth(spawned_enemy:GetMaxHealth() *
            math.max(HORDE.difficulty_elite_health_scale_multiplier[HORDE.difficulty],
                scale * HORDE.difficulty_elite_health_scale_multiplier[HORDE.difficulty] *
                (add + HORDE.difficulty_elite_health_scale_add[HORDE.difficulty])))
    end

    if enemy.health_scale then
        spawned_enemy:SetMaxHealth(spawned_enemy:GetMaxHealth() * enemy.health_scale)
    end

    if HORDE:IsExtendedWave() then
        spawned_enemy:SetMaxHealth(spawned_enemy:GetMaxHealth() * (HORDE.extended_health_multiplier or 1))
    end

    spawned_enemy:SetMaxHealth(spawned_enemy:GetMaxHealth() * HORDE.difficulty_health_multiplier[HORDE.difficulty])

    spawned_enemy:SetHealth(spawned_enemy:GetMaxHealth())

    if enemy.reward_scale then
        spawned_enemy:SetVar("reward_scale", enemy.reward_scale)
    end

    if enemy.damage_scale then
        spawned_enemy:SetVar("damage_scale", enemy.damage_scale)
    end

    if enemy.color then
        spawned_enemy:SetColor(enemy.color)
        spawned_enemy:SetRenderMode(RENDERMODE_TRANSCOLOR)
    end

    if enemy.weapon then
        if enemy.weapon == "" or enemy.weapon == "_gmod_none" then
        elseif enemy.weapon == "_gmod_default" then
            local wpns = npc_info["Weapons"]
            if wpns then
                local wpn = wpns[math.random(#wpns)]
                spawned_enemy:Give(wpn)
            end
        else
            spawned_enemy:Give(enemy.weapon)
        end
    end

    if enemy.skin then
        spawned_enemy:SetSkin(enemy.skin)
    end

    if enemy.model then
        spawned_enemy:SetModel(enemy.model)
    end

    spawned_enemy:SetLagCompensated(true)

    if args[3] then
        timer.Simple(0.1, function() spawned_enemy:Horde_SetMutation(args[3]) end)
    end

    if args[4] then
        timer.Simple(0.1, function() spawned_enemy:Horde_SetMutation(args[4]) end)
    end
end)

hook.Add( "OnDamagedByExplosion", "HordeDisableTinnitus", function()
    return true
end)
