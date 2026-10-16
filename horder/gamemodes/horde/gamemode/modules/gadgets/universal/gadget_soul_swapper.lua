GADGET.PrintName = "Soul Swapper"
GADGET.Description = "Changes your place with enemy's (Doesn't work on Elites)"
GADGET.Icon = "items/gadgets/soul_swapper.png"
GADGET.Droppable = false

GADGET.Cooldown =1
GADGET.Active = true
GADGET.Params = {
    [1] = {value = 0, percent = true},
}
GADGET.Hooks = {}

local g=GADGET
GADGET.Hooks.Horde_UseActiveGadget = function (ply)
    if CLIENT then return  end
    if ply:Horde_GetGadget() ~= "gadget_soul_swapper" then return end
    local trace = ply:GetEyeTrace()
    local target = trace.Entity
    if IsValid(target) and target:IsNPC() and target:Disposition(ply) == D_HT and not target:Horde_IsElite() then
        local plyPos=ply:GetPos()
        local targetPos=target:GetPos()
        local distancePlyTar=ply:GetPos():Distance(targetPos)

        local distanceDamage=math.min(math.floor(distancePlyTar/5), 275)

        ply:SetPos(targetPos)
        target:SetPos(plyPos)
        local dmgi = DamageInfo()
                dmgi:SetDamageType(DMG_BULLET)
                dmgi:SetDamage(distanceDamage )
                dmgi:SetInflictor(ply)
                dmgi:SetAttacker(ply)
        target:TakeDamageInfo( dmgi )

    end

end
