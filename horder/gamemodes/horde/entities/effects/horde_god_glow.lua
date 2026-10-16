local GLOW_R = 255
local GLOW_G = 140
local GLOW_B = 0
local GLOW_BRIGHTNESS = 3
local GLOW_SIZE = 110
local GLOW_DECAY = 320

local OUTLINE_COLORS = {
	["npc_vj_horde_scorcher_spectre"]  = Color(255, 60, 0),
	["npc_vj_horde_screecher_spectre"] = Color(255, 190, 0),
}

hook.Add("PreDrawHalos", "Horde_GodSpectreOutline", function ()
	for class, color in pairs(OUTLINE_COLORS) do
		local summons = ents.FindByClass(class)
		if #summons > 0 then
			halo.Add(summons, color, 3, 3, 1, true, true)
		end
	end
end)

function EFFECT:Init(effect_data)
	self.entity = effect_data:GetEntity()
end

function EFFECT:Think()
	if not IsValid(self.entity) then return false end

	local pos = self.entity:GetPos()
	if not self.dlight then
		self.dlight = DynamicLight(0)
	end
	if self.dlight then
		self.dlight.Pos = pos
		self.dlight.r = GLOW_R
		self.dlight.g = GLOW_G
		self.dlight.b = GLOW_B
		self.dlight.Brightness = GLOW_BRIGHTNESS
		self.dlight.Size = GLOW_SIZE
		self.dlight.Decay = GLOW_DECAY
		self.dlight.DieTime = CurTime() + 0.2
	end

	return true
end

function EFFECT:Render()
end
