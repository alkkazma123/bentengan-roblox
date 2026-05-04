--[[
	Client Bootstrap - Loads all client controllers
]]

local script_folder = script

local CheckpointFX = require(script_folder:WaitForChild("CheckpointFX"))
local PhoneUI = require(script_folder:WaitForChild("PhoneUI"))
local OverheadController = require(script_folder:WaitForChild("OverheadController"))
local SettingsController = require(script_folder:WaitForChild("SettingsController"))
local AvatarCatalogUI = require(script_folder:WaitForChild("AvatarCatalogUI"))

CheckpointFX.Init()
PhoneUI.Init()
OverheadController.Init()
SettingsController.Init()
AvatarCatalogUI.Init()
