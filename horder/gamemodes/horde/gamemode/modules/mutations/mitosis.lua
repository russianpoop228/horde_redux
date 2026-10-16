MUTATION.PrintName   = "Mitosis"
MUTATION.Description = "Upon death, splits into 2 smaller clones with 50% HP.\nClones explode after 60 seconds. Deals 50% less damage."
MUTATION.Wave        = 7

MUTATION.Hooks = {}

local CHILD_SCALE        = 0.6
local CHILD_HP_RATIO     = 0.5
local CHILD_EXPLODE_TIME = 60
local CHILD_COLOR        = Color(150, 75, 0)

MUTATION.Hooks.Horde_OnSetMutation = function(ent, mutation)
    if mutation ~= "mitosis" then return end
    if not SERVER then return end
    if not IsValid(ent) then return end
    if ent:GetVar("is_boss") then return end
    if ent.IsMitosisChild then return end

    ent:SetModelScale(1.25, 0)
    ent:SetColor(CHILD_COLOR)
end

MUTATION.Hooks.Horde_OnUnsetMutation = function(ent, mutation)
    if mutation ~= "mitosis" then return end
    if not SERVER then return end
    if not IsValid(ent) then return end

    ent:SetModelScale(1.0, 0)
    ent:SetColor(Color(255, 255, 255))
end

MUTATION.Hooks.EntityTakeDamage = function(target, dmg)
    if not SERVER then return end

    local attacker = dmg:GetAttacker()
    if not IsValid(attacker) then return end
    if not attacker:IsNPC() then return end
    if not attacker:Horde_HasMutation("mitosis") then return end

    dmg:ScaleDamage(0.5)
end

local function SpawnSplitEffect(pos)
    local ef = EffectData()
    ef:SetOrigin(pos)
    ef:SetScale(1)
    util.Effect("StriderBlood", ef)
end

local function SpawnChild(class, pos, ang, maxHealth, attacker)
    local child = ents.Create(class)
    if not IsValid(child) then return end

    local spawnAng  = Angle(ang.p, math.random(0, 360), ang.r)
    local spawnPos  = pos + Vector(math.random(-64, 64), math.random(-64, 64), 10)

    child:SetPos(spawnPos)
    child:SetAngles(spawnAng)
    child.IsMitosisChild = true
    child:Spawn()
    child:Activate()

    if not IsValid(child) then return end

    child:SetModelScale(CHILD_SCALE, 0)

    local childHP = math.max(1, math.floor(maxHealth * CHILD_HP_RATIO))
    child:SetMaxHealth(childHP)
    child:SetHealth(childHP)
    child:SetColor(CHILD_COLOR)

    if child.IsVJBaseSNPC and IsValid(attacker) then
        child:SetEnemy(attacker)
    end

    SpawnSplitEffect(spawnPos)

    timer.Simple(CHILD_EXPLODE_TIME, function()
        if not IsValid(child) then return end

        SpawnSplitEffect(child:GetPos() + Vector(0, 0, 10))
        child:EmitSound("physics/flesh/flesh_bloody_break.wav", 75, 100)
        util.BlastDamage(child, child, child:GetPos(), 100, 25)
        SafeRemoveEntity(child)
    end)
end

MUTATION.Hooks.Horde_OnEnemyKilled = function(ent, attacker, inflictor)
    if not SERVER then return end
    if not IsValid(ent) then return end
    if not ent:Horde_HasMutation("mitosis") then return end
    if ent.IsMitosisChild then return end

    local class     = ent:GetClass()
    local pos       = ent:GetPos()
    local ang       = ent:GetAngles()
    local maxHealth = ent:GetMaxHealth()

    if maxHealth <= 0 then return end

    timer.Simple(0.1, function()
        for _ = 1, 2 do
            SpawnChild(class, pos, ang, maxHealth, attacker)
        end
    end)
end
