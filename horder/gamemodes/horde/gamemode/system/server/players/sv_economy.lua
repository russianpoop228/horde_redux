concommand.Add("horde_drop_money", function (ply, cmd, args)
    ply:Horde_DropMoney(args[1])
end)

concommand.Add("horde_drop_weapon", function (ply, cmd, args)
    local cannotdropbase = {
        horde_spell_weapon_base = true,
        arccw_horde_base_nade = true,}
    local cannotdropclass = {
        horde_pheropod = true,
        horde_carcass = true,
        weapon_horde_medkit = true,
        horde_slam = true,}
    if ply:GetActiveWeapon() and ply:GetActiveWeapon():IsValid() and (cannotdropbase[ply:GetActiveWeapon().Base] or cannotdropclass[ply:GetActiveWeapon():GetClass()]) then
        HORDE:SendNotification("You can't drop this!", 1, ply)
        ply:EmitSound("player/suit_denydevice.wav")
        return
    end
    ply:DropWeapon()
end)

local GIVE_LEFTOVER_LIMIT = 3
local GIVE_LEFTOVER_LIFETIME = 30

function HORDE:TrackGivenLeftover(ply, ent)
    if not IsValid(ent) or ent:IsWeapon() then return end
    timer.Simple(0, function()
        if not IsValid(ent) or IsValid(ent:GetOwner()) then return end
        if not IsValid(ply) then ent:Remove() return end
        local list = ply.Horde_GiveLeftovers or {}
        for i = #list, 1, -1 do
            if not IsValid(list[i]) then table.remove(list, i) end
        end
        list[#list + 1] = ent
        while #list > GIVE_LEFTOVER_LIMIT do
            local old = table.remove(list, 1)
            if IsValid(old) then old:Remove() end
        end
        ply.Horde_GiveLeftovers = list
        timer.Simple(GIVE_LEFTOVER_LIFETIME, function()
            if IsValid(ent) and not IsValid(ent:GetOwner()) then ent:Remove() end
        end)
    end)
end

util.AddNetworkString("Horde_BuyItem")
util.AddNetworkString("Horde_BuyItemAmmoPrimary")
util.AddNetworkString("Horde_BuyItemAmmoSecondary")
util.AddNetworkString("Horde_BuyItemUpgrade")
util.AddNetworkString("Horde_BuySpellUpgrade")
util.AddNetworkString("Horde_BuySpell")
util.AddNetworkString("Horde_SellItem")
util.AddNetworkString("Horde_SelectClass")
util.AddNetworkString("Horde_InitClass")
util.AddNetworkString("Horde_SyncEconomy")
util.AddNetworkString("Horde_SyncDifficulty")
util.AddNetworkString("Horde_SyncDifficultyText")
util.AddNetworkString("Horde_RemoveReadyPanel")
util.AddNetworkString("Horde_SyncMaxWeight")
util.AddNetworkString("Horde_IsInBuyZone")
util.AddNetworkString("Horde_IsInBreakTime")

local plymeta = FindMetaTable("Player")

function plymeta:Horde_SetMaxHealth(base)
    timer.Simple(0, function ()
        if not self:IsValid() then return end
        if not base then base = 100 end
        local bonus = {increase = 0, more = 1, add = 0}
        hook.Run("Horde_OnSetMaxHealth", self, bonus)
        self:SetMaxHealth(bonus.add + base * bonus.more * (1 + bonus.increase))
        self:SetHealth(self:GetMaxHealth())
    end)
end

function plymeta:Horde_SetMaxArmor(base)
    timer.Simple(0, function ()
        if not self:IsValid() then return end
        if not base then base = 100 end
        local bonus = {increase = 0, more = 1, add = 0}
        hook.Run("Horde_OnSetMaxArmor", self, bonus)
        self:SetMaxArmor(bonus.add + base * bonus.more * (1 + bonus.increase))
    end)
end

function plymeta:Horde_SetMaxHealthOnly(base)
    timer.Simple(0, function ()
        if not self:IsValid() then return end
        if not base then base = 100 end
        local bonus = {increase = 0, more = 1, add = 0}
        hook.Run("Horde_OnSetMaxHealth", self, bonus)
        self:SetMaxHealth(bonus.add + base * bonus.more * (1 + bonus.increase))
    end)
end

function plymeta:Horde_SetWeight(weight)
    self.Horde_weight = math.Clamp(weight, 0, self:Horde_GetMaxWeight())
end

function plymeta:Horde_SetMaxWeight(weight)
    if self.Horde_max_weight then
        if self.Horde_max_weight > weight then
            local old_max_weight = self:Horde_GetMaxWeight()
            self.Horde_max_weight = weight
            self.Horde_weight = math.min(weight, self:Horde_GetWeight() - (old_max_weight - weight))
            timer.Simple(0, function()
                self:Horde_RecalcWeight()
            end)
            self:Horde_SyncEconomy()
        else
            self.Horde_weight = math.min(weight, self:Horde_GetWeight() + weight - self:Horde_GetMaxWeight())
            self:Horde_SyncEconomy()
        end
    end
    self.Horde_max_weight = weight
    net.Start("Horde_SyncMaxWeight")
        net.WriteUInt(self.Horde_max_weight, 5)
    net.Send(self)
end

function plymeta:Horde_SetMoney(money)
    self.Horde_money = money
end

function plymeta:Horde_SetSkullTokens(tokens)
    self.Horde_skull_tokens = tokens
end

function HORDE:ShopAllowed()
    return true
end

function HORDE:UnarmedShopBlocked(ply)
    return false
end

function plymeta:Horde_SetInBuyZone(can_buy)
    if can_buy and not HORDE:ShopAllowed() then can_buy = false end
    self.Horde_CanBuy = can_buy
    net.Start("Horde_SyncStatus")
        net.WriteUInt(HORDE.Status_CanBuy, 8)
        if can_buy then
            net.WriteUInt(1, 8)
        else
            net.WriteUInt(0, 8)
        end
    net.Send(self)

    net.Start("Horde_IsInBuyZone")
        net.WriteBool(can_buy)
    net.Send(self)
end

function plymeta:Horde_GetInBuyZone()
    return self.Horde_CanBuy
end

function plymeta:Horde_SetClassModel(class)
    if HORDE.classes[class.name].model and HORDE.classes[class.name].model ~= "" then
        local mdl = HORDE.classes[class.name].model
        local mdl_path = player_manager.TranslatePlayerModel(mdl)
        timer.Simple(0.1, function() self:SetModel(mdl_path) self:SetupHands() end)
        timer.Simple(0.2, function()
            local mdlhands = player_manager.TranslatePlayerHands(mdl)
            local hands_ent = self:GetHands()
            if hands_ent and mdlhands and istable(mdlhands) then
                if hands_ent:GetModel() ~= mdlhands.model then
                    if (IsValid(hands_ent)) then
                        hands_ent:SetModel( mdlhands.model )
                        hands_ent:SetSkin( mdlhands.skin )
                        hands_ent:SetBodyGroups( mdlhands.body )
                    end
                end
            end
        end)
    end
end

function plymeta:Horde_SetDropEntities(entities)
    self.Horde_drop_entities = entities
end

function plymeta:Horde_AddDropEntity(class, entity)
    if not self:IsValid() then return end
    if not self.Horde_drop_entities then
        self.Horde_drop_entities = {}
    end
    if self.Horde_drop_entities[class] then
        self.Horde_drop_entities[class] = self.Horde_drop_entities[class] + 1
    else
        self.Horde_drop_entities[class] = 1
    end
    if not HORDE.player_drop_entities[self:SteamID()] then
        HORDE.player_drop_entities[self:SteamID()] = {}
    end
    HORDE.player_drop_entities[self:SteamID()][entity:GetCreationID()] = entity
end

function plymeta:Horde_RemoveDropEntity(class, entity_creation_id, weightless)
    if not self:IsValid() then return end
    if self.Horde_drop_entities and self.Horde_drop_entities[class] then
        self.Horde_drop_entities[class] = self.Horde_drop_entities[class] - 1
        if self.Horde_drop_entities[class] == 0 then
            self.Horde_drop_entities[class] = nil
        end
    end
    if HORDE.player_drop_entities[self:SteamID()] then
        HORDE.player_drop_entities[self:SteamID()][entity_creation_id] = nil
    end
    local item = HORDE.items[class]
    if item and (not weightless) then
        self:Horde_AddWeight(item.weight)
    end
end

function plymeta:Horde_RemoveMinionsAndDrops()
    if not self:IsValid() then return end
    if HORDE.player_drop_entities[self:SteamID()] then
        for _, ent in pairs(HORDE.player_drop_entities[self:SteamID()]) do
            if ent:IsValid() and HORDE:IsMinion(ent) then
                local eClass = ent:GetClass()
                local item = HORDE.items[eClass]
                if item then
                    self:Horde_AddMoney(math.floor(0.75 * item.price))
                end
                ent:Remove()
                if self.Horde_drop_entities and self.Horde_drop_entities[eClass] then
                    self.Horde_drop_entities[eClass] = self.Horde_drop_entities[eClass] - 1
                    if self.Horde_drop_entities[eClass] == 0 then
                        self.Horde_drop_entities[eClass] = nil
                    end
                end
                if item and not ent:IsNPC() then
                    self:Horde_AddWeight(item.weight)
                end
            end
        end
    end
end

function plymeta:Horde_SetMinionCount(count)
    self.Horde_MinionCount = math.max(0,count)
    net.Start("Horde_SyncStatus")
        net.WriteUInt(HORDE.Status_Minion, 8)
        net.WriteUInt(self.Horde_MinionCount, 8)
    net.Send(self)
end

function plymeta:Horde_GetMinionCount()
    return self.Horde_MinionCount or 0
end

function plymeta:Horde_AddMoney(money)
    if not self:IsValid() or not money then return end
    if not self.Horde_money then self.Horde_money = 0 end
    self.Horde_money = self.Horde_money + money
end

function plymeta:Horde_AddWeight(weight)
    if not self:IsValid() then return end
    if not self.Horde_weight then self.Horde_weight = 0 end
    self.Horde_weight = math.Clamp(self.Horde_weight + weight, 0, self:Horde_GetMaxWeight())
end

function plymeta:Horde_AddSkullTokens(tokens)
    if not self:IsValid() or not tokens then return end
    if not self.Horde_skull_tokens then self.Horde_skull_tokens = 0 end
    self.Horde_skull_tokens = self.Horde_skull_tokens + tokens
    HORDE:SaveSkullTokens(self)
end

function plymeta:Horde_GetMoney()
    return self.Horde_money
end

function plymeta:Horde_GetSkullTokens()
    return self.Horde_skull_tokens or 0
end

function plymeta:Horde_GetDropEntities()
    return self.Horde_drop_entities
end

function plymeta:Horde_DropMoney(amount)
    local numeric = tonumber(amount)
    if not numeric or numeric ~= numeric then numeric = 50 end
	amount = math.floor(numeric)
	if amount < 50 then amount = 50 end
    if self:Horde_GetMoney() >= amount and self:Alive() then
        local res = hook.Run("Horde_PlayerDropMoney", self)
        if res then
            self:Horde_SyncEconomy()
            return
        end
        self:Horde_AddMoney(-amount)
        local money = ents.Create("horde_money")
        local pos = self:GetPos()
        local dir = (self:GetEyeTrace().HitPos - pos)
        dir:Normalize()
        local drop_pos = pos + dir * 50
        drop_pos.z = pos.z + 15
        money:SetPos(drop_pos)
        money:Spawn()
		money:SetMoney(amount)
        self:Horde_SyncEconomy()
    end
end

function plymeta:Horde_GetMaxWeight()
    return self.Horde_max_weight
end

function plymeta:Horde_GetWeight()
    return self.Horde_weight or 0
end

function plymeta:Horde_SyncEconomy()
    if not self:IsValid() then return end
    if not self.Horde_money or not self.Horde_weight or not self.Horde_class then return end
    local money = tonumber(self.Horde_money)
    local tokens = tonumber(self.Horde_skull_tokens) or 0
    local weight = tonumber(self.Horde_weight)
    local subclass = self:Horde_GetSubclass(self.Horde_class.name)
    local drop_entities = self.Horde_drop_entities
    if not money or not weight then return end
    if type(subclass) ~= "string" then return end
    if not istable(drop_entities) then drop_entities = {} end

    net.Start("Horde_SyncEconomy")
        net.WriteEntity(self)
        net.WriteInt(math.floor(money), 32)
        net.WriteInt(math.floor(tokens), 32)
        net.WriteInt(math.floor(weight), 32)
        net.WriteString(subclass)
        net.WriteTable(drop_entities)
    net.Broadcast()
end

function plymeta:Horde_WeightSync()
    if not self:IsValid() then return end
    local weight = self:Horde_GetMaxWeight() or HORDE.max_weight
    if self.Horde_Special_Upgrades then
        for mod, _ in pairs(self.Horde_Special_Upgrades) do
            local it = HORDE.items[mod]
            if it then weight = weight - (tonumber(it.weight) or 0) end
        end
    end
    if self:Horde_GetGadget() then
        local it = HORDE.items[self:Horde_GetGadget()]
        if it then weight = weight - (tonumber(it.weight) or 0) end
    end
    if HORDE.player_drop_entities[self:SteamID()] then
        for _, ent in pairs(HORDE.player_drop_entities[self:SteamID()]) do
            if IsValid(ent) then
                local it = HORDE.items[ent:GetClass()]
                if it then weight = weight - (tonumber(it.weight) or 0) end
            end
        end
    end
    for _, wpn in pairs(self:GetWeapons()) do
        local it = HORDE.items[wpn:GetClass()]
        if it then weight = weight - (tonumber(it.weight) or 0) end
    end
    self:Horde_SetWeight(math.max(0, weight))
    self:Horde_SyncEconomy()
end

function HORDE:WeightSync(ply)
    if IsValid(ply) then ply:Horde_WeightSync() return end
    for _, p in pairs(player.GetAll()) do
        if p:IsValid() then p:Horde_WeightSync() end
    end
end

function plymeta:Horde_RecalcWeight()
    local weight = 0
    for _, wpn in pairs(self:GetWeapons()) do
        if not HORDE.items[wpn:GetClass()] then goto cont end
        local wpn_weight = HORDE.items[wpn:GetClass()].weight
        local gadget_weight = 0
        if self:Horde_GetGadget() then
            gadget_weight = HORDE.items[self:Horde_GetGadget()].weight
        end
        if weight + gadget_weight + wpn_weight > self:Horde_GetMaxWeight() then
            self:DropWeapon(wpn)
        else
            weight = weight + wpn_weight
        end
        ::cont::
    end
end

hook.Add("PlayerSpawn", "Horde_Economy_Sync", function (ply)
    if ply.Horde_Fake_Respawn == true then return end
    hook.Run("Horde_ResetStatus", ply)
    net.Start("Horde_ClearStatus")
    net.Send(ply)
    ply:SetCustomCollisionCheck(true)
    HORDE.refresh_living_players = true

    if HORDE.start_game and HORDE.current_break_time <= 0 then
        if ply:IsValid() then
            local ret = hook.Run("Horde_OnPlayerShouldRespawnDuringWave", ply)
            if not ret then
                ply:KillSilent()
                HORDE:SendNotification("You will respawn next wave.", 0, ply)
            end
        end
    end

    if not ply:IsValid() or not ply.Horde_Init_Complete then return end
    if not ply:Horde_GetCurrentSubclass() then return end
    ply:Horde_SetMaxWeight(HORDE.max_weight)
    ply:Horde_ApplyPerksForClass()
    ply:Horde_SchedulePendingPerkApply()
    local module_weight = 0
    if ply.Horde_Special_Upgrades and next(ply.Horde_Special_Upgrades) ~= nil then
        for spec_modules, _ in pairs(ply.Horde_Special_Upgrades) do
            module_weight = module_weight - HORDE.items[spec_modules].weight
        end
    end
    ply:Horde_SetWeight(ply:Horde_GetMaxWeight() + module_weight)
    if ply.Horde_Special_Armor then
        net.Start("Horde_SyncSpecialArmor")
            net.WriteString(ply.Horde_Special_Armor)
            net.WriteUInt(1, 3)
        net.Send(ply)
    end
    if ply:Horde_GetGadget() then
        local item = HORDE.items[ply:Horde_GetGadget()]
        if item then
            ply:Horde_AddWeight(-item.weight)
        end
    end
    if HORDE.player_drop_entities[ply:SteamID()] then
        for _, ent in pairs(HORDE.player_drop_entities[ply:SteamID()]) do
            if ent:IsValid() then
                local item = HORDE.items[ent:GetClass()]
                if item then
                    ply:Horde_AddWeight(-item.weight)
                end
            end
        end
    end

    ply:Horde_SyncEconomy()
    if ply:Alive() and not (HORDE.start_game and HORDE.current_break_time <= 0) then
        HORDE:GiveStarterWeapons(ply)
    end

    if GetConVar("horde_enable_sandbox"):GetInt() == 1 then
        net.Start("Horde_SyncStatus")
            net.WriteUInt(HORDE.Status_ExpDisabled, 8)
            net.WriteUInt(1, 8)
        net.Send(ply)
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
end)

hook.Add("PlayerDroppedWeapon", "Horde_Economy_Drop", function (ply, wpn)
    if not ply:IsValid() then return end
    if ply:IsNPC() then return end
    local class = wpn:GetClass()
    if HORDE.items[class] then
        local item = HORDE.items[class]
        ply:Horde_AddWeight(item.weight)
        ply:Horde_SyncEconomy()

        if item.starter_classes then
            if HORDE.relic_weapon_subclass[class] == ply:Horde_GetCurrentSubclass() then
                local c = wpn:GetClass()
                if (wpn.Base == "horde_spell_weapon_base") then
                    local primary_next = wpn:GetNextPrimaryFire()
                    local secondary_next = wpn:GetNextSecondaryFire()
                    local utility_next = wpn:GetNextUtilityFire()
                    local ultimate_next = wpn:GetNextUltimateFire()

                    wpn:Remove()
                    timer.Simple(0, function()
                        if ply:Alive() then
                            ply:Give(c)
                            timer.Simple(0, function ()
                                local w2 = ply:Horde_GetSpellWeapon()
                                if w2 then
                                    w2:SetNextPrimaryFire(primary_next)
                                    w2:SetNextSecondaryFire(secondary_next)
                                    w2:SetNextUtilityFire(utility_next)
                                    w2:SetNextUltimateFire(ultimate_next)
                                end
                            end)
                        end
                    end)
                else
                    wpn:Remove()
                    timer.Simple(0, function()
                        if ply:Alive() then
                            ply:Give(c)
                        end
                    end)
                end
            end
        end
    end
end)

hook.Add("PlayerCanPickupWeapon", "Horde_Economy_Pickup", function (ply, wpn)
    if not ply:IsValid() then return false end
    if ply:IsNPC() then return true end
    local unarmed_loot = HORDE.unarmed_mode and wpn.Horde_UnarmedDrop
    if HORDE.items[wpn:GetClass()] then
        local item = HORDE.items[wpn:GetClass()]
        if (ply:Horde_GetWeight() - item.weight < 0) then
            if unarmed_loot and (not ply.Horde_UnarmedWeightMsg or ply.Horde_UnarmedWeightMsg < CurTime()) then
                ply.Horde_UnarmedWeightMsg = CurTime() + 2
                HORDE:SendNotification("Too heavy! You don't have enough weight capacity for this weapon.", 1, ply)
            end
            return false
        end
        if unarmed_loot then return true end
        if ply:Horde_GetCurrentSubclass() == "Gunslinger" and item.category == "Pistol" then return true end

        if item.whitelist and not item.whitelist[ply:Horde_GetCurrentSubclass()] then
            return false
        end

        if item.starter_classes then
            local required_subclass = HORDE.relic_weapon_subclass[item.class]
            if required_subclass and ply:Horde_GetCurrentSubclass() ~= required_subclass then
                return false
            end
        end
        if ply:Horde_GetCurrentSubclass() == "Carcass"
        and (item.class ~= "horde_carcass" and item.class ~= "weapon_horde_medkit") then
            return false
        end
        if ply:Horde_GetSpellWeapon() and (item.class ~= "weapon_horde_medkit") then
            return false
        end
    end

    return true
end)

hook.Add("WeaponEquip", "Horde_Economy_Equip", function (wpn, ply)
    if not ply:IsValid() then return end
    if HORDE.items[wpn:GetClass()] then
        local item = HORDE.items[wpn:GetClass()]
        if HORDE.unarmed_mode and wpn.Horde_UnarmedDrop then
            wpn.Horde_UnarmedDrop = nil
            wpn.Horde_UnarmedLoot = true
            wpn:SetNWBool("Horde_UnarmedDrop", false)
            wpn:SetNWBool("Horde_UnarmedLoot", true)
            if HORDE.Unarmed_OnPickup then HORDE:Unarmed_OnPickup(wpn, ply) end
            ply:Horde_AddWeight(-item.weight)
            ply:Horde_SyncEconomy()
            return
        end
        if ply:Horde_GetCurrentSubclass() == "Gunslinger" and item.category == "Pistol" then
            ply:Horde_AddWeight(-item.weight)
            ply:Horde_SyncEconomy()
            return
        end
        if (ply:Horde_GetWeight() - item.weight < 0) or (item.whitelist and not item.whitelist[ply:Horde_GetCurrentSubclass()]) then
            timer.Simple(0, function ()
                ply:DropWeapon(wpn)
            end)
            return
        end
        ply:Horde_AddWeight(-item.weight)
        ply:Horde_SyncEconomy()
        return
    end
end)

net.Receive("Horde_BuyItem", function (len, ply)
    if not ply:IsValid() or not ply:Alive() or not ply.Horde_Init_Complete then return end
    if not HORDE:AllowNetRequest(ply, "buy_item", 0.15) then return end
    if HORDE:UnarmedShopBlocked(ply) then return end
    local class = net.ReadString()
    local item = HORDE.items and HORDE.items[class]
    if not item then return end
    if HORDE.IsPurismBlockedShopItem and HORDE:IsPurismBlockedShopItem(item) then return end
    local price = tonumber(item.price)
    local weight = tonumber(item.weight) or 0
    local levels = item.levels
    local skull_tokens = tonumber(item.skull_tokens) or 0
    if not price or price < 0 or price ~= price or weight < 0 or weight ~= weight
        or skull_tokens < 0 or skull_tokens ~= skull_tokens or (levels ~= nil and not istable(levels)) then return end
    local subclass = ply:Horde_GetCurrentSubclass()
    if item.whitelist and (not subclass or item.whitelist[subclass] ~= true) then return end
    local level_satisfy = true
    if levels and (HORDE.disable_levels_restrictions == 0) then
        for c, level in pairs(levels) do
            if ply:Horde_GetLevel(c) < level then
                level_satisfy = false
                break
            end
        end
    end
    if ply:Horde_GetMoney() >= price and ply:Horde_GetWeight() >= weight and ply:Horde_GetSkullTokens() >= skull_tokens and level_satisfy then
        if item.entity_properties then
            if item.entity_properties.type == HORDE.ENTITY_PROPERTY_WPN then
                local wpns = list.Get("Weapon")
                if not wpns[class] then return end
                if HORDE.unarmed_mode and HORDE.Unarmed_HasLooted and not HORDE:Unarmed_HasLooted(ply, class) then
                    local msg = (translate and translate.Get and translate.Get("Shop_Unarmed_NotLooted"))
                        or "You can only buy weapons you have already found on the map (Unarmed mode)."
                    HORDE:SendNotification(msg, 1, ply)
                    return
                end
                ply:Horde_AddMoney(-price)
                ply:Horde_AddSkullTokens(-skull_tokens)
                ply:Give(class)
                ply:SelectWeapon(class)
            elseif item.entity_properties.type == HORDE.ENTITY_PROPERTY_GIVE then
                if class == "item_battery" and ply:Armor() >= ply:GetMaxArmor() then
                    HORDE:SendNotification("Your armor is already full.", 1, ply)
                    return
                end
                ply:Horde_AddMoney(-price)
                ply:Horde_AddSkullTokens(-skull_tokens)
                if item.entity_properties.is_arccw_attachment and item.entity_properties.is_arccw_attachment == true then
                    ArcCW:PlayerGiveAtt(ply, class, 1)
                    ArcCW:PlayerSendAttInv(ply)
                else
                    HORDE:TrackGivenLeftover(ply, ply:Give(class))
                end
            elseif item.entity_properties.type == HORDE.ENTITY_PROPERTY_DROP then
                local drop_entities = ply:Horde_GetDropEntities()
                local drop_limit = tonumber(item.entity_properties.limit)
                if drop_entities[item.class] and drop_limit and drop_entities[item.class] > drop_limit then
                    return
                end

                if item.CanPurchase then
                    local ok, reason = item.CanPurchase(ply, item)
                    if ok == false then
                        if reason then HORDE:SendNotification(reason, 1, ply) end
                        return
                    end
                elseif item.class == "npc_turret_floor" and ply:Horde_GetPerk("engineer_manhack") then
                    return
                end

                ply:Horde_AddMoney(-price)
                ply:Horde_AddSkullTokens(-skull_tokens)
                ply:Horde_AddWeight(-item.weight)
                local ent = ents.Create(class)
                if not IsValid(ent) then
                    ply:Horde_AddMoney(price)
                    ply:Horde_AddSkullTokens(skull_tokens)
                    ply:Horde_AddWeight(item.weight)
                    ply:Horde_SyncEconomy()
                    HORDE:SendNotification("This unit is not available on this server.", 1, ply)
                    return
                end
                local pos = ply:GetPos()
                local dir = (ply:GetEyeTrace().HitPos - pos)
                dir:Normalize()
                local drop_pos = pos + dir * item.entity_properties.x
                drop_pos.z = pos.z + item.entity_properties.z
                ent:SetPos(drop_pos)
                ent:SetAngles(Angle(0, ply:GetAngles().y + item.entity_properties.yaw, 0))
                ply:Horde_AddDropEntity(ent:GetClass(), ent)
                ent:SetNWEntity("HordeOwner", ply)
                ent:SetOwner(ply)
                ent.Horde_Owner = ply
                ent:Spawn()

                if ent:IsNPC() then
                    HORDE:FriendlyAlly(ent)
                    timer.Simple(0.1, function ()
                        if IsValid(ent) then ent.VJFriendly = false end
                    end)
                    local npc_info = list.Get("NPC")[ent:GetClass()]
                    if not npc_info then
                        print("[HORDE] NPC class is missing from the NPC list: " .. ent:GetClass())
                    end

                    local wpns = npc_info and npc_info["Weapons"]
                    if wpns then
                        local wpn = wpns[math.random(#wpns)]
                        ent:Give(wpn)
                    end

                    local id = ent:GetCreationID()
                    local is_manhack = ent:GetClass() == "npc_manhack"

                    if is_manhack then
                        ent:SetMaxHealth(100)
                        ent.Horde_Minion_Respawn = true
                    end

                    ent:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
                    timer.Create("Horde_MinionCollision" .. id, 1, 0, function ()
                        if not IsValid(ent) then timer.Remove("Horde_MinionCollision" .. id) return end
                        ent:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
                    end)
                    if HORDE:IsTurretMinion(ent) then
                        HORDE:DropTurret(ent)
                    end

                    HORDE:RegisterMinion(ent, ply, {
                        no_collision = false,
                        drop_entity  = false,
                        on_remove = function(removed, owner)
                            timer.Remove("Horde_MinionCollision" .. id)
                            if IsValid(owner) then
                                owner:Horde_RemoveDropEntity(removed:GetClass(), id)
                                owner:Horde_SyncEconomy()
                            end
                            if is_manhack then
                                timer.Remove("Horde_ManhackRepos" .. id)
                                if removed.Horde_Minion_Respawn and IsValid(owner) then
                                    timer.Remove("Horde_ManhackRespawn" .. id)
                                    local drop_ents = owner:Horde_GetDropEntities()
                                    local count = drop_ents and drop_ents[class]
                                    if (!count) or (count and count <= item.entity_properties.limit) then
                                        timer.Create("Horde_ManhackRespawn" .. id, 30, 1, function ()
                                            if owner:IsValid() then
                                                HORDE:SpawnManhack(owner, id)
                                            end
                                        end)
                                    end
                                end
                            end
                        end,
                    })

                    if is_manhack then
                        timer.Create("Horde_ManhackRepos" .. id, 30, 0, function ()
                            if ent:IsValid() and ply:Alive() then
                                ent:SetPos(ply:GetPos() + VectorRand())
                            else
                                timer.Remove("Horde_ManhackRepos" .. id)
                                if ent:IsValid() then ent:Remove() end
                            end
                        end)
                    end
                end
            elseif item.entity_properties.type == HORDE.ENTITY_PROPERTY_ARMOR then
                local is_standard = item.is_standard_armor
                    or item.class == "armor100"
                    or item.class == "armor150"
                if is_standard then
                    if ply:Armor() >= ply:GetMaxArmor() then return end
                else
                    ply.Horde_Special_Armor = item.class
                    net.Start("Horde_SyncSpecialArmor")
                        net.WriteString(ply.Horde_Special_Armor)
                        net.WriteUInt(1, 3)
                    net.Send(ply)
                end
                if item.OnPickup then
                    item.OnPickup(ply, item)
                end
                ply:SetArmor(ply:GetMaxArmor() * item.entity_properties.armor / 100)
                ply:Horde_SetMaxHealth()
                ply:Horde_SetMaxArmor()
                ply:Horde_AddMoney(-price)
                ply:Horde_AddSkullTokens(-skull_tokens)
                ply:Horde_SyncEconomy()

            elseif item.entity_properties.type == HORDE.ENTITY_PROPERTY_SPECIAL_UPGRADE then
                ply:Horde_SetSpecialUpgrade(item.class)
                ply:Horde_AddMoney(-price)
                ply:Horde_AddSkullTokens(-skull_tokens)
                ply:Horde_SyncEconomy()
                hook.Run("Horde_OnSpecialUpgradeBuySell", ply)

            elseif item.entity_properties.type == HORDE.ENTITY_PROPERTY_GADGET then
                ply:Horde_UnsetGadget()
                ply:Horde_SetGadget(item.class)
                ply:Horde_AddMoney(-price)
                ply:Horde_AddSkullTokens(-skull_tokens)
                ply:Horde_SyncEconomy()
            end
        else
            local wpns = list.Get("Weapon")
            if not wpns[class] then return end
            ply:Horde_AddMoney(-price)
            ply:Give(class)
            ply:SelectWeapon(class)
        end

        HORDE:SendNotification("You bought " .. item.name .. ".", 0, ply)
        ply:Horde_SyncEconomy()
    end
end)

net.Receive("Horde_BuySpell", function (len, ply)
    if not ply:IsValid() or not ply:Alive() or not ply.Horde_Init_Complete then return end
    if not HORDE:AllowNetRequest(ply, "buy_spell", 0.25) then return end
    if HORDE:UnarmedShopBlocked(ply) then return end
    local spell_name = net.ReadString()
    local spell = HORDE.spells and HORDE.spells[spell_name]
    if not spell or not isnumber(spell.Slot) or spell.Slot < 0 or spell.Slot > 3 then return end
    local price = tonumber(spell.Price) or 0
    if price < 0 or price ~= price then return end
    if ply:Horde_GetMoney() >= price then
        ply:Horde_AddMoney(-price)
        ply:Horde_SetSpell(spell_name)
        HORDE:SendNotification("You bought " .. tostring(spell.PrintName or spell_name) .. ".", 0, ply)
        ply:Horde_SyncEconomy()
    end
end)

function GM:PlayerUse(other_ply, target)
    local owner = target:GetNWEntity("HordeOwner")
    if IsValid(owner) and other_ply ~= owner then return false end

    if target:GetClass() == "npc_turret_floor" then
        target:GetPhysicsObject():EnableMotion(true)
    end

    return true
end

function HORDE:DropTurret(ent)
    local turret_pos = ent:GetPos()
    local tr = util.TraceLine({
        start = turret_pos,
        endpos = turret_pos + Vector(0,0,-1) * 10000,
        filter = ent,
        collisiongroup =  COLLISION_GROUP_WORLD
    })

    if IsValid(tr.Entity) or tr.HitWorld then
        local dist_sqr = turret_pos:DistToSqr(tr.HitPos)
        if dist_sqr >= 40000 then return end
        ent:SetPos(Vector(turret_pos.x, turret_pos.y, tr.HitPos.z + 15))
        ent:DropToFloor()
        timer.Simple(0.5, function()
            if not ent:IsValid() then return end
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(false)
                phys:SetMass(50000)
            end
        end)
    end
end

hook.Add("OnPlayerPhysicsDrop", "Horde_TurretDrop", function (ply, ent, thrown)
    if HORDE:IsMinion(ent) and HORDE:IsTurretMinion(ent) and (not ent.Horde_Pickedup) then
        local a = ent:GetAngles()
        if ent:GetClass() == "npc_vj_horde_sniper_turret" then
        else
            ent:SetAngles(Angle(0, a.y, 0))
        end

        HORDE:DropTurret(ent)

        if ent:GetClass() == "npc_vj_horde_rocket_turret" || ent:GetClass() == "npc_vj_horde_laser_turret" then
            ent:SetAngles(Angle(0,0,0))
            ent:PhysicsInit(SOLID_OBB)
        end
    end
end)

net.Receive("Horde_SellItem", function (len, ply)
    if not ply:IsValid() or not ply.Horde_Init_Complete then return end
    if not HORDE:AllowNetRequest(ply, "sell_item", 0.15) then return end
    if HORDE:UnarmedShopBlocked(ply) then return end
    local class = net.ReadString()
    local item = HORDE.items and HORDE.items[class]
    if not item then return end
    local item_price = tonumber(item.price)
    if not item_price or item_price < 0 or item_price ~= item_price then return end
    local canSell, why = hook.Call("CanSell", HORDE, ply, class)
    if canSell == false then
        HORDE:SendNotification(why or "You can't sell this.", 1, ply)
        return
    end
    if ply:HasWeapon(class) then
        ply:Horde_AddMoney(math.floor(item_price * 0.75))
        ply:StripWeapon(class)
        ply:Horde_SyncEconomy()
    else
        if not item.entity_properties then return end
        if item.entity_properties.type == HORDE.ENTITY_PROPERTY_DROP then
            local drop_entities = ply:Horde_GetDropEntities()
            if drop_entities and drop_entities[class] then
                ply:Horde_AddMoney(math.floor(0.75 * item_price * drop_entities[class]))
                for _, ent in pairs(HORDE.player_drop_entities[ply:SteamID()]) do
                    if ent:IsValid() and ent:GetClass() == class then
                        ent.Horde_Minion_Respawn = nil
                        timer.Remove("Horde_ManhackRespawn" .. ent:GetCreationID())
                        ent:Remove()
                        if not ent:IsNPC() then
                            if ply.Horde_drop_entities and ply.Horde_drop_entities[class] then
                                ply.Horde_drop_entities[class] = ply.Horde_drop_entities[class] - 1
                                if ply.Horde_drop_entities[class] == 0 then
                                    ply.Horde_drop_entities[class] = nil
                                end
                            end
                            if not ent.Horde_Is_Mini_Sentry then
                                ply:Horde_AddWeight(item.weight)
                            end
                        end
                    end
                end
                ply:Horde_SyncEconomy()
            end
        elseif item.entity_properties.type == HORDE.ENTITY_PROPERTY_SPECIAL_UPGRADE then
            ply:Horde_UnsetSpecialUpgrade(item.class)
            ply:Horde_SyncEconomy()
            hook.Run("Horde_OnSpecialUpgradeBuySell", ply)

        elseif item.entity_properties.type == HORDE.ENTITY_PROPERTY_GADGET then
            if ply:Horde_GetGadget() == nil then return end
            ply:Horde_UnsetGadget()
            ply:Horde_SyncEconomy()
        end
    end
end)

net.Receive("Horde_InitClass", function (len, ply)
    if not HORDE:AllowNetRequest(ply, "init_class", 5) or ply.Horde_ClassInitialized then return end
    local subclass_name = net.ReadString()
    local subclass = HORDE.subclasses and HORDE.subclasses[subclass_name]
    if not subclass then return end
    if not HORDE:LoadSubclassUnlocks(ply) then return end
    local class_name = subclass.ParentClass or subclass.PrintName
    local class = HORDE.classes[class_name]
    if not class then return end
    if subclass.ParentClass and ply:Horde_GetSubclassUnlocked(subclass_name) ~= true then
        subclass_name = class_name
    end
    class = HORDE:ValidateClassTransition(ply, class_name, subclass_name, true)
    if not class then return end
    ply:Horde_SetClass(class)
    if not ply:Horde_SetSubclass(class.name, subclass_name, true) then return end
    ply:Horde_SetMaxWeight(HORDE.max_weight)
    ply:Horde_ApplyPerksForClass()
    ply:Horde_WeightSync()
    ply.Horde_ClassInitialized = true
    ply:Horde_SyncEconomy()
end)

net.Receive("Horde_SelectClass", function (len, ply)
    if not HORDE:AllowNetRequest(ply, "select_class", 1) then return end
    local name = net.ReadString()
    local subclass_name = net.ReadString()
    local class, reason = HORDE:ValidateClassTransition(ply, name, subclass_name, false)
    if not class then
        if reason then HORDE:SendNotification(reason, 1, ply) end
        return
    end

    net.Start("Horde_ClearStatus")
    net.Send(ply)

    ply:Horde_SetClass(class)
    for _, wpn in pairs(ply:GetWeapons()) do
        if wpn:GetClass() == "weapon_horde_medkit" then continue end
        ply:StripWeapon(wpn:GetClass())
    end
    hook.Run("Horde_OnPlayerSelectClass", ply, class)
    if not ply:Horde_SetSubclass(name, subclass_name, true) then return end
    ply:Horde_SetMaxWeight(HORDE.max_weight)
    ply:Horde_WeightSync()

    if ply.Horde_Special_Upgrades then
        for upgrades in pairs(ply.Horde_Special_Upgrades) do
            ply:Horde_UnsetSpecialUpgrade(upgrades)
        end
    end

    if HORDE.player_drop_entities[ply:SteamID()] then
        for _, ent in pairs(HORDE.player_drop_entities[ply:SteamID()]) do
            if ent:IsValid() then
                local eClass = ent:GetClass()
                local item = HORDE.items[eClass]
                if item then
                    ply:Horde_AddMoney(math.floor(0.75 * item.price))
                end
                ent:Remove()
                if ply.Horde_drop_entities and ply.Horde_drop_entities[eClass] then
                    ply.Horde_drop_entities[eClass] = ply.Horde_drop_entities[eClass] - 1
                    if ply.Horde_drop_entities[eClass] == 0 then
                        ply.Horde_drop_entities[eClass] = nil
                    end
                end
            end
        end
    end
    HORDE.player_drop_entities[ply:SteamID()] = {}
    ply:Horde_SetMinionCount(0)
    ply:Horde_UnsetSpellWeapon()
    ply:Horde_ApplyPerksForClass()
    if ply.Horde_Special_Armor then
        net.Start("Horde_SyncSpecialArmor")
            net.WriteString(ply.Horde_Special_Armor)
            net.WriteUInt(0, 3)
        net.Send(ply)
        ply.Horde_Special_Armor = nil
    end
    ply:Horde_UnsetGadget()
    if HORDE:ShopAllowed() then
        net.Start("Horde_ToggleShop")
        net.Send(ply)
    end

    HORDE:SendNotification("You changed class to " .. class.name, 0, ply)

    if GetConVar("horde_testing_unlimited_class_change"):GetInt() == 0 then
        HORDE.player_class_changed[ply:SteamID()] = true
    end

    HORDE:RegiveStarterWeapons(ply)

    ply:Horde_SyncEconomy()

    HORDE:TryAddTopTen(ply)
end)

net.Receive("Horde_BuyItemAmmoPrimary", function (len, ply)
    if not ply:IsValid() or not ply:Alive() or not ply.Horde_Init_Complete then return end
    if not HORDE:AllowNetRequest(ply, "buy_primary_ammo", 0.15) then return end
    if HORDE:UnarmedShopBlocked(ply) then return end
    local class = net.ReadString()
    local count = net.ReadUInt(4)
    local item = HORDE.items and HORDE.items[class]
    if not item or count < 1 then return end
    if not ply:HasWeapon(class) then
        HORDE:SendNotification("You don't have this weapon!", 0, ply)
        return
    end

    local wpn = ply:GetWeapon(class)
    local clip_size = wpn:GetMaxClip1()
    local ammo_id = wpn:GetPrimaryAmmoType()

    if clip_size > 0 then
        clip_size = clip_size
    elseif ammo_id >= 1 then
        clip_size = 1
    end

    local ammo_safe_clip = math.max(1, clip_size)
    if wpn.Primary and wpn.Primary.MaxAmmo then
        local ammo_room = wpn.Primary.MaxAmmo - ply:GetAmmoCount(ammo_id)
        if ammo_room <= 0 then return end
        local max_mags = math.floor(ammo_room / ammo_safe_clip)
        if max_mags <= 0 then return end
        if count > max_mags then
            count = max_mags
        end
    elseif count * clip_size + ply:GetAmmoCount(ammo_id) >= 9999 then
        if ply:GetAmmoCount(ammo_id) >= 9999 then return end
        count = math.ceil((9999 - ply:GetAmmoCount(ammo_id)) / ammo_safe_clip)
    end

    local ammo_price = tonumber(item.ammo_price)
    if not ammo_price or ammo_price < 0 or ammo_price ~= ammo_price then return end
    local price = ammo_price * count
    if ply:Horde_GetMoney() >= price then
        ply:Horde_AddMoney(-price)
        HORDE:GiveAmmo(ply, wpn, count)
        ply:Horde_SyncEconomy()
    end
end)

net.Receive("Horde_BuyItemAmmoSecondary", function (len, ply)
    if not ply:IsValid() or not ply:Alive() or not ply.Horde_Init_Complete then return end
    if not HORDE:AllowNetRequest(ply, "buy_secondary_ammo", 0.15) then return end
    if HORDE:UnarmedShopBlocked(ply) then return end
    local class = net.ReadString()
    local count = net.ReadUInt(4)
    local item = HORDE.items and HORDE.items[class]
    if not item or count < 1 then return end
    if not ply:HasWeapon(class) then
        HORDE:SendNotification("You don't have this weapon!", 0, ply)
        return
    end

    local wpn = ply:GetWeapon(class)
    local ammo_id = wpn:GetSecondaryAmmoType()

    if not ammo_id or ammo_id < 0 then return end

    if wpn.Secondary and wpn.Secondary.MaxAmmo and wpn.Secondary.MaxAmmo <= ply:GetAmmoCount(ammo_id) then return end
    if ply:GetAmmoCount(ammo_id) >= 9999 then return end

    local ammo_price = tonumber(item.secondary_ammo_price)
    if not ammo_price or ammo_price < 0 or ammo_price ~= ammo_price then return end
    local price = ammo_price * count
    if ply:Horde_GetMoney() >= price then
        ply:Horde_AddMoney(-price)
        ply:GiveAmmo(count, ammo_id, false)
        ply:Horde_SyncEconomy()
    end
end)

net.Receive("Horde_BuyItemUpgrade", function (len, ply)
    if not ply:IsValid() or not ply:Alive() or not ply.Horde_Init_Complete then return end
    if not HORDE:AllowNetRequest(ply, "buy_item_upgrade", 0.25) then return end
    if HORDE:UnarmedShopBlocked(ply) then return end
    if HORDE.wave666_mode then return end
    local class = net.ReadString()
    if not (HORDE.items and HORDE.items[class]) then return end
    if not ply:HasWeapon(class) then
        HORDE:SendNotification("You don't have this weapon!")
        return
    end

    local max_level = (HORDE.GetUpgradeMax and HORDE:GetUpgradeMax(ply, class)) or 10
    if ply:Horde_GetUpgrade(class) >= max_level then return end
    if HORDE.relic_no_upgrade and HORDE.relic_no_upgrade[class] then return end

    local item = HORDE.items[class]
    local is_relic = HORDE.relic_weapon_subclass and HORDE.relic_weapon_subclass[class]
    local is_gunslinger_pistol = ply:Horde_GetCurrentSubclass() == "Gunslinger"
        and item and item.category == "Pistol"
    local has_callback = item and item.OnUpgrade
    if not (is_relic or is_gunslinger_pistol or has_callback or class == "horde_pheropod") then
        return
    end

    local price = tonumber(HORDE:GetUpgradePrice(class, ply))
    if not price or price < 0 or price ~= price then return end
    if ply:Horde_GetMoney() >= price then
        ply:Horde_AddMoney(-price)
        ply:Horde_SetUpgrade(class, ply:Horde_GetUpgrade(class) + 1)
        ply:Horde_SyncEconomy()
        sound.Play("items/battery_pickup.wav", ply:GetPos())
        local item = HORDE.items[class]
        if item and item.OnUpgrade then
            item.OnUpgrade(ply, item)
        elseif class == "horde_pheropod" then
            local wep = ply:GetWeapon("horde_pheropod")
            if IsValid(wep) and wep.UpgradeReset then wep:UpgradeReset() end
        end
    end
end)

function HORDE:CanSell(ply, class)

    local item = HORDE.items[class]
    if item and item.CanSell then
        local ok, reason = item.CanSell(ply, item)
        if ok == false then
            return false, reason or "You can't sell this item!"
        end
    end

    local subclass = ply:Horde_GetSubclass(ply:Horde_GetClass().name)
    local unsellable = HORDE.subclass_unsellable_weapons[subclass]
    if unsellable then
        for _, unsellable_class in ipairs(unsellable) do
            if unsellable_class == class then
                local item_name = (HORDE.items[class] and HORDE.items[class].name) or class
                return false, "You can't sell " .. item_name .. " as " .. subclass .. " subclass!"
            end
        end
    end

    return true
end
