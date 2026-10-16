GADGET.PrintName   = "Acid Pulse"
GADGET.Description = [[
Release an acidic pulse that applies {1} Corrosion buildup
to enemies within {2} units.]]
GADGET.Icon        = "items/gadgets/elixir.png"
GADGET.Duration    = 0
GADGET.Cooldown    = 20
GADGET.Active      = true
GADGET.Params      = {
    [1] = { value = 60 },
    [2] = { value = 300 },
}

GADGET.Hooks = {}

GADGET.Hooks.Horde_UseActiveGadget = function(ply)
    if CLIENT then return end
    if ply:Horde_GetGadget() ~= "gadget_acid_pulse" then return end
    HORDE:ApplyDebuffInRadius(HORDE.Status_Corrosion, ply:GetPos(), 300, 60, ply)
    ply:EmitSound("horde/status/bleeding_trigger.ogg")
end
