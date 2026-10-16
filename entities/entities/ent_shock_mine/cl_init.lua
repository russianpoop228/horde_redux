include('shared.lua')

function ENT:Initialize()
    self:SetMaterial("models/player/shared/ice_player")
end

function ENT:Draw()
    self:DrawModel()
end

hook.Add("PreDrawHalos", "Horde_ShockMine_Halo", function()
    local mines = ents.FindByClass("ent_shock_mine")

    if #mines > 0 then
        halo.Add(
            mines,
            Color(255, 255, 0),
            2,
            2,
            1,
            true,
            false
        )
    end
end)
