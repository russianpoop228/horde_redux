include("shared.lua")

local SHIELD_MAT = Material("models/props_combine/portalball001_sheet")

local function DrawPrinceShield()
    for _, ent in ipairs(ents.FindByClass("npc_vj_horde_blue_prince")) do
        if IsValid(ent) and ent:GetNWBool("Horde_PrinceShield") then
            local col_min, col_max = ent:GetCollisionBounds()
            local radius = col_max:Distance(col_min) / 2
            local height = math.abs(col_min.z - col_max.z)

            render.SetMaterial(SHIELD_MAT)
            local pos = ent:GetPos()
            pos.z = pos.z + height / 2
            render.DrawSphere(pos, radius + 5, 50, 50)
        end
    end
end

hook.Add("PostDrawTranslucentRenderables", "Horde_BluePrinceShieldDraw", DrawPrinceShield)
