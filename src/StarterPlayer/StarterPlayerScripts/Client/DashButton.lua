--!strict
-- Always-visible Dash button + keybind. Fires Remotes.RequestDash; the server
-- validates cooldown and actually applies the forward impulse.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Theme = require(Shared:WaitForChild("Theme"))

local DashButton = {}
DashButton.__index = DashButton

function DashButton.new(gui: ScreenGui)
	local self = setmetatable({}, DashButton)
	self.cooldownEndsAt = 0

	local btn = Instance.new("TextButton")
	btn.Name = "DashButton"
	btn.Size = UDim2.fromOffset(86, 86)
	btn.AnchorPoint = Vector2.new(1, 1)
	btn.Position = UDim2.new(1, -20, 1, -120)
	btn.BackgroundColor3 = Theme.Colors.Accent
	btn.AutoButtonColor = false
	btn.Font = Theme.FontBold
	btn.TextSize = 18
	btn.TextColor3 = Color3.new(0, 0, 0)
	btn.Text = "DASH"
	btn.ZIndex = 20
	btn.Parent = gui
	Theme.applyCorner(btn, UDim.new(0, 14))
	Theme.applyStroke(btn, Theme.Colors.Stroke)
	self.btn = btn

	local hotkey = Instance.new("TextLabel")
	hotkey.Size = UDim2.fromOffset(56, 16)
	hotkey.AnchorPoint = Vector2.new(0.5, 0)
	hotkey.Position = UDim2.new(0.5, 0, 0, 6)
	hotkey.BackgroundTransparency = 1
	hotkey.Font = Theme.FontMed
	hotkey.TextSize = 11
	hotkey.TextColor3 = Color3.fromRGB(20, 40, 60)
	hotkey.Text = "[L Shift]"
	hotkey.Parent = btn
	self.hotkey = hotkey

	local overlay = Instance.new("TextLabel")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.45
	overlay.BorderSizePixel = 0
	overlay.Font = Theme.FontBold
	overlay.TextSize = 22
	overlay.TextColor3 = Color3.new(1, 1, 1)
	overlay.Text = ""
	overlay.Visible = false
	overlay.Parent = btn
	Theme.applyCorner(overlay, UDim.new(0, 14))
	self.overlay = overlay

	local function tryDash()
		if os.clock() < self.cooldownEndsAt then
			return
		end
		Remotes.RequestDash:FireServer()
	end

	btn.MouseButton1Click:Connect(tryDash)
	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Theme.Colors.AccentAlt
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = Theme.Colors.Accent
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			tryDash()
		end
	end)

	Remotes.DashFeedback.OnClientEvent:Connect(function(info)
		if type(info) ~= "table" then
			return
		end
		if info.Type == "DashStart" and typeof(info.CooldownEndsAt) == "number" then
			self.cooldownEndsAt = info.CooldownEndsAt
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

function DashButton:_tick()
	local remaining = self.cooldownEndsAt - os.clock()
	if remaining > 0 then
		self.overlay.Visible = true
		self.overlay.Text = string.format("%.1fs", remaining)
		self.btn.BackgroundColor3 = Theme.Colors.Panel
		self.hotkey.TextColor3 = Color3.fromRGB(200, 200, 220)
	else
		self.overlay.Visible = false
		self.btn.BackgroundColor3 = Theme.Colors.Accent
		self.hotkey.TextColor3 = Color3.fromRGB(20, 40, 60)
	end
end

function DashButton:setVisible(v: boolean)
	self.btn.Visible = v
end

-- Expose cooldown for any other UI that may care.
function DashButton:getCooldownEndsAt(): number
	return self.cooldownEndsAt
end

return DashButton
