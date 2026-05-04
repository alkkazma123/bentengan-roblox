--[[
	LeaderboardService - Server + Global leaderboard
	Creates physical boards near Start.
	Uses OrderedDataStore for global rankings.
	Fires data to client for scrollable UI.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local LeaderboardService = {}

local globalStore = nil
local UPDATE_INTERVAL = 30
local MAX_ENTRIES = 100

if not RunService:IsStudio() then
	local ok, store = pcall(function()
		return DataStoreService:GetOrderedDataStore("SummitKit_GlobalLB")
	end)
	if ok then
		globalStore = store
	end
end

local function getServerLeaderboard()
	local entries = {}
	local Server = ServerScriptService:WaitForChild("Server")
	local DataService = require(Server:WaitForChild("DataService"))

	for _, player in ipairs(Players:GetPlayers()) do
		local data = DataService.GetData(player)
		if data then
			table.insert(entries, {
				name = player.DisplayName,
				userId = player.UserId,
				summits = data.summits,
			})
		end
	end

	table.sort(entries, function(a, b)
		return a.summits > b.summits
	end)

	return entries
end

local function getGlobalLeaderboard()
	if not globalStore then
		return {}
	end

	local entries = {}
	local ok, pages = pcall(function()
		return globalStore:GetSortedAsync(false, MAX_ENTRIES)
	end)

	if not ok or not pages then
		return {}
	end

	local pageData = pages:GetCurrentPage()
	for rank, entry in ipairs(pageData) do
		local userId = tonumber(entry.key)
		local summits = entry.value
		local name = "Player"

		if userId then
			local nameOk, nameResult = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if nameOk and nameResult then
				name = nameResult
			end
		end

		table.insert(entries, {
			rank = rank,
			name = name,
			userId = userId or 0,
			summits = summits,
		})
	end

	return entries
end

local function updateGlobalStore()
	if not globalStore then
		return
	end

	local Server = ServerScriptService:WaitForChild("Server")
	local DataService = require(Server:WaitForChild("DataService"))

	for _, player in ipairs(Players:GetPlayers()) do
		local data = DataService.GetData(player)
		if data and data.summits > 0 then
			pcall(function()
				globalStore:SetAsync(tostring(player.UserId), data.summits)
			end)
		end
	end
end

local function createBoard(name, position, rotation)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(12, 16, 0.5)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromRGB(20, 20, 25)
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, rotation, 0)
	part.Parent = workspace
	return part
end

local function createBoardGui(part, title)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "LeaderboardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = part

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 50)
	titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	titleLabel.BorderSizePixel = 0
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	titleLabel.TextSize = 28
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = bg

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Entries"
	scroll.Size = UDim2.new(1, -8, 1, -58)
	scroll.Position = UDim2.new(0, 4, 0, 54)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = bg

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.Parent = scroll

	return gui, scroll
end

local function clearEntries(scroll)
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function addEntry(scroll, rank, name, summits, isTop3)
	local row = Instance.new("Frame")
	row.Name = "Entry_" .. rank
	row.Size = UDim2.new(1, 0, 0, 28)
	row.BackgroundTransparency = if isTop3 then 0.3 else 0.7
	row.BorderSizePixel = 0
	row.Parent = scroll

	if isTop3 then
		local colors = {
			Color3.fromRGB(255, 215, 0),
			Color3.fromRGB(192, 192, 192),
			Color3.fromRGB(205, 127, 50),
		}
		row.BackgroundColor3 = colors[rank] or Color3.fromRGB(40, 40, 50)
	else
		row.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	end

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(0, 35, 1, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Text = "#" .. rank
	rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rankLabel.TextSize = 14
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.6, -40, 1, 0)
	nameLabel.Position = UDim2.new(0, 38, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = row

	local sumLabel = Instance.new("TextLabel")
	sumLabel.Size = UDim2.new(0.3, 0, 1, 0)
	sumLabel.Position = UDim2.new(0.7, 0, 0, 0)
	sumLabel.BackgroundTransparency = 1
	sumLabel.Text = tostring(summits) .. " \u{26F0}"
	sumLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
	sumLabel.TextSize = 12
	sumLabel.Font = Enum.Font.GothamBold
	sumLabel.TextXAlignment = Enum.TextXAlignment.Right
	sumLabel.Parent = row
end

function LeaderboardService.Init(remotes)
	-- Wait for Start part to position boards nearby
	local folder = workspace:FindFirstChild("Checkpoints")
	if not folder then
		folder = workspace:WaitForChild("Checkpoints", 30)
	end

	local startPos = Vector3.new(0, 1, 0)
	if folder then
		local startPart = folder:FindFirstChild("Start")
		if startPart then
			startPos = startPart.Position
		end
	end

	-- Create boards near Start
	local serverBoard = createBoard("ServerLeaderboard", startPos + Vector3.new(-10, 8, -6), math.rad(15))
	local globalBoard = createBoard("GlobalLeaderboard", startPos + Vector3.new(10, 8, -6), math.rad(-15))

	local _, serverScroll = createBoardGui(serverBoard, "\u{1F3E0} SERVER")
	local _, globalScroll = createBoardGui(globalBoard, "\u{1F30D} GLOBAL")

	-- Global board: avatar display for top 3
	local avatarFrame = Instance.new("Frame")
	avatarFrame.Name = "TopAvatars"
	avatarFrame.Size = UDim2.new(1, 0, 0, 80)
	avatarFrame.BackgroundTransparency = 1
	avatarFrame.Parent = globalScroll

	print("[LeaderboardService] Boards created near Start.")

	-- Update loop
	local function updateBoards()
		-- Server leaderboard
		local serverData = getServerLeaderboard()
		clearEntries(serverScroll)
		for i, entry in ipairs(serverData) do
			addEntry(serverScroll, i, entry.name, entry.summits, i <= 3)
		end

		-- Global leaderboard
		updateGlobalStore()
		local globalData = getGlobalLeaderboard()
		clearEntries(globalScroll)

		-- Clear avatars
		for _, child in ipairs(avatarFrame:GetChildren()) do
			child:Destroy()
		end

		-- Top 3 avatars for global
		for i = 1, math.min(3, #globalData) do
			local entry = globalData[i]
			local img = Instance.new("ImageLabel")
			img.Size = UDim2.new(0, 60, 0, 60)
			img.Position = UDim2.new(0, (i - 1) * 70 + 50, 0, 5)
			img.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			img.Parent = avatarFrame

			local imgCorner = Instance.new("UICorner")
			imgCorner.CornerRadius = UDim.new(1, 0)
			imgCorner.Parent = img

			if entry.userId > 0 then
				local thumbOk, thumbUrl = pcall(function()
					return Players:GetUserThumbnailAsync(
						entry.userId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size48x48
					)
				end)
				if thumbOk and thumbUrl then
					img.Image = thumbUrl
				end
			end

			local crownLabel = Instance.new("TextLabel")
			crownLabel.Size = UDim2.new(1, 0, 0, 15)
			crownLabel.Position = UDim2.new(0, 0, 1, 0)
			crownLabel.BackgroundTransparency = 1
			crownLabel.Text = "#" .. i .. " " .. entry.name
			crownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			crownLabel.TextSize = 8
			crownLabel.Font = Enum.Font.GothamBold
			crownLabel.TextTruncate = Enum.TextTruncate.AtEnd
			crownLabel.Parent = img
		end

		-- All entries
		for i, entry in ipairs(globalData) do
			addEntry(globalScroll, i, entry.name, entry.summits, i <= 3)
		end

		-- Fire to clients for the full screen UI
		for _, player in ipairs(Players:GetPlayers()) do
			remotes.LeaderboardData:FireClient(player, serverData, globalData)
		end
	end

	-- Initial update
	task.delay(5, updateBoards)

	-- Periodic update
	task.spawn(function()
		while true do
			task.wait(UPDATE_INTERVAL)
			updateBoards()
		end
	end)

	-- Send to new players
	Players.PlayerAdded:Connect(function(player)
		task.wait(3)
		local serverData = getServerLeaderboard()
		local globalData = getGlobalLeaderboard()
		remotes.LeaderboardData:FireClient(player, serverData, globalData)
	end)
end

return LeaderboardService
