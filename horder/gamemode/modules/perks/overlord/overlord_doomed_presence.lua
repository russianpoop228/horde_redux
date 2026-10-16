PERK.PrintName = "Doomed Presence"
PERK.Description = [[Fear duration is infinite.
Enemies you hit gain {1} Fear stack.]]
PERK.Icon = "materials/perks/overlord/doomed_prescence.png"
PERK.Params = {
    [1] = { value = 1 },
}
PERK.Hooks = {}

PERK.FearStackBonus = 1

PERK.OwnerHooks.Horde_OnPlayerDamage = function(ply, npc, bonus, hitgroup, dmginfo)
    if not ply:Horde_GetPerk("overlord_doomed_presence") then return end
    npc:Horde_AddFearStack(ply)
end
