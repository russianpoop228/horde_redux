if SERVER then
util.AddNetworkString("Horde_SyncExp")
end

HORDE.Rank_Novice = "Novice"
HORDE.Rank_Amateur = "Amateur"
HORDE.Rank_Skilled = "Skilled"
HORDE.Rank_Professional = "Professional"
HORDE.Rank_Expert = "Expert"
HORDE.Rank_Champion = "Champion"
HORDE.Rank_Master = "Master"
HORDE.player_ranks = {}
HORDE.player_exps = {}
HORDE.max_level = 100

HORDE.Rank_Colors = {
    [HORDE.Rank_Novice] = color_white,
    [HORDE.Rank_Amateur] = Color(50,205,50),
    [HORDE.Rank_Skilled] = Color(135,206,235),
    [HORDE.Rank_Professional] = Color(220,0,220),
    [HORDE.Rank_Expert] = Color(255,69,0),
    [HORDE.Rank_Champion] = Color(255,215,0),
    [HORDE.Rank_Master] = HORDE.color_crimson
}

function HORDE:ScrubSteamID(ply)
	return ply:SteamID():gsub(":", "_")
end

local plymeta = FindMetaTable("Player")

function plymeta:Horde_GetExp(class_name)
    if not self.Horde_Exps then self.Horde_Exps = {} end
    if SERVER then
    end
    return self.Horde_Exps[class_name] or 0
end

function plymeta:Horde_SetExp(class_name, exp)
    if SERVER then
    end
    if not self:IsValid() then return end
    if not self.Horde_Exps then self.Horde_Exps = {} end
    if not class_name then return end
    local changed = self.Horde_Exps[class_name] ~= exp
    self.Horde_Exps[class_name] = exp
    local level = self:Horde_GetLevel(class_name)
    if exp >= HORDE:GetExpToNextLevel(level + 1) then
        self:Horde_SetLevel(class_name, level + 1)
        self.Horde_Exps[class_name] = 0
        changed = true
    end
    if SERVER and changed and self.Horde_Rank_Loaded then
        self.Horde_Rank_Dirty = self.Horde_Rank_Dirty or {}
        self.Horde_Rank_Dirty[class_name] = true
    end
end

function plymeta:Horde_AddExp(class_name, amount)
    if not class_name or not amount or amount <= 0 then return end
    local mult = HORDE.GetWaveExpMultiplier and HORDE:GetWaveExpMultiplier() or 1
    if mult <= 1 then
        self:Horde_SetExp(class_name, self:Horde_GetExp(class_name) + amount)
        return
    end
    if not self.Horde_Exp_Frac then self.Horde_Exp_Frac = {} end
    local pool = (self.Horde_Exp_Frac[class_name] or 0) + amount * mult
    local whole = math.floor(pool)
    self.Horde_Exp_Frac[class_name] = pool - whole
    if whole > 0 then
        self:Horde_SetExp(class_name, self:Horde_GetExp(class_name) + whole)
    end
end

function plymeta:Horde_GetLevel(class_name)
    if not self.Horde_Levels then self.Horde_Levels = {} end
    return self.Horde_Levels[class_name] or 0
end

function plymeta:Horde_SetLevel(class_name, level)
    if not self:IsValid() then return end
    if not self.Horde_Levels then self.Horde_Levels = {} end
    if not class_name then return end
    local changed = self.Horde_Levels[class_name] ~= level
    self.Horde_Levels[class_name] = level
    local rank, rank_level = HORDE:LevelToRank(level)
    self:Horde_SetRankLevel(class_name, rank_level)
    self:Horde_SetRank(class_name, rank)

    if SERVER then
        hook.Run("Horde_PrecomputePerkLevelBonus", self)
        if changed and self.Horde_Rank_Loaded then
            self.Horde_Rank_Dirty = self.Horde_Rank_Dirty or {}
            self.Horde_Rank_Dirty[class_name] = true
        end
    end
end

function plymeta:Horde_SetPerkLevelBonus(perk, bonus)
    if not self.Horde_Perk_Level_Bonus then self.Horde_Perk_Level_Bonus = {} end
    self.Horde_Perk_Level_Bonus[perk] = bonus
end

function plymeta:Horde_GetPerkLevelBonus(perk)
    if not self.Horde_Perk_Level_Bonus then return 0 end
    return self.Horde_Perk_Level_Bonus[perk] or 0
end

function plymeta:Horde_GetRankLevel(class_name)
    if not self.Horde_RankLevels then self.Horde_RankLevels = {} end
    return self.Horde_RankLevels[class_name] or 0
end

function plymeta:Horde_SetRankLevel(class_name, level)
    if not self:IsValid() then return end
    if not self.Horde_RankLevels then self.Horde_RankLevels = {} end
    self.Horde_RankLevels[class_name] = level
end

function plymeta:Horde_GetRank(class_name)
    if not self.Horde_Ranks then self.Horde_Ranks = {} end
    return self.Horde_Ranks[class_name] or HORDE.Rank_Novice
end

function plymeta:Horde_SetRank(class_name, rank)
    if not self:IsValid() then return end
    if not self.Horde_Ranks then self.Horde_Ranks = {} end
    self.Horde_Ranks[class_name] = rank
end

function plymeta:Horde_SyncExp()
    local payload = {}
    for subclass_name in pairs(HORDE.subclasses or {}) do
        payload[subclass_name] = {
            exp = self:Horde_GetExp(subclass_name),
            level = self:Horde_GetLevel(subclass_name),
        }
    end

    net.Start("Horde_SyncExp")
        net.WriteEntity(self)
        net.WriteTable(payload)
    net.Broadcast()
end

function HORDE:GetExpToNextLevel(level)
    return math.floor(50 + 2 * math.pow(1.1, level) + level * 25 + 100 * math.floor(level / 5))
end

local RANK_THRESHOLDS = {
    {  5, HORDE.Rank_Amateur       },
    { 10, HORDE.Rank_Skilled       },
    { 15, HORDE.Rank_Professional  },
    { 20, HORDE.Rank_Expert        },
    { 25, HORDE.Rank_Champion      },
}

function HORDE:LevelToRank(level)
    if level >= 30 then
        return HORDE.Rank_Master, level - 30
    end

    local rank = HORDE.Rank_Novice
    for _, entry in ipairs(RANK_THRESHOLDS) do
        if level < entry[1] then break end
        rank = entry[2]
    end

    return rank, level % 5
end

if CLIENT then
net.Receive("Horde_SyncExp", function(length)
    local ply = net.ReadEntity()
    local payload = net.ReadTable()
    if not ply:IsValid() then return end
    for class_name, data in pairs(payload or {}) do
        if isstring(class_name) and istable(data) then
            ply:Horde_SetLevel(class_name, tonumber(data.level) or 0)
            ply:Horde_SetExp(class_name, tonumber(data.exp) or 0)
        end
    end
end)

net.Receive("Horde_SyncPrestige", function()
    local ply = net.ReadEntity()
    local tbl = net.ReadTable()
    if not IsValid(ply) then return end
    ply.Horde_Prestige = tbl or {}
end)
end

if CLIENT then
    function plymeta:Horde_GetPrestige(subclass_key)
        if not self.Horde_Prestige then self.Horde_Prestige = {} end
        return self.Horde_Prestige[subclass_key] or 0
    end
end
