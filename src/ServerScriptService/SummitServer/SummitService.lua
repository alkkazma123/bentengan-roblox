--[[
	SummitService
	Handles the summit/finish part - awards summits and coins when touched.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SummitShared = ReplicatedStorage:WaitForChild("SummitShared")
local SummitConfig = require(SummitShared:WaitForChild("SummitConfig"))
local CoinConfig = require(SummitShared:WaitForChild("CoinConfig"))
local Remotes = require(SummitShared:WaitForChild("Remotes"))

local SummitService = {}

local cooldowns = {}

function SummitService.Init()
	local checkpointsFolder = workspace:FindFirstChild("Checkpoints")
	if not checkpointsFolder then
		return
	end

	local finishPart = checkpointsFolder:FindFirstChild("Finish")
	if not finishPart then
		return
	end

	finishPart.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end

		-- Cooldown check
		local now = tick()
		if cooldowns[player.UserId] and (now - cooldowns[player.UserId]) < SummitConfig.Cooldown then
			return
		end
		cooldowns[player.UserId] = now

		local SummitServer = ServerScriptService:FindFirstChild("SummitServer")
		local DataService = require(SummitServer:FindFirstChild("DataService"))
		local CheckpointService = require(SummitServer:FindFirstChild("CheckpointService"))

		-- Award summits
		DataService.AddSummits(player, SummitConfig.SummitsPerFinish)

		-- Award coins
		DataService.AddCoins(player, CoinConfig.CoinsPerSummit)

		-- Notify client
		local data = DataService.GetData(player)
		Remotes.SummitReached:FireClient(player, data.summits)
		Remotes.UpdateCoins:FireClient(player, data.coins)
		Remotes.UpdateOverhead:FireAllClients(player, data.summits)

		-- Reset checkpoint and teleport back
		CheckpointService.ResetPlayer(player)

		if SummitConfig.TeleportToStartAfterSummit then
			task.delay(SummitConfig.TeleportDelay, function()
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local spawnPos = CheckpointService.GetSpawnPosition(player)
					player.Character.HumanoidRootPart.CFrame = CFrame.new(spawnPos)
				end
			end)
		end
	end)

	-- Clean up cooldowns
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player.UserId] = nil
	end)
end

return SummitService
