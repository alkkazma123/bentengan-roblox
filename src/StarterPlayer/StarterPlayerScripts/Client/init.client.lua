--[[
	Client (init)
	Bootstrap: loads all summit kit client controllers.
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local Client = playerScripts:WaitForChild("Client")

local CheckpointFX = require(Client:WaitForChild("CheckpointFX"))
local PhoneUI = require(Client:WaitForChild("PhoneUI"))
local OverheadController = require(Client:WaitForChild("OverheadController"))
local SettingsController = require(Client:WaitForChild("SettingsController"))

CheckpointFX.Init()
PhoneUI.Init()
OverheadController.Init()
SettingsController.Init()
