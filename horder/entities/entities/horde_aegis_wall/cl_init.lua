include("shared.lua")

local TOP_MODEL = "models/hunter/plates/plate2x2.mdl"
local TOP_MAT   = "models/props_combine/stasisshield_sheet"
local TOP_OFFSET = Vector(0, 0, 50)

function ENT:Initialize()
	self:CreateTopPlate()
end

function ENT:CreateTopPlate()
	if IsValid(self.TopCS) then
		self.TopCS:Remove()
		self.TopCS = nil
	end

	local cs = ClientsideModel(TOP_MODEL, RENDERGROUP_OPAQUE)
	if not IsValid(cs) then return end

	cs:SetMaterial(TOP_MAT)
	cs:SetNoDraw(true)
	cs:SetPos(self:GetPos())
	cs:SetAngles(self:GetAngles())
	cs:SetParent(self)

	self.TopCS = cs
end

function ENT:Draw()
	self:DrawModel()

	if not IsValid(self.TopCS) then
		self:CreateTopPlate()
	end

	if IsValid(self.TopCS) then
		local pos = self:LocalToWorld(TOP_OFFSET)
		local ang = self:GetAngles() + Angle(90, 0, 0)
		self.TopCS:SetRenderOrigin(pos)
		self.TopCS:SetRenderAngles(ang)
		self.TopCS:SetupBones()
		self.TopCS:DrawModel()
	end
end

function ENT:OnRemove()
	if IsValid(self.TopCS) then
		self.TopCS:Remove()
		self.TopCS = nil
	end
end
