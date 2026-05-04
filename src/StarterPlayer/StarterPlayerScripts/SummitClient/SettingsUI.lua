--[[
	SettingsUI
	Settings page inside the phone menu.
	Options: hide players, hide overhead, hide aura, hide trail.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SummitShared = ReplicatedStorage:WaitForChild("SummitShared")
local Remotes = require(SummitShared:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local SettingsUI = {}

local settings = {
	hidePlayers = false,
	hideAura = false,
	hideTrail = false,
}

local function createToggle(name, label, _yOffset, parent)
	local container = Instance.new("Frame")
	container.Name = "Toggle_" .. name
	container.Size = UDim2.new(1, -20, 0, 45)
	container.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	container.BorderSizePixel = 0
	container.Parent = parent
	container.ZIndex = 6

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = container

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Label"
	textLabel.Size = UDim2.new(0.7, 0, 1, 0)
	textLabel.Position = UDim2.new(0, 15, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	textLabel.Text = label
	textLabel.TextSize = 13
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Font = Enum.Font.Gotham
	textLabel.Parent = container
	textLabel.ZIndex = 7

	-- Toggle switch
	local toggleBg = Instance.new("Frame")
	toggleBg.Name = "ToggleBg"
	toggleBg.Size = UDim2.new(0, 45, 0, 24)
	toggleBg.Position = UDim2.new(1, -60, 0.5, -12)
	toggleBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = container
	toggleBg.ZIndex = 7

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0.5, 0)
	toggleCorner.Parent = toggleBg

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.new(0, 20, 0, 20)
	knob.Position = UDim2.new(0, 2, 0.5, -10)
	knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	knob.Parent = toggleBg
	knob.ZIndex = 8

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(0.5, 0)
	knobCorner.Parent = knob

	-- Click handler
	local btn = Instance.new("TextButton")
	btn.Name = "ClickArea"
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Parent = container
	btn.ZIndex = 9

	local isOn = settings[name] or false

	local function updateVisual()
		if isOn then
			toggleBg.BackgroundColor3 = Color3.fromRGB(30, 215, 96)
			knob.Position = UDim2.new(1, -22, 0.5, -10)
		else
			toggleBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			knob.Position = UDim2.new(0, 2, 0.5, -10)
		end
	end

	updateVisual()

	btn.MouseButton1Click:Connect(function()
		isOn = not isOn
		settings[name] = isOn
		updateVisual()
		Remotes.UpdateSetting:FireServer(name, isOn)
		SettingsUI.ApplySetting(name, isOn)
	end)

	return container
end

function SettingsUI.ApplySetting(name, value)
	if name == "hidePlayers" then
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= player and otherPlayer.Character then
				for _, part in ipairs(otherPlayer.Character:GetDescendants()) do
					if part:IsA("BasePart") or part:IsA("Decal") then
						part.Transparency = if value then 1 else 0
					elseif part:IsA("BillboardGui") or part:IsA("ParticleEmitter") or part:IsA("Trail") then
						part.Enabled = not value
					end
				end
			end
		end
	elseif name == "hideAura" then
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= player and otherPlayer.Character then
				local hrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local aura = hrp:FindFirstChild("SummitAura")
					if aura then
						aura.Enabled = not value
					end
				end
			end
		end
	elseif name == "hideTrail" then
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= player and otherPlayer.Character then
				local trail = otherPlayer.Character:FindFirstChild("SummitTrail")
				if trail then
					trail.Enabled = not value
				end
			end
		end
	end
end

function SettingsUI.Init(frame)
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "SettingsTitle"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Text = "SETTINGS"
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	title.ZIndex = 6

	-- Scroll for settings
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "SettingsScroll"
	scroll.Size = UDim2.new(1, -10, 1, -45)
	scroll.Position = UDim2.new(0, 5, 0, 40)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scroll.Parent = frame
	scroll.ZIndex = 6

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = scroll

	createToggle("hidePlayers", "Hide Other Players", 0, scroll)
	createToggle("hideAura", "Hide Auras", 0, scroll)
	createToggle("hideTrail", "Hide Trails", 0, scroll)

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
end

return SettingsUI
