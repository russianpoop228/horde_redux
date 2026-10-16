PERK.PrintName = "Evolution"
PERK.Description = [[Your houndeyes deal {1} more damage.
Your houndeyes health is increased by {2}.]]
PERK.Icon = "materials/perks/sapper/evolution.png"
PERK.Params = {
    [1] = {value = 0.20, percent = true},
    [2] = {value = 0.10, percent = true},
}

PERK.Hooks = {}

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if not SERVER or perk ~= "sapper_evolution" then return end
    for _, v in ipairs(ents.FindByClass("npc_vj_horde_houndeye*")) do
        if IsValid(v) and v:GetOwner() == ply and not v.Horde_PocketHoundeye then
            v:Remove()
        end
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if not SERVER or perk ~= "sapper_evolution" then return end
    for _, v in ipairs(ents.FindByClass("npc_vj_horde_houndeye*")) do
        if IsValid(v) and v:GetOwner() == ply and not v.Horde_PocketHoundeye then
            v:Remove()
        end
    end
end
