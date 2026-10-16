HORDE = HORDE or {}

function HORDE:ForceReloadPerks()
    MsgC(Color(255,200,100), "[Horde Compat] ForceReloadPerks() устарел — v2.0 грузит всё автоматически. Используй HORDE:RegisterPerk(tbl).\n")
end
function HORDE:ForceReloadGadgets()
    MsgC(Color(255,200,100), "[Horde Compat] ForceReloadGadgets() устарел.\n")
end

if GetConVar("developer"):GetBool() then
    hook.Add("Horde_AllModulesLoaded", "Horde_CompatCheck", function()
        local ok = true
        for _, name in ipairs({ "perks","gadgets","spells","mutations","classes","subclasses","enemies" }) do
            if not HORDE[name] then
                MsgC(Color(255,100,100), "[Horde Compat] MISSING TABLE: HORDE." .. name .. "\n")
                ok = false
            end
        end
        if ok then MsgC(Color(0,255,0), "[Horde Compat] All core tables OK.\n") end
    end)
end
