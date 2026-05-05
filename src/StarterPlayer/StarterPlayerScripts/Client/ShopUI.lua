--[[
	ShopUI - Shop interface inside phone
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(Shared:WaitForChild("ShopConfig"))

local remoteFolder = ReplicatedStorage:WaitForChild("SummitRemotes")
local BuyItem = remoteFolder:WaitForChild("BuyItem")
local EquipItem = remoteFolder:WaitForChild("EquipItem")
local UnequipItem = remoteFolder:WaitForChild("UnequipItem")

local ShopUI = {}

function ShopUI.Init(frame)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = "SHOP"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	title.ZIndex = 6

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -10, 1, -35)
	scroll.Position = UDim2.new(0, 5, 0, 35)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = frame
	scroll.ZIndex = 6

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = scroll

	for _, category in ipairs(ShopConfig.Categories) do
		-- Category header
		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(1, 0, 0, 25)
		header.BackgroundTransparency = 1
		header.Text = "— " .. category.name .. " —"
		header.TextColor3 = Color3.fromRGB(200, 200, 200)
		header.TextSize = 14
		header.Font = Enum.Font.GothamBold
		header.Parent = scroll
		header.ZIndex = 6

		for _, item in ipairs(category.items) do
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 40)
			row.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
			row.Parent = scroll
			row.ZIndex = 6

			local rowCorner = Instance.new("UICorner")
			rowCorner.CornerRadius = UDim.new(0, 8)
			rowCorner.Parent = row

			-- Color preview
			local preview = Instance.new("Frame")
			preview.Size = UDim2.new(0, 20, 0, 20)
			preview.Position = UDim2.new(0, 8, 0.5, -10)
			preview.BackgroundColor3 = item.color
			preview.Parent = row
			preview.ZIndex = 7

			local previewCorner = Instance.new("UICorner")
			previewCorner.CornerRadius = UDim.new(1, 0)
			previewCorner.Parent = preview

			-- Name
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.5, -40, 1, 0)
			nameLabel.Position = UDim2.new(0, 36, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = item.name
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextSize = 11
			nameLabel.Font = Enum.Font.Gotham
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = row
			nameLabel.ZIndex = 7

			-- Buy button
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 60, 0, 28)
			btn.Position = UDim2.new(1, -68, 0.5, -14)
			btn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.Text = "$" .. item.price
			btn.TextSize = 11
			btn.Font = Enum.Font.GothamBold
			btn.Parent = row
			btn.ZIndex = 7

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 6)
			btnCorner.Parent = btn

			local itemId = item.id
			local catName = category.name

			btn.MouseButton1Click:Connect(function()
				if btn.Text == "Equip" then
					EquipItem:FireServer(itemId)
					btn.Text = "Unequip"
					btn.BackgroundColor3 = Color3.fromRGB(150, 50, 0)
				elseif btn.Text == "Unequip" then
					local slot = if catName == "Trails" then "trail" else "aura"
					UnequipItem:FireServer(slot)
					btn.Text = "Equip"
					btn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
				else
					local ok, msg = BuyItem:InvokeServer(itemId)
					if ok then
						btn.Text = "Equip"
						btn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
					else
						btn.Text = msg or "Error"
						task.delay(1.5, function()
							btn.Text = "$" .. item.price
							btn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
						end)
					end
				end
			end)
		end
	end
end

return ShopUI
