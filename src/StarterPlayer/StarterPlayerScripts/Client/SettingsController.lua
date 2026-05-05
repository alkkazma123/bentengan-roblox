--[[
	SettingsController - Applies local settings to newly spawned players
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteFolder = ReplicatedStorage:WaitForChild("SummitRemotes")
local UpdateSetting = remoteFolder:WaitForChild("UpdateSetting")

local SettingsController = {}

local localSettings = {
	hidePlayers = false,
	hideAura = false,
	hideTrail = false,
}

local function applyToCharacter(character)
	if not character then
		return
	end
	if localSettings.hidePlayers then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") then
				part.Transparency = 1
			elseif part:IsA("BillboardGui") then
				part.Enabled = false
			end
		end
	end
	if localSettings.hideAura then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local aura = hrp:FindFirstChild("SummitAura")
			if aura then
				aura.Enabled = false
			end
		end
	end
	if localSettings.hideTrail then
		local trail = character:FindFirstChild("SummitTrail")
		if trail then
			trail.Enabled = false
		end
	end
end

function SettingsController.Init()
	UpdateSetting.OnClientEvent:Connect(function(key, value)
		localSettings[key] = value
	end)

	local localPlayer = Players.LocalPlayer
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= localPlayer then
			otherPlayer.CharacterAdded:Connect(function(char)
				task.wait(1)
				applyToCharacter(char)
			end)
		end
	end

	Players.PlayerAdded:Connect(function(otherPlayer)
		otherPlayer.CharacterAdded:Connect(function(char)
			task.wait(1)
			applyToCharacter(char)
		end)
	end)
end

return SettingsController
