include("shared.lua")

function ENT:Draw()
    self:DrawModel()
end

hook.Add("PreDrawHalos", "Horde_SuperMine_Halo", function()
    local mines = ents.FindByClass("ent_super_mine")
    if #mines > 0 then
        halo.Add(mines, Color(255, 165, 0), 3, 3, 1, true, false)
    end
end)
