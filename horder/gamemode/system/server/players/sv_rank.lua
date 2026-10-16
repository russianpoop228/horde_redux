HORDE.Kill_XP = { Normal = 1, Elite = 10, Mutation_Min = 1, Mutation_Max = 2 }
HORDE.Special_Kill_XP = {
	["npc_vj_horde_lesion"] = 15,
	["npc_vj_horde_hulk"]   = 15,
	["npc_vj_horde_blight"] = 15,
}
HORDE.Wave_Completion_XP = 5

function HORDE:RankExpEnabled()
	return GetConVar("horde_enable_rank"):GetInt() == 1
		and GetConVar("horde_enable_sandbox"):GetInt() == 0
end

if HORDE:RankExpEnabled() then
	hook.Add("Horde_OnEnemyKilled", "Horde_GiveExp", function(victim, killer, wpn)
		if HORDE.current_wave <= 0 or GetConVar("sv_cheats"):GetInt() == 1 then return end
		if victim.Horde_NoReward then return end
		if not (IsValid(killer) and killer:IsPlayer() and killer:Horde_GetClass()) then return end
		if not HORDE:IsKillRewardAllowed(killer, victim) then return end

		local class_name = killer:Horde_GetCurrentSubclass()
		if not class_name or killer:Horde_GetLevel(class_name) >= HORDE.max_level then return end

		local xp = HORDE.Special_Kill_XP[victim:GetClass()]
			or (victim:Horde_IsElite() and HORDE.Kill_XP.Elite)
			or HORDE.Kill_XP.Normal

		if victim.Horde_Mutation and next(victim.Horde_Mutation) ~= nil then
			xp = xp + math.random(HORDE.Kill_XP.Mutation_Min, HORDE.Kill_XP.Mutation_Max)
		end

		killer:Horde_AddExp(class_name, xp)

		if victim:Horde_IsElite() then
			local p = math.random()
			if p < 0.01 or (p < 0.1 and killer:Horde_GetGadget() == "gadget_corporate_mindset") then
				local ent = ents.Create("horde_skull_token")
				local pos = killer:GetPos()
				local drop_pos = pos
				drop_pos = drop_pos
				drop_pos.z = pos.z + 15
				ent:SetPos(drop_pos)
				ent.Owner = killer
				ent:Spawn()
			end
		end
	end)
end
