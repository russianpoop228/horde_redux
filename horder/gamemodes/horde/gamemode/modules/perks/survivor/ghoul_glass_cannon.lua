if not HORDE.Status_Ghoul_GlassCannon then
    HORDE:RegisterStatus("Ghoul_GlassCannon", "materials/perks/ghoul/glass_cannon.png", nil, nil, true)
end

PERK.PrintName   = "Glass Cannon"
PERK.Description = [[Health drain increases to 10 HP per tick, but stops at 30 HP.
At 30 HP or below: 50% chance to die every 30 seconds (countdown shown as a status icon).
The lower your HP, the more damage you deal (up to x2 at 30 HP).]]

PERK.Icon   = "materials/perks/ghoul/glass_cannon.png"
PERK.Params = {}
PERK.Hooks  = {}

local DRAIN_FLOOR   = 30
local DICE_INTERVAL = 30
local DICE_CHANCE   = 0.50
local MAX_DMG_BONUS = 1.0

local function GC_ShowIcon(ply)
    net.Start("Horde_SyncActivePerk")
        net.WriteUInt(HORDE.Status_Ghoul_GlassCannon, 8)
        net.WriteUInt(1, 3)
    net.Send(ply)
end

local function GC_HideIcon(ply)
    net.Start("Horde_SyncActivePerk")
        net.WriteUInt(HORDE.Status_Ghoul_GlassCannon, 8)
        net.WriteUInt(0, 3)
    net.Send(ply)
end

local function GC_StartCountdown(ply, seconds)
    net.Start("Horde_PerkStartCooldown")
        net.WriteUInt(seconds, 8)
    net.Send(ply)
end

PERK.OwnerHooks.Horde_OnPlayerDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    if not ply:Horde_GetPerk("ghoul_glass_cannon") then return end

    local curHP = ply:Health()
    local maxHP = ply:GetMaxHealth()
    if curHP >= maxHP then return end

    local span  = math.max(1, maxHP - DRAIN_FLOOR)
    local ratio = math.Clamp((maxHP - curHP) / span, 0, 1)
    bonus.increase = bonus.increase + (ratio * MAX_DMG_BONUS)
end

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if not SERVER then return end
    if perk ~= "ghoul_glass_cannon" then return end

    local sid = ply:SteamID64()

    ply._gc_in_danger   = false
    ply._gc_next_roll   = nil

    timer.Create("GlassCannon_Monitor_" .. sid, 0.5, 0, function()
        if not IsValid(ply) then
            timer.Remove("GlassCannon_Monitor_" .. sid)
            return
        end
        if not ply:Horde_GetPerk("ghoul_glass_cannon") then
            timer.Remove("GlassCannon_Monitor_" .. sid)
            return
        end

        if not ply:Alive() then
            if ply._gc_in_danger then
                ply._gc_in_danger = false
                ply._gc_next_roll = nil
                GC_HideIcon(ply)
                GC_StartCountdown(ply, 0)
            end
            return
        end

        local inDanger = (ply:Health() <= DRAIN_FLOOR)

        if inDanger and not ply._gc_in_danger then
            ply._gc_in_danger = true
            ply._gc_next_roll = CurTime() + DICE_INTERVAL
            GC_ShowIcon(ply)
            GC_StartCountdown(ply, DICE_INTERVAL)

        elseif not inDanger and ply._gc_in_danger then
            ply._gc_in_danger = false
            ply._gc_next_roll = nil
            GC_HideIcon(ply)
            GC_StartCountdown(ply, 0)
        end

        if ply._gc_in_danger and ply._gc_next_roll and CurTime() >= ply._gc_next_roll then
            if math.random() < DICE_CHANCE then
                ply._gc_in_danger = false
                ply._gc_next_roll = nil
                GC_HideIcon(ply)
                GC_StartCountdown(ply, 0)
                ply:Kill()
                return
            end

            ply._gc_next_roll = CurTime() + DICE_INTERVAL
            GC_StartCountdown(ply, DICE_INTERVAL)
        end
    end)
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if not SERVER then return end
    if perk ~= "ghoul_glass_cannon" then return end

    timer.Remove("GlassCannon_Monitor_" .. ply:SteamID64())
    ply._gc_in_danger = false
    ply._gc_next_roll = nil

    GC_HideIcon(ply)
    GC_StartCountdown(ply, 0)
end
