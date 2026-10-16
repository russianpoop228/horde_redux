-- =============================================================
-- ПРИМЕР: Бафф из внешнего аддона
-- =============================================================
-- Разложите на два файла (как встроенные modules/status/buff/):
--
--   addons/my_addon/lua/horde/modules/status/buff/sh_overcharge.lua
--       — RegisterStatus (shared: id нужен и клиенту для иконки HUD)
--
--   addons/my_addon/lua/horde/modules/status/buff/sv_overcharge.lua
--       — серверная логика (стеки, хуки урона/скорости)
--
-- Порядок: core (sh_status) → STATUS_PHASE → внешние status/buff.
-- Id выдаётся следующим свободным номером; не занимайте имена
-- встроенных статусов (Adrenaline, Fortify, Berserk, ...).
-- =============================================================

-- ─── sh_overcharge.lua (shared) ─────────────────────────────
if HORDE and HORDE.RegisterStatus then
    if not HORDE:GetStatusID("Overcharge") then
        HORDE:RegisterStatus({
            Name      = "Overcharge",
            Icon      = "materials/status/damage.png",
            Stackable = true,
            IsDebuff  = false,
            IsSkill   = false,
        })
    end
end

-- ─── sv_overcharge.lua (server only) ────────────────────────
-- Скопируйте блок ниже в отдельный sv_ файл аддона.
if SERVER then
    local plymeta = FindMetaTable("Player")

    function plymeta:Horde_AddOverchargeStack()
        if not self:IsValid() or not self:Alive() then return end
        local max = self.Horde_MaxOverchargeStack or 5
        self.Horde_OverchargeStack = math.min(max, (self.Horde_OverchargeStack or 0) + 1)

        net.Start("Horde_SyncStatus")
            net.WriteUInt(HORDE.Status_Overcharge, 8)
            net.WriteUInt(self.Horde_OverchargeStack, 8)
        net.Send(self)

        local sid = self:SteamID()
        timer.Create("Horde_OverchargeDecay_" .. sid, 5, 1, function()
            if not IsValid(self) then return end
            self:Horde_RemoveOverchargeStack()
        end)
    end

    function plymeta:Horde_RemoveOverchargeStack()
        if not self:IsValid() then return end
        self.Horde_OverchargeStack = math.max(0, (self.Horde_OverchargeStack or 0) - 1)
        net.Start("Horde_SyncStatus")
            net.WriteUInt(HORDE.Status_Overcharge, 8)
            net.WriteUInt(self.Horde_OverchargeStack, 8)
        net.Send(self)
        if self.Horde_OverchargeStack > 0 then
            timer.Create("Horde_OverchargeDecay_" .. self:SteamID(), 5, 1, function()
                if IsValid(self) then self:Horde_RemoveOverchargeStack() end
            end)
        end
    end

    function plymeta:Horde_GetOverchargeStack()
        return self.Horde_OverchargeStack or 0
    end

    hook.Add("Horde_OnPlayerDamage", "MyAddon_OverchargeDamage", function(ply, npc, bonus, hitgroup, dmginfo)
        local s = ply:Horde_GetOverchargeStack()
        if s > 0 then
            bonus.increase = bonus.increase + s * 0.05
        end
    end)

    hook.Add("Horde_ResetStatus", "MyAddon_OverchargeReset", function(ply)
        ply.Horde_OverchargeStack = 0
    end)

    -- Пример начисления: при убийстве врага
    hook.Add("Horde_OnEnemyKilled", "MyAddon_OverchargeOnKill", function(victim, killer, wpn)
        if IsValid(killer) and killer:IsPlayer() and killer.Horde_OverchargeEnabled then
            killer:Horde_AddOverchargeStack()
        end
    end)
end
