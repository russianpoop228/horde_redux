AddCSLuaFile()

if CLIENT then
    SWEP.PrintName     = "Super Mine"
    SWEP.Slot          = 4
    SWEP.SlotPos       = 6
    SWEP.WepSelectIcon = surface.GetTextureID("items/hl2/weapon_slam.png")
end

SWEP.Base      = "weapon_base"
SWEP.Category  = "HORDE: Sapper"
SWEP.Spawnable = false
SWEP.UseHands  = true

SWEP.ViewModel    = "models/weapons/c_grenade.mdl"
SWEP.WorldModel   = "models/sapper/seabomb.mdl"
SWEP.ViewModelFOV = 60

SWEP.ThrowEntity = "ent_super_mine"

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo        = "none"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo        = "none"

function SWEP:Initialize()
    self:SetHoldType("grenade")
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_VM_DRAW)
    if CLIENT then
        local vm = self:GetOwner() and self:GetOwner():GetViewModel()
        if IsValid(vm) then
            local bone = vm:LookupBone("ValveBiped.Grenade_Body")
            if bone then vm:ManipulateBoneScale(bone, Vector(0, 0, 0)) end
        end
    end
    return true
end

function SWEP:Holster()
    if CLIENT then
        if IsValid(self.ClientModel) then
            self.ClientModel:Remove()
            self.ClientModel = nil
        end
        local ply = self:GetOwner()
        if IsValid(ply) then
            local vm = ply:GetViewModel()
            if IsValid(vm) then
                local bone = vm:LookupBone("ValveBiped.Grenade_Body")
                if bone then vm:ManipulateBoneScale(bone, Vector(1, 1, 1)) end
            end
        end
    end
    return true
end

function SWEP:OnRemove()
    self:Holster()
end

function SWEP:PrimaryAttack()
    if self:Clip1() == 0 and self:Ammo1() <= 0 then
        self:EmitSound("Weapon_Pistol.Empty")
        return
    end

    self:SendWeaponAnim(ACT_VM_PULLPIN)

    timer.Simple(0.1, function()
        if not IsValid(self) then return end
        self:SendWeaponAnim(ACT_VM_THROW)
        local ply = self:GetOwner()
        if IsValid(ply) then ply:SetAnimation(PLAYER_ATTACK1) end

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
            local src = ply:GetShootPos() + ply:GetAimVector() * 24 + ply:GetUp() * 5
            ent:SetPos(src)
            ent:SetAngles(ply:GetAngles())
            ent:SetOwner(ply)
            ent.Horde_Owner = ply
            ent:Spawn()
            ent:Activate()

            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(ply:GetAimVector() * 900 + ply:GetVelocity())
                phys:AddAngleVelocity(Vector(0, 400, 0))
            end

            ply:StripWeapon(self:GetClass())
        end
    end
end

function SWEP:SecondaryAttack() end

if CLIENT then
    local VM_OFFSET = Vector(3, -3, 1)
    local VM_ANGLE  = Angle(90, 0, 0)
    local VM_SCALE  = 0.6

    local WM_OFFSET = Vector(3, 2, -1)
    local WM_ANGLE  = Angle(0, 0, 180)
    local WM_SCALE  = 0.6

    function SWEP:PostDrawViewModel(vm, weapon, ply)
        if not IsValid(vm) then return end

        if not IsValid(self.ClientModel) then
            self.ClientModel = ClientsideModel("models/sapper/seabomb.mdl", RENDERGROUP_OPAQUE)
            self.ClientModel:SetNoDraw(true)
            self.ClientModel:SetModelScale(VM_SCALE)
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
        if not IsValid(ply) then self:DrawModel() return end

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
