local plymeta = FindMetaTable("Player")
local entmeta = FindMetaTable("Entity")

function plymeta:Horde_SetApplyIgniteDuration(duration)
    self.Horde_ApplyIgniteDuration = duration
end

function plymeta:Horde_GetApplyIgniteDuration()
    return (self.Horde_ApplyIgniteDuration or 4) * HORDE:GetPerkMultiplier(self, "ApplyIgniteDurationMult")
end

function plymeta:Horde_SetApplyIgniteChance(chance)
    self.Horde_ApplyIgniteChance = chance
end

function plymeta:Horde_GetApplyIgniteChance()
    return (self.Horde_ApplyIgniteChance or 0) + HORDE:GetPerkBonus(self, "ApplyIgniteChanceBonus")
end

local function IsBadNumber(n)
    return n ~= n or n == math.huge or n == -math.huge
end

function entmeta:Horde_SetMostRecentFireAttacker(attacker, dmginfo)
	self.Horde_MostRecentFireAttacker = attacker
    local d = dmginfo:GetDamage()
    if IsBadNumber(d) then return end
    if IsBadNumber(self.Horde_IgniteDamageTaken) then self.Horde_IgniteDamageTaken = nil end
    if self.Horde_IgniteDamageTaken then
        self.Horde_IgniteDamageTaken = math.max(self.Horde_IgniteDamageTaken, d * 0.025)
    else
        self.Horde_IgniteDamageTaken = math.max(1, d * 0.03)
    end
end

function entmeta:Horde_SetIgniteDamage(dmg)
    if IsBadNumber(dmg) then dmg = nil end
    self.Horde_IgniteDamageTaken = dmg
end

function entmeta:Horde_GetMostRecentFireAttacker()
	return self.Horde_MostRecentFireAttacker
end

function entmeta:Horde_GetIgniteDamageTaken()
    local d = self.Horde_IgniteDamageTaken
    if not d or d ~= d or d == math.huge or d == -math.huge then return 1 end
    return d
end

HORDE.Ignite_PlayerDmgPct = 0.01

function entmeta:Horde_AddIgniteEffect(duration, inflictor)
    if not self:IsPlayer() then return end
    self:Ignite(duration)
    timer.Remove("Horde_RemoveIgnite" .. self:SteamID())
    timer.Create("Horde_RemoveIgnite" .. self:SteamID(), duration, 1, function ()
        self:Horde_RemoveIgnite()
    end)

    local id = "Horde_IgniteEffect" .. self:SteamID()
    local attacker = IsValid(inflictor) and inflictor or Entity(0)
    timer.Remove(id)
    timer.Create(id, 0.5, 0, function ()
        if not IsValid(self) or not self:Alive() or HORDE:IsPlayerSpectator(self)
            or not self.Horde_Debuff_Active or not self.Horde_Debuff_Active[HORDE.Status_Ignite] then
            timer.Remove(id)
            return
        end
        local dmg = DamageInfo()
        dmg:SetAttacker(attacker)
        dmg:SetInflictor(attacker)
        dmg:SetDamageType(DMG_BURN)
        dmg:SetDamage(math.max(1, math.floor(self:GetMaxHealth() * HORDE.Ignite_PlayerDmgPct)))
        dmg:SetDamagePosition(self:GetPos())
        self:TakeDamageInfo(dmg)
    end)
end

function entmeta:Horde_RemoveIgnite()
    if not self:IsValid() then return end
    if self:IsPlayer() then
        self:Extinguish()
    end
end
