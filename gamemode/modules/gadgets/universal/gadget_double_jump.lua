GADGET.PrintName = "Air Stepper"
GADGET.Description = [[Grants double jump. Tap jump again in the air.]]
GADGET.Icon = "items/gadgets/air_stepper.png"
GADGET.Active = false
GADGET.Params = {
}
GADGET.Hooks = {}

GADGET.Hooks.PlayerTick = function(ply, mv)
    if CLIENT then return end
    if ply:Horde_GetGadget() ~= "gadget_double_jump" then return end

    if ply:OnGround() then
        ply.Horde_HasDoubleJumped = false
    end

    if not ply:OnGround() and not ply.Horde_HasDoubleJumped and mv:KeyPressed(IN_JUMP) then
        local vel = mv:GetVelocity()
        vel.z = 300
        mv:SetVelocity(vel)

        ply.Horde_HasDoubleJumped = true
        ply:EmitSound("player/suit_sprint.wav")
    end
end
