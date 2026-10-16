SWEP.Base = "arccw_base_melee"
SWEP.Primary.Ammo = "none"
SWEP.Primary.ClipSize = 100

SWEP.MaximumDurability = 100
SWEP.DurabilityCostPerHit = 1
SWEP.SecondaryAttackCostMul = 2
SWEP.IsHordeMelee = true
SWEP.UseHordeDurability = true
SWEP.WasHeadshot = false

SWEP.Dur_BaseDamageScale = 0.5

DEFINE_BASECLASS(SWEP.Base)

function SWEP.Initialize(self, ...)
    self:SetNWFloat("HORDE_Durability", self.MaximumDurability)
    BaseClass.Initialize(self, ...)
end

local IsValidEntity = function(owner, ent)
    return (IsValid(ent) && (ent != owner) && !ent:GetNWEntity("HordeOwner"):IsPlayer() && ((ent:IsNPC() || ent:IsNextBot())))
end

local VisCheck = function(owner, pos)
    return util.TraceLine({
        start = pos,
        endpos = owner:EyePos(),
        filter = {owner},
        mask = MASK_SHOT,
        collisiongroup = COLLISION_GROUP_DEBRIS,
    }).Fraction == 1
end

SWEP.HipDispersion = 75

function SWEP:MeleeAttack(melee2)
    local owner = self:GetOwner()
    local reach = 32 + self:GetBuff_Add("Add_MeleeRange") + self.MeleeRange
    local dmg = self:GetBuff_Override("Override_MeleeDamage", self.MeleeDamage) or 20
    local dmgtype = self:GetBuff_Override("Override_MeleeDamageType") or self.MeleeDamageType or DMG_CLUB
    local ragdoll_force = owner:GetRight() * math.random(-4912, 4912) + owner:GetForward() * math.random(2048, 9989)

    if melee2 then
        reach = 32 + self:GetBuff_Add("Add_MeleeRange") + self.Melee2Range
        dmg = self:GetBuff_Override("Override_MeleeDamage", self.Melee2Damage) or 20
    end
    dmg = dmg * self:GetBuff_Mult("Mult_MeleeDamage")

    local durability = self:GetNWFloat("HORDE_Durability", 100)
    if(durability <= 0) then
        dmg = dmg * self.Dur_BaseDamageScale
    end

    owner:LagCompensation(true)

    local filter = {owner, self}
    local mins, maxs = Vector(-16, -16, -4), Vector(16, 16, 4)
    local bbox = self.MeleeBoundingBox
    if(bbox) then
        if(!melee2) then
            if(bbox.primary) then
                mins = Vector(-bbox.primary.wide, -bbox.primary.wide, -bbox.primary.tall)
                maxs = Vector(bbox.primary.wide, bbox.primary.wide, bbox.primary.tall)
                reach = bbox.primary.length
            end
        else
            if(bbox.secondary) then
                mins = Vector(-bbox.secondary.wide, -bbox.secondary.wide, -bbox.secondary.tall)
                maxs = Vector(bbox.secondary.wide, bbox.secondary.wide, bbox.secondary.tall)
                reach = bbox.secondary.length
            end
        end
    end
    local trace_reach = reach + (mins:Distance(maxs) * 0.5)
    local trace_endpos = owner:EyePos() + owner:EyeAngles():Forward() * reach
    local maxhits = self.MaxHits || 2
    if melee2 and self.MaxHits then
        maxhits = self.MaxHitsSecondary || self.MaxHits
    end
    local hits = 0
    local tr = {
        start = owner:EyePos(),
        endpos = owner:EyePos() + owner:EyeAngles():Forward() * trace_reach,
        filter = filter,
        mask = MASK_SHOT,
    }
    local developer = GetConVar("developer"):GetInt() > 0
    local hitTargets = {}
    local enemies_hit = {}
    local preTr = util.TraceLine(tr)
    local preHit = preTr.Entity
    local hitworldSD = false
    local hitFleshSD = false
    if(IsValidEntity(owner, preHit)) then
        if(SERVER) then
            local dmginfo = DamageInfo()
                dmginfo:SetAttacker(owner)
                dmginfo:SetInflictor(self)
                dmginfo:SetDamage(dmg)
                dmginfo:SetDamageType(dmgtype)
                dmginfo:SetDamageForce(ragdoll_force)
                dmginfo:SetDamagePosition(preHit:NearestPoint(preTr.HitPos))

            if(preTr.HitGroup == 1) then
                if(preHit:IsNPC()) then
                    hook.Run("ScaleNPCDamage", preHit, preTr.HitGroup, dmginfo)
                elseif(preHit:IsPlayer()) then
                    hook.Run("ScalePlayerDamage", preHit, preTr.HitGroup, dmginfo)
                end
                self.WasHeadshot = true
            else
                self.WasHeadshot = false
            end

            preHit:TakeDamageInfo(dmginfo)
        end
        table.insert(enemies_hit, preHit)
        hits = hits + 1
        hitTargets[preHit:EntIndex()] = true

        if(!hitFleshSD) then
            self:MyEmitSound(self.MeleeHitNPCSound, 75, 100, 1, CHAN_STATIC)
            hitFleshSD = true
        end
    else
        if(preTr.Hit && !hitworldSD) then
            if !preHit:IsPlayer() and !preHit:GetNWEntity("HordeOwner"):IsValid() then
                self:MyEmitSound(self.MeleeHitSound, 75, 100, 1, CHAN_STATIC)
            end
            hitworldSD = true
            local dmginfo = DamageInfo()
                dmginfo:SetAttacker(owner)
                dmginfo:SetInflictor(self)
                dmginfo:SetDamage(dmg)
                dmginfo:SetDamageType(dmgtype)
                dmginfo:SetDamageForce(ragdoll_force)
                dmginfo:SetDamagePosition(preHit:NearestPoint(preTr.HitPos))
            preHit:DispatchTraceAttack(dmginfo, tr)
        end
    end
    self:MyEmitSound(self.MeleeMissSound, 75, 100, 1, CHAN_STATIC)

    if(hits < maxhits) then
        local targets_in_range = {}
        local eyepos = owner:EyePos()
        for _, ent in ipairs(ents.FindAlongRay(owner:EyePos(), trace_endpos, mins, maxs)) do
            if(!IsValidEntity(owner, ent)) then continue end
            if(hits > maxhits) then break end
            if(hitTargets[ent:EntIndex()]) then continue end
            if(!VisCheck(owner, ent:NearestPoint(eyepos))) then continue end
            if(developer) then
                debugoverlay.Cross(ent:NearestPoint(eyepos), 3, 1, Color(255, 0, 255, 255), true)
            end
            table.insert(targets_in_range, ent)
        end
        table.sort(targets_in_range, function(a, b) return a:GetPos():Distance(eyepos) < b:GetPos():Distance(eyepos) end)
        for _, target in ipairs(targets_in_range) do
            if(SERVER) then
                local dmginfo = DamageInfo()
                    dmginfo:SetAttacker(owner)
                    dmginfo:SetInflictor(self)
                    dmginfo:SetDamage(dmg)
                    dmginfo:SetDamageType(dmgtype)
                    dmginfo:SetDamageForce(ragdoll_force)
                    dmginfo:SetDamagePosition(target:GetPos() + target:OBBCenter())
                target:TakeDamageInfo(dmginfo)
            end
            table.insert(enemies_hit, target)
            hits = hits + 1
            if(!hitFleshSD) then
                self:MyEmitSound(self.MeleeHitNPCSound, 75, 100, 1, CHAN_STATIC)
                hitFleshSD = true
            end

            if(hits >= maxhits) then
                break
            end
        end

        if(developer) then
            debugoverlay.SweptBox(owner:EyePos(), trace_endpos, mins, maxs, Angle(0, 0, 0), 2, Color(255, 0, 0), true)
        end
    end
    if(developer) then
        debugoverlay.Line(owner:EyePos(), tr.endpos, 2, Color(255, 255, 255), true)
    end

    local cost = self.DurabilityCostPerHit
    if (melee2) then
        cost = cost * self.SecondaryAttackCostMul
    end
    if hits > 0 and self.UseHordeDurability and HORDE.enable_ammobox == 1 then
        self:SetNWFloat("HORDE_Durability", math.max(self:GetNWFloat("HORDE_Durability", self.MaximumDurability) - (cost * hits), 0))
    end

    self:GetBuff_Hook("Hook_HordePostCleaving", {tr = preTr, dmg = dmg, melee2 = melee2, cleave = enemies_hit, ply = owner, dmgtype = dmgtype})
    owner:LagCompensation(false)
end

hook.Add("Horde_OnPlayerDamagePost", "Horde_Splash_DamageInfo", function(ply, npc, bonus, hitgroup, dmginfo)
    if ply:GetActiveWeapon():IsValid() and ply:GetActiveWeapon().IsHordeMelee then
        ply:GetActiveWeapon().splash_dmg_check = dmginfo:GetDamage()
    end
end)
