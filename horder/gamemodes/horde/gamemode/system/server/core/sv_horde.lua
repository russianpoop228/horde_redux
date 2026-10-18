util.AddNetworkString("Horde_HighlightEntities")
util.AddNetworkString("Horde_DeathMarkHighlight")
util.AddNetworkString("Horde_HunterMarkHighlight")
util.AddNetworkString("Horde_RemoveDeathMarkHighlight")
util.AddNetworkString("Horde_RemoveHunterMarkHighlight")
util.AddNetworkString("Horde_MarkRemainingEnemies")
util.AddNetworkString("Horde_GameEnd")

local horde_players_count = 0
local horde_spawned_ammoboxes = {}
local horde_ammobox_refresh_timer = HORDE.ammobox_refresh_interval / 2
local horde_in_break = nil
local horde_perk_progress = 1
local horde_current_enemies_list = {}
local horde_force_spawn_enemies = {}

HORDE.horde_boss = nil
HORDE.horde_boss_name = nil
HORDE.finished_objs = 0
HORDE.max_objs = 0
local horde_boss_spawned = false
local horde_boss_reposition = false
local horde_boss_properties = nil
local boss_music_loop = nil

local horde_boss_critical = nil

HORDE.horde_active_holdzones = nil
local horde_has_escapezone = nil

local entmeta = FindMetaTable("Entity")
function entmeta:Horde_SetMostRecentAttacker(attacker)
    self.most_recent_attacker = attacker
end

function entmeta:Horde_GetMostRecentAttacker()
    return self.most_recent_attacker
end

function entmeta:Horde_SetName(name)
    self.horde_name = name
end

function entmeta:Horde_GetName()
    return self.horde_name
end

function entmeta:Horde_SetBossProperties(boss_properties)
    self.horde_boss_properties = boss_properties
end

function entmeta:Horde_GetBossProperties()
    return self.horde_boss_properties
end

function entmeta:Horde_SetElite()
    self.Horde_Elite = true
end

function entmeta:Horde_IsElite()
    return self.Horde_Elite
end

hook.Add("InitPostEntity", "Horde_Init", function()
    HORDE:Horde_InitMapEntities()
end)

util.AddNetworkString("Horde_SyncBuyZones")

local buy_zone_snapshot = {}
local buy_zone_shop_open = nil

local function IsShopOpen()
    if GetConVar("horde_enable_shop"):GetInt() == 0 then return false end
    if (HORDE.current_break_time or 0) <= 0 then return false end
    return HORDE:ShopAllowed()
end

function HORDE:SendBuyZones(target, force)
    local data = {}
    for i, zone in ipairs(ents.FindByClass("trigger_horde_buyzone")) do
        data[i] = zone:GetPos()
    end
    local shop_open = IsShopOpen()

    local changed = shop_open ~= buy_zone_shop_open or #data ~= #buy_zone_snapshot
    if not changed then
        for i, pos in ipairs(data) do
            if buy_zone_snapshot[i] ~= pos then
                changed = true
                break
            end
        end
    end

    if not (force or changed or IsValid(target)) then return end
    buy_zone_snapshot = data
    buy_zone_shop_open = shop_open

    net.Start("Horde_SyncBuyZones")
        net.WriteBool(shop_open)
        net.WriteUInt(#data, 4)
        for _, pos in ipairs(data) do
            net.WriteVector(pos)
        end
    if IsValid(target) then net.Send(target) else net.Broadcast() end
end

hook.Add("InitPostEntity", "Horde_BuyZoneSyncInit", function()
    HORDE:SendBuyZones(nil, true)
    timer.Create("Horde_SyncBuyZones", 1, 0, function()
        if player.GetCount() == 0 then return end
        HORDE:SendBuyZones()
    end)
end)

hook.Add("PlayerInitialSpawn", "Horde_BuyZoneSyncPlayer", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then HORDE:SendBuyZones(ply) end
    end)
end)

hook.Add("PlayerSpawn", "Horde_BuyZoneSyncSpawn", function(ply)
    timer.Simple(0, function()
        if IsValid(ply) then HORDE:SendBuyZones(ply) end
    end)
end)

hook.Add("EntityKeyValue", "Horde_EntityKeyValue", function(ent)
    if HORDE.found_horde_nodes then return end
    if ent:GetClass() == "info_player_teamspawn" then
        local valid = true
        for k, v in pairs(HORDE.ai_nodes) do
            if v["pos"] and v["pos"] == ent:GetPos() then
                valid = false
            end
        end

        if valid then
            local node = {
                pos = ent:GetPos(),
                yaw = 0,
                offset = 0,
                type = 0,
                info = 0,
                zone = 0,
                neighbor = {},
                numneighbors = 0,
                link = {},
                numlinks = 0
            }
            table.insert(HORDE.ai_nodes, node)
        end
    end
end)

function HORDE:OnEnemyKilled(victim, killer, weapon)
    if IsValid(victim) and victim:IsNPC() and not victim:GetVar("horde_killed") then
        victim:SetVar("horde_killed", true)
        if IsValid(killer) and killer:IsPlayer() then
            hook.Run("Horde_OnEnemyKilled", victim, killer, weapon)
        end

        if victim.Horde_Gadget_On_Death then
            local gadget_box = ents.Create("horde_gadgetbox")
            gadget_box.Horde_Gadget = victim.Horde_Gadget_On_Death
            gadget_box:SetPos(victim:GetPos())
            gadget_box:Spawn()
        end
    end
    if HORDE.spawned_enemies[victim:EntIndex()] then
        HORDE.spawned_enemies[victim:EntIndex()] = nil
        if (not HORDE.horde_boss) or (HORDE.horde_boss and (not horde_boss_properties) ) or (HORDE.horde_boss and horde_boss_properties and (not horde_boss_properties.unlimited_enemies_spawn)) then
            HORDE.alive_enemies_this_wave = HORDE.alive_enemies_this_wave - 1
            if (not HORDE.horde_has_active_objective) or (HORDE.killed_enemies_this_wave <= math.min(100, HORDE.total_enemies_this_wave_fixed * 0.5)) then
                HORDE.killed_enemies_this_wave = HORDE.killed_enemies_this_wave + 1
            else
                HORDE.total_enemies_this_wave = HORDE.total_enemies_this_wave + 1
            end
            if HORDE.total_enemies_this_wave <= 0 and HORDE.alive_enemies_this_wave <= 0 then
                timer.Adjust("Horde_Main", 1, nil, nil)
            end
        end
        if not HORDE.horde_has_active_objective then
            if false then
                if HORDE.horde_boss and HORDE.horde_boss:IsValid() and HORDE.horde_boss:Health() > 0 then
                    HORDE:BroadcastEnemiesCountMessage(true, tostring(HORDE.current_wave) .. " / ∞", 0)
                else
                    HORDE:BroadcastEnemiesCountMessage(false, tostring(HORDE.current_wave) .. " / ∞",
                        HORDE.total_enemies_this_wave_fixed - HORDE.killed_enemies_this_wave)
                end
            else
                if HORDE.horde_boss and HORDE.horde_boss:IsValid() and HORDE.horde_boss:Health() > 0 then
                    HORDE:BroadcastEnemiesCountMessage(true,
                        tostring(HORDE.current_wave) .. " / " .. tostring(HORDE.max_waves), 0)
                else
                    HORDE:BroadcastEnemiesCountMessage(false,
                        tostring(HORDE.current_wave) .. " / " .. tostring(HORDE.max_waves),
                        HORDE.total_enemies_this_wave_fixed - HORDE.killed_enemies_this_wave)
                end
            end
        end

        local boss_properties = victim:Horde_GetBossProperties()
        local defer_reward = false
        local reward = 0
        local boss_reward = 0
        if boss_properties and boss_properties.is_boss
            and (not HORDE.wave666_mode) and (not HORDE.purism_mode) then
            local boss_scale = 1
            if victim:GetVar("reward_scale") then
                boss_scale = victim:GetVar("reward_scale")
            end
            boss_reward = HORDE.kill_reward_base * boss_scale
        end
        if (killer:IsValid() and killer:IsPlayer()) or HORDE:IsMinion(killer) then
            local killer_owner = HORDE:GetMinionOwner(killer)
            if killer_owner then killer = killer_owner end
            local scale = 1
            if victim:GetVar("reward_scale") then
                scale = victim:GetVar("reward_scale")
            end
            if victim.Horde_NoReward then scale = 0 end
            if not HORDE:IsKillRewardAllowed(killer, victim) then scale = 0 end
            reward = HORDE.kill_reward_base * scale
            if HORDE.wave666_mode then reward = 0 end
            if HORDE.purism_mode then reward = 0 end
            if HORDE.budget_mode then reward = 0 end
            hook.Run("Horde_OnGivePlayerReward", killer, reward)
            if boss_properties and boss_properties.is_boss then
                defer_reward = true
            end
            if not defer_reward then
                if IsValid(victim.Horde_Assist) and victim.Horde_Assist ~= killer then
                    victim.Horde_Assist:Horde_AddMoney(reward * 0.1)
                    victim.Horde_Assist:Horde_SyncEconomy()
                    killer:Horde_AddMoney(reward * 0.9)
                else
                    killer:Horde_AddMoney(reward)
                end
            end

            if victim:Horde_IsElite() then
                if not HORDE.player_elite_kills[killer:SteamID()] then HORDE.player_elite_kills[killer:SteamID()] = 0 end
                HORDE.player_elite_kills[killer:SteamID()] = HORDE.player_elite_kills[killer:SteamID()] + 1
            end

            killer:AddFrags(1)
            if killer:IsPlayer() and HORDE.Leaderboard_AddKill then
                HORDE:Leaderboard_AddKill(killer)
            end
            killer:Horde_SyncEconomy()
        end

        if boss_properties then
            HORDE.horde_boss = nil
            horde_boss_properties = nil
            if boss_properties.end_wave and boss_properties.end_wave == true then
                if HORDE.horde_has_active_objective and HORDE.ForceCompleteObjectives then
                    HORDE:ForceCompleteObjectives()
                end
                if HORDE.current_wave == HORDE.max_waves and HORDE.has_escape_zones then
                    local zones = HORDE:GetEscapeZones()
                    HORDE.horde_active_escapezones = zones
                    for id, zone in pairs(zones) do
                        zone.Horde_Activated = true
                    end
                    HORDE:StartObjective(HORDE.OBJECTIVE_ESCAPE, { zones = zones })
                    HORDE.horde_has_active_objective = true
                else
                    HORDE:WaveEnd()
                    hook.Run("HordeWaveEnd", HORDE.current_wave)
                end
            end

            local boss_reward_to_give = reward > 0 and reward or boss_reward
            if HORDE.budget_mode then
                if HORDE.GetBudgetBossReward then
                    boss_reward_to_give = HORDE:GetBudgetBossReward()
                end
                if boss_reward_to_give > 0 and HORDE.Budget_AddToBank then
                    HORDE:Budget_AddToBank(boss_reward_to_give)
                    HORDE:SendNotification(string.format(
                        "Boss reward: +$%d to the team budget", boss_reward_to_give), 0)
                end
            else
                for _, ply in pairs(player.GetAll()) do
                    if boss_reward_to_give > 0 then
                        ply:Horde_AddMoney(boss_reward_to_give)
                    end
                    ply:Horde_SyncEconomy()
                end
            end
        end

        victim:Horde_SetMostRecentAttacker(nil)
    end
end

hook.Add("OnNPCKilled", "Horde_EnemyKilled", function(victim, killer, weapon)
    HORDE:OnEnemyKilled(victim, killer, weapon)
end)

if GetConVar("horde_corpse_cleanup"):GetInt() == 1 then
    RunConsoleCommand("g_ragdoll_maxcount", "0")
    hook.Add("OnEntityCreated", "Horde_CorpseRemoval", function(ent)
        if ent:IsRagdoll() then
            timer.Simple(0, function()
                if ent:IsValid() then
                    ent:Horde_SetMostRecentAttacker(nil)
                    ent:Remove()
                end
            end)
        end
    end)
else
    RunConsoleCommand("g_ragdoll_maxcount", "20")
end

hook.Add("PostEntityTakeDamage", "Horde_PostDamage", function(ent, dmg, took)
    if took then
        if ent:IsNPC() then
            if dmg:GetAttacker():IsPlayer() then
                local id = dmg:GetAttacker():SteamID()
                if not HORDE.player_damage[id] then HORDE.player_damage[id] = 0 end
                HORDE.player_damage[id] = HORDE.player_damage[id] + dmg:GetDamage()
                ent:Horde_SetMostRecentAttacker(dmg:GetAttacker())
                if GetConVar("horde_testing_display_damage"):GetInt() == 1 then
                    local dmgtype = HORDE:GetDamageType(dmg)
                    if dmgtype == HORDE.DMG_PURE then
                        HORDE:SendNotification("You dealt " .. dmg:GetDamage() .. " damage to " .. ent:GetClass(), 0,
                            dmg:GetAttacker())
                    else
                        HORDE:SendNotification(
                            "You dealt " ..
                            dmg:GetDamage() .. " " .. HORDE.DMG_TYPE_STRING[dmgtype] .. " damage to " .. ent:GetClass(),
                            0,
                            dmg:GetAttacker())
                    end
                end

                local boss_properties = ent:Horde_GetBossProperties()
                if boss_properties and boss_properties.is_boss and boss_properties.is_boss == true then
                    net.Start("Horde_SyncBossHealth")
                    net.WriteInt(ent:Health(), 32)
                    net.Broadcast()

                    if GetConVar("horde_default_enemy_config"):GetInt() == 1 and HORDE.horde_boss and HORDE.horde_boss:IsValid() and boss_music_loop and not horde_boss_critical and ent.Critical then
                        timer.Remove("Horde_BossMusic")
                        boss_music_loop:Stop()
                        local fierce_music = { "music/hl1_song10.mp3", "music/hl2_song4.mp3",
                            "music/hl2_song25_teleporter.mp3" }
                        local fierce_music_duration = { 103, 65, 43 }
                        local selected_id = math.random(#fierce_music)
                        boss_music_loop = CreateSound(game.GetWorld(), fierce_music[selected_id])
                        boss_music_loop:SetSoundLevel(0)
                        timer.Create("Horde_BossMusic", fierce_music_duration[selected_id], 0, function()
                            boss_music_loop:Stop()
                            boss_music_loop:Play()
                        end)
                        boss_music_loop:Play()
                        horde_boss_critical = true
                    end
                end
            end
            if ent:Health() <= 0 then
                ent:Remove()
                return
            end
        elseif ent:IsPlayer() and dmg:GetAttacker():IsNPC() then
            local id = ent:SteamID()
            if not HORDE.player_damage_taken[id] then HORDE.player_damage_taken[id] = 0 end
            HORDE.player_damage_taken[id] = HORDE.player_damage_taken[id] + dmg:GetDamage()
            if GetConVar("horde_testing_display_damage"):GetInt() == 1 then
                local dmgtype = HORDE:GetDamageType(dmg)
                if dmgtype == HORDE.DMG_PURE then
                    HORDE:SendNotification(
                        "You received " .. dmg:GetDamage() .. " damage from " .. dmg:GetAttacker():GetClass(), 0, ent)
                else
                    HORDE:SendNotification(
                        "You received " ..
                        dmg:GetDamage() ..
                        " " .. HORDE.DMG_TYPE_STRING[dmgtype] .. " damage from " .. dmg:GetAttacker():GetClass(), 0, ent)
                end
            end
        end
    end
end)

hook.Add("ScaleNPCDamage", "Horde_HeadshotCounter", function(npc, hitgroup, dmg)
    if npc:IsValid() and dmg:GetAttacker():IsPlayer() and hitgroup == HITGROUP_HEAD then
        local id = dmg:GetAttacker():SteamID()
        if not HORDE.player_headshots[id] then HORDE.player_headshots[id] = 0 end
        HORDE.player_headshots[id] = HORDE.player_headshots[id] + 1
    end
end)

hook.Add("EntityRemoved", "Horde_EntityRemoved", function(ent)
    if (ent:IsNPC() or ent:IsNextBot()) and ent:Horde_GetMostRecentAttacker() then
        HORDE:OnEnemyKilled(ent, ent:Horde_GetMostRecentAttacker())
    else
        if HORDE.spawned_enemies[ent:EntIndex()] then
            HORDE.spawned_enemies[ent:EntIndex()] = nil
            HORDE.alive_enemies_this_wave = HORDE.alive_enemies_this_wave - 1
            HORDE.total_enemies_this_wave = HORDE.total_enemies_this_wave + 1
            local count = HORDE.spawned_enemies_count[ent:Horde_GetName()]
            if count and count > 0 then
                HORDE.spawned_enemies_count[ent:Horde_GetName()] = count - 1
            end
            if ent.Horde_Forced_Spawn_Flag then
                local name = ent.Horde_Forced_Spawn_Flag
                table.insert(horde_force_spawn_enemies[name], math.random(1, HORDE.total_enemies_this_wave_fixed))
            end
        end
    end
end)

function HORDE:HardResetDirector()
    HORDE.start_game = false
    HORDE.leaderboard_game_recorded = nil
    HORDE.killed_enemies_this_wave = 0
    HORDE.total_enemies_this_wave = 0
    HORDE.alive_enemies_this_wave = 0
    HORDE.current_wave = 0
    HORDE.current_break_time = HORDE.total_break_time
    horde_in_break = nil
    HORDE.hundred_hold_break = nil
    horde_boss_spawned = false
    HORDE.horde_boss = nil
    horde_boss_properties = nil
    horde_boss_reposition = false
    HORDE.horde_boss_name = nil
    if boss_music_loop then
        boss_music_loop:Stop()
        boss_music_loop = nil
    end
    net.Start("Horde_SyncGameInfo")
    net.WriteUInt(HORDE.current_wave, 16)
    net.Broadcast()
end

function HORDE:HardResetEnemies()
    local enemies = HORDE:ScanEnemies()
    if not table.IsEmpty(enemies) then
        for _, enemy in pairs(enemies) do
            enemy:Horde_SetMostRecentAttacker(nil)
            enemy:Remove()
        end
    end
    HORDE.spawned_enemies_count = {}
end

function HORDE:SpawnEnemy(enemy, pos)
    local npc_info = HORDE.NPCS[enemy.class]
    if not npc_info then
        HORDE:SendNotification("NPC " .. enemy.class .. " does not exist.", 1)
    end

    local spawned_enemy = ents.Create(enemy.class)
    spawned_enemy:SetPos(pos)
    spawned_enemy:SetCustomCollisionCheck(true)
    timer.Simple(0, function() spawned_enemy:SetAngles(Angle(0, math.random(0, 360), 0)) end)
    spawned_enemy:Spawn()

    HORDE.spawned_enemies[spawned_enemy:EntIndex()] = true
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
            local scale = spawned_enemy:GetModelScale() * enemy.model_scale
            if not scale or scale == 0 or scale < 0.5 or scale > 10 then
                scale = 1
            end
            if scale ~= spawned_enemy:GetModelScale() then
                spawned_enemy:SetModelScale(scale)
            end
        end)
    end

    if enemy.boss_properties and enemy.boss_properties.is_boss == true then
        spawned_enemy:Horde_SetBossProperties(enemy.boss_properties)
    end

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

    if enemy.material and enemy.material ~= "" then
        spawned_enemy:SetMaterial(enemy.material)
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

    if enemy.gadget_drop then
        local gadget = enemy.gadget_drop.gadget
        local drop_rate = enemy.gadget_drop.drop_rate
        if drop_rate and gadget and drop_rate > 0 and HORDE.items[gadget] then
            local p = math.random()
            if p <= drop_rate then
                spawned_enemy.Horde_Gadget_On_Death = gadget
            end
        end
    end

    spawned_enemy:SetLagCompensated(true)

    if enemy.mutation and enemy.mutation ~= "" then
        timer.Simple(0.1, function() spawned_enemy:Horde_SetMutation(enemy.mutation) end)
    else
        local mut_prob = 0
        if enemy.is_elite and enemy.is_elite == true then
            if enemy.boss_properties and enemy.boss_properties.is_boss == true then
                if HORDE.difficulty >= 2 then
                    mut_prob = 1.0
                else
                    mut_prob = 0
                end
            else
                mut_prob = HORDE.difficulty_elite_mutation_probability[HORDE.difficulty]
            end
        else
            mut_prob = HORDE.difficulty_mutation_probability[HORDE.difficulty]
        end

        if HORDE:IsExtendedWave() and (HORDE._hundred_mutation_bonus or 0) > 0 then
            mut_prob = mut_prob + HORDE._hundred_mutation_bonus
        end

        local mutation_pool = HORDE.current_mutations
        if mut_prob > 0 and istable(mutation_pool) and #mutation_pool > 0 then
            local p = math.random()
            if p <= mut_prob then
                local mut = mutation_pool[math.random(1, #mutation_pool)]
                timer.Simple(0.1, function()
                    if ! IsValid(spawned_enemy) then return end
                    spawned_enemy:Horde_SetMutation(mut)
                end)
            end

            if HORDE.difficulty >= 4 then
                p = math.random()
                if p <= 0.25 then
                    local mut = mutation_pool[math.random(1, #mutation_pool)]
                    timer.Simple(0.2, function() spawned_enemy:Horde_SetMutation(mut) end)
                end
            end
        end
    end

    spawned_enemy.Horde_Debuff_Threshold = math.min(500, math.max(50, spawned_enemy:GetMaxHealth() * 0.2))

    hook.Run("HordeEnemySpawn", spawned_enemy)
    return spawned_enemy
end

function HORDE:ScanEnemies()
    local enemies = {}
    for ent_idx, _ in pairs(HORDE.spawned_enemies) do
        if not IsValid(Entity(ent_idx)) then
            HORDE.spawned_enemies[ent_idx] = nil
        else
            table.insert(enemies, Entity(ent_idx))
        end
    end
    return enemies
end

function HORDE:RemoveDistantEnemies(enemies)
    if HORDE.found_horde_nodes then return end
    for _, enemy in pairs(enemies) do
        local boss_properties = enemy:Horde_GetBossProperties()
        local closest = 99999
        local closest_z = 99999
        local closest_ply = nil
        local enemy_pos = enemy:GetPos()

        for _, ply in pairs(player.GetAll()) do
            if ply:Alive() then
                local dist = enemy_pos:Distance(ply:GetPos())
                local z_dist = math.abs(ply:GetPos().z - enemy_pos.z)

                if dist < closest then
                    closest_ply = ply
                    closest = dist
                end
                if z_dist < closest_z then
                    closest_z = z_dist
                end
            end
        end

        if closest > HORDE.max_spawn_distance or (closest_z > GetConVarNumber("horde_max_spawn_z_distance")) then
            if boss_properties and boss_properties.is_boss and boss_properties.is_boss == true then
                horde_boss_reposition = true
            else
                table.RemoveByValue(enemies, enemy)
                if enemy:IsValid() then
                    enemy:Horde_SetMostRecentAttacker(nil)
                    enemy:Remove()
                end
            end
        else
            if enemy:IsValid() and enemy:IsNPC() then
                enemy:SetLastPosition(closest_ply:GetPos())
                enemy:SetTarget(closest_ply)
            end
        end
    end
end

local function NearestAlivePlayer(pos, only_ply)
    local best, best_dist
    if only_ply then
        if IsValid(only_ply) and only_ply:Alive() then
            return only_ply, pos:Distance(only_ply:GetPos())
        end
        return nil, nil
    end
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            local d = pos:Distance(ply:GetPos())
            if not best_dist or d < best_dist then best, best_dist = ply, d end
        end
    end
    return best, best_dist
end

function HORDE:FindFreeSpawnPos(ent, opts)
    opts = opts or {}
    local min_dist = opts.min_dist or HORDE.min_spawn_distance
    local max_dist = opts.max_dist or HORDE.max_spawn_distance
    local max_z = opts.max_z or GetConVarNumber("horde_max_spawn_z_distance")
    local tries = opts.tries or 24
    local require_free_space = opts.require_free_space ~= false

    local candidates = {}
    for _, node in ipairs(HORDE.ai_nodes or {}) do
        local pos = node["pos"]
        if pos then
            local ply, dist = NearestAlivePlayer(pos, opts.player)
            if ply and dist and dist >= min_dist and dist <= max_dist
                and math.abs(pos.z - ply:GetPos().z) <= max_z then
                if (not opts.closer_than_pos) or dist <= opts.closer_than_pos:Distance(ply:GetPos()) - 64 then
                    table.insert(candidates, pos)
                end
            end
        end
    end
    if #candidates == 0 then return nil end

    for i = #candidates, 2, -1 do
        local j = math.random(i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end

    local mins = ent and ent:OBBMins() or Vector(-16, -16, 0)
    local maxs = ent and ent:OBBMaxs() or Vector(16, 16, 72)

    for i = 1, math.min(tries, #candidates) do
        local pos = candidates[i]
        local free = true
        if require_free_space then
            if not util.IsInWorld(pos) then
                free = false
            else
                local tr = util.TraceHull({
                    start = pos + Vector(0, 0, 4),
                    endpos = pos + Vector(0, 0, 4),
                    mins = mins,
                    maxs = maxs,
                    filter = ent,
                    mask = MASK_NPCSOLID,
                })
                if tr.Hit or tr.StartSolid then free = false end
            end
        end
        if free and (not opts.ignore_enemies) then
            for _, enemy in ipairs(self:ScanEnemies()) do
                if enemy ~= ent and pos:Distance(enemy:GetPos()) <= self.spawn_radius then
                    free = false
                    break
                end
            end
        end
        if free then return pos end
    end
    return nil
end

function HORDE:GetValidNodes(enemies)
    local valid_nodes = {}
    local invalid_nodes = {}

    local active_nodes = {}
    for _, node in ipairs(HORDE.ai_nodes or {}) do
        if node["pos"] and HORDE:IsNodeActive(node) then
            local weight = HORDE:GetNodeWeight(node)
            for _ = 1, math.max(1, weight) do
                active_nodes[#active_nodes + 1] = node
            end
        end
    end

    if HORDE.spawn_distribution == HORDE.SPAWN_UNIFORM then
        for _, node in ipairs(active_nodes) do
            table.insert(valid_nodes, node["pos"])
        end
        return valid_nodes
    end

    for _, node in ipairs(active_nodes) do
        local valid = false
        local z_dist
        local within_z = false

        for _, ply in pairs(player.GetAll()) do
            if ply:Alive() then
                local dist = node["pos"]:Distance(ply:GetPos())
                z_dist = math.abs(node["pos"].z - ply:GetPos().z)

                if dist <= HORDE.min_spawn_distance then
                    valid = false
                    break
                elseif dist < HORDE.max_spawn_distance then
                    valid = true
                end

                if z_dist < GetConVarNumber("horde_max_spawn_z_distance") then
                    within_z = true
                end
            end
        end

        if within_z == false then
            valid = false
        end

        if not valid then
            table.insert(invalid_nodes, node["pos"])
            goto cont
        end

        for _, enemy in pairs(enemies) do
            local dist = node["pos"]:Distance(enemy:GetPos())
            if dist <= HORDE.spawn_radius then
                valid = false
                break
            end
        end

        if valid then
            table.insert(valid_nodes, node["pos"])
        else
            table.insert(invalid_nodes, node["pos"])
        end

        ::cont::
    end

    if HORDE.found_horde_nodes and #invalid_nodes > 0
        and (HORDE.spawn_distribution == HORDE.SPAWN_PROXIMITY_NOISY or #valid_nodes <= 0) then
        table.insert(valid_nodes, invalid_nodes[math.random(#invalid_nodes)])
    end

    if #valid_nodes <= 0 and #invalid_nodes > 0 then
        local sorted = {}
        for _, pos in ipairs(invalid_nodes) do table.insert(sorted, pos) end
        table.sort(sorted, function(a, b)
            local _, da = NearestAlivePlayer(a)
            local _, db = NearestAlivePlayer(b)
            return (da or 0) > (db or 0)
        end)
        local forced = math.min(#sorted, HORDE.forced_spawn_nodes or 3)
        for i = 1, forced do
            table.insert(valid_nodes, sorted[i])
        end
    end
    return valid_nodes
end

function HORDE:GetEnemiesPerSpawn()
    local arr = HORDE.difficulty_additional_enemies_per_spawn
    local extra = (arr and arr[HORDE.difficulty]) or 0

    local diff = HORDE._difficulties and HORDE._difficulties[HORDE.difficulty]
    if istable(diff) then
        local step = tonumber(diff.EnemiesPerSpawnWaveStep) or 0
        if step > 0 then
            local amount = tonumber(diff.EnemiesPerSpawnWaveAmount) or 1
            local cap = tonumber(diff.EnemiesPerSpawnWaveCap) or 0
            local bonus = math.floor((HORDE.current_wave or 0) / step) * amount
            if cap > 0 then bonus = math.min(cap, bonus) end
            extra = extra + bonus
        end
    end

    return math.max(1, 1 + extra)
end

function HORDE:SpawnEnemies(enemies, valid_nodes)
    local add_pack = HORDE.difficulty_additional_pack[HORDE.difficulty] or 0
    local min_base = HORDE.min_base_enemy_spawns_per_think or 4
    local max_base = HORDE.max_base_enemy_spawns_per_think or 5
    local lo = min_base + add_pack + math.floor(horde_players_count / 2)
    local hi = max_base + add_pack + horde_players_count
    if hi < lo then hi = lo end

    local enemies_per_spawn = HORDE:GetEnemiesPerSpawn()

    for i = 0, math.random(lo, hi) do
        if (#enemies + 1 > HORDE.max_enemies_alive) or (HORDE.total_enemies_this_wave <= 0) then break end

        local pos = table.Random(valid_nodes)
        if pos == nil then break end
        table.RemoveByValue(valid_nodes, pos)
        local z = pos.z
        pos = pos + VectorRand() * 5
        pos.z = z

        local enemy_wave = HORDE.enemy_wave_index or HORDE:ResolveEnemyWaveIndex()

        if table.IsEmpty(horde_current_enemies_list) then
            if HORDE._empty_enemy_list_wave ~= HORDE.current_wave then
                HORDE._empty_enemy_list_wave = HORDE.current_wave
                HORDE:SendNotification("Current enemy list is empty!", 1)
            end
            HORDE.total_enemies_this_wave = 0
            return
        end

        for _batch = 1, enemies_per_spawn do
            if (#enemies + 1 > HORDE.max_enemies_alive) or (HORDE.total_enemies_this_wave <= 0) then break end

            local p = math.random()
            local p_cum = 0
            local spawned_enemy
            local renormalize = nil
            local spawn_pos = pos + Vector(math.Rand(-14, 14), math.Rand(-14, 14), HORDE.enemy_spawn_z)

            for name, orders in pairs(horde_force_spawn_enemies) do
                for idx, order in pairs(orders) do
                    if HORDE.total_enemies_this_wave < order then
                        horde_force_spawn_enemies[name][idx] = nil
                        local enemy = HORDE.enemies[name .. tostring(enemy_wave)]
                        if not enemy then goto cont3 end
                        if enemy.spawn_limit and enemy.spawn_limit > 0 then
                            local count = HORDE.spawned_enemies_count[name]
                            if count and count >= enemy.spawn_limit then
                                renormalize = true
                                horde_current_enemies_list[name] = nil
                                goto cont3
                            else
                                spawned_enemy = HORDE:SpawnEnemy(enemy, spawn_pos)
                                table.insert(enemies, spawned_enemy)
                                spawned_enemy.Horde_Forced_Spawn_Flag = name
                                if count then
                                    HORDE.spawned_enemies_count[name] = count + 1
                                else
                                    HORDE.spawned_enemies_count[name] = 1
                                end
                                goto cont2
                            end
                        else
                            spawned_enemy = HORDE:SpawnEnemy(enemy, spawn_pos)
                            table.insert(enemies, spawned_enemy)
                            spawned_enemy.Horde_Forced_Spawn_Flag = name
                            goto cont2
                        end
                    end
                end
                ::cont3::
            end

            for name, weight in pairs(horde_current_enemies_list) do
                p_cum = p_cum + weight
                if p <= p_cum then
                    local enemy = HORDE.enemies[name .. tostring(enemy_wave)]
                    if not enemy then break end
                    if enemy.spawn_limit and enemy.spawn_limit > 0 then
                        local count = HORDE.spawned_enemies_count[name]
                        if count and count >= enemy.spawn_limit then
                            renormalize = true
                            horde_current_enemies_list[name] = nil
                            goto cont
                        else
                            spawned_enemy = HORDE:SpawnEnemy(enemy, spawn_pos)
                            table.insert(enemies, spawned_enemy)
                            if count then
                                HORDE.spawned_enemies_count[name] = count + 1
                            else
                                HORDE.spawned_enemies_count[name] = 1
                            end
                        end
                    else
                        spawned_enemy = HORDE:SpawnEnemy(enemy, spawn_pos)
                        table.insert(enemies, spawned_enemy)
                    end

                    break
                end
                ::cont::
            end

            ::cont2::

            if renormalize then
                HORDE:NormalizeEnemiesWeightOnWave(horde_current_enemies_list)
            end

            HORDE.total_enemies_this_wave = HORDE.total_enemies_this_wave - 1
            if IsValid(spawned_enemy) then
                HORDE.alive_enemies_this_wave = HORDE.alive_enemies_this_wave + 1
            end
        end
    end
end

function HORDE:SpawnBoss(enemies, valid_nodes)
    if (HORDE.horde_boss_name) and (#enemies + 1 <= HORDE.max_enemies_alive) and (not HORDE.horde_boss) and (HORDE.total_enemies_this_wave > 0) then
        local enemy_wave = HORDE.enemy_wave_index or HORDE:ResolveEnemyWaveIndex()
        local spawned_enemy

        local enemy = HORDE.bosses[HORDE.horde_boss_name .. tostring(enemy_wave)]
        if not enemy then
            if HORDE.wave666_mode then
                enemy = HORDE.bosses[HORDE.horde_boss_name .. "10"]
            else
                local best_wave
                for _, b in pairs(HORDE.bosses) do
                    if istable(b) and b.name == HORDE.horde_boss_name and b.wave
                        and (not best_wave or b.wave < best_wave) then
                        best_wave = b.wave
                        enemy = b
                    end
                end
            end
        end
        if not enemy then return end

        local candidates
        if HORDE.Horde_GetBossSpawnPositions then
            local boss_positions = HORDE:Horde_GetBossSpawnPositions(HORDE.horde_boss_name)
            if #boss_positions > 0 then candidates = boss_positions end
        end
        if not candidates then candidates = valid_nodes end
        if not candidates or #candidates == 0 then return end

        enemy.is_elite = true

        local pos
        for _ = 1, math.min(#candidates, 6) do
            pos = table.Random(candidates)
            if pos then
                spawned_enemy = HORDE:SpawnEnemy(enemy, pos + Vector(0, 0, HORDE.enemy_spawn_z))
                if IsValid(spawned_enemy) then break end
            end
        end
        if not IsValid(spawned_enemy) then return end
        spawned_enemy:SetVar("is_boss", true)
        HORDE.horde_boss = spawned_enemy
        horde_boss_reposition = false
        table.insert(enemies, spawned_enemy)

        net.Start("Horde_SyncBossSpawned")
        net.WriteString((IsValid(spawned_enemy) and spawned_enemy:Horde_GetName()) or enemy.name or "")
        net.WriteInt(spawned_enemy:GetMaxHealth(), 32)
        net.WriteInt(spawned_enemy:Health(), 32)
        if enemy.boss_properties.music then
            boss_music_loop = CreateSound(game.GetWorld(), enemy.boss_properties.music)
            boss_music_loop:SetSoundLevel(0)
            if enemy.boss_properties.music_duration and enemy.boss_properties.music_duration > 0 then
                timer.Create("Horde_BossMusic", enemy.boss_properties.music_duration, 0, function()
                    boss_music_loop:Stop()
                    boss_music_loop:Play()
                end)
            end
            boss_music_loop:Play()
        end
        net.Broadcast()

        net.Start("Horde_HighlightEntities")
        net.WriteUInt(HORDE.render_highlight_enemies, 3)
        net.Broadcast()

        timer.Simple(5, function()
            net.Start("Horde_HighlightEntities")
            net.WriteUInt(HORDE.render_highlight_disable, 3)
            net.Broadcast()
        end)

        HORDE.total_enemies_this_wave = HORDE.total_enemies_this_wave - 1
        HORDE.alive_enemies_this_wave = HORDE.alive_enemies_this_wave + 1
    end
end

function HORDE:SetActiveBossProperties(props)
    horde_boss_properties = props
end

function HORDE:AllowNextBossSpawn()
    horde_boss_spawned = false
end

function HORDE:RepositionBoss(valid_nodes)
    if (not HORDE.horde_boss) or (not horde_boss_spawned) then return false end
    local boss = HORDE.horde_boss
    if not IsValid(boss) then return false end

    local pos = HORDE:FindFreeSpawnPos(boss, { ignore_enemies = true })
    if not pos and valid_nodes and #valid_nodes > 0 then
        pos = table.Random(valid_nodes)
    end
    if not pos then return false end

    boss:SetPos(pos)
    boss:SetVelocity(Vector(0, 0, 0))
    if boss.EmitSound then
        boss:EmitSound("ambient/machines/teleport4.wav", 90, 100)
    end

    local closest_ply, closest_dist
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            local d = pos:Distance(ply:GetPos())
            if not closest_dist or d < closest_dist then
                closest_ply, closest_dist = ply, d
            end
        end
    end
    if closest_ply then
        if boss.SetLastPosition then boss:SetLastPosition(closest_ply:GetPos()) end
        if boss.SetTarget then boss:SetTarget(closest_ply) end
    end
    if boss.SetSchedule then
        boss:SetSchedule(SCHED_IDLE_WANDER)
    end
    boss.Horde_Stunned = nil
    return true
end

function HORDE:CheckBossStuck()
    if (not HORDE.horde_boss) or (not horde_boss_spawned) then return end
    local pos = HORDE.horde_boss:GetPos()
    local tr = util.TraceHull({
        start = pos,
        endpos = pos,
        filter = HORDE.horde_boss,
        mins = HORDE.horde_boss:OBBMins(),
        maxs = HORDE.horde_boss:OBBMaxs(),
    })
    if tr.Hit then
        local ent = tr.Entity
        if ent:IsValid() and ent:IsWorld() then
            horde_boss_reposition = true
            print("[HORDE] Boss is stuck. Attempting to reposition...")
        end
    end
end

function HORDE:SpawnAmmoboxes(valid_nodes)
    for _, box in pairs(horde_spawned_ammoboxes) do
        if box:IsValid() then box:Remove() end
    end
    horde_spawned_ammoboxes = {}

    for i = 0, math.min(table.Count(player.GetAll()), HORDE.ammobox_max_count_limit) + HORDE.difficulty_additional_ammoboxes[HORDE.difficulty] do
        local pos = table.Random(valid_nodes)
        local spawned_ammobox = ents.Create("horde_ammobox")
        spawned_ammobox:SetPos(pos)
        spawned_ammobox:Spawn()
        table.insert(horde_spawned_ammoboxes, spawned_ammobox)
    end

    if table.Count(horde_spawned_ammoboxes) > 0 then
        net.Start("Horde_HighlightEntities")
        net.WriteUInt(HORDE.render_highlight_ammoboxes, 3)
        net.Broadcast()
    end

    horde_ammobox_refresh_timer = HORDE.ammobox_refresh_interval
end

local director_interval = 9
if GetConVarNumber("horde_director_interval") then
    director_interval = math.max(1, GetConVarNumber("horde_director_interval"))
end

local SPAWN_INTERVAL_MIN = 0.1

function HORDE:GetSpawnIntervalBase()
    local arr = HORDE.difficulty_spawn_interval
    local v = arr and tonumber(arr[HORDE.difficulty])
    local configured = (v ~= nil and v > 0)
    if not configured then v = director_interval end

    local diff = HORDE._difficulties and HORDE._difficulties[HORDE.difficulty]
    if istable(diff) then
        local step = tonumber(diff.SpawnIntervalWaveStep) or 0
        if step > 0 then
            configured = true
            local amount = tonumber(diff.SpawnIntervalWaveAmount) or 0
            v = v - math.floor((HORDE.current_wave or 0) / step) * amount
            local cap = tonumber(diff.SpawnIntervalWaveCap)
            if cap ~= nil and v < cap then v = cap end
        end
    end

    if v < SPAWN_INTERVAL_MIN then v = SPAWN_INTERVAL_MIN end
    return v, configured
end

function HORDE:GetDirectorInterval()
    local base, configured = HORDE:GetSpawnIntervalBase()
    local arr = HORDE.difficulty_spawn_speed_mult
    local speed = (arr and arr[HORDE.difficulty]) or 1
    speed = tonumber(speed) or 1
    if speed <= 0 then speed = 1 end
    local min_interval = configured and SPAWN_INTERVAL_MIN or 1
    return math.max(min_interval, base / speed)
end

HORDE.EnemyCycleSkipsBossWaves = false

function HORDE:ResolveEnemyWaveIndex()
    local w = HORDE.current_wave
    if HORDE.wave666_mode then
        return HORDE.WAVE666_ENEMY_WAVE
    end
    if HORDE:IsExtendedWave() then
        local base = HORDE.max_max_waves
        if w % 5 == 0 then
            local slots = HORDE.boss_slots
            if slots and #slots > 0 then
                return slots[math.random(#slots)]
            end
            return (math.random(2) == 1) and 5 or 10
        end
        local pool = HORDE.enemy_pool_slots
        if pool and #pool > 0 then
            local step = w - base - 1
            if HORDE.EnemyCycleSkipsBossWaves then
                step = (w - base) - (math.floor(w / 5) - math.floor(base / 5)) - 1
            end
            return pool[(step % #pool) + 1]
        end
        return ((w - 11) % 4) + 6
    end
    return ((w - 1) % HORDE.max_max_waves) + 1
end

local function CountReadyPlayers()
    local ready, total = 0, 0
    for _, ply in pairs(player.GetAll()) do
        if HORDE.player_ready[ply] == 1 then ready = ready + 1 end
        total = total + 1
    end
    return ready, total
end

function HORDE:StartBreak()
    if horde_in_break then return end
    horde_in_break = true
    timer.Adjust("Horde_Main", director_interval, nil, nil)
    net.Start("Horde_SyncGameInfo")
    net.WriteUInt(HORDE.current_wave, 16)
    net.Broadcast()

    if HORDE.hundred_hold_break then
        local ready, total = CountReadyPlayers()
        HORDE:BroadcastBreakCountDownMessage(math.max(HORDE.current_break_time, 11), false, true)
        HORDE:BroadcastPlayersReadyMessage(tostring(ready) .. "/" .. tostring(total))
        return
    end

    timer.Create("Horder_Counter", 1, 0, function()
        if not HORDE.start_game then return end
        HORDE:BroadcastBreakCountDownMessage(HORDE.current_break_time, false)

        if HORDE.Skip_Wave_Timer then
            HORDE.current_break_time = 0
        end

        if 0 < HORDE.current_break_time then
            HORDE.current_break_time = HORDE.current_break_time - 1
        elseif HORDE.current_break_time == 0 then
            timer.Adjust("Horde_Main", 1, nil, nil)
            HORDE.current_wave = HORDE.current_wave + 1
            net.Start("Horde_SyncGameInfo")
            net.WriteUInt(HORDE.current_wave, 16)
            net.Broadcast()
            HORDE:BroadcastBreakCountDownMessage(0, false)
            horde_in_break = nil
            timer.Remove("Horder_Counter")
        end
    end)
end

function HORDE:InBreak()
    return horde_in_break
end

function HORDE:WaveStart()
    HORDE:ApplyPendingConfigs()

    timer.Adjust("Horde_Main", HORDE:GetDirectorInterval(), nil, nil)
    HORDE.Skip_Wave_Timer = nil
    HORDE.hundred_hold_break = nil

    if (HORDE.enemies_normalized == nil) or table.IsEmpty(HORDE.enemies_normalized) then
        HORDE:HardResetDirector()
        HORDE:SendNotification("Enemies list is empty. Config the enemy list or no enemies wil spawn.", 1)
        HORDE.start_game = false
        return
    end

    if HORDE.enemies_normalized[HORDE.current_wave] and table.IsEmpty(HORDE.enemies_normalized[HORDE.current_wave]) then
        HORDE:SendNotification("No enemy config set for this wave. Falling back to previous wave settings.", 1)
    end

    HORDE.enemy_wave_index = HORDE:ResolveEnemyWaveIndex()
    local current_wave = HORDE.enemy_wave_index
    horde_players_count = table.Count(player.GetAll())
    local _enemy_src = HORDE.enemies_normalized[current_wave]
    if not _enemy_src or table.IsEmpty(_enemy_src) then
        local found
        for slot = current_wave - 1, 1, -1 do
            local src = HORDE.enemies_normalized[slot]
            if src and not table.IsEmpty(src) then found = src; break end
        end
        _enemy_src = found or HORDE.enemies_normalized[9] or HORDE.enemies_normalized[HORDE.max_max_waves] or {}
    end
    horde_current_enemies_list = table.Copy(_enemy_src)
    local player_scale = math.max(1, horde_players_count)

    if HORDE.wave666_mode then
        HORDE._hundred_mutation_bonus = 0
        local w666_players = math.max(1, horde_players_count)
        local w666_quota = HORDE.Wave666_KillQuota and HORDE:Wave666_KillQuota(w666_players)
        if not w666_quota then
            w666_quota = (HORDE.wave666_kills_base or 1024) + (HORDE.wave666_kills_per_player or 256) * (w666_players - 1)
        end
        HORDE.wave666_kill_quota = w666_quota
        HORDE.total_enemies_this_wave = HORDE.wave666_kill_quota
    elseif HORDE:IsExtendedWave() then
        local over = HORDE.current_wave - HORDE.max_max_waves
        HORDE.total_enemies_this_wave = (HORDE.total_enemies_per_wave[HORDE.max_max_waves] + 5 * over) * player_scale
        local scale_per_wave = HORDE.hundred_scale_per_wave or 0.025
        local hp_dmg_scale = math.min(1 + scale_per_wave * over, 1.5)
        HORDE.extended_health_multiplier = hp_dmg_scale
        HORDE.extended_damage_multiplier = hp_dmg_scale

        local mutation_bonus = math.min(math.floor(over / 5) * 0.25, 2.5)
        HORDE._hundred_mutation_bonus = mutation_bonus
    else
        HORDE._hundred_mutation_bonus = 0
        HORDE.total_enemies_this_wave = HORDE.total_enemies_per_wave[HORDE.current_wave] * player_scale
    end

    HORDE.current_mutations = {}
    for _, mutation in pairs(HORDE.mutations_rand) do
        if mutation == "shadow" then goto cont end
        if mutation.Wave and HORDE.current_wave >= mutation.Wave then
            table.insert(HORDE.current_mutations, mutation.ClassName)
        elseif not mutation.Wave then
            table.insert(HORDE.current_mutations, mutation.ClassName)
        end
        ::cont::
    end

    if (not HORDE.wave666_mode) and GetConVar("horde_total_enemies_scaling"):GetInt() > 1 then
        HORDE.total_enemies_this_wave = HORDE.total_enemies_this_wave * GetConVar("horde_total_enemies_scaling"):GetInt()
    end

    HORDE.total_enemies_this_wave_fixed = HORDE.total_enemies_this_wave
    local max_enemies_alive_base = GetConVarNumber("horde_max_enemies_alive_base")
    local scale = GetConVarNumber("horde_max_enemies_alive_scale_factor")
    local max_enemies_alive_max = GetConVarNumber("horde_max_enemies_alive_max")

    local diff_tbl = HORDE._difficulties and HORDE._difficulties[HORDE.difficulty]
    if istable(diff_tbl) then
        max_enemies_alive_base = tonumber(diff_tbl.MaxEnemiesAliveBase) or max_enemies_alive_base
        scale                   = tonumber(diff_tbl.MaxEnemiesAlivePerPlayer) or scale
        max_enemies_alive_max   = tonumber(diff_tbl.MaxEnemiesAliveCap) or max_enemies_alive_max
    end

    local alive = max_enemies_alive_base + scale * math.max(1, horde_players_count)
    HORDE.max_enemies_alive = math.floor(math.min(max_enemies_alive_max, alive))
    HORDE.alive_enemies_this_wave = 0
    HORDE.current_break_time = -1
    HORDE.killed_enemies_this_wave = 0

    local has_boss = HORDE.bosses_normalized[current_wave] and not table.IsEmpty(HORDE.bosses_normalized[current_wave])
    if has_boss then
        local p = HORDE:Random()
        local p_cum = 0
        local picked
        for name, weight in pairs(HORDE.bosses_normalized[current_wave]) do
            p_cum = p_cum + weight
            if p <= p_cum then
                picked = name
                break
            end
        end
        HORDE.horde_boss_name = picked or next(HORDE.bosses_normalized[current_wave])

        horde_boss_properties = HORDE.bosses[HORDE.horde_boss_name .. current_wave].boss_properties
        if horde_boss_properties.enemies_spawn_threshold <= 0 and horde_boss_properties.end_wave == true then
            HORDE.total_enemies_this_wave = 1
            HORDE.total_enemies_this_wave_fixed = 1
        end
    end

    horde_ammobox_refresh_timer = HORDE.ammobox_refresh_interval
    if false then
        if horde_boss_properties then
            HORDE:BroadcastEnemiesCountMessage(true, tostring(HORDE.current_wave) .. " / ∞", 0)
        else
            HORDE:BroadcastEnemiesCountMessage(false, tostring(HORDE.current_wave) .. " / ∞",
                HORDE.total_enemies_this_wave_fixed - HORDE.killed_enemies_this_wave)
        end
    else
        if horde_boss_properties then
            HORDE:BroadcastEnemiesCountMessage(true, tostring(HORDE.current_wave) .. " / " .. tostring(HORDE.max_waves),
                0)
        else
            HORDE:BroadcastEnemiesCountMessage(false, tostring(HORDE.current_wave) .. " / " .. tostring(HORDE.max_waves),
                HORDE.total_enemies_this_wave_fixed - HORDE.killed_enemies_this_wave)
        end
    end

    local enemy_wave = current_wave
    horde_force_spawn_enemies = HORDE:GetForcedEnemiesOnWave(horde_current_enemies_list, enemy_wave,
        HORDE.total_enemies_this_wave_fixed)

    net.Start("Horde_ForceCloseShop")
    net.Broadcast()

        net.Start("Horde_SyncStatus")
        net.WriteUInt(HORDE.Status_CanBuy, 8)
        net.WriteUInt(0, 8)
        net.Broadcast()

        net.Start("Horde_IsInBuyZone")
            net.WriteBool(false)
        net.Broadcast()

    if not has_boss and not HORDE:IsExtendedWave() and not HORDE.wave666_mode then
        HORDE:StartObjectiveSets(current_wave)
    end

    for _, ent in pairs(ents.FindByClass("logic_horde_waves")) do
        if ent.Wave == HORDE.current_wave or ent.Wave == -1 then
            ent:Input("onwavestart", ent, ent, HORDE.current_wave)
        end
    end
end

function HORDE:WaveEnd()
    timer.Remove("Horde_BossMusic")
    if boss_music_loop then
        boss_music_loop:Stop()
    end

    HORDE.current_break_time = HORDE.total_break_time
    HORDE.hundred_hold_break = HORDE.hundred_mode
        and HORDE.current_wave > 0
        and HORDE.current_wave < HORDE.max_waves
        and (HORDE.current_wave % 10 == 0)
    HORDE.horde_boss = nil
    HORDE.horde_boss_name = nil
    horde_in_break = nil
    horde_boss_spawned = false
    horde_boss_properties = nil
    horde_boss_reposition = false
    horde_boss_critical = false
    HORDE.player_ready = {}

    local enemies = HORDE:ScanEnemies()
    if not table.IsEmpty(enemies) then
        for _, enemy in pairs(enemies) do
            enemy:Horde_SetMostRecentAttacker(nil)
            enemy:Remove()
        end
    end
    HORDE.spawned_enemies_count = {}

    if (HORDE.current_wave >= HORDE.max_waves) and (true) then
        if boss_music_loop then boss_music_loop:Stop() end
        HORDE:GameEnd("VICTORY")

        boss_music_loop = CreateSound(game.GetWorld(), "music/hl2_song23_suitsong3.mp3")
        boss_music_loop:SetSoundLevel(0)
        timer.Create("Horde_BossMusic", 43, 0, function()
            boss_music_loop:Stop()
            boss_music_loop:Play()
        end)
        boss_music_loop:Play()
    else
        HORDE:BroadcastBreakCountDownMessage(0, true)
        HORDE:StartBreak()
        if HORDE.extended_waves and HORDE.current_wave >= HORDE.max_max_waves then
            local waves_left = HORDE.max_waves - HORDE.current_wave
            HORDE:SendNotification("Wave " .. HORDE.current_wave .. "/" .. HORDE.max_waves .. " complete! " .. waves_left .. " to go!", 0)
        else
            HORDE:SendNotification("Wave Completed!", 0)
        end
    end

    net.Start("Horde_HighlightEntities")
    net.WriteUInt(HORDE.render_highlight_disable, 3)
    net.Broadcast()

    for _, ply in pairs(player.GetAll()) do
        if not ply:Alive() then ply:Spawn() end
        HORDE.player_class_changed[ply:SteamID()] = false
        HORDE.player_ready[ply] = 0

        if (HORDE.current_wave < HORDE.max_waves) then
            net.Start("Horde_ShowLeaderboardsTemporarily")
            net.Send(ply)

            local tip = HORDE:GetTip()
            if tip then
                net.Start("Horde_SyncTip")
                    net.WriteString(HORDE:GetTip())
                net.Send(ply)
                local id = ply:SteamID()
                timer.Create("Horde_TipsTimer" .. id, 10, 0, function()
                    if not IsValid(ply) then timer.Remove("Horde_TipsTimer" .. id) return end
                    if not HORDE:InBreak() or HORDE.current_break_time <= 10 then timer.Remove("Horde_TipsTimer" .. id) return end
                    net.Start("Horde_SyncTip")
                        net.WriteString(HORDE:GetTip())
                    net.Send(ply)
                end)
            end
        end
    end

    if GetConVarNumber("horde_npc_cleanup") == 1 then
        local tracked = {}
        for _, drops in pairs(HORDE.player_drop_entities) do
            if istable(drops) then
                for _, e in pairs(drops) do
                    if IsValid(e) then tracked[e] = true end
                end
            end
        end
        local friendly_classes = HORDE.MinionFriendlyClasses or {
            ["npc_vj_horde_houndeye"]          = true,
            ["npc_vj_horde_houndeye_champion"] = true,
            ["npc_vj_horde_spectre"]           = true,
            ["npc_vj_horde_shadow_hulk"]       = true,
            ["npc_vj_horde_blight_spectre"]    = true,
            ["npc_vj_horde_scorcher_spectre"]  = true,
            ["npc_vj_horde_screecher_spectre"] = true,
            ["npc_vj_horde_antlion"]           = true,
            ["npc_vj_horde_overlord_projection"] = true,
        }
        for _, ent in pairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() then
                local is_friendly =
                    HORDE:IsMinion(ent)
                    or ent.Horde_MinionRegistered == true
                    or (IsValid(ent.Horde_Owner) and ent.Horde_Owner:IsPlayer())
                    or tracked[ent]
                    or friendly_classes[ent:GetClass()]
                if not is_friendly then
                    ent:Remove()
                end
            end
        end
    end

    net.Start("Horde_SyncBossHealth")
    net.WriteInt(0, 32)
    net.Broadcast()

    if horde_perk_progress <= 4 and HORDE:Horde_GetWaveForPerk(horde_perk_progress) and HORDE.current_wave >= HORDE:Horde_GetWaveForPerk(horde_perk_progress) then
        timer.Simple(1, function()
            HORDE:SendNotification("Tier " .. horde_perk_progress .. " perks have been unlocked!", 0)
            horde_perk_progress = horde_perk_progress + 1
        end)
    end

    local hundred_skull_reward = 0
    if HORDE.hundred_mode and HORDE.GetHundredWaveSkullReward then
        hundred_skull_reward = HORDE:GetHundredWaveSkullReward(HORDE.current_wave) or 0
    end

    local purism_diff_name = tostring((HORDE.difficulty_text or {})[HORDE.difficulty])
    local purism_reward = HORDE.purism_mode == true
        or (HORDE.IsPurismMode ~= nil and HORDE:IsPurismMode() == true)
        or string.upper(purism_diff_name) == "PURISM"
    if HORDE.purism_mode ~= true and purism_reward then
        print(string.format("[Horde PURISM] HORDE.purism_mode не выставлен — режим определён по имени сложности '%s'", purism_diff_name))
    end

    for _, ply in pairs(player.GetAll()) do
        if HORDE.waveskip_active then
        elseif purism_reward then
            local cash
            if HORDE.GetPurismWaveCash then cash = tonumber(HORDE:GetPurismWaveCash()) end
            if not cash or cash < 1 then cash = math.random(1000, 1500) end
            ply:Horde_AddMoney(cash)
            ply:Horde_SyncEconomy()
            HORDE:SendNotification(string.format("Wave reward: $%d", cash), 0, ply)
        elseif HORDE.budget_mode then
        elseif not HORDE.wave666_mode then
            ply:Horde_AddMoney(HORDE.round_bonus_base)
        end
        local drops = HORDE.player_drop_entities[ply:SteamID()]
        if istable(drops) then
            for _, ent in pairs(drops) do
                if IsValid(ent) and ent:IsNPC() then
                    ent:SetHealth(ent:GetMaxHealth())
                end
            end
        end
        if hundred_skull_reward > 0 and not HORDE.waveskip_active then
            ply:Horde_AddSkullTokens(hundred_skull_reward)
            HORDE:SendNotification(string.format("Wave %d reward: +%d skull tokens", HORDE.current_wave, hundred_skull_reward), 0, ply)
        end
        if not HORDE.waveskip_active and HORDE:RankExpEnabled() then
            local exp_class = ply:Horde_GetCurrentSubclass()
            if exp_class and ply:Horde_GetLevel(exp_class) < HORDE.max_level then
                ply:Horde_AddExp(exp_class, HORDE.Wave_Completion_XP)
                HORDE:SendNotification(string.format("+%d EXP for completing the wave!", HORDE.Wave_Completion_XP), 0, ply)
            end
        end
        ply:Horde_SyncEconomy()
        ply:Horde_SetGivenStarterWeapons(nil)
        ply:Horde_ApplyPerksForClass()
        if GetConVar("horde_enable_rank"):GetInt() == 1 then
            HORDE:SaveRank(ply)
        end

        ply:Horde_SyncExp()
        HORDE:TryAddTopTen(ply)
    end

    net.Start("Horde_PlayerReadySync")
        local _ready_sync = {}
        for _ply, _status in pairs(HORDE.player_ready) do
            if IsValid(_ply) then _ready_sync[_ply:SteamID()] = _status end
        end
        net.WriteTable(_ready_sync)
    net.Broadcast()

    if not HORDE.has_buy_zone then
        local shop_open = HORDE:ShopAllowed()
        net.Start("Horde_SyncStatus")
        net.WriteUInt(HORDE.Status_CanBuy, 8)
        net.WriteUInt(shop_open and 1 or 0, 8)
        net.Broadcast()

        net.Start("Horde_IsInBuyZone")
            net.WriteBool(shop_open)
        net.Broadcast()
    end

    for _, ent in pairs(ents.FindByClass("logic_horde_waves")) do
        if ent.Wave == HORDE.current_wave or ent.Wave == -1 then
            ent:Input("onwaveend", ent, ent, HORDE.current_wave)
        end
    end
end

function HORDE:Direct()
    if table.Count(player.GetAll()) <= 0 then
        HORDE:HardResetDirector()
        HORDE:HardResetEnemies()
        HORDE.player_ready = {}
    end

    if not HORDE.start_game then
        HORDE:HardResetDirector()
        HORDE:HardResetEnemies()

        local ready_count = 0
        local total_player = 0
        for _, ply in pairs(player.GetAll()) do
            if HORDE.player_ready[ply] == 1 then
                ready_count = ready_count + 1
            end
            total_player = total_player + 1
        end

        if total_player > 0 and total_player == ready_count then
            HORDE.start_game = true
        else
            HORDE:BroadcastPlayersReadyMessage(tostring(ready_count) .. "/" .. tostring(total_player))
        end
        return
    end

    if HORDE.hundred_hold_break then
        local ready, total = CountReadyPlayers()
        if (total > 0 and ready >= total) or HORDE.Skip_Wave_Timer then
            HORDE.hundred_hold_break = nil
            HORDE.Skip_Wave_Timer = nil
            horde_in_break = nil
            HORDE.current_wave = HORDE.current_wave + 1
            net.Start("Horde_SyncGameInfo")
            net.WriteUInt(HORDE.current_wave, 16)
            net.Broadcast()
            HORDE:BroadcastBreakCountDownMessage(0, false)
            HORDE.current_break_time = 0
        else
            HORDE:BroadcastBreakCountDownMessage(math.max(HORDE.current_break_time, 11), false, true)
            HORDE:BroadcastPlayersReadyMessage(tostring(ready) .. "/" .. tostring(total))
            return
        end
    end

    if not HORDE.found_ai_nodes then
        ParseFile()
    end

    if not HORDE.ai_nodes or table.IsEmpty(HORDE.ai_nodes) then
        if not HORDE._no_nodes_warned then
            HORDE._no_nodes_warned = true
            print("[HORDE] No info_node(s) in map! NPCs will not spawn.")
            HORDE:SendNotification("Map has no info nodes! NPCs will not spawn.", 1)
        end
        timer.Adjust("Horde_Main", HORDE:GetDirectorInterval(), nil, nil)
        return
    end

    if (not HORDE.found_horde_nodes) and (#HORDE.ai_nodes <= 35) then
        print("Enemies may not spawn well on this map, please try another.")
    end

    if HORDE.current_break_time > 0 and HORDE.current_break_time <= HORDE.total_break_time then
        HORDE:StartBreak()
    end

    if HORDE.current_break_time > 0 then
        return
    end

    if HORDE.current_break_time == 0 then
        HORDE:WaveStart()
        hook.Run("HordeWaveStart", HORDE.current_wave)
    end

    if HORDE.enable_ammobox == 1 then
        horde_ammobox_refresh_timer = horde_ammobox_refresh_timer - HORDE:GetDirectorInterval()
        net.Start("Horde_AmmoboxCountdown")
        net.WriteInt(horde_ammobox_refresh_timer, 8)
        net.Broadcast()
    end

    local enemies = HORDE:ScanEnemies()
    HORDE:RemoveDistantEnemies(enemies)

    if #enemies >= HORDE.max_enemies_alive then
        return
    end

    local valid_nodes = HORDE:GetValidNodes(enemies)

    HORDE:CheckBossStuck()
    if horde_boss_reposition then
        HORDE:RepositionBoss(valid_nodes)
        horde_boss_reposition = false
    end

    if #valid_nodes > 0 then
        local wave = HORDE.enemy_wave_index or (((HORDE.current_wave - 1) % HORDE.max_max_waves) + 1)
        local has_boss = HORDE.bosses_normalized[wave]

        if HORDE.wave666_mode and (not HORDE.horde_boss_name) and (not HORDE.horde_boss)
            and HORDE.killed_enemies_this_wave >= (HORDE.wave666_kill_quota or math.huge) then
            local pool = HORDE.bosses_normalized[10]
            if pool and not table.IsEmpty(pool) then
                local roll, cumulative = HORDE:Random(), 0
                for name, weight in pairs(pool) do
                    cumulative = cumulative + weight
                    if roll <= cumulative then
                        HORDE.horde_boss_name = name
                        break
                    end
                end
                if not HORDE.horde_boss_name then
                    HORDE.horde_boss_name = next(pool)
                end
            end
            if HORDE.horde_boss_name then
                local boss_data = HORDE.bosses[HORDE.horde_boss_name .. "10"]
                horde_boss_properties = boss_data and boss_data.boss_properties or nil
                HORDE.total_enemies_this_wave = math.max(1, HORDE.total_enemies_this_wave) + 1
                HORDE:SendNotification("The elite horde has fallen. A boss has awakened — finish it to clear WAVE 666!", 0)
            end
        end
        if HORDE.wave666_mode then has_boss = HORDE.horde_boss_name ~= nil end

        if has_boss and (not horde_boss_spawned) and (not HORDE.horde_boss) then
            if HORDE.boss_spawns and #HORDE.boss_spawns > 0 then
                HORDE:SpawnBoss(enemies, HORDE.boss_spawns)
            else
                HORDE:SpawnBoss(enemies, valid_nodes)
            end
            hook.Run("HordeBossSpawn", HORDE.horde_boss)
            horde_boss_spawned = true
        end

        if (not horde_boss_properties) then
            HORDE:SpawnEnemies(enemies, valid_nodes)
        else
            if HORDE.horde_boss and (HORDE.horde_boss:Health() <= horde_boss_properties.enemies_spawn_threshold * HORDE.horde_boss:GetMaxHealth()) then
                HORDE:SpawnEnemies(enemies, valid_nodes)
            end
        end

        if horde_ammobox_refresh_timer <= 0 then
            if HORDE.ammobox_nodes and not (table.IsEmpty(HORDE.ammobox_nodes)) then
                HORDE:SpawnAmmoboxes(HORDE.ammobox_nodes)
            else
                HORDE:SpawnAmmoboxes(valid_nodes)
            end
        end
    end

    if (HORDE.total_enemies_this_wave_fixed - HORDE.killed_enemies_this_wave) <= 10 then
        local remaining = {}
        for _, enemy in ipairs(enemies) do
            remaining[enemy] = enemy:GetPos()
        end

        net.Start("Horde_MarkRemainingEnemies")
            net.WriteTable(remaining)
        net.Broadcast()
    end

    if HORDE.total_enemies_this_wave <= 0 and HORDE.alive_enemies_this_wave <= 0 then
        local boss_blocks = IsValid(HORDE.horde_boss)
        local obj_blocks = HORDE.horde_has_active_objective
        if not boss_blocks and not obj_blocks then
            HORDE:WaveEnd()
            hook.Run("HordeWaveEnd", HORDE.current_wave)
        end
    end
end

timer.Create("Horde_Main", HORDE:GetDirectorInterval(), 0, function()
    local status, err = pcall(function() HORDE:Direct() end)

    if not status then
        print(err)
    end
end)
