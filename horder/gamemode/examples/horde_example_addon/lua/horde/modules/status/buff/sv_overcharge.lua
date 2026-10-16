local plymeta = FindMetaTable("Player")

local MAX_STACKS = 5
local DECAY = 5

local function Sync(ply)
    ply:Horde_SyncStatus(HORDE.Status_Overcharge, ply.Horde_OverchargeStack or 0)
end

function plymeta:Horde_GetOverchargeStack()
    return self.Horde_OverchargeStack or 0
end

function plymeta:Horde_AddOverchargeStack()
    self.Horde_OverchargeStack = math.min(MAX_STACKS, self:Horde_GetOverchargeStack() + 1)
    Sync(self)
    timer.Create("Horde_OverchargeDecay" .. self:SteamID64(), DECAY, 1, function()
        if IsValid(self) then self:Horde_RemoveOverchargeStack() end
    end)
end

function plymeta:Horde_RemoveOverchargeStack()
    self.Horde_OverchargeStack = math.max(0, self:Horde_GetOverchargeStack() - 1)
    Sync(self)
    if self.Horde_OverchargeStack > 0 then
        timer.Create("Horde_OverchargeDecay" .. self:SteamID64(), DECAY, 1, function()
            if IsValid(self) then self:Horde_RemoveOverchargeStack() end
        end)
    end
end

function plymeta:Horde_ClearOvercharge()
    timer.Remove("Horde_OverchargeDecay" .. self:SteamID64())
    self.Horde_OverchargeStack = 0
    Sync(self)
end

hook.Add("Horde_OnPlayerDamage", "Example_Overcharge", function(ply, npc, bonus, hitgroup, dmginfo)
    local stacks = ply.Horde_OverchargeStack
    if stacks and stacks > 0 then
        bonus.increase = bonus.increase + stacks * 0.05
    end
end)

hook.Add("Horde_ResetStatus", "Example_Overcharge", function(ply)
    timer.Remove("Horde_OverchargeDecay" .. ply:SteamID64())
    ply.Horde_OverchargeStack = 0
end)
