GADGET.PrintName = "Windy Blast"
GADGET.Description =  [[Upon use knockbacks all enemies away from you.]]
GADGET.Icon = "items/gadgets/windy_blast.png"
GADGET.Droppable = false
GADGET.Cooldown =15
GADGET.Active = true
GADGET.Hooks = {}

GADGET.Hooks.Horde_UseActiveGadget = function (ply)
    if CLIENT then return  end
    if ply:Horde_GetGadget() ~= "gadget_windy_blast"  then return end
    local enemys= ents.FindInSphere(ply:GetPos(),300)
    for _, enemy in ipairs(enemys) do
        ply:EmitSound("physics/flesh/flesh_strider_impact_bullet1.wav", 70, 100, 0.8)
            if not enemy:IsNPC() then continue   end
            if enemy:Disposition(ply) ~= D_HT then continue  end
            if  not enemy:Horde_IsElite() then
                local direction = (enemy:GetPos() - ply:GetPos()):GetNormalized()
                enemy:SetVelocity(direction * 1500 + Vector(0, 0, 200))
            else
                local direction = (enemy:GetPos() - ply:GetPos()):GetNormalized()
                enemy:SetVelocity(direction * 500 + Vector(0, 0, 200))
            end
		end
end
