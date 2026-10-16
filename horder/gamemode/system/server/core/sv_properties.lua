if not SERVER then return end

local BLOCKED_PROPERTIES = {
    statue        = true,
    statue_stop   = true,
    npc_smaller   = true,
    npc_bigger    = true,
    ignite        = true,
    extinguish    = true,
    drive         = true,
    remover       = true,
}

hook.Add("CanProperty", "Horde_BlockedProperties", function(ply, property, ent)
    if BLOCKED_PROPERTIES[property] then
        return false
    end
end)

properties.Add("ignite", {
    MenuLabel = "#ignite",
    Order = 999,
    MenuIcon = "icon16/fire.png",
    Filter = function() end,
    Action = function() end,
    Receive = function() end,
})

properties.Add("extinguish", {
    MenuLabel = "#extinguish",
    Order = 999,
    MenuIcon = "icon16/water.png",
    Filter = function() end,
    Action = function() end,
    Receive = function() end,
})
