HORDE.Attachments = {}
HORDE.Attachments.Pricings = {}
HORDE.UniversalPricing = 100
HORDE.UniversalCategoryPricing = {
	["Optic"] = 100,
	["Underbarrel"] = 150,
	["Tactical"] = 100,
	["Barrel"] = 125,
	["Muzzle"] = 125,
	["Magazine"] = 150,
	["Stock"] = 100,
	["Ammo Type"] = 50,
	["Perk"] = 200,
	["Charm"] = 0,
}

function HORDE.CompressTable(t)
	local data = util.Compress(util.TableToJSON(t))
	local len = #data
	return data, len
end

function HORDE.DecompressTable(data)
	return util.JSONToTable(util.Decompress(data))
end

function HORDE.GetAttachmentPrice(slot, class)
	local uPrice = HORDE.UniversalCategoryPricing[slot] || HORDE.UniversalPricing
	local att = HORDE.items[class]
	if(att && att.price) then
		uPrice = att.price
	end
	return uPrice
end

if(SERVER) then
	util.AddNetworkString("Horde_RequestAttachments")
	util.AddNetworkString("Horde_SyncAttachments")
	util.AddNetworkString("Horde_BuyAttachment")

	function HORDE.SaveAttachments()
		local data = HORDE.CompressTable(HORDE.Attachments.Pricings)
		file.Write("horde/attachments.txt", data)
	end

	function HORDE.ReadAttachments()
		if(file.Exists("horde/attachments.txt", "DATA")) then
			local data = file.Read("horde/attachments.txt", "DATA")
			local tbl = HORDE:DecodeCompressedJSON(data)
			if tbl and HORDE.Validate.Attachments(tbl) then
				HORDE.Attachments.Pricings = tbl
			else
				print("[HORDE] - horde/attachments.txt is invalid, ignoring it.")
			end
		end
	end

	function HORDE.BroadcastAttachments()
		local data, len = HORDE.CompressTable(HORDE.Attachments.Pricings)
		net.Start("Horde_SyncAttachments")
		net.WriteUInt(len, 32)
		net.WriteData(data, len)
		net.Broadcast()
	end

	function HORDE.SyncAttachments(ply)
		local data, len = HORDE.CompressTable(HORDE.Attachments.Pricings)
		net.Start("Horde_SyncAttachments")
		net.WriteUInt(len, 32)
		net.WriteData(data, len)
		net.Send(ply)
	end

	net.Receive("Horde_RequestAttachments", function(len, ply)
		if not IsValid(ply) then return end
		if not HORDE:AllowNetRequest(ply, "request_attachments", 1) then return end
		HORDE.SyncAttachments(ply)
	end)

	net.Receive("Horde_SyncAttachments", function(len, ply)
		if(!IsValid(ply) or !ply:IsSuperAdmin()) then return end
		if not HORDE:AllowNetRequest(ply, "sync_attachments", 2) then return end
		local tbl, err = HORDE:ReadCompressedJSON()
		if not tbl then
			HORDE:SendNotification("Attachment config rejected: " .. tostring(err), 1, ply)
			return
		end
		local ok, verr = HORDE.Validate.Attachments(tbl)
		if not ok then
			HORDE:SendNotification("Attachment config rejected: " .. tostring(verr), 1, ply)
			return
		end
		HORDE.Attachments.Pricings = tbl
		HORDE.BroadcastAttachments()
		HORDE.SaveAttachments()
	end)

		net.Receive("Horde_BuyAttachment", function(len, ply)
            if not HORDE:AllowNetRequest(ply, "buy_attachment", 0.25) then return end
            if not IsValid(ply) or not ply:Alive() or not ply.Horde_Init_Complete then return end
			local requested_slot = net.ReadString()
			local class = net.ReadString()
			local item = HORDE.items and HORDE.items[class]
			local properties = item and item.entity_properties
			if not item or item.category ~= "Attachment" or not properties
				or properties.is_arccw_attachment ~= true or properties.type ~= HORDE.ENTITY_PROPERTY_GIVE then return end
			if not ArcCWInstalled or not ArcCW or not isfunction(ArcCW.PlayerGiveAtt)
				or not isfunction(ArcCW.PlayerSendAttInv) then return end
			if HORDE.UnarmedShopBlocked and HORDE:UnarmedShopBlocked(ply) then return end
			local subclass = ply:Horde_GetCurrentSubclass()
			if not subclass or (item.whitelist and item.whitelist[subclass] ~= true) then return end
			local server_slot = properties.arccw_attachment_type
			if not isstring(server_slot) or server_slot == "" then return end
			local price = tonumber(item.price) or tonumber(HORDE.UniversalCategoryPricing[server_slot])
			if not price or price < 0 or price ~= price then return end
			if(ply:Horde_GetMoney() < price) then return end
			ArcCW:PlayerGiveAtt(ply, class, 1)
		ArcCW:PlayerSendAttInv(ply)
		ply:EmitSound("weapons/arccw/useatt.wav")
		ply:Horde_AddMoney(-price)
		ply:Horde_SyncEconomy()
	end)

	HORDE.ReadAttachments()
else
	function HORDE.RequestAttachments()
		net.Start("Horde_RequestAttachments")
		net.SendToServer()
	end

	function HORDE.IsAttachmentWhitelisted(class)
		local att = HORDE.items[class]
		if(GetConVar("horde_testing_attachment_copy"):GetInt() == 1) then return true end
		if(!att) then return false end
		if(!att.whitelist) then return true end
		local subclass = LocalPlayer():Horde_GetCurrentSubclass()
		return att.whitelist[subclass] == true
	end

	net.Receive("Horde_SyncAttachments", function()
		local len = net.ReadUInt(32)
		local data = net.ReadData(len)
		HORDE.Attachments.Pricings = HORDE.DecompressTable(data)
	end)

	hook.Add("InitPostEntity", "Horde_GetAttachments", function()
	end)
end
