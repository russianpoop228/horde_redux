GADGET.PrintName = "The Stomp of Fury"
GADGET.Description = [[Stomps once dealing Blunt damage to all enemies in the radius.
Power depends on damage dealt to enemies (max {1}).
More damage dealt = more damage, larger radius, but longer windup!
Slows you down and provides resistance while charging.
Stored damage resets after use.]]
GADGET.Icon = "items/gadgets/stompfury.png"
GADGET.Duration = 3
GADGET.Cooldown = 15
GADGET.Active = true
GADGET.Params = {
    [1] = {value = 45000},
}
GADGET.Hooks = {}

if SERVER then
    util.AddNetworkString("StompFury_UpdateUI")

    hook.Add("PlayerSpawn", "StompFury_Init", function(ply)
        ply.StompFury_StoredDamage = 0
        ply.StompFury_MaxStoredDamage = 45000
    end)

    hook.Add("EntityTakeDamage", "StompFury_Accumulate", function(ent, dmginfo)
        if not ent:IsNPC() then return end

        local attacker = dmginfo:GetAttacker()
        if not attacker:IsPlayer() then return end

        if attacker:Horde_GetGadget() ~= "gadget_stomp_of_fury" then return end

        local damage = dmginfo:GetDamage()
        attacker.StompFury_StoredDamage = math.min(
            (attacker.StompFury_StoredDamage or 0) + damage,
            attacker.StompFury_MaxStoredDamage or 45000
        )

        net.Start("StompFury_UpdateUI")
        net.WriteFloat(attacker.StompFury_StoredDamage)
        net.WriteFloat(attacker.StompFury_MaxStoredDamage or 45000)
        net.Send(attacker)

    end)

end

if CLIENT then
    local displayStoredDamage = 0
    local displayMaxDamage = 45000

    net.Receive("StompFury_UpdateUI", function()
        displayStoredDamage = net.ReadFloat()
        displayMaxDamage = net.ReadFloat()
    end)

    hook.Add("HUDPaint", "StompFury_UI", function()
        local ply = LocalPlayer()
        if not ply:IsValid() then return end
        if ply:Horde_GetGadget() ~= "gadget_stomp_of_fury" then return end

        local stored = displayStoredDamage
        if stored <= 0 then return end

        local airgap = ScreenScale(6)
        local x = ScrW() - airgap - ScreenScale(80) + 5
        local y = ScrH() - ScreenScale(61.75) - airgap + 25
        local width = 148
        local height = 25
		local progress = math.min(stored / displayMaxDamage, 1)
        local bordercolor = Color(40, 40, 40, 200)
        local color = Color(255, 200 - 150 * progress, 50)

        draw.RoundedBox(8, x, y, width, height, bordercolor)
        draw.RoundedBox(4, x + 4, y + 4, (width - 8) * progress, height - 8, color)

        draw.SimpleText(
            math.floor(stored),
            "TargetID",
            x + width / 2,
            y + height / 2 - 1,
            Color(255, 255, 255, 255),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end)
end

GADGET.Hooks.Horde_UseActiveGadget = function (ply)
    if CLIENT then return end
    if ply:Horde_GetGadget() ~= "gadget_stomp_of_fury" then return end

    local storedDamage = ply.StompFury_StoredDamage or 0
    local progress = math.min(storedDamage / 45000, 1)

    local windupDelay = 0.5 + (storedDamage / 45000) * 1
    local damageBonus = math.floor((storedDamage / 45000) * 575)
    local radiusBonus = math.floor((storedDamage / 45000) * 250)
    local knockbackBonus = math.floor(100 + progress * 400)
    local effectDuration = 1.35 + progress * 1.5
	local ringCount = 3 + math.floor(progress * 6)

    ply.Horde_HasForce = true

    if progress >= 0.7 then
        ply:EmitSound("ambient/machines/floodgate_move_short1.wav", 100, 85 + progress * 20, 1, CHAN_AUTO)
    end

    timer.Simple(effectDuration, function()
        if ply:IsValid() then ply.Horde_HasForce = nil end
    end)

    timer.Simple(0.3, function()
        if not ply:Alive() then return end

		for i = 1, ringCount do
			timer.Simple(0.15 * i, function()
				local stompchargeEffect = EffectData()
				stompchargeEffect:SetOrigin(ply:GetPos())
				stompchargeEffect:SetRadius(50 + radiusBonus * 0.3)
				stompchargeEffect:SetColor(100 + 155 * progress)
				util.Effect("horde_stompcharge", stompchargeEffect)
			end)
		end

        ply:EmitSound("ambient/machines/floodgate_stop1.wav", 100, 80 + progress * 30, 1, CHAN_AUTO)
    end)

    timer.Simple(0.5 + windupDelay, function()
        if not ply:Alive() or not ply:IsValid() then return end

		local stomphitEffect = EffectData()
		stomphitEffect:SetOrigin(ply:GetPos())
		stomphitEffect:SetRadius(50 + radiusBonus * 0.3)
		stomphitEffect:SetColor(100 + 155 * progress)
		util.Effect("horde_stomphit", stomphitEffect)
		util.ScreenShake(ply:GetPos(), 2 + 20 * progress, 80, 0.5 + 2.5 * progress, radiusBonus)

        ply:EmitSound("plats/tram_hit4.wav", 100, 80 + progress * 40, 1, CHAN_AUTO)

        local baseRadius = 160 + radiusBonus
        local baseDamage = 25 + damageBonus

        for _, ent in pairs(ents.FindInSphere(ply:GetPos(), baseRadius)) do
            if ent:IsNPC() then
                local dir = ((ent:GetPos() - ply:GetPos()):GetNormalized() + Vector(0, 0, 1) * 0.5):GetNormalized()
                ent:SetVelocity(dir * knockbackBonus)
            end
        end

        for i = 1, 3 do
            local waveRadius = (80 * i) + radiusBonus * (i / 3)
            local waveDamage = baseDamage * 0.33

            for _, ent in pairs(ents.FindInSphere(ply:GetPos(), waveRadius)) do
                if ent:IsNPC() then
                    local dmg = DamageInfo()
                    dmg:SetDamage(math.floor(waveDamage))
                    dmg:SetDamageType(DMG_CLUB)
                    dmg:SetAttacker(ply)
                    dmg:SetInflictor(ply)
                    dmg:SetDamagePosition(ply:GetPos())
                    ent:TakeDamageInfo(dmg)
                end
            end
        end

        ply.StompFury_StoredDamage = 0

        net.Start("StompFury_UpdateUI")
        net.WriteFloat(0)
        net.WriteFloat(ply.StompFury_MaxStoredDamage or 45000)
        net.Send(ply)

    end)
end

GADGET.Hooks.Horde_OnPlayerDamageTaken = function (ply, dmginfo, bonus)
    if ply:Horde_GetGadget() ~= "gadget_stomp_of_fury" or not ply.Horde_HasForce then return end

    local storedDamage = ply.StompFury_StoredDamage or 0
    local progress = math.min(storedDamage / 45000, 1)

    bonus.resistance = bonus.resistance + (0.1 + progress * 0.2)
end

GADGET.Hooks.Horde_PlayerMoveBonus = function(ply, bonus_walk, bonus_run)
    if ply:Horde_GetGadget() ~= "gadget_stomp_of_fury" or not ply.Horde_HasForce then return end

    local storedDamage = ply.StompFury_StoredDamage or 0
    local progress = math.min(storedDamage / 45000, 1)

    local slowAddition = 0.2 + progress * 0.3

    bonus_walk.increase = bonus_walk.increase - slowAddition
    bonus_run.increase = bonus_run.increase - slowAddition
    ply:SetJumpPower(0)
end
