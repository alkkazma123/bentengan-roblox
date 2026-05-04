--[[
	SettingsController
	Applies visibility settings when new players join or characters load.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SummitShared = ReplicatedStorage:WaitForChild("SummitShared")
local Remotes = require(SummitShared:WaitForChild("Remotes"))

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local SettingsController = {}

local localSettings = {
	hidePlayers = false,
	hideAura = false,
	hideTrail = false,
}

local function applyToCharacter(character)
	if localSettings.hidePlayers then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Decal") then
				part.Transparency = 1
			elseif part:IsA("BillboardGui") or part:IsA("ParticleEmitter") or part:IsA("Trail") then
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
	-- Listen for setting changes from SettingsUI
	Remotes.UpdateSetting.OnClientEvent:Connect(function(key, value)
		if localSettings[key] ~= nil then
			localSettings[key] = value
		end
	end)

	-- Apply to new characters
	Players.PlayerAdded:Connect(function(otherPlayer)
		if otherPlayer == player then
			return
		end
		otherPlayer.CharacterAdded:Connect(function(character)
			task.wait(1)
			applyToCharacter(character)
		end)
	end)

	-- Apply to existing players
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			if otherPlayer.Character then
				applyToCharacter(otherPlayer.Character)
			end
			otherPlayer.CharacterAdded:Connect(function(character)
				task.wait(1)
				applyToCharacter(character)
			end)
		end
	end
end

return SettingsController
