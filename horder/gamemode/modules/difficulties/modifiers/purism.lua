local DIFF = "PURISM"
local function V(key, default)
    return HORDE.DiffCfg(DIFF, key, default)
end

HORDE:RegisterDifficulty({
    Name    = DIFF,
    Index   = 8,
    IsModifier = true,

    IsPurism   = true,
    MaxWaves   = 10,

})
