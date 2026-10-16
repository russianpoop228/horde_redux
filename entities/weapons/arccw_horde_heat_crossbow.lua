if not ArcCWInstalled then return end
if CLIENT then
    SWEP.WepSelectIcon = Material("items/hl2/weapon_crossbow.png")
    killicon.AddAlias("arccw_horde_heat_crossbow", "crossbow_bolt")
    killicon.AddAlias("projectile_horde_heat_bolt", "crossbow_bolt")
end
SWEP.Base = "arccw_base"
SWEP.Spawnable = true
SWEP.Category = "ArcCW - Horde"
SWEP.AdminOnly = false

SWEP.PrintName = "Heat Crossbow"
SWEP.Trivia_Class = "Crossbow"
SWEP.Trivia_Desc = "Improvised sniper weapon. Can switch between ballistic mode and heat mode."
SWEP.Trivia_Manufacturer = "Resistance"
SWEP.Trivia_Calibre = "Rebar"
SWEP.Trivia_Mechanism = "String"
SWEP.Trivia_Country = "Earth"
SWEP.Trivia_Year = 2007

SWEP.Slot = 3

SWEP.Spawnable = true

SWEP.UseHands = true

SWEP.ViewModel = "models/weapons/c_crossbow.mdl"
SWEP.WorldModel = "models/weapons/w_crossbow.mdl"
SWEP.MirrorVMWM = false
SWEP.ViewModelFOV = 65

SWEP.Damage = 300
SWEP.DamageMin = 300
SWEP.Range = 50
SWEP.Penetration = 20
SWEP.DamageType = DMG_BULLET
SWEP.ShootEntity = "projectile_horde_heat_bolt"
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
        PrintName = "Ballistic Mode"
    },
    {
        Mode = 3,
        PrintName = "Impact Mode"
    },
}

SWEP.NPCWeaponType = "weapon_crossbow"
SWEP.NPCWeight = 75

SWEP.AccuracyMOA = 10
SWEP.HipDispersion = 150
SWEP.MoveDispersion = 250

SWEP.Primary.Ammo = "XBowBolt"

SWEP.ShootVol = 100
SWEP.ShootPitch = 100

SWEP.ShootSound = "weapons/crossbow/fire1.wav"
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
    Magnification = 4,
    CrosshairInSights = true,
}

SWEP.HoldtypeHolstered = "normal"
SWEP.HoldtypeActive = "crossbow"
SWEP.HoldtypeSights = "crossbow"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW

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

SWEP.ExtraSightDist = 5

SWEP.RejectAttachments = {["go_homemade_auto"] = true, ["go_perk_burst"] = true}

SWEP.Attachments = {
    {
        PrintName = "Perk",
        Slot = "go_perk"
    },
}

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
        Time = 10,
        TPAnim = ACT_HL2MP_IDLE_CROSSBOW,
    },
    ["idle_empty"] = {
        Source = "idle_empty",
        Time = 10,
        TPAnim = ACT_CROSSBOW_DRAW_UNLOADED,
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
    ["fire_empty"] = {
        Source = "fire",
        Time = 0.5,
        TPAnim = ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW,
    },
    ["fire_iron"] = {
        Source = "fire",
        Time = 0.5,
        TPAnim = ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW,
    },
    ["reload"] = {
        Source = "reload",
        Time = 2,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_CROSSBOW,
        FrameRate = 30,
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.2,
        SoundTable = {
            {s = {"weapons/crossbow/bolt_load1.wav", "weapons/crossbow/bolt_load2.wav"}, t = 0},
        }
    },
}

function SWEP:DrawWeaponSelection(x, y, w, h, a)
    surface.SetDrawColor(255, 255, 255, a)
    surface.SetMaterial(self.WepSelectIcon)

    surface.DrawTexturedRect(x, y, w, w / 2)
end
