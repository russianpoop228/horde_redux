GADGET.PrintName = "Matriarch Womb"
GADGET.Description = [[
Spawns 1 friendly headcrab when used.
The headcrab dies after 10 seconds.]]
GADGET.Icon = "items/gadgets/matriarch_womb.png"
GADGET.Duration = 0
GADGET.Cooldown = 10
GADGET.Active = true
GADGET.Droppable = true
GADGET.Params = {}
GADGET.Hooks = {}

GADGET.Hooks.Horde_UseActiveGadget = function (ply)
    if CLIENT then return end
    if ply:Horde_GetGadget() ~= "gadget_matriarch_womb" then return end

    local ent = ents.Create("npc_vj_horde_headcrab")
    ent:SetPos(ply:GetPos() + ply:GetForward() * 50 + Vector(0,0,1) * 10)
    HORDE:AssignMinionOwner(ent, ply)
    ent:Spawn()
    HORDE:RegisterMinion(ent, ply, { weightless = true })

    timer.Simple(10, function ()
        if ent:IsValid() then ent:Remove() end
    end)
end
