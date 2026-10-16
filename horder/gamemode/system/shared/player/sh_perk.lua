HORDE.NET_PERK_SET = 1
HORDE.NET_PERK_UNSET = 2
HORDE.NET_PERK_CLEAR = 3

HORDE.NET_PERK_BITS = 2

HORDE.perks = HORDE.perks or {}

if SERVER then
util.AddNetworkString("Horde_PerkStartCooldown")
util.AddNetworkString("Horde_PerkChargesUpdate")
util.AddNetworkString("Horde_PerkCooldownCheck")
end

if CLIENT then
    net.Receive("Horde_Perk", function()
        if GetConVar("horde_enable_perk"):GetInt() ~= 1 then return end
        local mode = net.ReadUInt(HORDE.NET_PERK_BITS)
        local ply = net.ReadEntity()
        if not ply:IsValid() then return end
        ply.Horde_Perks = ply.Horde_Perks or {}
        if mode == HORDE.NET_PERK_SET then
            local perk = net.ReadString()
            ply:Horde_SetPerk(perk)
        elseif mode == HORDE.NET_PERK_UNSET then
            local perk = net.ReadString()
            ply:Horde_UnsetPerk(perk)
        elseif mode == HORDE.NET_PERK_CLEAR then
            ply:Horde_ClearPerks()
        end
    end)

    net.Receive("Horde_SyncPerk", function ()
        local ply = net.ReadEntity()
        local perk_choices = net.ReadTable()
        if ply ~= MySelf then
            if !IsValid(ply) then return end
            if not ply.Horde_PerkChoices then ply.Horde_PerkChoices = {} end
            if not ply:Horde_GetCurrentSubclass() then return end
            ply.Horde_PerkChoices[ply:Horde_GetCurrentSubclass()] = perk_choices
        end
    end)

    function HORDE:SendSavedPerkChoices(class)
        local tbl = MySelf.Horde_PerkChoices
        if not tbl or table.IsEmpty(tbl) then
            local f = HORDE.Prefs and HORDE.Prefs.Get("perk_choices")
            local saved = f and util.JSONToTable(f)
            if saved then
                MySelf.Horde_PerkChoices = saved
                tbl = saved
            end
        end

        net.Start("Horde_PerkChoice")
            net.WriteString(class)
            net.WriteUInt(0, 4)
            for perk_level = 1,4 do
                if not tbl or not tbl[class] then
                    net.WriteUInt(1, 4)
                else
                    net.WriteUInt(tbl[class][perk_level] or 1, 4)
                end
            end
        net.SendToServer()
    end
    net.Receive("Horde_PerkChoice", function() HORDE:SendSavedPerkChoices(MySelf:Horde_GetCurrentSubclass()) end)
end

function HORDE:IsWave666Mode()
    if HORDE.wave666_mode == true then return true end
    local name = HORDE.difficulty_text and HORDE.difficulty_text[HORDE.difficulty]
    if name == "WAVE_666" then return true end
    local d = HORDE._difficulties and HORDE._difficulties[HORDE.difficulty]
    if istable(d) and d.IsWave666 then return true end
    return false
end

function HORDE:Horde_GetWaveForPerk(perk_level)
    if HORDE:IsWave666Mode() then return 0 end
    if HORDE.IsPurismMode and HORDE:IsPurismMode() then return 9999 end
    return GetConVar("horde_perk_start_wave"):GetInt() + math.Round((perk_level - 1) * GetConVar("horde_perk_scaling"):GetFloat())
end

local plymeta = FindMetaTable("Player")

function plymeta:Horde_GetPerk(perk)
    return self.Horde_Perks and self.Horde_Perks[perk] or nil
end

function HORDE:GetPerkBonus(ply, field)
    local bonus = 0
    for name, perk in pairs(HORDE.perks or {}) do
        if perk[field] and ply:Horde_GetPerk(name) then
            bonus = bonus + perk[field]
        end
    end
    return bonus
end

function HORDE:GetSpectreMaxBonus(ply)
    return self:GetPerkBonus(ply, "SpectreMaxBonus")
end

function HORDE:GetGadgetBonus(ply, field)
    local name = ply:Horde_GetGadget()
    local gadget = name and HORDE.gadgets and HORDE.gadgets[name]
    return (gadget and gadget[field]) or 0
end

function HORDE:GetPerkMultiplier(ply, field)
    local mult = 1
    for name, perk in pairs(HORDE.perks or {}) do
        if perk[field] and ply:Horde_GetPerk(name) then
            mult = mult * perk[field]
        end
    end
    return mult
end

function plymeta:Horde_RecalcSpectreMaxCount()
    if not SERVER then return end
    self.Horde_Spectre_Max_Count = 1 + HORDE:GetSpectreMaxBonus(self)
end

function plymeta:Horde_RecalcMaxHypertrophyStack()
    if not SERVER then return end
    self:Horde_SetMaxHypertrophyStack(HORDE:GetPerkBonus(self, "HypertrophyMaxBonus"))
end

function plymeta:Horde_RecalcMaxAdrenalineStack()
    if not SERVER then return end
    self:Horde_SetMaxAdrenalineStack(HORDE:GetPerkBonus(self, "AdrenalineStackBonus")
        + HORDE:GetGadgetBonus(self, "AdrenalineStackBonus"))
end

function plymeta:Horde_RecalcMaxFearStack()
    if not SERVER then return end
    self:Horde_SetMaxFearStack(HORDE:GetPerkBonus(self, "FearStackBonus"))
end

function plymeta:Horde_RecalcMaxIntensityStack()
    if not SERVER then return end
    self:Horde_SetMaxIntensityStack(HORDE:GetPerkBonus(self, "IntensityStackBonus"))
end

function plymeta:Horde_RecalcDerivedStats()
    if not SERVER then return end
    self:Horde_RecalcSpectreMaxCount()
    self:Horde_RecalcMaxHypertrophyStack()
    self:Horde_RecalcMaxAdrenalineStack()
    self:Horde_RecalcMaxFearStack()
    self:Horde_RecalcMaxIntensityStack()
end

local PERK_APPLY_RETRY_INTERVAL = 0.2
local PERK_APPLY_RETRY_ATTEMPTS = 150
local PERK_APPLY_TIMER = "Horde_PendingPerkApply"
local pending_perk_apply = {}

function plymeta:Horde_SchedulePendingPerkApply()
    if not SERVER or not IsValid(self) or not self.Horde_PerksPendingApply then return end
    pending_perk_apply[self] = 0
    if timer.Exists(PERK_APPLY_TIMER) then return end
    timer.Create(PERK_APPLY_TIMER, PERK_APPLY_RETRY_INTERVAL, 0, function()
        local waiting = 0
        for ply in pairs(pending_perk_apply) do
            if not IsValid(ply) or not ply.Horde_PerksPendingApply then
                pending_perk_apply[ply] = nil
            elseif ply:Alive() then
                pending_perk_apply[ply] = nil
                ply:Horde_ApplyPerksForClass()
            else
                pending_perk_apply[ply] = pending_perk_apply[ply] + 1
                if pending_perk_apply[ply] > PERK_APPLY_RETRY_ATTEMPTS then
                    pending_perk_apply[ply] = nil
                else
                    waiting = waiting + 1
                end
            end
        end
        if waiting == 0 then timer.Remove(PERK_APPLY_TIMER) end
    end)
end

function plymeta:Horde_SetPerk(perk, shared)
    if not HORDE.perks[perk] then error("Tried to use nonexistent perk '" .. perk .. "' in Horde_SetPerk!") return end
    self.Horde_Perks = self.Horde_Perks or {}
    self.Horde_Perks[perk] = true
    self.Horde_PerkHookCache = nil
    self:Horde_RecalcDerivedStats()
    if SERVER then
        hook.Run("Horde_PrecomputePerkLevelBonus", self)
    end

    if self:Alive() then
        hook.Run("Horde_OnSetPerk", self, perk)
    elseif SERVER then
        self.Horde_PerksPendingApply = true
        self:Horde_SchedulePendingPerkApply()
    end

    if SERVER and not shared then
        net.Start("Horde_Perk")
            net.WriteUInt(HORDE.NET_PERK_SET, HORDE.NET_PERK_BITS)
            net.WriteEntity(self)
            net.WriteString(perk)
        net.Broadcast()
    end
end

function plymeta:Horde_UnsetPerk(perk, shared)
    self.Horde_Perks = self.Horde_Perks or {}

    hook.Run("Horde_OnUnsetPerk", self, perk)

    self.Horde_Perks[perk] = nil
    self.Horde_PerkHookCache = nil
    self:Horde_RecalcDerivedStats()

    if SERVER and not shared then
        net.Start("Horde_Perk")
            net.WriteUInt(HORDE.NET_PERK_UNSET, HORDE.NET_PERK_BITS)
            net.WriteEntity(self)
            net.WriteString(perk)
        net.Broadcast()
    end
end

function plymeta:Horde_ClearPerks(shared)

    hook.Run("Horde_OnClearPerks", self)

    if not shared then
        for k, v in pairs(self.Horde_Perks or {}) do
            self:Horde_UnsetPerk(k, shared)
        end
    end

    if SERVER and not shared then
        net.Start("Horde_Perk")
            net.WriteUInt(HORDE.NET_PERK_CLEAR, HORDE.NET_PERK_BITS)
            net.WriteEntity(self)
        net.Broadcast()
    end
end

local prefix = "horde/gamemode/modules/perks/"
local function Horde_LoadPerks()
    local dev = GetConVar("developer"):GetBool()
    for _, f in ipairs(file.Find(prefix .. "*", "LUA")) do
        PERK = {}
        AddCSLuaFile(prefix .. f)
        include(prefix .. f)
        if PERK.Ignore then goto cont end
        PERK.ClassName = string.lower(PERK.ClassName or string.Explode(".", f)[1])
        PERK.SortOrder = PERK.SortOrder or 0

        hook.Run("Horde_OnLoadPerk", PERK)

        HORDE.perks[PERK.ClassName] = PERK

        for k, v in pairs(PERK.Hooks or {}) do
            hook.Add(k, "horde_perk_" .. PERK.ClassName, v)
        end

        if dev then print("[Horde] Loaded perk '" .. PERK.ClassName .. "'.") end
        ::cont::
    end

    for subclass_name, subclass in pairs(HORDE.subclasses) do
        prefix = "horde/gamemode/modules/perks/" .. subclass_name .. "/"
        for _, f in ipairs(file.Find(prefix .. "*", "LUA")) do
            PERK = {}
            AddCSLuaFile(prefix .. f)
            include(prefix .. f)
            if PERK.Ignore then goto cont end
            PERK.ClassName = string.lower(PERK.ClassName or string.Explode(".", f)[1])
            PERK.SortOrder = PERK.SortOrder or 0

            hook.Run("Horde_OnLoadPerk", PERK)

            HORDE.perks[PERK.ClassName] = PERK

            for k, v in pairs(PERK.Hooks or {}) do
                hook.Add(k, "horde_perk_" .. PERK.ClassName, v)
            end

            if dev then print("[Horde] Loaded perk '" .. PERK.ClassName .. "'.") end
            ::cont::
        end
    end
    PERK = nil
end

function plymeta:Horde_GetPerkNextThink()
    return self.Horde_PerkNextThink or 0
end

function plymeta:Horde_SetPerkNextThink(t)
    self.Horde_PerkNextThink = t
end

function plymeta:Horde_SetPerkDuration(d)
    self.Horde_PerkDuration = d
end

function plymeta:Horde_GetPerkDuration()
    return self.Horde_PerkDuration or 0
end

function plymeta:Horde_SetPerkCooldown(cd)
    self.Horde_PerkCooldown = cd
    if SERVER then
        net.Start("Horde_PerkCooldownCheck")
            net.WriteInt(cd, 8)
        net.Send(self)
    end
end

function plymeta:Horde_SetPerkInternalCooldown(cd)
    self.Horde_PerkInternalCooldown = cd
end

function plymeta:Horde_SetPerkCharges(charges)
    self.Horde_PerkCharges = charges
    if SERVER then
        net.Start("Horde_PerkChargesUpdate")
            net.WriteInt(charges, 8)
        net.Send(self)
    end
end

function plymeta:Horde_GetPerkInternalCooldown()
    return self.Horde_PerkInternalCooldown or 0
end

function plymeta:Horde_GetPerkCooldown()
    return self.Horde_PerkCooldown or 0
end

function plymeta:Horde_GetSpamPerkCooldown()
    return self.Horde_SpamPerkCooldown or 0
end

function plymeta:Horde_SetSpamPerkCooldown(cd)
    self.Horde_SpamPerkCooldown = cd
end

function plymeta:Horde_GetPerkCharges(charges)
    return self.Horde_PerkCharges or -1
end

if SERVER then
    function HORDE:RefreshPerkCooldown(ply)
        ply:Horde_SetPerkInternalCooldown(0)
        net.Start("Horde_PerkStartCooldown")
            net.WriteUInt(0, 8)
        net.Send(ply)
    end

    local think_t = 0.5
    local BufferTime = 0.5
    function HORDE:UsePerkSkill(ply, auto)
        if ply:Horde_GetSpamPerkCooldown() <= CurTime() and ply:Alive() then
            local cd = ply:Horde_GetPerkInternalCooldown()
            if(cd > 0 && !auto) then
                if(cd <= BufferTime) and ply:Horde_GetPerkCooldown() >= 1 then
                    ply.QueuedPerkSkill = true
                end
                return
            end
            local res = hook.Run("Horde_UseActivePerk", ply)
            if res then return end
            ply:Horde_SetPerkInternalCooldown(ply:Horde_GetPerkCooldown())
            ply:Horde_SetPerkNextThink(CurTime() + think_t)
            net.Start("Horde_PerkStartCooldown")
                net.WriteUInt(ply:Horde_GetPerkCooldown(), 8)
            net.Send(ply)
        end
    end

    hook.Add("PlayerPostThink", "Horde_PerkCooldown", function(ply)
        if CurTime() >= ply:Horde_GetPerkNextThink() then
            ply:Horde_SetPerkNextThink(CurTime() + think_t)
            local cd = ply:Horde_GetPerkInternalCooldown()
            local newcd = cd - think_t
            if(newcd <= 0) then
                if(ply.QueuedPerkSkill) then
                    newcd = 0
                    HORDE:UsePerkSkill(ply, true)
                    ply.QueuedPerkSkill = false
                    return
                end
            end
            if(cd <= 0) then
                return
            end
            ply:Horde_SetPerkInternalCooldown(newcd)
        end
    end)

    function HORDE:UseQuickGrenade(ply)
        local classes = {
            ["Assault"] = {
                grenadeclass = "arccw_horde_nade_stun",
                grenadethrown = "arccw_thr_stun",
            },
            ["SpecOps"] = {
                grenadeclass = "arccw_horde_nade_stun",
                grenadethrown = "arccw_thr_stun",
            },
            ["Heavy"] = {
                grenadeclass = "arccw_horde_nade_shrapnel",
                grenadethrown = "arccw_thr_shrapnel",
            },
            ["Medic"] = {
                grenadeclass = "arccw_nade_medic",
                grenadethrown = "arccw_thr_medicgrenade",
            },
            ["Hatcher"] = {
                grenadeclass = "arccw_nade_medic",
                grenadethrown = "arccw_thr_medicgrenade",
            },
            ["Demolition"] = {
                grenadeclass = "arccw_horde_m67",
                grenadethrown = "arccw_thr_horde_m67",
            },
            ["Warlock"] = {
                grenadeclass = "the_illuminati_group",
                grenadethrown = "projectile_horde_illuminate",
            },
            ["Ghost"] = {
                grenadeclass = "arccw_horde_nade_sonar",
                grenadethrown = "arccw_thr_sonar",
            },
            ["Gunslinger"] = {
                grenadeclass = "arccw_horde_nade_sonar",
                grenadethrown = "arccw_thr_sonar",
            },
            ["Engineer"] = {
                grenadeclass = "arccw_horde_nade_nanobot",
                grenadethrown = "arccw_thr_nanobot",
            },
            ["Necromancer"] = {
                grenadeclass = "the_illuminati_group",
                grenadethrown = "projectile_horde_illuminate",
            },
            ["Berserker"] = {
                grenadeclass = "arccw_horde_nade_hemo",
                grenadethrown = "arccw_thr_hemo",
            },
            ["Samurai"] = {
                grenadeclass = "arccw_horde_nade_hemo",
                grenadethrown = "arccw_thr_hemo",
            },
            ["Warden"] = {
                grenadeclass = "arccw_horde_nade_emp",
                grenadethrown = "arccw_thr_emp",
            },
            ["Overlord"] = {
                grenadeclass = "arccw_horde_nade_emp",
                grenadethrown = "arccw_thr_emp",
            },
            ["Cremator"] = {
                grenadeclass = "arccw_horde_nade_molotov",
                grenadethrown = "arccw_thr_horde_molotov",
            },
            ["Artificer"] = {
                grenadeclass = "the_illuminati_group",
                grenadethrown = "projectile_horde_illuminate",
            },
        }
        if classes[ply:Horde_GetCurrentSubclass()] == nil then return end

        if not ply.Horde_GrenadeSpamCooldown then
            ply.Horde_GrenadeSpamCooldown = 0
        end

        if ply.Horde_GrenadeSpamCooldown > CurTime() then return true end
        ply.Horde_GrenadeSpamCooldown = CurTime() + 0.35

        local nade = ply:GetActiveWeapon()

        if classes[ply:Horde_GetCurrentSubclass()].grenadeclass ~= "the_illuminati_group" then
            if ply:GetAmmoCount("Grenade") <= 0 or nade.Base == "arccw_horde_base_nade" or (!ply:HasWeapon(classes[ply:Horde_GetCurrentSubclass()].grenadeclass)) then
                ply:EmitSound("player/suit_denydevice.wav")
                return
            end
            ply:SetAmmo(ply:GetAmmoCount("Grenade") - 1, "Grenade")
            ply.GrenadeDampened = true
        end

        local grenade = ents.Create(classes[ply:Horde_GetCurrentSubclass()].grenadethrown)
        local vel = 15
        local ang = ply:EyeAngles()

        local src = (ply:EyePos() + Vector(0,0,-3) + ( ply:GetAimVector() * 16 ) + (ply:GetRight()*-4))

        if !grenade:IsValid() then print("!!! INVALID ROUND " .. grenade) return end

        local grenadeAng = Angle(ang.p, ang.y, ang.r)

        grenade:SetAngles(grenadeAng)
        grenade:SetPos(src)

        grenade:SetOwner(ply)
        grenade.Owner = ply
        grenade.Inflictor = grenade

        local RealVelocity = (ply:GetAbsVelocity() or Vector(0, 0, 0)) + ang:Forward() * vel / 0.0254
        grenade.CurVel = RealVelocity

        grenade:Spawn()
        grenade:Activate()

        local spin = grenade:GetPhysicsObject()
        spin:AddAngleVelocity(Vector(0, -750, 0))

        if !grenade.NoPhys and grenade:GetPhysicsObject():IsValid() then
            grenade:SetCollisionGroup(grenade.CollisionGroup or COLLISION_GROUP_DEBRIS)
            grenade:GetPhysicsObject():SetVelocityInstantaneous(RealVelocity)
        end

        if grenade.Launch and grenade.SetState then
            grenade:SetState(1)
            grenade:Launch()
        end
    end
end
