--!strict
-- Lobby selection screen. Shows 4 lobby cards with live state, join/leave buttons,
-- and top bar with coin display + shop button + rules button.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(Shared:WaitForChild("Theme"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local LobbyUI = {}
LobbyUI.__index = LobbyUI

local STATE_COLORS = {
	Idle = Color3.fromRGB(150, 158, 172),
	Countdown = Color3.fromRGB(250, 205, 100),
	InMatch = Color3.fromRGB(230, 90, 90),
	Ending = Color3.fromRGB(120, 170, 255),
}
local STATE_LABELS = {
	Idle = "Menunggu pemain",
	Countdown = "Countdown",
	InMatch = "Match berjalan",
	Ending = "Selesai...",
}

function LobbyUI.new(gui: ScreenGui)
	local self = setmetatable({}, LobbyUI)
	self.minimized = false
	self.visible = true

	local root = Instance.new("Frame")
	root.Name = "LobbyRoot"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = gui
	self.root = root

	-- Floating "OPEN LOBBY" pill shown when the full UI is minimized.
	local reopenPill = Instance.new("TextButton")
	reopenPill.Name = "ReopenLobbyPill"
	reopenPill.Size = UDim2.fromOffset(200, 36)
	reopenPill.AnchorPoint = Vector2.new(0.5, 0)
	reopenPill.Position = UDim2.new(0.5, 0, 0, 12)
	reopenPill.BackgroundColor3 = Theme.Colors.Bg
	reopenPill.AutoButtonColor = false
	reopenPill.Font = Theme.FontBold
	reopenPill.TextSize = 14
	reopenPill.TextColor3 = Theme.Colors.Text
	reopenPill.Text = "OPEN LOBBY  [M]"
	reopenPill.Visible = false
	reopenPill.ZIndex = 50
	reopenPill.Parent = gui
	Theme.applyCorner(reopenPill, UDim.new(0, 18))
	Theme.applyStroke(reopenPill, Theme.Colors.Stroke)
	self.reopenPill = reopenPill
	reopenPill.MouseEnter:Connect(function()
		reopenPill.BackgroundColor3 = Theme.Colors.Panel
	end)
	reopenPill.MouseLeave:Connect(function()
		reopenPill.BackgroundColor3 = Theme.Colors.Bg
	end)
	reopenPill.MouseButton1Click:Connect(function()
		self:setMinimized(false)
	end)

	-- Top bar
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 60)
	topBar.BackgroundColor3 = Theme.Colors.Bg
	topBar.BorderSizePixel = 0
	topBar.Parent = root
	Theme.applyStroke(topBar, Theme.Colors.Stroke)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0, 300, 1, 0)
	titleLabel.Position = UDim2.fromOffset(20, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Theme.FontBold
	titleLabel.TextSize = 22
	titleLabel.TextColor3 = Theme.Colors.Text
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "BENTENGAN / LOBBY"
	titleLabel.Parent = topBar

	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Size = UDim2.fromOffset(200, 40)
	coinsLabel.AnchorPoint = Vector2.new(1, 0.5)
	coinsLabel.Position = UDim2.new(1, -360, 0.5, 0)
	coinsLabel.BackgroundColor3 = Theme.Colors.Panel
	coinsLabel.Font = Theme.FontBold
	coinsLabel.TextSize = 16
	coinsLabel.TextColor3 = Theme.Colors.Gold
	coinsLabel.Text = "★ 0"
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Center
	coinsLabel.Parent = topBar
	Theme.applyCorner(coinsLabel, Theme.SmallRadius)
	Theme.applyStroke(coinsLabel, Theme.Colors.Stroke)
	self.coinsLabel = coinsLabel

	local rulesBtn = Instance.new("TextButton")
	rulesBtn.Size = UDim2.fromOffset(100, 40)
	rulesBtn.AnchorPoint = Vector2.new(1, 0.5)
	rulesBtn.Position = UDim2.new(1, -350, 0.5, 0)
	rulesBtn.BackgroundColor3 = Theme.Colors.Panel
	rulesBtn.AutoButtonColor = false
	rulesBtn.Font = Theme.FontMed
	rulesBtn.TextSize = 14
	rulesBtn.TextColor3 = Theme.Colors.Text
	rulesBtn.Text = "RULES"
	rulesBtn.Parent = topBar
	Theme.applyCorner(rulesBtn, Theme.SmallRadius)
	Theme.applyStroke(rulesBtn, Theme.Colors.Stroke)
	self.rulesBtn = rulesBtn

	local shopBtn = Instance.new("TextButton")
	shopBtn.Size = UDim2.fromOffset(100, 40)
	shopBtn.AnchorPoint = Vector2.new(1, 0.5)
	shopBtn.Position = UDim2.new(1, -130, 0.5, 0)
	shopBtn.BackgroundColor3 = Theme.Colors.Accent
	shopBtn.AutoButtonColor = false
	shopBtn.Font = Theme.FontBold
	shopBtn.TextSize = 14
	shopBtn.TextColor3 = Color3.new(0, 0, 0)
	shopBtn.Text = "SHOP"
	shopBtn.Parent = topBar
	Theme.applyCorner(shopBtn, Theme.SmallRadius)
	self.shopBtn = shopBtn

	local leaveBtn = Instance.new("TextButton")
	leaveBtn.Size = UDim2.fromOffset(110, 40)
	leaveBtn.AnchorPoint = Vector2.new(1, 0.5)
	leaveBtn.Position = UDim2.new(1, -20, 0.5, 0)
	leaveBtn.BackgroundColor3 = Theme.Colors.Danger
	leaveBtn.AutoButtonColor = false
	leaveBtn.Font = Theme.FontBold
	leaveBtn.TextSize = 14
	leaveBtn.TextColor3 = Color3.new(1, 1, 1)
	leaveBtn.Text = "LEAVE LOBBY"
	leaveBtn.Visible = false
	leaveBtn.Parent = topBar
	Theme.applyCorner(leaveBtn, Theme.SmallRadius)
	self.leaveBtn = leaveBtn

	-- Minimize button: collapses the full lobby UI so the player can walk
	-- around the lobby pad freely. Re-opens via the floating pill or [M] key.
	local minimizeBtn = Instance.new("TextButton")
	minimizeBtn.Size = UDim2.fromOffset(44, 40)
	minimizeBtn.AnchorPoint = Vector2.new(1, 0.5)
	minimizeBtn.Position = UDim2.new(1, -240, 0.5, 0)
	minimizeBtn.BackgroundColor3 = Theme.Colors.Panel
	minimizeBtn.AutoButtonColor = false
	minimizeBtn.Font = Theme.FontBold
	minimizeBtn.TextSize = 20
	minimizeBtn.TextColor3 = Theme.Colors.Text
	minimizeBtn.Text = "—"
	minimizeBtn.Parent = topBar
	Theme.applyCorner(minimizeBtn, Theme.SmallRadius)
	Theme.applyStroke(minimizeBtn, Theme.Colors.Stroke)
	minimizeBtn.MouseEnter:Connect(function()
		minimizeBtn.BackgroundColor3 = Theme.Colors.PanelAlt
	end)
	minimizeBtn.MouseLeave:Connect(function()
		minimizeBtn.BackgroundColor3 = Theme.Colors.Panel
	end)
	minimizeBtn.MouseButton1Click:Connect(function()
		self:setMinimized(true)
	end)
	self.minimizeBtn = minimizeBtn

	-- Grid of lobbies
	local grid = Instance.new("Frame")
	grid.Size = UDim2.new(1, -40, 1, -100)
	grid.Position = UDim2.fromOffset(20, 80)
	grid.BackgroundTransparency = 1
	grid.Parent = root
	self.grid = grid

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.5, -10, 0.5, -10)
	gridLayout.CellPadding = UDim2.fromOffset(20, 20)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = grid

	self.cards = {}
	for i = 1, GameConfig.NumLobbies do
		self.cards[i] = self:_buildCard(i, grid)
	end

	-- Hooks
	leaveBtn.MouseButton1Click:Connect(function()
		if self.onLeaveClicked then
			self.onLeaveClicked()
		end
		Remotes.RequestLeaveLobby:FireServer()
	end)

	return self
end

function LobbyUI:_buildCard(index: number, parent: Instance)
	local card = Instance.new("Frame")
	card.LayoutOrder = index
	card.BackgroundColor3 = Theme.Colors.Panel
	card.BorderSizePixel = 0
	card.Parent = parent
	Theme.applyCorner(card)
	Theme.applyStroke(card, Theme.Colors.Stroke)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -30, 0, 30)
	title.Position = UDim2.fromOffset(20, 18)
	title.BackgroundTransparency = 1
	title.Font = Theme.FontBold
	title.TextSize = 22
	title.TextColor3 = Theme.Colors.Text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Lobby " .. index
	title.Parent = card

	local stateLabel = Instance.new("TextLabel")
	stateLabel.Size = UDim2.fromOffset(160, 24)
	stateLabel.AnchorPoint = Vector2.new(1, 0)
	stateLabel.Position = UDim2.new(1, -20, 0, 22)
	stateLabel.BackgroundTransparency = 1
	stateLabel.Font = Theme.FontBold
	stateLabel.TextSize = 14
	stateLabel.TextColor3 = STATE_COLORS.Idle
	stateLabel.TextXAlignment = Enum.TextXAlignment.Right
	stateLabel.Text = STATE_LABELS.Idle
	stateLabel.Parent = card

	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(1, -40, 0, 60)
	countLabel.Position = UDim2.fromOffset(20, 60)
	countLabel.BackgroundTransparency = 1
	countLabel.Font = Theme.FontBold
	countLabel.TextSize = 46
	countLabel.TextColor3 = Theme.Colors.Text
	countLabel.TextXAlignment = Enum.TextXAlignment.Left
	countLabel.Text = "0 / " .. GameConfig.MaxPlayersPerLobby
	countLabel.Parent = card

	local subLabel = Instance.new("TextLabel")
	subLabel.Size = UDim2.new(1, -40, 0, 20)
	subLabel.Position = UDim2.fromOffset(20, 120)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = Theme.Font
	subLabel.TextSize = 14
	subLabel.TextColor3 = Theme.Colors.TextDim
	subLabel.TextXAlignment = Enum.TextXAlignment.Left
	subLabel.Text = "Minimal " .. GameConfig.MinPlayersPerLobby .. " pemain untuk mulai"
	subLabel.Parent = card

	local joinBtn = Instance.new("TextButton")
	joinBtn.Size = UDim2.new(1, -40, 0, 42)
	joinBtn.AnchorPoint = Vector2.new(0, 1)
	joinBtn.Position = UDim2.new(0, 20, 1, -20)
	joinBtn.BackgroundColor3 = Theme.Colors.Accent
	joinBtn.AutoButtonColor = false
	joinBtn.Font = Theme.FontBold
	joinBtn.TextSize = 16
	joinBtn.TextColor3 = Color3.new(0, 0, 0)
	joinBtn.Text = "JOIN LOBBY"
	joinBtn.Parent = card
	Theme.applyCorner(joinBtn, Theme.SmallRadius)

	joinBtn.MouseEnter:Connect(function()
		joinBtn.BackgroundColor3 = Theme.Colors.AccentAlt
	end)
	joinBtn.MouseLeave:Connect(function()
		joinBtn.BackgroundColor3 = Theme.Colors.Accent
	end)

	joinBtn.MouseButton1Click:Connect(function()
		if self.onJoinClicked then
			self.onJoinClicked(index)
		end
		Remotes.RequestJoinLobby:FireServer(index)
	end)

	return {
		Frame = card,
		Title = title,
		State = stateLabel,
		Count = countLabel,
		Sub = subLabel,
		Join = joinBtn,
	}
end

function LobbyUI:setVisible(v: boolean)
	self.visible = v
	self:_render()
end

function LobbyUI:setMinimized(m: boolean)
	self.minimized = m
	self:_render()
end

function LobbyUI:toggleMinimized()
	self:setMinimized(not self.minimized)
end

function LobbyUI:_render()
	local showFull = self.visible and not self.minimized
	self.root.Visible = showFull
	self.reopenPill.Visible = self.visible and self.minimized
end

function LobbyUI:updateCoins(amount: number)
	self.coinsLabel.Text = "★ " .. tostring(amount)
end

function LobbyUI:updateLobbies(snapshot: { [number]: any }, myLobbyIndex: number?)
	for i, data in snapshot do
		local card = self.cards[i]
		if not card then
			continue
		end
		card.Count.Text = string.format("%d / %d", data.Count, data.Max)
		card.State.Text = STATE_LABELS[data.State] or data.State
		card.State.TextColor3 = STATE_COLORS[data.State] or Theme.Colors.TextDim
		if data.State == "Countdown" then
			local remaining = math.max(0, math.floor(data.CountdownEndsAt - os.clock()))
			card.Sub.Text = "Mulai dalam " .. remaining .. "s"
		elseif data.State == "InMatch" then
			local remaining = math.max(0, math.floor(data.MatchEndsAt - os.clock()))
			card.Sub.Text = "Sisa match: " .. remaining .. "s"
		else
			card.Sub.Text = "Minimal " .. data.Min .. " pemain untuk mulai"
		end

		if myLobbyIndex == i then
			card.Join.Text = "JOINED"
			card.Join.BackgroundColor3 = Theme.Colors.AccentAlt
			card.Join.Active = false
		else
			local canJoin = data.Count < data.Max and (data.State == "Idle" or data.State == "Countdown")
			card.Join.Text = canJoin and "JOIN LOBBY" or (if data.State == "InMatch" then "IN MATCH" else "FULL")
			card.Join.BackgroundColor3 = canJoin and Theme.Colors.Accent or Theme.Colors.Panel
			card.Join.TextColor3 = canJoin and Color3.new(0, 0, 0) or Theme.Colors.TextDim
			card.Join.Active = canJoin
		end
	end

	self.leaveBtn.Visible = myLobbyIndex ~= nil
end

return LobbyUI
