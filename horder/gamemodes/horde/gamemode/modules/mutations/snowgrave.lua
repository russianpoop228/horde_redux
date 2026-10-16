MUTATION.PrintName   = "Snowgrave"
MUTATION.Description = "Frozen with power. Periodically spits freezing projectiles that deal 20% of max HP and apply Freeze."
MUTATION.Wave        = 8

MUTATION.Hooks = {}

local PROJ_CLASS     = "obj_horde_snowgrave_proj"
local INTERVAL_MIN   = 2
local INTERVAL_MAX   = 10
local SHOOT_RANGE_SQ = 2500000
local FACING_DOT_MIN = 0.6
local PROJ_SPEED     = 1100
local PROJ_ARC_MAX   = 250

local function GetMuzzlePos(ent)
    local attachId = ent:LookupAttachment("mouth")
    if attachId and attachId > 0 then
        return ent:GetAttachment(attachId).Pos
    end

    local headId = ent:LookupAttachment("anim_attachment_head")
    if headId and headId > 0 then
        return ent:GetAttachment(headId).Pos
    end

    return ent:GetPos() + Vector(0, 0, 50)
end

local function FindTarget(ent)
    local enemy = ent:GetEnemy()
    if IsValid(enemy) and enemy:IsPlayer() and enemy:Alive() then
        if ent:GetPos():DistToSqr(enemy:GetPos()) <= SHOOT_RANGE_SQ then
            return enemy
        end
    end

    local best, bestDistSq = nil, SHOOT_RANGE_SQ
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply:Alive() then continue end
        local d = ent:GetPos():DistToSqr(ply:GetPos())
        if d < bestDistSq then
            bestDistSq = d
            best = ply
        end
    end
    return best
end

MUTATION.Hooks.Horde_OnSetMutation = function(ent, mutation)
    if mutation ~= "snowgrave" then return end
    if not SERVER then return end
    if not IsValid(ent) then return end

    ent.Snowgrave_OriginalMaterial = ent:GetMaterial()
    ent.Snowgrave_OriginalColor    = ent:GetColor()

    ent:SetRenderMode(RENDERMODE_TRANSALPHA)
    ent:SetColor(Color(0, 255, 255, 180))
    ent:SetMaterial("models/debug/debugwhite")

    local id        = ent:EntIndex()
    local timerName = "Horde_Snowgrave_Shoot_" .. id

    timer.Create(timerName, math.random(INTERVAL_MIN, INTERVAL_MAX), 0, function()
        if not IsValid(ent) or ent:Health() <= 0 then
            timer.Remove(timerName)
            return
        end

        local target = FindTarget(ent)
        if not IsValid(target) then
            timer.Adjust(timerName, math.random(INTERVAL_MIN, INTERVAL_MAX))
            return
        end

        local dirToTarget = (target:GetPos() - ent:GetPos()):GetNormalized()
        if ent:GetForward():Dot(dirToTarget) < FACING_DOT_MIN then
            timer.Adjust(timerName, math.random(INTERVAL_MIN, INTERVAL_MAX))
            return
        end

        if not ent:Visible(target) then
            timer.Adjust(timerName, math.random(INTERVAL_MIN, INTERVAL_MAX))
            return
        end

        local proj = ents.Create(PROJ_CLASS)
        if IsValid(proj) then
            local spawnPos  = GetMuzzlePos(ent)
            local targetPos = target:GetPos() + target:OBBCenter()
            local dist      = spawnPos:Distance(targetPos)

            proj:SetPos(spawnPos)
            proj:SetOwner(ent)
            proj:SetPhysicsAttacker(ent)
            proj:Spawn()
            proj:Activate()

            local phys = proj:GetPhysicsObject()
            if IsValid(phys) then
                local velocity = (targetPos - spawnPos):GetNormalized() * PROJ_SPEED
                velocity.z = velocity.z + math.min(dist * 0.15, PROJ_ARC_MAX)
                phys:Wake()
                phys:SetVelocity(velocity)
            end

            ent:EmitSound("weapons/slam/throw.wav", 80, 100)
        end

        timer.Adjust(timerName, math.random(INTERVAL_MIN, INTERVAL_MAX))
    end)
end

MUTATION.Hooks.Horde_OnUnsetMutation = function(ent, mutation)
    if mutation ~= "snowgrave" then return end
    if not SERVER then return end

    timer.Remove("Horde_Snowgrave_Shoot_" .. ent:EntIndex())

    if IsValid(ent) then
        ent:SetRenderMode(RENDERMODE_NORMAL)
        ent:SetColor(ent.Snowgrave_OriginalColor or Color(255, 255, 255))
        ent:SetMaterial(ent.Snowgrave_OriginalMaterial or "")
        ent.Snowgrave_OriginalColor    = nil
        ent.Snowgrave_OriginalMaterial = nil
    end
end

MUTATION.Hooks.Horde_OnEnemyKilled = function(ent, attacker, inflictor)
    if not SERVER then return end
    if not IsValid(ent) then return end
    if not ent:Horde_HasMutation("snowgrave") then return end

    timer.Remove("Horde_Snowgrave_Shoot_" .. ent:EntIndex())
end
