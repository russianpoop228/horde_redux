INFUSION = {}

INFUSION.Key         = "Vampiric"
INFUSION.Name        = "Vampiric"
INFUSION.Icon        = "infusion/siphoning.png"
INFUSION.Color       = Color(180, 20, 60)
INFUSION.Description = [[
Heal for 5% of damage dealt.

15% less weapon damage.
]]

INFUSION.OnDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    bonus.more = bonus.more * 0.85
    if SERVER and ply:Alive() then
        local heal = math.max(1, math.floor(dmginfo:GetDamage() * 0.05))
        HORDE:OnPlayerHeal(ply, HealInfo:New({ amount = heal, healer = ply }))
    end
end
