ENT.Type = "point"

function ENT:Think()
end

function ENT:AcceptInput(name, activator, caller, args)
	name = string.lower(name)
	if string.sub(name, 1, 2) == "on" then
		self:FireOutput(name, activator, caller, args)
	elseif name == "activateachievement" then
		if not self.Achievement or self.Achievement == "" then return true end
		local ply
		for _, e in ipairs(ents.FindByName(tostring(args or ""))) do
			if IsValid(e) and e:IsPlayer() then ply = e break end
		end
		if not ply and IsValid(activator) and activator:IsPlayer() then ply = activator end
		if ply then
			net.Start("Horde_SaveExtraAchievements")
				net.WriteString(self.Achievement)
			net.Send(ply)
		end
		return true
    end
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if string.sub(key, 1, 2) == "on" then
		self:AddOnOutput(key, value)
	elseif key == "achievement" then
		self.Achievement = tostring(value or "")
	elseif key == "description" then
		self.Description = tostring(value or "")
	end
end
