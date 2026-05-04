--[[
	Server (init)
	Bootstrap: loads all summit kit server services.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Server = ServerScriptService:FindFirstChild("Server")

local DataService = require(Server:FindFirstChild("DataService"))
local CheckpointService = require(Server:FindFirstChild("CheckpointService"))
local SummitService = require(Server:FindFirstChild("SummitService"))
local KillPartService = require(Server:FindFirstChild("KillPartService"))
local OverheadService = require(Server:FindFirstChild("OverheadService"))
local CoinService = require(Server:FindFirstChild("CoinService"))
local ShopService = require(Server:FindFirstChild("ShopService"))
local EmoteService = require(Server:FindFirstChild("EmoteService"))
local MapBuilder = require(Server:FindFirstChild("MapBuilder"))

DataService.Init()
CheckpointService.Init()
SummitService.Init()
KillPartService.Init()
OverheadService.Init()
CoinService.Init()
ShopService.Init()
EmoteService.Init()

-- Build map if not already in workspace
MapBuilder.Init()

Players.PlayerAdded:Connect(function(player)
	DataService.LoadPlayer(player)
	OverheadService.SetupPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	DataService.SavePlayer(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.SavePlayer(player)
	end
end)
