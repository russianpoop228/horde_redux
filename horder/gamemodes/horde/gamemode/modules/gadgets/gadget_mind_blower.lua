GADGET.PrintName = "Mind Blower"
GADGET.Description = "Reveals your mines across the entire map and lets you activate them remotely.\nWhile this gadget is equipped, your mines cannot be activated by enemies or other means."
GADGET.Icon = "items/gadgets/mind_blower.png"
GADGET.Droppable = false
GADGET.Cooldown = 8
GADGET.Active = true
GADGET.Params = {}
GADGET.Hooks = {}

local MINE_CLASSES = {
    "ent_shock_mine",
    "ent_frosty_mine",
    "ent_magma_mine",
    "ent_sticky_mine",
    "ent_tank_mine",
    "ent_combine_tripmine",
}

local function GetMineOwner(mine)
    local owner = mine:GetOwner()
    if IsValid(owner) then return owner end
    owner = mine:GetNWEntity("HordeOwner")
    if IsValid(owner) then return owner end
    if IsValid(mine.Horde_Owner) then return mine.Horde_Owner end
end

local function GetOwnedMines(ply)
    local out = {}
    for _, class in ipairs(MINE_CLASSES) do
        for _, mine in ipairs(ents.FindByClass(class)) do
            if IsValid(mine) and GetMineOwner(mine) == ply then
                out[#out + 1] = mine
            end
        end
    end
    return out
end

local function GetLookedMines(ply, limit)
    local eyePos = ply:EyePos()
    local forward = ply:EyeAngles():Forward()
    local candidates = {}

    for _, mine in ipairs(GetOwnedMines(ply)) do
        local delta = mine:GetPos() - eyePos
        local dist = delta:Length()
        if dist > 1 then
            local dot = forward:Dot(delta / dist)
            if dot > 0.90 then
                candidates[#candidates + 1] = {
                    ent = mine,
                    score = dot - dist * 0.00001,
                }
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.score > b.score
    end)

    local result = {}
    for i = 1, math.min(limit or 6, #candidates) do
        result[#result + 1] = candidates[i].ent
    end
    return result
end

GADGET.Hooks.Horde_UseActiveGadget = function(ply)
    if CLIENT then return end
    if ply:Horde_GetGadget() ~= "gadget_mind_blower" then return end

    local mines = GetLookedMines(ply, 6)
    for _, mine in ipairs(mines) do
        if IsValid(mine) then
            mine._MindBlowerRemote = true
            mine:Explode()
            mine._MindBlowerRemote = nil
        end
    end
end

if CLIENT then
    local mat = Material("models/debug/debugwhite")

    hook.Add("PostDrawOpaqueRenderables", "MindBlower_DrawAllMines", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if ply:Horde_GetGadget() ~= "gadget_mind_blower" then return end

        local mines = GetOwnedMines(ply)
        if #mines == 0 then return end

        cam.IgnoreZ(true)
        render.SuppressEngineLighting(true)
        render.MaterialOverride(mat)

        for _, mine in ipairs(mines) do
            if IsValid(mine) then
                mine:DrawModel()
            end
        end

        render.MaterialOverride(nil)
        render.SuppressEngineLighting(false)
        cam.IgnoreZ(false)
    end)
end
