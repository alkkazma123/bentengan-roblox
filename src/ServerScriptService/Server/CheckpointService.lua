--[[
	CheckpointService - Tracks player checkpoints
	Saves last checkpoint to DataStore.
	On login: player spawns at last saved checkpoint.
	On respawn: teleports to last checkpoint (or start if reset).
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CheckpointConfig = require(Shared:WaitForChild("CheckpointConfig"))
local CoinConfig = require(Shared:WaitForChild("CoinConfig"))

local CheckpointService = {}

local playerCheckpoints = {}
local checkpointParts = {}
local Remotes = nil
local startCFrame = CFrame.new(0, 10, 0)

function CheckpointService.GetSpawnCFrame(player)
	local data = playerCheckpoints[player.UserId]
	if data and data.index > 0 then
		local cp = checkpointParts[data.index]
		if cp then
			return cp.CFrame + Vector3.new(0, 3, 0)
		end
	end
	return startCFrame + Vector3.new(0, 3, 0)
end

function CheckpointService.GetCheckpointIndex(player)
	local data = playerCheckpoints[player.UserId]
	return data and data.index or 0
end

function CheckpointService.ResetCheckpoint(player)
	playerCheckpoints[player.UserId] = nil
	local Server = ServerScriptService:WaitForChild("Server")
	local DataService = require(Server:WaitForChild("DataService"))
	DataService.SetLastCheckpoint(player, 0)
end

function CheckpointService.Init(remotes)
	Remotes = remotes

	local folder = workspace:FindFirstChild("Checkpoints")
	if not folder then
		folder = workspace:WaitForChild("Checkpoints", 30)
	end
	if not folder then
		warn("[CheckpointService] ERROR: Folder 'Checkpoints' not found in workspace!")
		return
	end

	local Server = ServerScriptService:WaitForChild("Server")
	local DataService = require(Server:WaitForChild("DataService"))

	-- Start part
	local startPart = folder:FindFirstChild("Start")
	if not startPart then
		startPart = folder:WaitForChild("Start", 30)
	end
	if startPart then
		startCFrame = startPart.CFrame
		startPart.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end
			playerCheckpoints[player.UserId] = { index = 0 }
		end)
		print("[CheckpointService] Start part found.")
	else
		warn("[CheckpointService] WARNING: Part 'Start' not found! Using default spawn.")
	end

	-- Checkpoint parts
	local foundCount = 0
	for i = 1, CheckpointConfig.TotalCheckpoints do
		local cp = folder:FindFirstChild("Checkpoint_" .. i)
		if not cp then
			cp = folder:WaitForChild("Checkpoint_" .. i, 10)
		end
		if cp then
			foundCount = foundCount + 1
			checkpointParts[i] = cp
			local idx = i
			cp.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if not player then
					return
				end
				local current = CheckpointService.GetCheckpointIndex(player)
				if idx > current then
					playerCheckpoints[player.UserId] = { index = idx }
					DataService.SetLastCheckpoint(player, idx)
					Remotes.CheckpointReached:FireClient(player, idx)
					DataService.AddCoins(player, CoinConfig.CoinsPerCheckpoint)
					Remotes.UpdateCoins:FireClient(player, DataService.GetCoins(player))
					print("[CheckpointService] " .. player.Name .. " reached Checkpoint_" .. idx)
				end
			end)
		else
			warn("[CheckpointService] WARNING: Checkpoint_" .. i .. " not found!")
		end
	end

	print("[CheckpointService] Found " .. foundCount .. "/" .. CheckpointConfig.TotalCheckpoints .. " checkpoints.")

	-- Respawn + login handler
	Players.PlayerAdded:Connect(function(player)
		-- Wait for data to load
		task.wait(1.5)
		local savedCp = DataService.GetLastCheckpoint(player)
		if savedCp > 0 then
			playerCheckpoints[player.UserId] = { index = savedCp }
			print("[CheckpointService] " .. player.Name .. " resuming at Checkpoint_" .. savedCp)
		end

		player.CharacterAdded:Connect(function(character)
			task.wait(0.2)
			local hrp = character:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				hrp.CFrame = CheckpointService.GetSpawnCFrame(player)
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerCheckpoints[player.UserId] = nil
	end)
end

return CheckpointService
