GADGET.PrintName = "Ectoplasm Injection"
GADGET.Description = [[
Makes you slightly invisible, all enemies can't see you for 8 seconds. 
]]
GADGET.Icon = "items/gadgets/ectoplasm_injection.png"
GADGET.Cooldown = 0
GADGET.Once = true
GADGET.Active = true
GADGET.Params = {
}
GADGET.Hooks = {}

GADGET.Hooks.Horde_UseActiveGadget = function(ply)
    if CLIENT then return end
    if ply:Horde_GetGadget() ~= "gadget_ectoplasm_injection" then return end

    ply:EmitSound("buttons/button5.wav")

    ply:SetRenderMode(RENDERMODE_TRANSALPHA)
    ply:SetColor(Color(255, 255, 255, 120))

    ply:SetNoTarget(true)

    ply:SetCustomCollisionCheck(true)

    local hookName = "Gadget_NoCollideNPC_" .. ply:SteamID64()
    hook.Add("ShouldCollide", hookName, function(ent1, ent2)
        if not IsValid(ply) then return end

        if (ent1 == ply and ent2:IsNPC()) or (ent2 == ply and ent1:IsNPC()) then
            return false
        end
    end)

    for _, npc in ipairs(ents.GetAll()) do
        if IsValid(npc) and npc:IsNPC() then
            if npc:GetEnemy() == ply then
                npc:SetEnemy(nil)
                npc:SetSchedule(SCHED_IDLE_STAND)
                npc:ClearEnemyMemory(ply)
            end
        end
    end

    local timerName = "Gadget_Invis_" .. ply:SteamID64()
    timer.Create(timerName, 8, 1, function()
        if IsValid(ply) then

            ply:SetColor(Color(255, 255, 255, 255))
            ply:SetRenderMode(RENDERMODE_NORMAL)

            ply:SetNoTarget(false)

            hook.Remove("ShouldCollide", hookName)
            ply:SetCustomCollisionCheck(false)
        end
    end)
end
