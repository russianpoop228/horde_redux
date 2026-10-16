util.AddNetworkString("Horde_Perk")
util.AddNetworkString("Horde_PerkChoice")
util.AddNetworkString("Horde_SyncPerk")

local plymeta = FindMetaTable("Player")

function plymeta:Horde_ApplyPerksForClass()
    if GetConVar("horde_enable_perk"):GetInt() ~= 1 then
        self.Horde_PerksPendingApply = nil
        return
    end
    self.Horde_PerksRefreshing = true
    self.Horde_Spectre_Max_Count = 1
    local class = HORDE.Class_Survivor
    if self:Horde_GetClass() then
        class = self:Horde_GetClass().name
    end

    local subclass = HORDE.subclasses[self:Horde_GetSubclass(class)]
    local perks = HORDE.classes[class].perks
    if subclass and subclass.ParentClass then
        class = subclass.PrintName
        perks = subclass.Perks
    end

    self:Horde_ClearPerks()

    if subclass and subclass.ParentClass then
        self:Horde_SetPerk(subclass.BasePerk)
    else
        self:Horde_SetPerk(self:Horde_GetClass().base_perk)
    end

    self.Horde_PerkChoices = self.Horde_PerkChoices or {}
    self.Horde_PerkChoices[class] = self.Horde_PerkChoices[class] or {}

    for perk_level, v in pairs(perks) do
        if HORDE.current_wave < HORDE:Horde_GetWaveForPerk(perk_level) then goto cont end
        local c = math.min(2, math.max(1, self.Horde_PerkChoices[class][perk_level] or 1))
        local choice = v.choices[c]
        if not choice then error("Invalid choice in perk level " .. perk_level .. " for " .. class .. "!") return end
        if self:Horde_GetPerk(choice) then goto cont end
        self:Horde_SetPerk(choice)
        ::cont::
    end

    hook.Run("Horde_OnPerksApplied", self)

    self:Horde_SetMaxHealth()
    self:Horde_SetMaxArmor()
    if self:Horde_GetSpellWeapon() then
        self:Horde_RecalcAndSetMaxMind()
    else
        self:Horde_SetMaxMind(0)
        self:Horde_SetMind(0)
    end

    net.Start("Horde_SyncPerk")
        net.WriteEntity(self)
        net.WriteTable(self.Horde_PerkChoices[class])
    net.Broadcast()

    if self:Alive() then
        self.Horde_PerksPendingApply = nil
    end

    self.Horde_PerksRefreshing = nil
end

net.Receive("Horde_PerkChoice", function(len, ply)
    if GetConVar("horde_enable_perk"):GetInt() ~= 1 then return end
    local joining = not ply.Horde_Init_Complete
    if joining then
        ply.Horde_JoinPerkChoiceCount = (ply.Horde_JoinPerkChoiceCount or 0) + 1
        if ply.Horde_JoinPerkChoiceCount > 8 then return end
    elseif not HORDE:AllowNetRequest(ply, "perk_choice", 0.25) then
        return
    end
    local class = net.ReadString()
    local subclass = HORDE.subclasses and HORDE.subclasses[class]
    if not subclass then return end
    if not joining then
        if subclass.ParentClass and ply:Horde_GetSubclassUnlocked(class) ~= true then return end
        if (HORDE.current_break_time or 0) <= 0 then return end
    end
    local is_active_subclass = ply:Horde_GetClass() ~= nil and ply:Horde_GetCurrentSubclass() == class
    local subclass_name = subclass.PrintName
    local perks
    if subclass.ParentClass then
        perks = subclass.Perks
    else
        local class_data = HORDE.classes and HORDE.classes[class]
        if not class_data then return end
        perks = class_data.perks
    end
    if not istable(perks) then return end

    local level = net.ReadUInt(4)
    local choices = {}
    if level == 0 then
        for perk_level, tier in SortedPairs(perks) do
            local choice = net.ReadUInt(4)
            if not tier or not tier.choices or #tier.choices < 1 then continue end
            choices[perk_level] = math.Clamp(choice, 1, #tier.choices)
        end
    else
        local tier = perks[level]
        if not tier or not tier.choices then return end
        local choice = net.ReadUInt(4)
        if choice < 1 or choice > #tier.choices then return end
        choices[level] = choice
    end

    ply.Horde_PerkChoices = ply.Horde_PerkChoices or {}
    local current = ply.Horde_PerkChoices[subclass_name] or {}
    local changed = false
    for perk_level, choice in pairs(choices) do
        if current[perk_level] ~= choice then changed = true end
    end
    local updated = current
    if changed then
        updated = table.Copy(current)
        for perk_level, choice in pairs(choices) do updated[perk_level] = choice end
        ply.Horde_PerkChoices[subclass_name] = updated
    end

    if joining or not is_active_subclass then return end
    net.Start("Horde_SyncPerk")
        net.WriteEntity(ply)
        net.WriteTable(updated)
    net.Broadcast()
    ply:Horde_SetMaxHealthOnly()
    ply:Horde_SetMaxArmor()
    timer.Simple(0.1, function()
        if ply:Horde_GetSpellWeapon() then
            ply:Horde_RecalcAndSetMaxMind()
        else
            ply:Horde_SetMaxMind(0)
            ply:Horde_SetMind(0)
        end
    end)

    if level == 0 then return end
    if HORDE.current_wave < HORDE:Horde_GetWaveForPerk(level) then return end

    if class == ply:Horde_GetSubclass(ply:Horde_GetClass().name) then
        for c, perk in pairs(perks[level].choices) do
            local has_perk = ply:Horde_GetPerk(perk)
            if c == ply.Horde_PerkChoices[class][level] and (not has_perk)then
                ply:Horde_SetPerk(perk)
            elseif c ~= ply.Horde_PerkChoices[class][level] and has_perk then
                ply:Horde_UnsetPerk(perk)
            end
        end
    end
end)
