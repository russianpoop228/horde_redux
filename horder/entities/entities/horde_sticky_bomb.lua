AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Spawnable = false

local TRAIL_TEXTURE = "effects/reactive_mine/glow01.vmt"
local TRAIL_COLOR   = Color(255, 80, 80)
local BLAST_RADIUS  = 150
local BLAST_DAMAGE  = 200
function ENT:Draw()
    self:DrawModel()
end

function ENT:Initialize()
    if not SERVER then return end

    self:SetModel("models/horde/stickybomb/stickybomb.mdl")
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
    self:DrawShadow( false )

    self.Horde_Trail = util.SpriteTrail(self, 0, TRAIL_COLOR, true, 6, 0, 0.15, 1 / 6 * 0.5, TRAIL_TEXTURE)
end

function ENT:StopTrail()
    if IsValid(self.Horde_Trail) then
        self.Horde_Trail:Remove()
    end
    self.Horde_Trail = nil
end

function ENT:Detonate()
    self:Remove()
end

function ENT:RemoveSilently()
    self.Horde_Silent = true
    self:Remove()
end

function ENT:Think()
    if not SERVER then return end
    if self.Horde_StuckTo and not IsValid(self.Horde_StuckTo) then
        self:RemoveSilently()
    end
end

function ENT:PhysicsCollide(coldata, collider)
    if not SERVER then return end
    if self.Horde_Stuck then return end
    self.Horde_Stuck = true

    local hit_entity = coldata.HitEntity

    timer.Simple(0, function()
        if not IsValid(self) then return end
        self:SetMoveType( MOVETYPE_NONE )
        self:SetSolid( SOLID_NONE )
        self:PhysicsInit( SOLID_NONE )
        self:SetCollisionGroup( COLLISION_GROUP_NONE )
        self:StopTrail()
        if IsValid(hit_entity) and hit_entity:IsNPC() then
            self:SetParent(hit_entity, 0)
            self.Horde_StuckTo = hit_entity
        end
    end)
end

function ENT:OnRemove()
    if not SERVER then return end
    self:StopTrail()
    if self.Horde_Silent then return end

    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    util.Effect( "Explosion", effectdata )
    util.BlastDamage(self, self:GetOwner(), self:GetPos(), BLAST_RADIUS, BLAST_DAMAGE)
end

if SERVER then
    hook.Add("PlayerDisconnected", "Horde_StickyBombs_Cleanup", function(ply)
        for _, bomb in ipairs(ents.FindByClass("horde_sticky_bomb")) do
            if bomb:GetOwner() == ply then
                bomb:RemoveSilently()
            end
        end
    end)
end
