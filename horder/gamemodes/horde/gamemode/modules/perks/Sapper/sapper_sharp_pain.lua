PERK.PrintName = "Sharp Pain"
PERK.Description = [[Blast damage have a {1} chance to bleed enemies.]]
PERK.Icon = "materials/perks/sapper/sharp_pain.png"
PERK.Params = {
     [1] = {value = 0.5, percent = true}
}

PERK.Hooks = {}

PERK.OwnerHooks.Horde_OnPlayerDamage = function (ply, npc, bonus, hitgroup, dmginfo)
    if not ply:Horde_GetPerk("sapper_sharp_pain") then return end
    local ch=math.random(1,2)
    if HORDE:IsBlastDamage(dmginfo) and ch==1 then
        npc:Horde_AddDebuffBuildup(HORDE.Status_Bleeding,100,ply)
    end

end
