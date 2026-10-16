local entmeta = FindMetaTable("Entity")

local STUN_DURATION_NORMAL = 5
local STUN_DURATION_BOSS   = 0.5

function entmeta:Horde_AddStun(duration)
    if not IsValid(self) then return end
    if (self:IsPlayer() and not self:Alive()) or HORDE:IsPlayerSpectator(self) then return end
    if HORDE:IsStatusImmune(self, HORDE.Status_Stun) then return end
    if self.Horde_Stunned then return end

    local is_boss = self:GetVar("is_boss") == true
    local dur = duration
    if not dur or dur <= 0 then
        dur = is_boss and STUN_DURATION_BOSS or STUN_DURATION_NORMAL
    elseif is_boss then
        dur = math.min(dur, STUN_DURATION_BOSS)
    end

    if self:IsPlayer() then
        self.Horde_Stunned = true
        timer.Create("Horde_RemoveStun" .. self:GetCreationID(), dur, 1, function()
            if not IsValid(self) then return end
            self.Horde_Stunned = nil
        end)
        return
    end

    if self:Health() <= 0 then return end

    if not self.Base then
        self:NextThink(CurTime() + dur)
    elseif self.Base == "npc_vj_creature_base" or self.Base == "npc_vj_human_base" then
        self:SetSchedule(SCHED_NPC_FREEZE)
        self:NextThink(CurTime() + dur)
        self.Horde_Stunned = true
        timer.Create("Horde_RemoveStun" .. self:GetCreationID(), dur, 1, function()
            if not IsValid(self) then return end
            self:SetCondition(68)
            self.Horde_Stunned = nil
        end)
    end
end
