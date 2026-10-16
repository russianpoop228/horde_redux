MUTATION.PrintName   = "Healer"
MUTATION.Description = "Supports the horde.\nHeals nearby allies for 40–80 HP every 15 seconds."
MUTATION.Wave        = 6

MUTATION.Hooks = {}

local HEAL_RADIUS   = 300
local HEAL_INTERVAL = 15
local NW_KEY        = "Horde_IsHealer"

if CLIENT then
    local trackedHealers = {}

    hook.Add("PreDrawHalos", "Horde_Mutation_Healer_Halo", function()
        if next(trackedHealers) == nil then return end

        for ent in pairs(trackedHealers) do
            if not IsValid(ent) or not ent:GetNWBool(NW_KEY, false) then
                trackedHealers[ent] = nil
            end
        end

        local entList = table.GetKeys(trackedHealers)
        if #entList > 0 then
            halo.Add(entList, Color(0, 255, 0), 2, 2, 1, true, false)
        end
    end)

    hook.Add("OnEntityCreated", "Horde_Mutation_Healer_Tracker", function(ent)
        timer.Simple(0.5, function()
            if IsValid(ent) and ent:GetNWBool(NW_KEY, false) then
                trackedHealers[ent] = true
            end
        end)
    end)

    timer.Create("Horde_Healer_Halo_Rescan", 3, 0, function()
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() and ent:GetNWBool(NW_KEY, false) then
                trackedHealers[ent] = true
            end
        end
    end)
end

local function SpawnHealSmoke(pos)
    local smoke = ents.Create("env_smoketrail")
    if not IsValid(smoke) then return end

    smoke:SetPos(pos)
    smoke:SetKeyValue("startsize",   "15")
    smoke:SetKeyValue("endsize",     "35")
    smoke:SetKeyValue("spawnradius", "10")
    smoke:SetKeyValue("startcolor",  "0 255 0")
    smoke:SetKeyValue("endcolor",    "0 100 0")
    smoke:SetKeyValue("opacity",     "0.5")
    smoke:SetKeyValue("spawnrate",   "15")
    smoke:SetKeyValue("lifetime",    "0.5")
    smoke:Spawn()
    smoke:Activate()

    smoke:Fire("TurnOn",  "", 0)
    smoke:Fire("TurnOff", "", 1)
    smoke:Fire("Kill",    "", 1.2)
end

MUTATION.Hooks.Horde_OnSetMutation = function(ent, mutation)
    if mutation ~= "healer" then return end

    ent:SetNWBool(NW_KEY, true)

    if not SERVER then return end
    if not IsValid(ent) then return end

    local timerName = "Horde_Healer_Pulse_" .. ent:EntIndex()

    timer.Create(timerName, HEAL_INTERVAL, 0, function()
        if not IsValid(ent) or ent:Health() <= 0 then
            timer.Remove(timerName)
            return
        end

        local healedSomeone = false

        for _, ally in ipairs(ents.FindInSphere(ent:GetPos(), HEAL_RADIUS)) do
            if not IsValid(ally) then continue end
            if not ally:IsNPC() then continue end
            if ally == ent then continue end
            if ally:Health() >= ally:GetMaxHealth() then continue end
            if ally:Disposition(ent) ~= D_LI then continue end

            local healAmount = math.random(40, 80)
            ally:SetHealth(math.min(ally:GetMaxHealth(), ally:Health() + healAmount))
            SpawnHealSmoke(ally:GetPos())
            healedSomeone = true
        end

        if healedSomeone then
            ent:EmitSound("items/suitchargeok1.wav", 80, 100)
        end
    end)
end

MUTATION.Hooks.Horde_OnUnsetMutation = function(ent, mutation)
    if mutation ~= "healer" then return end

    ent:SetNWBool(NW_KEY, false)

    if SERVER then
        timer.Remove("Horde_Healer_Pulse_" .. ent:EntIndex())
    end
end

MUTATION.Hooks.Horde_OnEnemyKilled = function(ent, attacker, inflictor)
    if not SERVER then return end
    if not IsValid(ent) then return end
    if not ent:Horde_HasMutation("healer") then return end

    timer.Remove("Horde_Healer_Pulse_" .. ent:EntIndex())
end
