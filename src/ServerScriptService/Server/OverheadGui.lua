--!strict
-- Adds a BillboardGui above every player's head showing their current Title
-- (if any), username, and Wins count. Live-updates when leaderstats.Wins
-- changes or when TitleService updates the player's title.

local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)

local OverheadGui = {}

-- Per-player references so we can mutate labels later (e.g. setTitle).
local labelsByPlayer: { [Player]: { Title: TextLabel, Name: TextLabel, Wins: TextLabel } } = {}

local function applyTitleText(label: TextLabel, title: string)
	if title and title ~= "" then
		label.Text = title
		label.Visible = true
	else
		label.Text = ""
		label.Visible = false
	end
end

local function buildGui(player: Player, head: BasePart)
	local existing = head:FindFirstChild("BentenganOverhead")
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "BentenganOverhead"
	gui.Size = UDim2.new(0, 220, 0, 72)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
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

	-- Custom title (gold, smaller). Hidden when empty.
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 18)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 14
	titleLabel.TextColor3 = Color3.fromRGB(255, 200, 70)
	titleLabel.TextStrokeTransparency = 0.2
	titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	titleLabel.Text = ""
	titleLabel.Visible = false
	titleLabel.LayoutOrder = 1
	titleLabel.Parent = container

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 26)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.Text = player.DisplayName
	nameLabel.LayoutOrder = 2
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
	winsLabel.LayoutOrder = 3
	winsLabel.Parent = container

	return titleLabel, nameLabel, winsLabel
end

local function attachToCharacter(player: Player, character: Model)
	local head = character:WaitForChild("Head", 5)
	if not head or not head:IsA("BasePart") then
		return
	end
	local titleLabel, nameLabel, winsLabel = buildGui(player, head)
	labelsByPlayer[player] = { Title = titleLabel, Name = nameLabel, Wins = winsLabel }

	-- Hide the default username display so ours is the only overhead label.
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	-- Initial title from profile.
	local profile = DataService.getProfile(player)
	applyTitleText(titleLabel, profile.Title or "")

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

function OverheadGui.setTitle(player: Player, title: string)
	local labels = labelsByPlayer[player]
	if not labels then
		return
	end
	applyTitleText(labels.Title, title or "")
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
	Players.PlayerRemoving:Connect(function(p)
		labelsByPlayer[p] = nil
	end)
end

return OverheadGui
