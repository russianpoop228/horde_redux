if not CLIENT then return end

local cv_sway = CreateClientConVar("horde_view_sway", "0", true, false, "Camera roll/bob while moving (0 = off).", 0, 1)

local SPEED_SMOOTH = 0.9
local STRAFE_ROLL  = 0.01
local STEP_ROLL    = 0.001
local STEP_PITCH   = 0.001

local vel_smooth = 1
local walk_timer = 0.5

hook.Add("CalcView", "Horde_StrafeCam", function(ply, origin, angles, fov)
    if not cv_sway:GetBool() then return end
    if not IsValid(ply) or ply:GetMoveType() ~= MOVETYPE_WALK then return end

    local vel = ply:GetVelocity()
    vel_smooth = vel_smooth * SPEED_SMOOTH + vel:Length() * (1 - SPEED_SMOOTH)
    walk_timer = walk_timer + vel_smooth * FrameTime() * 0.05

    angles.roll = angles.roll + ply:EyeAngles():Right():Dot(vel) * STRAFE_ROLL

    if ply:GetGroundEntity() ~= NULL then
        angles.roll  = angles.roll  + math.sin(walk_timer) * vel_smooth * STEP_ROLL
        angles.pitch = angles.pitch + math.sin(walk_timer * 0.5) * vel_smooth * STEP_PITCH
    end
end)
