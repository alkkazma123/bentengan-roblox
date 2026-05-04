--[[
	SummitServer (init)
	Bootstrap: loads all summit server services.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local SummitServer = ServerScriptService:FindFirstChild("SummitServer")

local DataService = require(SummitServer:FindFirstChild("DataService"))
local CheckpointService = require(SummitServer:FindFirstChild("CheckpointService"))
local SummitService = require(SummitServer:FindFirstChild("SummitService"))
local KillPartService = require(SummitServer:FindFirstChild("KillPartService"))
local OverheadService = require(SummitServer:FindFirstChild("OverheadService"))
local CoinService = require(SummitServer:FindFirstChild("CoinService"))
local ShopService = require(SummitServer:FindFirstChild("ShopService"))
local EmoteService = require(SummitServer:FindFirstChild("EmoteService"))
local MapBuilder = require(SummitServer:FindFirstChild("MapBuilder"))

-- Initialize services
DataService.Init()
CheckpointService.Init()
SummitService.Init()
KillPartService.Init()
OverheadService.Init()
CoinService.Init()
ShopService.Init()
EmoteService.Init()

-- Build map parts if not already in workspace
MapBuilder.Init()

-- Handle new players
Players.PlayerAdded:Connect(function(player)
	DataService.LoadPlayer(player)
	OverheadService.SetupPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	DataService.SavePlayer(player)
end)

-- Save all on shutdown
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.SavePlayer(player)
	end
end)
