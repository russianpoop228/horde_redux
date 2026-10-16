PERK.PrintName = "Resonance Cascade"
PERK.Description = "Aura effect increased by {1}.\nAura radius increased by {2}."
PERK.Icon = "materials/perks/resonance_cascade.png"
PERK.Params = {
    [1] = {value = 0.5, percent = true},
    [2] = {value = 0.5, percent = true},
}

PERK.Hooks = {}

PERK.WardenAuraRadiusMult = 1.5
PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if SERVER and perk == "warden_resonance_cascade" then
        ply:Horde_AddWardenAura()
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "warden_resonance_cascade" then
        if ply:Horde_GetPerk("warden_base") then
            ply:Horde_AddWardenAura()
        else
            ply:Horde_RemoveWardenAura()
        end
    end
end
