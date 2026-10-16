if not HORDE:GetStatusID("Overcharge") then
    HORDE:RegisterStatus({
        Name      = "Overcharge",
        Icon      = "materials/status/damage.png",
        Stackable = true,
    })
end
