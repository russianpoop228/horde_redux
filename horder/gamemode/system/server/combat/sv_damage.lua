local plymeta = FindMetaTable("Player")
local entmeta = FindMetaTable("Entity")

HORDE.ARMOR_BONUS_HANDLERS = {
    ["armor_assault"]    = function(bonus, dmg)
        if HORDE:IsBallisticDamage(dmg) then bonus.resistance = bonus.resistance + 0.08 end
    end,
    ["armor_heavy"]      = function(bonus, dmg) end,
    ["armor_medic"]      = function(bonus, dmg)
        if HORDE:IsPoisonDamage(dmg) then bonus.resistance = bonus.resistance + 0.08 end
    end,
    ["armor_demolition"] = function(bonus, dmg)
        if HORDE:IsBlastDamage(dmg) then bonus.resistance = bonus.resistance + 0.08 end
    end,
    ["armor_ghost"]      = function(bonus, dmg)
        bonus.evasion = bonus.evasion + 0.05
    end,
    ["armor_engineer"]   = function(bonus, dmg)
        bonus.resistance = bonus.resistance + 0.05
    end,
    ["armor_warden"]     = function(bonus, dmg)
        if HORDE:IsLightningDamage(dmg) then bonus.resistance = bonus.resistance + 0.08 end
    end,
    ["armor_cremator"]   = function(bonus, dmg)
        if HORDE:IsFireDamage(dmg) then bonus.resistance = bonus.resistance + 0.08 end
    end,
    ["armor_berserker"]  = function(bonus, dmg)
        local t = dmg:GetDamageType()
        if t == DMG_SLASH or t == DMG_CLUB then bonus.resistance = bonus.resistance + 0.08 end
    end,
    ["armor_survivor"]   = function(bonus, dmg)
        bonus.resistance = bonus.resistance + 0.05
    end,
}

local DAMAGE_TYPE_DEBUFF_MAP = nil
local function BuildDamageDebuffMap()
    DAMAGE_TYPE_DEBUFF_MAP = {
        { check = function(d) return HORDE:IsPoisonDamage(d) end,      status = HORDE.Status_Break,     more = 2 },
        { check = function(d) return HORDE:IsFireDamage(d) end,        status = HORDE.Status_Ignite,    more = 2 },
        { check = function(d) return HORDE:IsLightningDamage(d) end,   status = HORDE.Status_Shock,     more = 2 },
        { check = function(d) return HORDE:IsColdDamage(d) end,        status = HORDE.Status_Frostbite, more = 2 },
        { check = function(d) return d:IsDamageType(DMG_DISSOLVE) end, status = HORDE.Status_Necrosis,  more = 2 },
    }
end

function HORDE:GetDamageTypeDebuff(dmginfo)
    if not DAMAGE_TYPE_DEBUFF_MAP then BuildDamageDebuffMap() end
    for _, entry in ipairs(DAMAGE_TYPE_DEBUFF_MAP) do
        if entry.check(dmginfo) then
            return entry.status, entry.more
        end
    end
    return nil, nil
end

HORDE.DMG_CALCULATED = 1
HORDE.DMG_OVER_TIME = 3
HORDE.DMG_SPLASH = 2
HORDE.DMG_PLAYER_FRIENDLY = -3
HORDE.DMG_PARASITE = 4

function HORDE:IsBadNumber(n)
    return n ~= n or n == math.huge or n == -math.huge
end

function HORDE:SanitizeDamage(dmginfo)
    local d = dmginfo:GetDamage()
    if d ~= d or d == math.huge or d == -math.huge then
        dmginfo:SetDamage(0)
        return true
    end
    return false
end

hook.Add("EntityTakeDamage", "Horde_NaNDamageGuard", function(target, dmginfo)
    if HORDE:SanitizeDamage(dmginfo) then return true end
end)

local POISON_DAMAGE_MASK = DMG_POISON + DMG_ACID + DMG_RADIATION + DMG_NERVEGAS

local function IsBuildableOrTurret(ent)
    if HORDE:IsTurretMinion(ent) then return true end
    local class = ent:GetClass()
    return (HORDE.EngineerBuildables and HORDE.EngineerBuildables[class] ~= nil)
        or (HORDE.EngineerBuildableCustom and HORDE.EngineerBuildableCustom[class] ~= nil)
        or (HORDE.WardenBuildables and HORDE.WardenBuildables[class] ~= nil)
        or class == "horde_engiconstruction"
        or class == "horde_wardenconstruction"
end

local function IsToxicImmuneEntity(ent)
    if IsBuildableOrTurret(ent) then return true end
    return HORDE:IsMinion(ent) == true
end

hook.Add("EntityTakeDamage", "Horde_BuildableToxicImmunity", function(target, dmginfo)
    if not IsValid(target) or target:IsPlayer() then return end
    if not target.Immune_AcidPoisonRadiation then return end
    if not IsToxicImmuneEntity(target) then return end
    if bit.band(dmginfo:GetDamageType(), POISON_DAMAGE_MASK) ~= 0 then
        dmginfo:SetDamage(0)
        return true
    end
end)

function HORDE:ApplyDamage(npc, hitgroup, dmginfo)
    if dmginfo:GetDamageCustom() > 0 then return end
    if dmginfo:GetDamage() <= 0 then return end
    if not npc:IsValid() then return end
    if GetConVar("horde_corpse_cleanup"):GetInt() == 1 and npc:Health() <= 0 then
        npc:Remove()
        return
    end

    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) then return end

    local attacker_owner = HORDE:GetMinionOwner(attacker)
    if attacker_owner then
        dmginfo:SetInflictor(attacker)
        dmginfo:SetAttacker(attacker_owner)
    end

    if IsValid(attacker:GetOwner()) and attacker:GetOwner():IsPlayer() then
        dmginfo:SetAttacker(attacker:GetOwner())
    end

    local ply = dmginfo:GetAttacker()
    if not ply:IsPlayer() then return end

    local minion_inflictor = dmginfo:GetInflictor()
    if IsValid(minion_inflictor) and minion_inflictor:GetClass() == "npc_manhack" then
        local manhack_dmg = minion_inflictor:GetNWFloat("Horde_UpgradeDamage", 0)
        if manhack_dmg > 0 then dmginfo:SetDamage(manhack_dmg) end
    end

    local increase = 0
    local more = 1
    local base_add = 0
    local post_add = 0

    local bonus = { increase = increase, more = more, base_add = base_add, post_add = post_add }
    if ply:Horde_GetCurrentSubclass() == "Gunslinger" then
        local wpn = HORDE:GetCurrentWeapon(dmginfo:GetInflictor())
        if IsValid(wpn) then
            local level = ply:Horde_GetUpgrade(wpn:GetClass())
            if level and level > 0 then
                if HORDE.items[wpn:GetClass()].starter_classes then
                    bonus.more = bonus.more * (1 + 0.1 * level)
                else
                    bonus.more = bonus.more * (1 + 0.03 * level)
                end
            end
        end
    end
    local res = hook.Run("Horde_OnPlayerDamagePre", ply, npc, bonus, hitgroup, dmginfo)
    if res then
        dmginfo:AddDamage(bonus.base_add)
        dmginfo:ScaleDamage(bonus.more * (1 + bonus.increase))
        dmginfo:AddDamage(bonus.post_add)
        dmginfo:SetDamageCustom(HORDE.DMG_CALCULATED)
        if hitgroup == HITGROUP_HEAD then
            sound.Play("horde/player/headshot.ogg", npc:GetPos())
        end
        return
    end
    hook.Run("Horde_OnPlayerDamage", ply, npc, bonus, hitgroup, dmginfo)
    if HORDE:IsMinion(dmginfo:GetInflictor()) then
        hook.Run("Horde_OnPlayerMinionDamage", ply, npc, bonus, dmginfo)
    end

    if dmginfo:GetInflictor():GetClass() == "entityflame" then
        dmginfo:SetDamagePosition(npc:GetPos())
        dmginfo:SetDamage(npc:Horde_GetIgniteDamageTaken())
    else
        if dmginfo:GetDamageType() == DMG_BURN then
            dmginfo:SetDamageType(DMG_SLOWBURN)
            if ply:Horde_GetGadget() ~= "gadget_hydrogen_burner" then
                npc:Horde_SetMostRecentFireAttacker(ply, dmginfo)
                npc:Ignite(ply:Horde_GetApplyIgniteDuration())
            end
        elseif ply:Horde_GetApplyIgniteChance() > 0 then
            local ignite = math.random()
            if ignite <= ply:Horde_GetApplyIgniteChance() then
                if ply:Horde_GetGadget() ~= "gadget_hydrogen_burner" then
                    npc:Horde_SetMostRecentFireAttacker(ply, dmginfo)
                    npc:Ignite(ply:Horde_GetApplyIgniteDuration())
                end
            end
        end
    end

    dmginfo:AddDamage(bonus.base_add)
    dmginfo:ScaleDamage(bonus.more * (1 + bonus.increase))
    dmginfo:AddDamage(bonus.post_add)
    dmginfo:SetDamageCustom(HORDE.DMG_CALCULATED)

    if HORDE:IsLightningDamage(dmginfo) and dmginfo:GetInflictor():GetClass() == "npc_vortigaunt" then
        local dmg = DamageInfo()
        dmg:SetAttacker(dmginfo:GetAttacker())
        dmg:SetInflictor(dmginfo:GetInflictor())
        dmg:SetDamageType(DMG_PLASMA)
        dmg:SetDamage(dmginfo:GetDamage())
        dmg:SetDamageCustom(HORDE.DMG_SPLASH)
        util.BlastDamageInfo(dmg, dmginfo:GetDamagePosition(), 250)
    end

    if hitgroup == HITGROUP_HEAD then
        sound.Play("horde/player/headshot.ogg", npc:GetPos())
    end

    hook.Run("Horde_OnPlayerDamagePost", ply, npc, bonus, hitgroup, dmginfo)

    if not npc.Horde_Assist then
        npc.Horde_Assist = ply
    elseif ply ~= npc.Horde_Hit then
        npc.Horde_Assist = npc.Horde_Hit
    end

    npc.Horde_Hit = ply
end

function entmeta:TakeDamageOverTime(attacker, dmg, dmgtype, interval, duration)
    local dmginfo = DamageInfo()
    dmginfo:SetAttacker(attacker)
    dmginfo:SetInflictor(self)
    dmginfo:SetDamageType(dmgtype)
    dmginfo:SetDamage(dmg)
    dmginfo:SetDamageCustom(HORDE.DMG_OVER_TIME)
    dmginfo:SetDamagePosition(self:GetPos())

    self:TakeDamageInfo(dmginfo)
    for i = 1, duration / interval do
        timer.Simple(interval * i, function()
            if self:IsValid() then
                local dmginfo2 = DamageInfo()
                dmginfo2:SetAttacker(attacker)
                dmginfo2:SetInflictor(Entity(0))
                dmginfo2:SetDamageType(dmgtype)
                dmginfo2:SetDamage(dmg)
                dmginfo2:SetDamageCustom(HORDE.DMG_OVER_TIME)
                dmginfo2:SetDamagePosition(self:GetPos())
                self:TakeDamageInfo(dmginfo2)
            end
        end)
    end
end

function HORDE:ApplyDamageInRadius(pos, radius, dmginfo, callback)
    for _, ent in pairs(ents.FindInSphere(pos, radius)) do
        if ent:IsNPC() and HORDE:IsPlayerOrMinion(ent) ~= true then
            dmginfo:SetDamagePosition(ent:GetPos())
            ent:TakeDamageInfo(dmginfo)
            if callback then
                callback(ent)
            end
        end
    end
end

function HORDE:DamageInfo(damage, dmgtype, attacker, inflictor, damage_custom)
    local dmginfo = DamageInfo()
    dmginfo:SetAttacker(attacker)

    if inflictor then
        dmginfo:SetInflictor(inflictor)
    else
        dmginfo:SetInflictor(attacker)
    end

    if dmgtype then
        dmginfo:SetDamageType(dmgtype)
    else
        dmginfo:SetDamageType(DMG_GENERIC)
    end
    dmginfo:SetDamage(damage)
    if damage_custom then
        dmginfo:SetDamageCustom(damage_custom)
    end
    return dmginfo
end

function HORDE:TakeDamage(victim, damage, dmgtype, attacker, inflictor, damage_custom)
    local dmginfo = DamageInfo()
    if attacker then
        dmginfo:SetInflictor(attacker)
    else
        dmginfo:SetInflictor(Entity(0))
    end

    if inflictor then
        dmginfo:SetInflictor(inflictor)
    else
        dmginfo:SetInflictor(Entity(0))
    end

    dmginfo:SetDamagePosition(victim:GetPos())

    if dmgtype then
        dmginfo:SetDamageType(dmgtype)
    else
        dmginfo:SetDamageType(DMG_GENERIC)
    end
    dmginfo:SetDamage(damage)
    if damage_custom then
        dmginfo:SetDamageCustom(damage_custom)
    end
    victim:TakeDamageInfo(dmginfo)
end

hook.Add("EntityTakeDamage", "Horde_DamageRedirection", function(target, dmginfo)
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) then return end
    if not HORDE:IsEnemy(target) then return end

    if attacker:GetClass() == "entityflame" then
        if target:Horde_GetMostRecentFireAttacker() then
            dmginfo:SetAttacker(target:Horde_GetMostRecentFireAttacker())
        end
    elseif HORDE:IsMinion(attacker) then
        dmginfo:SetInflictor(attacker)
        dmginfo:SetAttacker(HORDE:GetMinionOwner(attacker))
    elseif IsValid(attacker:GetOwner()) and attacker:GetOwner():IsPlayer() then
        dmginfo:SetAttacker(attacker:GetOwner())
    end

    if dmginfo:GetAttacker():IsPlayer() then
        HORDE:ApplyDamage(target, HITGROUP_GENERIC, dmginfo)
        if HORDE:SanitizeDamage(dmginfo) then return true end
    end
end)

hook.Add("ScaleNPCDamage", "Horde_ApplyDamage", function(npc, hitgroup, dmginfo)
    if (not HORDE:IsPlayerMinion(npc)) then
        HORDE:ApplyDamage(npc, hitgroup, dmginfo)
        HORDE:SanitizeDamage(dmginfo)
    end
end)

hook.Add("PlayerShouldTakeDamage", "Horde_SpectatorNoDamage", function(ply, attacker)
    if not IsValid(ply) then return end
    if not ply:Alive()
        or ply:GetObserverMode() ~= OBS_MODE_NONE
        or ply:GetMoveType() == MOVETYPE_OBSERVER
        or ply.Horde_SpectatorGhost then
        return false
    end
end)

hook.Add("EntityTakeDamage", "Horde_ApplyDamageTaken", function(target, dmg)
    if not target:IsValid() or not target:IsPlayer() then return end
    if dmg:GetDamageCustom() ~= 0 then return true end
    local ply = target

    if not ply:Alive()
        or ply:GetObserverMode() ~= OBS_MODE_NONE
        or ply:GetMoveType() == MOVETYPE_OBSERVER
        or ply.Horde_SpectatorGhost then
        return true
    end

    if dmg:GetAttacker():IsPlayer() and (dmg:GetInflictor() == dmg:GetAttacker()) then return true end

    if dmg:GetInflictor():IsNPC() and dmg:GetAttacker():IsPlayer() then return true end

    if HORDE:IsPlayerMinion(dmg:GetInflictor()) or HORDE:IsPlayerMinion(dmg:GetAttacker()) then return true end

    if dmg:GetDamage() <= 0.5 then return true end

    local bonus = { resistance = 0, less = 1, evasion = 0, block = 0 }
    local ret = hook.Run("Horde_OnPlayerDamageTaken", ply, dmg, bonus)
    if ret then return end
    if bonus.evasion > 0 then
        local evade = math.random()
        if evade <= bonus.evasion then
            ply:EmitSound("horde/player/evade.ogg", 125, 100, 1, CHAN_AUTO)
            hook.Run("Horde_OnPlayerEvade", ply, dmg)
            return true
        end
    end
    if bonus.resistance >= 1.0 then return true end

    if ply.Horde_Special_Armor then
        local handler = HORDE.ARMOR_BONUS_HANDLERS[ply.Horde_Special_Armor]
        if handler then handler(bonus, dmg) end
    end

    dmg:ScaleDamage(bonus.less * (1 - bonus.resistance))
    dmg:SubtractDamage(bonus.block)

    if dmg:GetDamage() <= 0.5 then return true end

    hook.Run("Horde_OnPlayerDamageTakenPost", ply, dmg, bonus)

    if dmg:GetDamage() > 0 then
        local debuff, more = HORDE:GetDamageTypeDebuff(dmg)
        if not debuff then return end

        local buildup = dmg:GetDamage() * more
        local class = dmg:GetAttacker():GetClass()
        if class == "npc_headcrab_poison" or class == "npc_headcrab_black" then
            dmg:SetDamage(1)
            if debuff == HORDE.Status_Break then
                buildup = ply:Health() * 2
            end
        else
            buildup = math.min(85, buildup)
        end
        ply:Horde_AddDebuffBuildup(debuff, buildup, dmg:GetAttacker())
    end
end)

hook.Add("EntityTakeDamage", "Horde_ApplyMinionDamageTaken", function(target, dmg)
    if not target:IsValid() or not HORDE:IsPlayerMinion(target) then return end
    if dmg:GetAttacker():IsPlayer() then return true end
    hook.Run("Horde_OnMinionDamageTaken", target, dmg)
    if dmg:GetDamage() <= 0.5 then return true end
    local bonus = { more = 1 }
    if dmg:GetDamage() > 0 then
        local debuff, more = HORDE:GetDamageTypeDebuff(dmg)
        if not debuff then return end
        bonus.more = more

        local buildup = dmg:GetDamage() * bonus.more
        local class = dmg:GetAttacker():GetClass()
        if class == "npc_headcrab_poison" or class == "npc_headcrab_black" then
            dmg:SetDamage(1)
            if debuff == HORDE.Status_Break then
                buildup = target:Health() * 2
            end
        else
            buildup = math.min(85, buildup)
        end
        target:Horde_AddDebuffBuildup(debuff, buildup)
    end
end)

hook.Add("EntityTakeDamage", "Horde_MutationDamage", function(target, dmg)
    if target:IsValid() and target:IsNPC() and dmg:GetInflictor():IsWorld() and dmg:GetAttacker():IsNPC() then
        return true
    end
end)

hook.Add("Horde_OnPlayerDamageTaken", "Horde_MeteorDefense", function(ply, dmginfo, bonus)
    if ply:Horde_GetMaxMind() > 0 and IsValid(dmginfo:GetInflictor()) and dmginfo:GetInflictor():GetClass() == "projectile_horde_meteor" then
        dmginfo:SetDamage(math.min(10, dmginfo:GetDamage()))
        dmginfo:SetDamageType(DMG_DIRECT)
    end
end)

hook.Add("EntityTakeDamage", "Horde_SplashDamage", function(target, dmg)
    if target:IsValid() and target:IsNPC() and dmg:GetInflictor() == target and dmg:GetAttacker():IsPlayer() and dmg:GetDamageCustom() == HORDE.DMG_SPLASH then
        return true
    end
end)

hook.Add("ScaleNPCDamage", "Horde_BossHeadshotDamage", function(npc, hitgroup, dmg)
    if npc:IsValid() and npc:Horde_GetBossProperties() and hitgroup == HITGROUP_HEAD then
        dmg:ScaleDamage(0.70)
    end
end)

local HitGroups = {
    [0] = 1,
    [1] = 1,
    [2] = 1,
    [3] = 1,
    [4] = 1,
    [5] = 1,
    [6] = 1,
    [7] = 1,
    [10] = 1,
}
local MeleeHitGroups = {
    [0] = 1,
    [1] = 1,
    [2] = 1,
    [3] = 1,
    [4] = 4,
    [5] = 4,
    [6] = 4,
    [7] = 4,
    [10] = 1,
}
hook.Add("ScaleNPCDamage", "Horde_Locational_Damage", function(npc, hitgroup, dmginfo)
    local attacker = dmginfo:GetAttacker()
    if (!IsValid(attacker)) then return end
    if (attacker:IsPlayer() and not attacker:GetActiveWeapon().Horde_Use_Locational_DMG)  then return end
    local scale = HitGroups[hitgroup] || 1
    if attacker:IsPlayer() and not HORDE:IsPlayerMinion(attacker) then
        if attacker:GetActiveWeapon().Horde_Use_Locational_DMG == "melee" then
            scale = MeleeHitGroups[hitgroup] || 1
        end
    elseif HORDE:IsPlayerMinion(attacker) then
        scale = MeleeHitGroups[hitgroup] || 1
    else
        scale = 1
    end
    dmginfo:ScaleDamage(scale)
end)

local defaults = {
    radius = 100,
    falloffradius = 0,
    falloff_cap = 0,
    damage = 100,
    basedamagemul = 0,
    fallofftype = "linear",
    falloff_speed = 1,
    ignoreattacker = false,
    origin = Vector(0, 0, 0),
    damagetype = 64,
    damagecustomtype = nil,
    antishotgun = nil,
}
function HORDE.RadiusDamageExtra(data)
    if(!data || !IsValid(data.attacker)) then return end
    for k,v in pairs(defaults) do

        if(data[k]) then continue end
        data[k] = v
    end

    local attacker = data.attacker
    local inflictor = data.inflictor
    local radius = data.radius
    local fradius = data.falloffradius
    local fradius_min = math.max(radius - fradius, 0)
    if(fradius_min == 0) then
        fradius_min = 1
    end
    local dmg = data.damage
    local dmgtype = data.damagetype
    local basedmg_scale = data.basedamagemul
    local ftype = data.fallofftype
    local fscale = data.falloff_speed
    if not isnumber(fscale) or fscale <= 0 then fscale = 1 end
    local fcap = data.falloff_cap
    local skip_attacker = data.ignoreattacker

    local pos = data.origin
    local dmgcustom = data.damagecustomtype
    local no_shotgunning = data.antishotgun

    local base_dmg = dmg * basedmg_scale
    local scalable_dmg = dmg * math.max(1 - basedmg_scale, 0)

    for _, ent in pairs(ents.FindInSphere(pos, radius)) do
        if(skip_attacker && ent == attacker) then continue end
        if ent:IsPlayer() && ent != attacker then continue end
        if HORDE:IsPlayerMinion(ent) == true then continue end
        if ent.horde_splash_antishotgun then continue end
        if no_shotgunning then
            ent.horde_splash_antishotgun = true
            timer.Simple(0, function()
                ent.horde_splash_antishotgun = nil
            end)
        end
        local dst = ent:GetPos():Distance(pos)
        if(dst > radius) then continue end
        local sData = {
            checkmode = 2,
            originVector = pos,
            targetEntity = ent,
            advancedCheck = true,
        }
        if(!HORDE.IsInSight(sData)) then continue end
        local ragdoll_force = attacker:GetRight() * math.random(-4912, 4912) + attacker:GetForward() * math.random(2048, 9989)
        local dmginfo = DamageInfo()
            dmginfo:SetAttacker(attacker)
            dmginfo:SetInflictor(inflictor)
            dmginfo:SetDamagePosition(ent:GetPos())
            dmginfo:SetDamageType(dmgtype)
            dmginfo:SetDamageForce(ragdoll_force)
            if dmgcustom then
                dmginfo:SetDamageCustom(dmgcustom)
            end

        if(dst <= fradius) then
            if ent.donthitmeagain then
                dmginfo:SetDamage(0)
            else
                dmginfo:SetDamage(dmg)
            end
            ent:TakeDamageInfo(dmginfo)
        else
            local newdst = dst - fradius
            local scale = (newdst / fradius_min) / fscale
            local sdmg = scalable_dmg
            if(ftype == "instant") then
                sdmg = 0
            elseif(ftype == "linear") then
                sdmg = sdmg * (1 - scale)
            elseif(ftype == "linear_inverted") then
                sdmg = sdmg * scale
            end
            if ent.donthitmeagain then
                dmginfo:SetDamage(0)
            else
                dmginfo:SetDamage(math.max(base_dmg + sdmg, fcap))
            end
            ent:TakeDamageInfo(dmginfo)
        end
    end
end
