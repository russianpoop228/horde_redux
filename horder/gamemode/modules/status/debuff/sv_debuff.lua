local plymeta = FindMetaTable("Player")
local entmeta = FindMetaTable("Entity")

util.AddNetworkString("Horde_OnEnemyDebuffRemove")

function HORDE:ApplyDebuffInRadius(debuff, pos, radius, buildup, inflictor, callback)
    for _, ent in pairs(ents.FindInSphere(pos, radius)) do
        if ent:IsNPC() and HORDE:IsPlayerOrMinion(ent) ~= true then
            if ent.hit_by_aoe_buildup then continue end
            ent.hit_by_aoe_buildup = true
            ent:Horde_AddDebuffBuildup(debuff, buildup, inflictor)
            timer.Simple(0, function()
                ent.hit_by_aoe_buildup = nil
            end)
        end
    end
end

function plymeta:Horde_SetApplyDebuffDuration(duration)
    self.Horde_ApplyDebuffDuration = duration
end

function plymeta:Horde_GetApplyDebuffDuration()
    return self.Horde_ApplyDebuffDuration or 5
end

function plymeta:Horde_SetApplyDebuffMore(more)
    self.Horde_ApplyDebuffMore = more
end

function plymeta:Horde_GetApplyDebuffMore()
    return self.Horde_ApplyDebuffMore or 0
end

function plymeta:Horde_ReduceDebuffBuildup(debuff, amount)
    if not self.Horde_Debuff_Buildup[debuff] or self.Horde_Debuff_Buildup[debuff] <= 0 or self.Horde_Debuff_Active[debuff] then return end
    self.Horde_Debuff_Buildup[debuff] = math.max(0, self.Horde_Debuff_Buildup[debuff] - amount)
    net.Start("Horde_SyncStatus")
    net.WriteUInt(debuff, 8)
    net.WriteUInt(self.Horde_Debuff_Buildup[debuff], 8)
    net.Send(self)
    if debuff == HORDE.Status_Bleeding then
        local d2 = HORDE.Status_Hemorrhage
        if not self.Horde_Debuff_Buildup[d2] then return end
        self.Horde_Debuff_Buildup[d2] = math.max(0, self.Horde_Debuff_Buildup[d2] - amount)
        net.Start("Horde_SyncStatus")
        net.WriteUInt(d2, 8)
        net.WriteUInt(self.Horde_Debuff_Buildup[d2], 8)
        net.Send(self)
    end
end

function entmeta:Horde_HasDebuff(debuff)
    if self.Horde_Debuff_Active then
        return self.Horde_Debuff_Active[debuff]
    end
    return nil
end

function entmeta:Horde_GetDebuffBuildup(debuff)
    if self.Horde_Debuff_Buildup[debuff] then
        return self.Horde_Debuff_Buildup[debuff]
    end
    return 0
end

local function effect_map()
    return setmetatable({}, { __newindex = function(t, k, v)
        if k ~= nil then rawset(t, k, v) end
    end })
end
local PlayerDebuffEffects = effect_map()
local EnemyDebuffEffects  = effect_map()
local debuff_effects_built = false

local function StartShockEffect(self)
    local id = self:EntIndex()
    local bones = self:GetBoneCount()
    local bone_step = math.max(1, math.ceil((bones - 1) / 15))
    timer.Create("ShockEffect" .. id, 0.5, 0, function()
        if not self:IsValid()
            or not self.Horde_Debuff_Active
            or not self.Horde_Debuff_Active[HORDE.Status_Shock]
            or HORDE:IsPlayerSpectator(self) then
            timer.Remove("ShockEffect" .. id)
            return
        end
        for bone = 1, bones - 1, bone_step do
            local p, angle = self:GetBonePosition(bone)
            local e = EffectData()
            e:SetOrigin(p)
            util.Effect("horde_status_shock", e, true, true)
        end
    end)
end

local function BuildDebuffEffectTables()
    if debuff_effects_built then return end
    debuff_effects_built = true

    PlayerDebuffEffects[HORDE.Status_Bleeding] = function(self, duration, inflictor)
        self:Horde_AddBleedingEffect(inflictor)
    end
    PlayerDebuffEffects[HORDE.Status_Frostbite] = function(self, duration)
        self:Horde_AddFrostbiteEffect(duration)
    end
    PlayerDebuffEffects[HORDE.Status_Ignite] = function(self, duration, inflictor)
        self:Horde_AddIgniteEffect(duration, inflictor)
    end
    PlayerDebuffEffects[HORDE.Status_Break] = function(self, duration, inflictor)
        timer.Simple(0, function() self:Horde_AddBreakEffect(duration, inflictor) end)
    end
    PlayerDebuffEffects[HORDE.Status_Necrosis] = function(self)
        self:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), 1, 2.5)
        timer.Simple(2.5, function()
            if self:IsValid() then
                self:Kill()
            end
        end)
    end
    PlayerDebuffEffects[HORDE.Status_Shock] = function(self)
        StartShockEffect(self)
    end
    PlayerDebuffEffects[HORDE.Status_Hemorrhage] = function(self)
        self:Horde_ActivateHemorrhage()
    end
    PlayerDebuffEffects[HORDE.Status_Flash] = function(self, duration)
        self:Horde_AddFlashEffect(duration)
    end
    PlayerDebuffEffects[HORDE.Status_Deafenation] = function(self, duration)
        self:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 8, duration - 1)
        self:Horde_AddDeafenationEffect(duration - 1)
    end
    PlayerDebuffEffects[HORDE.Status_Numbness] = function(self, duration, inflictor)
        self:Horde_AddNumbnessEffect(duration, inflictor)
        self:ScreenFade(SCREENFADE.IN, Color(200, 200, 0, 60), 1, duration)
    end
    PlayerDebuffEffects[HORDE.Status_Insensitivity] = function(self, duration, inflictor)
        self:Horde_AddInsensitivityEffect(duration, inflictor)
        self:ScreenFade(SCREENFADE.IN, Color(53, 6, 62, 240), 1, duration)
    end

    EnemyDebuffEffects[HORDE.Status_Bleeding] = function(self, duration, inflictor)
        self:Horde_AddBleedingEffect(inflictor)
    end
    EnemyDebuffEffects[HORDE.Status_Frostbite] = function(self, duration, inflictor)
        local bonus = { increase = 0 }
        hook.Run("Horde_OnEnemyFrostbiteApply", inflictor, self, bonus)
        duration = duration * (1 + bonus.increase)
        self:Horde_AddFrostbiteEffect(duration)
    end
    EnemyDebuffEffects[HORDE.Status_Ignite] = function(self, duration, inflictor)
        self:Horde_AddIgniteEffect(duration, inflictor)
    end
    EnemyDebuffEffects[HORDE.Status_Break] = function(self, duration, inflictor)
        self:Horde_AddBreakEffect(duration, inflictor)
    end
    EnemyDebuffEffects[HORDE.Status_Necrosis] = function(self, duration, inflictor)
        local id = self:EntIndex()
        if not self.Necrosis_Stacks then
            self.Necrosis_Stacks = 0
        end
        self.Necrosis_Stacks = self.Necrosis_Stacks + 1
        timer.Create("NecrosisEffect" .. id, 0.5, 0, function()
            if not self:IsValid() then
                timer.Remove("NecrosisEffect" .. id)
                return
            end
            local ef = EffectData()
            if self:IsValid() then
                ef:SetEntity(self)
                util.Effect("horde_fear01", ef)
            end
            local dmg = DamageInfo()
            if inflictor and inflictor:IsValid() then
                dmg:SetAttacker(inflictor)
                dmg:SetInflictor(self)
            else
                dmg:SetAttacker(self)
                dmg:SetInflictor(self)
            end
            dmg:SetDamageType(DMG_DIRECT)
            dmg:SetDamageCustom(HORDE.DMG_CALCULATED)
            dmg:SetDamagePosition(self:GetPos())
            dmg:SetDamage(math.Clamp(self:Health() * 0.05, 1, 25) * self.Necrosis_Stacks)
            self:TakeDamageInfo(dmg)
        end)
    end
    EnemyDebuffEffects[HORDE.Status_Freeze] = function(self, duration)
        self:Horde_AddFreezeEffect(duration)
    end
    EnemyDebuffEffects[HORDE.Status_Shock] = function(self)
        StartShockEffect(self)
    end
    EnemyDebuffEffects[HORDE.Status_Stun] = function(self, duration)
        self:Horde_AddStun(duration)
    end
end

function entmeta:Horde_AddDebuffBuildup(debuff, buildup, inflictor, pos)
    if not IsValid(self) then return end
    if self.Horde_DebuffImmune then return end
    if self:IsPlayer() then
        if not self:Alive() then return end
        if self:GetMoveType() == MOVETYPE_OBSERVER then return end
        local obs = self:GetObserverMode()
        if obs and obs ~= OBS_MODE_NONE then return end
        if self.Horde_SpectatorGhost then return end
    end
    if inflictor and (HORDE:IsPlayerOrMinion(inflictor) == true) and (HORDE:IsPlayerOrMinion(self) == true) and inflictor ~= self then return end
    if not self.Horde_Debuff_Active then self.Horde_Debuff_Active = {} end
    if not self.Horde_Debuff_Buildup then self.Horde_Debuff_Buildup = {} end
    if not self.Horde_Debuff_Cooldown then self.Horde_Debuff_Cooldown = {} end
    if HORDE:IsStatusImmune(self, debuff) then return end
    if HORDE:IsImmuneToStatusDamageType(self, debuff) then return end
    if self.Horde_Debuff_Cooldown[debuff] then return end
    if self.Horde_Debuff_Active[debuff] then return end
    if not self.Horde_Debuff_Buildup[debuff] then self.Horde_Debuff_Buildup[debuff] = 0 end
    if self:IsPlayer() then
        if self.Horde_Debuff_Buildup[debuff] >= 100 then return end
        local bonus = { apply = 1, less = 1, add = 0 }
        local d2 = debuff
        if d2 == HORDE.Status_Hemorrhage then
            d2 = HORDE.Status_Bleeding
        end
        hook.Run("Horde_OnPlayerDebuffApply", self, d2, bonus, inflictor, buildup)
        if bonus.apply == 0 then return end
        buildup = buildup * bonus.less + bonus.add
        if buildup < 1 then return end

        if HORDE.Status_Buildup_Sounds[debuff] then
            self:EmitSound(HORDE.Status_Buildup_Sounds[debuff], 70, math.random(80, 110), 1, CHAN_AUTO)
        end
        self.Horde_Debuff_Buildup[debuff] = math.min(100, self.Horde_Debuff_Buildup[debuff] + buildup)

        local str = "Horde_RemoveBuildup_" .. tostring(debuff) .. "_" .. self:SteamID()
        timer.Create(str, 1, 0, function()
            if not self:IsValid() or not self:Alive() or self.Horde_Debuff_Active[debuff] then
                if not self:IsValid() then timer.Remove(str) end
                return
            end
            if not self.Horde_Debuff_Buildup[debuff] then return end
            self.Horde_Debuff_Buildup[debuff] = math.max(0, self.Horde_Debuff_Buildup[debuff] - 5)
            net.Start("Horde_SyncStatus")
            net.WriteUInt(debuff, 8)
            net.WriteUInt(self.Horde_Debuff_Buildup[debuff], 8)
            net.Send(self)
        end)

        net.Start("Horde_SyncStatus")
        net.WriteUInt(debuff, 8)
        net.WriteUInt(self.Horde_Debuff_Buildup[debuff], 8)
        net.Send(self)

        if self.Horde_Debuff_Buildup[debuff] < 100 then return end
    else
        local threshold = self.Horde_Debuff_Threshold or 100
        if self.Horde_Debuff_Buildup[debuff] >= threshold then return end
        local bonus = { apply = 1, more = 1, increase = 0 }
        if inflictor and inflictor:IsValid() and inflictor:IsPlayer() then
            hook.Run("Horde_OnEnemyDebuffApply", self, debuff, bonus, inflictor, buildup)
        end
        if bonus.apply == 0 then return end
        buildup = buildup * bonus.more * (1 + bonus.increase)
        if buildup < 1 then return end

        if HORDE.Status_Buildup_Sounds[debuff] then
            sound.Play(HORDE.Status_Buildup_Sounds[debuff], self:GetPos(), 100, math.random(80, 110))
        end
        self.Horde_Debuff_Buildup[debuff] = math.min(threshold, self.Horde_Debuff_Buildup[debuff] + buildup)

        if self.Horde_Debuff_Buildup[debuff] < threshold then return end
    end

    if HORDE.Status_Trigger_Sounds[debuff] then
        sound.Play(HORDE.Status_Trigger_Sounds[debuff], self:GetPos())
    end

    if not pos then pos = self:GetPos() + self:OBBCenter() end
    local is_player = self:IsPlayer()
    if (debuff == HORDE.Status_Frostbite) or (debuff == HORDE.Status_Freeze) then
        local effectdata = EffectData()
        effectdata:SetOrigin(pos)
        effectdata:SetScale(10)
        effectdata:SetMagnitude(10)
        util.Effect("GlassImpact", effectdata, true, true)
        util.Effect("GlassImpact", effectdata, true, true)
    elseif (not is_player) and debuff == HORDE.Status_Shock then
        local data = EffectData();
        data:SetOrigin(pos)
        util.Effect("StunstickImpact", data);
    elseif (not is_player) and debuff == HORDE.Status_Bleeding then
        local data = EffectData()
        data:SetOrigin(pos)
        data:SetRadius(50)
        util.Effect("horde_hemo_mist", data, true, true)
    end

    if self:IsPlayer() then
        local apply = hook.Run("Horde_PrePlayerDebuffApply", self, debuff)
        if apply ~= nil then
            for d, b in pairs(self.Horde_Debuff_Buildup) do
                self:Horde_RemoveDebuff(d)
                self:Horde_ReduceDebuffBuildup(d, b)
            end
            return
        end

        local duration = 5 + HORDE.difficulty_status_duration_bonus[HORDE.difficulty]
        local str = "Horde_Remove_" .. tostring(debuff) .. "_" .. self:SteamID()
        timer.Remove(str)
        timer.Create(str, duration, 1, function()
            self:Horde_RemoveDebuff(debuff)
        end)

        BuildDebuffEffectTables()
        local apply_effect = PlayerDebuffEffects[debuff]
        if apply_effect then apply_effect(self, duration, inflictor) end

        if not self.Horde_Debuff_Active[debuff] then
            HORDE:SendNotificationDebuff(debuff, self)
        end

        self.Horde_Debuff_Active[debuff] = true
    else
        local duration = 5
        local str = "Horde_Remove_" .. tostring(debuff) .. "_" .. self:GetCreationID()
        timer.Remove(str)
        timer.Create(str, duration, 1, function()
            self:Horde_RemoveDebuff(debuff)
        end)

        BuildDebuffEffectTables()
        local apply_effect = EnemyDebuffEffects[debuff]
        if apply_effect then apply_effect(self, duration, inflictor) end

        self.Horde_Debuff_Active[debuff] = true

        hook.Run("Horde_PostEnemyDebuffApply", self, inflictor, debuff, pos)
    end
end

function entmeta:Horde_RemoveDebuff(debuff)
    if not self:IsValid() or not self.Horde_Debuff_Active[debuff] then return end
    self.Horde_Debuff_Active[debuff] = nil
    self.Horde_Debuff_Buildup[debuff] = 0
    if self:IsPlayer() then
        net.Start("Horde_SyncStatus")
        net.WriteUInt(debuff, 8)
        net.WriteUInt(0, 8)
        net.Send(self)

        if debuff == HORDE.Status_Hemorrhage then
            local id = self:GetCreationID()
            timer.Remove("Horde_HemorrhageLoop" .. id)
        end
        if debuff == HORDE.Status_Bleeding and self.Horde_RemoveBleedingEffect then
            self:Horde_RemoveBleedingEffect()
        end
    else
        self.Horde_Debuff_Cooldown[debuff] = true
        if debuff == HORDE.Status_Stun then
            timer.Simple(5, function()
                if not self:IsValid() then return end
                self.Horde_Debuff_Cooldown[debuff] = nil
            end)
        else
            timer.Simple(3, function()
                if not self:IsValid() then return end
                self.Horde_Debuff_Cooldown[debuff] = nil
            end)
        end

        hook.Run("Horde_OnEnemyDebuffRemove", self, self.Horde_Debuff_Active)
    end
end

function HORDE:ClearPlayerDebuffs(ply)
    if not IsValid(ply) then return end
    local active = ply.Horde_Debuff_Active
    if active then
        local list = {}
        for debuff, on in pairs(active) do
            if on then list[#list + 1] = debuff end
        end
        for _, debuff in ipairs(list) do
            ply:Horde_RemoveDebuff(debuff)
        end
    end
    if ply.Horde_Debuff_Buildup then
        for debuff, _ in pairs(ply.Horde_Debuff_Buildup) do
            ply.Horde_Debuff_Buildup[debuff] = 0
            timer.Remove("Horde_RemoveBuildup_" .. tostring(debuff) .. "_" .. ply:SteamID())
        end
    end
    if ply.Horde_RemoveBleedingEffect then ply:Horde_RemoveBleedingEffect() end
    ply.Horde_Debuff_Active = {}
    ply.Horde_Debuff_Buildup = {}
end

hook.Add("Horde_ResetStatus", "Horde_PlayerStatusReset", function(ply)
    HORDE:ClearPlayerDebuffs(ply)
end)

hook.Add("Horde_OnEnemyDebuffRemove", "Horde_RemoveSync", function(ent, debuffs)
    net.Start("Horde_OnEnemyDebuffRemove")
    net.WriteEntity(ent)
    net.WriteTable(debuffs)
    net.Broadcast()
end)
