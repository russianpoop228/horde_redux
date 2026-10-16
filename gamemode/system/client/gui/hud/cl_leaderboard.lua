HORDE.LeaderboardData = HORDE.LeaderboardData or {}

net.Receive("Horde_SyncTopTen", function()
    local payload = net.ReadString()
    local incoming = util.JSONToTable(payload) or {}
    HORDE.LeaderboardData = {}
    for level, ply in pairs(incoming) do
        local key = tonumber(level) or level
        HORDE.LeaderboardData[key] = {
            name = ply.name or "Loading...",
            steamid = ply.steamid,
            class = ply.class
        }
        if ply.steamid then
            local target = HORDE.LeaderboardData[key]
            steamworks.RequestPlayerInfo(ply.steamid, function(steamName)
                if target then
                    target.name = steamName or target.name
                    if IsValid(HORDE.SummaryPanel) and HORDE.SummaryPanel.active_tab == "leaderboard" then
                        local page = HORDE.SummaryPanel.pages and HORDE.SummaryPanel.pages.leaderboard
                        if IsValid(page) and page.RefreshData then page:RefreshData() end
                    end
                end
            end)
        end
    end
    if IsValid(HORDE.SummaryPanel) and HORDE.SummaryPanel.active_tab == "leaderboard" then
        local page = HORDE.SummaryPanel.pages and HORDE.SummaryPanel.pages.leaderboard
        if IsValid(page) and page.RefreshData then page:RefreshData() end
    end
end)
