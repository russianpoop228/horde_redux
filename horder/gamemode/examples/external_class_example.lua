-- =============================================================
-- EXAMPLE: New class from an external addon
-- Path: addons/my_addon/lua/horde/modules/classes/class_ranger.lua
-- =============================================================
-- Use HORDE:RegisterClass() (alias for CreateClass) with
-- a named-field table — readable and safe.
-- =============================================================

-- Wait for the class system to finish loading
hook.Add("Horde_AllModulesLoaded", "Register_Ranger_Class", function()

    HORDE:RegisterClass({
        name        = "Ranger",
        description = "A long-range specialist using precision and traps.",
        max_hp      = 80,
        movespd     = 200,
        sprintspd   = 320,
        base_perk   = "ranger_base",
        perks       = {
            -- Perks are defined in modules/perks/ranger/
            -- [1] = { title = "...", choices = { "ranger_perk_a", "ranger_perk_b" } },
        },
        order       = 11,       -- after Cremator (order = 9)
        display_name = "Ranger",
        model       = "models/player/custom_ranger.mdl",
        icon        = "Ranger.png",
        subclasses  = { "Ranger" },
    })

    print("[MyAddon] Ranger class registered!")
end)

-- =============================================================
-- EXAMPLE: Matching subclass
-- Path: addons/my_addon/lua/horde/modules/subclasses/ranger.lua
-- =============================================================

-- SUBCLASS = {}
-- SUBCLASS.PrintName   = "Ranger"
-- SUBCLASS.ParentClass = "Ranger"  -- base class
-- SUBCLASS.Description = "Precision shooter. Uses traps and ranged abilities."
-- SUBCLASS.Perks       = {}
-- SUBCLASS.Icon        = "Ranger.png"
-- SUBCLASS.UnlockCost  = 5000
-- -- UnlockCost = 0 means unlocked by default