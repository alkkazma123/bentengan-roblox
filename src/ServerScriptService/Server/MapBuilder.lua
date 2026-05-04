--[[
	MapBuilder - Auto-generates map parts if not present
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CheckpointConfig = require(Shared:WaitForChild("CheckpointConfig"))

local MapBuilder = {}

function MapBuilder.Init()
	if workspace:FindFirstChild("Checkpoints") then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "Checkpoints"
	folder.Parent = workspace

	-- Start
	local start = Instance.new("Part")
	start.Name = "Start"
	start.Size = Vector3.new(12, 2, 12)
	start.Position = Vector3.new(0, 1, 0)
	start.Color = Color3.fromRGB(0, 200, 0)
	start.Anchored = true
	start.Material = Enum.Material.SmoothPlastic
	start.Transparency = 0.3
	start.Parent = folder

	-- SpawnLocation
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 2.5, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Transparency = 1
	spawn.Parent = folder

	-- Checkpoints
	for i = 1, CheckpointConfig.TotalCheckpoints do
		local cp = Instance.new("Part")
		cp.Name = "Checkpoint_" .. i
		cp.Size = Vector3.new(8, 2, 8)
		cp.Position = Vector3.new(0, 10 + (i * 15), -(i * 30))
		cp.Color = Color3.fromRGB(255, 200, 0)
		cp.Anchored = true
		cp.Material = Enum.Material.SmoothPlastic
		cp.Parent = folder
	end

	-- Finish
	local total = CheckpointConfig.TotalCheckpoints
	local finish = Instance.new("Part")
	finish.Name = "Finish"
	finish.Size = Vector3.new(10, 2, 10)
	finish.Position = Vector3.new(0, 10 + ((total + 1) * 15), -((total + 1) * 30))
	finish.Color = Color3.fromRGB(255, 215, 0)
	finish.Anchored = true
	finish.Material = Enum.Material.Neon
	finish.Parent = folder

	-- KillParts
	if not workspace:FindFirstChild("KillParts") then
		local killFolder = Instance.new("Folder")
		killFolder.Name = "KillParts"
		killFolder.Parent = workspace

		for i = 1, total do
			local kp = Instance.new("Part")
			kp.Name = "KillPart_" .. i
			kp.Size = Vector3.new(30, 1, 30)
			kp.Position = Vector3.new(0, (i * 15) - 2, -((i - 0.5) * 30))
			kp.Color = Color3.fromRGB(200, 0, 0)
			kp.Anchored = true
			kp.Transparency = 0.5
			kp.CanCollide = false
			kp.Parent = killFolder
		end
	end
end

return MapBuilder
