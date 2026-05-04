--[[
	SummitService - Awards summits when player touches Finish
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SummitConfig = require(Shared:WaitForChild("SummitConfig"))
local CoinConfig = require(Shared:WaitForChild("CoinConfig"))

local SummitService = {}

local cooldowns = {}

function SummitService.Init(remotes)
	local folder = workspace:WaitForChild("Checkpoints", 10)
	if not folder then
		return
	end

	local finishPart = folder:FindFirstChild("Finish")
	if not finishPart then
		return
	end

	local Server = ServerScriptService:WaitForChild("Server")
	local DataService = require(Server:WaitForChild("DataService"))
	local CheckpointService = require(Server:WaitForChild("CheckpointService"))

	finishPart.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end

		local now = tick()
		if cooldowns[player.UserId] and (now - cooldowns[player.UserId]) < SummitConfig.Cooldown then
			return
		end
		cooldowns[player.UserId] = now

		DataService.AddSummits(player, SummitConfig.SummitsPerFinish)
		DataService.AddCoins(player, CoinConfig.CoinsPerSummit)

		local data = DataService.GetData(player)
		local summits = data and data.summits or 0
		remotes.SummitReached:FireClient(player, summits)
		remotes.UpdateCoins:FireClient(player, DataService.GetCoins(player))
		remotes.UpdateOverhead:FireAllClients(player, summits)

		CheckpointService.ResetCheckpoint(player)

		if SummitConfig.TeleportToStart then
			task.delay(SummitConfig.TeleportDelay, function()
				if player.Character then
					local hrp = player.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						hrp.CFrame = CheckpointService.GetSpawnCFrame(player)
					end
				end
			end)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player.UserId] = nil
	end)
end

return SummitService
