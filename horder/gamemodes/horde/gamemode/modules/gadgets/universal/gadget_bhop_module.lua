GADGET.PrintName = "Bhop Module"
GADGET.Description = [[
Installs a hydraulic system in your legs.
Allows you to auto-jump by holding the Space bar.
Maintains momentum, but does not increase air control.
]]
GADGET.Icon = "items/gadgets/agility_shard.png"
GADGET.Droppable = false
GADGET.Active = false
GADGET.Cooldown = 0
GADGET.Params = {}
GADGET.Hooks = {}

GADGET.Hooks.PlayerTick = function(ply, mv, cmd)
    if ply:Horde_GetGadget() ~= "gadget_bhop_module" then return end
    if not IsValid(ply) or not ply:Alive() then return end
    if ply:WaterLevel() >= 2 or ply:GetMoveType() == MOVETYPE_LADDER then return end
    if mv:KeyDown(IN_JUMP) then
        if not ply:IsOnGround() then
            mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
        end
    end
end
