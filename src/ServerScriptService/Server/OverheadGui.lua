--!strict
-- Adds a BillboardGui above every player's head showing their username and
-- current Wins count. Updates live when the leaderstats.Wins value changes.

local Players = game:GetService("Players")

local OverheadGui = {}

local function buildGui(player: Player, head: BasePart)
	local existing = head:FindFirstChild("BentenganOverhead")
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "BentenganOverhead"
	gui.Size = UDim2.new(0, 200, 0, 50)
	gui.StudsOffset = Vector3.new(0, 2.4, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 80
	gui.Parent = head

	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 0)
	layout.Parent = container

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 26)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.Text = player.DisplayName
	nameLabel.LayoutOrder = 1
	nameLabel.Parent = container

	local winsLabel = Instance.new("TextLabel")
	winsLabel.Size = UDim2.new(1, 0, 0, 20)
	winsLabel.BackgroundTransparency = 1
	winsLabel.Font = Enum.Font.GothamBold
	winsLabel.TextSize = 14
	winsLabel.TextColor3 = Color3.fromRGB(255, 215, 120)
	winsLabel.TextStrokeTransparency = 0.3
	winsLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	winsLabel.Text = "★ 0 wins"
	winsLabel.LayoutOrder = 2
	winsLabel.Parent = container

	return winsLabel
end

local function attachToCharacter(player: Player, character: Model)
	local head = character:WaitForChild("Head", 5)
	if not head or not head:IsA("BasePart") then
		return
	end
	local winsLabel = buildGui(player, head)

	-- Hide the default username display so ours is the only overhead label.
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	local function refresh()
		local folder = player:FindFirstChild("leaderstats")
		local winsStat = folder and folder:FindFirstChild("Wins")
		local wins = 0
		if winsStat and winsStat:IsA("IntValue") then
			wins = winsStat.Value
		end
		winsLabel.Text = string.format("★ %d wins", wins)
	end

	refresh()

	-- Watch for leaderstats.Wins changes. The folder may not exist yet when
	-- the character first loads, so keep polling briefly until it shows up.
	task.spawn(function()
		local deadline = os.clock() + 5
		while os.clock() < deadline do
			local folder = player:FindFirstChild("leaderstats")
			local winsStat = folder and folder:FindFirstChild("Wins")
			if winsStat and winsStat:IsA("IntValue") then
				winsStat:GetPropertyChangedSignal("Value"):Connect(refresh)
				refresh()
				return
			end
			task.wait(0.25)
		end
	end)
end

function OverheadGui.attach(player: Player)
	if player.Character then
		attachToCharacter(player, player.Character)
	end
	player.CharacterAdded:Connect(function(char)
		attachToCharacter(player, char)
	end)
end

function OverheadGui.init()
	for _, p in Players:GetPlayers() do
		OverheadGui.attach(p)
	end
	Players.PlayerAdded:Connect(OverheadGui.attach)
end

return OverheadGui
