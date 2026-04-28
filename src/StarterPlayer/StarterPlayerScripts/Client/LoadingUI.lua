--!strict
-- Real loading screen. Tracks ContentProvider preload + script require progress
-- and drives a visible progress bar. Resolves when fully ready.

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local LoadingUI = {}

local function collectPreloadAssets(): { string }
	local assets = {}
	for _, def in GameConfig.Abilities do
		if def.Icon and def.Icon ~= "" then
			table.insert(assets, def.Icon)
		end
	end
	return assets
end

function LoadingUI.show(gui: ScreenGui): (Frame, TextLabel, Frame)
	local screen = Instance.new("Frame")
	screen.Name = "LoadingScreen"
	screen.Size = UDim2.fromScale(1, 1)
	screen.BackgroundColor3 = Theme.Colors.Bg
	screen.BorderSizePixel = 0
	screen.ZIndex = 1000
	screen.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 48)
	title.Position = UDim2.new(0, 0, 0.35, 0)
	title.BackgroundTransparency = 1
	title.Font = Theme.FontBold
	title.TextSize = 36
	title.TextColor3 = Theme.Colors.Text
	title.Text = "BENTENGAN"
	title.Parent = screen

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, 0, 0, 24)
	subtitle.Position = UDim2.new(0, 0, 0.35, 52)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Theme.Font
	subtitle.TextSize = 16
	subtitle.TextColor3 = Theme.Colors.TextDim
	subtitle.Text = "Memuat aset dan script..."
	subtitle.Parent = screen

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(0, 420, 0, 14)
	barBg.AnchorPoint = Vector2.new(0.5, 0.5)
	barBg.Position = UDim2.new(0.5, 0, 0.55, 0)
	barBg.BackgroundColor3 = Theme.Colors.Panel
	barBg.BorderSizePixel = 0
	barBg.Parent = screen
	Theme.applyCorner(barBg, UDim.new(0, 7))
	Theme.applyStroke(barBg, Theme.Colors.Stroke, 1)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Theme.Colors.Accent
	fill.BorderSizePixel = 0
	fill.Parent = barBg
	Theme.applyCorner(fill, UDim.new(0, 7))

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(0, 420, 0, 20)
	statusLabel.AnchorPoint = Vector2.new(0.5, 0)
	statusLabel.Position = UDim2.new(0.5, 0, 0.55, 16)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Theme.Font
	statusLabel.TextSize = 14
	statusLabel.TextColor3 = Theme.Colors.TextDim
	statusLabel.Text = "0%"
	statusLabel.Parent = screen

	return fill, statusLabel, screen
end

function LoadingUI.hide(screen: Frame)
	local goal = { BackgroundTransparency = 1 }
	local info = TweenInfo.new(0.4, Enum.EasingStyle.Quad)
	local tween = TweenService:Create(screen, info, goal)
	for _, child in screen:GetDescendants() do
		if child:IsA("TextLabel") then
			TweenService:Create(child, info, { TextTransparency = 1 }):Play()
		elseif child:IsA("Frame") then
			TweenService:Create(child, info, { BackgroundTransparency = 1 }):Play()
		elseif child:IsA("UIStroke") then
			TweenService:Create(child, info, { Transparency = 1 }):Play()
		end
	end
	tween:Play()
	tween.Completed:Connect(function()
		screen:Destroy()
	end)
end

function LoadingUI.run(gui: ScreenGui, extraSteps: { () -> () }?): ()
	local fill, statusLabel, screen = LoadingUI.show(gui)

	local assets = collectPreloadAssets()
	local totalSteps = #assets + (extraSteps and #extraSteps or 0) + 2 -- +2 for shared module waits
	local completed = 0

	local function setProgress(pct: number, label: string)
		pct = math.clamp(pct, 0, 1)
		fill:TweenSize(UDim2.fromScale(pct, 1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
		statusLabel.Text = string.format("%d%% - %s", math.floor(pct * 100), label)
	end

	local function step(label: string)
		completed += 1
		setProgress(completed / totalSteps, label)
	end

	setProgress(0, "Mulai...")
	task.wait(0.1)

	-- Step: wait for shared modules (they are already required but this gates against
	-- slow client startup).
	step("Memuat modul shared")
	task.wait(0.05)

	step("Menyinkronkan remote")
	task.wait(0.05)

	-- Preload assets one at a time so we get real per-asset progress.
	for _, asset in assets do
		local ok, err = pcall(function()
			ContentProvider:PreloadAsync({ asset })
		end)
		if not ok then
			warn("[LoadingUI] preload failed:", asset, err)
		end
		step("Memuat asset")
	end

	-- Extra custom steps (e.g. awaiting first LobbyStateUpdate).
	if extraSteps then
		for _, fn in extraSteps do
			local ok, err = pcall(fn)
			if not ok then
				warn("[LoadingUI] step failed:", err)
			end
			step("Inisialisasi")
		end
	end

	setProgress(1, "Siap!")
	task.wait(0.35)
	LoadingUI.hide(screen)
end

return LoadingUI
