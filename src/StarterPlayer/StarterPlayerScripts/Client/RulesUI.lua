--!strict
-- Fullscreen overlay that explains the rules. Resolves when the player hits Close.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local RulesText = require(Shared:WaitForChild("RulesText"))

local RulesUI = {}

function RulesUI.show(gui: ScreenGui, onDismiss: (() -> ())?): Frame
	local existing = gui:FindFirstChild("RulesFrame")
	if existing and existing:IsA("Frame") then
		existing.Visible = true
		if onDismiss then
			local conn
			conn = existing:GetPropertyChangedSignal("Visible"):Connect(function()
				if not existing.Visible then
					if conn then
						conn:Disconnect()
					end
					onDismiss()
				end
			end)
		end
		return existing
	end

	local overlay = Instance.new("Frame")
	overlay.Name = "RulesFrame"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.35
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 500
	overlay.Parent = gui

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0.9, 0, 0.9, 0)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3 = Theme.Colors.Bg
	panel.BorderSizePixel = 0
	panel.ZIndex = 501
	panel.Parent = overlay
	Theme.applyCorner(panel)
	Theme.applyStroke(panel, Theme.Colors.Stroke, 1)

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MaxSize = Vector2.new(640, 520)
	sizeConstraint.MinSize = Vector2.new(260, 320)
	sizeConstraint.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 42)
	title.Position = UDim2.fromOffset(20, 16)
	title.BackgroundTransparency = 1
	title.Font = Theme.FontBold
	title.TextSize = 26
	title.TextColor3 = Theme.Colors.Text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = RulesText.Title
	title.ZIndex = 502
	title.Parent = panel

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(40, 40)
	close.Position = UDim2.new(1, -52, 0, 12)
	close.BackgroundColor3 = Theme.Colors.Panel
	close.AutoButtonColor = false
	close.Font = Theme.FontBold
	close.TextSize = 22
	close.TextColor3 = Theme.Colors.Text
	close.Text = "X"
	close.ZIndex = 502
	close.Parent = panel
	Theme.applyCorner(close, Theme.SmallRadius)
	Theme.applyStroke(close, Theme.Colors.Stroke)

	close.MouseEnter:Connect(function()
		close.BackgroundColor3 = Theme.Colors.Danger
	end)
	close.MouseLeave:Connect(function()
		close.BackgroundColor3 = Theme.Colors.Panel
	end)

	local body = Instance.new("ScrollingFrame")
	body.Size = UDim2.new(1, -40, 1, -120)
	body.Position = UDim2.fromOffset(20, 68)
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.ScrollBarThickness = 4
	body.CanvasSize = UDim2.fromOffset(0, 0)
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.ScrollingDirection = Enum.ScrollingDirection.Y
	body.ZIndex = 502
	body.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = body

	for i, line in RulesText.Lines do
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.new(1, 0, 0, 0)
		tl.AutomaticSize = Enum.AutomaticSize.Y
		tl.BackgroundTransparency = 1
		tl.Font = Theme.Font
		tl.TextSize = 16
		tl.TextXAlignment = Enum.TextXAlignment.Left
		tl.TextYAlignment = Enum.TextYAlignment.Top
		tl.TextWrapped = true
		tl.TextColor3 = if line:match("^%d") then Theme.Colors.Text else Theme.Colors.TextDim
		tl.Text = line
		tl.LayoutOrder = i
		tl.ZIndex = 502
		tl.Parent = body
	end

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(1, -40, 0, 40)
	closeBtn.Position = UDim2.new(0, 20, 1, -52)
	closeBtn.BackgroundColor3 = Theme.Colors.Accent
	closeBtn.AutoButtonColor = false
	closeBtn.Font = Theme.FontBold
	closeBtn.TextSize = 16
	closeBtn.TextColor3 = Color3.new(0, 0, 0)
	closeBtn.Text = "MULAI BERMAIN"
	closeBtn.ZIndex = 502
	closeBtn.Parent = panel
	Theme.applyCorner(closeBtn, Theme.SmallRadius)

	closeBtn.MouseEnter:Connect(function()
		closeBtn.BackgroundColor3 = Theme.Colors.AccentAlt
	end)
	closeBtn.MouseLeave:Connect(function()
		closeBtn.BackgroundColor3 = Theme.Colors.Accent
	end)

	local function dismiss()
		overlay.Visible = false
		if onDismiss then
			onDismiss()
		end
	end

	close.MouseButton1Click:Connect(dismiss)
	closeBtn.MouseButton1Click:Connect(dismiss)

	return overlay
end

return RulesUI
