HORDE = HORDE or {}

HORDE.PlayerAchievements = HORDE.PlayerAchievements or {
    defs  = {},
    order = {},
    state = { progress = {}, unlocked = {}, owned = {}, loaded = false },
}
local A = HORDE.PlayerAchievements

function A:Register(def)
    if not istable(def) or not isstring(def.id) or def.id == "" then return end
    def.goal = math.max(1, math.floor(tonumber(def.goal) or 1))
    def.mode = (def.mode == "max") and "max" or "sum"
    if not self.defs[def.id] then self.order[#self.order + 1] = def.id end
    self.defs[def.id] = def
    return def
end

function A:Get(id) return self.defs[id] end

function A:List()
    local out = {}
    for _, id in ipairs(self.order) do
        if self.defs[id] then out[#out + 1] = self.defs[id] end
    end
    return out
end

function A:GetFraction(def)
    local st = self.state
    if st.unlocked[def.id] then return 1 end
    return math.Clamp((tonumber(st.progress[def.id]) or 0) / def.goal, 0, 1)
end

A:Register({
    id     = "test_jumper_slayer",
    test   = true,
    name   = { en = "Jumper Slayer I", ru = "Убийца Прыгунов I" },
    desc   = { en = "Kill 100 Fast Zombie enemies.", ru = "Убейте 100 Fast Zombie врагов." },
    icon   = "materials/gui/bolt.png",
    goal   = 100,
    event  = "kill",
    filter = function(ply, ctx) return ctx.class == "npc_fastzombie" end,
    reward = { skulls = 1, exp = 300 },
})

if SERVER then
    util.AddNetworkString("Horde_Ach_Sync")
    util.AddNetworkString("Horde_Ach_Request")
    util.AddNetworkString("Horde_Ach_Unlocked")
end

if CLIENT then
    net.Receive("Horde_Ach_Sync", function()
        local st = { progress = {}, unlocked = {}, owned = {}, loaded = true }
        local n = net.ReadUInt(12)
        for _ = 1, n do
            local id = net.ReadString()
            st.progress[id] = net.ReadUInt(32)
            st.unlocked[id] = net.ReadBool()
            local owned = net.ReadFloat()
            if owned >= 0 then st.owned[id] = owned end
        end
        A.state = st
        hook.Run("Horde_AchievementsSynced")
    end)

    net.Receive("Horde_Ach_Unlocked", function()
        local id = net.ReadString()
        local def = A:Get(id)
        A.state.unlocked[id] = true
        if def then A.state.progress[id] = def.goal end
        hook.Run("Horde_AchievementReceived", id, def)
    end)

    local last_request = 0
    function A:Request(force)
        if not force and CurTime() - last_request < 1 then return end
        last_request = CurTime()
        net.Start("Horde_Ach_Request")
        net.SendToServer()
    end
end
