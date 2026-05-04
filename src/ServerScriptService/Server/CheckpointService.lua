--[[
	CheckpointService
	Handles checkpoint touch detection and player respawn tracking.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CheckpointConfig = require(Shared:WaitForChild("CheckpointConfig"))
local CoinConfig = require(Shared:WaitForChild("CoinConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local CheckpointService = {}

local playerCheckpoints = {}

function CheckpointService.Init()
	local checkpointsFolder = workspace:FindFirstChild("Checkpoints")
	if not checkpointsFolder then
		return
	end

	local startPart = checkpointsFolder:FindFirstChild("Start")
	if startPart then
		startPart.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end
			CheckpointService.SetCheckpoint(player, 0, startPart.Position)
		end)
	end

	for i = 1, CheckpointConfig.TotalCheckpoints do
		local cpPart = checkpointsFolder:FindFirstChild("Checkpoint_" .. i)
		if cpPart then
			local index = i
			cpPart.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if not player then
					return
				end
				local current = CheckpointService.GetCheckpoint(player)
				if index > current then
					CheckpointService.SetCheckpoint(player, index, cpPart.Position)
					Remotes.CheckpointReached:FireClient(player, index)

					local Server = ServerScriptService:FindFirstChild("Server")
					local DataService = require(Server:FindFirstChild("DataService"))
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

Players.PlayerRemoving:Connect(function(player)
	playerCheckpoints[player.UserId] = nil
end)

return CheckpointService
