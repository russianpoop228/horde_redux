if HORDE and HORDE.RegisterStatus then
    if not HORDE:GetStatusID("Flash") then
        HORDE:RegisterStatus({
            Name         = "Flash",
            Icon         = "materials/spells/floating_chaos.png",
            IsDebuff     = true,
            Stackable    = false,
            Notification = "You're temporarily blinded!",
        })
        if HORDE.STATUS_COLOR then
            HORDE.STATUS_COLOR[HORDE.Status_Flash] = Color(255, 255, 200)
        end
    end
end
