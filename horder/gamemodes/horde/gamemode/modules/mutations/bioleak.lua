MUTATION.PrintName   = "Bioleak"
MUTATION.Description = "Deals 35% more damage. Always drops loot or spawns a grenade on death. Rare chance for a Skull Token!"
MUTATION.Wave        = 2

MUTATION.Hooks = {}

MUTATION.Hooks.Horde_OnSetMutation = function(ent, mutation)
    if mutation ~= "bioleak" then return end
    if not SERVER then return end

    ent:SetColor(Color(100, 255, 100))
    ent:SetRenderMode(RENDERMODE_TRANSALPHA)
end

MUTATION.Hooks.Horde_OnUnsetMutation = function(ent, mutation)
    if mutation ~= "bioleak" then return end
    if not SERVER then return end
    if not IsValid(ent) then return end

    ent:SetColor(Color(255, 255, 255))
    ent:SetRenderMode(RENDERMODE_NORMAL)
end

MUTATION.Hooks.EntityTakeDamage = function(target, dmg)
    if not SERVER then return end

    local attacker = dmg:GetAttacker()
    if not IsValid(attacker) then return end
    if not attacker:IsNPC() then return end
    if not attacker:Horde_HasMutation("bioleak") then return end

    dmg:ScaleDamage(1.35)
end

local DROP_TABLE = {
    { threshold = 0.01,  type = "skull_token"          },
    { threshold = 0.06,  type = "item_healthkit"        },
    { threshold = 0.28,  type = "item_healthvial"       },
    { threshold = 0.50,  type = "item_battery"          },
    { threshold = 0.72,  type = "horde_ammobox"         },
    { threshold = 0.85,  type = "npc_headcrab_black"    },
    { threshold = 1.00,  type = "grenade_helicopter"    },
}

local function GiveSkullToken(killPos, attacker)
    local target = (IsValid(attacker) and attacker:IsPlayer()) and attacker or nil

    if not target then
        local minDistSq = math.huge
        for _, ply in ipairs(player.GetAll()) do
            local d = ply:GetPos():DistToSqr(killPos)
            if d < minDistSq then
                minDistSq = d
                target = ply
            end
        end
    end

    if not IsValid(target) then return end

    target:Horde_AddSkullTokens(1)
    target:Horde_SyncEconomy()
    sound.Play("items/battery_pickup.wav", killPos)
    HORDE:SendNotification("Skull token found!", 0, target)
end

local PICKUP_LIFETIME = 30
local PICKUPS = {
    item_healthkit  = true,
    item_healthvial = true,
    item_battery    = true,
    horde_ammobox   = true,
}

local function SpawnEntity(class, spawnPos)
    local ent = ents.Create(class)
    if not IsValid(ent) then return end
    ent:SetPos(spawnPos)
    ent:Spawn()
    ent:Activate()
    if PICKUPS[class] then
        timer.Simple(PICKUP_LIFETIME, function()
            if IsValid(ent) and not IsValid(ent:GetOwner()) then ent:Remove() end
        end)
    end
end

MUTATION.Hooks.Horde_OnEnemyKilled = function(ent, attacker, inflictor)
    if not SERVER then return end
    if not IsValid(ent) then return end
    if not ent:Horde_HasMutation("bioleak") then return end

    local rand     = math.random()
    local spawnPos = ent:GetPos() + Vector(0, 0, 20)

    for _, entry in ipairs(DROP_TABLE) do
        if rand <= entry.threshold then
            if entry.type == "skull_token" then
                GiveSkullToken(ent:GetPos(), attacker)
            else
                SpawnEntity(entry.type, spawnPos)
            end
            return
        end
    end
end
