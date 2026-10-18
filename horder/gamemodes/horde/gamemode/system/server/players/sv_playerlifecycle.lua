util.AddNetworkString("Horde_Votemap")
util.AddNetworkString("Horde_SpectatorGhosts")
util.AddNetworkString("Horde_Votediff")
util.AddNetworkString("Horde_VotemapSync")
util.AddNetworkString("Horde_VotediffSync")
util.AddNetworkString("Horde_RemainingTime")
util.AddNetworkString("Horde_VotemapPlayersSync")
util.AddNetworkString("Horde_ClearStatus")
util.AddNetworkString("Horde_SyncGameInfo")
util.AddNetworkString("Horde_SaveAchievements")
util.AddNetworkString("Horde_SaveExtraAchievements")
util.AddNetworkString("Horde_SyncClientExps")
util.AddNetworkString("Horde_ShowLeaderboardsTemporarily")
util.AddNetworkString("Horde_Summary_MapCacheSync")

local function SyncSummaryMapCache(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not HORDE.GetInstalledMaps then return end

    local maps = HORDE:GetInstalledMaps()
    if not istable(maps) or #maps == 0 then return end

    net.Start("Horde_Summary_MapCacheSync")
        net.WriteTable(maps)
    net.Send(ply)
end

hook.Add("PlayerInitialSpawn", "Horde_Summary_MapCacheSync", function(ply)
    timer.Simple(5, function()
        if IsValid(ply) then SyncSummaryMapCache(ply) end
    end)
end)

HORDE.vote_remaining_time = 60
HORDE.game_end = nil
local plymeta = FindMetaTable("Player")
local map_list = {}
local map_votes = {}
local diff_votes = {}

function plymeta:Horde_SetGivenStarterWeapons(given)
    self.Horde_GivenStarterWeapons = given
end

function plymeta:Horde_GetGivenStarterWeapons()
    return self.Horde_GivenStarterWeapons or nil
end

local function UnarmedStarterAllowed(wpn_class)
    if HORDE.unarmed_kept_weapons and HORDE.unarmed_kept_weapons[wpn_class] then return true end
    return HORDE.relic_weapon_subclass and HORDE.relic_weapon_subclass[wpn_class] ~= nil
end

function HORDE:GiveStarterWeapons(ply)
    if GetConVar("horde_enable_starter"):GetInt() == 0 then return end
    if ply:Alive() and (not ply:Horde_GetGivenStarterWeapons()) then
        local unarmed = HORDE.unarmed_mode
        if HORDE.starter_weapons[ply:Horde_GetCurrentSubclass()] then
            for _, wpn_class in pairs(HORDE.starter_weapons[ply:Horde_GetCurrentSubclass()]) do
                if unarmed and not UnarmedStarterAllowed(wpn_class) then continue end
                ply:Give(wpn_class)
            end
        end

        if HORDE.starter_weapons["All"] then
            for _, wpn_class in pairs(HORDE.starter_weapons["All"]) do
                if unarmed and not UnarmedStarterAllowed(wpn_class) then continue end
                ply:Give(wpn_class)
            end
        end

        ply:GiveAmmo(200, 3)
        ply:Horde_SetGivenStarterWeapons(true)

        if HORDE.wave666_mode and HORDE.Wave666_MaxPlayerUpgrades then
            HORDE:Wave666_MaxPlayerUpgrades(ply)
        end
    end
end

function HORDE:RegiveStarterWeapons(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if HORDE.start_game and (HORDE.current_break_time or 0) <= 0 then return end
    ply:Horde_SetGivenStarterWeapons(nil)
    HORDE:GiveStarterWeapons(ply)
end

function HORDE:GameEnd(status)
    if HORDE.game_end then return end
    timer.Simple(HORDE.vote_remaining_time + 3, function ()
        map_list = HORDE:GetNextMaps()

        if not map_list then
            map_list = {game.GetMapNext()}
        end
        timer.Simple(0, function() RunConsoleCommand("changelevel", map_list[HORDE:Random(#map_list)]) end)
    end)

    if status == "DEFEAT" then
        HORDE:SendNotification("All players are dead!", 1)
    end

    if status == "VICTORY" then
        net.Start("Horde_SaveAchievements")
        net.Broadcast()
    end

    local tokens = math.floor(HORDE.current_wave / 2)
    if status == "VICTORY" then
        tokens = tokens + math.max(0, HORDE.difficulty - 1)
    end
    if status == "VICTORY" and HORDE.victory_skulls ~= nil then
        tokens = HORDE.victory_skulls
    elseif status ~= "VICTORY" and HORDE.defeat_skulls ~= nil then
        tokens = HORDE.defeat_skulls
    end
    if HORDE.wave666_mode and status == "VICTORY" then
        tokens = HORDE.wave666_skulls or 66
    end
    if HORDE.hundred_mode and status == "VICTORY" then
        tokens = 0
    end
    for _, ply in pairs(player.GetHumans()) do
        ply:Horde_AddSkullTokens(tokens)
        if HORDE.wave666_mode and status == "VICTORY" then
            HORDE:Wave666_GrantExp(ply, HORDE.wave666_exp or 7500)
        end
    end

    HORDE.game_end = true
    if not player.GetHumans() or player.GetCount() < 1 then
        map_list = HORDE:GetNextMaps()

        if not map_list then
            map_list = {game.GetMapNext()}
        end
        timer.Simple(0, function() RunConsoleCommand("changelevel", map_list[HORDE:Random(#map_list)]) end)
        return
    end
    local randomplayer = player.GetHumans()[1]

    local mvp_player = randomplayer
    local mvp_damage = 0
    local mvp_kills = 0

    local kills_player = randomplayer
    local most_kills = 0
    local second_kills_player = randomplayer
    local second_most_kills = 0

    local most_heal_player = randomplayer
    local most_heal = 0

    local headshot_player = randomplayer
    local most_headshots = 0

    local damage_player = randomplayer
    local most_damage = 0
    local second_damage_player = randomplayer
    local second_most_damage = 0
    local total_damage = 0

    local damage_taken_player = randomplayer
    local most_damage_taken = 0

    local elite_kill_player = randomplayer
    local most_elite_kills = 0

    for _,ply in pairs(player.GetHumans()) do
        if not ply:IsValid() then goto cont end
        local id = ply:SteamID()
        if (not id) or (id == "") then goto cont end
        if HORDE.player_damage and HORDE.player_damage[id] then
            total_damage = total_damage + HORDE.player_damage[id]
            if HORDE.player_damage[id] > most_damage then
                second_damage_player = damage_player
                second_most_damage = most_damage
                most_damage = HORDE.player_damage[id]
                damage_player = ply
            elseif HORDE.player_damage[id] > second_most_damage then
                second_damage_player = ply
                second_most_damage = HORDE.player_damage[id]
            end
        end

        if ply:Frags() > most_kills then
            second_kills_player = kills_player
            second_most_kills = most_kills
            most_kills = ply:Frags()
            kills_player = ply
        end

        if HORDE.player_heal and HORDE.player_heal[id] and HORDE.player_heal[id] > most_heal then
            most_heal = HORDE.player_heal[id]
            most_heal_player = ply
        end

        if HORDE.player_damage_taken and HORDE.player_damage_taken[id] and HORDE.player_damage_taken[id] > most_damage_taken then
            most_damage_taken = HORDE.player_damage_taken[id]
            damage_taken_player = ply
        end

        if HORDE.player_elite_kills and HORDE.player_elite_kills[id] and HORDE.player_elite_kills[id] > most_elite_kills then
            most_elite_kills = HORDE.player_elite_kills[id]
            elite_kill_player = ply
        end

        if HORDE.player_headshots and HORDE.player_headshots[id] and HORDE.player_headshots[id] > most_headshots then
            most_headshots = HORDE.player_headshots[id]
            headshot_player = ply
        end

        ::cont::
    end

    if kills_player:SteamID() == damage_player:SteamID() then
        mvp_player = kills_player
        mvp_kills = most_kills
        mvp_damage = most_damage
    else
        if kills_player:SteamID() == second_damage_player:SteamID() then
            mvp_player = kills_player
            mvp_kills = most_kills
            mvp_damage = second_most_damage
        elseif damage_player:SteamID() == second_kills_player:SteamID() then
            mvp_player = kills_player
            mvp_kills = second_most_kills
            mvp_damage = most_damage
        else
            local damage_elite_kills = (HORDE.player_elite_kills and HORDE.player_elite_kills[damage_player:SteamID()]) or 0
            local killer_elite_kills = (HORDE.player_elite_kills and HORDE.player_elite_kills[kills_player:SteamID()]) or 0
            if damage_elite_kills > killer_elite_kills then
                mvp_player = damage_player
                mvp_kills = damage_player:Frags()
                mvp_damage = most_damage
            else
                mvp_player = kills_player
                mvp_kills = most_kills
                mvp_damage = HORDE.player_damage[kills_player:SteamID()] or 0
            end
        end
    end

    net.Start("Horde_GameEnd")

    net.WriteString(status)
    net.WriteEntity(mvp_player)
    net.WriteUInt(mvp_damage, 32)
    net.WriteUInt(mvp_kills, 32)

    net.WriteEntity(damage_player)
    net.WriteUInt(most_damage, 32)

    net.WriteEntity(kills_player)
    net.WriteUInt(most_kills, 32)

    net.WriteEntity(most_heal_player)
    net.WriteUInt(most_heal, 32)

    net.WriteEntity(headshot_player)
    net.WriteUInt(most_headshots, 32)

    net.WriteEntity(elite_kill_player)
    net.WriteUInt(most_elite_kills, 32)

    net.WriteEntity(damage_taken_player)
    net.WriteUInt(most_damage_taken, 32)

    net.WriteUInt(total_damage, 32)

    local installed_map_list = HORDE.GetInstalledMaps and HORDE:GetInstalledMaps() or {}

    map_list = HORDE:GetNextMaps()
    if not istable(map_list) or #map_list == 0 then
        map_list = {game.GetMapNext()}
    end

    local current_map = game.GetMap()
    local current_lower = string.lower(current_map)
    local current_name = current_map
    for i = #map_list, 1, -1 do
        if string.lower(map_list[i]) == current_lower then
            current_name = map_list[i]
            table.remove(map_list, i)
        end
    end

    local pool_size = #map_list
    HORDE:Shuffle(map_list)
    while #map_list > 8 do table.remove(map_list) end
    print(string.format("[Horde Vote] map pool %d (installed %d): %s", pool_size,
        #installed_map_list, table.concat(map_list, ", ")))
    table.insert(map_list, math.min(5, #map_list + 1), current_name)

    net.WriteTable(map_list)

    net.Broadcast()

    if istable(installed_map_list) and #installed_map_list > 0 then
        net.Start("Horde_Summary_MapCacheSync")
            net.WriteTable(installed_map_list)
        net.Broadcast()
    end

    net.Start("Horde_SyncEscapeEnd")
    net.Broadcast()

    timer.Remove("Horde_Main")
    timer.Remove("Horder_Counter")
    HORDE:BroadcastGameResultMessage(status, HORDE.current_wave)

    if HORDE.Leaderboard_OnGameEnd then
        HORDE:Leaderboard_OnGameEnd(mvp_player, status)
    end

    for _, ply in pairs(player.GetHumans()) do
        if not ply:IsValid() then goto cont end
        if GetConVar("horde_enable_rank"):GetInt() == 1 then
            HORDE:SaveRank(ply)
        end
        ::cont::
    end

    timer.Create("Horde_MapVoteCountdown", 1, 0, function ()
        if HORDE.vote_remaining_time <= 0 then
            timer.Remove("Horde_MapVoteCountdown")

            local chosen_map = game.GetMapNext()
            local chosen_map_count = 0

            local map_collect = {}
            for _, map in pairs(map_list) do
                map_collect[map] = 0
            end

            for ply, map_voted in pairs(map_votes) do
                for map, count in pairs(map_collect) do
                    if map == map_voted then
                        map_collect[map] = count + 1
                    end
                end
            end

            for map, count in pairs(map_collect) do
                if count > chosen_map_count then
                    chosen_map = map
                    chosen_map_count = count
                end
            end

            local function is_modifier_name(name)
                if not isstring(name) then return false end
                if HORDE.IsModifier then return HORDE:IsModifier(name) end
                for _, def in pairs(HORDE._difficulties or {}) do
                    if istable(def) and def.Name == name and HORDE.GetDifficultyInclude then
                        return HORDE:GetDifficultyInclude(def) ~= nil
                    end
                end
                return false
            end

            local base_collect, mod_collect = {}, { ["__none__"] = 0 }
            for _, entry in ipairs(HORDE:GetDifficultyNameList()) do
                local diff = entry.name
                if is_modifier_name(diff) then
                    mod_collect[diff] = 0
                else
                    base_collect[diff] = 0
                end
            end

            for _, vote in pairs(diff_votes) do
                local base_name, mod_name
                if istable(vote) then
                    base_name, mod_name = vote.base, vote.mod
                elseif isstring(vote) then
                    if is_modifier_name(vote) then
                        mod_name = vote
                        base_name = HORDE.difficulty_text and HORDE.difficulty_text[HORDE.difficulty]
                    else
                        base_name = vote
                    end
                end
                if isstring(base_name) and base_collect[base_name] ~= nil then
                    base_collect[base_name] = base_collect[base_name] + 1
                end
                if isstring(mod_name) and mod_collect[mod_name] ~= nil then
                    mod_collect[mod_name] = mod_collect[mod_name] + 1
                else
                    mod_collect["__none__"] = (mod_collect["__none__"] or 0) + 1
                end
            end

            local function DifficultyIndex(name)
                for idx, diff_def in pairs(HORDE._difficulties or {}) do
                    if istable(diff_def) and diff_def.Name == name then return idx end
                end
                for idx, n in pairs(HORDE.difficulty_text or {}) do
                    if n == name then return idx end
                end
                return math.huge
            end

            local function PickBest(collect)
                local best, best_count = nil, 0
                for name, count in pairs(collect) do
                    if name ~= "__none__" and count > 0 then
                        if not best or count > best_count
                            or (count == best_count and DifficultyIndex(name) < DifficultyIndex(best)) then
                            best, best_count = name, count
                        end
                    end
                end
                return best, best_count
            end

            local chosen_base, chosen_base_count = PickBest(base_collect)
            if not chosen_base then
                chosen_base = HORDE.difficulty_text and HORDE.difficulty_text[HORDE.difficulty]
                chosen_base_count = 0
            end

            if chosen_base and is_modifier_name(chosen_base) then
                local def
                for _, dd in pairs(HORDE._difficulties or {}) do
                    if istable(dd) and dd.Name == chosen_base then def = dd break end
                end
                local resolved = def and HORDE.ResolveDifficultyBase and HORDE:ResolveDifficultyBase(def)
                print(string.format("[Horde Vote] base '%s' is a modifier — using '%s' instead",
                    tostring(chosen_base), tostring(resolved or HORDE.DEFAULT_MODIFIER_BASE)))
                if isstring(resolved) and not is_modifier_name(resolved) then
                    chosen_base = resolved
                else
                    chosen_base = HORDE.DEFAULT_MODIFIER_BASE
                end
            end

            local chosen_mod, chosen_mod_count = PickBest(mod_collect)
            if (mod_collect["__none__"] or 0) > chosen_mod_count then
                chosen_mod = nil
            end

            local chosen_diff = chosen_mod or chosen_base
            print(string.format("[Horde Vote] result: base %s (%d votes), modifier %s",
                tostring(chosen_base), chosen_base_count or 0, tostring(chosen_mod or "none")))

            if chosen_mod and chosen_base then
                if HORDE.SetVotedDifficultyIncludeBase then
                    HORDE:SetVotedDifficultyIncludeBase(chosen_base)
                else
                    RunConsoleCommand("horde_difficulty_include_base", string.upper(chosen_base))
                end
                print(string.format("[Horde Vote] %s + base %s (persisted for next map)",
                    tostring(chosen_mod), tostring(chosen_base)))
            else
                if HORDE.SetVotedDifficultyIncludeBase then
                    HORDE:SetVotedDifficultyIncludeBase(nil)
                else
                    RunConsoleCommand("horde_difficulty_include_base", "")
                end
                print(string.format("[Horde Vote] base only: %s (no modifier)",
                    tostring(chosen_base)))
            end

            local new_diff_index = nil
            for idx, diff_def in pairs(HORDE._difficulties or {}) do
                if istable(diff_def) and diff_def.Name == chosen_diff then
                    new_diff_index = idx - 1
                    break
                end
            end
            if not new_diff_index then
                for _, entry in ipairs(HORDE:GetDifficultyNameList()) do
                    if entry.name == chosen_diff then
                        new_diff_index = entry.index - 1
                        break
                    end
                end
            end
            if new_diff_index then
                GetConVar("horde_difficulty"):SetInt(new_diff_index)
            end

            timer.Simple(0, function() RunConsoleCommand("changelevel", chosen_map) end)
        end
        net.Start("Horde_RemainingTime")
        net.WriteInt(HORDE.vote_remaining_time, 8)
        net.Broadcast()
        HORDE.vote_remaining_time = HORDE.vote_remaining_time - 1
    end)
end

net.Receive("Horde_Votemap", function (len, ply)
    if not IsValid(ply) then return end
    if not HORDE:AllowNetRequest(ply, "vote_map", 0.15) then return end
    local voted_map = net.ReadString()
    local valid_map = false
    for _, map in pairs(map_list) do
        if map == voted_map then valid_map = true break end
    end
    if not valid_map then return end
    map_votes[ply] = voted_map

    local map_collect = {}
    for _, map in pairs(map_list) do
        map_collect[map] = 0
    end

    for _, map_voted in pairs(map_votes) do
        for map, count in pairs(map_collect) do
            if map == map_voted then
                map_collect[map] = count + 1
            end
        end
    end

    local total_players = table.Count(player.GetAll())
    for _, count in pairs(map_collect) do
        if count >= total_players then
            HORDE.vote_remaining_time = math.min(HORDE.vote_remaining_time, 10)
        elseif count >= HORDE:Round2(total_players * 2 / 3) then
            HORDE.vote_remaining_time = math.min(HORDE.vote_remaining_time, 30)
            break
        end
    end

    net.Start("Horde_VotemapSync")
    net.WriteTable(map_collect)
    net.Broadcast()

    local voters = {}
    for voter, voted in pairs(map_votes) do
        if IsValid(voter) then voters[#voters + 1] = { voter, voted } end
    end
    net.Start("Horde_VotemapPlayersSync")
    net.WriteUInt(math.min(#voters, 255), 8)
    for i = 1, math.min(#voters, 255) do
        net.WriteEntity(voters[i][1])
        net.WriteString(voters[i][2])
    end
    net.Broadcast()
end)

function HORDE:PlayerInit(ply)
    if not IsValid(ply) or ply.Horde_Init_Complete or ply.Horde_Init_InProgress then return false end
    HORDE.current_players = player.GetAll()
    local rank_ok, rank_error = HORDE:LoadRank(ply)
    if not rank_ok then
        HORDE:SendNotification("Your saved progress could not be loaded; initialization was stopped to protect it.", 1, ply)
        MsgC(Color(255, 100, 100), "[Horde] Player init aborted for " .. ply:SteamID() .. ": " .. tostring(rank_error) .. "\n")
        return false
    end
    local tokens_ok, tokens_error = HORDE:LoadSkullTokens(ply)
    if not tokens_ok then
        HORDE:SendNotification("Your saved tokens could not be loaded; initialization was stopped to protect them.", 1, ply)
        MsgC(Color(255, 100, 100), "[Horde] Player init aborted for " .. ply:SteamID() .. ": " .. tostring(tokens_error) .. "\n")
        return false
    end
    if not ply.Horde_subclasses_unlocked and not HORDE:LoadSubclassUnlocks(ply) then
        HORDE:SendNotification("Your saved subclass unlocks could not be loaded; initialization was stopped to protect them.", 1, ply)
        return false
    end
    ply.Horde_Init_InProgress = true

    if ply.Horde_Just_Migrated then
        ply.Horde_Just_Migrated = nil
        timer.Simple(3, function()
            if IsValid(ply) then
                HORDE:SendNotification("Your progress was successfully migrated to the new save system!", 0, ply)
            end
        end)
    end

    net.Start("Horde_SyncItems")
    local str = HORDE.GetCachedHordeItems()
    net.WriteUInt(string.len(str), 32)
        net.WriteData(str, string.len(str))
    net.Send(ply)

    net.Start("Horde_SyncClasses")
        net.WriteTable(HORDE.classes)
    net.Send(ply)

    net.Start("Horde_SyncSubclasses")
        net.WriteTable(HORDE.subclass_overrides or {})
    net.Send(ply)

    net.Start("Horde_SyncDifficulty")
        net.WriteUInt(HORDE.difficulty, 16)
        net.WriteString(HORDE.difficulty_base_name or "")
    net.Send(ply)

    net.Start("Horde_SyncDifficultyText")
        net.WriteTable(HORDE.difficulty_text)
    net.Send(ply)

    HORDE:SyncGameplayConfigTo(ply)

    net.Start("Horde_SyncGameInfo")
        net.WriteUInt(HORDE.current_wave, 16)
    net.Send(ply)

    if HORDE.disable_levels_restrictions == 1 then
        net.Start("Horde_Disable_Levels")
        net.Send(ply)
    end
    if not HORDE.start_game or HORDE:InBreak() then
        HORDE.player_ready[ply] = 0
        net.Start("Horde_PlayerReadySync")
            local _ready_sync = {}
    for _ply, _status in pairs(HORDE.player_ready) do
        if IsValid(_ply) then _ready_sync[_ply:SteamID()] = _status end
    end
    net.WriteTable(_ready_sync)
        net.Broadcast()

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
                if HORDE.start_game or HORDE.current_break_time <= 10 then timer.Remove("Horde_TipsTimer" .. id) return end
                net.Start("Horde_SyncTip")
                    net.WriteString(HORDE:GetTip())
                net.Send(ply)
            end)
        end
    end

    local wave666_prep_bonus = (HORDE.Wave666_PrepBonus and HORDE:Wave666_PrepBonus()) or 0
    local wave666_money_restored = false

    if HORDE.start_game then
        net.Start("Horde_RemoveReadyPanel")
        net.Send(ply)
        if HORDE.player_money_wave[ply:SteamID()] and HORDE.player_money[ply:SteamID()] and HORDE.player_money_wave[ply:SteamID()] == HORDE.current_wave then
            ply:Horde_SetMoney(HORDE.player_money[ply:SteamID()])
            wave666_money_restored = true
        else
            ply:Horde_SetMoney(HORDE.start_money + math.max(0, HORDE.current_wave - 1) * 150 + wave666_prep_bonus)
        end
        if HORDE.horde_boss and HORDE.horde_boss:IsValid() and HORDE.horde_boss_name then
            net.Start("Horde_SyncBossSpawned")
                net.WriteString(HORDE.horde_boss_name)
                net.WriteInt(HORDE.horde_boss:GetMaxHealth(),32)
                net.WriteInt(HORDE.horde_boss:Health(),32)
            net.Send(ply)
        end

        if HORDE.horde_active_holdzones then
            for id, zone in pairs(HORDE.horde_active_holdzones) do
                local shape, _, radius = HORDE:GetZoneShapeData(zone)
                net.Start("Horde_SyncHoldLocation")
                net.WriteUInt(zone.Horde_Zone_Id, 4)
                net.WriteVector(zone:GetPos())
                net.WriteAngle(zone:GetAngles())
                net.WriteVector(zone:OBBMins())
                net.WriteVector(zone:OBBMaxs())
                net.WriteUInt(shape, 1)
                net.WriteFloat(radius)
                net.Send(ply)

                net.Start("Horde_SyncHoldProgress")
                net.WriteUInt(zone.Horde_Zone_Id, 4)
                net.WriteUInt(math.Clamp(tonumber(zone.Horde_Hold_Progress) or 0, 0, 255), 8)
                net.Send(ply)
            end

            net.Start("Horde_RenderObjectives")
            net.WriteUInt(HORDE.finished_objs, 4)
            net.WriteUInt(HORDE.max_objs, 4)
            net.Send(ply)
        end

        if HORDE.horde_active_escapezones then
            for id, zone in pairs(HORDE.horde_active_escapezones) do
                net.Start("Horde_SyncEscapeLocation")
                net.WriteUInt(zone.Horde_Zone_Id, 4)
                net.WriteVector(zone:GetPos())
                net.WriteVector(zone:OBBMins())
                net.WriteVector(zone:OBBMaxs())
                net.Send(ply)
            end
            net.Start("Horde_RenderObjectives")
            net.WriteUInt(HORDE.finished_objs, 4)
            net.WriteUInt(HORDE.max_objs, 4)
            net.Send(ply)
        end

        if HORDE.horde_active_payload_spawns then
            for id, spawn in pairs(HORDE.horde_active_payload_spawns) do
                net.Start("Horde_SyncPayloadLocation")
                net.WriteUInt(spawn.Horde_Payload_Spawn_Id, 4)
                net.WriteVector(spawn:GetPos())
                net.Send(ply)

                net.Start("Horde_SyncPayloadIcon")
                net.WriteUInt(spawn.Horde_Payload_Spawn_Id, 4)
                net.WriteUInt(spawn.Horde_Payload_Icon, 4)
                net.Send(ply)
            end
            net.Start("Horde_SyncEscapeStart")
            net.Send(ply)
        end

        if HORDE.horde_active_payload_destinations then
            for id, dest in pairs(HORDE.horde_active_payload_destinations) do
                net.Start("Horde_SyncPayloadDestinationLocation")
                net.WriteUInt(dest.Horde_Payload_Destination_Id, 4)
                net.WriteVector(dest:GetPos())
                net.WriteVector(dest:OBBMins())
                net.WriteVector(dest:OBBMaxs())
                net.Send(ply)
            end
        end
    else
        if HORDE.player_money[ply:SteamID()] then
            ply:Horde_SetMoney(HORDE.player_money[ply:SteamID()])
            wave666_money_restored = true
        else
            ply:Horde_SetMoney(HORDE.start_money + wave666_prep_bonus)
        end
    end
    if HORDE.Wave666_OnPrepInit then HORDE:Wave666_OnPrepInit(ply, wave666_money_restored) end
    if HORDE.Wave666_MaxPlayerUpgrades then HORDE:Wave666_MaxPlayerUpgrades(ply) end
    ply:Horde_SetDropEntities({})
    ply:Horde_SetMaxWeight(HORDE.max_weight)
    if not ply:Horde_GetClass() then
        ply:Horde_SetClass(HORDE.classes[HORDE.Class_Survivor])
    end

    hook.Run("Horde_ResetStatus", ply)
    ply.Horde_Spectre_Max_Count = 1
    ply:Horde_ApplyPerksForClass()
    ply:Horde_SetWeight(ply:Horde_GetMaxWeight())
    HORDE.player_class_changed[ply:SteamID()] = false
    ply:Horde_SyncEconomy()
    if ply:Alive() and not (HORDE.start_game and HORDE.current_break_time <= 0) then
        HORDE:GiveStarterWeapons(ply)
    end

    ply.Horde_Status = {}
    ply:PrintMessage(HUD_PRINTTALK, "Use '!help' to see special commands!")

    ply:Horde_SyncExp()
    for _, other_ply in pairs(player.GetAll()) do
        if other_ply == ply then goto cont end
        local subclass = other_ply:Horde_GetCurrentSubclass()
        if not subclass then goto cont end
        net.Start("Horde_SyncExp")
            net.WriteEntity(other_ply)
            net.WriteTable({ [subclass] = {
                exp = other_ply:Horde_GetExp(subclass),
                level = other_ply:Horde_GetLevel(subclass),
            } })
        net.Send(ply)

        net.Start("Horde_SyncPerk")
            net.WriteEntity(other_ply)
            local other_choices = other_ply.Horde_PerkChoices and other_ply.Horde_PerkChoices[subclass]
            net.WriteTable(other_choices or {})
        net.Send(ply)
        ::cont::
    end
    net.Start("Horde_SyncClientExps")
    net.Send(ply)

    if GetConVar("horde_enable_sandbox"):GetInt() == 1 then
        net.Start("Horde_SyncStatus")
            net.WriteUInt(HORDE.Status_ExpDisabled, 8)
            net.WriteUInt(1, 8)
        net.Send(ply)
    end

    ply.Horde_Init_InProgress = nil
    ply.Horde_Init_Complete = true
    local added = HORDE:TryAddTopTen(ply)
    if not added then
        net.Start("Horde_SyncTopTen")
            net.WriteString(util.TableToJSON(HORDE.top_tens))
        net.Broadcast()
    end

    if not HORDE.has_buy_zone then
        net.Start("Horde_SyncStatus")
        local shop_open = HORDE.current_break_time > 0 and HORDE:ShopAllowed()
        net.WriteUInt(HORDE.Status_CanBuy, 8)
        net.WriteUInt(shop_open and 1 or 0, 8)
        net.Send(ply)

        net.Start("Horde_IsInBuyZone")
            net.WriteBool(shop_open)
        net.Send(ply)
    end

    if HORDE.start_game then return end

    local ready_count = 0
    local total_player = 0
    for _, other_ply in pairs(player.GetAll()) do
        if HORDE.player_ready[other_ply] == 1 then
            ready_count = ready_count + 1
        end
        total_player = total_player + 1
    end

    if total_player > 0 and total_player == ready_count then
        HORDE.start_game = true
    end

    HORDE:BroadcastPlayersReadyMessage(tostring(ready_count) .. "/" .. tostring(total_player))
end

net.Receive("Horde_PlayerInit", function (len, ply)
    if ply.Horde_Init_Complete or not HORDE:AllowNetRequest(ply, "player_init", 5) then return end
    local ok, err = pcall(HORDE.PlayerInit, HORDE, ply)
    if not ok then
        if IsValid(ply) then ply.Horde_Init_InProgress = nil end
        ErrorNoHaltWithStack("[Horde] PlayerInit failed for " .. tostring(ply) .. ": " .. tostring(err) .. "\n")
    end
end)

HORDE.player_money = {}
HORDE.player_money_wave = {}
hook.Add("PlayerDisconnected", "Horde_PlayerDisconnect", function(ply)
    HORDE.current_players = player.GetAll()
    if HORDE.player_vote_map_change[ply] then
        HORDE.player_vote_map_change[ply] = nil
    end

    map_votes[ply] = nil
    diff_votes[ply] = nil

    timer.Remove("Horde_TipsTimer" .. ply:SteamID())

    if ply:IsValid() then
        HORDE.player_money[ply:SteamID()] = ply:Horde_GetMoney()
        HORDE.player_money_wave[ply:SteamID()] = HORDE.current_wave
    end

    if (not HORDE.start_game) and HORDE.player_ready[ply] then
        HORDE.player_ready[ply] = nil
        net.Start("Horde_PlayerReadySync")
        local _ready_sync = {}
    for _ply, _status in pairs(HORDE.player_ready) do
        if IsValid(_ply) then _ready_sync[_ply:SteamID()] = _status end
    end
    net.WriteTable(_ready_sync)
        net.Broadcast()
    end

    if not ply:IsValid() then return end

    if HORDE.player_drop_entities[ply:SteamID()] then
        for _, ent in pairs(HORDE.player_drop_entities[ply:SteamID()]) do
            if ent:IsValid() then
                ent.Horde_Minion_Respawn = nil
                timer.Remove("Horde_ManhackRespawn" .. ent:GetCreationID())
                ent:Remove()
            end
        end
    end

    timer.Simple(0, function() HORDE:CheckAlivePlayers() end)
end)

net.Receive("Horde_Votediff", function (len, ply)
    if not IsValid(ply) then return end
    if not HORDE:AllowNetRequest(ply, "vote_diff", 0.15) then
        print(string.format("[Horde Vote] %s: vote throttled (too fast)", ply:Nick()))
        return
    end

    local voted_base = net.ReadString()
    local voted_mod = nil
    if net.BytesLeft and net.BytesLeft() > 0 then
        local s = net.ReadString()
        if isstring(s) and s ~= "" then voted_mod = s end
    end

    local function valid_name(name)
        if not isstring(name) or name == "" then return false end
        for _, entry in ipairs(HORDE:GetDifficultyNameList()) do
            if entry.name == name then return true end
        end
        return false
    end

    if not valid_name(voted_base) and not voted_mod then
        print(string.format("[Horde Vote] %s: vote rejected, unknown difficulty '%s'",
            ply:Nick(), tostring(voted_base)))
        return
    end
    if voted_base and HORDE.IsDifficultyHidden and HORDE:IsDifficultyHidden(voted_base) then
        print(string.format("[Horde Vote] %s: base '%s' is hidden - vote ignored", ply:Nick(), tostring(voted_base)))
        return
    end
    if voted_mod and HORDE.IsDifficultyHidden and HORDE:IsDifficultyHidden(voted_mod) then
        print(string.format("[Horde Vote] %s: modifier '%s' is hidden - vote ignored", ply:Nick(), tostring(voted_mod)))
        return
    end

    local function is_mod(name)
        if not isstring(name) then return false end
        if HORDE.IsModifier then return HORDE:IsModifier(name) end
        for _, def in pairs(HORDE._difficulties or {}) do
            if istable(def) and def.Name == name and HORDE.GetDifficultyInclude then
                return HORDE:GetDifficultyInclude(def) ~= nil
            end
        end
        return false
    end

    if valid_name(voted_base) and is_mod(voted_base) and not voted_mod then
        voted_mod = voted_base
        voted_base = HORDE.difficulty_text and HORDE.difficulty_text[HORDE.difficulty]
    end

    if voted_base and not valid_name(voted_base) then voted_base = nil end
    if voted_mod and not valid_name(voted_mod) then voted_mod = nil end
    if not voted_base and not voted_mod then return end

    diff_votes[ply] = { base = voted_base, mod = voted_mod }
    print(string.format("[Horde Vote] %s voted: base '%s', modifier '%s'",
        ply:Nick(), tostring(voted_base), tostring(voted_mod or "none")))

    local diff_collect = {}
    for _, entry in ipairs(HORDE:GetDifficultyNameList()) do
        diff_collect[entry.name] = 0
    end
    for _, vote in pairs(diff_votes) do
        if istable(vote) then
            if vote.base and diff_collect[vote.base] ~= nil then
                diff_collect[vote.base] = diff_collect[vote.base] + 1
            end
            if vote.mod and diff_collect[vote.mod] ~= nil then
                diff_collect[vote.mod] = diff_collect[vote.mod] + 1
            end
        elseif isstring(vote) and diff_collect[vote] ~= nil then
            diff_collect[vote] = diff_collect[vote] + 1
        end
    end
    net.Start("Horde_VotediffSync")
    net.WriteTable(diff_collect)
    net.Broadcast()
end)

HORDE.VoteChangeMap = function (ply)
    HORDE.player_vote_map_change[ply] = 1
    if table.Count(HORDE.player_vote_map_change) == table.Count(player.GetAll()) then
        HORDE:SendNotification("All players want to change map! Initiating map vote...", 0)
        timer.Simple(1, function ()
            HORDE:GameEnd("Change Map")
        end)
    else
        HORDE:SendNotification(ply:GetName() .. " wants to change the map. (" .. tostring(table.Count(HORDE.player_vote_map_change)) .. "/" .. tostring(table.Count(player.GetAll())) .. ")", 0)
    end
end

function HORDE:ClearSpectatorState(ply)
    if not IsValid(ply) then return end
    ply:SetCollisionGroup(15)
    ply:SetCanZoom(false)
    ply:SetMoveType(MOVETYPE_WALK)

    ply:SetNoDraw(false)
    ply:DrawShadow(true)
    ply.Horde_SpectatorGhost = nil
    ply.Horde_DebuffImmune = nil
    if ply.SetNoTarget then ply:SetNoTarget(false) end
end

hook.Add("PlayerSpawn", "Horde_PlayerInitialSpawn", function(ply)
    if ply.Horde_Fake_Respawn == true then return end
    if ply:IsValid() then
        HORDE:ClearSpectatorState(ply)
        net.Start("Horde_ForceCloseShop")
        net.Send(ply)
    end
end)

hook.Add("Move", "Horde_PlayerMove", function (ply, mv)
    if ply:Horde_GetClass() then
        ply:SetJumpPower(150)
        local bonus_walk = {more = 1, increase = 0}
        local bonus_run = {more = 1, increase = 0}
        hook.Run("Horde_PlayerMoveBonus", ply, bonus_walk, bonus_run)
        ply:SetWalkSpeed(ply:Horde_GetClass().movespd * bonus_walk.more * (1 + bonus_walk.increase))
        ply:SetRunSpeed(ply:Horde_GetClass().sprintspd * bonus_run.more * (1 + bonus_run.increase))
    end
end)

hook.Add("Horde_PlayerMoveBonus", "Horde_PlayerPayloadMove", function (ply, bonus_walk, bonus_run)
    if ply:Horde_HasPayload() then
        local mass = ply.Horde_Payload_Spawn.Horde_Payload_Mass
        if mass and mass > 0 then
            bonus_walk.more = bonus_walk.more * (1 - math.max(0.1, mass/100))
            bonus_run.more = bonus_run.more * (1 - math.max(0.1, mass/100))
        end
    end
end)

local ghosts_sent = false
timer.Create("Horde_SpectatorGhosts", 0.1, 0, function()
    local list = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply.Horde_SpectatorGhost and not ply:Alive() and not IsValid(ply:GetObserverTarget()) then
            list[#list + 1] = ply
        end
    end
    if #list == 0 and not ghosts_sent then return end
    ghosts_sent = #list > 0
    net.Start("Horde_SpectatorGhosts", true)
    net.WriteUInt(#list, 8)
    for _, ply in ipairs(list) do
        net.WriteUInt(ply:EntIndex(), 8)
        net.WriteVector(ply:EyePos())
    end
    net.Broadcast()
end)

local function Horde_DeathSpectatingFunction(victim, inflictor, attacker)
    if not HORDE.start_game or HORDE.current_break_time > 0 then return end

    if IsValid(victim) then
        victim:SetNoDraw(true)
        victim:DrawShadow(false)
        victim.Horde_SpectatorGhost = true
        victim.Horde_DebuffImmune = true
        if victim.SetNoTarget then victim:SetNoTarget(true) end
    end

    timer.Simple(1, function()
        if victim:IsValid() and (not victim:Alive()) then
            victim:SetObserverMode(OBS_MODE_ROAMING)
            victim:SetMoveType(MOVETYPE_OBSERVER)
            victim:SetNoDraw(true)
            victim:DrawShadow(false)
            victim.Horde_SpectatorGhost = true
        end
    end)
end

local function Horde_GetAllLivingPlayers()
    if not HORDE.alive_players then HORDE.alive_players = {} end
    if HORDE.refresh_living_players then
        HORDE.alive_players = {}
        for _, ply in pairs(player.GetAll()) do
            if ply:Alive() then
                table.insert(HORDE.alive_players, ply)
            end
        end
        HORDE.refresh_living_players = nil
    end
end

function plymeta:Horde_SpectatePrevPlayer()
    local plys = HORDE.alive_players
    if #plys > 0 then
        local cur_target = self:GetObserverTarget()
        local index

        if !IsValid( cur_target ) then
            index = 1
        else
            for i, v in ipairs( plys ) do
                if v == cur_target then
                    index = i - 1
                    break
                end
            end
        end

        if !index then index = 1 end

        if index < 1 then
            index = #plys
        end

        local target = plys[index]

        if target ~= cur_target then
            self:SpectateEntity( target )
        end
    end
end

function plymeta:Horde_SpectateNextPlayer()
    local plys = HORDE.alive_players
    if #plys > 0 then
        local cur_target = self:GetObserverTarget()
        local index

        if !IsValid( cur_target ) or (not cur_target:Alive()) then
            index = 1
        else
            for i, v in ipairs( plys ) do
                if v == cur_target then
                    index = i + 1
                    break
                end
            end
        end

        if !index then index = 1 end

        if index > #plys then
            index = 1
        end

        local target = plys[index]

        if target ~= cur_target then
            self:SpectateEntity( target )
        end
    end
end

hook.Add("Horde_OnPlayerDebuffApply", "Horde_BlockSpectatorDebuff", function(ply, debuff, bonus, inflictor, buildup)
    if not IsValid(ply) then
        if istable(bonus) then bonus.apply = 0 end
        return
    end
    if not ply:Alive()
        or ply:GetMoveType() == MOVETYPE_OBSERVER
        or (ply.GetObserverMode and ply:GetObserverMode() ~= OBS_MODE_NONE)
        or ply.Horde_SpectatorGhost then
        if istable(bonus) then bonus.apply = 0 end
        return true
    end
end)

local SPECTATOR_LIGHT_COOLDOWN = 3
local SPECTATOR_LIGHT_DURATION = 4
local SPECTATOR_LIGHT_DISTANCE = 140
local SPECTATOR_LIGHT_BRIGHTNESS = 5

local function Horde_SpectatorIlluminate(ply)
    if not IsValid(ply) or ply:Alive() then return end
    if ply.Horde_SpectatorLightNext and ply.Horde_SpectatorLightNext > CurTime() then return end
    ply.Horde_SpectatorLightNext = CurTime() + SPECTATOR_LIGHT_COOLDOWN

    ply:EmitSound("ambient/fire/mtov_flame2.wav", 55, 130)

    local pos = ply:EyePos()
    if not pos or pos:IsZero() then
        pos = ply:GetPos() + Vector(0, 0, 36)
    end

    local light = ents.Create("light_dynamic")
    if not IsValid(light) then return end
    light:SetKeyValue("brightness", tostring(SPECTATOR_LIGHT_BRIGHTNESS))
    light:SetKeyValue("distance", tostring(SPECTATOR_LIGHT_DISTANCE))
    light:SetLocalPos(pos)
    light:SetLocalAngles(Angle(0, 0, 0))
    light:Fire("Color", "200 220 255")
    light:Spawn()
    light:Activate()
    light:Fire("TurnOn", "", 0)
    light:Fire("Kill", "", SPECTATOR_LIGHT_DURATION)
end

hook.Add("PlayerButtonDown", "Horde_SpectatorIlluminate", function(ply, button)
    if button ~= KEY_F then return end
    if not IsValid(ply) or ply:Alive() then return end
    Horde_SpectatorIlluminate(ply)
end)

hook.Add("KeyPress", "PlayerChangeSpectate", function(ply, key)
    if ply:Alive() then return end

    Horde_GetAllLivingPlayers()
    if #HORDE.alive_players == 0 then
        ply:SetObserverMode(OBS_MODE_ROAMING)
        return
    end
	if (key == IN_JUMP) then
		if ply:GetObserverMode() == OBS_MODE_ROAMING then
            ply:SetObserverMode(OBS_MODE_CHASE)
            ply:Horde_SpectateNextPlayer()
        else
            ply:SetObserverMode(OBS_MODE_ROAMING)
        end
	end

    if (key == IN_ATTACK) and ply:GetObserverMode() == OBS_MODE_CHASE then
        ply:Horde_SpectateNextPlayer()
    end

    if (key == IN_ATTACK2) and ply:GetObserverMode() == OBS_MODE_CHASE then
        ply:Horde_SpectatePrevPlayer()
    end
end)

hook.Add("PlayerDeath", "Horde_DeathSpectatingFunction", Horde_DeathSpectatingFunction)
hook.Add("PlayerSilentDeath", "Horde_DeathSpectatingFunction", Horde_DeathSpectatingFunction)

function HORDE:CheckAlivePlayers()
    HORDE.refresh_living_players = true
    local aliveplayers = 0
    local deadplayers = 0
    for _, ply in pairs(player.GetAll()) do
        if ply:IsValid() and ply:Alive() then
            aliveplayers = aliveplayers + 1
        end
        if ply:IsValid() and not ply:Alive() then
            deadplayers = deadplayers + 1
        end
    end
    if aliveplayers == 0 and deadplayers > 0 then
        for _, b in ipairs(ents.FindByClass("horde_watchtower_beacon")) do
            if IsValid(b) and b.Horde_BeaconCanRevive and b:Horde_BeaconCanRevive() then
                return
            end
        end
        for _, ply in pairs(player.GetAll()) do
        end
        local ret = hook.Run("Horde_ShouldContinueGameWhenAllPlayersAreDead")
        if ret then return end
        HORDE:GameEnd("DEFEAT")
    end
end

hook.Add("PlayerDeathThink", "Horde_PlayerDeathThink", function (ply)
    if HORDE.current_break_time > 0 then return true end
    if HORDE.start_game then return false end
    return true
end)

hook.Add("DoPlayerDeath", "Horde_DoPlayerDeath", function(victim)
    if HORDE.ClearPlayerDebuffs then
        HORDE:ClearPlayerDebuffs(victim)
    else
        hook.Run("Horde_ResetStatus", victim)
    end

    net.Start("Horde_ClearStatus")
    net.Send(victim)

    net.Start("Horde_ForceCloseShop")
    net.Send(victim)

    for _, wpn in pairs(victim:GetWeapons()) do
        victim:DropWeapon(wpn)
    end
    if (not HORDE.start_game) or (HORDE.current_break_time > 0) then
        timer.Simple(1, function() if victim:IsValid() then
            victim:Spawn()
        end end)
        return
    end
    HORDE:SendNotification("You are dead. You will respawn next wave.", 1, victim)
    HORDE:CheckAlivePlayers()
end)

hook.Add("Horde_AllModulesLoaded", "Horde_WrapDebuffForSpectators", function()
    local meta = FindMetaTable("Entity")
    if not meta or not meta.Horde_AddDebuffBuildup then return end
    if meta._Horde_DebuffWrappedForSpec then return end
    meta._Horde_DebuffWrappedForSpec = true

    local old = meta.Horde_AddDebuffBuildup
    function meta:Horde_AddDebuffBuildup(debuff, buildup, inflictor, pos)
        if IsValid(self) and self:IsPlayer() then
            if self.Horde_DebuffImmune
                or not self:Alive()
                or self:GetMoveType() == MOVETYPE_OBSERVER
                or self.Horde_SpectatorGhost
                or (self:GetObserverMode() ~= OBS_MODE_NONE) then
                return
            end
        end
        return old(self, debuff, buildup, inflictor, pos)
    end
    print("[Horde] DebuffBuildup wrapped — spectators immune")
end)

timer.Simple(0, function()
    local meta = FindMetaTable("Entity")
    if not meta or not meta.Horde_AddDebuffBuildup or meta._Horde_DebuffWrappedForSpec then return end
    meta._Horde_DebuffWrappedForSpec = true
    local oldfn = meta.Horde_AddDebuffBuildup
    function meta:Horde_AddDebuffBuildup(debuff, buildup, inflictor, pos)
        if IsValid(self) and self:IsPlayer() then
            if self.Horde_DebuffImmune
                or not self:Alive()
                or self:GetMoveType() == MOVETYPE_OBSERVER
                or self.Horde_SpectatorGhost
                or (self:GetObserverMode() ~= OBS_MODE_NONE) then
                return
            end
        end
        return oldfn(self, debuff, buildup, inflictor, pos)
    end
    print("[Horde] DebuffBuildup wrapped (late) — spectators immune")
end)
