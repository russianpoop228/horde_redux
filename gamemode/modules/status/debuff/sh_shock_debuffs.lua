if HORDE and HORDE.RegisterStatus then
    if not HORDE:GetStatusID("Deafenation") then
        HORDE:RegisterStatus({
            Name         = "Deafenation",
            Icon         = "materials/status/deafenation.png",
            IsDebuff     = true,
            Notification = "Bad news. You're temporarily blinded and halfly deaf!",
        })
        if HORDE.STATUS_COLOR then
            HORDE.STATUS_COLOR[HORDE.Status_Deafenation] = Color(125, 125, 125)
        end
    end

    if not HORDE:GetStatusID("Numbness") then
        HORDE:RegisterStatus({
            Name         = "Numbness",
            Icon         = "materials/status/intense_shock.png",
            IsDebuff     = true,
            BuildupSound = "weapons/physcannon/energy_disintegrate5.wav",
            Notification = "You are inflicted by Intense Shock. You're weakened.",
        })
        if HORDE.STATUS_COLOR then
            HORDE.STATUS_COLOR[HORDE.Status_Numbness] = Color(255, 200, 20)
        end
    end

    if not HORDE:GetStatusID("Insensitivity") then
        HORDE:RegisterStatus({
            Name         = "Insensitivity",
            Icon         = "materials/status/dark_shock.png",
            IsDebuff     = true,
            BuildupSound = "weapons/mortar/mortar_explode3.wav",
            Notification = "You are inflicted by Dark Shock. You're significantly weakened.",
        })
        if HORDE.STATUS_COLOR then
            HORDE.STATUS_COLOR[HORDE.Status_Insensitivity] = Color(160, 48, 220)
        end
    end
end
