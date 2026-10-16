if not HORDE:GetStatusID("Corrosion") then
    HORDE:RegisterStatus({
        Name         = "Corrosion",
        Icon         = "materials/status/decay.png",
        IsDebuff     = true,
        BuildupSound = "horde/status/bleeding_buildup.ogg",
        TriggerSound = "horde/status/bleeding_trigger.ogg",
        Notification = "You are corroding.\nHealth drains over time.",
    })
end
