--[[
	CheckpointFX
	Handles screen shake and checkpoint notification when reaching a checkpoint.
	Also handles summit celebration and death effects.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SummitShared = ReplicatedStorage:WaitForChild("SummitShared")
local CheckpointConfig = require(SummitShared:WaitForChild("CheckpointConfig"))
local SummitConfig = require(SummitShared:WaitForChild("SummitConfig"))
local Remotes = require(SummitShared:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CheckpointFX = {}

local screenGui = nil
local notifLabel = nil

local function createUI()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CheckpointFXGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	notifLabel = Instance.new("TextLabel")
	notifLabel.Name = "Notification"
	notifLabel.Size = UDim2.new(0, 400, 0, 60)
	notifLabel.Position = UDim2.new(0.5, -200, 0, 80)
	notifLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	notifLabel.BackgroundTransparency = 0.3
	notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	notifLabel.TextScaled = true
	notifLabel.Font = Enum.Font.GothamBold
	notifLabel.Text = ""
	notifLabel.Visible = false
	notifLabel.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = notifLabel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 200, 0)
	stroke.Thickness = 2
	stroke.Parent = notifLabel
end

local function screenShake()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local intensity = CheckpointConfig.ShakeIntensity
	local duration = CheckpointConfig.ShakeDuration
	local startTime = tick()

	local connection
	connection = game:GetService("RunService").RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= duration then
			connection:Disconnect()
			return
		end

		local progress = elapsed / duration
		local currentIntensity = intensity * (1 - progress)
		local offsetX = (math.random() - 0.5) * 2 * currentIntensity
		local offsetY = (math.random() - 0.5) * 2 * currentIntensity
		camera.CFrame = camera.CFrame * CFrame.new(offsetX * 0.01, offsetY * 0.01, 0)
	end)
end

local function showNotification(text, color)
	if not notifLabel then
		return
	end
	notifLabel.Text = text
	notifLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	notifLabel.Visible = true
	notifLabel.TextTransparency = 0
	notifLabel.BackgroundTransparency = 0.3

	task.delay(CheckpointConfig.NotificationDuration, function()
		if notifLabel then
			local tween = TweenService:Create(notifLabel, TweenInfo.new(0.5), {
				TextTransparency = 1,
				BackgroundTransparency = 1,
			})
			tween:Play()
			tween.Completed:Connect(function()
				if notifLabel then
					notifLabel.Visible = false
				end
			end)
		end
	end)
end

function CheckpointFX.Init()
	createUI()

	-- Checkpoint reached
	Remotes.CheckpointReached.OnClientEvent:Connect(function(checkpointIndex)
		screenShake()

		local name = "Checkpoint " .. checkpointIndex
		if CheckpointConfig.Names and CheckpointConfig.Names[checkpointIndex] then
			name = CheckpointConfig.Names[checkpointIndex]
		end
		showNotification(name, Color3.fromRGB(255, 200, 0))
	end)

	-- Summit reached
	Remotes.SummitReached.OnClientEvent:Connect(function(totalSummits)
		screenShake()
		showNotification(
			SummitConfig.CelebrationMessage .. " (" .. totalSummits .. " total)",
			Color3.fromRGB(255, 215, 0)
		)
	end)

	-- Player died (kill part)
	Remotes.PlayerDied.OnClientEvent:Connect(function()
		screenShake()
	end)
end

return CheckpointFX
