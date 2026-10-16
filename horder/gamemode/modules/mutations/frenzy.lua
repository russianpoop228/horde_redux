MUTATION.PrintName = "Frenzy"
MUTATION.Description = "50% increased action speed."

MUTATION.Hooks = {}

local TRAIL_TEXTURE = "trails/tube"
local TRAIL_COLOR   = Color(200, 50, 50)

local function StopTrail(ent)
    if IsValid(ent.Horde_FrenzyTrail) then
        ent.Horde_FrenzyTrail:Remove()
    end
    ent.Horde_FrenzyTrail = nil
end

MUTATION.Hooks.Horde_OnSetMutation = function(ent, mutation)
    if mutation == "frenzy" then
        if SERVER then
            if ent.AnimationPlaybackRate then
                ent.AnimationPlaybackRate = ent.AnimationPlaybackRate * 1.5
            else
                ent:SetPlaybackRate(ent:GetPlaybackRate() * 1.5)
            end

            StopTrail(ent)
            ent.Horde_FrenzyTrail = util.SpriteTrail(ent, 0, TRAIL_COLOR, false, 14, 2, 0.4, 1 / 16 * 0.5, TRAIL_TEXTURE)
            ent:CallOnRemove("Horde_FrenzyTrail", function() StopTrail(ent) end)

            local e = EffectData()
                e:SetOrigin(ent:GetPos())
                e:SetEntity(ent)
            util.Effect("frenzy", e, true, true)
        end
    end
end

MUTATION.Hooks.Horde_OnUnsetMutation = function (ent, mutation)
    if not ent:IsValid() or mutation ~= "frenzy" then return end
    if SERVER then StopTrail(ent) end
    if ent.AnimationPlaybackRate then
        ent.AnimationPlaybackRate = ent.AnimationPlaybackRate / 1.5
    else
        ent:SetPlaybackRate(ent:GetPlaybackRate() / 1.5)
    end
end
