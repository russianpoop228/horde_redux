GADGET.PrintName = "Black Hole Synthesizer"
GADGET.Description = "Stuns enemies and sucks them in one dot."
GADGET.Icon = "items/gadgets/black_hole_synthesizer.png"
GADGET.Droppable = false
GADGET.Cooldown = 60
GADGET.Active = true
GADGET.Params = {
}
GADGET.Hooks = {}

GADGET.Hooks.Horde_UseActiveGadget = function (ply)
    if CLIENT then return  end
    if ply:Horde_GetGadget() ~= "gadget_black_hole_synthesizer" then return end
    local trace = ply:GetEyeTrace()
    local trPos = trace.HitPos
    local enemys= ents.FindInSphere(trPos,300)
    for _, enemy in ipairs(enemys) do
            if not enemy:IsNPC() then continue   end
            if enemy:Disposition(ply) ~= D_HT then continue  end
            enemy:Horde_AddStun(10)
            if  not enemy:Horde_IsElite() then
                for i = 1, 17 do
                    timer.Simple((i-1) * 0.2, function ()
                        local direction = (trPos - enemy:GetPos()  ):GetNormalized()
                        enemy:SetVelocity(direction * trPos:Distance(enemy:GetPos())*3 )
                    end)
                end
            else
                for i = 1, 17 do
                    timer.Simple((i-1) * 0.2, function ()
                        local direction = (trPos - enemy:GetPos()  ):GetNormalized()
                        enemy:SetVelocity(direction * trPos:Distance(enemy:GetPos())*3/2 )
                    end)
                end

            end
		end

end
