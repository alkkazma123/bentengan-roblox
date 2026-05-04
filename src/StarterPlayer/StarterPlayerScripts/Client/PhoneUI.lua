--[[
	PhoneUI
	Main phone menu system. Toggle button at top center (aligned with Roblox top bar).
	Phone frame with swipeable pages: Shop, Music, Emotes, Settings.
	All UI uses AutoScale for device adaptation.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local playerScripts = player:WaitForChild("PlayerScripts")
local Client = playerScripts:WaitForChild("Client")

local ShopUI = require(Client:WaitForChild("ShopUI"))
local MusicPlayerUI = require(Client:WaitForChild("MusicPlayerUI"))
local EmoteUI = require(Client:WaitForChild("EmoteUI"))
local SettingsUI = require(Client:WaitForChild("SettingsUI"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local PhoneUI = {}

local screenGui = nil
local phoneFrame = nil
local toggleButton = nil
local coinLabel = nil
local isOpen = false
local currentPage = 1
local pages = {}
local PHONE_POSITION_OPEN = UDim2.new(0.5, 0, 0.5, 0)
local PHONE_POSITION_CLOSED = UDim2.new(0.5, 0, 1.5, 0)

local function createScreenGui()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PhoneGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui

	-- AutoScale: UIScale adapts to screen size
	local scale = Instance.new("UIScale")
	scale.Name = "AutoScale"
	scale.Parent = screenGui

	local function updateScale()
		local viewportSize = workspace.CurrentCamera.ViewportSize
		local baseWidth = 1920
		local ratio = math.clamp(viewportSize.X / baseWidth, 0.5, 1.5)
		scale.Scale = ratio
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	task.defer(updateScale)
end

local function createCoinUI()
	local coinFrame = Instance.new("Frame")
	coinFrame.Name = "CoinDisplay"
	coinFrame.Size = UDim2.new(0, 140, 0, 36)
	coinFrame.Position = UDim2.new(0, 12, 0, 42)
	coinFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	coinFrame.BackgroundTransparency = 0.2
	coinFrame.Parent = screenGui
	coinFrame.ZIndex = 10

	local coinCorner = Instance.new("UICorner")
	coinCorner.CornerRadius = UDim.new(0, 18)
	coinCorner.Parent = coinFrame

	local coinStroke = Instance.new("UIStroke")
	coinStroke.Color = Color3.fromRGB(255, 200, 0)
	coinStroke.Thickness = 1.5
	coinStroke.Parent = coinFrame

	local coinIcon = Instance.new("TextLabel")
	coinIcon.Name = "Icon"
	coinIcon.Size = UDim2.new(0, 30, 0, 30)
	coinIcon.Position = UDim2.new(0, 6, 0.5, -15)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Text = "COIN"
	coinIcon.TextSize = 9
	coinIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinIcon.Font = Enum.Font.GothamBold
	coinIcon.Parent = coinFrame
	coinIcon.ZIndex = 11

	coinLabel = Instance.new("TextLabel")
	coinLabel.Name = "Amount"
	coinLabel.Size = UDim2.new(1, -42, 1, 0)
	coinLabel.Position = UDim2.new(0, 38, 0, 0)
	coinLabel.BackgroundTransparency = 1
	coinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	coinLabel.Text = "0"
	coinLabel.TextSize = 16
	coinLabel.Font = Enum.Font.GothamBold
	coinLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinLabel.Parent = coinFrame
	coinLabel.ZIndex = 11

	-- Listen for coin updates
	Remotes.UpdateCoins.OnClientEvent:Connect(function(amount)
		if coinLabel then
			coinLabel.Text = tostring(amount)
		end
	end)

	-- Initial value from leaderstats
	task.defer(function()
		local leaderstats = player:WaitForChild("leaderstats", 10)
		if leaderstats then
			local coins = leaderstats:WaitForChild("Coins", 5)
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
end

local function createToggleButton()
	-- Position aligned with Roblox top bar (GuiInset is ignored, so y=4 is top)
	toggleButton = Instance.new("TextButton")
	toggleButton.Name = "PhoneToggle"
	toggleButton.Size = UDim2.new(0, 44, 0, 44)
	toggleButton.Position = UDim2.new(0.5, -22, 0, 2)
	toggleButton.AnchorPoint = Vector2.new(0, 0)
	toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.Text = "TEL"
	toggleButton.TextSize = 11
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.Parent = screenGui
	toggleButton.ZIndex = 10

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 22)
	corner.Parent = toggleButton

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 80, 100)
	stroke.Thickness = 1.5
	stroke.Parent = toggleButton

	toggleButton.MouseButton1Click:Connect(function()
		PhoneUI.Toggle()
	end)
end

local function createPhoneFrame()
	phoneFrame = Instance.new("Frame")
	phoneFrame.Name = "PhoneFrame"
	phoneFrame.Size = UDim2.new(0, 320, 0, 520)
	phoneFrame.Position = PHONE_POSITION_CLOSED
	phoneFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	phoneFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	phoneFrame.BorderSizePixel = 0
	phoneFrame.ClipsDescendants = true
	phoneFrame.Parent = screenGui
	phoneFrame.ZIndex = 5

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = phoneFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 60, 60)
	stroke.Thickness = 2
	stroke.Parent = phoneFrame

	-- Top bar with page tabs
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 50)
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	topBar.BorderSizePixel = 0
	topBar.Parent = phoneFrame
	topBar.ZIndex = 6

	local topCorner = Instance.new("UICorner")
	topCorner.CornerRadius = UDim.new(0, 20)
	topCorner.Parent = topBar

	local tabNames = { "Shop", "Music", "Emotes", "Settings" }
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

		local pageIndex = i
		tab.MouseButton1Click:Connect(function()
			PhoneUI.GoToPage(pageIndex)
		end)
	end

	-- Content area
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, 0, 1, -50)
	contentFrame.Position = UDim2.new(0, 0, 0, 50)
	contentFrame.BackgroundTransparency = 1
	contentFrame.ClipsDescendants = true
	contentFrame.Parent = phoneFrame
	contentFrame.ZIndex = 5

	pages = {}
	for i = 1, 4 do
		local page = Instance.new("Frame")
		page.Name = "Page_" .. i
		page.Size = UDim2.new(1, 0, 1, 0)
		page.Position = UDim2.new((i - 1), 0, 0, 0)
		page.BackgroundTransparency = 1
		page.Parent = contentFrame
		page.ZIndex = 5
		pages[i] = page
	end

	ShopUI.Init(pages[1])
	MusicPlayerUI.Init(pages[2])
	EmoteUI.Init(pages[3])
	SettingsUI.Init(pages[4])
end

local function setupSwipe()
	local dragging = false
	local dragStart = nil

	UserInputService.InputBegan:Connect(function(input)
		if not isOpen then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1
		then
			local pos = input.Position
			local phoneAbsPos = phoneFrame.AbsolutePosition
			local phoneAbsSize = phoneFrame.AbsoluteSize
			if
				pos.X >= phoneAbsPos.X
				and pos.X <= phoneAbsPos.X + phoneAbsSize.X
				and pos.Y >= phoneAbsPos.Y + 50
				and pos.Y <= phoneAbsPos.Y + phoneAbsSize.Y
			then
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
		local targetPos = UDim2.new(i - pageIndex, 0, 0, 0)
		TweenService:Create(page, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = targetPos,
		}):Play()
	end

	local topBar = phoneFrame:FindFirstChild("TopBar")
	if topBar then
		local tabNames = { "Shop", "Music", "Emotes", "Settings" }
		for i, name in ipairs(tabNames) do
			local tab = topBar:FindFirstChild("Tab_" .. name)
			if tab then
				tab.BackgroundColor3 = if i == pageIndex then Color3.fromRGB(60, 60, 70) else Color3.fromRGB(40, 40, 45)
			end
		end
	end
end

function PhoneUI.Toggle()
	isOpen = not isOpen
	local targetPos = if isOpen then PHONE_POSITION_OPEN else PHONE_POSITION_CLOSED
	TweenService:Create(phoneFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = targetPos,
	}):Play()
end

function PhoneUI.Init()
	createScreenGui()
	createCoinUI()
	createToggleButton()
	createPhoneFrame()
	setupSwipe()
end

return PhoneUI
