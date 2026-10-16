SWEP.Base = "arccw_base"
SWEP.Spawnable = true
SWEP.Category = "ArcCW - MW Classic"
SWEP.AdminOnly = false

SWEP.PrintName = "M60E3"
SWEP.Trivia_Class = "Light Machine Gun"
SWEP.Trivia_Desc = "The U.S. Military's standard general purpose machine gun adopted in 1957. Nicknamed the Pig due to it's huge size and appetite for ammo."
SWEP.Trivia_Manufacturer = "U.S. Ordnance"
SWEP.Trivia_Calibre = "7.62x51mm NATO"
SWEP.Trivia_Mechanism = "Short-stroke gas piston"
SWEP.Trivia_Country = "USA"
SWEP.Trivia_Year = 1957

SWEP.Slot = 3

SWEP.ViewModel = "models/weapons/arccw/c_cod4_m60.mdl"
SWEP.WorldModel = "models/weapons/arccw/c_cod4_m60.mdl"
SWEP.MirrorVMWM = true
SWEP.WorldModelOffset = {
    pos        =    Vector(-5.6, 4, -7.5),
    ang        =    Angle(-5, 0, 180),
    bone    =    "ValveBiped.Bip01_R_Hand",
    scale   =   1.2
}
SWEP.ViewModelFOV = 60

SWEP.Damage = 75
SWEP.DamageMin = 38
SWEP.Range = 300
SWEP.RangeMin = 30

SWEP.Penetration = 10
SWEP.DamageType = DMG_BULLET
SWEP.ShootEntity = nil
SWEP.MuzzleVelocity = 800

SWEP.TracerNum = 1
SWEP.TracerCol = Color(255, 25, 25)
SWEP.TracerWidth = 4

SWEP.ChamberSize = 0
SWEP.Primary.ClipSize = 100
SWEP.ExtendedClipSize = 250
SWEP.ReducedClipSize = 75

SWEP.Recoil = 0.8
SWEP.RecoilSide = 0.7
SWEP.RecoilRise = 0.75
SWEP.VisualRecoilMult = 0.5

SWEP.Delay = 60 / 550
SWEP.Num = 1
SWEP.Firemodes = {
    {
        Mode = 2,
    },
    {
        Mode = 1,
    },
    {
        Mode = 0
    }
}

SWEP.NPCWeaponType = "weapon_ar2"
SWEP.NPCWeight = 100

SWEP.AccuracyMOA = 6
SWEP.HipDispersion = 700
SWEP.MoveDispersion = 200
SWEP.SightsDispersion = 80

SWEP.Primary.Ammo = "ar2"
SWEP.MagID = "m60"

SWEP.ShootVol = 115
SWEP.ShootPitch = 100

SWEP.ShootSound = "ArcCW_COD4E.M60_Fire"
SWEP.ShootSoundSilenced = "ArcCW_COD4E.M4M16_Sil"

SWEP.MuzzleEffect = "muzzleflash_4"
SWEP.ShellModel = "models/shells/shell_556.mdl"
SWEP.ShellPitch = 90
SWEP.ShellScale = 1.5

SWEP.MuzzleEffectAttachment = 1
SWEP.CaseEffectAttachment = 2
SWEP.ProceduralViewBobAttachment = 1
SWEP.CamAttachment = 3

SWEP.SpeedMult = 0.8
SWEP.SightedSpeedMult = 0.25
SWEP.SightTime = 0.75
SWEP.ShootSpeedMult = 0.75

SWEP.BulletBones = {
     [0] = "j_bullets0",
     [1] = "j_bullets1",
     [2] = "j_bullets2",
     [3] = "j_bullets3",
     [4] = "j_bullets4",
     [5] = "j_bullets5",
     [6] = "j_bullets6",
     [7] = "j_bullets7",
     [8] = "j_bullets8",
     [9] = "j_bullets9",
     [10] = "j_bullets10",
     [11] = "j_bullets11",
     [12] = "j_bullets12",
     [13] = "j_bullets13",
}

SWEP.ProceduralRegularFire = false
SWEP.ProceduralIronFire = false

SWEP.CaseBones = {}

SWEP.IronSightStruct = {
    Pos = Vector(-3.245, 0, 0.625),
    Ang = Angle(0.25, 0.025, 0),
    Magnification = 1.1,
    CrosshairInSights = false,
    SwitchToSound = "",
}

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(0, 1, 0.5)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.InBipodPos = Vector(-5, 0, -1.5)
SWEP.InBipodAng = Angle(0, 0, 0)

SWEP.SprintPos = Vector(0, 1, 0.5)
SWEP.SprintAng = Angle(0, 0, 0)

SWEP.CustomizePos = Vector(15, 0, 0)
SWEP.CustomizeAng = Angle(15, 40, 25)

SWEP.HolsterPos = Vector(3, 0, 0)
SWEP.HolsterAng = Angle(-7.036, 30.016, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.BarrelLength = 30

SWEP.ExtraSightDist = 5

SWEP.Bipod_Integral = true
SWEP.BipodDispersion = 0.1
SWEP.BipodRecoil = 0.05

SWEP.M_Hook_Mult_SightsDispersion = function(wep, data)
    if wep:InBipod() then
        data.mult = 0
    end
end

SWEP.DefaultBodygroups = "000000000"

SWEP.AttachmentElements = {
    ["mwc_bipod"] = {
        VMBodygroups = {
            {ind = 2, bg = 1},
        },
    },
    ["rail"] = {
        VMBodygroups = {
            {ind = 1, bg = 1}
        },
    },
    ["papname1"] = {
        NamePriority = 10,
        NameChange = "Slow Burn",
    },
}

SWEP.Attachments = {
    {
        PrintName = "Optic",
        DefaultAttName = "Iron Sights",
        Slot = {"optic"},
        VMScale = Vector(1, 1, 1),
        Bone = "j_reload_cover",
        Offset = {
            vpos = Vector(-2.125, 0, 0.45),
            vang = Angle(0, 0, 0),
        },
        InstalledEles = {"rail"},
        CorrectivePos = Vector(0, 0, 0),
        CorrectiveAng = Angle(-0.1, 0, 0),
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "Standard Muzzle",
        Slot = "muzzle",
        Bone = "tag_weapon",
        Offset = {
            vpos = Vector(24, 0, 2.35),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Underbarrel",
        Slot = {"foregrip"},
        Bone = "tag_weapon",
        Offset = {
            vpos = Vector(7.25, 0, 0),
            vang = Angle(0, 0, 0),
        },
        MergeSlots = {4},
    },
    {
        Hidden = true,
        Slot = {"bipod"},
        Bone = "tag_weapon",
        Offset = {
            vpos = Vector(15, 0, 0.5),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Tactical",
        Slot = {"bo1_tacprimary"},
        VMScale = Vector(1, 1, 1),
        Bone = "tag_weapon",
        Offset = {
            vpos = Vector(21, 0, 0.5),
            vang = Angle(0, 0, 0),
        },
    },
    {
        PrintName = "Fire Group",
        Slot = {"bo1_fcg"}
    },
    {
        PrintName = "Ammo Type",
        Slot = {"ammo_pap", "mw3_ammo"}
    },
    {
        PrintName = "Perk",
        Slot = {"mw3_perk"}
    },
    {
        PrintName = "Proficiency",
        Slot = "mw3_pro"
    },
    {
        PrintName = "Charm",
        Slot = "charm",
        FreeSlot = true,
        Bone = "j_reload_cover",
        Offset = {
            vpos = Vector(-5.25, -1, -0.5),
            vang = Angle(0, 0, 0),
        },
    },
}

SWEP.Hook_ModifyBodygroups = function(wep, data)
    local vm = data.vm
    local papcamo = wep:GetBuff_Override("PackAPunch")

    if papcamo then vm:SetSkin(3) end

    if wep:InBipod() then
        vm:SetBodygroup(2, 1)
    end
end

SWEP.Hook_TranslateAnimation = function(wep, anim)
    if wep.Attachments[1].Installed then
        return anim .. "_optic"
    end
end

SWEP.RejectAttachments = {
}

SWEP.Animations = {
    ["idle"] = {
        Source = "idle",
        Time = 1 / 30,
    },
    ["draw"] = {
        Source = "draw",
        Time = 41 / 30,
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.2,s
    },
    ["holster"] = {
        Source = "holster",
        Time = 41 / 30,
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.2,
    },
    ["ready"] = {
        Source = "draw",
        Time = 41 / 30,
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.2,
    },
    ["fire"] = {
        Source = {"fire"},
        Time = 7 / 30,
        ShellEjectAt = 0,
    },
    ["fire_iron"] = {
        Source = {"fire_ads"},
        Time = 7 / 30,
        ShellEjectAt = 0,
    },
    ["reload"] = {
        Source = "reload",
        Time = 281 / 35,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Framerate = 37,
        Checkpoints = {28, 38, 69},
        LHIK = true,
        LHIKIn = 0.2,
        LHIKOut = 0.2,
        LastClip1OutTime = 110 / 35,
        SoundTable = {
            {s = "ArcCW_COD4E.M60_Chamber", t = 17 / 35},
            {s = "ArcCW_COD4E.M60_Open", t = 57 / 35},
            {s = "ArcCW_COD4E.M60_Out", t = 95 / 35},
            {s = "ArcCW_COD4E.M60_In", t = 130 / 35},
            {s = "ArcCW_COD4E.M60_Raise", t = 160 / 35},
            {s = "ArcCW_COD4E.M60_Close", t = 200 / 35},
            {s = "ArcCW_COD4E.M60_LidClose", t = 205 / 35},
            {s = "ArcCW_COD4E.M60_Hit", t = 210 / 35},
        },
    },
    ["reload_optic"] = {
        Source = "reload_optic",
        Time = 281 / 35,
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Framerate = 37,
        Checkpoints = {28, 38, 69},
        LHIK = true,
        LHIKIn = 0.5,
        LHIKOut = 0.5,
        LastClip1OutTime = 110 / 35,
        SoundTable = {
            {s = "ArcCW_COD4E.M60_Chamber", t = 17 / 35},
            {s = "ArcCW_COD4E.M60_Open", t = 57 / 35},
            {s = "ArcCW_COD4E.M60_Out", t = 95 / 35},
            {s = "ArcCW_COD4E.M60_In", t = 130 / 35},
            {s = "ArcCW_COD4E.M60_Raise", t = 160 / 35},
            {s = "ArcCW_COD4E.M60_Close", t = 200 / 35},
            {s = "ArcCW_COD4E.M60_Hit", t = 210 / 35},
        },
    },
    ["enter_sprint"] = {
        Source = "sprint_in",
        Time = 10 / 30
    },
    ["idle_sprint"] = {
        Source = "sprint_loop",
        Time = 30 / 40
    },
    ["exit_sprint"] = {
        Source = "sprint_out",
        Time = 10 / 30
    },
}
