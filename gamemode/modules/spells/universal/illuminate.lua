SPELL.PrintName       = "Illuminate"
SPELL.Weapon          = nil
SPELL.Mind            = {5}
SPELL.Price           = 0
SPELL.ChargeTime      = {0}
SPELL.ChargeRelease   = true
SPELL.Cooldown        = 2
SPELL.Slot            = HORDE.Spell_Slot_Utility
SPELL.DamageType      = nil
SPELL.Icon            = "spells/illuminate.png"
SPELL.Type            = {HORDE.Spell_Type_Utility}
SPELL.Description     = [[Illuminates the area around you.]]
local LIGHT_RADIUS  = 250
local LIGHT_SECONDS = 5

SPELL.Fire            = function (ply, wpn, charge_stage)
    ply:EmitSound("ambient/fire/mtov_flame2.wav")
    local pos = ply:GetPos()
    pos.z = pos.z + 50
    local light = ents.Create("light_dynamic")
	light:SetKeyValue("brightness", "8")
	light:SetKeyValue("distance", tostring(LIGHT_RADIUS))
	light:SetLocalPos(pos)
	light:SetLocalAngles( ply:EyeAngles() )
	light:Fire("Color", "255 255 200")
	light:Spawn()
	light:Activate()
	light:Fire("TurnOn", "", 0)
	light:Fire("Kill", "", LIGHT_SECONDS)

    if HORDE:IsPlayerSpellcaster(ply) then
        for _, ent in ipairs(ents.FindInSphere(pos, LIGHT_RADIUS)) do
            if HORDE:IsEnemy(ent) and ent:Health() > 0 then
                ent:Horde_AddFearStack(ply, true)
            end
        end
    end
end
SPELL.Price = 0
