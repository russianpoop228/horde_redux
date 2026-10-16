local plymeta = FindMetaTable("Player")

function plymeta:Horde_SetApplyBuffDuration(duration)
    self.Horde_ApplyBuffDuration = duration
end

function plymeta:Horde_GetApplyBuffDuration()
    return (self.Horde_ApplyBuffDuration or 5) * HORDE:GetPerkMultiplier(self, "ApplyBuffDurationMult")
end

function plymeta:Horde_SetApplyBuffMore(more)
    self.Horde_ApplyBuffMore = more
end

function plymeta:Horde_GetApplyBuffMore()
    if self:Horde_GetPerk("medic_xcele") then return 1 end
    return self.Horde_ApplyBuffMore or 0
end
