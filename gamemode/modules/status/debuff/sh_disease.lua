if HORDE and HORDE.RegisterStatus then
    if not HORDE:GetStatusID("Disease") then
        HORDE:RegisterStatus({
            Name         = "Disease",
            Icon         = "materials/status/disease.png",
            IsDebuff     = true,
            Stackable    = false,
            BuildupSound = "horde/status/bleeding_buildup.ogg",
            TriggerSound = "horde/status/shock_trigger.ogg",
            Notification = "You are inflicted by Disease. Hurry, heal with something!",
        })
    end
end
