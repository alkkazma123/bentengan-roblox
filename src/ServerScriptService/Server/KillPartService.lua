--[[
	KillPartService - Teleports player to last checkpoint on touch
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local KillPartService = {}

local debounce = {}

function KillPartService.Init(remotes)
	local killFolder = workspace:FindFirstChild("KillParts")
	if not killFolder then
		return
	end

	local Server = ServerScriptService:WaitForChild("Server")
	local CheckpointService = require(Server:WaitForChild("CheckpointService"))

	for _, part in ipairs(killFolder:GetChildren()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if not player then
					return
				end
				if debounce[player.UserId] then
					return
				end
				debounce[player.UserId] = true

				local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					hrp.CFrame = CheckpointService.GetSpawnCFrame(player)
				end

				remotes.PlayerDied:FireClient(player)

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
