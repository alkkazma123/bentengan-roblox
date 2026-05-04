--[[
	SummitService - Awards summits when player touches Finish
	Player stays at summit. On respawn, goes back to start (checkpoint reset).
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
	local folder = workspace:FindFirstChild("Checkpoints")
	if not folder then
		folder = workspace:WaitForChild("Checkpoints", 30)
	end
	if not folder then
		warn("[SummitService] ERROR: Folder 'Checkpoints' not found in workspace!")
		return
	end

	local finishPart = folder:FindFirstChild("Finish")
	if not finishPart then
		finishPart = folder:WaitForChild("Finish", 30)
	end
	if not finishPart then
		warn("[SummitService] ERROR: Part 'Finish' not found in Checkpoints folder!")
		return
	end

	print("[SummitService] Finish part found. Service ready.")

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

		-- Award summit + coins
		DataService.AddSummits(player, SummitConfig.SummitsPerFinish)
		DataService.AddCoins(player, CoinConfig.CoinsPerSummit)

		local data = DataService.GetData(player)
		local summits = data and data.summits or 0
		remotes.SummitReached:FireClient(player, summits)
		remotes.UpdateCoins:FireClient(player, DataService.GetCoins(player))
		remotes.UpdateOverhead:FireAllClients(player, summits)

		-- Reset checkpoint so on respawn player goes back to start
		CheckpointService.ResetCheckpoint(player)

		print("[SummitService] " .. player.Name .. " reached summit! Total: " .. summits)
	end)

	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player.UserId] = nil
	end)
end

return SummitService
