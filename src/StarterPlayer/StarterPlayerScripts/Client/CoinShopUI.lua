--!strict
-- Robux coin pack shop. Three tiles, one per developer product. The server
-- sends the catalog (so we don't hardcode IDs on the client) and handles the
-- actual MarketplaceService prompt.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local CoinShopUI = {}
CoinShopUI.__index = CoinShopUI

local TILE_BG = { Theme.Colors.Panel, Theme.Colors.PanelAlt, Theme.Colors.Panel }

local function buildPanel(parent: ScreenGui)
	local backdrop = Instance.new("Frame")
	backdrop.Name = "CoinShopBackdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.4
	backdrop.BorderSizePixel = 0
	backdrop.Visible = false
	backdrop.ZIndex = 80
	backdrop.Parent = parent

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(520, 360)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3 = Theme.Colors.Bg
	panel.BorderSizePixel = 0
	panel.ZIndex = 81
	panel.Parent = backdrop
	Theme.applyCorner(panel)
	Theme.applyStroke(panel, Theme.Colors.Stroke)

	local sizeC = Instance.new("UISizeConstraint")
	sizeC.MinSize = Vector2.new(320, 360)
	sizeC.MaxSize = Vector2.new(620, 420)
	sizeC.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 36)
	title.Position = UDim2.fromOffset(10, 10)
	title.BackgroundTransparency = 1
	title.Font = Theme.FontBold
	title.TextSize = 22
	title.TextColor3 = Theme.Colors.Gold
	title.Text = "BELI KOIN"
	title.ZIndex = 82
	title.Parent = panel

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -20, 0, 18)
	sub.Position = UDim2.fromOffset(10, 44)
	sub.BackgroundTransparency = 1
	sub.Font = Theme.Font
	sub.TextSize = 13
	sub.TextColor3 = Theme.Colors.TextDim
	sub.Text = "Tukar Robux dengan koin in-game"
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

	local tilesHolder = Instance.new("Frame")
	tilesHolder.Size = UDim2.new(1, -20, 1, -100)
	tilesHolder.Position = UDim2.fromOffset(10, 76)
	tilesHolder.BackgroundTransparency = 1
	tilesHolder.ZIndex = 82
	tilesHolder.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 12)
	layout.Parent = tilesHolder

	return {
		Backdrop = backdrop,
		Panel = panel,
		Tiles = tilesHolder,
		Close = closeBtn,
	}
end

local function buildTile(parent: GuiObject, idx: number, entry, onClick: () -> ())
	local tile = Instance.new("TextButton")
	tile.Size = UDim2.new(0.31, 0, 1, 0)
	tile.BackgroundColor3 = TILE_BG[((idx - 1) % #TILE_BG) + 1]
	tile.AutoButtonColor = false
	tile.Text = ""
	tile.LayoutOrder = idx
	tile.ZIndex = 83
	tile.Parent = parent
	Theme.applyCorner(tile, Theme.SmallRadius)
	Theme.applyStroke(tile, Theme.Colors.Stroke)

	local sizeC = Instance.new("UISizeConstraint")
	sizeC.MinSize = Vector2.new(96, 0)
	sizeC.MaxSize = Vector2.new(180, math.huge)
	sizeC.Parent = tile

	local coinLabel = Instance.new("TextLabel")
	coinLabel.Size = UDim2.new(1, -10, 0, 64)
	coinLabel.Position = UDim2.fromOffset(5, 24)
	coinLabel.BackgroundTransparency = 1
	coinLabel.Font = Theme.FontBold
	coinLabel.TextSize = 28
	coinLabel.TextColor3 = Theme.Colors.Gold
	coinLabel.TextScaled = true
	coinLabel.Text = "★ " .. tostring(entry.Coins)
	coinLabel.ZIndex = 84
	coinLabel.Parent = tile

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 18)
	nameLabel.Position = UDim2.fromOffset(5, 96)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Theme.Font
	nameLabel.TextSize = 12
	nameLabel.TextColor3 = Theme.Colors.TextDim
	nameLabel.Text = "koin"
	nameLabel.ZIndex = 84
	nameLabel.Parent = tile

	local priceBtn = Instance.new("TextLabel")
	priceBtn.Size = UDim2.new(1, -16, 0, 38)
	priceBtn.Position = UDim2.new(0, 8, 1, -50)
	priceBtn.BackgroundColor3 = Theme.Colors.AccentAlt
	priceBtn.BorderSizePixel = 0
	priceBtn.Font = Theme.FontBold
	priceBtn.TextSize = 16
	priceBtn.TextColor3 = Color3.new(0, 0, 0)
	priceBtn.Text = entry.RobuxLabel
	priceBtn.ZIndex = 84
	priceBtn.Parent = tile
	Theme.applyCorner(priceBtn, Theme.SmallRadius)

	tile.MouseButton1Click:Connect(onClick)
	tile.MouseEnter:Connect(function()
		tile.BackgroundColor3 = Theme.Colors.PanelAlt
	end)
	tile.MouseLeave:Connect(function()
		tile.BackgroundColor3 = TILE_BG[((idx - 1) % #TILE_BG) + 1]
	end)
end

function CoinShopUI.new(gui: ScreenGui)
	local self = setmetatable({}, CoinShopUI)
	self.parts = buildPanel(gui)
	self.catalog = nil
	self.parts.Close.MouseButton1Click:Connect(function()
		self.parts.Backdrop.Visible = false
	end)

	Remotes.CoinShopCatalog.OnClientEvent:Connect(function(catalog)
		if type(catalog) ~= "table" then
			return
		end
		self:_renderCatalog(catalog)
	end)

	return self
end

function CoinShopUI:_renderCatalog(catalog)
	self.catalog = catalog
	for _, child in self.parts.Tiles:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for i, entry in catalog do
		buildTile(self.parts.Tiles, i, entry, function()
			Remotes.RequestCoinPurchase:FireServer(entry.Id)
		end)
	end
end

function CoinShopUI:open()
	self.parts.Backdrop.Visible = true
end

function CoinShopUI:close()
	self.parts.Backdrop.Visible = false
end

return CoinShopUI
