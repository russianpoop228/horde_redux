local entmeta = FindMetaTable("Entity")

function entmeta:Horde_AddFlashEffect(duration)
    if CLIENT then return end
    if not self:IsPlayer() then return end

    local id = self:EntIndex()

    self:EmitSound("npc/waste_scanner/grenade_fire.wav", 100, 100, 1, CHAN_AUTO)

    self:ScreenFade(SCREENFADE.OUT, Color(255, 255, 255, 255), 0.4, duration)

    timer.Create("Horde_RemoveFlash" .. id, duration, 1, function()
        if IsValid(self) then
            self:Horde_RemoveFlash()
        end
    end)
end

function entmeta:Horde_RemoveFlash()
    if not IsValid(self) then return end
    local id = self:EntIndex()

    timer.Remove("Horde_RemoveFlash" .. id)

    if self:IsPlayer() then
        self:ScreenFade(SCREENFADE.PURGE, Color(255, 255, 255, 0), 0.2, 0)
    end
end
