--[[
	LeaderboardService - Server + Global leaderboard boards
	Creates boards near Start with SurfaceGui.
	Global board has 3 podium parts with avatar dummies for top 1-3.
	No ProximityPrompt, boards are always visible.
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

	local success, pageData = pcall(function()
		return pages:GetCurrentPage()
	end)

	if not success or not pageData then
		return {}
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

local function createBoard(name, cframe)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(14, 18, 0.5)
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromRGB(20, 20, 25)
	part.Parent = workspace
	return part
end

local function createBoardGui(part, title)
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

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Entries"
	scroll.Size = UDim2.new(1, -8, 1, -52)
	scroll.Position = UDim2.new(0, 4, 0, 48)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 3
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = bg

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.Parent = scroll

	return scroll
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

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(0, 35, 1, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Text = "#" .. rank
	rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rankLabel.TextSize = 13
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.55, -35, 1, 0)
	nameLabel.Position = UDim2.new(0, 38, 0, 0)
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
	sumLabel.Text = tostring(summits)
	sumLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
	sumLabel.TextSize = 12
	sumLabel.Font = Enum.Font.GothamBold
	sumLabel.TextXAlignment = Enum.TextXAlignment.Right
	sumLabel.Parent = row
end

-- Podium system: 3 parts with avatar dummies
local podiumModels = {}

local function createPodiums(basePos)
	local podiumFolder = Instance.new("Folder")
	podiumFolder.Name = "LeaderboardPodiums"
	podiumFolder.Parent = workspace

	local heights = { 8, 6, 4 }
	local offsets = { 0, -5, 5 }
	local colors = {
		Color3.fromRGB(255, 200, 0),
		Color3.fromRGB(180, 180, 190),
		Color3.fromRGB(180, 110, 40),
	}

	for i = 1, 3 do
		local podium = Instance.new("Part")
		podium.Name = "Top" .. i
		podium.Size = Vector3.new(4, heights[i], 4)
		podium.Position = basePos + Vector3.new(offsets[i], heights[i] / 2, 0)
		podium.Anchored = true
		podium.Material = Enum.Material.SmoothPlastic
		podium.Color = colors[i]
		podium.Parent = podiumFolder

		-- Rank label on podium
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 30
		gui.Parent = podium

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = "#" .. i
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextSize = 40
		label.Font = Enum.Font.GothamBold
		label.Parent = gui

		podiumModels[i] = { part = podium, currentModel = nil }
	end

	return podiumFolder
end

local function updatePodiumAvatars(globalEntries)
	for i = 1, 3 do
		local podData = podiumModels[i]
		if not podData then
			continue
		end

		-- Remove old model
		if podData.currentModel then
			podData.currentModel:Destroy()
			podData.currentModel = nil
		end

		local entry = globalEntries[i]
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
			local podiumTop = podData.part.Position + Vector3.new(0, podData.part.Size.Y / 2, 0)
			model:SetPrimaryPartCFrame(CFrame.new(podiumTop + Vector3.new(0, 3, 0)))

			-- Make sure it won't fall
			for _, part in ipairs(model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end

			-- Add name tag
			local head = model:FindFirstChild("Head")
			if head then
				local bb = Instance.new("BillboardGui")
				bb.Size = UDim2.new(0, 120, 0, 30)
				bb.StudsOffset = Vector3.new(0, 2, 0)
				bb.Parent = head

				local nameTag = Instance.new("TextLabel")
				nameTag.Size = UDim2.new(1, 0, 1, 0)
				nameTag.BackgroundTransparency = 1
				nameTag.Text = entry.name .. " (" .. entry.summits .. ")"
				nameTag.TextColor3 = Color3.fromRGB(255, 255, 255)
				nameTag.TextStrokeTransparency = 0.5
				nameTag.TextSize = 14
				nameTag.Font = Enum.Font.GothamBold
				nameTag.Parent = bb
			end

			model.Parent = workspace
			podData.currentModel = model
		else
			warn("[LeaderboardService] Failed to create avatar for userId: " .. tostring(entry.userId))
		end
	end
end

function LeaderboardService.Init(_remotes)
	-- Find Start position
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

	-- Create boards
	local serverBoardCF = CFrame.new(startPos + Vector3.new(-12, 9, -8)) * CFrame.Angles(0, math.rad(10), 0)
	local globalBoardCF = CFrame.new(startPos + Vector3.new(12, 9, -8)) * CFrame.Angles(0, math.rad(-10), 0)

	local serverBoard = createBoard("ServerLeaderboard", serverBoardCF)
	local globalBoard = createBoard("GlobalLeaderboard", globalBoardCF)

	local serverScroll = createBoardGui(serverBoard, "\u{1F3E0} SERVER")
	local globalScroll = createBoardGui(globalBoard, "\u{1F30D} GLOBAL")

	-- Create podiums next to global board
	local podiumBase = startPos + Vector3.new(12, 0, -14)
	createPodiums(podiumBase)

	print("[LeaderboardService] Boards + podiums created near Start.")

	-- Update function
	local function updateBoards()
		-- Server leaderboard
		local serverData = getServerLeaderboard()
		clearScroll(serverScroll)
		for i, entry in ipairs(serverData) do
			addEntry(serverScroll, i, entry.name, entry.summits, i <= 3)
		end

		-- Update global store with current players
		updateGlobalStore()

		-- Global leaderboard
		local globalData = getGlobalLeaderboard()
		clearScroll(globalScroll)
		for i, entry in ipairs(globalData) do
			addEntry(globalScroll, i, entry.name, entry.summits, i <= 3)
		end

		-- Update podium avatars
		updatePodiumAvatars(globalData)
	end

	-- Initial update (delay for data to load)
	task.delay(8, updateBoards)

	-- Periodic update
	task.spawn(function()
		while true do
			task.wait(UPDATE_INTERVAL)
			updateBoards()
		end
	end)
end

return LeaderboardService
