--[[
	AvatarCatalogUI - Avatar catalog with Girls/Boys categories
	Toggle button next to phone toggle.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AvatarCatalog = require(Shared:WaitForChild("AvatarCatalog"))

local remoteFolder = ReplicatedStorage:WaitForChild("SummitRemotes")
local ApplyAvatar = remoteFolder:WaitForChild("ApplyAvatar")
local ResetAvatar = remoteFolder:WaitForChild("ResetAvatar")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AvatarCatalogUI = {}

local screenGui = nil
local catalogFrame = nil
local isOpen = false

function AvatarCatalogUI.Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AvatarCatalogGui"
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

	-- Toggle button (next to phone toggle, on the right)
	local toggle = Instance.new("TextButton")
	toggle.Name = "AvatarToggle"
	toggle.Size = UDim2.new(0, 56, 0, 56)
	toggle.Position = UDim2.new(0.5, 36, 0, 2)
	toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggle.Text = "\u{1F464}"
	toggle.TextSize = 26
	toggle.Font = Enum.Font.GothamBold
	toggle.Parent = screenGui
	toggle.ZIndex = 10

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 28)
	toggleCorner.Parent = toggle

	local toggleStroke = Instance.new("UIStroke")
	toggleStroke.Color = Color3.fromRGB(100, 80, 200)
	toggleStroke.Thickness = 1.5
	toggleStroke.Parent = toggle

	toggle.MouseButton1Click:Connect(function()
		AvatarCatalogUI.Toggle()
	end)

	-- Catalog Frame
	catalogFrame = Instance.new("Frame")
	catalogFrame.Name = "CatalogFrame"
	catalogFrame.Size = UDim2.new(0, 300, 0, 450)
	catalogFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
	catalogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	catalogFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	catalogFrame.BorderSizePixel = 0
	catalogFrame.ClipsDescendants = true
	catalogFrame.Parent = screenGui
	catalogFrame.ZIndex = 5

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 20)
	frameCorner.Parent = catalogFrame

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Color3.fromRGB(100, 80, 200)
	frameStroke.Thickness = 2
	frameStroke.Parent = catalogFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	title.BorderSizePixel = 0
	title.Text = "AVATAR CATALOG"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.Parent = catalogFrame
	title.ZIndex = 6

	-- Reset button
	local resetBtn = Instance.new("TextButton")
	resetBtn.Size = UDim2.new(0, 60, 0, 26)
	resetBtn.Position = UDim2.new(1, -65, 0, 7)
	resetBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
	resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	resetBtn.Text = "RESET"
	resetBtn.TextSize = 10
	resetBtn.Font = Enum.Font.GothamBold
	resetBtn.Parent = catalogFrame
	resetBtn.ZIndex = 7

	local resetCorner = Instance.new("UICorner")
	resetCorner.CornerRadius = UDim.new(0, 6)
	resetCorner.Parent = resetBtn

	resetBtn.MouseButton1Click:Connect(function()
		ResetAvatar:FireServer()
	end)

	-- Scroll content
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -10, 1, -50)
	scroll.Position = UDim2.new(0, 5, 0, 45)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = catalogFrame
	scroll.ZIndex = 6

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = scroll

	-- Build categories
	for _, category in ipairs(AvatarCatalog.Categories) do
		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(1, 0, 0, 25)
		header.BackgroundTransparency = 1
		header.Text = "— " .. category.name .. " —"
		header.TextColor3 = Color3.fromRGB(200, 150, 255)
		header.TextSize = 13
		header.Font = Enum.Font.GothamBold
		header.Parent = scroll
		header.ZIndex = 6

		for _, avatar in ipairs(category.avatars) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 44)
			row.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
			row.Parent = scroll
			row.ZIndex = 6

			local rowCorner = Instance.new("UICorner")
			rowCorner.CornerRadius = UDim.new(0, 8)
			rowCorner.Parent = row

			-- Avatar thumbnail
			local thumb = Instance.new("ImageLabel")
			thumb.Size = UDim2.new(0, 34, 0, 34)
			thumb.Position = UDim2.new(0, 5, 0.5, -17)
			thumb.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
			thumb.Parent = row
			thumb.ZIndex = 7

			local thumbCorner = Instance.new("UICorner")
			thumbCorner.CornerRadius = UDim.new(1, 0)
			thumbCorner.Parent = thumb

			-- Load thumbnail async
			local avatarUserId = avatar.userId
			task.spawn(function()
				local imgOk, imgResult = pcall(function()
					return Players:GetUserThumbnailAsync(
						avatarUserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size48x48
					)
				end)
				if imgOk and imgResult then
					thumb.Image = imgResult
				end
			end)

			-- Name
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.5, -10, 1, 0)
			nameLabel.Position = UDim2.new(0, 44, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = avatar.name
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextSize = 12
			nameLabel.Font = Enum.Font.Gotham
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = row
			nameLabel.ZIndex = 7

			-- Use button
			local useBtn = Instance.new("TextButton")
			useBtn.Size = UDim2.new(0, 55, 0, 28)
			useBtn.Position = UDim2.new(1, -62, 0.5, -14)
			useBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 180)
			useBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			useBtn.Text = "USE"
			useBtn.TextSize = 11
			useBtn.Font = Enum.Font.GothamBold
			useBtn.Parent = row
			useBtn.ZIndex = 7

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 6)
			btnCorner.Parent = useBtn

			useBtn.MouseButton1Click:Connect(function()
				ApplyAvatar:FireServer(avatarUserId)
				useBtn.Text = "..."
				task.delay(2, function()
					useBtn.Text = "USE"
				end)
			end)
		end
	end
end

function AvatarCatalogUI.Toggle()
	isOpen = not isOpen
	local target = if isOpen then UDim2.new(0.5, 0, 0.5, 0) else UDim2.new(0.5, 0, 1.5, 0)
	TweenService:Create(catalogFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = target,
	}):Play()
end

return AvatarCatalogUI
