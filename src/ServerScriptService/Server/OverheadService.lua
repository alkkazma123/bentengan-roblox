--[[
	OverheadService - Creates BillboardGui overhead on players
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TitleConfig = require(Shared:WaitForChild("TitleConfig"))

local OverheadService = {}

local function createBillboard(player, character)
	local head = character:WaitForChild("Head", 5)
	if not head then
		return
	end

	local existing = head:FindFirstChild("SummitOverhead")
	if existing then
		existing:Destroy()
	end

	local Server = ServerScriptService:WaitForChild("Server")
	local DataService = require(Server:WaitForChild("DataService"))
	local data = DataService.GetData(player)
	local summits = data and data.summits or 0
	local title, titleColor = TitleConfig.GetTitle(summits)

	local bb = Instance.new("BillboardGui")
	bb.Name = "SummitOverhead"
	bb.Size = UDim2.new(0, 200, 0, 80)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 50
	bb.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Username"
	nameLabel.Size = UDim2.new(1, 0, 0.35, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.DisplayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = bb

	local summitLabel = Instance.new("TextLabel")
	summitLabel.Name = "Summits"
	summitLabel.Size = UDim2.new(1, 0, 0.3, 0)
	summitLabel.Position = UDim2.new(0, 0, 0.35, 0)
	summitLabel.BackgroundTransparency = 1
	summitLabel.Text = summits .. " Summits"
	summitLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	summitLabel.TextScaled = true
	summitLabel.Font = Enum.Font.Gotham
	summitLabel.Parent = bb

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
	titleLabel.Position = UDim2.new(0, 0, 0.65, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = titleColor
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = bb
end

function OverheadService.SetupPlayer(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		createBillboard(player, character)
	end)
	if player.Character then
		createBillboard(player, player.Character)
	end
end

function OverheadService.Init(_remotes) end

return OverheadService
