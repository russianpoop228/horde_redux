if SERVER then
    util.AddNetworkString("Horde_SyncActivePerk")
end

HORDE.Status_Icon = {}
HORDE.Status_Id = 0
HORDE.Is_Status_Stackable = {}
HORDE.Is_Status_Debuff = {}
HORDE.Is_Status_Skill = {}
HORDE.Is_Status_StackableSkill = {}
HORDE.Status_String = {}
HORDE.Status_ByName = HORDE.Status_ByName or {}
HORDE.Status_DrawFuncs = HORDE.Status_DrawFuncs or {}
HORDE.Status_UsePerkCooldown = HORDE.Status_UsePerkCooldown or {}

function HORDE:RegisterStatus(name_or_tbl, icon, stackable, is_debuff, is_skill)
    local name, tbl
    local is_stackable_skill, use_perk_cd, draw_fn
    if istable(name_or_tbl) then
        tbl = name_or_tbl
        name = tbl.Name or tbl.name or tbl.PrintName
        icon = tbl.Icon or tbl.icon or icon
        stackable = tbl.Stackable or tbl.stackable or stackable
        is_debuff = tbl.IsDebuff or tbl.is_debuff or is_debuff
        is_skill = tbl.IsSkill or tbl.is_skill or is_skill
        is_stackable_skill = tbl.IsStackableSkill or tbl.is_stackable_skill
        use_perk_cd = tbl.UsePerkCooldown
        if use_perk_cd == nil then use_perk_cd = tbl.use_perk_cooldown end
        draw_fn = tbl.Draw or tbl.draw
    else
        name = name_or_tbl
    end

    if not name or name == "" then
        ErrorNoHaltWithStack("[Horde Status] RegisterStatus: empty Name\n")
        return nil
    end

    if HORDE.Status_ByName[name] ~= nil then
        MsgC(Color(255, 255, 0), "[Horde Status] Status already registered: " .. name .. " (id=" .. tostring(HORDE.Status_ByName[name]) .. ")\n")
        return HORDE.Status_ByName[name]
    end

    if HORDE.Status_Id >= 256 then
        ErrorNoHaltWithStack("[HORDE] Ran out of status ids!\n")
        return nil
    end

    local id = HORDE.Status_Id
    local s = "Status_" .. name
    HORDE[s] = id
    HORDE.Status_Icon[id] = icon
    HORDE.Status_String[id] = name
    HORDE.Status_ByName[name] = id

    if stackable == true then
        HORDE.Is_Status_Stackable[id] = true
    end
    if is_debuff == true then
        HORDE.Is_Status_Debuff[id] = true
    end
    if is_skill == true then
        HORDE.Is_Status_Skill[id] = true
        if use_perk_cd == nil then use_perk_cd = true end
    end
    if is_stackable_skill == true then
        HORDE.Is_Status_StackableSkill[id] = true
    end
    if use_perk_cd == true then
        HORDE.Status_UsePerkCooldown[id] = true
    elseif use_perk_cd == false then
        HORDE.Status_UsePerkCooldown[id] = false
    end
    if isfunction(draw_fn) then
        HORDE.Status_DrawFuncs[id] = draw_fn
    end

    if tbl then
        if tbl.BuildupSound then
            HORDE.Status_Buildup_Sounds = HORDE.Status_Buildup_Sounds or {}
            HORDE.Status_Buildup_Sounds[id] = tbl.BuildupSound
        end
        if tbl.TriggerSound then
            HORDE.Status_Trigger_Sounds = HORDE.Status_Trigger_Sounds or {}
            HORDE.Status_Trigger_Sounds[id] = tbl.TriggerSound
        end
        if tbl.Notification then
            HORDE.Debuff_Notifications = HORDE.Debuff_Notifications or {}
            HORDE.Debuff_Notifications[id] = tbl.Notification
        end
    end

    HORDE.Status_Id = HORDE.Status_Id + 1
    hook.Run("Horde_OnStatusRegistered", name, id, tbl)
    return id
end

function HORDE:GetStatusID(name)
    return HORDE.Status_ByName and HORDE.Status_ByName[name]
end

HORDE:RegisterStatus("CanBuy", "materials/status/canbuy.png")
HORDE:RegisterStatus("CanEscape", "materials/status/escape.png")
HORDE:RegisterStatus("CanHold", "materials/status/hold.png")
HORDE:RegisterStatus("HasPayload", "materials/status/objective.png")
HORDE:RegisterStatus("AntimatterShield", "materials/perks/antimatter_shield.png", nil, nil, true)
HORDE:RegisterStatus("Displacer", "materials/perks/displacer.png", nil, nil, true)
HORDE:RegisterStatus({
    Name = "Quickstep",
    Icon = "materials/abilities/quickstep.png",
    IsSkill = true,
    IsStackableSkill = true,
    UsePerkCooldown = true,
})
HORDE:RegisterStatus("Hunter_Mark", "materials/status/hunter_mark.png", nil, nil, true)
HORDE:RegisterStatus("Smokescreen", "materials/perks/specops/smokescreen.png", nil, nil, true)
HORDE:RegisterStatus("Flare", "materials/perks/specops/flare.png", nil, nil, true)
HORDE:RegisterStatus("AAS_Perfume", "materials/perks/carcass/AAS_Perfume.png", nil, nil, true)
HORDE:RegisterStatus("Juxtapose", "materials/perks/overlord/juxtapose.png", nil, nil, true)
HORDE:RegisterStatus("DarkEnergyBlast", "materials/perks/overlord/dark_energy_blast.png", nil, nil, true)
HORDE:RegisterStatus("Steadfast_Parry", "materials/perks/bushido.png", nil, nil, true)

HORDE:RegisterStatus("Tactical_Mode", "materials/status/tactical_mode.png")
HORDE:RegisterStatus("Camoflague", "materials/status/camoflague.png")
HORDE:RegisterStatus("Frenzy_Mode", "materials/subclasses/psycho.png")

HORDE:RegisterStatus("Minion", "materials/status/minion.png", true)
HORDE:RegisterStatus("Adrenaline", "materials/status/adrenaline.png", true)
HORDE:RegisterStatus("Headhunter", "materials/perks/headhunter.png", true)
HORDE:RegisterStatus("Deadeye", "materials/perks/gunslinger/deadeye.png", true)
HORDE:RegisterStatus("Intensity", "materials/perks/artificer/intensity.png", true)
HORDE:RegisterStatus("Neuron_Stabilizer", "materials/perks/specops/neuron_stabilizer.png", true)
HORDE:RegisterStatus("Phalanx", "materials/perks/phalanx.png", true)
HORDE:RegisterStatus("Brutality", "materials/perks/psycho/brutality.png", true)
HORDE:RegisterStatus("Hypertrophy", "materials/status/hypertrophy.png", true)
HORDE:RegisterStatus("SolarFlux", "materials/perks/artificer/solar_flux.png", true)
HORDE:RegisterStatus("Bio_Thruster", "materials/perks/carcass/bio_thruster.png", true)
HORDE:RegisterStatus("Twin_Heart", "materials/perks/carcass/twin_heart.png", true)
HORDE:RegisterStatus("Hysteria", "materials/perks/overlord/despair.png", true)

HORDE:RegisterStatus("Fortify", "materials/perks/fortify.png")
HORDE:RegisterStatus("Berserk", "materials/perks/berserk.png")
HORDE:RegisterStatus("Haste", "materials/perks/haste.png")
HORDE:RegisterStatus("Sandcloak", "materials/perks/hatcher/sand_cloak.png")
HORDE:RegisterStatus("VileBlood", "materials/perks/hatcher/vile_blood.png")
HORDE:RegisterStatus("FleshEater", "materials/perks/hatcher/flesh_eater.png")
HORDE:RegisterStatus("SigilArcana", "materials/spells/sigil_of_arcana.png")
HORDE:RegisterStatus("SigilAlacrity", "materials/spells/sigil_of_alacrity.png")
HORDE:RegisterStatus("Enlighten", "materials/spells/enlighten.png")
HORDE:RegisterStatus("ArmorRegen", "materials/status/armorregen.png")
HORDE:RegisterStatus("HealthRegen", "materials/status/healthregen.png")
HORDE:RegisterStatus("Quickdraw", "materials/perks/gunslinger/quickdraw.png")
HORDE:RegisterStatus("WardenAura", "materials/warden.png")
HORDE:RegisterStatus("ReactiveArmor", "materials/perks/reactive_armor.png")
HORDE:RegisterStatus("EntropyShield", "materials/perks/entropy_shield.png")
HORDE:RegisterStatus("Tactical_Spleen", "materials/perks/carcass/tactical_spleen.png")
HORDE:RegisterStatus("Foresight", "materials/perks/samurai/foresight.png")
HORDE:RegisterStatus("Smuggle", "materials/perks/gunslinger/smuggle_shop.png")
HORDE:RegisterStatus("Phantom_Reload", "materials/perks/gunslinger/phantom_reload.png")
HORDE:RegisterStatus("Smokescreen_Effect", "materials/perks/specops/smokescreen.png")
HORDE:RegisterStatus("Unwavering_Guard", "materials/perks/unwavering_guard.png")
HORDE:RegisterStatus("Damage_Shard", "materials/status/damage.png")
HORDE:RegisterStatus("Agility_Shard", "materials/status/speed.png")
HORDE:RegisterStatus("Assassin_Optics", "materials/status/gadget/assassin_optics.png")
HORDE:RegisterStatus("Aegis", "materials/status/gadget/aegis.png")

HORDE:RegisterStatus("Armor_Survivor", "items/armor_survivor.png")
HORDE:RegisterStatus("Armor_Assault", "items/armor_assault.png")
HORDE:RegisterStatus("Armor_Heavy", "items/armor_heavy.png")
HORDE:RegisterStatus("Armor_Demolition", "items/armor_demolition.png")
HORDE:RegisterStatus("Armor_Ghost", "items/armor_ghost.png")
HORDE:RegisterStatus("Armor_Medic", "items/armor_medic.png")
HORDE:RegisterStatus("Armor_Engineer", "items/armor_engineer.png")
HORDE:RegisterStatus("Armor_Warden", "items/armor_warden.png")
HORDE:RegisterStatus("Armor_Cremator", "items/armor_cremator.png")
HORDE:RegisterStatus("Armor_Berserker", "items/armor_berserker.png")

HORDE:RegisterStatus("ExpDisabled", "materials/status/exp_disabled.png")
HORDE:RegisterStatus("Bleeding", "materials/status/bleeding.png", nil, true)
HORDE:RegisterStatus("Ignite", "materials/status/ignite.png", nil, true)
HORDE:RegisterStatus("Frostbite", "materials/status/frostbite.png", nil, true)
HORDE:RegisterStatus("Shock", "materials/status/shock.png", nil, true)
HORDE:RegisterStatus("Break", "materials/status/break.png", nil, true)
HORDE:RegisterStatus("Decay", "materials/status/decay.png", nil, true)
HORDE:RegisterStatus("Necrosis", "materials/status/necrosis.png", nil, true)
HORDE:RegisterStatus("Psychosis", "materials/status/psychosis.png", nil, true)
HORDE:RegisterStatus("Stun", "materials/perks/knockout.png", nil, true)
HORDE:RegisterStatus("Freeze", "materials/status/frostbite.png", nil, true)
HORDE:RegisterStatus("Weaken", "materials/perks/crude_casing.png", nil, true)
HORDE:RegisterStatus("Hinder", "materials/perks/sticky_compound.png", nil, true)
HORDE:RegisterStatus("Hemorrhage", "materials/status/hemorrhage.png", nil, true)
HORDE:RegisterStatus("Fear", "materials/status/fear.png", nil, true)

HORDE.Status_Buildup_Sounds = {}
HORDE.Status_Buildup_Sounds[HORDE.Status_Bleeding] = "horde/status/bleeding_buildup.ogg"
HORDE.Status_Buildup_Sounds[HORDE.Status_Frostbite] = "horde/status/frostbite_buildup.ogg"
HORDE.Status_Buildup_Sounds[HORDE.Status_Shock] = "weapons/stunstick/stunstick_fleshhit2.wav"
HORDE.Status_Buildup_Sounds[HORDE.Status_Break] = "ambient/levels/canals/toxic_slime_sizzle1.wav"
HORDE.Status_Buildup_Sounds[HORDE.Status_Necrosis] = "horde/status/necrosis_buildup.ogg"

HORDE.Status_Trigger_Sounds = {}
HORDE.Status_Trigger_Sounds[HORDE.Status_Bleeding] = "horde/status/bleeding_trigger.ogg"
HORDE.Status_Trigger_Sounds[HORDE.Status_Frostbite] = "horde/status/frostbite_trigger.ogg"
HORDE.Status_Trigger_Sounds[HORDE.Status_Shock] = "horde/status/shock_trigger.ogg"
HORDE.Status_Trigger_Sounds[HORDE.Status_Break] = "horde/status/break_trigger.ogg"
HORDE.Status_Trigger_Sounds[HORDE.Status_Necrosis] = ""

HORDE.Debuff_Notifications = {
    [HORDE.Status_Bleeding] = "You are inflicted by Bleeding.\nYour health is removed over time.",
    [HORDE.Status_Ignite] = "You are inflicted by Ignite.\nYou take Fire damage over time.",
    [HORDE.Status_Frostbite] = "You are inflicted by Frostbite.\nYour movement speed is reduced.",
    [HORDE.Status_Shock] = "You are inflicted by Shock.\nYou take increased damage from all sources.",
    [HORDE.Status_Break] = "You are inflicted by Break.\nYour health is reduced drastically and will recover slowly.",
    [HORDE.Status_Decay] = "You are inflicted by Decay.\nYou cannot heal.",
    [HORDE.Status_Psychosis] = "Y'ai 'ng'ngah, Yog-Sothoth h'ee - l'geb f'ai throdog uaaah.",
    [HORDE.Status_Necrosis] = "You are dying from Necrosis."
}

local plymeta = FindMetaTable("Player")
function plymeta:Horde_SyncStatus(status, stack)
    net.Start("Horde_SyncStatus")
    net.WriteUInt(status, 8)
    net.WriteUInt(stack, 8)
    net.Send(self)
end

function HORDE:IsStatusStackable(status)
    return HORDE.Is_Status_Stackable[status]
end

function HORDE:IsDebuff(status)
    return HORDE.Is_Status_Debuff[status]
end

function HORDE:IsStatusImmune(ent, status)
    if not IsValid(ent) or ent:IsPlayer() then return false end
    if ent.Horde_Immune_Status_All then return true end
    local list = ent.Horde_Immune_Status
    if status ~= nil and istable(list) and list[status] then return true end
    return false
end

function HORDE:IsPlayerSpectator(ent)
    if not IsValid(ent) or not ent:IsPlayer() then return false end
    if ent.Horde_SpectatorGhost then return true end
    if ent.Horde_Fake_Respawn then return true end
    if ent:GetMoveType() == MOVETYPE_OBSERVER then return true end
    local obs = ent:GetObserverMode()
    return obs ~= nil and obs ~= OBS_MODE_NONE
end

HORDE.Status_ImmunityFlags = HORDE.Status_ImmunityFlags or {
    [HORDE.Status_Ignite]    = { "Immune_Fire" },
    [HORDE.Status_Frostbite] = { "Immune_Cold" },
    [HORDE.Status_Shock]     = { "Immune_Electricity" },
    [HORDE.Status_Break]     = { "Immune_AcidPoisonRadiation" },
    [HORDE.Status_Necrosis]  = { "Immune_Dissolve" },
}

function HORDE:IsImmuneToStatusDamageType(ent, status)
    if not IsValid(ent) or status == nil then return false end
    local flags = HORDE.Status_ImmunityFlags[status]
    if not flags then return false end
    for _, flag in ipairs(flags) do
        if ent[flag] then return true end
    end
    return false
end

function HORDE:IsSkillStatus(status)
    return HORDE.Is_Status_Skill[status]
end

function HORDE:IsStackableSkillStatus(status)
    if HORDE.Is_Status_StackableSkill[status] then return true end
    if status == HORDE.Status_Quickstep then return true end
    return false
end

function HORDE:StatusUsesPerkCooldown(status)
    local v = HORDE.Status_UsePerkCooldown[status]
    if v ~= nil then return v end
    return HORDE:IsSkillStatus(status)
end

if SERVER then
    util.AddNetworkString("Horde_SyncStatusCooldown")
    util.AddNetworkString("Horde_SyncStatusCharges")
end

function plymeta:Horde_SetStatusCooldown(status, duration)
    if not status then return end
    self.Horde_StatusCooldown = self.Horde_StatusCooldown or {}
    if duration and duration > 0 then
        self.Horde_StatusCooldown[status] = CurTime() + duration
    else
        self.Horde_StatusCooldown[status] = nil
    end
    if SERVER then
        net.Start("Horde_SyncStatusCooldown")
            net.WriteUInt(status, 8)
            net.WriteFloat(self.Horde_StatusCooldown[status] or 0)
        net.Send(self)
    end
end

function plymeta:Horde_GetStatusCooldown(status)
    if not status or not self.Horde_StatusCooldown then return 0 end
    local endt = self.Horde_StatusCooldown[status]
    if not endt then return 0 end
    return math.max(0, math.ceil(endt - CurTime()))
end

function plymeta:Horde_SetStatusCharges(status, amount)
    if not status then return end
    self.Horde_StatusCharges = self.Horde_StatusCharges or {}
    self.Horde_StatusCharges[status] = amount
    if SERVER then
        net.Start("Horde_SyncStatusCharges")
            net.WriteUInt(status, 8)
            net.WriteInt(amount or -1, 16)
        net.Send(self)
    end
end

function plymeta:Horde_GetStatusCharges(status)
    if not status or not self.Horde_StatusCharges then return -1 end
    local v = self.Horde_StatusCharges[status]
    if v == nil then return -1 end
    return v
end

if CLIENT then
    net.Receive("Horde_SyncStatusCooldown", function()
        local status = net.ReadUInt(8)
        local endt = net.ReadFloat()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        ply.Horde_StatusCooldown = ply.Horde_StatusCooldown or {}
        if endt > 0 then
            ply.Horde_StatusCooldown[status] = endt
        else
            ply.Horde_StatusCooldown[status] = nil
        end
    end)

    net.Receive("Horde_SyncStatusCharges", function()
        local status = net.ReadUInt(8)
        local amount = net.ReadInt(16)
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        ply.Horde_StatusCharges = ply.Horde_StatusCharges or {}
        ply.Horde_StatusCharges[status] = amount
    end)
end
