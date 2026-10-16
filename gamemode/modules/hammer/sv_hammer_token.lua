if not SERVER then return end
if not HORDE then return end

HORDE.MapTokenEntities = HORDE.MapTokenEntities or {
    [HORDE.HammerToken.MONEY] = "horde_money",
    [HORDE.HammerToken.SKULL] = "horde_skull_token",
    [HORDE.HammerToken.METAL] = "horde_metal",
}

HORDE.MapTokenDefaultAmount = HORDE.MapTokenDefaultAmount or {
    [HORDE.HammerToken.MONEY] = 50,
    [HORDE.HammerToken.SKULL] = 1,
    [HORDE.HammerToken.METAL] = 100,
}

function HORDE:Horde_SpawnMapToken(kind, pos, angles, cfg)
    cfg = cfg or {}
    kind = HORDE:Horde_ParseHammerToken(kind, HORDE.HammerToken.MONEY)

    local class = HORDE.MapTokenEntities[kind]
    if not class then
        return nil, "unknown token kind: " .. tostring(kind)
    end

    local ent = ents.Create(class)
    if not IsValid(ent) then
        return nil, "ents.Create failed for " .. class
    end

    local amount = tonumber(cfg.amount)
    if amount == nil then
        amount = HORDE.MapTokenDefaultAmount[kind] or 1
    end
    amount = math.max(1, math.floor(amount))

    ent.Horde_MapTokenKind = kind
    if kind == HORDE.HammerToken.MONEY then
        ent.Horde_Money = amount
    elseif kind == HORDE.HammerToken.METAL then
        ent.Horde_MetalAmount = amount
    end

    local lifetime = tonumber(cfg.lifetime)
    if lifetime ~= nil then
        ent.Horde_Lifetime = math.max(0, math.floor(lifetime))
    end

    ent:SetPos(pos)
    ent:SetAngles(angles or angle_zero)
    ent:Spawn()
    ent:Activate()

    print(string.format("[HORDE] Map token '%s' (%s) x%d spawned at %s",
        kind, class, amount, tostring(pos)))
    return ent
end
