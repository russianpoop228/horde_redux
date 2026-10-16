AddCSLuaFile()

if CLIENT then
    SWEP.PrintName     = "Combine Tripmine"
    SWEP.Slot          = 4
    SWEP.SlotPos       = 2
    SWEP.WepSelectIcon = surface.GetTextureID("hl1/icons/tripmine")
end

SWEP.Base         = "weapon_base"
SWEP.Category     = "Half-Life 2"
SWEP.Spawnable    = true
SWEP.UseHands     = true

SWEP.ViewModel    = "models/weapons/c_slam.mdl"
SWEP.WorldModel   = "models/props_combine/combine_mine01.mdl"
SWEP.ViewModelFOV = 60

SWEP.ThrowEntity  = "ent_combine_tripmine"

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo        = "AR2"
SWEP.Primary.MaxAmmo     = 15

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo        = "none"

function SWEP:Initialize()
    self:SetHoldType("slam")
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_DRAW)
    return true
end

function SWEP:Holster()
    if CLIENT and IsValid(self.ClientMineModel) then
        self.ClientMineModel:Remove()
        self.ClientMineModel = nil
    end
    return true
end

function SWEP:OnRemove()
    self:Holster()
end

function SWEP:PrimaryAttack()
    if self:Ammo1() <= 0 then
        self:EmitSound("Weapon_Pistol.Empty")
        self:SetNextPrimaryFire(CurTime() + 0.2)
        return
    end

    local ply = self:GetOwner()
    local tr = util.TraceLine({
        start = ply:GetShootPos(),
        endpos = ply:GetShootPos() + ply:GetAimVector() * 128,
        filter = ply
    })

    if tr.HitWorld then
        self:SetNextPrimaryFire(CurTime() + 1.0)

        self:SendWeaponAnim(ACT_VM_THROW)
        ply:SetAnimation(PLAYER_ATTACK1)

        timer.Simple(0.3, function()
            if not IsValid(self) or not IsValid(ply) or ply:GetActiveWeapon() ~= self then return end

            local tr2 = util.TraceLine({
                start = ply:GetShootPos(),
                endpos = ply:GetShootPos() + ply:GetAimVector() * 128,
                filter = ply
            })

            if tr2.HitWorld then
                if SERVER then
                    local ang = tr2.HitNormal:Angle()
                    ang:RotateAroundAxis(ang:Right(), -90)

                    local pEnt = ents.Create(self.ThrowEntity)
                    if IsValid(pEnt) then
                        pEnt:SetPos(tr2.HitPos + tr2.HitNormal * 2)
                        pEnt:SetAngles(ang)
                        pEnt:SetOwner(ply)
                        pEnt:Spawn()
                        pEnt:Activate()
                        pEnt:EmitSound("buttons/lever6.wav")

                        self:TakePrimaryAmmo(1)
                    end
                end

                self:SendWeaponAnim(ACT_VM_DRAW)
            end
        end)
    else
        self:EmitSound("common/wpn_denyselect.wav")
        self:SetNextPrimaryFire(CurTime() + 0.5)
    end
end

function SWEP:SecondaryAttack()
end

if CLIENT then

    local VM_OFFSET = Vector(0, 0, 5)
    local VM_ANGLE  = Angle(210, 90, 0)
    local VM_SCALE  = 0.7

    local WM_OFFSET = Vector(4, -2, -2)
    local WM_ANGLE  = Angle(-20, 180, 0)
    local WM_SCALE  = 0.5

    function SWEP:PreDrawViewModel(vm, weapon, ply)
        render.SetBlend(0)
    end

    function SWEP:PostDrawViewModel(vm, weapon, ply)
        render.SetBlend(1)
        if not IsValid(vm) then return end

        if not IsValid(self.ClientMineModel) then
            self.ClientMineModel = ClientsideModel("models/props_combine/combine_mine01.mdl", RENDERGROUP_OPAQUE)
            self.ClientMineModel:SetNoDraw(true)
            self.ClientMineModel:SetModelScale(VM_SCALE)
        end

        local boneid = vm:LookupBone("ValveBiped.Bip01_R_Hand")
        if not boneid then return end

        local matrix = vm:GetBoneMatrix(boneid)
        if not matrix then return end

        local newPos, newAng = LocalToWorld(VM_OFFSET, VM_ANGLE, matrix:GetTranslation(), matrix:GetAngles())

        self.ClientMineModel:SetPos(newPos)
        self.ClientMineModel:SetAngles(newAng)
        self.ClientMineModel:DrawModel()
    end

    function SWEP:DrawWorldModel()
        local ply = self:GetOwner()

        if not IsValid(ply) then
            self:SetRenderOrigin(nil)
            self:SetRenderAngles(nil)
            self:DrawModel()
            return
        end

        local boneid = ply:LookupBone("ValveBiped.Bip01_R_Hand")
        if not boneid then self:DrawModel() return end

        local matrix = ply:GetBoneMatrix(boneid)
        if not matrix then self:DrawModel() return end

        local newPos, newAng = LocalToWorld(WM_OFFSET, WM_ANGLE, matrix:GetTranslation(), matrix:GetAngles())

        self:SetRenderOrigin(newPos)
        self:SetRenderAngles(newAng)

        local mat = Matrix()
        mat:Scale(Vector(WM_SCALE, WM_SCALE, WM_SCALE))
        self:EnableMatrix("RenderMultiply", mat)

        self:DrawModel()

        self:DisableMatrix("RenderMultiply")
    end
end
