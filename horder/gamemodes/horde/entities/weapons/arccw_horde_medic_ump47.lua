if not ArcCWInstalled then return end
if CLIENT then
    SWEP.WepSelectIcon = surface.GetTextureID("arccw/weaponicons/arccw_go_ump")
    killicon.Add("arccw_horde_medic_ump47", "arccw/weaponicons/arccw_go_ump", Color(0, 0, 0, 255))
end

SWEP.Base = "arccw_base"
SWEP.Spawnable = true
SWEP.Category = "ArcCW - Horde"
SWEP.AdminOnly = false

SWEP.PrintName = "UMP47 Medic"
SWEP.Trivia_Class = "Submachine Gun"
SWEP.Trivia_Desc = ".45 calibre submachine gun created to replace the MP5. Has a more controllable fire rate, and 2-round burst features."
SWEP.Trivia_Manufacturer = "Heckler und Koch"
SWEP.Trivia_Calibre = ".45 ACP"
SWEP.Trivia_Mechanism = "Roller-Delayed Blowback"
SWEP.Trivia_Country = "Germany"
SWEP.Trivia_Year = 1999

SWEP.Slot = 2

SWEP.UseHands = true

SWEP.ViewModel = "models/weapons/arccw_go/v_smg_ump45.mdl"
SWEP.WorldModel = "models/weapons/arccw_go/v_smg_ump45.mdl"
SWEP.ViewModelFOV = 60

SWEP.DefaultBodygroups = "000000000000"

SWEP.Damage = 35
SWEP.DamageMin = 24
SWEP.Range = 75
SWEP.Penetration = 6
SWEP.DamageType = DMG_BULLET
SWEP.ShootEntity = nil
SWEP.MuzzleVelocity = 250
SWEP.ChamberSize = 1
SWEP.Primary.ClipSize = 25

SWEP.PhysBulletMuzzleVelocity = 300

SWEP.Recoil = 0.200
SWEP.RecoilSide = 0.100
SWEP.RecoilRise = 0.1
SWEP.RecoilPunch = 2.5

SWEP.Delay = 60 / 650
SWEP.Num = 1
SWEP.Firemodes = {
    {
        Mode = 2,
    },
    {
        Mode = -2
    },
    {
        Mode = 1,
    },
    {
        Mode = 0
    }
}

SWEP.Hook_TranslateAnimation = function(wep, anim)
    if anim != "ready" then return end

    local dice = util.SharedRandom("ReadyOrNot", 0, 1, CurTime())

    if dice > 0.5 then
        return "ready_55"
    else
        return "ready_56"
    end
end

SWEP.NPCWeaponType = "weapon_smg1"
SWEP.NPCWeight = 100

SWEP.AccuracyMOA = 7
SWEP.HipDispersion = 325
SWEP.MoveDispersion = 75

SWEP.Primary.Ammo = "pistol"
SWEP.MagID = "ump"

SWEP.ShootVol = 110
SWEP.ShootPitch = 100

SWEP.FirstShootSound = "arccw_go/ump45/ump45_02.wav"
SWEP.ShootSound = "arccw_go/ump45/ump45_04.wav"
SWEP.ShootSoundSilenced = "arccw_go/mp5/mp5_01.wav"
SWEP.DistantShootSound = "arccw_go/ump45/ump45-1-distant.wav"

SWEP.MeleeSwingSound = "arccw_go/m249/m249_draw.wav"
SWEP.MeleeMissSound = "weapons/iceaxe/iceaxe_swing1.wav"
SWEP.MeleeHitSound = "arccw_go/knife/knife_hitwall1.wav"
SWEP.MeleeHitNPCSound = "physics/body/body_medium_break2.wav"

SWEP.MuzzleEffect = "muzzleflash_smg"
SWEP.ShellModel = "models/shells/shell_9mm.mdl"
SWEP.ShellPitch = 100
SWEP.ShellScale = 1.25
SWEP.ShellRotateAngle = Angle(0, 180, 0)

SWEP.MuzzleEffectAttachment = 1
SWEP.CaseEffectAttachment = 2

SWEP.SpeedMult = 0.95
SWEP.SightedSpeedMult = 0.75
SWEP.SightTime = 0.300

SWEP.IronSightStruct = {
    Pos = Vector(-5.1, -7, 1.5),
    Ang = Angle(0, 0.05, 0),
    Magnification = 1.1,
    SwitchToSound = "",
    CrosshairInSights = false
}

SWEP.HoldtypeHolstered = "passive"
SWEP.HoldtypeActive = "ar2"
SWEP.HoldtypeSights = "rpg"

SWEP.AnimShoot = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

SWEP.ActivePos = Vector(-1, 2, -1)
SWEP.ActiveAng = Angle(0, 0, 0)

SWEP.CrouchPos = Vector(-4, 0, -1)
SWEP.CrouchAng = Angle(0, 0, -10)

SWEP.HolsterPos = Vector(3, 3, 0)
SWEP.HolsterAng = Angle(-7.036, 30.016, 0)

SWEP.BarrelOffsetSighted = Vector(0, 0, -1)
SWEP.BarrelOffsetHip = Vector(2, 0, -2)

SWEP.CustomizePos = Vector(8, 0, 1)
SWEP.CustomizeAng = Angle(5, 30, 30)

SWEP.BarrelLength = 24

SWEP.AttachmentElements = {
    ["go_stock_none"] = {
        VMBodygroups = {{ind = 3, bg = 1}},
    },
    ["go_ump_stock_in"] = {
        VMBodygroups = {{ind = 3, bg = 2}},
    },
    ["go_ump_mag_12"] = {
        VMBodygroups = {{ind = 2, bg = 1}},
    },
    ["go_ump_mag_30_9mm"] = {
        NameChange = "UMP-9",
        VMBodygroups = {{ind = 2, bg = 2}},
    },
    ["go_ump_barrel_med"] = {
        VMBodygroups = {{ind = 1, bg = 1}},
        AttPosMods = {
            [5] = {
                vpos = Vector(0, -3.95, 17.5),
            }
        }
    },
    ["go_ump_barrel_long"] = {
        VMBodygroups = {{ind = 1, bg = 2}},
        AttPosMods = {
            [5] = {
                vpos = Vector(0, -3.95, 20),
            }
        }
    },
    ["go_stock"] = {
        VMBodygroups = {
            {ind = 3, bg = 1},
        },
        VMElements = {
            {
                Model = "models/weapons/arccw_go/atts/stock_buftube.mdl",
                Bone = "v_weapon.ump45_Parent",
                Offset = {
                    pos = Vector(0, -4.5, -1.75),
                    ang = Angle(90, 0, -90),
                },
            }
        },
    },
}

SWEP.ExtraSightDist = 10
SWEP.GuaranteeLaser = true

SWEP.WorldModelOffset = {
    pos = Vector(-17, 6, -5),
    ang = Angle(-10, 0, 180)
}

SWEP.MirrorVMWM = true

SWEP.Attachments = {
    {
        PrintName = "Optic",
        Slot = {"optic_lp", "optic"},
        Bone = "v_weapon.ump45_parent",
        DefaultAttName = "Iron Sights",
        Offset = {
            vpos = Vector(0, -6.2, 4),
            vang = Angle(90, 0, -90),
        },
        InstalledEles = {"rail"},
        VMScale = Vector(1.25, 1.25, 1.25),
        CorrectiveAng = Angle(0.5, 0, 0),
        CorrectivePos = Vector(0, 0, 0)
    },
    {
        PrintName = "Underbarrel",
        Slot = "foregrip",
        Bone = "v_weapon.ump45_parent",
        DefaultAttName = "Standard Foregrip",
        Offset = {
            vpos = Vector(0, -3, 12),
            vang = Angle(90, 0, -90),
        },
        InstalledEles = {"ubrms"},
    },
    {
        PrintName = "Tactical",
        Slot = "tac",
        Bone = "v_weapon.ump45_parent",
        Offset = {
            vpos = Vector(0.75, -4, 11),
            vang = Angle(90, 0, 0),
        },
        InstalledEles = {"tacms"},
    },
    {
        PrintName = "Barrel",
        Slot = "go_ump_barrel",
        DefaultAttName = "200mm HK Barrel"
    },
    {
        PrintName = "Muzzle",
        DefaultAttName = "Standard Muzzle",
        Slot = "muzzle",
        Bone = "v_weapon.ump45_parent",
        Offset = {
            vpos = Vector(0, -3.95, 15),
            vang = Angle(90, 0, -90),
        },
    },
    {
        PrintName = "Magazine",
        Slot = "go_ump_mag",
        DefaultAttName = "25-Round .45 UMP"
    },
    {
        PrintName = "Stock",
        Slot = {"go_ump_stock", "go_stock_none", "go_stock"},
        DefaultAttName = "Standard Stock",
        Bone = "v_weapon.ump45_parent",
        Offset = {
            vpos = Vector(0, -4.5, -1.75),
            vang = Angle(90, 0, -90),
        },
    },
    {
        PrintName = "Ammo Type",
        Slot = "go_ammo",
        DefaultAttName = "Standard Ammo"
    },
    {
        PrintName = "Perk",
        Slot = "go_perk"
    },
    {
        PrintName = "Charm",
        Slot = "charm",
        FreeSlot = true,
        Bone = "v_weapon.ump45_parent",
        Offset = {
            vpos = Vector(0.9, -4, 3),
            vang = Angle(90, 0, -90),
        },
    },
}

function SWEP:Hook_TranslateAnimation(anim)
    if anim == "fire_iron" then
        if self:GetBuff_Override("NoStock") then return "fire" end
    elseif anim == "fire_iron_empty" then
        if self:GetBuff_Override("NoStock") then return "fire_empty" end
    end
end

SWEP.Animations = {
    ["idle"] = {
        Source = "idle"
    },
    ["draw"] = {
        Source = "draw",
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 0.5,
    },
    ["ready"] = {
        Source = "ready",
        LHIK = true,
        LHIKIn = 0,
        LHIKOut = 0.5,
    },
    ["fire"] = {
        Source = "shoot",
        Time = 0.25,
        ShellEjectAt = 0,
    },
    ["fire_iron"] = {
        Source = "idle",
        Time = 0.5,
        ShellEjectAt = 0,
    },
    ["reload"] = {
        Source = "reload",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {16, 30},
        FrameRate = 30,
        LHIK = true,
        LHIKIn = 0.4,
        LHIKOut = 0.4,
        LHIKEaseOut = 0.3
    },
    ["reload_empty"] = {
        Source = "reload_empty",
        TPAnim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        Checkpoints = {16, 30, 55},
        FrameRate = 30,
        LHIK = true,
        LHIKIn = 0.4,
        LHIKOut = 0.4,
        LHIKEaseOut = 0.3
    },
}

sound.Add({
    name = "ARCCW_GO_UMP.Draw",
    channel = 16,
    volume = 1.0,
    sound = "arccw_go/ump45/ump45_draw.wav"
})

sound.Add({
    name = "ARCCW_GO_UMP.BoltBack",
    channel = 16,
    volume = 1.0,
    sound = "arccw_go/ump45/ump45_boltback.wav"
})

sound.Add({
    name = "ARCCW_GO_UMP.BoltForward",
    channel = 16,
    volume = 1.0,
    sound = "arccw_go/ump45/ump45_boltforward.wav"
})

sound.Add({
    name = "ARCCW_GO_UMP.Clipout",
    channel = 16,
    volume = 1.0,
    sound = "arccw_go/ump45/ump45_clipout.wav"
})

sound.Add({
    name = "ARCCW_GO_UMP.Clipin",
    channel = 16,
    volume = 1.0,
    sound = "arccw_go/ump45/ump45_clipin.wav"
})

sound.Add({
    name = "ARCCW_GO_UMP.Cliphit",
    channel = 16,
    volume = 1.0,
    sound = "arccw_go/ump45/ump45_cliphit.wav"
})

function SWEP:ChangeFiremode(pred)
    if self:GetNextSecondaryFire() > CurTime() then return end
    if not self.CanBash and not self:GetBuff_Override("Override_CanBash") then return end
    if CLIENT then return end

    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    local tr = util.TraceHull({
        start = ply:GetShootPos(),
        endpos = ply:GetShootPos() + ply:GetAimVector() * 5000,
        filter = {ply},
        mins = Vector(-16, -16, -8),
        maxs = Vector(16, 16, 8),
        mask = MASK_SHOT_HULL
    })

    if tr.Hit then
        local effectdata = EffectData()
        effectdata:SetOrigin(tr.HitPos)
        effectdata:SetRadius(50)
        util.Effect("horde_heal_mist", effectdata)

        for _, ent in pairs(ents.FindInSphere(tr.HitPos, 100)) do
            if ent:IsPlayer() then
                local healinfo = HealInfo:New({amount = 20, healer = ply})
                HORDE:OnPlayerHeal(ent, healinfo)
            elseif ent:GetClass() == "npc_vj_horde_antlion" then
                local healinfo = HealInfo:New({amount = 20, healer = ply})
                HORDE:OnAntlionHeal(ent, healinfo)
            end
        end
    end

    ply:EmitSound("horde/weapons/mp7m/heal.ogg", 125, 100, 1, CHAN_AUTO)

    self:SetNextSecondaryFire(CurTime() + 5)
    self:SetNextPrimaryFire(CurTime() + 0.25)
    return true
end

function SWEP:Hook_Think()
    if SERVER then return end

    local ply = self:GetOwner()
    if not IsValid(ply) then
        self.Horde_HealTarget = nil
        return
    end

    local tr = util.TraceHull({
        start = ply:GetShootPos(),
        endpos = ply:GetShootPos() + ply:GetAimVector() * 5000,
        filter = {ply},
        mins = Vector(-20, -20, -8),
        maxs = Vector(20, 20, 8),
        mask = MASK_SHOT_HULL
    })

    if tr.Hit and IsValid(tr.Entity) and tr.Entity:IsPlayer() then
        self.Horde_HealTarget = tr.Entity
    else
        self.Horde_HealTarget = nil
    end
end

local function nv_center(ent)
    return ent:LocalToWorld(ent:OBBCenter())
end

function SWEP:Hook_DrawHUD()
    if not IsValid(self.Horde_HealTarget) then return end

    local pos = nv_center(self.Horde_HealTarget):ToScreen()
    surface.SetDrawColor(Color(50, 200, 50))
    surface.DrawCircle(pos.x, pos.y, 30)
    draw.DrawText(
        self.Horde_HealTarget:Health(),
        "Trebuchet24",
        pos.x - 15,
        pos.y - 15,
        Color(50, 200, 50),
        TEXT_ALIGN_LEFT
    )
end
