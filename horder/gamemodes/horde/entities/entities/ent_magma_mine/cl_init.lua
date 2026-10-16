include('shared.lua')

function ENT:Initialize()
    self:SetMaterial("models/player/shared/gold_player")
end

function ENT:Draw()
    self:DrawModel()
end

hook.Add("PreDrawHalos", "Horde_MagmaMine_Halo", function()
    local mines = ents.FindByClass("ent_magma_mine")
    if #mines > 0 then
        halo.Add(mines, Color(255, 100, 0), 2, 2, 1, true, false)
    end
end)
