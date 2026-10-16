if not ArcCWInstalled then return end
SWEP.Base = "arccw_horde_gl_base"
SWEP.Spawnable = true
SWEP.Category = "ArcCW - Horde"
SWEP.AdminOnly = false

SWEP.PrintName = "M79"
SWEP.Trivia_Class = "Grenade Launcher"
SWEP.Trivia_Desc = "A break-action type grenade launcher."
SWEP.Trivia_Manufacturer = "Springfield Armory"
SWEP.Trivia_Calibre = "40mm"
SWEP.Trivia_Mechanism = "Break-Action"
SWEP.Trivia_Country = "USA"
SWEP.Trivia_Year = 1961

SWEP.Slot = 3

SWEP.Spawnable = true

SWEP.UseHands = true

SWEP.ViewModel = "models/horde/weapons/v_m79.mdl"
SWEP.WorldModel = "models/horde/weapons/v_m79.mdl"
SWEP.MirrorVMWM = true
SWEP.WorldModelOffset = {
    pos        =    Vector(0, 5, -7),
    ang        =    Angle(-10, 2.5, 180),
    bone    =    "ValveBiped.Bip01_R_Hand",
}
SWEP.ViewModelFOV = 50

SWEP.Damage = 26
SWEP.DamageMin = 20
SWEP.Range = 50
SWEP.Penetration = 20
SWEP.DamageType = DMG_BULLET
SWEP.ShootEntity = "horde_projectile_he_round"
SWEP.MuzzleVelocity = 100000

SWEP.CanFireUnderwater = false

SWEP.TracerNum = 1
SWEP.TracerCol = Color(255, 25, 25)
SWEP.TracerWidth = 3

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 1
SWEP.ExtendedClipSize = 1
SWEP.ReducedClipSize = 1

SWEP.Recoil = 1
SWEP.RecoilSide = 1
SWEP.VisualRecoilMult = 1
SWEP.RecoilRise = 2

SWEP.Delay = 60 / 600
SWEP.Num = 1
SWEP.Firemodes = {
    {
        Mode = 2,
    },
    {
        Mode = 0
    }
}

SWEP.NPCWeaponType = "weapon_pistol"
SWEP.NPCWeight = 75

SWEP.AccuracyMOA = 10
SWEP.HipDispersion = 150
SWEP.MoveDispersion = 250

SWEP.Primary.Ammo = "SMG1_Grenade"

SWEP.ShootVol = 100
SWEP.ShootPitch = 100

SWEP.ShootSound = "GrenadeLauncher.Fire"
SWEP.ShootSoundSilenced = nil
SWEP.DistantShootSound = nil

SWEP.MuzzleEffect = "muzzleflash_pistol"
SWEP.ShellModel = "models/shells/shell_9mm.mdl"
SWEP.ShellScale = 1

SWEP.MuzzleEffectAttachment = 1
SWEP.CaseEffectAttachment = 2

SWEP.SightTime = 0.175

SWEP.SpeedMult = 0.95
SWEP.SightedSpeedMult = 0.6

SWEP.BarrelLength = 18

SWEP.ProceduralRegularFire = false
SWEP.ProceduralIronFire = false

SWEP.CaseBones = {}

SWEP.IronSightStruct = {
    Pos = Vector(-3.5, 0, 0.5),
    Ang = Angle(-0, 0, 0),
    Magnification = 1.3,
}

SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "shotgun"
SWEP.HoldtypeSights = "ar2"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL

SWEP.ActivePos = Vector(0, 0, 0)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.HolsterPos = Vector(-2, -7.145, -11.561)
SWEP.HolsterAng = Angle(36.533, 0, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.CustomizePos = Vector(12, -8, -4.897)
SWEP.CustomizeAng = Angle(12.149, 30.547, 0)

SWEP.SprintPos = Vector(5, 0, 0)
SWEP.SprintAng = Angle(0, 25, 0)

SWEP.AttachmentElements = {

}

SWEP.ExtraSightDist = 5

SWEP.RejectAttachments = {["go_homemade_auto"] = true, ["go_perk_burst"] = true}
SWEP.Attachments = {
    {
        PrintName = "Charms",
        Slot = "charm",
        Bone = "Barrel",
        Offset = {
            vpos = Vector(6, -0.9, 1),
            vang = Angle(0, 0, 0),
            wpos = Vector(7, 2, -4.5),
            wang = Angle(-5, 1, 180)
        },
    },
    {
        PrintName = "Ammo",
        Slot = "horde_ammo"
    },
    {
        PrintName = "Perk",
        Slot = "go_perk"
    },
}

SWEP.Animations = {
    ["idle"] = {
    Source = "idle",
    Time = 10,
    },
    ["draw"] = {
        Source = "draw",
        Time = 0.5,
        SoundTable = {
            {
            s = "weapons/arccw/draw_secondary.wav",
            t = 0
            }
        },
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 0.25,
    },
    ["fire"] = {
        Source = "shoot",
        Time = 0.5,
        ShellEjectAt = 0,
        RestoreAmmo = 1,
    },
    ["fire_iron"] = {
        Source = "shoot",
        Time = 0.5,
        ShellEjectAt = 0,
    },
    ["reload"] = {
        Source = "reload",
        Time = 2,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        FrameRate = 30,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.2,
    },
}
sound.Add(
{
name = "GrenadeLauncher.Fire",
channel = CHAN_WEAPON,
volume = 0.8,
soundlevel = SNDLVL_TALKING,
sound = "horde/weapons/gl/fire.mp3"
})
sound.Add(
{
name = "GrenadeLauncher.LatchOpen",
channel = CHAN_ITEM,
volume = 1.0,
soundlevel = SNDLVL_NORM,
sound = "horde/weapons/gl/grenade_launcher_latchopen.mp3"
})
sound.Add(
{
name = "GrenadeLauncher.ShellOut",
channel = CHAN_ITEM,
volume = 1.0,
soundlevel = SNDLVL_NORM,
sound = "horde/weapons/gl/grenade_launcher_shellout.mp3"
})
sound.Add(
{
name = "GrenadeLauncher.ShellIn",
channel = CHAN_ITEM,
volume = 1.0,
soundlevel = SNDLVL_NORM,
sound = "horde/weapons/gl/grenade_launcher_shellin.mp3"
})
sound.Add(
{
name = "GrenadeLauncher.ActionClosed",
channel = CHAN_ITEM,
volume = 1.0,
soundlevel = SNDLVL_NORM,
sound = "horde/weapons/gl/grenade_launcher_actionclosed.mp3"
})
