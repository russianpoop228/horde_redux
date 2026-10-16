if SERVER then
    util.AddNetworkString("Horde_SyncMetal")
end

local plymeta = FindMetaTable("Player")

HORDE.Metal_ChampionLevel      = 25
HORDE.Metal_BaseStart          = 750
HORDE.Metal_ChampionStart      = 1250
HORDE.Metal_RegenAmount        = 25
HORDE.Metal_BaseRegenTick      = 30
HORDE.Metal_ChampionRegenTick  = 25
HORDE.Metal_PerAmmobox         = 150
HORDE.Metal_PerKillPct         = 0.10
HORDE.Metal_PerKillCap         = 2500

local function LerpByLevel(level, from, to)
    local t = math.Clamp((level or 0) / HORDE.Metal_ChampionLevel, 0, 1)
    return from + (to - from) * t
end

function HORDE:Horde_GetMetalStartAmount(level)
    return math.floor(LerpByLevel(level, HORDE.Metal_BaseStart, HORDE.Metal_ChampionStart))
end

function HORDE:Horde_GetMetalRegenTick(level)
    return LerpByLevel(level, HORDE.Metal_BaseRegenTick, HORDE.Metal_ChampionRegenTick)
end

function plymeta:Horde_SetMetal(metal)
    self.Horde_Metal = math.max(0, math.floor(metal))
    if SERVER then
        net.Start("Horde_SyncMetal")
            net.WriteUInt(math.min(self.Horde_Metal, 999999), 32)
        net.Send(self)
    end
end

function plymeta:Horde_GetMetal()
    return self.Horde_Metal or 0
end

function plymeta:Horde_AddMetal(amount)
    if not amount or amount == 0 then return end
    self:Horde_SetMetal(self:Horde_GetMetal() + amount)
end

function plymeta:Horde_TrySpendMetal(cost)
    if not SERVER then return false end
    cost = cost or 0
    if cost <= 0 then return true end
    if self:Horde_GetMetal() < cost then return false end
    self:Horde_AddMetal(-cost)
    return true
end

function plymeta:Horde_SetMetalRegenTick(tick)
    local old_tick = self.Horde_MetalRegenTick
    self.Horde_MetalRegenTick = tick
    if not tick or tick <= 0 then
        self.Horde_MetalRegenLast = CurTime()
        return
    end
    if not old_tick or old_tick <= 0 or not self.Horde_MetalRegenLast then
        self.Horde_MetalRegenLast = CurTime() + tick
        return
    end
    local deadline = self.Horde_MetalRegenLast
    if deadline > CurTime() + tick then
        self.Horde_MetalRegenLast = CurTime() + tick
    end
end

function plymeta:Horde_GetMetalRegenTick()
    return self.Horde_MetalRegenTick
end

HORDE:AddPlayerTick("Horde_MetalRegen", function(ply)
    if not SERVER then return end
    if not ply:Horde_GetPerk("engineer_base") then return end
    local tick = ply:Horde_GetMetalRegenTick()
    if not tick or tick <= 0 then
        tick = HORDE:Horde_GetMetalRegenTick(ply:Horde_GetLevel(HORDE.Class_Engineer))
        ply:Horde_SetMetalRegenTick(tick)
    end
    if not ply.Horde_MetalRegenLast then
        ply.Horde_MetalRegenLast = CurTime() + tick
        return
    end
    if CurTime() < ply.Horde_MetalRegenLast then return end

    local amount = HORDE.Metal_RegenAmount or 25
    local metal = ply:Horde_GetMetal() or 0
    local pct = 0
    if ply:Horde_GetPerk("engineer_tinkerer") then
        pct = pct + 0.01
    end
    if ply:Horde_GetPerk("engineer_symbiosis") then
        pct = pct + 0.04
    end
    if pct > 0 then
        amount = amount + math.max(0, math.floor(metal * pct))
    end
    ply:Horde_AddMetal(amount)
    ply.Horde_MetalRegenLast = CurTime() + tick
end)

if CLIENT then
    net.Receive("Horde_SyncMetal", function()
        MySelf:Horde_SetMetal(net.ReadUInt(32))
    end)
end
