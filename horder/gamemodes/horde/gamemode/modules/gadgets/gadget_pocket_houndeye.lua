GADGET.PrintName = "Pocket Houndeye"
GADGET.Description = "Deploys a small green Houndeye each use (up to 3 active at once).\nSapper perks do not apply to these Houndeyes."
GADGET.Icon = "items/gadgets/pocket_houndeye.png"
GADGET.Cooldown = 15
GADGET.Active = true
GADGET.Params = {}
GADGET.Hooks = {}

local HOUNDEYE_CLASS    = "npc_vj_horde_houndeye"
local MAX_HOUNDEYES     = 3
local HOUNDEYE_COLOR    = Color(110, 255, 110, 255)
local HOUNDEYE_MATERIAL = "horde/pocket_houndeye"

local HOUNDEYE_MINS = Vector(-16, -16, 0)
local HOUNDEYE_MAXS = Vector(16, 16, 35)

local SPAWN_OFFSETS = {
    Vector(80, 0, 0),
    Vector(45, 70, 0),
    Vector(45, -70, 0),
    Vector(-40, 80, 0),
    Vector(-40, -80, 0),
    Vector(100, 45, 0),
    Vector(100, -45, 0),
}

local function ResolvePocketSpawnPos(ply, candidate)
    local hull = util.TraceHull({
        start = candidate + Vector(0, 0, 40),
        endpos = candidate + Vector(0, 0, 40),
        mins = HOUNDEYE_MINS,
        maxs = HOUNDEYE_MAXS,
        filter = ply,
        mask = MASK_SOLID_BRUSHONLY,
    })
    if hull.StartSolid or hull.AllSolid then return nil end

    local ground = util.TraceLine({
        start = candidate + Vector(0, 0, 40),
        endpos = candidate - Vector(0, 0, 256),
        filter = ply,
        mask = MASK_SOLID_BRUSHONLY,
    })
    return ground.Hit and (ground.HitPos + Vector(0, 0, 4)) or candidate
end

local function FindPocketSpawnPos(ply)
    local origin = ply:GetPos()
    local forward, right = ply:GetForward(), ply:GetRight()

    for _, offset in ipairs(SPAWN_OFFSETS) do
        local candidate = origin + forward * offset.x + right * offset.y
        local pos = ResolvePocketSpawnPos(ply, candidate)
        if pos then return pos end
    end

    return origin + forward * 50 + Vector(0, 0, 8)
end

local function CountPocketHoundeyes(ply)
    local count = 0
    for _, ent in ipairs(ents.FindByClass(HOUNDEYE_CLASS)) do
        if IsValid(ent) and ent.Horde_PocketHoundeye == ply then
            count = count + 1
        end
    end
    return count
end

GADGET.Hooks.Horde_UseActiveGadget = function(ply)
    if CLIENT then return end
    if ply:Horde_GetGadget() ~= "gadget_pocket_houndeye" then return end

    if CountPocketHoundeyes(ply) >= MAX_HOUNDEYES then return end

    local ent = ents.Create(HOUNDEYE_CLASS)
    if not IsValid(ent) then return end

    ent.Horde_PocketHoundeye = ply

    local spawnPos = FindPocketSpawnPos(ply)

    ent:SetPos(spawnPos)
    ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    if HORDE and HORDE.AssignMinionOwner then
        HORDE:AssignMinionOwner(ent, ply)
    else
        ent:SetNWEntity("HordeOwner", ply)
        ent:SetOwner(ply)
        ent.Horde_Owner = ply
    end

    ent:Spawn()
    ent:Activate()

    ent:SetModelScale(0.5, 0)

    ent:SetMaterial(HOUNDEYE_MATERIAL)
    ent:SetColor(HOUNDEYE_COLOR)
    ent:SetRenderMode(RENDERMODE_TRANSCOLOR)

    if HORDE and HORDE.RegisterMinion then
        HORDE:RegisterMinion(ent, ply, {
            count = true,
            drop_entity = true,
            no_collision = true,
            relationship = true,
        })
    else
        ent:AddRelationship("player D_LI 99")
        ent.VJ_NPC_Class = {"CLASS_PLAYER_ALLY", "CLASS_COMBINE"}
        ply:Horde_AddDropEntity(ent:GetClass(), ent)
    end

    ent:SetCollisionGroup(COLLISION_GROUP_WORLD)

    local npc_info = list.Get("NPC") and list.Get("NPC")[ent:GetClass()]
    if npc_info and npc_info.Weapons then
        local wpns = npc_info.Weapons
        if #wpns > 0 then
            ent:Give(wpns[math.random(#wpns)])
        end
    end
end
