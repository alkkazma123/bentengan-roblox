--[[
	PhoneUI - Phone menu with swipeable tabs + coin display
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local scriptFolder = script.Parent

local ShopUI = require(scriptFolder:WaitForChild("ShopUI"))
local MusicPlayerUI = require(scriptFolder:WaitForChild("MusicPlayerUI"))
local EmoteUI = require(scriptFolder:WaitForChild("EmoteUI"))
local SettingsUI = require(scriptFolder:WaitForChild("SettingsUI"))
local SkyUI = require(scriptFolder:WaitForChild("SkyUI"))

local remoteFolder = ReplicatedStorage:WaitForChild("SummitRemotes")
local UpdateCoins = remoteFolder:WaitForChild("UpdateCoins")

local PhoneUI = {}

local screenGui = nil
local phoneFrame = nil
local coinLabel = nil
local isOpen = false
local currentPage = 1
local pages = {}

function PhoneUI.Init()
	-- ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PhoneGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	-- AutoScale
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

	-- Coin Display (center-left, bigger)
	local coinFrame = Instance.new("Frame")
	coinFrame.Name = "CoinDisplay"
	coinFrame.Size = UDim2.new(0, 180, 0, 48)
	coinFrame.Position = UDim2.new(0, 14, 0.5, -24)
	coinFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	coinFrame.BackgroundTransparency = 0.2
	coinFrame.Parent = screenGui
	coinFrame.ZIndex = 10

	local coinCorner = Instance.new("UICorner")
	coinCorner.CornerRadius = UDim.new(0, 24)
	coinCorner.Parent = coinFrame

	local coinStroke = Instance.new("UIStroke")
	coinStroke.Color = Color3.fromRGB(255, 200, 0)
	coinStroke.Thickness = 1.5
	coinStroke.Parent = coinFrame

	local coinIcon = Instance.new("TextLabel")
	coinIcon.Name = "Icon"
	coinIcon.Size = UDim2.new(0, 36, 1, 0)
	coinIcon.Position = UDim2.new(0, 8, 0, 0)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Text = "\u{1FA99}"
	coinIcon.TextSize = 22
	coinIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinIcon.Font = Enum.Font.GothamBold
	coinIcon.Parent = coinFrame
	coinIcon.ZIndex = 11

	coinLabel = Instance.new("TextLabel")
	coinLabel.Name = "Amount"
	coinLabel.Size = UDim2.new(1, -50, 1, 0)
	coinLabel.Position = UDim2.new(0, 46, 0, 0)
	coinLabel.BackgroundTransparency = 1
	coinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	coinLabel.Text = "0"
	coinLabel.TextSize = 20
	coinLabel.Font = Enum.Font.GothamBold
	coinLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinLabel.Parent = coinFrame
	coinLabel.ZIndex = 11

	UpdateCoins.OnClientEvent:Connect(function(amount)
		if coinLabel then
			coinLabel.Text = tostring(amount)
		end
	end)

	task.defer(function()
		local ls = player:WaitForChild("leaderstats", 10)
		if ls then
			local coins = ls:WaitForChild("Coins", 5)
			if coins and coinLabel then
				coinLabel.Text = tostring(coins.Value)
				coins.Changed:Connect(function(val)
					if coinLabel then
						coinLabel.Text = tostring(val)
					end
				end)
			end
		end
	end)

	-- Toggle Button (top center, same level as Roblox bar)
	local toggle = Instance.new("TextButton")
	toggle.Name = "PhoneToggle"
	toggle.Size = UDim2.new(0, 56, 0, 56)
	toggle.Position = UDim2.new(0.5, -28, 0, 2)
	toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggle.Text = "\u{1F4F1}"
	toggle.TextSize = 26
	toggle.Font = Enum.Font.GothamBold
	toggle.Parent = screenGui
	toggle.ZIndex = 10

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 28)
	toggleCorner.Parent = toggle

	local toggleStroke = Instance.new("UIStroke")
	toggleStroke.Color = Color3.fromRGB(80, 80, 100)
	toggleStroke.Thickness = 1.5
	toggleStroke.Parent = toggle

	toggle.MouseButton1Click:Connect(function()
		PhoneUI.Toggle()
	end)

	-- Phone Frame
	phoneFrame = Instance.new("Frame")
	phoneFrame.Name = "PhoneFrame"
	phoneFrame.Size = UDim2.new(0, 320, 0, 520)
	phoneFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
	phoneFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	phoneFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	phoneFrame.BorderSizePixel = 0
	phoneFrame.ClipsDescendants = true
	phoneFrame.Parent = screenGui
	phoneFrame.ZIndex = 5

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 20)
	frameCorner.Parent = phoneFrame

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Color3.fromRGB(60, 60, 60)
	frameStroke.Thickness = 2
	frameStroke.Parent = phoneFrame

	-- Top bar with tabs
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 50)
	topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	topBar.BorderSizePixel = 0
	topBar.Parent = phoneFrame
	topBar.ZIndex = 6

	local tabNames = { "Shop", "Music", "Emotes", "Settings", "Sky" }
	local tabWidth = 1 / #tabNames

	for i, tabName in ipairs(tabNames) do
		local tab = Instance.new("TextButton")
		tab.Name = "Tab_" .. tabName
		tab.Size = UDim2.new(tabWidth, -4, 1, -10)
		tab.Position = UDim2.new((i - 1) * tabWidth, 2, 0, 5)
		tab.BackgroundColor3 = if i == 1 then Color3.fromRGB(60, 60, 70) else Color3.fromRGB(40, 40, 45)
		tab.BackgroundTransparency = 0.5
		tab.TextColor3 = Color3.fromRGB(255, 255, 255)
		tab.Text = tabName
		tab.TextSize = 12
		tab.Font = Enum.Font.GothamBold
		tab.BorderSizePixel = 0
		tab.Parent = topBar
		tab.ZIndex = 7

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 8)
		tabCorner.Parent = tab

		tab.MouseButton1Click:Connect(function()
			PhoneUI.GoToPage(i)
		end)
	end

	-- Content
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 1, -50)
	content.Position = UDim2.new(0, 0, 0, 50)
	content.BackgroundTransparency = 1
	content.ClipsDescendants = true
	content.Parent = phoneFrame
	content.ZIndex = 5

	pages = {}
	for i = 1, 5 do
		local page = Instance.new("Frame")
		page.Name = "Page_" .. i
		page.Size = UDim2.new(1, 0, 1, 0)
		page.Position = UDim2.new(i - 1, 0, 0, 0)
		page.BackgroundTransparency = 1
		page.Parent = content
		page.ZIndex = 5
		pages[i] = page
	end

	ShopUI.Init(pages[1])
	MusicPlayerUI.Init(pages[2])
	EmoteUI.Init(pages[3])
	SettingsUI.Init(pages[4])
	SkyUI.CreateMenu(pages[5])

	-- Swipe
	local dragging = false
	local dragStart = 0

	UserInputService.InputBegan:Connect(function(input)
		if not isOpen then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			local pos = input.Position
			local ap = phoneFrame.AbsolutePosition
			local as = phoneFrame.AbsoluteSize
			if pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y + 50 and pos.Y <= ap.Y + as.Y then
				dragging = true
				dragStart = pos.X
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if not dragging then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			dragging = false
			local diff = input.Position.X - dragStart
			if diff < -50 and currentPage < #pages then
				PhoneUI.GoToPage(currentPage + 1)
			elseif diff > 50 and currentPage > 1 then
				PhoneUI.GoToPage(currentPage - 1)
			end
		end
	end)
end

function PhoneUI.GoToPage(pageIndex)
	if pageIndex < 1 or pageIndex > #pages then
		return
	end
	currentPage = pageIndex

	for i, page in ipairs(pages) do
		local target = UDim2.new(i - pageIndex, 0, 0, 0)
		TweenService:Create(page, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = target,
		}):Play()
	end

	-- Highlight active tab
	local topBar = phoneFrame:FindFirstChild("TopBar")
	if topBar then
		for i, name in ipairs({ "Shop", "Music", "Emotes", "Settings", "Sky" }) do
			local tab = topBar:FindFirstChild("Tab_" .. name)
			if tab then
				tab.BackgroundColor3 = if i == pageIndex then Color3.fromRGB(60, 60, 70) else Color3.fromRGB(40, 40, 45)
			end
		end
	end
end

function PhoneUI.Toggle()
	isOpen = not isOpen
	local target = if isOpen then UDim2.new(0.5, 0, 0.5, 0) else UDim2.new(0.5, 0, 1.5, 0)
	TweenService:Create(phoneFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = target,
	}):Play()
end

return PhoneUI
