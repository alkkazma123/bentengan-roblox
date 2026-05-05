--[[
	EmoteUI - Emote grid inside phone
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EmoteList = require(Shared:WaitForChild("EmoteList"))

local remoteFolder = ReplicatedStorage:WaitForChild("SummitRemotes")
local PlayEmote = remoteFolder:WaitForChild("PlayEmote")

local EmoteUI = {}

local function getEmotes()
	local emotes = {}
	for _, e in ipairs(EmoteList.Emotes) do
		table.insert(emotes, e)
	end
	local folder = ReplicatedStorage:FindFirstChild("Emotes")
	if folder then
		for _, anim in ipairs(folder:GetChildren()) do
			if anim:IsA("Animation") then
				table.insert(emotes, { id = anim.AnimationId, name = anim.Name })
			end
		end
	end
	return emotes
end

function EmoteUI.Init(frame)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 25)
	title.BackgroundTransparency = 1
	title.Text = "EMOTES"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	title.ZIndex = 6

	-- Stop button
	local stopBtn = Instance.new("TextButton")
	stopBtn.Size = UDim2.new(0, 60, 0, 24)
	stopBtn.Position = UDim2.new(1, -65, 0, 2)
	stopBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
	stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	stopBtn.Text = "STOP"
	stopBtn.TextSize = 10
	stopBtn.Font = Enum.Font.GothamBold
	stopBtn.Parent = frame
	stopBtn.ZIndex = 7

	local stopCorner = Instance.new("UICorner")
	stopCorner.CornerRadius = UDim.new(0, 6)
	stopCorner.Parent = stopBtn

	stopBtn.MouseButton1Click:Connect(function()
		PlayEmote:FireServer(nil)
	end)

	-- Scroll with grid
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -10, 1, -35)
	scroll.Position = UDim2.new(0, 5, 0, 30)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 3
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = frame
	scroll.ZIndex = 6

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 75, 0, 80)
	grid.CellPadding = UDim2.new(0, 6, 0, 6)
	grid.Parent = scroll

	local emotes = getEmotes()

	if #emotes == 0 then
		local noEmotes = Instance.new("TextLabel")
		noEmotes.Size = UDim2.new(1, 0, 0, 40)
		noEmotes.BackgroundTransparency = 1
		noEmotes.Text = "No emotes yet.\nAdd to EmoteList or Emotes folder."
		noEmotes.TextColor3 = Color3.fromRGB(150, 150, 150)
		noEmotes.TextSize = 11
		noEmotes.Font = Enum.Font.Gotham
		noEmotes.Parent = scroll
		noEmotes.ZIndex = 6
		return
	end

	for _, emote in ipairs(emotes) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 75, 0, 80)
		btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Text = emote.name
		btn.TextSize = 10
		btn.Font = Enum.Font.Gotham
		btn.TextYAlignment = Enum.TextYAlignment.Bottom
		btn.Parent = scroll
		btn.ZIndex = 7

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn

		local emoteName = emote.name
		btn.MouseButton1Click:Connect(function()
			PlayEmote:FireServer(emoteName)
		end)
	end
end

return EmoteUI
