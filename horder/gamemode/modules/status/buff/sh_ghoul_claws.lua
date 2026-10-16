if not (HORDE and HORDE.RegisterStatus) then return end

HORDE.GhoulClaws = HORDE.GhoulClaws or {}

HORDE.GhoulClaws.Keys = {
    camouflage = { key = KEY_B    },
    appetite   = { key = KEY_LALT },
}

HORDE.GhoulClaws.Icons = {
    Ghoul_Camouflage = "materials/status/camoflague.png",
    Ghoul_BoneBurst  = "materials/status/bleeding.png",
    Ghoul_Appetite   = "materials/perks/berserk.png",
}

local DrawAbility

if CLIENT then
    local COL_BG = Color(40, 40, 40, 200)

    local ABILITIES = {
        camouflage = { cd = "GetCamouflageCDEnd" },
        bone       = { cd = "GetBoneBurstCDEnd" },
        appetite   = { cd = "GetAppetiteCDEnd" },
    }

    local mats = {}
    local function GetMat(path)
        if not mats[path] then mats[path] = Material(path, "mips smooth") end
        return mats[path]
    end

    local function GetClaws()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local wep = ply:GetWeapon("horde_ghoul_claws")
        if IsValid(wep) then return wep end
    end

    local function Call(wep, getter)
        local fn = IsValid(wep) and getter and wep[getter]
        return fn and fn(wep) or nil
    end

    DrawAbility = function(kind, status, displacement)
        local def = ABILITIES[kind]
        local wep = GetClaws()
        local s   = ScreenScale(15)
        local x   = ScreenScale(displacement)

        local cd = math.max(0, math.ceil((Call(wep, def.cd) or 0) - CurTime()))

        draw.RoundedBox(10, x, 0, s, s, COL_BG)

        surface.SetMaterial(GetMat(HORDE.Status_Icon[status]))
        surface.SetDrawColor(color_white)
        surface.DrawTexturedRect(x + ScreenScale(1), ScreenScale(5/4), ScreenScale(13), ScreenScale(13))

        if cd > 0 then
            draw.RoundedBox(10, x, 0, s, s, COL_BG)
            draw.SimpleText(cd, "Horde_Cd", x + ScreenScale(7.5), ScreenScale(7), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end

local function Register(name, kind)
    if HORDE:GetStatusID(name) then return end
    HORDE:RegisterStatus({
        Name            = name,
        Icon            = HORDE.GhoulClaws.Icons[name],
        IsSkill         = true,
        UsePerkCooldown = false,
        Draw = CLIENT and function(status, stack, displacement)
            DrawAbility(kind, status, displacement)
            return true
        end or nil,
    })
end

Register("Ghoul_Camouflage", "camouflage")
Register("Ghoul_BoneBurst",  "bone")
Register("Ghoul_Appetite",   "appetite")
