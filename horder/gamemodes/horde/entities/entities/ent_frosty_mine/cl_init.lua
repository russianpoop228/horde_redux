include('shared.lua')

function ENT:Initialize()
    self:SetMaterial("models/player/shared/ice_player")
end

function ENT:Draw()
    self:DrawModel()
end

hook.Add("PreDrawHalos", "Horde_FrostyMine_Halo", function()
    local mines = ents.FindByClass("ent_frosty_mine")

    if #mines > 0 then
        halo.Add(
            mines,
            Color(135, 206, 235),
            2,
            2,
            1,
            true,
            false
        )
    end
end)
