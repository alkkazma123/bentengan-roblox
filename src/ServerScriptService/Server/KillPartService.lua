--[[
	KillPartService
	Handles kill parts - teleports player to last checkpoint when touched.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local KillPartService = {}

local debounce = {}

function KillPartService.Init()
	local killPartsFolder = workspace:FindFirstChild("KillParts")
	if not killPartsFolder then
		return
	end

	for _, killPart in ipairs(killPartsFolder:GetChildren()) do
		if killPart:IsA("BasePart") then
			killPart.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if not player then
					return
				end

				if debounce[player.UserId] then
					return
				end
				debounce[player.UserId] = true

				local Server = ServerScriptService:FindFirstChild("Server")
				local CheckpointService = require(Server:FindFirstChild("CheckpointService"))

				local spawnPos = CheckpointService.GetSpawnPosition(player)
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					player.Character.HumanoidRootPart.CFrame = CFrame.new(spawnPos)
				end

				Remotes.PlayerDied:FireClient(player)

				task.delay(1, function()
					debounce[player.UserId] = nil
				end)
			end)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		debounce[player.UserId] = nil
	end)
end

return KillPartService
