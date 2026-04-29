--!strict
-- Builds a 3D leaderboard billboard next to the world spawn pad that shows
-- the top 10 players currently in the server sorted by Wins. Refreshes every
-- few seconds so it stays live while players win matches.

local Players = game:GetService("Players")

local LeaderboardBoard = {}

local TOP_N = 10
local REFRESH_SECONDS = 3

local function winsOf(player: Player): number
	local folder = player:FindFirstChild("leaderstats")
	local stat = folder and folder:FindFirstChild("Wins")
	if stat and stat:IsA("IntValue") then
		return stat.Value
	end
	return 0
end

local function makeRow(index: number, name: string, wins: number): Frame
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -20, 0, 34)
	row.BackgroundColor3 = if index % 2 == 0 then Color3.fromRGB(30, 34, 44) else Color3.fromRGB(24, 28, 36)
	row.BorderSizePixel = 0
	row.LayoutOrder = index

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = row

	local rank = Instance.new("TextLabel")
	rank.Size = UDim2.fromOffset(40, 34)
	rank.BackgroundTransparency = 1
	rank.Font = Enum.Font.GothamBold
	rank.TextSize = 18
	rank.TextColor3 = if index == 1
		then Color3.fromRGB(255, 215, 90)
		elseif index == 2 then Color3.fromRGB(210, 220, 230)
		elseif index == 3 then Color3.fromRGB(230, 160, 90)
		else Color3.fromRGB(140, 150, 170)
	rank.Text = "#" .. index
	rank.TextXAlignment = Enum.TextXAlignment.Center
	rank.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -130, 1, 0)
	nameLabel.Position = UDim2.fromOffset(46, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.TextSize = 16
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = name
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = row

	local winsLabel = Instance.new("TextLabel")
	winsLabel.Size = UDim2.fromOffset(80, 34)
	winsLabel.AnchorPoint = Vector2.new(1, 0)
	winsLabel.Position = UDim2.new(1, -10, 0, 0)
	winsLabel.BackgroundTransparency = 1
	winsLabel.Font = Enum.Font.GothamBold
	winsLabel.TextSize = 16
	winsLabel.TextColor3 = Color3.fromRGB(255, 215, 120)
	winsLabel.TextXAlignment = Enum.TextXAlignment.Right
	winsLabel.Text = "★ " .. wins
	winsLabel.Parent = row

	return row
end

local function buildBoard(parent: Instance): (SurfaceGui, Frame)
	local stand = Instance.new("Part")
	stand.Name = "LeaderboardStand"
	stand.Anchored = true
	stand.CanCollide = false
	stand.Material = Enum.Material.SmoothPlastic
	stand.Color = Color3.fromRGB(24, 28, 36)
	stand.Size = Vector3.new(16, 14, 1)
	-- Place next to the world spawn pad (origin of WorldSpawn is 0,80,-320).
	-- Rotated 180 deg vs. previous build so the front face points at the pad.
	stand.CFrame = CFrame.new(Vector3.new(-30, 87, -320)) * CFrame.Angles(0, math.rad(-90), 0)
	stand.Parent = parent

	local frame = Instance.new("Part")
	frame.Name = "LeaderboardFrame"
	frame.Anchored = true
	frame.CanCollide = false
	frame.Material = Enum.Material.Neon
	frame.Color = Color3.fromRGB(120, 170, 255)
	frame.Transparency = 0.3
	frame.Size = Vector3.new(16.6, 14.6, 0.3)
	frame.CFrame = stand.CFrame * CFrame.new(0, 0, 0.4)
	frame.Parent = parent

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(640, 560)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.PixelsPerStud = 40
	gui.Parent = stand

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 60)
	title.Position = UDim2.fromOffset(10, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 28
	title.TextColor3 = Color3.fromRGB(255, 215, 90)
	title.Text = "TOP PEMAIN (Wins)"
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = bg

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -20, 0, 20)
	sub.Position = UDim2.fromOffset(10, 60)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 13
	sub.TextColor3 = Color3.fromRGB(150, 160, 180)
	sub.Text = "dari pemain di server ini"
	sub.TextXAlignment = Enum.TextXAlignment.Center
	sub.Parent = bg

	local listFrame = Instance.new("Frame")
	listFrame.Size = UDim2.new(1, -20, 1, -90)
	listFrame.Position = UDim2.fromOffset(10, 84)
	listFrame.BackgroundTransparency = 1
	listFrame.Parent = bg

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = listFrame

	return gui, listFrame
end

function LeaderboardBoard.init(parent: Instance)
	local arenasFolder = parent
	local worldSpawn = arenasFolder:FindFirstChild("WorldSpawn")
	if not worldSpawn then
		warn("[LeaderboardBoard] WorldSpawn missing; cannot place board.")
		return
	end

	-- Clear any previous board if this is re-run (e.g. /reload in Studio).
	for _, name in { "LeaderboardStand", "LeaderboardFrame" } do
		local existing = worldSpawn:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end

	local _gui, listFrame = buildBoard(worldSpawn)

	local function refresh()
		local players = Players:GetPlayers()
		table.sort(players, function(a, b)
			return winsOf(a) > winsOf(b)
		end)

		for _, child in listFrame:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		local shown = 0
		for i, p in players do
			if i > TOP_N then
				break
			end
			local row = makeRow(i, p.DisplayName, winsOf(p))
			row.Parent = listFrame
			shown += 1
		end

		if shown == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.new(1, -20, 0, 40)
			empty.BackgroundTransparency = 1
			empty.Font = Enum.Font.Gotham
			empty.TextSize = 16
			empty.TextColor3 = Color3.fromRGB(140, 150, 170)
			empty.Text = "Belum ada pemain."
			empty.Parent = listFrame
		end
	end

	refresh()
	task.spawn(function()
		while true do
			task.wait(REFRESH_SECONDS)
			refresh()
		end
	end)
end

return LeaderboardBoard
