--[[
	SettingsUI - Settings page in phone
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteFolder = ReplicatedStorage:WaitForChild("SummitRemotes")
local UpdateSetting = remoteFolder:WaitForChild("UpdateSetting")

local SettingsUI = {}

local settings = {
	hidePlayers = false,
	hideAura = false,
	hideTrail = false,
}

function SettingsUI.Init(frame)
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 25)
	title.BackgroundTransparency = 1
	title.Text = "SETTINGS"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	title.ZIndex = 6

	local settingsData = {
		{ key = "hidePlayers", label = "Hide Players" },
		{ key = "hideAura", label = "Hide Auras" },
		{ key = "hideTrail", label = "Hide Trails" },
	}

	for i, s in ipairs(settingsData) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -20, 0, 40)
		row.Position = UDim2.new(0, 10, 0, 30 + (i - 1) * 50)
		row.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
		row.Parent = frame
		row.ZIndex = 6

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 10)
		rowCorner.Parent = row

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.6, 0, 1, 0)
		label.Position = UDim2.new(0, 12, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = s.label
		label.TextColor3 = Color3.fromRGB(220, 220, 220)
		label.TextSize = 13
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row
		label.ZIndex = 7

		local toggleBg = Instance.new("TextButton")
		toggleBg.Size = UDim2.new(0, 50, 0, 26)
		toggleBg.Position = UDim2.new(1, -60, 0.5, -13)
		toggleBg.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
		toggleBg.Text = ""
		toggleBg.Parent = row
		toggleBg.ZIndex = 7

		local toggleCorner = Instance.new("UICorner")
		toggleCorner.CornerRadius = UDim.new(1, 0)
		toggleCorner.Parent = toggleBg

		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 20, 0, 20)
		knob.Position = UDim2.new(0, 3, 0.5, -10)
		knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		knob.Parent = toggleBg
		knob.ZIndex = 8

		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = UDim.new(1, 0)
		knobCorner.Parent = knob

		local key = s.key
		toggleBg.MouseButton1Click:Connect(function()
			settings[key] = not settings[key]
			if settings[key] then
				toggleBg.BackgroundColor3 = Color3.fromRGB(30, 150, 80)
				knob.Position = UDim2.new(1, -23, 0.5, -10)
			else
				toggleBg.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
				knob.Position = UDim2.new(0, 3, 0.5, -10)
			end
			UpdateSetting:FireServer(key, settings[key])
			SettingsUI.ApplySetting(key, settings[key])
		end)
	end
end

function SettingsUI.ApplySetting(key, value)
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= localPlayer then
			local character = otherPlayer.Character
			if character then
				if key == "hidePlayers" then
					for _, part in ipairs(character:GetDescendants()) do
						if part:IsA("BasePart") or part:IsA("Decal") then
							part.Transparency = if value then 1 else 0
						elseif part:IsA("BillboardGui") then
							part.Enabled = not value
						end
					end
				elseif key == "hideAura" then
					local hrp = character:FindFirstChild("HumanoidRootPart")
					if hrp then
						local aura = hrp:FindFirstChild("SummitAura")
						if aura then
							aura.Enabled = not value
						end
					end
				elseif key == "hideTrail" then
					local trail = character:FindFirstChild("SummitTrail")
					if trail then
						trail.Enabled = not value
					end
				end
			end
		end
	end
end

return SettingsUI
