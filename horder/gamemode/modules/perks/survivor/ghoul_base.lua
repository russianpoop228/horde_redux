PERK.PrintName = "Ghoul Base"
PERK.Description = [[
The Ghoul class specializes in balancing high speed with maintaining their own health.

Complexity: HIGH

Constantly loses health (-1 each 0.25 seconds).
Cannot be healed by allies, medkits or any external sources.
Healing occurs as damage is dealt to enemies up to {1} of your enemy's HP.
{4} resistance to all debuffs. ({2} per level, up to {3})
{5} constant resistance to debuffs: Break & Bleeding]]
PERK.Icon = "materials/subclasses/ghoul.png"

local PARAMS = {
    [1] = {value = 0.05, percent = true},
    [2] = {value = 0.005, percent = true},
    [3] = {value = 0.50, percent = true},
    [4] = {percent = true, level = 0.005, max = 0.50, classname = "Ghoul"},
    [5] = {value = 0.25, percent = true}
}
PERK.Params = PARAMS
PERK.Hooks = {}

local function Ghoul_RecalcMaxHP(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not SERVER then return end

    local targetMax = 100

    if ply:Horde_GetPerk("ghoul_unhealthy_taste") then
        targetMax = 125
    end

    if ply:Horde_GetPerk("ghoul_humanity") then
        targetMax = math.floor(targetMax * 1.20)
    end

    if ply:GetMaxHealth() == targetMax then return end

    local wasAtFull = (ply:Health() >= ply:GetMaxHealth())
    ply:SetMaxHealth(targetMax)

    if wasAtFull then
        ply:SetHealth(targetMax)
    elseif ply:Health() > targetMax then
        ply:SetHealth(targetMax)
    end
end

function Ghoul_ScheduleMaxHPRecalc(ply)
    timer.Simple(0, function()
        Ghoul_RecalcMaxHP(ply)
    end)
end

PERK.Hooks.Horde_PlayerMoveBonus = function(ply, bonus_walk, bonus_run)
    if not IsValid(ply) or not ply:Horde_GetPerk("ghoul_base") then return end

    local ratio = 1 - (ply:Health() / ply:GetMaxHealth())
    ratio = math.Clamp(ratio, 0, 1)
    bonus_walk.increase = bonus_walk.increase + ratio
    bonus_run.increase  = bonus_run.increase  + ratio

    if ply:Horde_GetPerk("ghoul_unhealthy_taste") then
        local hpAbove100 = math.max(0, ply:Health() - 100)
        local penalty    = math.floor(hpAbove100 / 10) * 0.01
        bonus_walk.increase = bonus_walk.increase - penalty
        bonus_run.increase  = bonus_run.increase  - penalty
    end

    if ply:Horde_GetPerk("ghoul_light_speed") then
        bonus_walk.increase = bonus_walk.increase + 0.30
        bonus_run.increase  = bonus_run.increase  + 0.30
    end

    if ply:Horde_GetPerk("ghoul_insatiable_thirst") then
        bonus_walk.increase = bonus_walk.increase + 0.10
        bonus_run.increase  = bonus_run.increase  + 0.10
    end

    if ply:Horde_GetPerk("ghoul_quickest_of_all") then
        bonus_walk.increase = bonus_walk.increase + 0.10
        bonus_run.increase  = bonus_run.increase  + 0.10
    end
end

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if not SERVER then return end
    if perk ~= "ghoul_base" then return end

    Ghoul_ScheduleMaxHPRecalc(ply)

    local timerID = "Ghoul_Drain_" .. ply:SteamID64()
    ply._ghoul_drain_acc = 0

    timer.Create(timerID, 0.25, 0, function()
        if not IsValid(ply) then timer.Remove(timerID) return end
        if not ply:Alive() then return end

        Ghoul_RecalcMaxHP(ply)

        if HORDE.current_break_time > 0 then return end

        local drainRate = 1.0

        if ply:Horde_GetPerk("ghoul_cornered_beast") then
            if ply:GetVelocity():LengthSqr() < 100 then
                drainRate = drainRate * 0.85
            end
        end

        ply._ghoul_drain_acc = (ply._ghoul_drain_acc or 0) + drainRate
        if ply._ghoul_drain_acc < 1 then return end
        ply._ghoul_drain_acc = ply._ghoul_drain_acc - 1

        local CurHP = ply:Health()

        if ply:Horde_GetPerk("ghoul_glass_cannon") then
            if CurHP <= 30 then return end
            ply:SetHealth(math.max(30, CurHP - 10))
        else
            if CurHP <= 1 and not ply.Ghoul_AppetiteInvincible then
                ply:Kill()
            else
                ply:SetHealth(CurHP - 1)
            end
        end
    end)
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if not SERVER then return end
    if perk ~= "ghoul_base" then return end

    timer.Remove("Ghoul_Drain_" .. ply:SteamID64())
    ply._ghoul_drain_acc = 0
    ply:SetMaxHealth(100)
    if ply:Health() > 100 then ply:SetHealth(100) end
    ply:SetArmor(0)
end

PERK.Hooks.DoPlayerDeath = function(ply, attacker, dmginfo)
    if SERVER and ply:Horde_GetPerk("ghoul_base") then
        if HORDE.current_break_time > 0 then return end
        local ent = ents.Create("npc_vj_zss_slow")
        if IsValid(ent) then
            ent:SetPos(ply:GetPos())
            ent:SetAngles(ply:GetAngles())
            ent:Spawn()
            ent:Activate()
        end
    end
end

PERK.Hooks.EntityTakeDamage = function(target, dmginfo)
    if not SERVER then return end

    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not attacker:Horde_GetPerk("ghoul_base") then return end
    if not IsValid(target) or not target:IsNPC() then return end

    local damage = dmginfo:GetDamage()
    if damage <= 0 then return end

    local enemyMaxHP = target:GetMaxHealth()
    if not enemyMaxHP or enemyMaxHP <= 0 then enemyMaxHP = 100 end

    local healAmount = math.min(damage, enemyMaxHP * PARAMS[1].value)

    if attacker:Horde_GetPerk("ghoul_quickest_of_all") then
        healAmount = healAmount * 0.75
    end

    local curHP = attacker:Health()
    local maxHP = attacker:GetMaxHealth()
    if curHP < maxHP then
        attacker:SetHealth(math.min(curHP + healAmount, maxHP))
    end
end

PERK.OwnerHooks.Horde_OnPlayerHeal = function(ply, healinfo)
    if not ply:Horde_GetPerk("ghoul_base") then return end
    if ply:Horde_GetPerk("ghoul_humanity") then
        healinfo.amount = healinfo.amount * 0.1
    else
        healinfo.amount = 0
    end
end

PERK.Hooks.Horde_PrecomputePerkLevelBonus = function(ply)
    if SERVER then
        ply:Horde_SetPerkLevelBonus(
            "ghoul_base",
            math.min(0.50, 0.005 * ply:Horde_GetLevel("Ghoul"))
        )
    end
end

PERK.OwnerHooks.Horde_OnPlayerDebuffApply = function(ply, debuff, bonus, inflictor)
    if not ply:Horde_GetPerk("ghoul_base") then return end

    local levelResist = ply:Horde_GetPerkLevelBonus("ghoul_base")
    if levelResist > 0 then
        bonus.less = bonus.less * (1 - levelResist)
    end

    if debuff == HORDE.Status_Break or debuff == HORDE.Status_Bleeding then
        bonus.less = bonus.less * 0.75
    end
end
