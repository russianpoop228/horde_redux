PERK.PrintName = "Quickest Of All"
PERK.Description = [[{1} decreased health regen from attacking enemies.
{2} increased attack speed.
{3} increased movement speed]]

PERK.Icon = "materials/perks/ghoul/quickest_of_all.png"
PERK.Params = {
    [1] = {value = 0.25, percent = true},
    [2] = {value = 0.25, percent = true},
    [3] = {value = 0.10, percent = true}
}

PERK.Hooks = {}

local ATTACK_SPEED_BONUS = PERK.Params[2].value

function HORDE:GetGhoulAttackSpeedMult(ply)
    if IsValid(ply) and ply:IsPlayer() and ply.Horde_GetPerk and ply:Horde_GetPerk("ghoul_quickest_of_all") then
        return 1 + ATTACK_SPEED_BONUS
    end
    return 1
end

PERK.Hooks.M_Hook_Mult_RPM = function(wpn, data)
    local ply = wpn:GetOwner()
    if IsValid(ply) and ply:IsPlayer() and ply:Horde_GetPerk("ghoul_quickest_of_all") then
        data.mult = (data.mult or 1) + ATTACK_SPEED_BONUS
    end
end

local function ShortenDelay(wep, getter, setter, before, ct, mult)
    local after = wep[getter](wep)
    if after > before then
        local delay = after - ct
        if delay > 0 then
            wep[setter](wep, ct + delay / mult)
        end
    end
end

local function WrapAttack(wep, fname)
    local orig = wep[fname]
    if not isfunction(orig) then return end

    wep[fname] = function(self, ...)
        local mult = HORDE:GetGhoulAttackSpeedMult(self:GetOwner())
        if mult <= 1 then return orig(self, ...) end

        local ct = CurTime()
        local p0, s0 = self:GetNextPrimaryFire(), self:GetNextSecondaryFire()

        local ret = orig(self, ...)

        if IsValid(self) then
            ShortenDelay(self, "GetNextPrimaryFire",   "SetNextPrimaryFire",   p0, ct, mult)
            ShortenDelay(self, "GetNextSecondaryFire", "SetNextSecondaryFire", s0, ct, mult)
        end
        return ret
    end
end

PERK.Hooks.PlayerTick = function(ply, mv)
    if not ply.Horde_GetPerk or not ply:Horde_GetPerk("ghoul_quickest_of_all") then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep.Horde_QuickestWrapped then return end
    wep.Horde_QuickestWrapped = true

    if wep.ArcCW or wep.Horde_HandlesAttackSpeed or wep.Base == "horde_spell_weapon_base" then return end
    if not wep:IsScripted() then return end

    WrapAttack(wep, "PrimaryAttack")
    WrapAttack(wep, "SecondaryAttack")
end

local function RecalcWeapons(ply, perk)
    if perk == "ghoul_quickest_of_all" then
        for _, wpn in pairs(ply:GetWeapons()) do
            if wpn.ArcCW then wpn:RecalcAllBuffs() end
        end
    end
end
PERK.Hooks.Horde_OnSetPerk   = RecalcWeapons
PERK.Hooks.Horde_OnUnsetPerk = RecalcWeapons
