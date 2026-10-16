local plymeta = FindMetaTable("Player")

function plymeta:Horde_TrySpendMoney(cost)
    if not SERVER then return false end
    cost = cost or 0
    if cost <= 0 then return true end
    if self:Horde_GetMoney() < cost then return false end
    self:Horde_AddMoney(-cost)
    if self.Horde_SyncEconomy then
        self:Horde_SyncEconomy()
    end
    return true
end
