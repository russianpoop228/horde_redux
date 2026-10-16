if not ArcCWInstalled then return end
if CLIENT then
    SWEP.WepSelectIcon = surface.GetTextureID("arccw/weaponicons/arccw_horde_apollo")
    killicon.Add("arccw_horde_apollo", "arccw/weaponicons/arccw_horde_apollo", Color(0, 0, 0, 255))
    killicon.AddAlias("projectile_horde_apollo_projectile", "arccw_horde_apollo")
end
SWEP.Base = "arccw_base"
SWEP.Spawnable = true
SWEP.Category = "ArcCW - Horde"
SWEP.AdminOnly = false

SWEP.PrintName = "Apollo"
SWEP.Trivia_Class = "Energy Rifle"
SWEP.Trivia_Desc = "Fires energy orb that incinerates targets on contact."
SWEP.Trivia_Manufacturer = "Combine"
SWEP.Trivia_Calibre = "Dark Energy"
SWEP.Trivia_Mechanism = "humper and Capsules"
SWEP.Trivia_Country = "Combine"
SWEP.Trivia_Year = 2007

SWEP.Slot = 2

SWEP.UseHands = true

SWEP.ViewModel = "models/horde/weapons/c_apollo.mdl"
SWEP.WorldModel = "models/horde/weapons/c_apollo.mdl"
SWEP.ViewModelFOV = 65

SWEP.Damage = 55
SWEP.DamageMin = 42
SWEP.Range = 50
SWEP.Penetration = 10
SWEP.DamageType = DMG_BULLET
SWEP.ShootEntity = "projectile_horde_apollo_projectile"
SWEP.MuzzleVelocity = 1500
SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 30

SWEP.PhysBulletMuzzleVelocity = 400

SWEP.Tracer = "AR2Tracer"
SWEP.TracerNum = 1
SWEP.TracerCol = Color(255, 25, 25)
SWEP.TracerWidth = 3

SWEP.Recoil = 0.2
SWEP.RecoilSide = 0.75
SWEP.RecoilRise = 1

SWEP.Delay = 60 / 600
SWEP.Num = 1
SWEP.Firemodes = {
    {
        Mode = 2,
    },
    {
        Mode = 1,
    },
    {
        Mode = 0,
    },
}

SWEP.NPCWeaponType = "weapon_ar2"
SWEP.NPCWeight = 100

SWEP.AccuracyMOA = 12
SWEP.HipDispersion = 200
SWEP.MoveDispersion = 75

SWEP.Primary.Ammo = "ar2"
SWEP.MagID = "type2"

SWEP.ShootVol = 115
SWEP.ShootPitch = 100

SWEP.ShootSound = "horde/weapons/ar2/fire1.ogg"
SWEP.ShootSoundSilenced = "weapons/arccw/m4a1/m4a1_silencer_01.wav"
SWEP.DistantShootSound = "weapons/arccw/ak47/ak47-1-distant.wav"

SWEP.MuzzleEffect = "muzzleflash_1"
SWEP.ShellModel = "models/weapons/arccw/irifleshell.mdl"

SWEP.MeleeSwingSound = "arccw_go/m249/m249_draw.wav"
SWEP.MeleeMissSound = "weapons/iceaxe/iceaxe_swing1.wav"
SWEP.MeleeHitSound = "arccw_go/knife/knife_hitwall1.wav"
SWEP.MeleeHitNPCSound = "physics/body/body_medium_break2.wav"

SWEP.MuzzleEffectAttachment = 1
SWEP.CaseEffectAttachment = 2

SWEP.SpeedMult = 1
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.275

SWEP.BulletBones = {
}

SWEP.ProceduralRegularFire = false
SWEP.ProceduralIronFire = false

SWEP.CaseBones = {}

SWEP.IronSightStruct = {
    Pos = Vector(-3.2, -1, 0.3),
    Ang = Angle(0, 0, -30),
    Magnification = 1.1,
    SwitchToSound = "",
    CrosshairInSights = true
}

SWEP.HoldtypeHolstered = "ar2"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "ar2"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, 0, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.CrouchPos = Vector(-4, 0, -1)
SWEP.CrouchAng = Angle(0, 0, -10)

SWEP.HolsterPos = Vector(3, 3, 0)
SWEP.HolsterAng = Angle(-7.036, 30.016, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.CustomizePos = Vector(8, 0, 1)
SWEP.CustomizeAng = Angle(5, 30, 30)

SWEP.BarrelLength = 0

SWEP.AttachmentElements = {
    ["rail"] = {
        VMBodygroups = {{ind = 5, bg = 1}},
        WMBodygroups = {{ind = 5, bg = 1}},
    },
}

SWEP.ExtraSightDist = 10
SWEP.GuaranteeLaser = true

SWEP.MirrorVMWM = true
SWEP.WorldModelOffset = {
    pos = Vector(-10, 4.2, -6),
    ang = Angle(-10, 0, 180)
}

SWEP.Attachments = {
    {
        PrintName = "Optic",
        Slot = "optic_lp",
        Bone = "pulserifle",
        DefaultAttName = "Iron Sights",
        Offset = {
            vpos = Vector(-0, -5, 4.25),
            vang = Angle(0, 90, 0),
        },
        VMScale = Vector(1.15, 1.15, 1.15),
        CorrectivePos = Vector(0, -10, 0),
        CorrectiveAng = Angle(0, 0, 0),
    },
    {
        PrintName = "Underbarrel",
        Slot = "foregrip",
        Bone = "pulserifle",
        Offset = {
            vpos = Vector(0, 10, -1.1),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Tactical",
        Slot = "tac",
        Bone = "pulserifle",
        Offset = {
            vpos = Vector(-0, 12, 1.2),
            vang = Angle(0, -90, 0),
        },
    },
    {
        PrintName = "Perk",
        Slot = "go_perk"
    },
    {
        PrintName = "Charm",
        Slot = "charm",
        FreeSlot = true,
        Bone = "pulserifle",
        Offset = {
            vpos = Vector(0.5, -1, 4),
            vang = Angle(0, -90, 0),
        },
    },
}

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
    },
    ["draw"] = {
        Source = "draw",
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 0.5,
    },
    ["fire"] = {
        Source = {"fire1","fire2"},
        Time = 0.5,
    },
    ["fire_iron"] = {
        Source = "fire3",
        Time = 0.5,
    },
    ["enter_sights"] = {
        Source = "idle",
        Time = 0,
    },
    ["idle_sights"] = {
        Source = "idle",
        Time = 0,
    },
    ["exit_sights"] = {
        Source = "idle",
        Time = 0,
    },
    ["enter_inspect"] = {
        Source = "inspect",
    },
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
    },
}
