--[[
	OverheadService
	Creates and manages overhead BillboardGui showing username, summits, and title.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SummitShared = ReplicatedStorage:WaitForChild("SummitShared")
local TitleConfig = require(SummitShared:WaitForChild("TitleConfig"))
local Remotes = require(SummitShared:WaitForChild("Remotes"))

local OverheadService = {}

function OverheadService.Init()
	Remotes.UpdateOverhead.OnServerEvent:Connect(function() end)
end

function OverheadService.SetupPlayer(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		OverheadService.CreateOverhead(player, character)
	end)

	if player.Character then
		OverheadService.CreateOverhead(player, player.Character)
	end
end

function OverheadService.CreateOverhead(player, character)
	local head = character:WaitForChild("Head", 5)
	if not head then
		return
	end

	-- Remove existing
	local existing = head:FindFirstChild("SummitOverhead")
	if existing then
		existing:Destroy()
	end

	local SummitServer = ServerScriptService:FindFirstChild("SummitServer")
	local DataService = require(SummitServer:FindFirstChild("DataService"))
	local data = DataService.GetData(player)
	local summits = data and data.summits or 0
	local title, titleColor = TitleConfig.GetTitle(summits)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SummitOverhead"
	billboard.Size = UDim2.new(0, 200, 0, 80)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 50
	billboard.Parent = head

	-- Username
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Username"
	nameLabel.Size = UDim2.new(1, 0, 0.35, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.DisplayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = billboard

	-- Summit count
	local summitLabel = Instance.new("TextLabel")
	summitLabel.Name = "Summits"
	summitLabel.Size = UDim2.new(1, 0, 0.3, 0)
	summitLabel.Position = UDim2.new(0, 0, 0.35, 0)
	summitLabel.BackgroundTransparency = 1
	summitLabel.Text = summits .. " Summits"
	summitLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	summitLabel.TextScaled = true
	summitLabel.Font = Enum.Font.Gotham
	summitLabel.Parent = billboard

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
	titleLabel.Position = UDim2.new(0, 0, 0.65, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = titleColor
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = billboard
end

function OverheadService.UpdateOverhead(player)
	if not player.Character then
		return
	end
	local head = player.Character:FindFirstChild("Head")
	if not head then
		return
	end

	local billboard = head:FindFirstChild("SummitOverhead")
	if not billboard then
		return
	end

	local SummitServer = ServerScriptService:FindFirstChild("SummitServer")
	local DataService = require(SummitServer:FindFirstChild("DataService"))
	local data = DataService.GetData(player)
	local summits = data and data.summits or 0
	local title, titleColor = TitleConfig.GetTitle(summits)

	local summitLabel = billboard:FindFirstChild("Summits")
	if summitLabel then
		summitLabel.Text = summits .. " Summits"
	end

	local titleLabel = billboard:FindFirstChild("Title")
	if titleLabel then
		titleLabel.Text = title
		titleLabel.TextColor3 = titleColor
	end
end

return OverheadService
