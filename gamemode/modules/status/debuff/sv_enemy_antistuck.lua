if CLIENT then return end

local CHECK_INTERVAL    = 2.0
local STUCK_TIME        = 20.0
local STUCK_DIST_SQR    = 48 * 48
local TELEPORT_COOLDOWN = 15.0
local FIGHT_DIST        = 600

local last_pos      = {}
local stuck_since   = {}
local last_teleport = {}

local function IsBossEnemy(ent)
    if ent.GetVar and ent:GetVar("is_boss") == true then return true end
    local props = ent.Horde_GetBossProperties and ent:Horde_GetBossProperties()
    return props and props.is_boss == true
end

local function IsFighting(ent)
    local my_pos = ent:GetPos()
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and my_pos:Distance(ply:GetPos()) <= FIGHT_DIST and ent:Visible(ply) then
            return true
        end
    end
    return false
end

local function IsAttacking(ent)
    if not IsValid(ent) then return false end

    local started = (VJ and VJ.ATTACK_STATE_STARTED) or 2
    if ent.AttackState and ent.AttackState >= started then return true end
    local fire = (VJ and VJ.WEP_ATTACK_STATE_FIRE) or 10
    if ent.WeaponAttackState and ent.WeaponAttackState >= fire then return true end

    local act = ent.GetActivity and ent:GetActivity()
    if act and act >= ACT_RANGE_ATTACK1 and act <= ACT_SPECIAL_ATTACK2 then return true end

    return false
end

local function ClosestPlayer(pos)
    local best, best_dist
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            local d = pos:Distance(ply:GetPos())
            if not best_dist or d < best_dist then best, best_dist = ply, d end
        end
    end
    return best, best_dist
end

local function TeleportToPlayer(ent, ply)
    local pos = HORDE:FindFreeSpawnPos(ent, { player = ply, closer_than_pos = ent:GetPos() })
    if not pos then return false end

    ent:EmitSound("ambient/machines/teleport4.wav", 75, 100)
    ent:SetPos(pos + Vector(0, 0, HORDE.enemy_spawn_z or 0))
    ent:SetVelocity(Vector(0, 0, 0))
    ent.Horde_Stunned = nil
    if ent.SetLastPosition then ent:SetLastPosition(ply:GetPos()) end
    if ent.SetTarget then ent:SetTarget(ply) end
    if ent.SetSchedule then ent:SetSchedule(SCHED_TARGET_CHASE) end
    return true
end

local function Forget(ent)
    last_pos[ent] = nil
    stuck_since[ent] = nil
    last_teleport[ent] = nil
end

timer.Create("Horde_EnemyAntiStuck", CHECK_INTERVAL, 0, function()
    local enemies = HORDE.ScanEnemies and HORDE:ScanEnemies() or {}
    local now = CurTime()

    for _, ent in ipairs(enemies) do
        if not IsValid(ent) or ent:Health() <= 0 or IsBossEnemy(ent) then
            Forget(ent)
        else
            local pos = ent:GetPos()
            local prev = last_pos[ent]
            last_pos[ent] = pos

            if prev and prev:DistToSqr(pos) > STUCK_DIST_SQR then
                stuck_since[ent] = nil
            else
                stuck_since[ent] = stuck_since[ent] or now
                if (now - stuck_since[ent]) >= STUCK_TIME then
                    if IsFighting(ent) then
                        stuck_since[ent] = nil
                    elseif not IsAttacking(ent)
                        and ((not last_teleport[ent]) or (now - last_teleport[ent]) >= TELEPORT_COOLDOWN) then
                        local ply = ClosestPlayer(pos)
                        if ply then
                            if TeleportToPlayer(ent, ply) then
                                last_teleport[ent] = now
                                stuck_since[ent] = nil
                            else
                                stuck_since[ent] = now - STUCK_TIME + 1
                            end
                        end
                    end
                end
            end
        end
    end
end)

hook.Add("EntityRemoved", "Horde_EnemyAntiStuckCleanup", function(ent)
    Forget(ent)
end)
