--!strict
-- Daily login bonus popup + spin wheel UI. The server is authoritative for
-- both timing and reward picks; this module only renders state and forwards
-- click events.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local DailyRewardsUI = {}
DailyRewardsUI.__index = DailyRewardsUI

local STREAK_REWARDS = { 50, 75, 100, 150, 200, 300, 500 }

local function formatHMS(sec: number): string
	if sec <= 0 then
		return "siap!"
	end
	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = math.floor(sec % 60)
	return string.format("%02d:%02d:%02d", h, m, s)
end

-- ===== Login popup =====

local function buildLoginPopup(parent: ScreenGui)
	local backdrop = Instance.new("Frame")
	backdrop.Name = "LoginBonusBackdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.4
	backdrop.BorderSizePixel = 0
	backdrop.Visible = false
	backdrop.ZIndex = 60
	backdrop.Parent = parent

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(440, 360)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3 = Theme.Colors.Bg
	panel.BorderSizePixel = 0
	panel.ZIndex = 61
	panel.Parent = backdrop
	Theme.applyCorner(panel)
	Theme.applyStroke(panel, Theme.Colors.Stroke)

	local sizeC = Instance.new("UISizeConstraint")
	sizeC.MinSize = Vector2.new(280, 320)
	sizeC.MaxSize = Vector2.new(520, 420)
	sizeC.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 40)
	title.Position = UDim2.fromOffset(10, 10)
	title.BackgroundTransparency = 1
	title.Font = Theme.FontBold
	title.TextSize = 24
	title.TextColor3 = Theme.Colors.Gold
	title.Text = "BONUS LOGIN HARIAN"
	title.ZIndex = 62
	title.Parent = panel

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -20, 0, 22)
	sub.Position = UDim2.fromOffset(10, 50)
	sub.BackgroundTransparency = 1
	sub.Font = Theme.Font
	sub.TextSize = 14
	sub.TextColor3 = Theme.Colors.TextDim
	sub.Text = "Login tiap hari supaya streak naik!"
	sub.ZIndex = 62
	sub.Parent = panel

	local strip = Instance.new("Frame")
	strip.Size = UDim2.new(1, -20, 0, 80)
	strip.Position = UDim2.fromOffset(10, 80)
	strip.BackgroundTransparency = 1
	strip.ZIndex = 62
	strip.Parent = panel

	local stripLayout = Instance.new("UIListLayout")
	stripLayout.FillDirection = Enum.FillDirection.Horizontal
	stripLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	stripLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	stripLayout.Padding = UDim.new(0, 4)
	stripLayout.Parent = strip

	local dayCells = {}
	for i, reward in STREAK_REWARDS do
		local cell = Instance.new("Frame")
		cell.Size = UDim2.fromOffset(54, 70)
		cell.BackgroundColor3 = Theme.Colors.Panel
		cell.BorderSizePixel = 0
		cell.LayoutOrder = i
		cell.ZIndex = 63
		cell.Parent = strip
		Theme.applyCorner(cell, Theme.SmallRadius)
		Theme.applyStroke(cell, Theme.Colors.Stroke)

		local dayLbl = Instance.new("TextLabel")
		dayLbl.Size = UDim2.new(1, 0, 0, 18)
		dayLbl.Position = UDim2.fromOffset(0, 4)
		dayLbl.BackgroundTransparency = 1
		dayLbl.Font = Theme.FontMed
		dayLbl.TextSize = 11
		dayLbl.TextColor3 = Theme.Colors.TextDim
		dayLbl.Text = "Hari " .. i
		dayLbl.ZIndex = 64
		dayLbl.Parent = cell

		local rewardLbl = Instance.new("TextLabel")
		rewardLbl.Size = UDim2.new(1, 0, 0, 28)
		rewardLbl.Position = UDim2.fromOffset(0, 22)
		rewardLbl.BackgroundTransparency = 1
		rewardLbl.Font = Theme.FontBold
		rewardLbl.TextSize = 18
		rewardLbl.TextColor3 = Theme.Colors.Gold
		rewardLbl.Text = "★" .. reward
		rewardLbl.ZIndex = 64
		rewardLbl.Parent = cell

		local check = Instance.new("TextLabel")
		check.Size = UDim2.new(1, 0, 0, 16)
		check.Position = UDim2.new(0, 0, 1, -18)
		check.BackgroundTransparency = 1
		check.Font = Theme.FontBold
		check.TextSize = 14
		check.TextColor3 = Theme.Colors.AccentAlt
		check.Text = ""
		check.ZIndex = 64
		check.Parent = cell

		dayCells[i] = { Frame = cell, Check = check, DayLbl = dayLbl, RewardLbl = rewardLbl }
	end

	local rewardLine = Instance.new("TextLabel")
	rewardLine.Size = UDim2.new(1, -20, 0, 36)
	rewardLine.Position = UDim2.fromOffset(10, 174)
	rewardLine.BackgroundTransparency = 1
	rewardLine.Font = Theme.FontBold
	rewardLine.TextSize = 22
	rewardLine.TextColor3 = Theme.Colors.Text
	rewardLine.Text = "+ ★0"
	rewardLine.ZIndex = 62
	rewardLine.Parent = panel

	local statusLine = Instance.new("TextLabel")
	statusLine.Size = UDim2.new(1, -20, 0, 24)
	statusLine.Position = UDim2.fromOffset(10, 212)
	statusLine.BackgroundTransparency = 1
	statusLine.Font = Theme.Font
	statusLine.TextSize = 14
	statusLine.TextColor3 = Theme.Colors.TextDim
	statusLine.Text = ""
	statusLine.ZIndex = 62
	statusLine.Parent = panel

	local claimBtn = Instance.new("TextButton")
	claimBtn.Size = UDim2.new(1, -40, 0, 50)
	claimBtn.Position = UDim2.fromOffset(20, 248)
	claimBtn.BackgroundColor3 = Theme.Colors.AccentAlt
	claimBtn.AutoButtonColor = false
	claimBtn.Font = Theme.FontBold
	claimBtn.TextSize = 18
	claimBtn.TextColor3 = Color3.new(0, 0, 0)
	claimBtn.Text = "KLAIM"
	claimBtn.ZIndex = 62
	claimBtn.Parent = panel
	Theme.applyCorner(claimBtn, Theme.SmallRadius)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(36, 36)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -10, 0, 10)
	closeBtn.BackgroundColor3 = Theme.Colors.Danger
	closeBtn.AutoButtonColor = false
	closeBtn.Font = Theme.FontBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Text = "X"
	closeBtn.ZIndex = 62
	closeBtn.Parent = panel
	Theme.applyCorner(closeBtn, UDim.new(0, 8))

	return {
		Backdrop = backdrop,
		Panel = panel,
		Cells = dayCells,
		Reward = rewardLine,
		Status = statusLine,
		Claim = claimBtn,
		Close = closeBtn,
	}
end

-- ===== Spin wheel =====

local SEGMENT_COLORS = {
	Color3.fromRGB(120, 170, 255),
	Color3.fromRGB(90, 220, 180),
	Color3.fromRGB(250, 205, 100),
	Color3.fromRGB(230, 120, 200),
	Color3.fromRGB(120, 170, 255),
	Color3.fromRGB(90, 220, 180),
	Color3.fromRGB(250, 205, 100),
	Color3.fromRGB(230, 120, 200),
}

local function buildSpinPanel(parent: ScreenGui)
	local backdrop = Instance.new("Frame")
	backdrop.Name = "SpinBackdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.4
	backdrop.BorderSizePixel = 0
	backdrop.Visible = false
	backdrop.ZIndex = 70
	backdrop.Parent = parent

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(440, 520)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3 = Theme.Colors.Bg
	panel.BorderSizePixel = 0
	panel.ZIndex = 71
	panel.Parent = backdrop
	Theme.applyCorner(panel)
	Theme.applyStroke(panel, Theme.Colors.Stroke)

	local sizeC = Instance.new("UISizeConstraint")
	sizeC.MinSize = Vector2.new(300, 460)
	sizeC.MaxSize = Vector2.new(520, 600)
	sizeC.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 40)
	title.Position = UDim2.fromOffset(10, 10)
	title.BackgroundTransparency = 1
	title.Font = Theme.FontBold
	title.TextSize = 24
	title.TextColor3 = Theme.Colors.Gold
	title.Text = "SPIN HARIAN"
	title.ZIndex = 72
	title.Parent = panel

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -20, 0, 20)
	sub.Position = UDim2.fromOffset(10, 50)
	sub.BackgroundTransparency = 1
	sub.Font = Theme.Font
	sub.TextSize = 13
	sub.TextColor3 = Theme.Colors.TextDim
	sub.Text = "Sekali per 24 jam"
	sub.ZIndex = 72
	sub.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(36, 36)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -10, 0, 10)
	closeBtn.BackgroundColor3 = Theme.Colors.Danger
	closeBtn.AutoButtonColor = false
	closeBtn.Font = Theme.FontBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Text = "X"
	closeBtn.ZIndex = 72
	closeBtn.Parent = panel
	Theme.applyCorner(closeBtn, UDim.new(0, 8))

	local wheelHolder = Instance.new("Frame")
	wheelHolder.Size = UDim2.fromOffset(280, 280)
	wheelHolder.AnchorPoint = Vector2.new(0.5, 0)
	wheelHolder.Position = UDim2.new(0.5, 0, 0, 80)
	wheelHolder.BackgroundTransparency = 1
	wheelHolder.ZIndex = 72
	wheelHolder.Parent = panel

	local wheel = Instance.new("Frame")
	wheel.Size = UDim2.fromScale(1, 1)
	wheel.AnchorPoint = Vector2.new(0.5, 0.5)
	wheel.Position = UDim2.fromScale(0.5, 0.5)
	wheel.BackgroundColor3 = Theme.Colors.Bg
	wheel.BorderSizePixel = 0
	wheel.ZIndex = 73
	wheel.Parent = wheelHolder
	local wheelCorner = Instance.new("UICorner")
	wheelCorner.CornerRadius = UDim.new(1, 0)
	wheelCorner.Parent = wheel
	Theme.applyStroke(wheel, Theme.Colors.Stroke, 2)

	-- Build 8 pie segments using triangle frames rotated around the center.
	-- Each segment is a half-disk colored frame masked by sibling frames; the
	-- simpler approach used here is 8 thin colored sectors built from 8 ImageLabels
	-- with rotation.
	local segmentCount = 8
	local segLabels = {}
	for i = 1, segmentCount do
		local seg = Instance.new("Frame")
		seg.Size = UDim2.fromScale(0.5, 0.5)
		seg.AnchorPoint = Vector2.new(0, 1)
		seg.Position = UDim2.fromScale(0.5, 0.5)
		seg.BackgroundColor3 = SEGMENT_COLORS[i]
		seg.BorderSizePixel = 0
		seg.Rotation = (i - 1) * (360 / segmentCount)
		seg.ZIndex = 74
		seg.Parent = wheel

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromOffset(60, 22)
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		-- Place near outer arc midpoint of the sector.
		label.Position = UDim2.new(0.4, 0, 0.2, 0)
		label.BackgroundTransparency = 1
		label.Font = Theme.FontBold
		label.TextSize = 16
		label.TextColor3 = Color3.new(0, 0, 0)
		label.Text = "★?"
		label.Rotation = -((i - 1) * (360 / segmentCount)) + (360 / segmentCount) / 2
		label.ZIndex = 75
		label.Parent = seg
		segLabels[i] = label
	end

	-- Center hub.
	local hub = Instance.new("Frame")
	hub.Size = UDim2.fromOffset(70, 70)
	hub.AnchorPoint = Vector2.new(0.5, 0.5)
	hub.Position = UDim2.fromScale(0.5, 0.5)
	hub.BackgroundColor3 = Theme.Colors.Bg
	hub.BorderSizePixel = 0
	hub.ZIndex = 76
	hub.Parent = wheel
	local hubCorner = Instance.new("UICorner")
	hubCorner.CornerRadius = UDim.new(1, 0)
	hubCorner.Parent = hub
	Theme.applyStroke(hub, Theme.Colors.Stroke, 2)

	-- Pointer (triangle arrow at top of wheel).
	local pointer = Instance.new("TextLabel")
	pointer.Size = UDim2.fromOffset(36, 36)
	pointer.AnchorPoint = Vector2.new(0.5, 0)
	pointer.Position = UDim2.new(0.5, 0, 0, -10)
	pointer.BackgroundTransparency = 1
	pointer.Font = Theme.FontBold
	pointer.TextSize = 36
	pointer.TextColor3 = Theme.Colors.Gold
	pointer.Text = "▼"
	pointer.ZIndex = 78
	pointer.Parent = wheelHolder

	local statusLine = Instance.new("TextLabel")
	statusLine.Size = UDim2.new(1, -20, 0, 24)
	statusLine.Position = UDim2.new(0, 10, 0, 376)
	statusLine.BackgroundTransparency = 1
	statusLine.Font = Theme.Font
	statusLine.TextSize = 14
	statusLine.TextColor3 = Theme.Colors.TextDim
	statusLine.Text = ""
	statusLine.ZIndex = 72
	statusLine.Parent = panel

	local resultLine = Instance.new("TextLabel")
	resultLine.Size = UDim2.new(1, -20, 0, 28)
	resultLine.Position = UDim2.new(0, 10, 0, 402)
	resultLine.BackgroundTransparency = 1
	resultLine.Font = Theme.FontBold
	resultLine.TextSize = 18
	resultLine.TextColor3 = Theme.Colors.Gold
	resultLine.Text = ""
	resultLine.ZIndex = 72
	resultLine.Parent = panel

	local spinBtn = Instance.new("TextButton")
	spinBtn.Size = UDim2.new(1, -40, 0, 50)
	spinBtn.Position = UDim2.new(0, 20, 1, -68)
	spinBtn.BackgroundColor3 = Theme.Colors.Accent
	spinBtn.AutoButtonColor = false
	spinBtn.Font = Theme.FontBold
	spinBtn.TextSize = 18
	spinBtn.TextColor3 = Color3.new(0, 0, 0)
	spinBtn.Text = "SPIN"
	spinBtn.ZIndex = 72
	spinBtn.Parent = panel
	Theme.applyCorner(spinBtn, Theme.SmallRadius)

	return {
		Backdrop = backdrop,
		Panel = panel,
		Wheel = wheel,
		SegmentLabels = segLabels,
		SegmentCount = segmentCount,
		Status = statusLine,
		Result = resultLine,
		SpinBtn = spinBtn,
		Close = closeBtn,
	}
end

function DailyRewardsUI.new(gui: ScreenGui)
	local self = setmetatable({}, DailyRewardsUI)
	self.gui = gui
	self.login = buildLoginPopup(gui)
	self.spin = buildSpinPanel(gui)
	self.spinning = false
	self.lastSpinState = nil
	self.currentRotation = 0

	self.login.Close.MouseButton1Click:Connect(function()
		self.login.Backdrop.Visible = false
	end)
	self.login.Claim.MouseButton1Click:Connect(function()
		Remotes.RequestClaimLogin:FireServer()
	end)
	self.spin.Close.MouseButton1Click:Connect(function()
		self.spin.Backdrop.Visible = false
	end)
	self.spin.SpinBtn.MouseButton1Click:Connect(function()
		if self.spinning then
			return
		end
		Remotes.RequestSpin:FireServer()
	end)

	Remotes.DailyRewardsState.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		self:_applyState(payload)
	end)
	Remotes.SpinResult.OnClientEvent:Connect(function(result)
		if type(result) ~= "table" then
			return
		end
		self:_applySpinResult(result)
	end)

	-- Tick the spin cooldown countdown text.
	task.spawn(function()
		while true do
			task.wait(1)
			self:_tickSpin()
		end
	end)

	return self
end

function DailyRewardsUI:_applyState(payload)
	local login = payload.Login
	local spin = payload.Spin
	if login then
		self:_renderLogin(login, payload.Claimed == true)
	end
	if spin then
		self.lastSpinState = spin
		-- Render segment labels from server-provided segment values.
		if typeof(spin.Segments) == "table" then
			for i, lbl in self.spin.SegmentLabels do
				local val = spin.Segments[i]
				lbl.Text = if val then "★" .. tostring(val) else "★?"
			end
		end
		self:_tickSpin()
	end
end

function DailyRewardsUI:_renderLogin(login, justClaimed: boolean)
	for i, cell in self.login.Cells do
		local active = i == login.Streak
		cell.Frame.BackgroundColor3 = active and Theme.Colors.PanelAlt or Theme.Colors.Panel
		cell.Check.Text = if i < login.Streak then "✓" elseif active then "TODAY" else ""
		cell.Check.TextColor3 = if i < login.Streak then Theme.Colors.AccentAlt else Theme.Colors.Gold
		cell.Check.TextSize = if active and i >= login.Streak then 11 else 14
	end
	self.login.Reward.Text = string.format("+ ★%d  (Streak Day %d)", login.Reward, login.Streak)

	if login.AlreadyClaimedToday and not justClaimed then
		-- Already collected today; just show the wheel info but don't pop the
		-- modal automatically.
		self.login.Status.Text = "Sudah diklaim hari ini. Kembali besok!"
		self.login.Claim.Visible = false
		self.login.Backdrop.Visible = false
	else
		self.login.Claim.Visible = not justClaimed
		self.login.Status.Text = if justClaimed
			then string.format("Diterima ★%d. Sampai jumpa besok!", login.Reward)
			else "Klaim sebelum keluar."
		self.login.Backdrop.Visible = true
		if justClaimed then
			task.delay(2.0, function()
				self.login.Backdrop.Visible = false
			end)
		end
	end
end

function DailyRewardsUI:_tickSpin()
	local spin = self.lastSpinState
	if not spin then
		return
	end
	local now = os.time()
	local available = spin.Available or now >= (spin.NextAvailableAt or 0)
	if available then
		self.spin.SpinBtn.Text = "SPIN"
		self.spin.SpinBtn.BackgroundColor3 = Theme.Colors.Accent
		self.spin.SpinBtn.AutoButtonColor = true
		self.spin.Status.Text = "Siap spin!"
	else
		local remaining = (spin.NextAvailableAt or 0) - now
		self.spin.SpinBtn.Text = "TUNGGU " .. formatHMS(remaining)
		self.spin.SpinBtn.BackgroundColor3 = Theme.Colors.Panel
		self.spin.SpinBtn.AutoButtonColor = false
		self.spin.Status.Text = "Cooldown sampai bisa spin lagi."
	end
end

function DailyRewardsUI:_applySpinResult(result)
	if not result.Success then
		self.spin.Status.Text = result.Message or "Gagal spin"
		return
	end
	self.spinning = true
	self.spin.Result.Text = ""
	local segCount = self.spin.SegmentCount
	local segIndex = math.clamp(result.SegmentIndex or 1, 1, segCount)
	local degPerSeg = 360 / segCount
	local target = (-((segIndex - 1) * degPerSeg) - degPerSeg / 2) -- align segment center under top pointer
	local fullSpins = 5
	local newRotation = self.currentRotation - 360 * fullSpins + target - (self.currentRotation % 360)
	self.currentRotation = newRotation

	local tween = TweenService:Create(
		self.spin.Wheel,
		TweenInfo.new(3.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
		{ Rotation = newRotation }
	)
	tween:Play()
	tween.Completed:Connect(function()
		self.spinning = false
		self.spin.Result.Text = string.format("Selamat! +★%d", result.Reward)
		if self.lastSpinState then
			self.lastSpinState.Available = false
			self.lastSpinState.NextAvailableAt = result.NextAvailableAt
		end
		self:_tickSpin()
	end)
end

function DailyRewardsUI:openSpin()
	self.spin.Backdrop.Visible = true
	self:_tickSpin()
end

function DailyRewardsUI:openLogin()
	self.login.Backdrop.Visible = true
end

return DailyRewardsUI
