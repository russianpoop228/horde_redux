if CLIENT then return end

util.AddNetworkString("Horde_Purism_DiseaseState")
util.AddNetworkString("Horde_Purism_DiseaseTick")

local DISEASE_DURATION      = 45
local DISEASE_ACCUM_RATE    = 10
local NECROSIS_ACCUM_RATE   = 5
local DISEASE_HP_DRAIN      = 5
local DISEASE_HIT_CHANCE    = 0.25
local BLEEDING_HIT_CHANCE   = 0.40
local DISEASE_WAVE_CHANCE   = 0.05
local DISEASE_OUTGOING_MULT = 0.75
local WAVE_CASH_MIN         = 1000
local WAVE_CASH_MAX         = 1500

local function IsPurism()
    return HORDE.purism_mode == true
end

local GHOUL_SUBCLASS = "Ghoul"

local function IsDiseaseImmune(ply)
    return ply.Horde_GetCurrentSubclass ~= nil
        and ply:Horde_GetCurrentSubclass() == GHOUL_SUBCLASS
end

function HORDE:GetPurismWaveCash()
    return math.random(WAVE_CASH_MIN, WAVE_CASH_MAX)
end

local function SyncDiseaseBar(ply, progress)
    if not IsValid(ply) or not HORDE.Status_Disease then return end
    net.Start("Horde_SyncStatus")
        net.WriteUInt(HORDE.Status_Disease, 8)
        net.WriteUInt(math.Clamp(math.floor(progress), 0, 100), 8)
    net.Send(ply)
end

local function NetDiseaseVisual(ply, active)
    if not IsValid(ply) then return end
    net.Start("Horde_Purism_DiseaseState")
        net.WriteBool(active and true or false)
    net.Send(ply)
end

local function TimerName(ply)
    return "Horde_Purism_Disease_" .. ply:SteamID()
end

local function ResetNecrosisBuildup(ply)
    local sid = HORDE.Status_Necrosis
    if not sid or not ply.Horde_Debuff_Buildup then return end
    if ply.Horde_Debuff_Active and ply.Horde_Debuff_Active[sid] then return end
    local cur = ply.Horde_Debuff_Buildup[sid]
    if cur and cur > 0 then
        ply:Horde_ReduceDebuffBuildup(sid, cur)
    end
end

local function ClearDisease(ply, from_debuff_system)
    if not IsValid(ply) then return end
    local was = ply.Horde_DiseaseActive
    ply.Horde_DiseaseActive   = false
    ply.Horde_DiseaseProgress = 0
    ply.Horde_DiseaseExpire   = 0
    timer.Remove(TimerName(ply))
    if not was then return end

    local sid = HORDE.Status_Disease
    if sid and not from_debuff_system then
        if ply.Horde_Debuff_Active then ply.Horde_Debuff_Active[sid] = nil end
        if ply.Horde_Debuff_Buildup then ply.Horde_Debuff_Buildup[sid] = 0 end
    end
    SyncDiseaseBar(ply, 0)
    NetDiseaseVisual(ply, false)
    ResetNecrosisBuildup(ply)
end

local function SetProgress(ply, value)
    ply.Horde_DiseaseProgress = math.Clamp(value, 0, 100)
    local sid = HORDE.Status_Disease
    if sid and ply.Horde_Debuff_Buildup then
        ply.Horde_Debuff_Buildup[sid] = math.floor(ply.Horde_DiseaseProgress)
    end
    SyncDiseaseBar(ply, math.max(1, ply.Horde_DiseaseProgress))
end

local function DiseaseTick(ply)
    if not IsValid(ply) or not ply:Alive() or HORDE:IsPlayerSpectator(ply) or not IsPurism() or not ply.Horde_DiseaseActive or IsDiseaseImmune(ply) then
        if IsValid(ply) then ClearDisease(ply) end
        return
    end
    if CurTime() >= ply.Horde_DiseaseExpire then
        ClearDisease(ply)
        return
    end

    if ply.Horde_DiseaseProgress < 100 then
        SetProgress(ply, ply.Horde_DiseaseProgress + DISEASE_ACCUM_RATE)
    end

    if ply.Horde_DiseaseProgress >= 100 and HORDE.Status_Necrosis then
        ply:Horde_AddDebuffBuildup(HORDE.Status_Necrosis, NECROSIS_ACCUM_RATE, ply)
        timer.Remove("Horde_RemoveBuildup_" .. tostring(HORDE.Status_Necrosis) .. "_" .. ply:SteamID())
    end

    local cur_hp = ply:Health()
    if cur_hp > 1 then
        local new_hp = math.max(1, cur_hp - DISEASE_HP_DRAIN)
        if new_hp < cur_hp then
            ply:SetHealth(new_hp)
            net.Start("Horde_Purism_DiseaseTick")
            net.Send(ply)
        end
    end
end

local function ApplyDisease(ply)
    if not IsValid(ply) or not ply:Alive() or not IsPurism() then return end
    if IsDiseaseImmune(ply) then return end
    local now = CurTime()
    if ply.Horde_DiseaseActive then
        ply.Horde_DiseaseExpire = math.max(ply.Horde_DiseaseExpire or 0, now + DISEASE_DURATION)
        return
    end

    ply.Horde_DiseaseActive = true
    ply.Horde_DiseaseExpire = now + DISEASE_DURATION

    if not ply.Horde_Debuff_Active  then ply.Horde_Debuff_Active  = {} end
    if not ply.Horde_Debuff_Buildup then ply.Horde_Debuff_Buildup = {} end
    if HORDE.Status_Disease then ply.Horde_Debuff_Active[HORDE.Status_Disease] = true end

    SetProgress(ply, 0)
    NetDiseaseVisual(ply, true)
    if HORDE.Debuff_Notifications and HORDE.Status_Disease and HORDE.SendNotificationDebuff then
        HORDE:SendNotificationDebuff(HORDE.Status_Disease, ply)
    end

    timer.Create(TimerName(ply), 1, 0, function() DiseaseTick(ply) end)
end

local entmeta = FindMetaTable("Entity")
if entmeta and entmeta.Horde_RemoveDebuff and not HORDE._purism_remove_wrapped then
    HORDE._purism_remove_wrapped = true
    local old_remove = entmeta.Horde_RemoveDebuff
    function entmeta:Horde_RemoveDebuff(debuff)
        local was_disease = HORDE.Status_Disease and debuff == HORDE.Status_Disease
        old_remove(self, debuff)
        if was_disease and self:IsPlayer() then ClearDisease(self, true) end
    end
end

hook.Add("Horde_ResetStatus", "Horde_Purism_DiseaseReset", function(ply)
    ply.Horde_DiseaseActive = false
    ply.Horde_DiseaseProgress = 0
    ply.Horde_DiseaseExpire = 0
    timer.Remove(TimerName(ply))
    NetDiseaseVisual(ply, false)
end)

local function IsEnemyDamage(dmginfo)
    if dmginfo:IsDamageType(DMG_DIRECT) or dmginfo:IsFallDamage() then return false end
    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()
    local function is_enemy(e)
        return IsValid(e) and (e:IsNPC() or e:IsNextBot()) and not HORDE:IsPlayerOrMinion(e)
    end
    return is_enemy(attacker) or is_enemy(inflictor)
end

local function ApplyFullBleeding(ply, attacker)
    local sid = HORDE.Status_Bleeding
    if not sid or not ply.Horde_AddDebuffBuildup then return end
    if ply.Horde_Debuff_Active and ply.Horde_Debuff_Active[sid] then return end
    ply:Horde_AddDebuffBuildup(sid, 100000, attacker, IsValid(attacker) and attacker:GetPos() or ply:GetPos())
end

local handled_damage = setmetatable({}, { __mode = "k" })

local function ConvertEnemyDamage(ply, dmginfo)
    if not IsPurism() then return false end
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
    if dmginfo:GetDamage() <= 0 or not IsEnemyDamage(dmginfo) then return false end
    if handled_damage[dmginfo] then return false end
    handled_damage[dmginfo] = true

    if math.random() < DISEASE_HIT_CHANCE then
        ApplyDisease(ply)
    end

    if math.random() >= BLEEDING_HIT_CHANCE then return false end

    ApplyFullBleeding(ply, dmginfo:GetAttacker())
    dmginfo:SetDamage(0)
    return true
end

hook.Add("Horde_OnPlayerDamageTaken", "Horde_Purism_EnemyDamageToBleeding", function(ply, dmginfo, bonus)
    if ConvertEnemyDamage(ply, dmginfo) and bonus then
        bonus.resistance = 1
    end
end)

hook.Add("EntityTakeDamage", "Horde_Purism_EnemyDamageToBleeding_Fallback", function(ent, dmginfo)
    if ConvertEnemyDamage(ent, dmginfo) then return true end
end)

hook.Add("EntityTakeDamage", "Horde_Purism_DiseaseIncoming", function(ent, dmginfo)
    if not IsPurism() or not IsValid(ent) or not ent:IsPlayer() then return end
    if not ent.Horde_DiseaseActive then return end
    if dmginfo:IsDamageType(DMG_DIRECT) then return end
    local inc = (HORDE.difficulty_shock_damage_increase and HORDE.difficulty_shock_damage_increase[HORDE.difficulty]) or 0.35
    dmginfo:ScaleDamage(1 + inc)
end)

hook.Add("Horde_OnPlayerDamage", "Horde_Purism_DiseaseWeakness", function(ply, npc, bonus, hitgroup, dmginfo)
    if not IsPurism() or not IsValid(ply) or not bonus then return end
    if not ply.Horde_DiseaseActive then return end
    bonus.more = (bonus.more or 1) * DISEASE_OUTGOING_MULT
end)

hook.Add("Horde_PostOnPlayerHeal", "Horde_Purism_HealDisease", function(ply, healinfo)
    if not IsPurism() or not IsValid(ply) or not ply.Horde_DiseaseActive then return end
    local before = ply:Health()
    timer.Simple(0, function()
        if not IsValid(ply) or not ply.Horde_DiseaseActive then return end
        local maxhp = ply:GetMaxHealth()
        local gained = ply:Health() - before
        if gained <= 0 or maxhp <= 0 then return end
        SetProgress(ply, (ply.Horde_DiseaseProgress or 0) - (gained / maxhp) * 100)
        if ply.Horde_DiseaseProgress < 100 then
            ResetNecrosisBuildup(ply)
        end
    end)
end)

hook.Add("HordeWaveStart", "Horde_Purism_WaveDisease", function()
    if not IsPurism() then return end
    timer.Simple(0.5, function()
        if not IsPurism() then return end
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Alive() and math.random() < DISEASE_WAVE_CHANCE then
                ApplyDisease(ply)
            end
        end
    end)
end)

hook.Add("PlayerDeath", "Horde_Purism_ClearDiseaseDeath", function(ply)
    ClearDisease(ply)
end)
hook.Add("PlayerDisconnected", "Horde_Purism_ClearDiseaseDC", function(ply)
    timer.Remove(TimerName(ply))
end)

print("[Horde PURISM] sv_purism_mode.lua loaded")
