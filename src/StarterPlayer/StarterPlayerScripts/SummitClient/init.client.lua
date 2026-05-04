--[[
	SummitClient (init)
	Bootstrap: loads all summit client controllers.
]]

local StarterPlayerScripts = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts")
local SummitClient = StarterPlayerScripts:WaitForChild("SummitClient")

local CheckpointFX = require(SummitClient:WaitForChild("CheckpointFX"))
local PhoneUI = require(SummitClient:WaitForChild("PhoneUI"))
local OverheadController = require(SummitClient:WaitForChild("OverheadController"))
local SettingsController = require(SummitClient:WaitForChild("SettingsController"))

-- Initialize all controllers
CheckpointFX.Init()
PhoneUI.Init()
OverheadController.Init()
SettingsController.Init()
