GADGET.PrintName = "U-Turn"
GADGET.Description = [[Rotates three times dealing 50/60/70 Slashing damage to all enemies in the radius.
Radius and damage are increasing each hit.
Provides 10% resistance for 1.7 seconds.
Slows you down.]]
GADGET.Icon = "items/gadgets/u-turn.png"
GADGET.Duration = 2
GADGET.Cooldown = 10
GADGET.Active = true
GADGET.Params = {
    [1] = {value = 45},
	[2] = {value = 55},
	[3] = {value = 65},
	[4] = {value = 1.7},
}
GADGET.Hooks = {}

GADGET.Hooks.Horde_UseActiveGadget = function (ply)
    if CLIENT then return end
    if ply:Horde_GetGadget() ~= "gadget_u_turn" then return end
	ply.Horde_HasForce = true
    timer.Simple(1.7, function()
        if ply:IsValid() then ply.Horde_HasForce = nil end
    end)
	for i = 0, 2 do
		timer.Simple(i*0.4, function ()
			local effectdata = EffectData()
			effectdata:SetOrigin(ply:GetPos())
			effectdata:SetRadius(300 + (i * 25))
			util.Effect("horde_u_turn", effectdata)
			ply:ScreenFade(SCREENFADE.IN, Color(65, 15, 15, 110), 0.2, 0.4)
			HORDE.SendBorderEffect(ply, {
				id = "UTurn_SE",
				color = Color(65, 15, 15),
				time = 1.35,
				alpha = 255,
			})

			if i == 0 then
				ply:EmitSound("npc/roller/blade_out.wav", 100, 110, 1, CHAN_AUTO)
			elseif i == 1 then
				ply:EmitSound("npc/roller/blade_out.wav", 100, 105, 1, CHAN_AUTO)
			elseif i == 2 then
				ply:EmitSound("npc/roller/blade_out.wav", 100, 100, 1, CHAN_AUTO)
			end

			for _, ent in pairs(ents.FindInSphere(ply:GetPos(), 275 + (i * 25))) do
				if ent:IsNPC() then
					local dmg = DamageInfo()
					dmg:SetDamage(45 + (i * 10))
					dmg:SetDamageType(DMG_SLASH)
					dmg:SetAttacker(ply)
					dmg:SetInflictor(ply)
					dmg:SetDamagePosition(ply:GetPos())
					ent:TakeDamageInfo(dmg)
				end
			end
		end)
	end
end

GADGET.Hooks.Horde_OnPlayerDamageTaken = function (ply, dmginfo, bonus)
    if ply:Horde_GetGadget() ~= "gadget_u_turn" or not ply.Horde_HasForce then return end
    bonus.resistance = bonus.resistance + 0.1
end

GADGET.Hooks.Horde_PlayerMoveBonus = function(ply, bonus_walk, bonus_run)
    if ply:Horde_GetGadget() ~= "gadget_u_turn" or not ply.Horde_HasForce then return end
    bonus_walk.increase = bonus_walk.increase - 0.3
    bonus_run.increase = bonus_run.increase - 0.3
end
