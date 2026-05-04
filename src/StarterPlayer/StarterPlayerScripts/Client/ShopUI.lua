--[[
	ShopUI
	Shop page inside the phone menu - shows trails and auras for purchase.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(Shared:WaitForChild("ShopConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local ShopUI = {}

local function createItemButton(item, _categoryName, scrollFrame, _index)
	local btn = Instance.new("Frame")
	btn.Name = "Item_" .. item.id
	btn.Size = UDim2.new(1, -16, 0, 60)
	btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	btn.BorderSizePixel = 0
	btn.Parent = scrollFrame
	btn.ZIndex = 6

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	local preview = Instance.new("Frame")
	preview.Name = "Preview"
	preview.Size = UDim2.new(0, 40, 0, 40)
	preview.Position = UDim2.new(0, 10, 0.5, -20)
	preview.BackgroundColor3 = item.trailColor or item.particleColor or Color3.fromRGB(255, 255, 255)
	preview.Parent = btn
	preview.ZIndex = 7

	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0.5, 0)
	previewCorner.Parent = preview

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ItemName"
	nameLabel.Size = UDim2.new(0.5, -60, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 60, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Text = item.name
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = btn
	nameLabel.ZIndex = 7

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Size = UDim2.new(0.5, -60, 0.5, 0)
	priceLabel.Position = UDim2.new(0, 60, 0.5, -5)
	priceLabel.BackgroundTransparency = 1
	priceLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
	priceLabel.Text = item.price .. " coins"
	priceLabel.TextSize = 12
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.Parent = btn
	priceLabel.ZIndex = 7

	local actionBtn = Instance.new("TextButton")
	actionBtn.Name = "ActionBtn"
	actionBtn.Size = UDim2.new(0, 70, 0, 30)
	actionBtn.Position = UDim2.new(1, -80, 0.5, -15)
	actionBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
	actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	actionBtn.Text = "Buy"
	actionBtn.TextSize = 12
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.BorderSizePixel = 0
	actionBtn.Parent = btn
	actionBtn.ZIndex = 8

	local actionCorner = Instance.new("UICorner")
	actionCorner.CornerRadius = UDim.new(0, 6)
	actionCorner.Parent = actionBtn

	actionBtn.MouseButton1Click:Connect(function()
		local success, result = Remotes.BuyItem:InvokeServer(item.id)
		if success then
			actionBtn.Text = "Equip"
			actionBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 180)
			priceLabel.Text = "Owned"
			priceLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		else
			actionBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			actionBtn.Text = result or "Error"
			task.delay(1, function()
				actionBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
				actionBtn.Text = "Buy"
			end)
		end
	end)
end

function ShopUI.Init(frame)
	local title = Instance.new("TextLabel")
	title.Name = "ShopTitle"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Text = "SHOP"
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	title.ZIndex = 6

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "ShopScroll"
	scroll.Size = UDim2.new(1, -10, 1, -40)
	scroll.Position = UDim2.new(0, 5, 0, 38)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = frame
	scroll.ZIndex = 6

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = scroll

	local index = 0
	for _, category in ipairs(ShopConfig.Categories) do
		local header = Instance.new("TextLabel")
		header.Name = "Header_" .. category.name
		header.Size = UDim2.new(1, -16, 0, 25)
		header.BackgroundTransparency = 1
		header.TextColor3 = Color3.fromRGB(180, 180, 180)
		header.Text = "-- " .. category.name .. " --"
		header.TextSize = 12
		header.Font = Enum.Font.Gotham
		header.LayoutOrder = index
		header.Parent = scroll
		header.ZIndex = 6
		index = index + 1

		for _, item in ipairs(category.items) do
			createItemButton(item, category.name, scroll, index)
			index = index + 1
		end
	end

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
end

return ShopUI
