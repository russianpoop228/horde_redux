if SERVER then
    util.AddNetworkString("Horde_SyncInfusion")
    util.AddNetworkString("Horde_BuyInfusion")
    util.AddNetworkString("Horde_SellInfusion")
end

HORDE.Infusion_All = -1
HORDE.Infusion_None = 0
HORDE.Infusion_Hemo = 1
HORDE.Infusion_Concussive = 2
HORDE.Infusion_Septic = 3
HORDE.Infusion_Flaming = 4
HORDE.Infusion_Arctic = 5
HORDE.Infusion_Galvanizing = 6
HORDE.Infusion_Quality = 7
HORDE.Infusion_Impaling = 8
HORDE.Infusion_Rejuvenating = 9
HORDE.Infusion_Quicksilver = 10
HORDE.Infusion_Siphoning = 11
HORDE.Infusion_Titanium = 12
HORDE.Infusion_Chrono = 13
HORDE.Infusion_Ruination = 14

HORDE.Infusion_Names = HORDE.Infusion_Names or {}
HORDE.Infusion_Icons = HORDE.Infusion_Icons or {}
HORDE.Infusion_Colors = HORDE.Infusion_Colors or {}
HORDE.Infusion_Description = HORDE.Infusion_Description or {}
HORDE.Infusion_Fns = HORDE.Infusion_Fns or {}
HORDE.Infusion_ByKey = HORDE.Infusion_ByKey or {}
HORDE.Infusion_NextId = HORDE.Infusion_NextId or 15

local function _noop_infusion() end

function HORDE:RegisterInfusion(tbl)
    if not istable(tbl) then
        ErrorNoHaltWithStack("[Horde Infusion] RegisterInfusion expects a table\n")
        return nil
    end

    local key = tbl.Key or tbl.key or tbl.Name or tbl.name or tbl.PrintName
    local name = tbl.Name or tbl.name or tbl.PrintName or key
    if not key or key == "" then
        ErrorNoHaltWithStack("[Horde Infusion] RegisterInfusion: missing Key/Name\n")
        return nil
    end

    local id = tbl.Id or tbl.id
    if id == nil then
        if HORDE.Infusion_ByKey[key] ~= nil then
            id = HORDE.Infusion_ByKey[key]
        else
            id = HORDE.Infusion_NextId
            HORDE.Infusion_NextId = HORDE.Infusion_NextId + 1
        end
    end

    if id >= 32 then
        ErrorNoHaltWithStack("[Horde Infusion] Ran out of infusion ids (max 31 for net)\n")
        return nil
    end

    local const_name = "Infusion_" .. key
    HORDE[const_name] = id
    HORDE.Infusion_ByKey[key] = id
    HORDE.Infusion_Names[id] = name
    HORDE.Infusion_Icons[id] = tbl.Icon or tbl.icon or "infusion/infusion.png"
    HORDE.Infusion_Colors[id] = tbl.Color or tbl.color or color_white
    HORDE.Infusion_Description[id] = tbl.Description or tbl.description or ""
    HORDE.Infusion_Fns[id] = tbl.OnDamage or tbl.on_damage or _noop_infusion

    if GetConVar("developer") and GetConVar("developer"):GetBool() then
        print("[Horde Infusion] registered " .. key .. " id=" .. tostring(id))
    end

    hook.Run("Horde_OnInfusionRegistered", key, id, tbl)
    return id
end

function HORDE:IsInfusionRegistered(id)
    id = tonumber(id)
    return id ~= nil and (id == HORDE.Infusion_None or HORDE.Infusion_Names[id] ~= nil)
end

function HORDE:GetInfusionID(key)
    return HORDE.Infusion_ByKey and HORDE.Infusion_ByKey[key]
end

function HORDE:GetInfusionOnDamage(id)
    return (HORDE.Infusion_Fns and HORDE.Infusion_Fns[id]) or _noop_infusion
end

local plymeta = FindMetaTable("Player")

function plymeta:Horde_GetInfusion(class)
    if not self.Horde_Infusions then return HORDE.Infusion_None end
    if not self.Horde_Infusions[class] then return HORDE.Infusion_None end
    return self.Horde_Infusions[class]
end

function plymeta:Horde_HasInfusion(class, infusion)
    if not self.Horde_Infusions then return end
    if not self.Horde_Infusions[class] then return end
    return self.Horde_Infusions[class] == infusion
end

function plymeta:Horde_GetBuilderInfusion(class)
    if not self.Horde_BuilderInfusions then return HORDE.Infusion_None end
    return self.Horde_BuilderInfusions[class] or HORDE.Infusion_None
end

if CLIENT then
net.Receive("Horde_SyncInfusion", function(len, ply)
    MySelf.Horde_Infusions = net.ReadTable()
end)
net.Receive("Horde_SyncBuilderInfusion", function()
    MySelf.Horde_BuilderInfusions = net.ReadTable()
end)
end

if SERVER then
function HORDE:InfuseWeapon(ply, class, infusion)
    if not ply.Horde_Infusions then ply.Horde_Infusions = {} end
    if not ply.Horde_Infusions[class] then ply.Horde_Infusions[class] = {} end
    if infusion == HORDE.Infusion_None or not HORDE:IsInfusionRegistered(infusion) then
        ply.Horde_Infusions[class] = nil
    else
        ply.Horde_Infusions[class] = infusion
        if infusion == HORDE.Infusion_Chrono then
            if not ply.Horde_Infusion_Chrono_Wave then ply.Horde_Infusion_Chrono_Wave = {} end
            if not ply.Horde_Infusion_Chrono_Wave[class] then
                ply.Horde_Infusion_Chrono_Wave = {}
            end
            ply.Horde_Infusion_Chrono_Wave[class] = HORDE.current_wave
        else
            ply.Horde_Infusion_Chrono_Wave = {}
        end
    end
end

function HORDE:GetCurrentWeapon(inflictor)
    local curr_weapon = inflictor
    if inflictor:IsPlayer() then
        curr_weapon = inflictor:GetActiveWeapon()
    end
    return curr_weapon
end

hook.Add("Horde_OnPlayerDamagePre", "Horde_ApplyFusion", function (ply, npc, bonus, hitgroup, dmginfo)
    if not ply.Horde_Infusions then return end
    local inflictor = dmginfo:GetInflictor()
    local curr_weapon = HORDE:GetCurrentWeapon(inflictor)
    local infusion = ply.Horde_Infusions[curr_weapon:GetClass()]
    if not infusion then return end
    npc.hitgroup = hitgroup
    local _ifn = HORDE.Infusion_Fns[infusion]
    if not _ifn then return end
    local res = _ifn(ply, npc, bonus, hitgroup, dmginfo)
    if res == true then return res end
end)

hook.Add("Horde_OnPlayerDamageTaken", "Horde_ApplyFusionDamageTaken", function (ply, dmg, bonus)
    if not ply.Horde_Infusions then return end
    local curr_weapon = HORDE:GetCurrentWeapon(ply)
    if not curr_weapon:IsValid() then return end
    local infusion = ply.Horde_Infusions[curr_weapon:GetClass()]
    if not infusion then return end
    if infusion == HORDE.Infusion_Titanium then
        local item = HORDE.items[curr_weapon:GetClass()]
        if item and item.weight then
            bonus.less = bonus.less * (1 - 0.01 * item.weight)
        end
    elseif infusion == HORDE.Infusion_Flaming then
        if HORDE:IsFireDamage(dmg) then
            bonus.resistance = (bonus.resistance or 0) + 0.20
        end
    end
end)

net.Receive("Horde_BuyInfusion", function (len, ply)
    if not HORDE:AllowNetRequest(ply, "buy_infusion", 0.25) then return end
    if HORDE.IsPurismMode and HORDE:IsPurismMode() then return end
    if HORDE.UnarmedShopBlocked and HORDE:UnarmedShopBlocked(ply) then return end
    if not IsValid(ply) or not ply:Alive() or not ply.Horde_Init_Complete then return end
    local class = net.ReadString()
    local infusion = net.ReadUInt(5)
    if infusion ~= HORDE.Infusion_None and not HORDE:IsInfusionRegistered(infusion) then return end
    local item = HORDE.items and HORDE.items[class]
    if not item or not istable(item.infusions) or table.IsEmpty(item.infusions)
        or not table.HasValue(item.infusions, infusion) or not ply:HasWeapon(class) then return end
    local item_price = tonumber(item.price)
    if not item_price or item_price < 0 or item_price ~= item_price then return end
    local price = 100 + item_price / 5
    local previous = ply:Horde_GetInfusion(class)
    if previous == infusion then return end
    local refund = 0
    if previous ~= HORDE.Infusion_None then
        local paid = ply.Horde_Infusion_Paid and tonumber(ply.Horde_Infusion_Paid[class]) or 0
        refund = math.floor(math.max(0, paid) * 0.75)
    end
    local charge = math.max(0, price - refund)
    if ply:Horde_GetMoney() >= charge then
        if not ply.Horde_Infusion_Paid then ply.Horde_Infusion_Paid = {} end
        ply:Horde_AddMoney(-charge)
        ply.Horde_Infusion_Paid[class] = charge
        HORDE:InfuseWeapon(ply, class, infusion)
        net.Start("Horde_SyncInfusion")
            net.WriteTable(ply.Horde_Infusions)
        net.Send(ply)
        ply:Horde_SyncEconomy()
    end
    if infusion == HORDE.Infusion_Ruination then ply.Horde_Last_Ruination_Check = CurTime() end
end)

net.Receive("Horde_SellInfusion", function (len, ply)
    if not HORDE:AllowNetRequest(ply, "sell_infusion", 0.25) then return end
    if HORDE.UnarmedShopBlocked and HORDE:UnarmedShopBlocked(ply) then return end
    if not IsValid(ply) or not ply:Alive() or not ply.Horde_Init_Complete then return end
    local class = net.ReadString()
    local item = HORDE.items and HORDE.items[class]
    if not item or not ply:HasWeapon(class) then return end
    local infusion = ply:Horde_GetInfusion(class)
    local paid = ply.Horde_Infusion_Paid and tonumber(ply.Horde_Infusion_Paid[class])
    if infusion == HORDE.Infusion_None or not paid or paid <= 0 then return end
    local ret_price = math.floor(paid * 0.75)
    if ret_price <= 0 then return end
    HORDE:InfuseWeapon(ply, class, HORDE.Infusion_None)
    ply.Horde_Infusion_Paid[class] = nil
    ply:Horde_AddMoney(ret_price)
    net.Start("Horde_SyncInfusion")
        net.WriteTable(ply.Horde_Infusions)
    net.Send(ply)
    ply:Horde_SyncEconomy()
end)

HORDE:AddPlayerTick("Horde_Ruination", function(ply, mv)

    if not ply.Horde_Infusions then return end

    local curr_weapon = HORDE:GetCurrentWeapon(ply)
    if not IsValid(curr_weapon) then return end

    local infusion = ply.Horde_Infusions[curr_weapon:GetClass()]

    if infusion == HORDE.Infusion_Ruination then

        if not ply.Horde_Ruination_NextTick
            or ply.Horde_Ruination_NextTick <= CurTime() then

            ply.Horde_Ruination_NextTick = CurTime() + 1

            ply:Horde_AddDebuffBuildup(HORDE.Status_Necrosis, 5.5)
        end
    end
end)

if SERVER then
    util.AddNetworkString("Horde_SyncBuilderInfusion")
    util.AddNetworkString("Horde_SetBuilderInfusion")
end

if SERVER then

function HORDE:Horde_GetBuilderInfusionPrice(class)
    local def = HORDE:Horde_GetBuilderSystemForBuildable(class)
    if def and def.GetInfusionPrice then return def.GetInfusionPrice(class) end
    local cost = HORDE:Horde_GetBuildableCost(class)
    return math.floor(100 + cost / 5)
end

net.Receive("Horde_SetBuilderInfusion", function(len, ply)
    if not ply:IsValid() or not ply:Alive() then return end
    if HORDE.IsPurismMode and HORDE:IsPurismMode() then return end
    local class = net.ReadString()
    local infusion = net.ReadUInt(5)

    local def = HORDE:Horde_GetBuilderSystemForBuildable(class)
    if not def then return end
    if infusion ~= HORDE.Infusion_None and def.IsInfusionAllowed and not def.IsInfusionAllowed(class, infusion) then return end

    if not ply.Horde_BuilderInfusions then ply.Horde_BuilderInfusions = {} end
    local had_infusion = ply.Horde_BuilderInfusions[class] ~= nil

    if infusion == HORDE.Infusion_None then
        ply.Horde_BuilderInfusions[class] = nil
    else
        local price = HORDE:Horde_GetBuilderInfusionPrice(class)
        local refund = had_infusion and math.floor(price * 0.75) or 0
        if not HORDE:Horde_BuilderSpendCurrency(def, ply, price - refund, "infusion") then
            HORDE:SendNotification("Not enough " .. HORDE:Horde_BuilderCurrencyName(def, "infusion") .. " (need " .. (price - refund) .. ").", 1, ply)
            return
        end
        ply.Horde_BuilderInfusions[class] = infusion
    end

    net.Start("Horde_SyncBuilderInfusion")
        net.WriteTable(ply.Horde_BuilderInfusions)
    net.Send(ply)
end)

hook.Add("Horde_OnPlayerMinionDamage", "Horde_ApplyBuilderInfusion", function(ply, npc, bonus, dmginfo)
    if not ply.Horde_BuilderInfusions then return end
    local class = dmginfo:GetInflictor():GetClass()
    local infusion = ply.Horde_BuilderInfusions[class]
    if not infusion then return end
    local _bifn = HORDE.Infusion_Fns[infusion]
    if _bifn then _bifn(ply, npc, bonus, nil, dmginfo) end
end)

end

end
