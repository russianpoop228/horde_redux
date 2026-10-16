util.AddNetworkString("Horde_HitnumbersSpawn")
util.AddNetworkString("Horde_HitnumbersDebuffSpawn")
util.AddNetworkString("Horde_FearDebuffSpawn")

local on = true

hook.Add("PostEntityTakeDamage", "Horde_HitnumbersDamagePost", function(target, dmginfo, took)
	if not GetConVar("horde_display_damage"):GetBool() then return end
	if not took then return end
	local attacker         = dmginfo:GetAttacker()
	local attackerIsPlayer = attacker:IsPlayer()

	if not (attackerIsPlayer) then return end
	if attacker == target then return end
	if not target:IsNPC() then return end

	local dmgAmount = dmginfo:GetDamage()
	local dmgType   = dmginfo:GetDamageType()
	local pos       = dmginfo:GetDamagePosition()
	if ! pos or dmginfo:IsExplosionDamage() then
		pos = target:GetPos()
	end

	net.Start("Horde_HitnumbersSpawn", true)

	net.WriteFloat(dmgAmount)

	net.WriteUInt(dmgType, 32)

	net.WriteVector(pos)

	net.Send(attacker)
end)

hook.Add("Horde_PostEnemyDebuffApply", "Horde_HitnumbersDebuff", function(target, inflictor, debuff, pos)
	if not GetConVar("horde_display_damage"):GetBool() then return end
	if IsValid(inflictor) and inflictor:IsPlayer() then
		net.Start("Horde_HitnumbersDebuffSpawn", true)

		net.WriteUInt(debuff, 32)

		net.WriteVector(pos)

		net.Send(inflictor)
	end
end)

hook.Add("Horde_PostFearApply", "Horde_FearDebuff", function(target, inflictor, debuff, pos, stack)
	if not GetConVar("horde_display_damage"):GetBool() then return end
	if IsValid(inflictor) and inflictor:IsPlayer() then
		net.Start("Horde_FearDebuffSpawn", true)

		net.WriteUInt(debuff, 32)

		net.WriteVector(pos)

		net.WriteUInt(stack, 4)

		net.Send(inflictor)
	end
end)
