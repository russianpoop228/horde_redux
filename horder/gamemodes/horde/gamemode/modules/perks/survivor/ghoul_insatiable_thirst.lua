PERK.PrintName   = "Insatiable Thirst"
PERK.Description = [[Gain {1} or {2} HP on each bullet hit.
Bullets run out faster.
{3} chance on kill to gain a random bonus.]]

PERK.Icon   = "materials/perks/ghoul/insatiable_thirst.png"
PERK.Params = {
    [1] = {value = 1},
    [2] = {value = 2},
    [3] = {value = 0.15, percent = true},
}
PERK.Hooks = {}

local HEAL_MIN    = PERK.Params[1].value
local HEAL_MAX    = PERK.Params[2].value
local KILL_CHANCE = PERK.Params[3].value
local MAX_ARMOR   = 100

local KILL_REWARDS = {
    "gadget_agility_shard",
    "gadget_cleansing_shard",
    "gadget_damage_shard",
    "gadget_vitality_shard",
    "bonus_armor",
}

local REWARD_NOTIFY = {
    gadget_agility_shard   = "Insatiable Thirst: Agility Shard!",
    gadget_cleansing_shard = "Insatiable Thirst: Cleansing Shard!",
    gadget_damage_shard    = "Insatiable Thirst: Damage Shard!",
    gadget_vitality_shard  = "Insatiable Thirst: Vitality Heal +25 HP!",
    bonus_armor            = "Insatiable Thirst: +10 Armor!",
}

local REWARD_SOUNDS = {
    "plats/elevbell1.wav",
    "hl1/fvox/bell.wav",
}

local function UseGadgetEffect(ply, class)
    local gadget  = HORDE.gadgets and HORDE.gadgets[class]
    local handler = gadget and gadget.Hooks and gadget.Hooks.Horde_UseActiveGadget
    if not handler then return false end

    ply.Horde_Debuff_Buildup = ply.Horde_Debuff_Buildup or {}

    local prev = ply.Horde_Gadget
    ply.Horde_Gadget = class
    local ok, err = pcall(handler, ply)
    ply.Horde_Gadget = prev

    if not ok then
        ErrorNoHalt("[Insatiable Thirst] " .. class .. ": " .. tostring(err) .. "\n")
    end
    return ok
end

local function ApplyReward(ply, reward)
    if reward == "bonus_armor" then
        ply:SetArmor(math.min(ply:Armor() + 10, MAX_ARMOR))

    elseif reward == "gadget_vitality_shard" then
        local curHP = ply:Health()
        local maxHP = ply:GetMaxHealth()
        ply:SetHealth(math.min(curHP + 25, maxHP))

    elseif not UseGadgetEffect(ply, reward) then
        return
    end

    sound.Play(REWARD_SOUNDS[math.random(#REWARD_SOUNDS)], ply:GetPos(), 75, math.random(90, 110))
    HORDE:SendNotification(REWARD_NOTIFY[reward], 0, ply)
end

PERK.Hooks.Horde_OnPlayerDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    if not SERVER then return end
    if not ply:Horde_GetPerk("ghoul_insatiable_thirst") then return end

    if not HORDE:IsBallisticDamage(dmginfo) then return end

    local inflictor = dmginfo:GetInflictor()
    if not IsValid(inflictor) then return end
    if inflictor ~= ply and not (inflictor:IsWeapon() and inflictor:GetOwner() == ply) then return end

    local curHP = ply:Health()
    local maxHP = ply:GetMaxHealth()
    if curHP < maxHP then
        ply:SetHealth(math.min(curHP + math.random(HEAL_MIN, HEAL_MAX), maxHP))
    end

    local wpn = HORDE:GetCurrentWeapon(inflictor)
    if IsValid(wpn) and wpn:IsWeapon() then
        local clip = wpn:Clip1()
        if clip > 0 then
            wpn:SetClip1(clip - 1)
        end
    end
end

PERK.Hooks.Horde_OnEnemyKilled = function(victim, killer, wpn)
    if not IsValid(killer) or not killer:IsPlayer() then return end
    if not killer:Horde_GetPerk("ghoul_insatiable_thirst") then return end

    if math.random() > KILL_CHANCE then return end

    ApplyReward(killer, KILL_REWARDS[math.random(#KILL_REWARDS)])
end
