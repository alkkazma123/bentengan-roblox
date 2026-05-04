--[[
	LeaderboardUI - Full screen scrollable leaderboard
	Server + Global tabs, top 3 with avatars, 100 entries
	Opens via ProximityPrompt on boards or toggle
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteFolder = ReplicatedStorage:WaitForChild("SummitRemotes")
local LeaderboardData = remoteFolder:WaitForChild("LeaderboardData")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local LeaderboardUI = {}

local screenGui = nil
local mainFrame = nil
local isOpen = false
local serverData = {}
local globalData = {}
local currentTab = "global"

local function createUI()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LeaderboardGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local scale = Instance.new("UIScale")
	scale.Name = "AutoScale"
	scale.Parent = screenGui
	local function updateScale()
		local cam = workspace.CurrentCamera
		if cam then
			local ratio = math.clamp(cam.ViewportSize.X / 1920, 0.5, 1.5)
			scale.Scale = ratio
		end
	end
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end
	task.defer(updateScale)

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "LeaderboardFrame"
	mainFrame.Size = UDim2.new(0, 380, 0, 550)
	mainFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 200, 0)
	stroke.Thickness = 2
	stroke.Parent = mainFrame

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 34, 0, 34)
	closeBtn.Position = UDim2.new(1, -40, 0, 6)
	closeBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "X"
	closeBtn.TextSize = 14
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = mainFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		LeaderboardUI.Close()
	end)

	-- Tab buttons
	local tabFrame = Instance.new("Frame")
	tabFrame.Size = UDim2.new(1, -10, 0, 40)
	tabFrame.Position = UDim2.new(0, 5, 0, 5)
	tabFrame.BackgroundTransparency = 1
	tabFrame.Parent = mainFrame

	local globalTab = Instance.new("TextButton")
	globalTab.Name = "GlobalTab"
	globalTab.Size = UDim2.new(0.5, -4, 1, 0)
	globalTab.BackgroundColor3 = Color3.fromRGB(60, 40, 120)
	globalTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	globalTab.Text = "\u{1F30D} GLOBAL"
	globalTab.TextSize = 13
	globalTab.Font = Enum.Font.GothamBold
	globalTab.Parent = tabFrame

	local globalTabCorner = Instance.new("UICorner")
	globalTabCorner.CornerRadius = UDim.new(0, 8)
	globalTabCorner.Parent = globalTab

	local serverTab = Instance.new("TextButton")
	serverTab.Name = "ServerTab"
	serverTab.Size = UDim2.new(0.5, -4, 1, 0)
	serverTab.Position = UDim2.new(0.5, 4, 0, 0)
	serverTab.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	serverTab.TextColor3 = Color3.fromRGB(200, 200, 200)
	serverTab.Text = "\u{1F3E0} SERVER"
	serverTab.TextSize = 13
	serverTab.Font = Enum.Font.GothamBold
	serverTab.Parent = tabFrame

	local serverTabCorner = Instance.new("UICorner")
	serverTabCorner.CornerRadius = UDim.new(0, 8)
	serverTabCorner.Parent = serverTab

	-- Top 3 avatar section (global only)
	local avatarSection = Instance.new("Frame")
	avatarSection.Name = "AvatarSection"
	avatarSection.Size = UDim2.new(1, -10, 0, 100)
	avatarSection.Position = UDim2.new(0, 5, 0, 50)
	avatarSection.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	avatarSection.Parent = mainFrame

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0, 10)
	avatarCorner.Parent = avatarSection

	-- Scroll for entries
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Entries"
	scroll.Size = UDim2.new(1, -10, 1, -160)
	scroll.Position = UDim2.new(0, 5, 0, 155)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = mainFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 3)
	layout.Parent = scroll

	-- Tab switching
	globalTab.MouseButton1Click:Connect(function()
		currentTab = "global"
		globalTab.BackgroundColor3 = Color3.fromRGB(60, 40, 120)
		globalTab.TextColor3 = Color3.fromRGB(255, 255, 255)
		serverTab.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		serverTab.TextColor3 = Color3.fromRGB(200, 200, 200)
		avatarSection.Visible = true
		scroll.Size = UDim2.new(1, -10, 1, -160)
		scroll.Position = UDim2.new(0, 5, 0, 155)
		LeaderboardUI.Refresh()
	end)

	serverTab.MouseButton1Click:Connect(function()
		currentTab = "server"
		serverTab.BackgroundColor3 = Color3.fromRGB(60, 40, 120)
		serverTab.TextColor3 = Color3.fromRGB(255, 255, 255)
		globalTab.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		globalTab.TextColor3 = Color3.fromRGB(200, 200, 200)
		avatarSection.Visible = false
		scroll.Size = UDim2.new(1, -10, 1, -55)
		scroll.Position = UDim2.new(0, 5, 0, 50)
		LeaderboardUI.Refresh()
	end)

	-- ProximityPrompt listener
	task.spawn(function()
		local serverBoard = workspace:WaitForChild("ServerLeaderboard", 30)
		if serverBoard then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "View Leaderboard"
			prompt.ObjectText = "Server Leaderboard"
			prompt.MaxActivationDistance = 15
			prompt.Parent = serverBoard
			prompt.Triggered:Connect(function(triggerPlayer)
				if triggerPlayer == player then
					currentTab = "server"
					LeaderboardUI.Open()
				end
			end)
		end

		local globalBoard = workspace:WaitForChild("GlobalLeaderboard", 30)
		if globalBoard then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "View Leaderboard"
			prompt.ObjectText = "Global Leaderboard"
			prompt.MaxActivationDistance = 15
			prompt.Parent = globalBoard
			prompt.Triggered:Connect(function(triggerPlayer)
				if triggerPlayer == player then
					currentTab = "global"
					LeaderboardUI.Open()
				end
			end)
		end
	end)
end

function LeaderboardUI.Refresh()
	if not mainFrame then
		return
	end

	local scroll = mainFrame:FindFirstChild("Entries")
	if not scroll then
		return
	end

	-- Clear entries
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local data = if currentTab == "global" then globalData else serverData

	for i, entry in ipairs(data) do
		local row = Instance.new("Frame")
		row.Name = "Row_" .. i
		row.Size = UDim2.new(1, 0, 0, 32)
		row.BackgroundTransparency = 0.5
		row.Parent = scroll

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		if i <= 3 then
			local colors = {
				Color3.fromRGB(255, 200, 0),
				Color3.fromRGB(180, 180, 180),
				Color3.fromRGB(180, 110, 40),
			}
			row.BackgroundColor3 = colors[i]
			row.BackgroundTransparency = 0.6
		else
			row.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
		end

		local rankLabel = Instance.new("TextLabel")
		rankLabel.Size = UDim2.new(0, 35, 1, 0)
		rankLabel.BackgroundTransparency = 1
		rankLabel.Text = "#" .. i
		rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		rankLabel.TextSize = 13
		rankLabel.Font = Enum.Font.GothamBold
		rankLabel.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.6, -35, 1, 0)
		nameLabel.Position = UDim2.new(0, 38, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = entry.name
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
		sumLabel.Text = tostring(entry.summits) .. " \u{26F0}"
		sumLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
		sumLabel.TextSize = 12
		sumLabel.Font = Enum.Font.GothamBold
		sumLabel.TextXAlignment = Enum.TextXAlignment.Right
		sumLabel.Parent = row
	end

	-- Update top 3 avatars (global only)
	local avatarSection = mainFrame:FindFirstChild("AvatarSection")
	if avatarSection then
		for _, child in ipairs(avatarSection:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		if currentTab == "global" then
			for i = 1, math.min(3, #globalData) do
				local entry = globalData[i]
				local card = Instance.new("Frame")
				card.Size = UDim2.new(0, 100, 0, 90)
				card.Position = UDim2.new(0, (i - 1) * 120 + 20, 0, 5)
				card.BackgroundTransparency = 1
				card.Parent = avatarSection

				local img = Instance.new("ImageLabel")
				img.Size = UDim2.new(0, 56, 0, 56)
				img.Position = UDim2.new(0.5, -28, 0, 0)
				img.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
				img.Parent = card

				local imgCorner = Instance.new("UICorner")
				imgCorner.CornerRadius = UDim.new(1, 0)
				imgCorner.Parent = img

				local medals = { "\u{1F947}", "\u{1F948}", "\u{1F949}" }

				local crownText = Instance.new("TextLabel")
				crownText.Size = UDim2.new(1, 0, 0, 16)
				crownText.Position = UDim2.new(0, 0, 0, -16)
				crownText.BackgroundTransparency = 1
				crownText.Text = medals[i] or ""
				crownText.TextSize = 14
				crownText.Parent = img

				local nameTag = Instance.new("TextLabel")
				nameTag.Size = UDim2.new(1, 0, 0, 14)
				nameTag.Position = UDim2.new(0, 0, 1, 4)
				nameTag.BackgroundTransparency = 1
				nameTag.Text = entry.name
				nameTag.TextColor3 = Color3.fromRGB(255, 255, 255)
				nameTag.TextSize = 9
				nameTag.Font = Enum.Font.GothamBold
				nameTag.TextTruncate = Enum.TextTruncate.AtEnd
				nameTag.Parent = card

				local sumTag = Instance.new("TextLabel")
				sumTag.Size = UDim2.new(1, 0, 0, 12)
				sumTag.Position = UDim2.new(0, 0, 1, 18)
				sumTag.BackgroundTransparency = 1
				sumTag.Text = tostring(entry.summits) .. " \u{26F0}"
				sumTag.TextColor3 = Color3.fromRGB(200, 200, 255)
				sumTag.TextSize = 9
				sumTag.Font = Enum.Font.Gotham
				sumTag.Parent = card

				-- Load avatar thumbnail
				if entry.userId and entry.userId > 0 then
					local uid = entry.userId
					task.spawn(function()
						local thumbOk, thumbUrl = pcall(function()
							return Players:GetUserThumbnailAsync(
								uid,
								Enum.ThumbnailType.HeadShot,
								Enum.ThumbnailSize.Size100x100
							)
						end)
						if thumbOk and thumbUrl then
							img.Image = thumbUrl
						end
					end)
				end
			end
		end
	end
end

function LeaderboardUI.Open()
	if isOpen then
		return
	end
	isOpen = true
	LeaderboardUI.Refresh()
	TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()
end

function LeaderboardUI.Close()
	if not isOpen then
		return
	end
	isOpen = false
	TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 1.5, 0),
	}):Play()
end

function LeaderboardUI.Init()
	createUI()

	LeaderboardData.OnClientEvent:Connect(function(sData, gData)
		serverData = sData or {}
		globalData = gData or {}
		if isOpen then
			LeaderboardUI.Refresh()
		end
	end)
end

return LeaderboardUI
