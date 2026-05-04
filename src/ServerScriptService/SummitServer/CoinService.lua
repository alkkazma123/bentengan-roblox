--[[
	CoinService
	Manages coin updates and syncs with client.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SummitShared = ReplicatedStorage:WaitForChild("SummitShared")
local Remotes = require(SummitShared:WaitForChild("Remotes"))

local CoinService = {}

function CoinService.Init()
	-- Coins are awarded through CheckpointService and SummitService
	-- This service handles any additional coin-related logic
	Remotes.UpdateCoins.OnServerEvent:Connect(function() end)
end

return CoinService
