--[[
	SkyUI - Sky selection menu in phone
	Options: Galaxy Sky (Lighting), Purple Galaxy (ReplicatedStorage), Sky (ReplicatedStorage), Default
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteFolder = ReplicatedStorage:WaitForChild("SummitRemotes")
local ChangeSky = remoteFolder:WaitForChild("ChangeSky")

local SkyUI = {}

local skyOptions = {
	{ name = "Galaxy Sky", source = "Lighting" },
	{ name = "Purple Galaxy", source = "ReplicatedStorage" },
	{ name = "Sky", source = "ReplicatedStorage" },
	{ name = "Default", source = "none" },
}

local currentSky = nil

local function applySky(skyName)
	-- Remove current custom sky from PlayerGui Lighting
	local existingSky = Lighting:FindFirstChildOfClass("Sky")

	if skyName == "Default" then
		-- Remove all custom skies, revert to default
		if currentSky then
			currentSky:Destroy()
			currentSky = nil
		end
		return
	end

	-- Find the sky object
	local skyObj = nil

	if skyName == "Galaxy Sky" then
		skyObj = Lighting:FindFirstChild("Galaxy Sky")
	else
		skyObj = ReplicatedStorage:FindFirstChild(skyName)
	end

	if not skyObj then
		warn("[SkyUI] Sky '" .. skyName .. "' not found!")
		return
	end

	-- Remove old custom sky
	if currentSky then
		currentSky:Destroy()
		currentSky = nil
	end

	-- If it's already in Lighting and named Galaxy Sky, just enable it
	if skyName == "Galaxy Sky" and existingSky and existingSky.Name == "Galaxy Sky" then
		existingSky.Parent = Lighting
		currentSky = existingSky
		return
	end

	-- Clone sky to Lighting
	if existingSky and existingSky ~= skyObj then
		existingSky:Destroy()
	end

	local clone = skyObj:Clone()
	clone.Parent = Lighting
	currentSky = clone
end

function SkyUI.CreateMenu(parent)
	local frame = Instance.new("Frame")
	frame.Name = "SkyMenu"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 35)
	title.BackgroundTransparency = 1
	title.Text = "\u{1F30C} Change Sky"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 40)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = frame

	for _, option in ipairs(skyOptions) do
		local btn = Instance.new("TextButton")
		btn.Name = option.name
		btn.Size = UDim2.new(1, 0, 0, 45)
		btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Text = option.name
		btn.TextSize = 14
		btn.Font = Enum.Font.GothamBold
		btn.Parent = frame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn

		btn.MouseButton1Click:Connect(function()
			ChangeSky:FireServer(option.name)
		end)
	end

	return frame
end

function SkyUI.Init()
	ChangeSky.OnClientEvent:Connect(function(skyName)
		applySky(skyName)
		print("[SkyUI] Sky changed to: " .. skyName)
	end)
end

return SkyUI
