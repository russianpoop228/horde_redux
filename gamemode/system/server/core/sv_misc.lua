local VECTOR_CONE_10DEGREES	= Vector(87.16, 87.16, 0)
hook.Add("EntityFireBullets", "Horde_ModifyTurretBullet", function(ent, data)
    if ent:GetClass() == "npc_turret_floor" then
        data.TracerName = "Tracer"
        local enemy, owner = ent:GetEnemy(), ent:GetNWEntity("HordeOwner")
        if IsValid(enemy) and owner:IsPlayer() then
            data.Dir = enemy:BodyTarget(data.Src) - data.Src
            data.Spread = VECTOR_CONE_10DEGREES * GetConVar("horde_turret_spread"):GetFloat()
            data.IgnoreEntity = owner
        end
        return true
    end
end)

function VJ_AddSpeed(ent, speed)
    if ent:IsPlayer() then
        return
    end
    ent:SetMoveVelocity(ent:GetMoveVelocity() * speed)
end

function HORDE:GetAntlionMinionsCount(ply)
    return self:GetPlayerMinionCountByClass(ply, "npc_vj_horde_antlion")
end

hook.Add("EntityTakeDamage", "ManhackContactDamage", function (target, dmginfo)
    local inflictor = dmginfo:GetInflictor()
    local ply = HORDE:GetMinionOwner(inflictor)
    if ply and inflictor:GetClass() == "npc_manhack" then
        local dmg = inflictor:GetNWFloat("Horde_UpgradeDamage", 0)
        if dmg <= 0 then dmg = inflictor:GetMaxHealth() end
        dmginfo:SetDamage(math.max(dmginfo:GetDamage(), dmg))
        timer.Simple(0, function() if inflictor:IsValid() then
            if inflictor.Horde_Has_Antimatter_Shield then
                local effectdata = EffectData()
                effectdata:SetOrigin(inflictor:GetPos())
                util.Effect("antimatter_explosion", effectdata)
                if ply then
                    local dd = DamageInfo()
                        dd:SetAttacker(ply)
                        dd:SetInflictor(ply)
                        dd:SetDamageType(DMG_CRUSH)
                        dd:SetDamage(inflictor.Horde_Has_Antimatter_Shield)
                    util.BlastDamageInfo(dd, inflictor:GetPos(), 200)
                end
            end
            if inflictor.Horde_Has_Void_Shield then
                local effectdata = EffectData()
                effectdata:SetOrigin(inflictor:GetPos())
                util.Effect("antimatter_explosion", effectdata)
                if ply then
                    local dd = DamageInfo()
                        dd:SetAttacker(ply)
                        dd:SetInflictor(ply)
                        dd:SetDamageType(DMG_CRUSH)
                        dd:SetDamage(inflictor.Horde_Has_Void_Shield)
                    util.BlastDamageInfo(dd, inflictor:GetPos(), 200)
                end
            end
            inflictor:Remove() end
        end)
    end
end)

function HORDE:SpawnManhack(ply, id)
    if CLIENT then return end
    if not ply:IsValid() or not ply:Alive() then return end
    local class = "npc_manhack"
    local item = HORDE.items[class]
    if ply:Horde_GetWeight() - item.weight < 0 then return end
    if not ply:Alive() then
        timer.Remove("Horde_ManhackRespawn" .. id)
        local drop_ents = ply:Horde_GetDropEntities()
        if not drop_ents then
            return
        end
        if not item.whitelist[ply:Horde_GetClass().name] then return end
        local count = drop_ents[class]
        if (!count) or (count and count <= item.entity_properties.limit) then
            timer.Create("Horde_ManhackRespawn" .. id, 30, 1, function ()
                if ply:IsValid() then
                    HORDE:SpawnManhack(ply, id)
                end
            end)
        end
    end
    if not item.whitelist[ply:Horde_GetClass().name] then return end
    local ent = ents.Create(class)
    local pos = ply:GetPos()
    local dis = VectorRand()
    dis.z = math.max(8, dis.z)
    local drop_pos = pos + dis
    ent:SetPos(drop_pos)
    ply:Horde_AddWeight(-item.weight)
    HORDE:AssignMinionOwner(ent, ply)
    ent:Spawn()
    ent:SetMaxHealth(150)
    ent.Horde_Minion_Respawn = true
    local id = ent:GetCreationID()

    HORDE:RegisterMinion(ent, ply, {
        relationship = true,
        on_remove = function(removed, owner)
            timer.Remove("Horde_ManhackRepos" .. id)
            if removed.Horde_Minion_Respawn and IsValid(owner) then
                timer.Remove("Horde_ManhackRespawn" .. id)
                local drop_ents = owner:Horde_GetDropEntities()
                if not drop_ents then return end
                if not item.whitelist[owner:Horde_GetClass().name] then return end
                local count = drop_ents[class]
                if (!count) or (count and count <= item.entity_properties.limit) then
                    timer.Create("Horde_ManhackRespawn" .. id, 30, 1, function ()
                        if owner:IsValid() then
                            HORDE:SpawnManhack(owner, id)
                        end
                    end)
                end
            end
        end,
    })

    timer.Create("Horde_ManhackRepos" .. id, 30, 0, function ()
        if ent:IsValid() and ply:Alive() then
            ent:SetPos(ply:GetPos() + VectorRand())
        else
            timer.Remove("Horde_ManhackRepos" .. id)
        end
    end)

    ply:Horde_SyncEconomy()
end

function HORDE:CheckDemonStompCharges(ply)
    timer.Simple(0.5, function ()
        if not ply:IsValid() or not ply:Horde_GetPerk("samurai_base") then return end
        local max_charges = 1
        if ply:Horde_GetPerk("samurai_focus_slash") then
            max_charges = max_charges + 1
        end
        if ply:Horde_GetPerk("samurai_demon_stomp") then
            max_charges = max_charges + 1
        end
        if ply:Horde_GetPerk("samurai_blade_dance") then
            max_charges = max_charges + 1
        end
        if ply:Horde_GetPerk("samurai_foresight") then
            max_charges = max_charges + 1
        end
        ply:Horde_SetPerkCharges(max_charges)
    end)
end

HORDE:AddPlayerTick("Horde_Misc", function(ply, mv)
    if !ply:IsOnGround() then return end
    local ground = ply:GetGroundEntity()
    if not IsValid(ground) or ground:IsWorld() then return end
    local tr = util.TraceHull({
        start = ply:GetPos(),
        endpos = ply:GetPos() + Vector(0,0,-1) * 50,
        filter = ply,
        mins = Vector(-8, -8, -8),
        maxs = Vector(8, 8, 8),
    })
    if tr.Entity and HORDE:IsEnemy(tr.Entity) and tr.Entity:Health() > 0 then
        local vrand = VectorRand()
        vrand.z = 0
        vrand = vrand * 200
        ply:SetVelocity(vrand)
    end
end)

function HORDE:CreateTimer(identifier, delay, repitition, fn)
    timer.Create("Horde_" .. identifier, delay, repitition, fn)
end

function HORDE:RemoveTimer(identifier)
    timer.Remove("Horde_" .. identifier)
end

function HORDE:SendNotification(text, type, ply)
    net.Start("Horde_SideNotification")
    net.WriteString(text or "")
    net.WriteInt(math.Clamp(math.floor(tonumber(type) or 0), -2, 1), 2)
    if ply == nil then
        net.Broadcast()
    else
        net.Send(ply)
    end
end

function HORDE:SendNotificationDebuff(debuff, ply)
    net.Start("Horde_SideNotificationDebuff")
    net.WriteUInt(debuff, 32)
    net.Send(ply)
end

function HORDE:SendNotificationDenyAccess(ply)
    net.Start("Horde_SideNotification")
    net.WriteString("You do not have access to this command.")
    net.WriteInt(1,2)
    net.Send(ply)
end

function HORDE:SendNotificationSandboxOnly(ply)
    net.Start("Horde_SideNotification")
    net.WriteString("Command only available in sandbox mode.")
    net.WriteInt(1,2)
    net.Send(ply)
end

function HORDE:SendNotificationObjective(objective, str, ply)
    net.Start("Horde_SideNotificationObjective")
    net.WriteUInt(objective, 4)
    if str then
        net.WriteString(str)
    else
        net.WriteString("Objective")
    end
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

hook.Add("PlayerSwitchFlashlight", "Horde_BlockFlashlightForMages", function (ply, switchOn)
    if (ply:Horde_GetMaxMind() > 0) then return false end
end)

function HORDE:SimpleParticleSystem(particle_name, pos, angles, parent)
    local p = ents.Create("info_particle_system")
    p:SetKeyValue("effect_name", particle_name)
    p:SetPos(pos)
    p:SetAngles(angles)
    p:SetParent(parent)
    p:Spawn()
    p:Activate()
    p:Fire( "start", "", 0 )
    return p
end
