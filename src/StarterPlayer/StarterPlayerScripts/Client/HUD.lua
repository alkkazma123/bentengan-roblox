--!strict
-- In-match HUD: timer, team indicator, coins, ability slots with cooldowns,
-- jail status banner, and toast notifications.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Utils = require(Shared:WaitForChild("Utils"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local HUD = {}
HUD.__index = HUD

-- Hotkey mapping for abilities (Q / E / R)
local HOTKEYS = { Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.R }

function HUD.new(gui: ScreenGui)
	local self = setmetatable({}, HUD)
	self.equipped = {} :: { string }
	self.matchEndsAt = 0
	self.isInMatch = false
	self.team = nil :: string?
	self.flyEndsAt = 0
	self.flyCooldownUntil = 0
	self.flyRemaining = GameConfig.Abilities.Fly.Params.Duration

	local root = Instance.new("Frame")
	root.Name = "HUDRoot"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Visible = false
	root.Parent = gui
	self.root = root

	-- Timer (top center)
	local timer = Instance.new("TextLabel")
	timer.Size = UDim2.fromOffset(160, 42)
	timer.AnchorPoint = Vector2.new(0.5, 0)
	timer.Position = UDim2.new(0.5, 0, 0, 12)
	timer.BackgroundColor3 = Theme.Colors.Bg
	timer.Font = Theme.FontBold
	timer.TextSize = 22
	timer.TextColor3 = Theme.Colors.Text
	timer.Text = "00:00"
	timer.Parent = root
	Theme.applyCorner(timer, Theme.SmallRadius)
	Theme.applyStroke(timer, Theme.Colors.Stroke)
	self.timer = timer

	-- Team badge (top left)
	local teamBadge = Instance.new("TextLabel")
	teamBadge.Size = UDim2.fromOffset(140, 42)
	teamBadge.Position = UDim2.fromOffset(20, 12)
	teamBadge.BackgroundColor3 = Theme.Colors.Panel
	teamBadge.Font = Theme.FontBold
	teamBadge.TextSize = 16
	teamBadge.TextColor3 = Theme.Colors.Text
	teamBadge.Text = "TEAM: -"
	teamBadge.Parent = root
	Theme.applyCorner(teamBadge, Theme.SmallRadius)
	Theme.applyStroke(teamBadge, Theme.Colors.Stroke)
	self.teamBadge = teamBadge

	-- Coins (top right)
	local coins = Instance.new("TextLabel")
	coins.Size = UDim2.fromOffset(140, 42)
	coins.AnchorPoint = Vector2.new(1, 0)
	coins.Position = UDim2.new(1, -20, 0, 12)
	coins.BackgroundColor3 = Theme.Colors.Panel
	coins.Font = Theme.FontBold
	coins.TextSize = 16
	coins.TextColor3 = Theme.Colors.Gold
	coins.Text = "★ 0"
	coins.Parent = root
	Theme.applyCorner(coins, Theme.SmallRadius)
	Theme.applyStroke(coins, Theme.Colors.Stroke)
	self.coinsLabel = coins

	-- Ability slots (bottom center)
	local slotsBar = Instance.new("Frame")
	slotsBar.Size = UDim2.fromOffset(260, 72)
	slotsBar.AnchorPoint = Vector2.new(0.5, 1)
	slotsBar.Position = UDim2.new(0.5, 0, 1, -20)
	slotsBar.BackgroundTransparency = 1
	slotsBar.Parent = root

	local slotsLayout = Instance.new("UIListLayout")
	slotsLayout.FillDirection = Enum.FillDirection.Horizontal
	slotsLayout.Padding = UDim.new(0, 8)
	slotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	slotsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	slotsLayout.Parent = slotsBar

	self.slots = {}
	for i = 1, GameConfig.MaxEquippedAbilities do
		local slot = Instance.new("Frame")
		slot.Size = UDim2.fromOffset(68, 68)
		slot.BackgroundColor3 = Theme.Colors.Panel
		slot.BorderSizePixel = 0
		slot.Parent = slotsBar
		Theme.applyCorner(slot, Theme.SmallRadius)
		Theme.applyStroke(slot, Theme.Colors.Stroke)

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Theme.FontBold
		lbl.TextSize = 12
		lbl.TextWrapped = true
		lbl.TextColor3 = Theme.Colors.TextDim
		lbl.Text = "Empty"
		lbl.Parent = slot

		local hotkey = Instance.new("TextLabel")
		hotkey.Size = UDim2.fromOffset(18, 18)
		hotkey.Position = UDim2.fromOffset(4, 4)
		hotkey.BackgroundColor3 = Theme.Colors.Bg
		hotkey.BorderSizePixel = 0
		hotkey.Font = Theme.FontBold
		hotkey.TextSize = 11
		hotkey.TextColor3 = Theme.Colors.Text
		hotkey.Text = HOTKEYS[i].Name
		hotkey.Parent = slot
		Theme.applyCorner(hotkey, UDim.new(0, 4))

		local overlay = Instance.new("Frame")
		overlay.Size = UDim2.fromScale(1, 1)
		overlay.BackgroundColor3 = Color3.new(0, 0, 0)
		overlay.BackgroundTransparency = 1
		overlay.BorderSizePixel = 0
		overlay.Visible = false
		overlay.Parent = slot
		Theme.applyCorner(overlay, Theme.SmallRadius)

		local overlayText = Instance.new("TextLabel")
		overlayText.Size = UDim2.fromScale(1, 1)
		overlayText.BackgroundTransparency = 1
		overlayText.Font = Theme.FontBold
		overlayText.TextSize = 18
		overlayText.TextColor3 = Theme.Colors.Text
		overlayText.Text = ""
		overlayText.Parent = overlay

		self.slots[i] = {
			Frame = slot,
			Label = lbl,
			Overlay = overlay,
			OverlayText = overlayText,
			AbilityId = nil :: string?,
		}
	end

	-- Jail banner
	local jail = Instance.new("TextLabel")
	jail.Size = UDim2.new(1, 0, 0, 48)
	jail.Position = UDim2.fromScale(0, 0.25)
	jail.BackgroundColor3 = Theme.Colors.Danger
	jail.BackgroundTransparency = 0.25
	jail.BorderSizePixel = 0
	jail.Font = Theme.FontBold
	jail.TextSize = 22
	jail.TextColor3 = Color3.new(1, 1, 1)
	jail.Text = "KAMU DITANGKAP - Tunggu teman membebaskanmu!"
	jail.Visible = false
	jail.Parent = root
	self.jailBanner = jail

	-- Toast
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.fromOffset(360, 36)
	toast.AnchorPoint = Vector2.new(0.5, 1)
	toast.Position = UDim2.new(0.5, 0, 1, -100)
	toast.BackgroundColor3 = Theme.Colors.Bg
	toast.Font = Theme.FontMed
	toast.TextSize = 14
	toast.TextColor3 = Theme.Colors.Text
	toast.Text = ""
	toast.Visible = false
	toast.Parent = root
	Theme.applyCorner(toast, Theme.SmallRadius)
	Theme.applyStroke(toast, Theme.Colors.Stroke)
	self.toast = toast

	-- Match end panel
	local endPanel = Instance.new("Frame")
	endPanel.Size = UDim2.fromOffset(420, 180)
	endPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	endPanel.Position = UDim2.fromScale(0.5, 0.5)
	endPanel.BackgroundColor3 = Theme.Colors.Bg
	endPanel.Visible = false
	endPanel.Parent = root
	Theme.applyCorner(endPanel)
	Theme.applyStroke(endPanel, Theme.Colors.Stroke)
	local endTitle = Instance.new("TextLabel")
	endTitle.Size = UDim2.new(1, 0, 0, 60)
	endTitle.Position = UDim2.fromOffset(0, 20)
	endTitle.BackgroundTransparency = 1
	endTitle.Font = Theme.FontBold
	endTitle.TextSize = 32
	endTitle.TextColor3 = Theme.Colors.Text
	endTitle.Text = ""
	endTitle.Parent = endPanel
	local endSub = Instance.new("TextLabel")
	endSub.Size = UDim2.new(1, 0, 0, 40)
	endSub.Position = UDim2.fromOffset(0, 90)
	endSub.BackgroundTransparency = 1
	endSub.Font = Theme.Font
	endSub.TextSize = 16
	endSub.TextColor3 = Theme.Colors.TextDim
	endSub.Text = ""
	endSub.Parent = endPanel
	self.endPanel = endPanel
	self.endTitle = endTitle
	self.endSub = endSub

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not self.isInMatch then
			return
		end
		for i, key in HOTKEYS do
			if input.KeyCode == key then
				local slot = self.slots[i]
				if slot and slot.AbilityId then
					self:_onSlotActivate(slot.AbilityId)
				end
				break
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.1)
			self:_tick()
		end
	end)

	return self
end

function HUD:_onSlotActivate(abilityId: string)
	-- Only Fly is a toggleable runtime ability; others are passive.
	if abilityId == "Fly" then
		Remotes.AbilityActivate:FireServer("Fly")
	end
end

function HUD:_tick()
	if not self.isInMatch then
		return
	end
	local remaining = math.max(0, self.matchEndsAt - os.clock())
	self.timer.Text = Utils.formatTime(remaining)

	local now = os.clock()
	for _, slot in self.slots do
		if slot.AbilityId == "Fly" then
			if self.flyEndsAt > now then
				slot.Overlay.Visible = true
				slot.Overlay.BackgroundTransparency = 0.3
				slot.Overlay.BackgroundColor3 = Theme.Colors.Accent
				slot.OverlayText.Text = string.format("%.1fs", self.flyEndsAt - now)
			elseif self.flyCooldownUntil > now then
				slot.Overlay.Visible = true
				slot.Overlay.BackgroundTransparency = 0.5
				slot.Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
				slot.OverlayText.Text = string.format("%ds", math.ceil(self.flyCooldownUntil - now))
			else
				slot.Overlay.Visible = false
			end
		end
	end
end

function HUD:setVisible(v: boolean)
	self.root.Visible = v
end

function HUD:onMatchStart(info: { Team: string, EndsAt: number, LobbyIndex: number })
	self.isInMatch = true
	self.matchEndsAt = info.EndsAt
	self.team = info.Team
	self.teamBadge.Text = "TEAM: " .. string.upper(info.Team) .. " - LOBBY " .. info.LobbyIndex
	self.teamBadge.TextColor3 = if info.Team == "Red" then Theme.Colors.Red else Theme.Colors.Blue
	self.endPanel.Visible = false
	self.jailBanner.Visible = false
	self.root.Visible = true
end

function HUD:onMatchEnd(info: { Winner: string, Reason: string })
	self.isInMatch = false
	self.endPanel.Visible = true
	if info.Winner == self.team then
		self.endTitle.Text = "KAMU MENANG!"
		self.endTitle.TextColor3 = Theme.Colors.AccentAlt
	elseif info.Winner == "Draw" then
		self.endTitle.Text = "DRAW"
		self.endTitle.TextColor3 = Theme.Colors.TextDim
	else
		self.endTitle.Text = "KALAH"
		self.endTitle.TextColor3 = Theme.Colors.Danger
	end
	local reasonLabels = {
		BaseTouch = "Benteng lawan tersentuh!",
		AllCaptured = "Semua lawan tertangkap",
		Timeout = "Waktu habis",
	}
	self.endSub.Text = reasonLabels[info.Reason] or info.Reason
	self.jailBanner.Visible = false
	task.delay(4, function()
		self.endPanel.Visible = false
	end)
end

function HUD:updateEquipped(equipped: { string })
	self.equipped = equipped
	for i, slot in self.slots do
		local id = equipped[i]
		slot.AbilityId = id
		if id then
			local def = GameConfig.Abilities[id]
			slot.Label.Text = def and def.Name or id
			slot.Label.TextColor3 = Theme.Colors.Text
			slot.Frame.BackgroundColor3 = Theme.Colors.PanelAlt
		else
			slot.Label.Text = "Empty"
			slot.Label.TextColor3 = Theme.Colors.TextDim
			slot.Frame.BackgroundColor3 = Theme.Colors.Panel
			slot.Overlay.Visible = false
		end
	end
end

function HUD:updateCoins(amount: number)
	self.coinsLabel.Text = "★ " .. tostring(amount)
end

function HUD:setJailed(jailed: boolean)
	self.jailBanner.Visible = jailed
end

function HUD:onFlyStart(endsAt: number)
	self.flyEndsAt = endsAt
end

function HUD:onFlyEnd(cooldown: number)
	self.flyEndsAt = 0
	self.flyCooldownUntil = os.clock() + cooldown
end

function HUD:showToast(msg: string, color: Color3?)
	self.toast.Text = msg
	self.toast.TextColor3 = color or Theme.Colors.Text
	self.toast.Visible = true
	task.delay(3, function()
		if self.toast.Text == msg then
			self.toast.Visible = false
		end
	end)
end

return HUD
