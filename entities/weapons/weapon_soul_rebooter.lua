AddCSLuaFile()

SWEP.Base           = "weapon_base"
SWEP.PrintName      = "Soul Rebooter"
SWEP.Category       = "Horde"
SWEP.Spawnable      = true
SWEP.AdminOnly      = false
SWEP.DrawCrosshair  = false
SWEP.UseHands       = true
SWEP.HoldType       = "slam"

SWEP.Description = [[
Opens the Resurrection menu. Choose 1 fallen ally to bring back to life.

Place a Soul Rebooter pylon on the ground.
When the timer finishes, the ally is revived at the pylon.

If the pylon is destroyed before the timer ends, it explodes.

Each successful placement consumes 1 charge. 
Charges are shop-only and cannot be replenished by Ammo Boxes.
]]
SWEP.Instructions   = "Primary: open resurrection menu / confirm placement.\nSecondary: cancel placement."
SWEP.Purpose        = "Resurrect a fallen ally by placing a timed pylon."

SWEP.ViewModel      = "models/weapons/c_slam.mdl"
SWEP.WorldModel     = "models/props_lab/tpplugholder_single.mdl"
SWEP.ViewModelFOV   = 67

local CFG = HordeSoulRebooterConfig or {}
local MAX_CHARGES = CFG.MaxCharges or 3

SWEP.Primary.ClipSize     = -1
SWEP.Primary.DefaultClip  = MAX_CHARGES
SWEP.Primary.Automatic    = false
SWEP.Primary.Ammo         = "AlyxGun"
SWEP.Primary.MaxAmmo      = 3
SWEP.Primary.Delay        = 0.5

SWEP.Secondary.ClipSize   = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo       = "none"
SWEP.Secondary.Delay      = 0.5

local PYLON_CLASS      = "horde_soul_rebooter_pylon"
local PLACEMENT_RANGE  = 128
local MODEL_HELD       = "models/props_lab/tpplugholder_single.mdl"

function SWEP:SetupDataTables()
    self:NetworkVar("Bool",   0, "Placing")
    self:NetworkVar("Entity", 0, "SelectedTarget")
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self:SetPlacing(false)
    self:SetSelectedTarget(NULL)
    self._SoulRebooterAmmoInitialized = false
end

function SWEP:CustomAmmoDisplay()
    self.AmmoDisplay = self.AmmoDisplay or {}
    self.AmmoDisplay.Draw = true
    self.AmmoDisplay.PrimaryClip = self:Ammo1()
    return self.AmmoDisplay
end

function SWEP:EnsureCharges()
    if CLIENT then return end
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    local ammoType = self.Primary.Ammo
    local want = MAX_CHARGES
    local have = ply:GetAmmoCount(ammoType)

    if have > 0 then
        self._SoulRebooterAmmoGranted = true
        return
    end

    if self._SoulRebooterAmmoGranted then return end

    ply:SetAmmo(want, ammoType)
    self._SoulRebooterAmmoGranted = true
end

function SWEP:Equip(newOwner)
    if not SERVER then return end
    if not IsValid(newOwner) then return end
    self:SetOwner(newOwner)
    self._SoulRebooterAmmoGranted = nil
    self:EnsureCharges()
end

function SWEP:Deploy()
    if SERVER then
        self:EnsureCharges()
    end

    self:SendWeaponAnim(ACT_VM_DRAW)
    self:SetNextPrimaryFire(CurTime() + 0.5)
    self:SetNextSecondaryFire(CurTime() + 0.5)
    return true
end

function SWEP:Holster()
    if SERVER then
        self:StopPlacement()
    end
    if CLIENT then
        self:CleanupClientModels()
    end
    return true
end

function SWEP:OnRemove()
    if SERVER then
        self:StopPlacement()
    end
    if CLIENT then
        self:CleanupClientModels()
    end
end

function SWEP:OnDrop()
    if SERVER then
        self:StopPlacement()
    end
end

function SWEP:PrimaryAttack()
    local delay = (self.Primary and self.Primary.Delay) or 0.5
    self:SetNextPrimaryFire(CurTime() + delay)
end

function SWEP:SecondaryAttack()
    local delay = (self.Secondary and self.Secondary.Delay) or 0.5
    self:SetNextSecondaryFire(CurTime() + delay)
end

function SWEP:Reload()
end

if SERVER then

    local function SoulRebooterNotify(ply, key, fallback, isErr)
        if not IsValid(ply) then return end
        local msg = fallback
        if translate and translate.ClientGet then
            local ok, value = pcall(translate.ClientGet, ply, key)
            if ok and isstring(value) and value ~= "" and value ~= key then
                msg = value
            end
        end
        if HORDE and HORDE.SendNotification then
            HORDE:SendNotification(msg, isErr and 1 or 0, ply)
        end
    end

    local function GetEligibleDead(ply)
        local list = {}
        for _, other in ipairs(player.GetAll()) do
            if IsValid(other)
                and other ~= ply
                and not other:Alive()
                and other:Team() ~= TEAM_SPECTATOR
            then
                list[#list + 1] = other
            end
        end
        return list
    end

    local function OpenMenuFor(ply, wpn)
        local dead = GetEligibleDead(ply)
        if #dead == 0 then
            if HORDE and HORDE.SendNotification then
                SoulRebooterNotify(ply, "SoulRebooter_NoPlayers", "No players available for resurrection.", true)
            end
            ply:EmitSound("buttons/combine_button2.wav")
            return false
        end

        ply._SoulRebooterWeapon = wpn

        net.Start("Horde_SoulRebooterSWEP_OpenMenu")
            net.WriteUInt(#dead, 8)
            for _, t in ipairs(dead) do
                net.WriteEntity(t)
            end
        net.Send(ply)
        return true
    end

    function SWEP:StopPlacement()
        if IsValid(self._Ghost) then
            self._Ghost:Remove()
        end
        self._Ghost = nil
        if timer.Exists("Horde_SoulRebooter_Ghost_" .. self:EntIndex()) then
            timer.Remove("Horde_SoulRebooter_Ghost_" .. self:EntIndex())
        end
        if IsValid(self) then
            self:SetPlacing(false)
            self:SetSelectedTarget(NULL)
        end
        local owner = self:GetOwner()
        if IsValid(owner) and owner._SoulRebooterWeapon == self then
            owner._SoulRebooterWeapon = nil
        end
    end

    local function PlacementTrace(ply)
        return util.TraceLine({
            start  = ply:GetShootPos(),
            endpos = ply:GetShootPos() + ply:GetAimVector() * PLACEMENT_RANGE,
            filter = ply,
            mask   = MASK_SOLID
        })
    end

    local function IsValidPlacement(tr)
        if not tr.Hit then return false end
        if tr.HitNormal.z < 0.65 then return false end
        if tr.HitSky then return false end
        return true
    end

    local function AlignModelToCursor(ent, hitPos, ang)
        if not IsValid(ent) then return end
        ent:SetAngles(ang)
        ent:SetPos(hitPos)
        local center = ent:WorldSpaceCenter()
        local dx = hitPos.x - center.x
        local dy = hitPos.y - center.y
        if math.abs(dx) > 0.01 or math.abs(dy) > 0.01 then
            ent:SetPos(ent:GetPos() + Vector(dx, dy, 0))
        end
    end

    local function UpdateGhost(self)
        if not IsValid(self) or not self:GetPlacing() then return end
        local ply = self:GetOwner()
        if not IsValid(ply) then
            self:StopPlacement()
            return
        end

        local tr = PlacementTrace(ply)
        if IsValidPlacement(tr) then
            if not IsValid(self._Ghost) then
                self._Ghost = ents.Create("prop_physics")
                if not IsValid(self._Ghost) then return end
                self._Ghost:SetModel(MODEL_HELD)
                self._Ghost:SetRenderMode(RENDERMODE_TRANSCOLOR)
                self._Ghost:SetColor(Color(80, 255, 80, 160))
                self._Ghost:SetCollisionGroup(COLLISION_GROUP_WORLD)
                self._Ghost:SetMoveType(MOVETYPE_NONE)
                self._Ghost:SetSolid(SOLID_NONE)
                self._Ghost:Spawn()
                self._Ghost:SetNotSolid(true)
                local phys = self._Ghost:GetPhysicsObject()
                if IsValid(phys) then
                    phys:EnableMotion(false)
                    phys:Sleep()
                end
            end
            local pos = tr.HitPos + tr.HitNormal
            local ang = Angle(CFG.ModelPitchFix or 0, ply:EyeAngles().y, 0)
            AlignModelToCursor(self._Ghost, pos, ang)
            self._Ghost:SetColor(Color(100, 255, 100, 120))
        else
            if IsValid(self._Ghost) then
                self._Ghost:SetColor(Color(255, 60, 60, 100))
            end
        end
    end

    function SWEP:StartPlacement(target)
        if not IsValid(target) then return end
        self:SetSelectedTarget(target)
        self:SetPlacing(true)

        local id = "Horde_SoulRebooter_Ghost_" .. self:EntIndex()
        timer.Create(id, 0.1, 0, function()
            if not IsValid(self) then
                timer.Remove(id)
                return
            end
            UpdateGhost(self)
        end)

        if HORDE and HORDE.SendNotification then
            SoulRebooterNotify(self:GetOwner(), "SoulRebooter_AimPlace", "Aim at the ground and press Primary to place. Secondary cancels.", false)
        end
    end

    function SWEP:ConfirmPlacement()
        local ply = self:GetOwner()
        if not IsValid(ply) then return end
        self:EnsureCharges()
        if self:Ammo1() <= 0 then return end

        local target = self:GetSelectedTarget()
        if not IsValid(target) or target:Alive() or target:Team() == TEAM_SPECTATOR then
            if HORDE and HORDE.SendNotification then
                SoulRebooterNotify(ply, "SoulRebooter_TargetInvalid", "Selected player is no longer valid.", true)
            end
            self:StopPlacement()
            return
        end

        local tr = PlacementTrace(ply)
        if not IsValidPlacement(tr) then
            self:EmitSound("common/wpn_denyselect.wav")
            return
        end

        self:TakePrimaryAmmo(1)

        local pos = tr.HitPos + tr.HitNormal
        local ang = Angle(CFG.ModelPitchFix or 0, ply:EyeAngles().y, 0)
        if IsValid(self._Ghost) then
            pos = self._Ghost:GetPos()
            ang = self._Ghost:GetAngles()
        end

        local ent = ents.Create(PYLON_CLASS)
        if not IsValid(ent) then
            if IsValid(ply) then
                ply:GiveAmmo(1, self.Primary.Ammo, true)
            end
            self:StopPlacement()
            return
        end

        ent:SetAngles(ang)
        ent:SetPos(pos)
        ent._SoulAnchorPos = pos
        ent._SoulAnchorAng = ang
        ent:SetOwner(ply)
        ent:SetNWEntity("HordeOwner", ply)
        ent:SetNWEntity("HordeSoulTarget", target)
        ent:SetNWString("HordeSoulTargetName", target:Nick())
        ent:Spawn()
        ent:Activate()
        AlignModelToCursor(ent, pos, ang)

        sound.Play("buttons/lever6.wav", pos, 70, 100)

        self:StopPlacement()
        self:SendWeaponAnim(ACT_VM_DRAW)
    end

    function SWEP:PrimaryAttack()
        local ply = self:GetOwner()
        if not IsValid(ply) then return end

        self:SetNextPrimaryFire(CurTime() + ((self.Primary and self.Primary.Delay) or 0.5))
        self:EnsureCharges()

        if self:GetPlacing() then
            self:ConfirmPlacement()
            return
        end

        if self:Ammo1() <= 0 then
            self:EmitSound("Weapon_Pistol.Empty")
            return
        end

        OpenMenuFor(ply, self)
    end

    function SWEP:SecondaryAttack()
        self:SetNextSecondaryFire(CurTime() + ((self.Secondary and self.Secondary.Delay) or 0.5))
        if self:GetPlacing() then
            self:StopPlacement()
            if HORDE and HORDE.SendNotification then
                SoulRebooterNotify(self:GetOwner(), "SoulRebooter_Cancelled", "Placement cancelled.", false)
            end
        end
    end

    hook.Add("PlayerDeath", "Horde_SoulRebooterSWEP_Death", function(ply)
        local wpn = ply:GetWeapon("weapon_soul_rebooter")
        if IsValid(wpn) then
            wpn:StopPlacement()
        end
    end)

    hook.Add("PlayerDisconnected", "Horde_SoulRebooterSWEP_Disconnect", function(ply)
        local wpn = ply:GetWeapon("weapon_soul_rebooter")
        if IsValid(wpn) then
            wpn:StopPlacement()
        end
    end)
end

if CLIENT then

    local VM_OFFSET = Vector(6, -2, -4)
    local VM_ANGLE  = Angle(0, 270, 90)
    local VM_SCALE  = 0.55

    local WM_OFFSET = Vector(4, -1, -4)
    local WM_ANGLE  = Angle(-10, 180, 0)
    local WM_SCALE  = 0.45

    function SWEP:CleanupClientModels()
        if IsValid(self.ClientMineModel) then
            self.ClientMineModel:Remove()
            self.ClientMineModel = nil
        end
    end

    function SWEP:PreDrawViewModel(vm, weapon, ply)
        render.SetBlend(0)
    end

    function SWEP:PostDrawViewModel(vm, weapon, ply)
        render.SetBlend(1)
        if not IsValid(vm) then return end

        if not IsValid(self.ClientMineModel) then
            self.ClientMineModel = ClientsideModel(MODEL_HELD, RENDERGROUP_OPAQUE)
            if IsValid(self.ClientMineModel) then
                self.ClientMineModel:SetNoDraw(true)
                self.ClientMineModel:SetModelScale(VM_SCALE, 0)
            end
        end
        if not IsValid(self.ClientMineModel) then return end

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
        if not boneid then
            self:DrawModel()
            return
        end

        local matrix = ply:GetBoneMatrix(boneid)
        if not matrix then
            self:DrawModel()
            return
        end

        local newPos, newAng = LocalToWorld(WM_OFFSET, WM_ANGLE, matrix:GetTranslation(), matrix:GetAngles())
        self:SetRenderOrigin(newPos)
        self:SetRenderAngles(newAng)

        local mat = Matrix()
        mat:Scale(Vector(WM_SCALE, WM_SCALE, WM_SCALE))
        self:EnableMatrix("RenderMultiply", mat)
        self:DrawModel()
        self:DisableMatrix("RenderMultiply")
    end

    local function SoulRebooterText(key, fallback)
        if translate and translate.Get then
            local ok, value = pcall(translate.Get, key)
            if ok and isstring(value) and value ~= "" and value ~= key then
                return value
            end
        end
        return fallback
    end

    local font = (translate and translate.GetFont and translate.GetFont()) or "Roboto"

    surface.CreateFont("SoulRebooter_Title",    { font = font, size = 24, weight = 600, extended = true })
    surface.CreateFont("SoulRebooter_Subtitle", { font = font, size = 19, weight = 400, extended = true })
    surface.CreateFont("SoulRebooter_Name",     { font = font, size = 18, weight = 400, extended = true })
    surface.CreateFont("SoulRebooter_Button",   { font = font, size = 22, weight = 500, extended = true })

    local COL_RED        = Color(199, 15, 46, 255)
    local COL_RED_HOVER  = Color(175, 12, 38, 255)
    local COL_BG         = Color(29, 29, 29, 255)
    local COL_TRACK      = Color(56, 56, 56, 255)
    local COL_TEXT       = Color(255, 255, 255, 255)
    local COL_HOVER_ROW  = Color(255, 255, 255, 8)

    local MAX_TARGETS_CL = 1
    local MIN_TARGETS_CL = 1

    local frame

    local function GetPlayerClassIcon(ply)
        if not IsValid(ply) or ply:IsBot() then
            local sub = HORDE and HORDE.subclasses and (HORDE.subclasses["Survivor"] or HORDE.subclasses[HORDE.Class_Survivor])
            if sub and sub.Icon then
                return Material(sub.Icon, "mips smooth")
            end
            return Material("Survivor.png", "mips smooth")
        end

        local subclass_name = ply.Horde_GetCurrentSubclass and ply:Horde_GetCurrentSubclass() or nil
        if subclass_name and HORDE and HORDE.subclasses and HORDE.subclasses[subclass_name] then
            local icon = HORDE.subclasses[subclass_name].Icon
            if icon then
                return Material(icon, "mips smooth")
            end
        end

        if ply.Horde_GetClass and ply:Horde_GetClass() then
            local cls = ply:Horde_GetClass()
            if cls.icon then
                return Material(cls.icon, "mips smooth")
            end
            if cls.name and HORDE and HORDE.subclasses and HORDE.subclasses[cls.name] and HORDE.subclasses[cls.name].Icon then
                return Material(HORDE.subclasses[cls.name].Icon, "mips smooth")
            end
        end

        return Material("Survivor.png", "mips smooth")
    end

    local function OpenSoulRebooterMenu(deadPlayers)
        if IsValid(frame) then frame:Close() end

        local W, H = 360, 480

        frame = vgui.Create("DFrame")
        frame:SetSize(W, H)
        frame:Center()
        frame:SetTitle("")
        frame:ShowCloseButton(false)
        frame:SetDraggable(true)
        frame:MakePopup()
        frame:SetKeyboardInputEnabled(false)
        frame:SetMouseInputEnabled(true)
        frame:DockPadding(0, 0, 0, 0)
        frame.selected = {}
        frame.committed = false

        frame.Paint = function(self, w, h)
            draw.RoundedBox(10, 0, 0, w, h, COL_RED)
            draw.RoundedBox(8, 2, 2, w - 4, h - 4, COL_BG)
        end

        local function RequestClose()
            frame:Close()
        end

        frame.Think = function(self)
            if input.IsKeyDown(KEY_ESCAPE) then
                if not self._escHeld then
                    self._escHeld = true
                    RequestClose()
                end
            else
                self._escHeld = false
            end
        end

        local header = vgui.Create("DPanel", frame)
        header:SetTall(52)
        header:Dock(TOP)
        header.Paint = function(self, w, h)
            draw.RoundedBoxEx(8, 2, 2, w - 4, h - 2, COL_RED, true, true, false, false)
            draw.SimpleText(SoulRebooterText("SoulRebooter_MenuTitle", "Soul Rebooter"), "SoulRebooter_Title", w / 2, (h + 2) / 2, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local closeBtn = vgui.Create("DButton", header)
        closeBtn:SetText("")
        closeBtn:SetSize(30, 30)
        closeBtn:SetPos(W - 40, 11)
        closeBtn.Paint = function(self, w, h)
            local col = self:IsHovered() and Color(255, 255, 255, 255) or COL_TEXT
            draw.SimpleText("✕", "SoulRebooter_Subtitle", w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        closeBtn.DoClick = RequestClose

        local sub = vgui.Create("DPanel", frame)
        sub:SetTall(42)
        sub:Dock(TOP)
        sub.Paint = function(self, w, h)
            draw.SimpleText(SoulRebooterText("SoulRebooter_SelectHint", "Select a fallen ally"), "SoulRebooter_Subtitle", w / 2, h / 2, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:Dock(FILL)
        scroll:DockMargin(2, 4, 6, 4)

        local sbar = scroll:GetVBar()
        sbar:SetWide(7)
        sbar.Paint = function() end
        sbar.btnUp.Paint = function() end
        sbar.btnDown.Paint = function() end
        sbar.btnGrip.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, COL_RED)
        end

        local progressWrap = vgui.Create("DPanel", frame)
        progressWrap:SetTall(8)
        progressWrap:Dock(BOTTOM)
        progressWrap:DockMargin(16, 0, 16, 14)
        progressWrap.frac = 0
        progressWrap.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, COL_TRACK)
            if self.frac > 0 then
                draw.RoundedBox(4, 0, 0, w * self.frac, h, COL_RED)
            end
        end

        local btn = vgui.Create("DButton", frame)
        btn:SetTall(46)
        btn:Dock(BOTTOM)
        btn:DockMargin(16, 6, 16, 10)
        btn:SetText("")
        btn.Enabled = false
        btn.Paint = function(self, w, h)
            local bg = self.Enabled and (self:IsHovered() and COL_RED_HOVER or COL_RED) or Color(130, 15, 32, 255)
            draw.RoundedBox(4, 0, 0, w, h, bg)
            local label = self.Enabled
                and SoulRebooterText("SoulRebooter_Confirm", "Resurrect")
                or  SoulRebooterText("SoulRebooter_SelectFirst", "Select a player")
            draw.SimpleText(label, "SoulRebooter_Button", w / 2, h / 2, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local function UpdateButton()
            btn.Enabled = (#frame.selected >= MIN_TARGETS_CL) and not frame.committed
        end

        local function ToggleRow(row)
            if frame.committed then return end
            local ply = row.Player
            if not IsValid(ply) then return end

            for _, r in ipairs(frame._rows or {}) do
                if r ~= row then
                    r.Selected = false
                end
            end
            row.Selected = not row.Selected

            frame.selected = {}
            if row.Selected then
                frame.selected[1] = ply
            end
            UpdateButton()
            surface.PlaySound("buttons/lightswitch2.wav")
        end

        frame._rows = {}
        for _, ply in ipairs(deadPlayers) do
            if not IsValid(ply) then continue end

            local row = vgui.Create("DButton", scroll)
            row:SetTall(52)
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 0)
            row:SetText("")
            row.Player = ply
            row.Selected = false
            frame._rows[#frame._rows + 1] = row

            local iconMat = GetPlayerClassIcon(ply)

            row.Paint = function(self, w, h)
                if self.Selected then
                    draw.RoundedBox(0, 0, 0, w, h, COL_RED)
                elseif self:IsHovered() then
                    draw.RoundedBox(0, 0, 0, w, h, COL_HOVER_ROW)
                end

                local iconSize = 36
                local iconX = 14
                local iconY = (h - iconSize) / 2

                if iconMat and not iconMat:IsError() then
                    surface.SetMaterial(iconMat)
                    surface.SetDrawColor(255, 255, 255, 255)
                    surface.DrawTexturedRect(iconX, iconY, iconSize, iconSize)
                end

                local name = IsValid(self.Player) and self.Player:Nick() or SoulRebooterText("SoulRebooter_UnknownPlayer", "Unknown Player")
                draw.SimpleText(name, "SoulRebooter_Name", iconX + iconSize + 14, h / 2, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            row.DoClick = function(self)
                ToggleRow(self)
            end
        end

        UpdateButton()

        btn.DoClick = function()
            if not btn.Enabled or frame.committed then return end
            if #frame.selected < MIN_TARGETS_CL then return end

            frame.committed = true
            btn.Enabled = false

            net.Start("Horde_SoulRebooterSWEP_Confirm")
                net.WriteUInt(#frame.selected, 8)
                for _, t in ipairs(frame.selected) do
                    net.WriteEntity(t)
                end
            net.SendToServer()

            surface.PlaySound("buttons/button14.wav")

            if IsValid(frame) then frame:Close() end
        end

        frame.OnClose = function()
        end
    end

    net.Receive("Horde_SoulRebooterSWEP_OpenMenu", function()
        local count = net.ReadUInt(8)
        local list = {}
        for _ = 1, count do
            local ent = net.ReadEntity()
            if IsValid(ent) then list[#list + 1] = ent end
        end
        local ok, err = pcall(OpenSoulRebooterMenu, list)
        if not ok then
            print("[Soul Rebooter SWEP] menu error: " .. tostring(err))
        end
    end)

    net.Receive("Horde_SoulRebooterSWEP_Close", function()
        if IsValid(frame) then frame:Close() end
    end)

    hook.Add("HUDPaint", "Horde_SoulRebooterSWEP_PlaceHint", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local wpn = ply:GetActiveWeapon()
        if not IsValid(wpn) or wpn:GetClass() ~= "weapon_soul_rebooter" then return end
        if not wpn.GetPlacing or not wpn:GetPlacing() then return end

        local target = wpn.GetSelectedTarget and wpn:GetSelectedTarget() or NULL
        local name = IsValid(target) and target:Nick() or "?"
        draw.SimpleTextOutlined(
            SoulRebooterText("SoulRebooter_PlaceHint", "PLACEMENT MODE — Left Click: place  |  Right Click: cancel"),
            "DermaDefaultBold", ScrW() / 2, ScrH() - 120,
            Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            1, Color(0, 0, 0)
        )
        draw.SimpleTextOutlined(
            SoulRebooterText("SoulRebooter_Target", "Target: ") .. name,
            "DermaDefault", ScrW() / 2, ScrH() - 98,
            color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            1, Color(0, 0, 0)
        )
    end)

end
