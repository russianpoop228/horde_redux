local entmeta = FindMetaTable("Entity")

local TICK_INTERVAL = 0.5

local function BleedingFxPositions(ent)
    local origin = ent:GetPos()
    local positions = {}

    if ent:IsPlayer() then
        return { ent:WorldSpaceCenter() }
    end

    local bones = ent:GetBoneCount() or 0
    if bones > 1 then
        local step = math.max(1, math.floor((bones - 1) / 3))
        for bone = 1, bones - 1, step do
            local p = ent:GetBonePosition(bone)
            if p and p:DistToSqr(origin) > 16 and p:DistToSqr(origin) < (200 * 200) then
                positions[#positions + 1] = p
                if #positions >= 3 then break end
            end
        end
    end
    if #positions == 0 then
        positions[1] = origin + Vector(0, 0, 40)
    end
    return positions
end

local function EmitBleedingFx(ent)
    for _, p in ipairs(BleedingFxPositions(ent)) do
        local e = EffectData()
        e:SetOrigin(p)
        e:SetScale(1)
        e:SetMagnitude(1)
        e:SetRadius(18)
        util.Effect("horde_status_bleeding", e, true, true)
    end
end

local function BleedingStillActive(ent)
    if not IsValid(ent) then return false end
    if ent:IsPlayer() then
        if not ent:Alive() then return false end
        if ent.Horde_DebuffImmune then return false end
        if ent.Horde_Fake_Respawn then return false end
        if HORDE:IsPlayerSpectator(ent) then return false end
    else
        if ent:Health() <= 0 then return false end
    end
    if not ent.Horde_Debuff_Active or not ent.Horde_Debuff_Active[HORDE.Status_Bleeding] then
        return false
    end
    return true
end

function entmeta:Horde_AddBleedingEffect(inflictor)
    if not IsValid(self) then return end
    if HORDE:IsStatusImmune(self, HORDE.Status_Bleeding) then return end
    if self:IsPlayer() then
        if not self:Alive() or self.Horde_DebuffImmune or self.Horde_Fake_Respawn
            or HORDE:IsPlayerSpectator(self) then return end
    elseif self:Health() <= 0 then
        return
    end

    if self:IsPlayer() then
        local id = "Horde_BleedingEffect" .. self:SteamID()
        local dmg_per_tick = self:GetMaxHealth() * 0.02

        timer.Create(id, TICK_INTERVAL, 0, function()
            if not BleedingStillActive(self) then
                timer.Remove(id)
                return
            end

            local dmg = DamageInfo()
            if IsValid(inflictor) then
                dmg:SetAttacker(inflictor)
                dmg:SetInflictor(inflictor)
            else
                dmg:SetAttacker(Entity(0))
                dmg:SetInflictor(Entity(0))
            end
            dmg:SetDamageType(DMG_DIRECT)
            dmg:SetDamage(dmg_per_tick)
            dmg:SetDamagePosition(self:WorldSpaceCenter())
            self:TakeDamageInfo(dmg)

            if not BleedingStillActive(self) then
                timer.Remove(id)
                return
            end

            self:EmitSound("player/pl_pain5.wav", 60, 100, 0.6, CHAN_AUTO)
            EmitBleedingFx(self)
        end)
    else
        local cur_hp = math.max(self:Health(), 1)
        local max_hp = math.max(self:GetMaxHealth(), 1)
        local perc_health = cur_hp * 0.01
        local mult = math.Clamp(max_hp / cur_hp, 1, 10)
        local base_dmg = 30 * mult + perc_health
        local timer_id = "Horde_BleedingEffect" .. self:GetCreationID()

        timer.Create(timer_id, TICK_INTERVAL, 0, function()
            if not BleedingStillActive(self) then
                timer.Remove(timer_id)
                return
            end

            local dmg = DamageInfo()
            if IsValid(inflictor) then
                dmg:SetAttacker(inflictor)
                dmg:SetInflictor(self)
            else
                dmg:SetAttacker(self)
                dmg:SetInflictor(self)
            end
            dmg:SetDamagePosition(self:GetPos())
            dmg:SetDamageType(DMG_CRUSH)
            dmg:SetDamage(base_dmg)
            self:TakeDamageInfo(dmg)

            self:EmitSound("player/pl_pain5.wav", 60, 100, 0.5, CHAN_AUTO)
            EmitBleedingFx(self)
        end)
    end
end

function entmeta:Horde_RemoveBleedingEffect()
    if not IsValid(self) then return end
    if self:IsPlayer() then
        timer.Remove("Horde_BleedingEffect" .. self:SteamID())
    else
        timer.Remove("Horde_BleedingEffect" .. self:GetCreationID())
    end
end
