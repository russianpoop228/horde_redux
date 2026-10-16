if not CLIENT then return end

HORDE = HORDE or {}
HORDE.PlayerMenu = HORDE.PlayerMenu or {}

HORDE.PlayerControls = HORDE.PlayerControls or {}
if HORDE.Prefs then
    local t = HORDE.Prefs.GetTable("player_controls")
    if istable(t) then HORDE.PlayerControls = t end
end

local function SavePlayerControls()
    if HORDE.Prefs then HORDE.Prefs.SetTable("player_controls", HORDE.PlayerControls) end
    if HORDE.InvalidateGameplayBinds then HORDE.InvalidateGameplayBinds() end
end

HORDE.PlayerMenu.SaveControls = SavePlayerControls

function HORDE:SetPlayerControlKey(id, key)
    if key == nil or key == "" then
        HORDE.PlayerControls[id] = nil
    else
        HORDE.PlayerControls[id] = tostring(key)
    end
    SavePlayerControls()
end

function HORDE:ResetPlayerControls()
    HORDE.PlayerControls = {}
    SavePlayerControls()
end

local MOUSE_CODES = {
    [MOUSE_LEFT] = true, [MOUSE_RIGHT] = true, [MOUSE_MIDDLE] = true,
    [MOUSE_4] = true, [MOUSE_5] = true,
}
local KEY_NAME_FIX = {
    LSHIFT = "SHIFT", RSHIFT = "SHIFT", LCONTROL = "CTRL", RCONTROL = "CTRL",
    LALT = "ALT", RALT = "ALT",
}
local CAPTURE_NAME, CAPTURE_CODES = {}, {}
do
    local function add(code, name)
        if not code or code <= 0 or CAPTURE_NAME[code] then return end
        CAPTURE_NAME[code] = name
        CAPTURE_CODES[#CAPTURE_CODES + 1] = code
    end
    add(MOUSE_LEFT, "MOUSE1"); add(MOUSE_RIGHT, "MOUSE2"); add(MOUSE_MIDDLE, "MOUSE3")
    add(MOUSE_4, "MOUSE4"); add(MOUSE_5, "MOUSE5")
    for gname, code in pairs(_G) do
        if isstring(gname) and type(code) == "number" and string.sub(gname, 1, 4) == "KEY_" then
            local n = string.sub(gname, 5)
            if n ~= "" and n ~= "NONE" and n ~= "FIRST" and n ~= "LAST" and n ~= "COUNT"
                and string.sub(n, 1, 5) ~= "MOUSE" then
                local name = KEY_NAME_FIX[n] or n
                if input.GetKeyCode(name) == code then add(code, name) end
            end
        end
    end
end

local function IsCodeDown(code)
    if MOUSE_CODES[code] then return input.IsMouseDown(code) end
    return input.IsKeyDown(code)
end

HORDE.PlayerMenu.CAPTURE_NAME  = CAPTURE_NAME
HORDE.PlayerMenu.CAPTURE_CODES = CAPTURE_CODES
HORDE.PlayerMenu.IsCodeDown    = IsCodeDown

function HORDE:TogglePlayerMenu()
    HORDE:ToggleStats()
end

net.Receive("Horde_TogglePlayerMenu", function()
    HORDE:ToggleStats()
end)

concommand.Add("horde_player_menu", function()
    HORDE:ToggleStats()
end)

concommand.Add("horde_player_binds", function()
    HORDE:ToggleStats()
end)
