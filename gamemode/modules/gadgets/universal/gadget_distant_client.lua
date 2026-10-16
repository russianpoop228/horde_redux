GADGET.PrintName = "Distant Client"
GADGET.Description = [[You can buy anything in the store every 2 minutes while the wave is going on.
You will be given 30 seconds to make your purchase.
But when wave will end, you won't be able to buy anything.You'll have to wait for the next wave.
]]
GADGET.Icon = "items/gadgets/distant_client.png"
GADGET.Droppable = false
GADGET.Cooldown =120
GADGET.Active = true
GADGET.Hooks = {}

GADGET.Hooks.Horde_UseActiveGadget = function (ply)
    if ply:Horde_GetGadget() ~= "gadget_distant_client"  then return end

    net.Start("Horde_ToggleShop")
    net.Send(ply)
    timer.Simple(30,function()
        net.Start("Horde_ForceCloseShop")
        net.Send(ply)
    end)

end

GADGET.Hooks.PlayerTick = function (ply, mv)
    if CLIENT then return end
    if ply:Horde_GetGadget() ~= "gadget_distant_client" then return end
    if  ply:IsValid()  then
        ply:Horde_SetInBuyZone(false )
    end
end
