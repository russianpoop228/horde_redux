ENT.Type = "brush"
ENT.LastThink = CurTime()
ENT.ThinkInterval = 0.5
ENT.Horde_HalfNotification = true

local REPOSITION_SYNC_INTERVAL = 0.25

function ENT:Initialize()
	self.LastThink = CurTime()
	self.Horde_Players_In_Zone = {}

	self.Horde_Hold_Progress = 0
	self.Horde_Progress_Amount = 1
	self.Horde_Activated = nil

	self.Horde_Zone_Id = self:GetCreationID()
	self.Horde_Player_Count = player.GetCount()
	self.Horde_Last_Holding = 0

	self.Horde_Total_Progress = 100
	self.Horde_Shape = HORDE.ZONE_SHAPE_BOX
	self.Horde_Radius = 0
	self.Horde_FixedOrientation = false
	self.Horde_UprightAng = Angle(0, 0, 0)

	self:SetMoveType(MOVETYPE_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	self:Horde_ApplyShape()
end

function ENT:Horde_ApplyShape()
if SERVER then
	if self.Horde_Shape == HORDE.ZONE_SHAPE_CYLINDER then
		self:SetSolid(SOLID_NONE)
		self:SetTrigger(false)
		self:SetNotSolid(true)
	else
		self:SetSolid(SOLID_BSP)
		self:SetTrigger(true)
		self:SetNotSolid(false)
	end
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
end
end

function ENT:Horde_GetShapeData()
	local shape, center, radius, height = HORDE:GetZoneShapeData(self)
	self.Horde_Shape = shape
	self.Horde_Radius = radius
	return shape, center, radius, height
end

function ENT:Horde_SyncLocation()
if SERVER and HORDE.horde_active_holdzones and HORDE.horde_active_holdzones[self.Horde_Zone_Id] then
	local shape, _, radius = self:Horde_GetShapeData()
	net.Start("Horde_SyncHoldLocation")
		net.WriteUInt(self.Horde_Zone_Id, 4)
		net.WriteVector(self:GetPos())
		net.WriteAngle(self:GetAngles())
		net.WriteVector(self:OBBMins())
		net.WriteVector(self:OBBMaxs())
		net.WriteUInt(shape, 1)
		net.WriteFloat(radius)
	net.Broadcast()
end
end

function ENT:Horde_SetFollowParent(parent)
if SERVER then
	if not IsValid(parent) then
		if IsValid(self:GetParent()) then
			self:SetParent(NULL)
		end
		self.Horde_Follow_Parent = nil
		self.Horde_FollowOffsetPos = nil
		self.Horde_FollowOffsetAng = nil
		return
	end

	self.Horde_Follow_Parent = parent
	self.Horde_FollowOffsetPos = parent:WorldToLocal(self:GetPos())
	local parent_ang = parent:GetAngles()
	local ang = self:GetAngles()
	self.Horde_FollowOffsetAng = Angle(
		ang.pitch - parent_ang.pitch,
		ang.yaw - parent_ang.yaw,
		ang.roll - parent_ang.roll
	)
	if not self.Horde_UprightAng then
		self.Horde_UprightAng = Angle(0, ang.yaw, 0)
	end

	if self.Horde_FixedOrientation then
		if IsValid(self:GetParent()) then
			self:SetParent(NULL)
		end
		self:SetAngles(self.Horde_UprightAng or Angle(0, 0, 0))
	else
		self:SetParent(parent)
	end

	self:Horde_SyncLocation()
end
end

function ENT:Horde_FollowParent()
	local parent = self.Horde_Follow_Parent
	if not IsValid(parent) then
		if IsValid(self:GetParent()) then
			self:SetParent(NULL)
		end
		self.Horde_Follow_Parent = nil
		return
	end

	if self.Horde_FixedOrientation then
		if IsValid(self:GetParent()) then
			self:SetParent(NULL)
		end
		local target_pos = parent:LocalToWorld(self.Horde_FollowOffsetPos or Vector(0, 0, 0))
		local upright = self.Horde_UprightAng or Angle(0, 0, 0)
		if self:GetPos():DistToSqr(target_pos) > 0.01 then
			self:SetPos(target_pos)
		end
		local cur = self:GetAngles()
		if math.abs(cur.pitch - upright.pitch) > 0.1
			or math.abs(cur.yaw - upright.yaw) > 0.1
			or math.abs(cur.roll - upright.roll) > 0.1 then
			self:SetAngles(upright)
		end
	else
		if self:GetParent() ~= parent then
			self:SetParent(parent)
		end
	end

	local now = CurTime()
	if (self.Horde_NextLocationSync or 0) <= now then
		self.Horde_NextLocationSync = now + REPOSITION_SYNC_INTERVAL
		self:Horde_SyncLocation()
	end
end

function ENT:Horde_RefreshPlayersInZone()
	local in_zone, used = {}, {}
	local my_pos = self:GetPos()

	local nearby = {}
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:Alive() and ply:GetPos():DistToSqr(my_pos) < 1000000 then
			nearby[#nearby + 1] = ply
		end
	end

	if self.Horde_Shape == HORDE.ZONE_SHAPE_CYLINDER then
		for _, ply in ipairs(nearby) do
			if HORDE:IsInsideZone(self, ply:GetPos()) then
				in_zone[ply:SteamID()] = ply
			end
		end
	else
		for _, ply in ipairs(nearby) do
			if self.Horde_Players_In_Zone[ply:SteamID()] or HORDE:IsInsideZone(self, ply:GetPos()) then
				in_zone[ply:SteamID()] = ply
			end
		end
	end

	for steamid, ply in pairs(in_zone) do
		if not self.Horde_Players_In_Zone[steamid] then
			net.Start("Horde_SyncStatus")
				net.WriteUInt(HORDE.Status_CanHold, 8)
				net.WriteUInt(1, 8)
			net.Send(ply)
		end
		used[steamid] = true
	end
	for steamid, ply in pairs(self.Horde_Players_In_Zone) do
		if not used[steamid] and IsValid(ply) then
			net.Start("Horde_SyncStatus")
				net.WriteUInt(HORDE.Status_CanHold, 8)
				net.WriteUInt(0, 8)
			net.Send(ply)
		end
	end

	self.Horde_Players_In_Zone = in_zone
end

function ENT:Horde_SetActivated(activated)
	self.Horde_Activated = activated
	self.Horde_Player_Count = player.GetCount()
	self.Horde_Progress_Amount = 1
	if self.Horde_Player_Count == 1 then
		self.Horde_Progress_Amount = self.Horde_Progress_Amount * 1
	elseif self.Horde_Player_Count == 2 then
		self.Horde_Progress_Amount = self.Horde_Progress_Amount * 0.65
	elseif self.Horde_Player_Count == 3 then
		self.Horde_Progress_Amount = self.Horde_Progress_Amount * 0.5
	elseif self.Horde_Player_Count >= 4 then
		self.Horde_Progress_Amount = self.Horde_Progress_Amount * 0.35
	end
	if activated and self.Horde_RefreshPlayersInZone then
		self:Horde_RefreshPlayersInZone()
	end
end

function ENT:Think()
	if self.Horde_Follow_Parent then
		self:Horde_FollowParent()
	end

	if not HORDE.game_end and self.Horde_Activated then
		if self.LastThink < CurTime() and (HORDE.current_wave == self.Horde_Active_Wave or self.Horde_Active_Wave <= 0) and HORDE.current_break_time <= 0 then
			if self.Horde_Shape == HORDE.ZONE_SHAPE_CYLINDER then
				self:Horde_RefreshPlayersInZone()
			end
			if self.Horde_Hold_Progress >= self.Horde_Total_Progress then
				self.Horde_Hold_Progress = 0
				self.Horde_Activated = nil
				self.Horde_HalfNotification = true
				HORDE:SyncHoldZoneProgress(self.Horde_Zone_Id, self.Horde_Hold_Progress)
				HORDE:EndObjective(HORDE.OBJECTIVE_HOLD, {zone=self})
				for _, p in pairs(self.Horde_Players_In_Zone) do
					if p:IsValid() then
						p:Horde_AddMoney(HORDE.round_bonus_base * 0.2)
						p:Horde_SyncEconomy()
						net.Start("Horde_SyncStatus")
							net.WriteUInt(HORDE.Status_CanHold, 8)
							net.WriteUInt(0, 8)
						net.Send(p)
					end
				end
				self.Horde_Players_In_Zone = {}
			elseif self.Horde_Hold_Progress >= 50 and self.Horde_HalfNotification then
				HORDE:SendNotificationObjective(HORDE.OBJECTIVE_HOLD, "You have defended " .. (self.Horde_Zone_Label or "the area") .. " for 50%!")
				self.Horde_HalfNotification = nil
			end

			if self.Horde_Activated then
				if self.Horde_Last_Holding + 5 <= CurTime() and table.Count(self.Horde_Players_In_Zone) == 0 then
					if self.Horde_Hold_Progress >= 50 then
						self.Horde_Hold_Progress = math.max(1, self.Horde_Hold_Progress - self.Horde_Progress_Amount / 2)
						HORDE:SyncHoldZoneProgress(self.Horde_Zone_Id, self.Horde_Hold_Progress)
					end
				else
					local progress = 0
					for _, p in pairs(self.Horde_Players_In_Zone) do
						if p:IsValid() and p:Alive() then
							progress = progress + self.Horde_Progress_Amount
							if self.Horde_Hold_Progress < 50 then
								p:Horde_AddMoney(1)
								p:Horde_SyncEconomy()
							end
						end
					end
					progress = math.min(1, progress)
					self.Horde_Hold_Progress = self.Horde_Hold_Progress + progress
					HORDE:SyncHoldZoneProgress(self.Horde_Zone_Id, self.Horde_Hold_Progress)
					if progress > 0 then
						self.Horde_Last_Holding = CurTime()
					end
				end
			end

			self.LastThink = CurTime() + self.ThinkInterval
		end
	end

	self:NextThink(CurTime())
	return true
end

function ENT:StartTouch(ent)
	if self.Horde_Shape == HORDE.ZONE_SHAPE_CYLINDER then return end
	if self.Horde_Activated and ent:IsPlayer() then
		self.Horde_Players_In_Zone[ent:SteamID()] = ent
		net.Start("Horde_SyncStatus")
			net.WriteUInt(HORDE.Status_CanHold, 8)
			net.WriteUInt(1, 8)
		net.Send(ent)
	end
end

function ENT:Touch(ent)
	if self.Horde_Shape == HORDE.ZONE_SHAPE_CYLINDER then return end
	if self.Horde_Activated and ent:IsPlayer() and ent:Alive() then
		self.Horde_Players_In_Zone[ent:SteamID()] = ent
	end
end

function ENT:EndTouch(ent)
	if self.Horde_Shape == HORDE.ZONE_SHAPE_CYLINDER then return end
	if self.Horde_Activated and ent:IsPlayer() then
		self.Horde_Players_In_Zone[ent:SteamID()] = nil
		net.Start("Horde_SyncStatus")
			net.WriteUInt(HORDE.Status_CanHold, 8)
			net.WriteUInt(0, 8)
		net.Send(ent)
	end
end

function ENT:AcceptInput(name, activator, caller, arg)
if not SERVER then return end
	name = string.lower(name)

	if name == "setparent" then
		local found = ents.FindByName(arg or "")
		self:Horde_SetFollowParent(IsValid(found[1]) and found[1] or nil)
		return true
	elseif name == "enable" or name == "unhide" then
		self.Horde_Disabled = nil
		return true
	elseif name == "disable" or name == "hide" then
		self.Horde_Disabled = true
		return true
	elseif name == "toggle" then
		self.Horde_Disabled = not self.Horde_Disabled
		return true
	elseif name == "setgroup" then
		self.Horde_Zone_Group = tonumber(arg) or 0
		return true
	elseif name == "setlink" then
		self.Horde_Obj_Link = tonumber(arg) or 0
		return true
	elseif name == "setradius" then
		self.Horde_Radius = math.max(0, tonumber(arg) or 0)
		self:Horde_ApplyShape()
		return true
	elseif name == "setshape" then
		self.Horde_Shape = (tonumber(arg) == HORDE.ZONE_SHAPE_CYLINDER)
			and HORDE.ZONE_SHAPE_CYLINDER or HORDE.ZONE_SHAPE_BOX
		self:Horde_ApplyShape()
		return true
	elseif name == "setfixedorientation" or name == "sfixedorientation" then
		self.Horde_FixedOrientation = (tonumber(arg) or 0) ~= 0
		if IsValid(self.Horde_Follow_Parent) then
			self:Horde_SetFollowParent(self.Horde_Follow_Parent)
		end
		return true
	end
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "wave" then
		self.Horde_Active_Wave = tonumber(value) or -1
		if self.Horde_Active_Wave == -1 then
			self.Horde_Active_Wave = 0
		end
	elseif key == "group" then
		self.Horde_Zone_Group = tonumber(value) or 0
	elseif key == "label" then
		self.Horde_Zone_Label = value or "the area"
	elseif key == "shape" then
		self.Horde_Shape = (tonumber(value) == HORDE.ZONE_SHAPE_CYLINDER)
			and HORDE.ZONE_SHAPE_CYLINDER or HORDE.ZONE_SHAPE_BOX
	elseif key == "radius" then
		self.Horde_Radius = math.max(0, tonumber(value) or 0)
	elseif key == "height" then
		self.Horde_Height = tonumber(value)
	elseif key == "combine" or key == "merge" then
		self.Horde_Obj_Combine = (tonumber(value) or 0) ~= 0
	elseif key == "link" then
		self.Horde_Obj_Link = tonumber(value) or 0
	elseif key == "fixedorientation" or key == "fixed_orientation" or key == "upright" then
		self.Horde_FixedOrientation = (tonumber(value) or 0) ~= 0
	elseif key == "parent" or key == "parentname" then
		self.Horde_Parent_Name = value
	elseif key == "disabled" then
		if (tonumber(value) or 0) ~= 0 then self.Horde_Disabled = true end
	elseif key == "oncompleted" then
		self:StoreOutput(key, value)
	end
end

hook.Add("InitPostEntity", "Horde_Holdzone_Parents", function()
	for _, zone in ipairs(ents.FindByClass("trigger_horde_holdzone")) do
		if zone.Horde_Parent_Name and zone.Horde_Parent_Name ~= "" then
			local parent = ents.FindByName(zone.Horde_Parent_Name)
			if IsValid(parent[1]) then
				zone:Horde_SetFollowParent(parent[1])
			end
		end
	end
end)
