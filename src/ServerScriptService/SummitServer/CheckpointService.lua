--[[
	CheckpointService
	Handles checkpoint touch detection and player respawn tracking.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SummitShared = ReplicatedStorage:WaitForChild("SummitShared")
local CheckpointConfig = require(SummitShared:WaitForChild("CheckpointConfig"))
local CoinConfig = require(SummitShared:WaitForChild("CoinConfig"))
local Remotes = require(SummitShared:WaitForChild("Remotes"))

local CheckpointService = {}

-- Track last checkpoint per player
local playerCheckpoints = {}

function CheckpointService.Init()
	-- Connect checkpoint touches
	local checkpointsFolder = workspace:FindFirstChild("Checkpoints")
	if not checkpointsFolder then
		return
	end

	-- Start part
	local startPart = checkpointsFolder:FindFirstChild("Start")
	if startPart then
		startPart.Touched:Connect(function(hit)
			local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end
			CheckpointService.SetCheckpoint(player, 0, startPart.Position)
		end)
	end

	-- Numbered checkpoints
	for i = 1, CheckpointConfig.TotalCheckpoints do
		local cpPart = checkpointsFolder:FindFirstChild("Checkpoint_" .. i)
		if cpPart then
			local index = i
			cpPart.Touched:Connect(function(hit)
				local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
				if not player then
					return
				end
				local current = CheckpointService.GetCheckpoint(player)
				if index > current then
					CheckpointService.SetCheckpoint(player, index, cpPart.Position)
					Remotes.CheckpointReached:FireClient(player, index)

					-- Award coins for first time reaching checkpoint this life
					local DataService = require(game:GetService("ServerScriptService").SummitServer.DataService)
					DataService.AddCoins(player, CoinConfig.CoinsPerCheckpoint)
					Remotes.UpdateCoins:FireClient(player, DataService.GetCoins(player))
				end
			end)
		end
	end
end

function CheckpointService.SetCheckpoint(player, index, position)
	playerCheckpoints[player.UserId] = { index = index, position = position }
end

function CheckpointService.GetCheckpoint(player)
	local data = playerCheckpoints[player.UserId]
	if data then
		return data.index
	end
	return 0
end

function CheckpointService.GetSpawnPosition(player)
	local data = playerCheckpoints[player.UserId]
	if data then
		return data.position + Vector3.new(0, 3, 0)
	end
	-- Default: start part
	local checkpointsFolder = workspace:FindFirstChild("Checkpoints")
	if checkpointsFolder then
		local startPart = checkpointsFolder:FindFirstChild("Start")
		if startPart then
			return startPart.Position + Vector3.new(0, 3, 0)
		end
	end
	return Vector3.new(0, 10, 0)
end

function CheckpointService.ResetPlayer(player)
	playerCheckpoints[player.UserId] = nil
end

-- Clean up on leave
game:GetService("Players").PlayerRemoving:Connect(function(player)
	playerCheckpoints[player.UserId] = nil
end)

return CheckpointService
