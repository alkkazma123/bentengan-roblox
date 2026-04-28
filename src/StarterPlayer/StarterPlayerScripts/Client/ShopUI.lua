--!strict
-- Modern dark-minimalist shop. Shows each ability as a card with:
--   - Name + Type badge
--   - Description
--   - Price
--   - Action button(s): BUY / EQUIP / UNEQUIP
-- Enforces client-side preview of equip rules; server re-validates.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared:WaitForChild("Theme"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local ShopUI = {}
ShopUI.__index = ShopUI

local TYPE_COLORS = {
	Speed = Color3.fromRGB(90, 220, 180),
	Jump = Color3.fromRGB(250, 205, 100),
	Vision = Color3.fromRGB(200, 130, 240),
	Fly = Color3.fromRGB(120, 170, 255),
}

function ShopUI.new(gui: ScreenGui)
	local self = setmetatable({}, ShopUI)
	self.owned = {} :: { [string]: boolean }
	self.equipped = {} :: { string }
	self.coins = 0
	self.statusMessage = ""

	local overlay = Instance.new("Frame")
	overlay.Name = "ShopOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.35
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.ZIndex = 400
	overlay.Parent = gui
	self.overlay = overlay

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(760, 560)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3 = Theme.Colors.Bg
	panel.BorderSizePixel = 0
	panel.ZIndex = 401
	panel.Parent = overlay
	Theme.applyCorner(panel)
	Theme.applyStroke(panel, Theme.Colors.Stroke)

	-- Header
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 42)
	title.Position = UDim2.fromOffset(20, 16)
	title.BackgroundTransparency = 1
	title.Font = Theme.FontBold
	title.TextSize = 24
	title.TextColor3 = Theme.Colors.Text
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "SHOP"
	title.ZIndex = 402
	title.Parent = panel

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.fromOffset(400, 20)
	subtitle.Position = UDim2.fromOffset(20, 48)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Theme.Font
	subtitle.TextSize = 13
	subtitle.TextColor3 = Theme.Colors.TextDim
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Text = "Max " .. GameConfig.MaxEquippedAbilities .. " ability di-equip. Tipe tidak boleh sama."
	subtitle.ZIndex = 402
	subtitle.Parent = panel

	local coins = Instance.new("TextLabel")
	coins.Size = UDim2.fromOffset(160, 36)
	coins.AnchorPoint = Vector2.new(1, 0)
	coins.Position = UDim2.new(1, -70, 0, 20)
	coins.BackgroundColor3 = Theme.Colors.Panel
	coins.Font = Theme.FontBold
	coins.TextSize = 16
	coins.TextColor3 = Theme.Colors.Gold
	coins.Text = "★ 0"
	coins.ZIndex = 402
	coins.Parent = panel
	Theme.applyCorner(coins, Theme.SmallRadius)
	Theme.applyStroke(coins, Theme.Colors.Stroke)
	self.coinsLabel = coins

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(40, 40)
	close.Position = UDim2.new(1, -52, 0, 14)
	close.BackgroundColor3 = Theme.Colors.Panel
	close.AutoButtonColor = false
	close.Font = Theme.FontBold
	close.TextSize = 22
	close.TextColor3 = Theme.Colors.Text
	close.Text = "X"
	close.ZIndex = 403
	close.Parent = panel
	Theme.applyCorner(close, Theme.SmallRadius)
	Theme.applyStroke(close, Theme.Colors.Stroke)
	close.MouseEnter:Connect(function()
		close.BackgroundColor3 = Theme.Colors.Danger
	end)
	close.MouseLeave:Connect(function()
		close.BackgroundColor3 = Theme.Colors.Panel
	end)
	close.MouseButton1Click:Connect(function()
		self:setVisible(false)
	end)

	-- Scrolling grid of ability cards
	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -40, 1, -150)
	list.Position = UDim2.fromOffset(20, 80)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 4
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list.ZIndex = 402
	list.Parent = panel
	self.list = list

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.5, -8, 0, 160)
	grid.CellPadding = UDim2.fromOffset(12, 12)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = list

	self.cards = {}
	local order = 1
	for id, def in GameConfig.Abilities do
		self.cards[id] = self:_buildCard(def, list, order)
		order += 1
	end

	-- Footer: status message
	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, -40, 0, 24)
	status.AnchorPoint = Vector2.new(0, 1)
	status.Position = UDim2.new(0, 20, 1, -30)
	status.BackgroundTransparency = 1
	status.Font = Theme.Font
	status.TextSize = 14
	status.TextColor3 = Theme.Colors.Warning
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Text = ""
	status.ZIndex = 402
	status.Parent = panel
	self.status = status

	self:refresh()
	return self
end

function ShopUI:_buildCard(def: any, parent: Instance, order: number)
	local card = Instance.new("Frame")
	card.LayoutOrder = order
	card.BackgroundColor3 = Theme.Colors.Panel
	card.BorderSizePixel = 0
	card.ZIndex = 402
	card.Parent = parent
	Theme.applyCorner(card)
	Theme.applyStroke(card, Theme.Colors.Stroke)

	local typeBadge = Instance.new("TextLabel")
	typeBadge.Size = UDim2.fromOffset(60, 20)
	typeBadge.Position = UDim2.fromOffset(16, 16)
	typeBadge.BackgroundColor3 = TYPE_COLORS[def.Type] or Theme.Colors.TextDim
	typeBadge.Font = Theme.FontBold
	typeBadge.TextSize = 11
	typeBadge.TextColor3 = Color3.new(0, 0, 0)
	typeBadge.Text = string.upper(def.Type)
	typeBadge.ZIndex = 403
	typeBadge.Parent = card
	Theme.applyCorner(typeBadge, UDim.new(0, 4))

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -32, 0, 24)
	name.Position = UDim2.fromOffset(16, 40)
	name.BackgroundTransparency = 1
	name.Font = Theme.FontBold
	name.TextSize = 18
	name.TextColor3 = Theme.Colors.Text
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = def.Name
	name.ZIndex = 403
	name.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -32, 0, 46)
	desc.Position = UDim2.fromOffset(16, 66)
	desc.BackgroundTransparency = 1
	desc.Font = Theme.Font
	desc.TextSize = 13
	desc.TextColor3 = Theme.Colors.TextDim
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.TextWrapped = true
	desc.Text = def.Description
	desc.ZIndex = 403
	desc.Parent = card

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.fromOffset(120, 24)
	priceLabel.AnchorPoint = Vector2.new(0, 1)
	priceLabel.Position = UDim2.new(0, 16, 1, -18)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Theme.FontBold
	priceLabel.TextSize = 15
	priceLabel.TextColor3 = Theme.Colors.Gold
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Text = "★ " .. def.Price
	priceLabel.ZIndex = 403
	priceLabel.Parent = card

	local actionBtn = Instance.new("TextButton")
	actionBtn.Size = UDim2.fromOffset(130, 34)
	actionBtn.AnchorPoint = Vector2.new(1, 1)
	actionBtn.Position = UDim2.new(1, -16, 1, -14)
	actionBtn.BackgroundColor3 = Theme.Colors.Accent
	actionBtn.AutoButtonColor = false
	actionBtn.Font = Theme.FontBold
	actionBtn.TextSize = 13
	actionBtn.TextColor3 = Color3.new(0, 0, 0)
	actionBtn.Text = "BUY"
	actionBtn.ZIndex = 403
	actionBtn.Parent = card
	Theme.applyCorner(actionBtn, Theme.SmallRadius)

	local entry = {
		Frame = card,
		Def = def,
		Action = actionBtn,
		Price = priceLabel,
		Connection = nil :: RBXScriptConnection?,
	}
	return entry
end

function ShopUI:_countTypesEquipped(excludeId: string?): { [string]: boolean }
	local types = {}
	for _, id in self.equipped do
		if id == excludeId then
			continue
		end
		local def = GameConfig.Abilities[id]
		if def then
			types[def.Type] = true
		end
	end
	return types
end

function ShopUI:refresh()
	self.coinsLabel.Text = "★ " .. tostring(self.coins)
	local typesEquipped = self:_countTypesEquipped(nil)
	local equippedCount = #self.equipped

	for id, card in self.cards do
		local def = card.Def
		local owned = self.owned[id] == true
		local equippedNow = table.find(self.equipped, id) ~= nil
		local btn = card.Action
		if not owned then
			btn.Text = "BUY"
			btn.BackgroundColor3 = self.coins >= def.Price and Theme.Colors.Accent or Theme.Colors.Panel
			btn.TextColor3 = self.coins >= def.Price and Color3.new(0, 0, 0) or Theme.Colors.TextDim
			btn.Active = self.coins >= def.Price
		elseif equippedNow then
			btn.Text = "UNEQUIP"
			btn.BackgroundColor3 = Theme.Colors.Warning
			btn.TextColor3 = Color3.new(0, 0, 0)
			btn.Active = true
		else
			local canEquip = equippedCount < GameConfig.MaxEquippedAbilities and not typesEquipped[def.Type]
			if canEquip then
				btn.Text = "EQUIP"
				btn.BackgroundColor3 = Theme.Colors.AccentAlt
				btn.TextColor3 = Color3.new(0, 0, 0)
				btn.Active = true
			else
				btn.Text = typesEquipped[def.Type] and "TIPE SAMA" or "PENUH"
				btn.BackgroundColor3 = Theme.Colors.Panel
				btn.TextColor3 = Theme.Colors.TextDim
				btn.Active = false
			end
		end
	end

	-- Re-wire each refresh: disconnect any previous click connection first.
	for id, card in self.cards do
		if card.Connection then
			card.Connection:Disconnect()
			card.Connection = nil
		end
		local action = card.Action
		card.Connection = action.MouseButton1Click:Connect(function()
			if not action.Active then
				return
			end
			if not self.owned[id] then
				Remotes.RequestBuyAbility:FireServer(id)
			elseif table.find(self.equipped, id) then
				Remotes.RequestUnequipAbility:FireServer(id)
			else
				Remotes.RequestEquipAbility:FireServer(id)
			end
		end)
	end
end

function ShopUI:updateInventory(owned: { [string]: boolean }, equipped: { string })
	self.owned = owned or {}
	self.equipped = equipped or {}
	self:refresh()
end

function ShopUI:updateCoins(amount: number)
	self.coins = amount
	self:refresh()
end

function ShopUI:showMessage(msg: string, color: Color3?)
	self.status.Text = msg
	self.status.TextColor3 = color or Theme.Colors.Warning
	task.delay(4, function()
		if self.status.Text == msg then
			self.status.Text = ""
		end
	end)
end

function ShopUI:setVisible(v: boolean)
	self.overlay.Visible = v
	if v then
		self:refresh()
	end
end

function ShopUI:isVisible(): boolean
	return self.overlay.Visible
end

return ShopUI
