SPELL.PrintName     = "Frost Bolt"
SPELL.Weapon        = { "horde_solar_seal" }
SPELL.Mind          = { 5, 10, 15 }
SPELL.ChargeTime    = { 0, 0.5, 1 }
SPELL.Cooldown      = 1
SPELL.Slot          = HORDE.Spell_Slot_RMB
SPELL.DamageType    = { HORDE.DMG_COLD }
SPELL.Type          = { HORDE.Spell_Type_Hitscan }
SPELL.Icon          = "spells/solar_bolt.png"
SPELL.Description   = [[Strikes the target with frost. Charge to increase damage and Frostbite buildup.]]
SPELL.Price         = 400
SPELL.Levels        = { Artificer = 1 }

SPELL.Fire = function(ply, wpn, charge_stage)
    local src = ply:GetShootPos()
    local dir = ply:GetAimVector()
    local tr = util.TraceLine({ start = src, endpos = src + dir * 1500, filter = ply })
    if not tr.Hit then return end

    wpn:FireBullets({
        Attacker = ply,
        Damage   = 20 * charge_stage,
        Tracer   = 0,
        Distance = 1500,
        Dir      = dir,
        Src      = src,
        Spread   = Vector(0, 0, 0),
    })

    if HORDE:IsEnemy(tr.Entity) then
        tr.Entity:Horde_AddDebuffBuildup(HORDE.Status_Frostbite, 20 * charge_stage, ply, tr.HitPos)
    end
    ply:EmitSound("horde/weapons/solar_seal/solar_storm_launch.ogg", 100, math.random(130, 150))
end
