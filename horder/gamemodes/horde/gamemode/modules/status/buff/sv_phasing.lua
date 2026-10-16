local plymeta = FindMetaTable("Player")

function plymeta:Horde_AddPhasing(duration, callback)
    timer.Remove("Horde_RemovePhasing" .. self:SteamID())
    timer.Create("Horde_RemovePhasing" .. self:SteamID(), duration, 1, function ()
        if !self:IsValid() then return end
        self:Horde_RemovePhasing()
        callback()
    end)

    if self.Horde_Phasing then return end

    self.Horde_Phasing = true
    self:CollisionRulesChanged()
end

function plymeta:Horde_RemovePhasing()
    if not self:IsValid() then return end
    if !self.Horde_Phasing then return end
    self.Horde_Phasing = nil
    self:CollisionRulesChanged()
end

function plymeta:Horde_GetPhasing()
    return self.Horde_Phasing
end

hook.Add("Horde_ShouldCollide", "Horde_Phasing_Collide", function (ent1, ent2)
    if not IsValid(ent1) or not IsValid(ent2) then return end

    local ply, npc
    if ent1:IsPlayer() then
        ply, npc = ent1, ent2
    elseif ent2:IsPlayer() then
        ply, npc = ent2, ent1
    else
        return
    end

    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(npc) or not (npc:IsNPC() or npc:IsNextBot()) then return end

    if ply.Horde_GetPhasing and ply:Horde_GetPhasing() then
        hook.Run("Horde_OnPhasingCollide", ply, npc)
        return false
    end
end)

hook.Add("Horde_ResetStatus", "Horde_PhasingReset", function(ply)
    if IsValid(ply) then ply:Horde_RemovePhasing() end
end)
