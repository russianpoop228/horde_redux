PERK.PrintName = "Pneumatic Legs"
PERK.Description =
[[Adds {1} maximum Hypertrophy stacks.
Press SPACE in air to descend, dealing area Physical damage based on your speed.
{2} reduced fall damage taken.]]
PERK.Icon = "materials/perks/carcass/pneumatic_legs.png"
PERK.Params = {
    [1] = {value = 1},
    [2] = {value = 0.9, percent = true},
    [3] = {value = 5},
}
PERK.Hooks = {}

PERK.HypertrophyMaxBonus = 1

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if SERVER and perk == "carcass_pneumatic_legs" then
        ply.Horde_Pneumatic_Leg_Ready = true
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "carcass_pneumatic_legs" then
        ply.Horde_Pneumatic_Leg_Ready = nil
    end
end

PERK.OwnerHooks.Horde_GetFallDamage = function(ply, speed, bonus)
    if ply:Horde_GetPerk("carcass_pneumatic_legs") then
        bonus.less = bonus.less * 0.1
        local dmg = math.max(0, math.ceil(0.2418 * speed - 141.75)) * 2
        if dmg < 10 then return end
        local dmginfo = DamageInfo()
        dmginfo:SetAttacker(ply)
        dmginfo:SetInflictor(ply)
        dmginfo:SetDamageType(DMG_GENERIC)
        dmginfo:SetDamage(dmg)
        dmginfo:SetDamagePosition(ply:GetPos())
        util.BlastDamageInfo(dmginfo, ply:GetPos(), 250)
        local e = EffectData()
            e:SetNormal(Vector(0,0,1))
            e:SetOrigin(ply:GetPos())
            e:SetRadius(250)
        util.Effect("seismic_wave", e, true, true)
        ply.Horde_Pneumatic_Leg_Ready = true
    end
end

PERK.Hooks.PlayerButtonDown = function (ply, key)
    if key == KEY_SPACE and ply:Horde_GetPerk("carcass_pneumatic_legs") and !ply:IsOnGround() then
        local dir = Vector(0,0,-1)
        local vel = dir * math.max(590, (ply:GetVelocity():Length() + 250))
        ply:SetLocalVelocity(vel)
    end
end
