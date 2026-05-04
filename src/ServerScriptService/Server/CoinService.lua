--[[
	CoinService
	Manages coin sync. Coins are awarded via CheckpointService and SummitService.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local CoinService = {}

function CoinService.Init()
	Remotes.UpdateCoins.OnServerEvent:Connect(function() end)
end

return CoinService
