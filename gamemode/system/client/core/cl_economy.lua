local plymeta = FindMetaTable("Player")

function plymeta:Horde_GetMoney()
    return self.Horde_money or 0
end

function plymeta:Horde_GetSkullTokens()
    return self.Horde_skull_tokens or 0
end

function plymeta:Horde_GetWeight()
    return self.Horde_weight or 0
end

function plymeta:Horde_GetMaxWeight()
    return self.Horde_max_weight or 0
end

function plymeta:Horde_GetDropEntities()
    return self.Horde_drop_entities
end

net.Receive("Horde_SyncEconomy", function(length)
    local ply = net.ReadEntity()
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local money = net.ReadInt(32)
    local skull_tokens = net.ReadInt(32)
    local weight = net.ReadInt(32)
    if money == nil or skull_tokens == nil or weight == nil then return end

    local subclass = net.ReadString()
    local drop_entities = net.ReadTable()

    local class = HORDE.subclasses_to_classes[subclass]
    local prev_money = ply.Horde_money or 0
    ply.Horde_money = money
    ply.Horde_skull_tokens = skull_tokens
    ply.Horde_weight = weight
    ply.Horde_class = HORDE.classes[class]
    if not ply.Horde_subclasses then ply.Horde_subclasses = {} end
    if class then ply.Horde_subclasses[class] = subclass end
    ply.Horde_drop_entities = drop_entities

    if MySelf == ply then
        HORDE:PlayMoneyNotification(money - prev_money, money)
    end
end)

net.Receive("Horde_SyncMaxWeight", function (len, ply)
    local max_weight = net.ReadUInt(5)
    MySelf.Horde_max_weight = max_weight
end)
