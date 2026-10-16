PERK.PrintName = "Hatcher Base"
PERK.Description = [[
The Hatcher class uses Antlions to provide unique support for the team.
COMPLEXITY: HIGH

{1} increased Antlion evolve rate. ({2} per level, up to {3}).
{1} increased Poison damage. ({2} per level, up to {3}).

Equipped with Pheropod. Upgradable through shop.
Upgrading Pheropod increases Antlion base health and damage.

LMB: Throw Pod
Throws a Pheropod at the target, forcing the Antlions to perform range attacks at the target.
Pods can also heal Antlion for 5% health.

RMB: Raise Antlion (40 Energy)
Creates an Antlion that follows you around. Heal Antlion to accelerate evolution.
HOLD RMB to force Antlions to your location.
Antlion gains new effects each stage:
- Stage I:
    - Bug Pulse: Every 5 seconds, generates a pulse that heals players nearby for 5% health.
- Stage II:
    - Increased health and damage.
    - Increased Aroma Pulse radius and reduce Bug Pulse cooldown.
    - 50% increased Poison damage resistance.
- Stage III:
    - Increased health, damage and attack speed.
    - Increased Aroma Pulse radius and reduce Bug Pulse cooldown.
    - Immune to Poison damage and Break.]]
PERK.Icon = "materials/subclasses/hatcher.png"
PERK.Params = {
    [1] = {percent = true, base = 0, level = 0.008, max = 0.2, classname = "Hatcher"},
    [2] = {value = 0.008, percent = true},
    [3] = {value = 0.2, percent = true},
}
PERK.Hooks = {}

PERK.Hooks.Horde_OnSetPerk = function(ply, perk)
    if SERVER and perk == "hatcher_base" then
        if ply:HasWeapon("horde_pheropod") == true then return end
        for _, wpn in pairs(ply:GetWeapons()) do
            if wpn:GetClass() == "weapon_horde_medkit" then continue end
            ply:StripWeapon(wpn:GetClass())
        end
        timer.Simple(0.1, function() ply:Give("horde_pheropod") end)
    end
end

PERK.Hooks.Horde_OnUnsetPerk = function(ply, perk)
    if SERVER and perk == "hatcher_base" then
    end
end

PERK.Hooks.Horde_PrecomputePerkLevelBonus = function (ply)
    if SERVER then
        ply:Horde_SetPerkLevelBonus("hatcher_base", math.min(0.2, 0.008 * ply:Horde_GetLevel("hatcher")))
    end
end

PERK.OwnerHooks.Horde_OnAntlionSelfEvolve = function(ply, npc, bonus)
    if not ply:Horde_GetPerk("hatcher_base") then return end
    bonus.increase = bonus.increase + ply:Horde_GetPerkLevelBonus("hatcher_base")
end

PERK.OwnerHooks.Horde_OnPlayerDamage = function (ply, npc, bonus, hitgroup, dmginfo)
    if not ply:Horde_GetPerk("hatcher_base") then return end
    if HORDE:IsPoisonDamage(dmginfo) then
        bonus.increase = bonus.increase + ply:Horde_GetPerkLevelBonus("hatcher_base")
    end
end

if not game.SinglePlayer() then
    local function nv_center(ent)
        return ent:LocalToWorld((ent:OBBCenter() * 1.5) - (ent:OBBMins() + ent:OBBMaxs()))
    end

    local function nv_color()
        return Color(120, 255, 120, 255)
    end

    local function nv_ents()
        local entities = {}
        for k, v in pairs(ents.FindByClass("npc_vj_horde_antlion")) do
            if v:IsValid() and HORDE:IsMinionOf(v, MySelf) then
                table.insert(entities, v)
            end
        end
        return entities
    end

    PERK.Hooks.HUDPaint = function()
        local ply = MySelf
        if not ply:IsValid() then return end
        if not ply:Horde_GetPerk("hatcher_base") then return end
        surface.SetDrawColor(Color(nv_color().r,nv_color().g,nv_color().b,math.random(255)))
        for id, ent in pairs(nv_ents()) do
            local pos = nv_center(ent):ToScreen()
            surface.DrawCircle(pos.x, pos.y, 30)
            draw.DrawText(ent:Health(), "Trebuchet24",
            pos.x - 15, pos.y - 15, nv_color(), TEXT_ALIGN_LEFT)
        end
    end
end

PERK.OwnerHooks.DoPlayerDeath = function (ply)
    if ply:Horde_GetPerk("hatcher_base") then
        for _, ent in ipairs(HORDE:GetPlayerMinions(ply, function(e) return e:GetClass() == "npc_vj_horde_antlion" end)) do
            ent:Remove()
        end
    end
end
