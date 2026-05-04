--[[
	LeaderboardService - Server + Global leaderboard boards
	Uses existing parts placed by user: ServerLeaderboard, GlobalLeaderboard, LeaderboardPodiums
	Global shows all-time rankings. If DataStore unavailable, uses server data.
	Podium top 1-3 shows avatar dummies.
	Cooldown timer on boards shows next refresh.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")

local LeaderboardService = {}

local globalStore = nil
local UPDATE_INTERVAL = 60
local MAX_ENTRIES = 100

-- Try to get OrderedDataStore (works in published game, and Studio with API access)
local storeOk, storeResult = pcall(function()
	return DataStoreService:GetOrderedDataStore("SummitKit_GlobalLB")
end)
if storeOk and storeResult then
	globalStore = storeResult
	print("[LeaderboardService] OrderedDataStore connected.")
else
	warn("[LeaderboardService] OrderedDataStore not available. Global will use server data as fallback.")
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
		return nil
	end

	local entries = {}
	local ok, pages = pcall(function()
		return globalStore:GetSortedAsync(false, MAX_ENTRIES)
	end)

	if not ok or not pages then
		return nil
	end

	local success, pageData = pcall(function()
		return pages:GetCurrentPage()
	end)

	if not success or not pageData then
		return nil
	end

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

local function setupBoardGui(part, title)
	-- Remove existing gui if any
	local existing = part:FindFirstChild("LeaderboardGui")
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("SurfaceGui")
	gui.Name = "LeaderboardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 36
	gui.Parent = part

	local bg = Instance.new("Frame")
	bg.Name = "BG"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 45)
	titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	titleLabel.BorderSizePixel = 0
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	titleLabel.TextSize = 26
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = bg

	-- Cooldown timer label
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "Timer"
	timerLabel.Size = UDim2.new(1, 0, 0, 20)
	timerLabel.Position = UDim2.new(0, 0, 0, 45)
	timerLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	timerLabel.BorderSizePixel = 0
	timerLabel.Text = "Next update: --"
	timerLabel.TextColor3 = Color3.fromRGB(150, 150, 200)
	timerLabel.TextSize = 11
	timerLabel.Font = Enum.Font.Gotham
	timerLabel.Parent = bg

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Entries"
	scroll.Size = UDim2.new(1, -8, 1, -72)
	scroll.Position = UDim2.new(0, 4, 0, 68)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 3
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = bg

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.Parent = scroll

	return scroll, timerLabel
end

local function clearScroll(scroll)
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function addEntry(scroll, rank, name, summits, isTop3)
	local row = Instance.new("Frame")
	row.Name = "E" .. rank
	row.Size = UDim2.new(1, 0, 0, 26)
	row.BorderSizePixel = 0
	row.Parent = scroll

	if isTop3 then
		local colors = {
			Color3.fromRGB(200, 170, 0),
			Color3.fromRGB(140, 140, 150),
			Color3.fromRGB(160, 100, 30),
		}
		row.BackgroundColor3 = colors[rank] or Color3.fromRGB(35, 35, 42)
		row.BackgroundTransparency = 0.3
	else
		row.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
		row.BackgroundTransparency = 0.4
	end

	local medals = { "\u{1F947} ", "\u{1F948} ", "\u{1F949} " }
	local prefix = if isTop3 then (medals[rank] or "#" .. rank) else "#" .. rank

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(0, 40, 1, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Text = prefix
	rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rankLabel.TextSize = 13
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.55, -40, 1, 0)
	nameLabel.Position = UDim2.new(0, 42, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 11
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = row

	local sumLabel = Instance.new("TextLabel")
	sumLabel.Size = UDim2.new(0.35, 0, 1, 0)
	sumLabel.Position = UDim2.new(0.65, 0, 0, 0)
	sumLabel.BackgroundTransparency = 1
	sumLabel.Text = tostring(summits) .. " \u{26F0}"
	sumLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
	sumLabel.TextSize = 12
	sumLabel.Font = Enum.Font.GothamBold
	sumLabel.TextXAlignment = Enum.TextXAlignment.Right
	sumLabel.Parent = row
end

-- Podium avatar system
local podiumModels = {}

local function updatePodiumAvatars(entries, podiumFolder)
	if not podiumFolder then
		return
	end

	for i = 1, 3 do
		local podium = podiumFolder:FindFirstChild("Top" .. i)
		if not podium then
			continue
		end

		-- Remove old model
		if podiumModels[i] then
			podiumModels[i]:Destroy()
			podiumModels[i] = nil
		end

		local entry = entries[i]
		if not entry or entry.userId <= 0 then
			continue
		end

		-- Create avatar dummy
		local ok, model = pcall(function()
			return Players:CreateHumanoidModelFromUserId(entry.userId)
		end)

		if ok and model then
			model.Name = "TopPlayer_" .. i

			-- Position on top of podium
			local podiumTop = podium.Position + Vector3.new(0, podium.Size.Y / 2, 0)
			model:SetPrimaryPartCFrame(CFrame.new(podiumTop + Vector3.new(0, 3, 0)))

			-- Anchor all parts so it won't fall
			for _, part in ipairs(model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end

			-- Add name tag above head
			local head = model:FindFirstChild("Head")
			if head then
				local bb = Instance.new("BillboardGui")
				bb.Size = UDim2.new(0, 150, 0, 40)
				bb.StudsOffset = Vector3.new(0, 2.5, 0)
				bb.Parent = head

				local nameTag = Instance.new("TextLabel")
				nameTag.Size = UDim2.new(1, 0, 0.5, 0)
				nameTag.BackgroundTransparency = 1
				nameTag.Text = entry.name
				nameTag.TextColor3 = Color3.fromRGB(255, 255, 255)
				nameTag.TextStrokeTransparency = 0.3
				nameTag.TextSize = 14
				nameTag.Font = Enum.Font.GothamBold
				nameTag.Parent = bb

				local sumTag = Instance.new("TextLabel")
				sumTag.Size = UDim2.new(1, 0, 0.5, 0)
				sumTag.Position = UDim2.new(0, 0, 0.5, 0)
				sumTag.BackgroundTransparency = 1
				sumTag.Text = tostring(entry.summits) .. " Summits"
				sumTag.TextColor3 = Color3.fromRGB(255, 215, 0)
				sumTag.TextStrokeTransparency = 0.3
				sumTag.TextSize = 12
				sumTag.Font = Enum.Font.GothamBold
				sumTag.Parent = bb
			end

			model.Parent = workspace
			podiumModels[i] = model
			print("[LeaderboardService] Avatar placed on Top" .. i .. ": " .. entry.name)
		else
			warn("[LeaderboardService] Failed to create avatar for Top" .. i .. " userId: " .. tostring(entry.userId))
		end
	end
end

function LeaderboardService.Init(_remotes)
	-- Find existing parts (user places them)
	local serverBoard = workspace:FindFirstChild("ServerLeaderboard")
	if not serverBoard then
		serverBoard = workspace:WaitForChild("ServerLeaderboard", 30)
	end
	if not serverBoard then
		warn("[LeaderboardService] WARNING: 'ServerLeaderboard' part not found in workspace!")
		return
	end

	local globalBoard = workspace:FindFirstChild("GlobalLeaderboard")
	if not globalBoard then
		globalBoard = workspace:WaitForChild("GlobalLeaderboard", 30)
	end
	if not globalBoard then
		warn("[LeaderboardService] WARNING: 'GlobalLeaderboard' part not found in workspace!")
		return
	end

	local podiumFolder = workspace:FindFirstChild("LeaderboardPodiums")
	if not podiumFolder then
		podiumFolder = workspace:WaitForChild("LeaderboardPodiums", 15)
	end
	if not podiumFolder then
		warn("[LeaderboardService] WARNING: 'LeaderboardPodiums' folder not found. Podium avatars disabled.")
	end

	-- Setup board GUIs
	local serverScroll, serverTimer = setupBoardGui(serverBoard, "\u{1F3E0} SERVER")
	local globalScroll, globalTimer = setupBoardGui(globalBoard, "\u{1F30D} GLOBAL")

	print("[LeaderboardService] Boards initialized. Update interval: " .. UPDATE_INTERVAL .. "s")

	-- Update function
	local function updateBoards()
		print("[LeaderboardService] Updating leaderboards...")

		-- Server leaderboard
		local serverData = getServerLeaderboard()
		clearScroll(serverScroll)
		for i, entry in ipairs(serverData) do
			addEntry(serverScroll, i, entry.name, entry.summits, i <= 3)
		end

		if #serverData == 0 then
			local empty = Instance.new("Frame")
			empty.Size = UDim2.new(1, 0, 0, 30)
			empty.BackgroundTransparency = 1
			empty.Parent = serverScroll

			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.Size = UDim2.new(1, 0, 1, 0)
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Text = "No players yet"
			emptyLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
			emptyLabel.TextSize = 12
			emptyLabel.Font = Enum.Font.Gotham
			emptyLabel.Parent = empty
		end

		-- Push current players to global store
		updateGlobalStore()

		-- Global leaderboard (DataStore or fallback to server data)
		local globalData = getGlobalLeaderboard()

		-- Fallback: if DataStore empty/unavailable, use server data as global
		if not globalData or #globalData == 0 then
			globalData = serverData
		end

		clearScroll(globalScroll)
		for i, entry in ipairs(globalData) do
			addEntry(globalScroll, i, entry.name, entry.summits, i <= 3)
		end

		if #globalData == 0 then
			local empty = Instance.new("Frame")
			empty.Size = UDim2.new(1, 0, 0, 30)
			empty.BackgroundTransparency = 1
			empty.Parent = globalScroll

			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.Size = UDim2.new(1, 0, 1, 0)
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Text = "No data yet"
			emptyLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
			emptyLabel.TextSize = 12
			emptyLabel.Font = Enum.Font.Gotham
			emptyLabel.Parent = empty
		end

		-- Update podium avatars
		updatePodiumAvatars(globalData, podiumFolder)

		print(
			"[LeaderboardService] Update complete. " .. #serverData .. " server, " .. #globalData .. " global entries."
		)
	end

	-- Cooldown timer loop
	task.spawn(function()
		local countdown = UPDATE_INTERVAL
		while true do
			countdown = countdown - 1
			if countdown <= 0 then
				countdown = UPDATE_INTERVAL
			end
			local text = "Next update: " .. countdown .. "s"
			if serverTimer then
				serverTimer.Text = text
			end
			if globalTimer then
				globalTimer.Text = text
			end
			task.wait(1)
		end
	end)

	-- Initial update (give time for players to load data)
	task.delay(5, updateBoards)

	-- Periodic update
	task.spawn(function()
		while true do
			task.wait(UPDATE_INTERVAL)
			updateBoards()
		end
	end)
end

return LeaderboardService
