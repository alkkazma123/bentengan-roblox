--!strict
-- "TITLE" panel: lets the player set the small gold tag that shows above
-- their head. They get one change per 24h. The UI offers a row of preset
-- chips for quick tap, plus a custom text input for anything else.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local TitleUI = {}
TitleUI.__index = TitleUI

local function fmtCountdown(secs: number): string
	if secs <= 0 then
		return "Tersedia"
	end
	local h = math.floor(secs / 3600)
	local m = math.floor((secs % 3600) / 60)
	local s = secs % 60
	if h > 0 then
		return string.format("%dj %dm", h, m)
	elseif m > 0 then
		return string.format("%dm %ds", m, s)
	end
	return string.format("%ds", s)
end

local function buildPanel(parent: ScreenGui)
	local backdrop = Instance.new("Frame")
	backdrop.Name = "TitleBackdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.4
	backdrop.BorderSizePixel = 0
	backdrop.Visible = false
	backdrop.ZIndex = 80
	backdrop.Parent = parent

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(560, 460)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3 = Theme.Colors.Bg
	panel.BorderSizePixel = 0
	panel.ZIndex = 81
	panel.Parent = backdrop
	Theme.applyCorner(panel)
	Theme.applyStroke(panel, Theme.Colors.Stroke)

	local sizeC = Instance.new("UISizeConstraint")
	sizeC.MinSize = Vector2.new(320, 460)
	sizeC.MaxSize = Vector2.new(620, 540)
	sizeC.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 36)
	title.Position = UDim2.fromOffset(10, 10)
	title.BackgroundTransparency = 1
	title.Font = Theme.FontBold
	title.TextSize = 22
	title.TextColor3 = Theme.Colors.Gold
	title.Text = "TITLE OVERHEAD"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 82
	title.Parent = panel

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -20, 0, 18)
	sub.Position = UDim2.fromOffset(10, 44)
	sub.BackgroundTransparency = 1
	sub.Font = Theme.Font
	sub.TextSize = 13
	sub.TextColor3 = Theme.Colors.TextDim
	sub.Text = "Pilih preset atau ketik sendiri (1 ganti / 24 jam, 14 char)."
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.ZIndex = 82
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
	closeBtn.ZIndex = 82
	closeBtn.Parent = panel
	Theme.applyCorner(closeBtn, UDim.new(0, 8))

	-- Current title preview.
	local current = Instance.new("Frame")
	current.Size = UDim2.new(1, -20, 0, 56)
	current.Position = UDim2.fromOffset(10, 76)
	current.BackgroundColor3 = Theme.Colors.Panel
	current.BorderSizePixel = 0
	current.ZIndex = 82
	current.Parent = panel
	Theme.applyCorner(current, Theme.SmallRadius)
	Theme.applyStroke(current, Theme.Colors.Stroke)

	local currentLbl = Instance.new("TextLabel")
	currentLbl.Size = UDim2.new(1, -20, 1, -8)
	currentLbl.Position = UDim2.fromOffset(10, 4)
	currentLbl.BackgroundTransparency = 1
	currentLbl.Font = Theme.FontBold
	currentLbl.TextSize = 14
	currentLbl.TextColor3 = Theme.Colors.TextDim
	currentLbl.TextXAlignment = Enum.TextXAlignment.Left
	currentLbl.TextYAlignment = Enum.TextYAlignment.Center
	currentLbl.Text = "Sekarang: -"
	currentLbl.ZIndex = 83
	currentLbl.Parent = current

	-- Presets grid (horizontal wrap).
	local presetsHeader = Instance.new("TextLabel")
	presetsHeader.Size = UDim2.new(1, -20, 0, 18)
	presetsHeader.Position = UDim2.fromOffset(10, 142)
	presetsHeader.BackgroundTransparency = 1
	presetsHeader.Font = Theme.FontMed
	presetsHeader.TextSize = 13
	presetsHeader.TextColor3 = Theme.Colors.TextDim
	presetsHeader.Text = "PRESET"
	presetsHeader.TextXAlignment = Enum.TextXAlignment.Left
	presetsHeader.ZIndex = 82
	presetsHeader.Parent = panel

	local presetsHolder = Instance.new("ScrollingFrame")
	presetsHolder.Size = UDim2.new(1, -20, 0, 144)
	presetsHolder.Position = UDim2.fromOffset(10, 162)
	presetsHolder.BackgroundColor3 = Theme.Colors.PanelAlt
	presetsHolder.BorderSizePixel = 0
	presetsHolder.ScrollBarThickness = 4
	presetsHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
	presetsHolder.CanvasSize = UDim2.new()
	presetsHolder.ZIndex = 82
	presetsHolder.Parent = panel
	Theme.applyCorner(presetsHolder, Theme.SmallRadius)

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(120, 30)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = presetsHolder

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent = presetsHolder

	-- Custom input.
	local inputHeader = Instance.new("TextLabel")
	inputHeader.Size = UDim2.new(1, -20, 0, 18)
	inputHeader.Position = UDim2.fromOffset(10, 314)
	inputHeader.BackgroundTransparency = 1
	inputHeader.Font = Theme.FontMed
	inputHeader.TextSize = 13
	inputHeader.TextColor3 = Theme.Colors.TextDim
	inputHeader.Text = "ATAU TULIS SENDIRI"
	inputHeader.TextXAlignment = Enum.TextXAlignment.Left
	inputHeader.ZIndex = 82
	inputHeader.Parent = panel

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, -160, 0, 38)
	input.Position = UDim2.fromOffset(10, 334)
	input.BackgroundColor3 = Theme.Colors.PanelAlt
	input.BorderSizePixel = 0
	input.Font = Theme.Font
	input.TextSize = 16
	input.TextColor3 = Theme.Colors.Text
	input.PlaceholderText = "Ketik max 14 karakter"
	input.PlaceholderColor3 = Theme.Colors.TextDim
	input.Text = ""
	input.ClearTextOnFocus = false
	input.TextXAlignment = Enum.TextXAlignment.Left
	input.ZIndex = 82
	input.Parent = panel
	Theme.applyCorner(input, Theme.SmallRadius)
	Theme.applyStroke(input, Theme.Colors.Stroke)
	local inputPad = Instance.new("UIPadding")
	inputPad.PaddingLeft = UDim.new(0, 10)
	inputPad.PaddingRight = UDim.new(0, 10)
	inputPad.Parent = input

	local applyBtn = Instance.new("TextButton")
	applyBtn.Size = UDim2.fromOffset(140, 38)
	applyBtn.AnchorPoint = Vector2.new(1, 0)
	applyBtn.Position = UDim2.new(1, -10, 0, 334)
	applyBtn.BackgroundColor3 = Theme.Colors.Accent
	applyBtn.AutoButtonColor = false
	applyBtn.Font = Theme.FontBold
	applyBtn.TextSize = 14
	applyBtn.TextColor3 = Color3.new(0, 0, 0)
	applyBtn.Text = "APPLY TITLE"
	applyBtn.ZIndex = 82
	applyBtn.Parent = panel
	Theme.applyCorner(applyBtn, Theme.SmallRadius)

	-- Status / cooldown line.
	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, -20, 0, 22)
	status.Position = UDim2.fromOffset(10, 386)
	status.BackgroundTransparency = 1
	status.Font = Theme.FontMed
	status.TextSize = 13
	status.TextColor3 = Theme.Colors.TextDim
	status.Text = ""
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.ZIndex = 82
	status.Parent = panel

	local message = Instance.new("TextLabel")
	message.Size = UDim2.new(1, -20, 0, 22)
	message.Position = UDim2.fromOffset(10, 412)
	message.BackgroundTransparency = 1
	message.Font = Theme.FontMed
	message.TextSize = 13
	message.TextColor3 = Theme.Colors.Danger
	message.Text = ""
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.ZIndex = 82
	message.Parent = panel

	return {
		Backdrop = backdrop,
		Panel = panel,
		Close = closeBtn,
		Current = currentLbl,
		Presets = presetsHolder,
		Input = input,
		Apply = applyBtn,
		Status = status,
		Message = message,
	}
end

local function buildPresetButton(parent: GuiObject, text: string, onClick: () -> ()): TextButton
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = Theme.Colors.Panel
	btn.AutoButtonColor = false
	btn.Font = Theme.FontMed
	btn.TextSize = 13
	btn.TextColor3 = Theme.Colors.Gold
	btn.Text = text
	btn.ZIndex = 84
	btn.Parent = parent
	Theme.applyCorner(btn, Theme.SmallRadius)
	Theme.applyStroke(btn, Theme.Colors.Stroke)

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Theme.Colors.PanelAlt
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = Theme.Colors.Panel
	end)
	btn.MouseButton1Click:Connect(onClick)
	return btn
end

function TitleUI.new(gui: ScreenGui)
	local self = setmetatable({}, TitleUI)
	self.parts = buildPanel(gui)
	self.state = nil

	self.parts.Close.MouseButton1Click:Connect(function()
		self:close()
	end)

	self.parts.Apply.MouseButton1Click:Connect(function()
		local txt = self.parts.Input.Text or ""
		if txt:gsub("%s+", "") == "" then
			self:_setMessage("Ketik teks dulu.")
			return
		end
		Remotes.RequestSetTitle:FireServer(txt)
	end)

	Remotes.TitleState.OnClientEvent:Connect(function(state)
		if type(state) ~= "table" then
			return
		end
		self:_applyState(state)
	end)

	Remotes.TitleResult.OnClientEvent:Connect(function(result)
		if type(result) ~= "table" then
			return
		end
		if result.Success then
			self:_setMessage("Berhasil! Title baru aktif.", false)
			self.parts.Input.Text = ""
		else
			self:_setMessage(result.Message or "Gagal.", true)
		end
	end)

	return self
end

function TitleUI:_renderPresets(presets: { string })
	for _, child in self.parts.Presets:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for i, p in presets do
		local btn = buildPresetButton(self.parts.Presets, p, function()
			Remotes.RequestSetTitle:FireServer(p)
		end)
		btn.LayoutOrder = i
	end
end

function TitleUI:_setMessage(text: string, isError: boolean?)
	self.parts.Message.Text = text
	if isError == false then
		self.parts.Message.TextColor3 = Theme.Colors.Accent
	else
		self.parts.Message.TextColor3 = Theme.Colors.Danger
	end
end

function TitleUI:_updateStatus()
	local state = self.state
	if not state then
		return
	end
	if state.Current and state.Current ~= "" then
		self.parts.Current.Text = "Sekarang: " .. state.Current
		self.parts.Current.TextColor3 = Theme.Colors.Gold
	else
		self.parts.Current.Text = "Sekarang: (belum ada)"
		self.parts.Current.TextColor3 = Theme.Colors.TextDim
	end
	local now = os.time()
	local remaining = math.max(0, (state.NextAvailableAt or 0) - now)
	if remaining <= 0 then
		self.parts.Status.Text = "Cooldown: tersedia (1 ganti / hari)."
		self.parts.Status.TextColor3 = Theme.Colors.Accent
		self.parts.Apply.AutoButtonColor = false
		self.parts.Apply.BackgroundColor3 = Theme.Colors.Accent
		self.parts.Apply.Active = true
	else
		self.parts.Status.Text = "Bisa ganti lagi dalam " .. fmtCountdown(remaining) .. "."
		self.parts.Status.TextColor3 = Theme.Colors.TextDim
		self.parts.Apply.BackgroundColor3 = Theme.Colors.Panel
		self.parts.Apply.Active = false
	end
end

function TitleUI:_applyState(state)
	self.state = state
	if state.Presets then
		self:_renderPresets(state.Presets)
	end
	self:_updateStatus()
end

function TitleUI:open()
	self.parts.Backdrop.Visible = true
	self:_setMessage("", false)
	-- Tick the cooldown countdown every second while panel is visible.
	self._heartbeatToken = (self._heartbeatToken or 0) + 1
	local token = self._heartbeatToken
	task.spawn(function()
		while self._heartbeatToken == token and self.parts.Backdrop.Visible do
			self:_updateStatus()
			task.wait(1)
		end
	end)
end

function TitleUI:close()
	self.parts.Backdrop.Visible = false
	self._heartbeatToken = (self._heartbeatToken or 0) + 1
end

return TitleUI
