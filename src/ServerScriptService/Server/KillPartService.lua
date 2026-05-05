--[[
	KillPartService - Teleports player to last checkpoint on touch
	Anti-bug: WaitForChild with warnings for missing parts.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local KillPartService = {}

local debounce = {}

function KillPartService.Init(remotes)
	local killFolder = workspace:FindFirstChild("KillParts")
	if not killFolder then
		killFolder = workspace:WaitForChild("KillParts", 30)
	end
	if not killFolder then
		warn("[KillPartService] WARNING: Folder 'KillParts' not found in workspace. No kill parts active.")
		return
	end

	local Server = ServerScriptService:WaitForChild("Server")
	local CheckpointService = require(Server:WaitForChild("CheckpointService"))

	local count = 0
	for _, part in ipairs(killFolder:GetChildren()) do
		if part:IsA("BasePart") then
			count = count + 1
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

	-- Also listen for new kill parts added later (streaming/far parts)
	killFolder.ChildAdded:Connect(function(part)
		if part:IsA("BasePart") then
			count = count + 1
			print("[KillPartService] New kill part loaded: " .. part.Name)
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
	end)

	print("[KillPartService] " .. count .. " kill parts active.")

	Players.PlayerRemoving:Connect(function(player)
		debounce[player.UserId] = nil
	end)
end

return KillPartService
