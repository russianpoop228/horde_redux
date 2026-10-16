AddCSLuaFile()

if CLIENT then
    SWEP.PrintName          = "Tank Mine"
    SWEP.Slot               = 4
    SWEP.SlotPos            = 4
    SWEP.WepSelectIcon      = surface.GetTextureID("items/hl2/weapon_slam.png")
end

SWEP.Base               = "weapon_base"
SWEP.Category           = "HORDE: Sapper"
SWEP.Spawnable          = true
SWEP.UseHands           = true

SWEP.ViewModel          = "models/weapons/c_grenade.mdl"
SWEP.WorldModel         = "models/mechanics/wheels/wheel_smooth_18r.mdl"
SWEP.ViewModelFOV       = 60

SWEP.ThrowEntity        = "ent_tank_mine"

SWEP.Primary.ClipSize     = -1
SWEP.Primary.DefaultClip  = 1
SWEP.Primary.Automatic    = false
SWEP.Primary.Ammo         = "RPG_Round"
SWEP.Primary.MaxAmmo      = 5

SWEP.Secondary.ClipSize   = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo       = "none"

function SWEP:Initialize()
    self:SetHoldType("grenade")
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_DRAW)

    if CLIENT then
        local vm = self:GetOwner():GetViewModel()
        if IsValid(vm) then
            local bone = vm:LookupBone("ValveBiped.Grenade_Body")
            if bone then
                vm:ManipulateBoneScale(bone, Vector(0, 0, 0))
            end
        end
    end
    return true
end

function SWEP:Holster()
    if CLIENT and IsValid(self.ClientModel) then
        self.ClientModel:Remove()
        self.ClientModel = nil
    end

    if CLIENT and IsValid(self:GetOwner()) then
        local vm = self:GetOwner():GetViewModel()
        if IsValid(vm) then
            local bone = vm:LookupBone("ValveBiped.Grenade_Body")
            if bone then
                vm:ManipulateBoneScale(bone, Vector(1, 1, 1))
            end
        end
    end
    return true
end

function SWEP:OnRemove()
    self:Holster()
end

function SWEP:PrimaryAttack()
    if self:Ammo1() <= 0 then
        self:EmitSound("Weapon_Pistol.Empty")
        return
    end

    self:SendWeaponAnim(ACT_VM_PULLPIN)

    timer.Simple(0.1, function()
        if not IsValid(self) then return end
        self:SendWeaponAnim(ACT_VM_THROW)
        self:GetOwner():SetAnimation(PLAYER_ATTACK1)

        timer.Simple(0.3, function()
            if not IsValid(self) then return end
            self:ThrowMine()
        end)
    end)

    self:SetNextPrimaryFire(CurTime() + 1.5)
end

function SWEP:ThrowMine()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    if SERVER then
        local ent = ents.Create(self.ThrowEntity)
        if IsValid(ent) then
            local src = ply:GetShootPos() + ply:GetAimVector() * 20 + ply:GetUp() * 5

            ent:SetPos(src)
            ent:SetAngles(ply:GetAngles())
            ent:SetOwner(ply)
            ent:Spawn()
            ent:Activate()

            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                local force = 400
                phys:SetVelocity(ply:GetAimVector() * force + ply:GetVelocity())
                phys:AddAngleVelocity(Vector(0, 500, 0))
            end

            self:TakePrimaryAmmo(1)
        end
    end

    timer.Simple(0.6, function()
        if IsValid(self) and self:Ammo1() > 0 then
            self:SendWeaponAnim(ACT_VM_DRAW)
        end
    end)
end

function SWEP:SecondaryAttack() end

if CLIENT then
    local VM_OFFSET = Vector(4, -3, 0)
    local VM_ANGLE  = Angle(90, 25, 0)
    local VM_SCALE  = 0.3

    local WM_OFFSET = Vector(3, 2, -1)
    local WM_ANGLE  = Angle(0, 0, 0)
    local WM_SCALE  = 0.3

    local MAT_ICE = "models/player/shared/ice_player"

    function SWEP:PostDrawViewModel(vm, weapon, ply)
        if not IsValid(vm) then return end

        if not IsValid(self.ClientModel) then
            self.ClientModel = ClientsideModel("models/mechanics/wheels/wheel_smooth_18r.mdl", RENDERGROUP_OPAQUE)
            self.ClientModel:SetNoDraw(true)
            self.ClientModel:SetModelScale(VM_SCALE)
            self.ClientModel:SetMaterial(MAT_ICE)
        end

        local boneid = vm:LookupBone("ValveBiped.Bip01_R_Hand")
        if not boneid then return end

        local matrix = vm:GetBoneMatrix(boneid)
        if not matrix then return end

        local newPos, newAng = LocalToWorld(VM_OFFSET, VM_ANGLE, matrix:GetTranslation(), matrix:GetAngles())

        self.ClientModel:SetPos(newPos)
        self.ClientModel:SetAngles(newAng)
        self.ClientModel:DrawModel()
    end

    function SWEP:DrawWorldModel()
        local ply = self:GetOwner()
        if not IsValid(ply) then
            self:SetMaterial(MAT_ICE)
            self:SetModelScale(0.5)
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

        self:SetMaterial(MAT_ICE)
        self:DrawModel()

        self:DisableMatrix("RenderMultiply")
    end
end
