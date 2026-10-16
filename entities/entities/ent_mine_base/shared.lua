ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Mine Base"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Armed")
end
