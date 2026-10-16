if CLIENT then return end

local SKULL_REWARD      = 20
local SKULL_REWARD_STEP = 20

function HORDE:GetHundredWaveSkullReward(wave)
    local w = tonumber(wave) or 0
    if w <= 0 or w % SKULL_REWARD_STEP ~= 0 then return 0 end
    return SKULL_REWARD
end
