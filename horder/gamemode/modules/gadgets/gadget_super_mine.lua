GADGET.PrintName   = "Super Mine"
GADGET.Description =
[[Instantly places a Super Mine at your feet.
Combines Shock, Frosty and Magma explosions simultaneously,
plus a direct blast dealing 33% more damage than a Tank Mine.
One use only.]]
GADGET.Icon      = "items/gadgets/super_mine.png"
GADGET.Droppable = false
GADGET.Cooldown  = 0
GADGET.Once      = true
GADGET.Active    = true
GADGET.Params    = {}
GADGET.Hooks     = {}

GADGET.Hooks.Horde_UseActiveGadget = function(ply)
    if CLIENT then return end
    if ply:Horde_GetGadget() ~= "gadget_super_mine" then return end

    local forward = ply:GetAimVector()
    forward.z = 0.5
    forward:Normalize()

    local spawnPos = ply:GetPos() + forward * 60

    local mine = ents.Create("ent_super_mine")
    if not IsValid(mine) then return end

    mine:SetPos(spawnPos)
    mine:SetAngles(Angle(0, ply:GetAngles().y, 0))
    mine:SetOwner(ply)
    mine.Horde_Owner = ply
    mine:Spawn()
    mine:Activate()

    local phys = mine:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end

    mine:EmitSound("weapons/c4/c4_plant.wav")
end
