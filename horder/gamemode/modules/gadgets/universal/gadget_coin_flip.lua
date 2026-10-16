GADGET.PrintName = "Coin Flip"
GADGET.Description = [[Upon use flips a coin. 
If you get lucky, enemy you're looking at gonna take 50% of its health as damage.
If luck isn't gonna be on your side, you will take 50% of your health as damage.
1% chance to destroy itself and give you 1000 dollars.
On successful flip destroys itself.]]
GADGET.Icon = "items/gadgets/coin_flip.png"
GADGET.Droppable = false
GADGET.Cooldown = 5
GADGET.Active = true
GADGET.Params = {
}
GADGET.Hooks = {}

local g=GADGET
GADGET.Hooks.Horde_UseActiveGadget = function (ply)
    if CLIENT then return  end
	if ply:Horde_GetGadget() ~= "gadget_coin_flip" then return end
    local trace = ply:GetEyeTrace()
    local target = trace.Entity
    if IsValid(target) and target:IsNPC() and target:Disposition(ply) == D_HT then
        local chance=math.random(0,99)
        if chance==99 then
            ply:EmitSound("ambient/alarms/warningbell1.wav", 75, 100, 1, CHAN_AUTO )
            ply:Horde_AddMoney(1000)
			ply:Horde_SyncEconomy()
        elseif chance<=49 then
            ply:EmitSound("buttons/combine_button5.wav", 75, 100, 1, CHAN_AUTO )
            local dmgi = DamageInfo()
                dmgi:SetDamageType(DMG_SLASH)
                dmgi:SetDamage( ply:Health() * 0.5 )
                dmgi:SetAttacker(target )
                dmgi:SetInflictor(ply)
            ply:TakeDamageInfo( dmgi )
        else
            ply:EmitSound("buttons/button9.wav", 75, 100, 1, CHAN_AUTO )
            local dmgi = DamageInfo()
                dmgi:SetDamageType(DMG_BULLET)
                dmgi:SetDamage( target:Health() * 0.5 )
                dmgi:SetInflictor(ply)
                dmgi:SetAttacker(ply)
            target:TakeDamageInfo( dmgi )
        end
        g.Once = true
    end

end
