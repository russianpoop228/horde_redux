MUTATION.PrintName   = "Light"
MUTATION.Description = "Permanently surrounded by a blinding light cloud.\nBlinds nearby players. Does not apply to bosses or elites."
MUTATION.Wave        = 7

MUTATION.Hooks = {}

local BLIND_RADIUS   = 175
local TICK_INTERVAL  = 0.5
local BUILDUP_AMOUNT = 10

MUTATION.Hooks.Horde_OnSetMutation = function(ent, mutation)
    if mutation ~= "light" then return end
    if not SERVER then return end
    if not IsValid(ent) then return end
    if ent:GetVar("is_boss") then return end
    if ent:Horde_IsElite() then return end

    ent:SetColor(Color(0, 0, 0, 50))
    ent:SetRenderMode(RENDERMODE_TRANSALPHA)

    ent.Horde_Mutation          = ent.Horde_Mutation or {}
    ent.Horde_Mutation["light"] = true

    local id             = ent:EntIndex()
    local deafTimer      = "Horde_Mutation_Light_Blind_"  .. id
    local effectTimer    = "Horde_Mutation_Light_Effect_" .. id

    timer.Remove(deafTimer)
    timer.Remove(effectTimer)

    timer.Create(deafTimer, TICK_INTERVAL, 0, function()
        if not IsValid(ent) or not (ent.Horde_Mutation and ent.Horde_Mutation["light"]) then
            timer.Remove(deafTimer)
            return
        end

        if not HORDE or not HORDE.Status_Flash then return end

        for _, e in ipairs(ents.FindInSphere(ent:GetPos(), BLIND_RADIUS)) do
            if IsValid(e) and HORDE:IsPlayerOrMinion(e) and not HORDE:IsPlayerSpectator(e) then
                e:Horde_AddDebuffBuildup(HORDE.Status_Flash, BUILDUP_AMOUNT, ent)
            end
        end
    end)

    timer.Create(effectTimer, TICK_INTERVAL, 0, function()
        if not IsValid(ent) or not (ent.Horde_Mutation and ent.Horde_Mutation["light"]) then
            timer.Remove(effectTimer)
            return
        end

        local e = EffectData()
        e:SetOrigin(ent:GetPos())
        util.Effect("light_effect", e, true, true)
    end)
end

MUTATION.Hooks.Horde_OnUnsetMutation = function(ent, mutation)
    if mutation ~= "light" then return end
    if not SERVER then return end
    if not IsValid(ent) then return end

    ent:SetColor(Color(255, 255, 255))
    ent:SetRenderMode(RENDERMODE_NORMAL)

    if ent.Horde_Mutation then
        ent.Horde_Mutation["light"] = nil
    end

    local id = ent:EntIndex()
    timer.Remove("Horde_Mutation_Light_Blind_"  .. id)
    timer.Remove("Horde_Mutation_Light_Effect_" .. id)
end
