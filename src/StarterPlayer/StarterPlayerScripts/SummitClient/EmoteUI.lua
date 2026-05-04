--[[
	EmoteUI
	Emote selection page inside the phone menu.
	Shows grid of emotes from EmoteList module and ReplicatedStorage.Emotes folder.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SummitShared = ReplicatedStorage:WaitForChild("SummitShared")
local EmoteList = require(SummitShared:WaitForChild("EmoteList"))
local Remotes = require(SummitShared:WaitForChild("Remotes"))

local EmoteUI = {}

local function loadEmotes()
	local emotes = {}
	-- From module
	for _, emote in ipairs(EmoteList.Emotes) do
		table.insert(emotes, emote)
	end
	-- From folder
	local emotesFolder = ReplicatedStorage:FindFirstChild("Emotes")
	if emotesFolder then
		for _, obj in ipairs(emotesFolder:GetChildren()) do
			if obj:IsA("Animation") then
				table.insert(emotes, {
					id = obj.AnimationId,
					name = obj.Name,
					icon = obj:GetAttribute("Icon") or "rbxassetid://6031071057",
				})
			end
		end
	end
	return emotes
end

function EmoteUI.Init(frame)
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "EmoteTitle"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Text = "EMOTES"
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	title.ZIndex = 6

	-- Stop emote button
	local stopBtn = Instance.new("TextButton")
	stopBtn.Name = "StopEmote"
	stopBtn.Size = UDim2.new(0.6, 0, 0, 30)
	stopBtn.Position = UDim2.new(0.2, 0, 0, 35)
	stopBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
	stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	stopBtn.Text = "Stop Emote"
	stopBtn.TextSize = 13
	stopBtn.Font = Enum.Font.GothamBold
	stopBtn.BorderSizePixel = 0
	stopBtn.Parent = frame
	stopBtn.ZIndex = 7

	local stopCorner = Instance.new("UICorner")
	stopCorner.CornerRadius = UDim.new(0, 8)
	stopCorner.Parent = stopBtn

	stopBtn.MouseButton1Click:Connect(function()
		Remotes.PlayEmote:FireServer(nil)
	end)

	-- Scroll frame for emotes grid
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "EmoteScroll"
	scroll.Size = UDim2.new(1, -10, 1, -80)
	scroll.Position = UDim2.new(0, 5, 0, 72)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scroll.Parent = frame
	scroll.ZIndex = 6

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 75, 0, 90)
	gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.Parent = scroll

	local emotes = loadEmotes()

	for i, emote in ipairs(emotes) do
		local emoteBtn = Instance.new("TextButton")
		emoteBtn.Name = "Emote_" .. emote.name
		emoteBtn.Size = UDim2.new(0, 75, 0, 90)
		emoteBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		emoteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		emoteBtn.Text = ""
		emoteBtn.BorderSizePixel = 0
		emoteBtn.LayoutOrder = i
		emoteBtn.Parent = scroll
		emoteBtn.ZIndex = 7

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 10)
		btnCorner.Parent = emoteBtn

		-- Icon placeholder
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.new(1, 0, 0.6, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		iconLabel.Text = "💃"
		iconLabel.TextSize = 28
		iconLabel.Parent = emoteBtn
		iconLabel.ZIndex = 8

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "EmoteName"
		nameLabel.Size = UDim2.new(1, -4, 0.35, 0)
		nameLabel.Position = UDim2.new(0, 2, 0.65, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		nameLabel.Text = emote.name
		nameLabel.TextSize = 10
		nameLabel.TextWrapped = true
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.Parent = emoteBtn
		nameLabel.ZIndex = 8

		emoteBtn.MouseButton1Click:Connect(function()
			Remotes.PlayEmote:FireServer(emote.name)
		end)
	end

	gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 10)
	end)
end

return EmoteUI
