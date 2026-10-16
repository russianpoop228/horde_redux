ENT.Type = "anim"
ENT.Base = "ent_mine_base"
ENT.PrintName = "Combine Tripmine"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self.BaseClass.SetupDataTables(self)

    self:NetworkVar("Bool", 1, "DrawLaser")
    self:NetworkVar("Vector", 0, "BeamEnd")
end
