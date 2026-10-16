if GetConVarNumber("horde_enable_scoreboard") == 0 then return end

local scoreboard = {}

local draw_SimpleText = draw.SimpleText

local draw_RoundedBoxEx = draw.RoundedBoxEx
local draw_RoundedBox = draw.RoundedBox

local player_GetAll = player.GetAll

local server_name = GetHostName()
local map_name = game.GetMap()
function HORDE:EasyLabel(parent, text, font, textcolor)
	local ELpanel = vgui.Create("DLabel", parent)
	if font then
		ELpanel:SetFont(font or "DefaultFont")
	end
	ELpanel:SetText(text)
	ELpanel:SizeToContents()
	if textcolor then
		ELpanel:SetTextColor(textcolor)
	end
	ELpanel:SetKeyboardInputEnabled(false)
	ELpanel:SetMouseInputEnabled(false)

	return ELpanel
end

local function GetDifficultyTitle()
	return HORDE:GetActiveDifficultyTitle() or ""
end

function scoreboard:show()

	local diff_title = GetDifficultyTitle()
	local left_text = "Horde: REDUX - " .. map_name .. " - " .. diff_title

	local TITLE_PAD, TITLE_GAP = 10, 40
	surface.SetFont("Title")
	local left_w = surface.GetTextSize(left_text)
	local right_w = surface.GetTextSize(server_name)
	local needed = TITLE_PAD + left_w + TITLE_GAP + right_w + TITLE_PAD
	local max_width = ScrW() * 0.96
	local width = math.min(math.max(ScrW() * 0.6, needed), max_width)
	local height = ScrH() * 0.65

	local right_text = server_name
	local right_room = width - TITLE_PAD * 2 - left_w - TITLE_GAP
	if right_w > right_room then
		local ell = "..."
		while #right_text > 0 and surface.GetTextSize(right_text .. ell) > math.max(0, right_room) do
			local off = utf8.offset(right_text, -1) or #right_text
			right_text = string.sub(right_text, 1, off - 1)
		end
		right_text = (right_text ~= "") and (right_text .. ell) or ""
	end

    local title = vgui.Create("DPanel")
    HORDE.ScoreboardPanel = title
    title:SetSize(width, height)
	title:AlignTop( ScrH() * 0.15 )
	title:CenterHorizontal()

    function title:Paint(w, h)

		draw.RoundedBoxEx(8,0,0,w,h * 0.135, Color(30,30,30,150), true, true, false,false)
        draw_SimpleText(left_text, "Title", TITLE_PAD, 12, HORDE.color_crimson_dim, TEXT_ALIGN_LEFT)
        draw_SimpleText(right_text, "Title", width - TITLE_PAD, 12, HORDE.color_crimson_dim, TEXT_ALIGN_RIGHT)
    end

	local header = title:Add("DHeaderPanel")
	header:Dock(TOP)
    header:SetSize(title:GetWide(), 45)
    header:DockMargin(0,50,0,0)

    local board = title:Add("DPanel")
	board:Dock(FILL)
    board:SetSize(width)
	board:CenterHorizontal()
    function board:Paint(w, h)
    end

    local ScrollPanel = board:Add("DScrollPanel")
    ScrollPanel:Dock(FILL)

    local Bar = ScrollPanel:GetVBar()
    local butC = 0

    function Bar:Paint(w,h)
        draw.RoundedBox(8,  w / 2 - w / 2, butC, w / 2, h - butC * 2, color_black_alpha120 )
    end

    function Bar.btnDown:Paint(w,h)
    end

    function Bar.btnUp:Paint(w,h)
        butC = h
    end

    function Bar.btnGrip:Paint(w,h)
        draw.RoundedBox(8,  w / 2 - w / 2, 0, w / 2, h, color_black)
    end
    local PlayerPanels
    if PlayerPanels == nil then
        PlayerPanels = {}
    end

    local function RemovePlayerPanel(panel)
	    if panel:IsValid() then
	    	PlayerPanels[panel:GetPlayer()] = nil
	    	panel:Remove()
	    end
    end

	for pl, panel in pairs(PlayerPanels) do
		if not panel:IsValid() or pl:IsValid() and pl:IsSpectator() then
			RemovePlayerPanel(panel)
		end
	end

    local function GetPlayerPanel(pl)
        for _, panel in pairs(PlayerPanels) do
            if panel:IsValid() and panel:GetPlayer() == pl then
                return panel
            end
        end
    end

    local function CreatePlayerPanel(pl)
        local curpan = GetPlayerPanel(pl)
        if curpan and curpan:IsValid() then return curpan end

        local panel = ScrollPanel:Add("DPlayerLine")
        panel:SetPlayer(pl)
        panel:Dock(TOP)
        panel:DockMargin(ScrollPanel:GetWide() * 0.01, 2, ScrollPanel:GetWide() * 0.01, 2)

        PlayerPanels[pl] = panel

        return panel
    end

    board:SizeToChildren(true, false)

    local player_score = {}
    for _, ply in pairs(player.GetAll()) do
        player_score[ply] = ply:Frags()
    end

    for ply, _ in SortedPairsByValue(player_score, true) do
        CreatePlayerPanel(ply)
    end

    local function GetPlayerPanel(pl)
        for _, panel in pairs(PlayerPanels) do
            if panel:IsValid() and panel:GetPlayer() == pl then
                return panel
            end
        end
    end

    function scoreboard:hide()
        gui.EnableScreenClicker(false)
        board:Remove()
        title:Remove()
        hook.Remove("KeyPress", "Horde_Scoreboard_Mouse")
	end

    hook.Add("KeyPress", "Horde_Scoreboard_Mouse", function(ply, key)
        if board and title and (key == IN_ATTACK or key == IN_ATTACK2 or key == IN_USE) then
            gui.EnableScreenClicker(true)
        end
    end)
end

function GM:ScoreboardShow()
	scoreboard:show()
end

function GM:ScoreboardHide()
	scoreboard:hide()
end
