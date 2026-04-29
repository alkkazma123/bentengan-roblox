--!strict
-- Creates and/or fetches RemoteEvents & RemoteFunctions used by the game.
-- This runs on first require from either server or client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "BentenganRemotes"

local EVENTS = {
	-- Lobby
	"RequestJoinLobby",
	"RequestLeaveLobby",
	"LobbyStateUpdate", -- server -> client broadcast of all lobbies
	"MatchCountdown",
	"MatchStart",
	"MatchEnd",
	-- UI / Client
	"ClientReady",
	"ShowRules",
	-- Shop
	"RequestBuyAbility",
	"RequestEquipAbility",
	"RequestUnequipAbility",
	"InventoryUpdate",
	"CoinsUpdate",
	-- Match runtime
	"AbilityActivate", -- client -> server (for toggleable abilities like Fly)
	"AbilityFeedback", -- server -> client (cooldown/duration updates)
	"TagEvent", -- server -> broadcast tag info (for sfx/hud)
	"JailUpdate",
	"TeamAssigned",
	"RequestDash", -- client -> server (L-Shift / Dash button)
	"DashFeedback", -- server -> client (dash cooldown sync)
	-- Leaderboard
	"LeaderboardUpdate",
}

local FUNCTIONS = {
	"GetProfile",
	"GetLobbyState",
}

local function getOrCreateFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	if RunService:IsServer() then
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME, 30) :: Folder
end

local folder = getOrCreateFolder()

local function ensureInstance(className: string, name: string): Instance
	local child = folder:FindFirstChild(name)
	if child then
		return child
	end
	if RunService:IsServer() then
		local inst = Instance.new(className)
		inst.Name = name
		inst.Parent = folder
		return inst
	end
	return folder:WaitForChild(name, 30)
end

local Remotes = {}

for _, name in ipairs(EVENTS) do
	Remotes[name] = ensureInstance("RemoteEvent", name) :: RemoteEvent
end

for _, name in ipairs(FUNCTIONS) do
	Remotes[name] = ensureInstance("RemoteFunction", name) :: RemoteFunction
end

return Remotes
