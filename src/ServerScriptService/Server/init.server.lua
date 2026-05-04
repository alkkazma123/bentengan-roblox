--[[
	Server Bootstrap
	Creates remotes then starts all services.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Create remote folder (server only)
local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "SummitRemotes"
remoteFolder.Parent = ReplicatedStorage

-- RemoteEvents
local function createEvent(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remoteFolder
	return remote
end

-- RemoteFunctions
local function createFunc(name)
	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = remoteFolder
	return remote
end

local Remotes = {
	CheckpointReached = createEvent("CheckpointReached"),
	SummitReached = createEvent("SummitReached"),
	PlayerDied = createEvent("PlayerDied"),
	UpdateOverhead = createEvent("UpdateOverhead"),
	UpdateCoins = createEvent("UpdateCoins"),
	EquipItem = createEvent("EquipItem"),
	UnequipItem = createEvent("UnequipItem"),
	UpdateSetting = createEvent("UpdateSetting"),
	PlayEmote = createEvent("PlayEmote"),
	BuyItem = createFunc("BuyItem"),
	GetInventory = createFunc("GetInventory"),
}

-- Load services
local Server = ServerScriptService:WaitForChild("Server")
local DataService = require(Server:WaitForChild("DataService"))
local MapBuilder = require(Server:WaitForChild("MapBuilder"))
local CheckpointService = require(Server:WaitForChild("CheckpointService"))
local SummitService = require(Server:WaitForChild("SummitService"))
local KillPartService = require(Server:WaitForChild("KillPartService"))
local OverheadService = require(Server:WaitForChild("OverheadService"))
local ShopService = require(Server:WaitForChild("ShopService"))
local EmoteService = require(Server:WaitForChild("EmoteService"))

-- Init order matters: MapBuilder first so parts exist
MapBuilder.Init()
DataService.Init()
CheckpointService.Init(Remotes)
SummitService.Init(Remotes)
KillPartService.Init(Remotes)
OverheadService.Init(Remotes)
ShopService.Init(Remotes)
EmoteService.Init(Remotes)

-- Player lifecycle
Players.PlayerAdded:Connect(function(player)
	DataService.LoadPlayer(player)
	OverheadService.SetupPlayer(player)

	-- Send initial coins
	task.wait(1)
	Remotes.UpdateCoins:FireClient(player, DataService.GetCoins(player))
end)

Players.PlayerRemoving:Connect(function(player)
	DataService.SavePlayer(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.SavePlayer(player)
	end
end)
