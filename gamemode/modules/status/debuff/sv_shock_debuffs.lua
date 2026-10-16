local entmeta = FindMetaTable("Entity")

function entmeta:Horde_AddDeafenationEffect(duration)
    if not self:IsPlayer() then
        local cid = self:GetCreationID()
        timer.Remove("Horde_RemoveDeafenation" .. cid)
        timer.Create("Horde_RemoveDeafenation" .. cid, duration, 1, function()
            if IsValid(self) then self:Horde_RemoveDeafenation() end
        end)
        self.Horde_Deafenation = 1
    end

    local soundir = "ambient/creatures/"
    for _ = 1, 6 do EmitSound(soundir .. "town_muffled_cry1.wav", self:GetPos(), -1) end

    local id = self:EntIndex()
    self:SetDSP(7, false)

    timer.Create("DeafenationDSP" .. id, 0.1, 0, function()
        if not IsValid(self)
            or (self:IsPlayer() and not self:Alive())
            or HORDE:IsPlayerSpectator(self)
            or not self.Horde_Debuff_Active
            or not self.Horde_Debuff_Active[HORDE.Status_Deafenation]
        then
            timer.Remove("DeafenationDSP" .. id)
            if IsValid(self) then self:SetDSP(1, false) end
            return
        end
        self:SetDSP(7, false)
    end)

    timer.Create("DeafenationEffect" .. id, 1.6, 0, function()
        if not IsValid(self)
            or (self:IsPlayer() and not self:Alive())
            or HORDE:IsPlayerSpectator(self)
            or not self.Horde_Debuff_Active
            or not self.Horde_Debuff_Active[HORDE.Status_Deafenation]
        then
            timer.Remove("DeafenationEffect" .. id)
            return
        end
        local num = math.random(1, 2)
        local snd = (math.random(1, 2) == 1)
            and (soundir .. "town_scared_sob" .. num .. ".wav")
            or  (soundir .. "town_scared_breathing" .. num .. ".wav")
        for _ = 1, 6 do EmitSound(snd, self:GetPos(), -1) end
    end)
end

function entmeta:Horde_RemoveDeafenation()
    if not IsValid(self) then return end
    local id = self:EntIndex()
    timer.Remove("DeafenationEffect" .. id)
    timer.Remove("DeafenationDSP" .. id)
end

function entmeta:Horde_AddInsensitivityEffect(duration, inflictor)
    if not self:IsPlayer() then
        local cid = self:GetCreationID()
        timer.Remove("Horde_RemoveInsensitivity" .. cid)
        timer.Create("Horde_RemoveInsensitivity" .. cid, duration, 1, function()
            if IsValid(self) then self:Horde_RemoveInsensitivity() end
        end)
        self.Horde_Insensitivity = 1
    end

    local id    = self:EntIndex()
    local bones = self:GetBoneCount()
    self:SetFOV(40, 0.5, self)
    self:SetDSP(31, false)
    self:Flashlight(false)

    local bone_step = math.max(1, math.ceil((bones - 1) / 15))

    timer.Create("InsensitivityEffect" .. id, 0.5, 0, function()
        if not IsValid(self)
            or (self:IsPlayer() and not self:Alive())
            or HORDE:IsPlayerSpectator(self)
            or not self.Horde_Debuff_Active
            or not self.Horde_Debuff_Active[HORDE.Status_Insensitivity]
        then
            timer.Remove("InsensitivityEffect" .. id)
            return
        end
        for bone = 1, bones - 1, bone_step do
            local pos = self:GetBonePosition(bone)
            local ed  = EffectData()
            ed:SetOrigin(pos)
            ed:SetScale(1)
            ed:SetMagnitude(1)
            ed:SetRadius(18)
            util.Effect("GlassImpact", ed, true, true)
            util.Effect("horde_status_insensitivity", ed, true, true)
        end
    end)

    timer.Create("InsensitivityFOV" .. id, 0.5, 0, function()
        if not IsValid(self)
            or (self:IsPlayer() and not self:Alive())
            or HORDE:IsPlayerSpectator(self)
            or not self.Horde_Debuff_Active
            or not self.Horde_Debuff_Active[HORDE.Status_Insensitivity]
        then
            timer.Remove("InsensitivityFOV" .. id)
            if IsValid(self) then
                self:SetFOV(0, 0.5, self)
                self:SetDSP(1, false)
            end
            return
        end
        if self:FlashlightIsOn() then
            local dmg = DamageInfo()
            if inflictor and IsValid(inflictor) then
                dmg:SetAttacker(inflictor)
                dmg:SetInflictor(inflictor)
            else
                dmg:SetAttacker(Entity(0))
                dmg:SetInflictor(Entity(0))
            end
            dmg:SetDamagePosition(self:GetPos())
            dmg:SetDamageType(DMG_CRUSH)
            dmg:SetDamage(self:GetMaxHealth() * 0.05)
            self:TakeDamageInfo(dmg)
            sound.Play("ambient/energy/zap" .. math.random(1, 7) .. ".wav", self:GetPos())
        end
    end)
end

function entmeta:Horde_RemoveInsensitivity()
    if not IsValid(self) then return end
    local id = self:EntIndex()
    timer.Remove("InsensitivityEffect" .. id)
    timer.Remove("InsensitivityFOV" .. id)
end

function entmeta:Horde_AddNumbnessEffect(duration, inflictor)
    if not self:IsPlayer() then
        local cid = self:GetCreationID()
        timer.Remove("Horde_RemoveNumbness" .. cid)
        timer.Create("Horde_RemoveNumbness" .. cid, duration, 1, function()
            if IsValid(self) then self:Horde_RemoveNumbness() end
        end)
        self.Horde_Numbness = 1
    end

    local id    = self:EntIndex()
    local bones = self:GetBoneCount()
    self:SetFOV(55, 0.5, self)
    self:SetDSP(30, false)
    self:Flashlight(false)

    local bone_step = math.max(1, math.ceil((bones - 1) / 15))

    timer.Create("NumbnessEffect" .. id, 0.5, 0, function()
        if not IsValid(self)
            or (self:IsPlayer() and not self:Alive())
            or HORDE:IsPlayerSpectator(self)
            or not self.Horde_Debuff_Active
            or not self.Horde_Debuff_Active[HORDE.Status_Numbness]
        then
            timer.Remove("NumbnessEffect" .. id)
            return
        end
        for bone = 1, bones - 1, bone_step do
            local pos = self:GetBonePosition(bone)
            local ed  = EffectData()
            ed:SetOrigin(pos)
            ed:SetScale(1)
            ed:SetMagnitude(1)
            ed:SetRadius(18)
            util.Effect("GlassImpact", ed, true, true)
            util.Effect("horde_status_shock", ed, true, true)
        end
    end)

    timer.Create("NumbnessFOV" .. id, 0.5, 0, function()
        if not IsValid(self)
            or (self:IsPlayer() and not self:Alive())
            or HORDE:IsPlayerSpectator(self)
            or not self.Horde_Debuff_Active
            or not self.Horde_Debuff_Active[HORDE.Status_Numbness]
        then
            timer.Remove("NumbnessFOV" .. id)
            if IsValid(self) then
                self:SetFOV(0, 0.5, self)
                self:SetDSP(1, false)
            end
            return
        end
        if self:FlashlightIsOn() then
            local dmg = DamageInfo()
            if inflictor and IsValid(inflictor) then
                dmg:SetAttacker(inflictor)
                dmg:SetInflictor(inflictor)
            else
                dmg:SetAttacker(Entity(0))
                dmg:SetInflictor(Entity(0))
            end
            dmg:SetDamagePosition(self:GetPos())
            dmg:SetDamageType(DMG_CRUSH)
            dmg:SetDamage(self:GetMaxHealth() * 0.02)
            self:TakeDamageInfo(dmg)
            sound.Play("weapons/stunstick/stunstick_fleshhit1.wav", self:GetPos())
        end
    end)
end

function entmeta:Horde_RemoveNumbness()
    if not IsValid(self) then return end
    local id = self:EntIndex()
    timer.Remove("NumbnessEffect" .. id)
    timer.Remove("NumbnessFOV" .. id)
end

hook.Add("Horde_OnPlayerDamage", "DH_NumbnessDamage", function(ply, npc, bonus, hitgroup)
    if not ply.Horde_Debuff_Active then return end
    if ply.Horde_Debuff_Active[HORDE.Status_Numbness] then
        bonus.increase = bonus.increase - 0.2
    elseif ply.Horde_Debuff_Active[HORDE.Status_Insensitivity] then
        bonus.increase = bonus.increase - 0.4
    end
end)

hook.Add("EntityTakeDamage", "DH_NumbnessDamageTaken", function(target, dmg)
    if not target.Horde_Debuff_Active then return end
    local diff = HORDE.difficulty
    local inc  = HORDE.difficulty_shock_damage_increase
    if not diff or not inc then return end
    if target.Horde_Debuff_Active[HORDE.Status_Numbness] then
        dmg:ScaleDamage(1 + inc[diff] * 1.35)
    end
    if target.Horde_Debuff_Active[HORDE.Status_Insensitivity] then
        dmg:ScaleDamage(1 + inc[diff] * 1.65)
    end
end)

hook.Add("Horde_PlayerMoveBonus", "DH_ShockMoveSpeed", function(ply, bonus_walk, bonus_run)
    if not ply.Horde_Debuff_Active then return end
    local diff = HORDE.difficulty
    local slow = HORDE.difficulty_frostbite_slow
    if not diff or not slow then return end
    if ply.Horde_Debuff_Active[HORDE.Status_Numbness] then
        bonus_walk.more = bonus_walk.more * (slow[diff] * 1.5)
        bonus_run.more  = bonus_run.more  * 0.75 * (slow[diff] * 1.5)
    elseif ply.Horde_Debuff_Active[HORDE.Status_Insensitivity] then
        bonus_walk.more = bonus_walk.more * (slow[diff] * 1.25)
        bonus_run.more  = bonus_run.more  * 0.75 * (slow[diff] * 1.25)
    end
end)
