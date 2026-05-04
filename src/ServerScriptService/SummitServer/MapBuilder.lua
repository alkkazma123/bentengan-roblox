--[[
	MapBuilder
	Builds the summit map parts (Start, Checkpoints, Finish, KillParts)
	if they don't already exist in workspace.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SummitShared = ReplicatedStorage:WaitForChild("SummitShared")
local CheckpointConfig = require(SummitShared:WaitForChild("CheckpointConfig"))

local MapBuilder = {}

local function createPart(name, size, position, color, parent, anchored)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Anchored = if anchored ~= nil then anchored else true
	part.CanCollide = true
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = parent
	return part
end

function MapBuilder.Init()
	-- Only build if Checkpoints folder doesn't exist
	if workspace:FindFirstChild("Checkpoints") then
		return
	end

	local checkpointsFolder = Instance.new("Folder")
	checkpointsFolder.Name = "Checkpoints"
	checkpointsFolder.Parent = workspace

	-- Start part (green)
	local startPart =
		createPart("Start", Vector3.new(12, 2, 12), Vector3.new(0, 1, 0), Color3.fromRGB(0, 200, 0), checkpointsFolder)
	-- Add spawn location on start
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StartSpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 2.5, 0)
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Parent = checkpointsFolder
	startPart.Transparency = 0.3

	-- Checkpoints (yellow, ascending)
	local baseHeight = 10
	local heightStep = 15
	local forwardStep = 30

	for i = 1, CheckpointConfig.TotalCheckpoints do
		local yPos = baseHeight + (i * heightStep)
		local zPos = -(i * forwardStep)
		createPart(
			"Checkpoint_" .. i,
			Vector3.new(8, 2, 8),
			Vector3.new(0, yPos, zPos),
			Color3.fromRGB(255, 200, 0),
			checkpointsFolder
		)
	end

	-- Finish/Summit part (gold, at the top)
	local finishY = baseHeight + ((CheckpointConfig.TotalCheckpoints + 1) * heightStep)
	local finishZ = -((CheckpointConfig.TotalCheckpoints + 1) * forwardStep)
	createPart(
		"Finish",
		Vector3.new(10, 2, 10),
		Vector3.new(0, finishY, finishZ),
		Color3.fromRGB(255, 215, 0),
		checkpointsFolder
	)

	-- KillParts folder
	if not workspace:FindFirstChild("KillParts") then
		local killFolder = Instance.new("Folder")
		killFolder.Name = "KillParts"
		killFolder.Parent = workspace

		-- Place kill parts between checkpoints (red)
		for i = 1, CheckpointConfig.TotalCheckpoints do
			local yPos = baseHeight + (i * heightStep) - (heightStep / 2) - 5
			local zPos = -((i - 0.5) * forwardStep)
			local killPart = createPart(
				"KillPart_" .. i,
				Vector3.new(30, 1, 30),
				Vector3.new(0, yPos, zPos),
				Color3.fromRGB(200, 0, 0),
				killFolder
			)
			killPart.Transparency = 0.5
			killPart.CanCollide = false
		end
	end
end

return MapBuilder
