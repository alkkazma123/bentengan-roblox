--[[
	CheckpointService - Tracks player checkpoints
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CheckpointConfig = require(Shared:WaitForChild("CheckpointConfig"))
local CoinConfig = require(Shared:WaitForChild("CoinConfig"))

local CheckpointService = {}

local playerCheckpoints = {}
local Remotes = nil

function CheckpointService.GetSpawnCFrame(player)
	local data = playerCheckpoints[player.UserId]
	if data and data.cframe then
		return data.cframe + Vector3.new(0, 3, 0)
	end
	local folder = workspace:FindFirstChild("Checkpoints")
	if folder then
		local startPart = folder:FindFirstChild("Start")
		if startPart then
			return startPart.CFrame + Vector3.new(0, 3, 0)
		end
	end
	return CFrame.new(0, 10, 0)
end

function CheckpointService.GetCheckpointIndex(player)
	local data = playerCheckpoints[player.UserId]
	return data and data.index or 0
end

function CheckpointService.ResetCheckpoint(player)
	playerCheckpoints[player.UserId] = nil
end

function CheckpointService.Init(remotes)
	Remotes = remotes

	local folder = workspace:WaitForChild("Checkpoints", 10)
	if not folder then
		return
	end

	local Server = ServerScriptService:WaitForChild("Server")
	local DataService = require(Server:WaitForChild("DataService"))

	-- Start part
	local startPart = folder:FindFirstChild("Start")
	if startPart then
		startPart.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end
			playerCheckpoints[player.UserId] = { index = 0, cframe = startPart.CFrame }
		end)
	end

	-- Checkpoint parts
	for i = 1, CheckpointConfig.TotalCheckpoints do
		local cp = folder:FindFirstChild("Checkpoint_" .. i)
		if cp then
			local idx = i
			cp.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if not player then
					return
				end
				local current = CheckpointService.GetCheckpointIndex(player)
				if idx > current then
					playerCheckpoints[player.UserId] = { index = idx, cframe = cp.CFrame }
					Remotes.CheckpointReached:FireClient(player, idx)
					DataService.AddCoins(player, CoinConfig.CoinsPerCheckpoint)
					Remotes.UpdateCoins:FireClient(player, DataService.GetCoins(player))
				end
			end)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		playerCheckpoints[player.UserId] = nil
	end)
end

return CheckpointService
