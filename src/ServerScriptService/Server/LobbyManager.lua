--!strict
-- Owns all 4 Lobby instances, routes join/leave, broadcasts aggregate state.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local ArenaResolver = require(script.Parent.ArenaResolver)
local Lobby = require(script.Parent.Lobby)

local LobbyManager = {}

local lobbies: { [number]: any } = {}
local arenas: { any } = {}

local broadcastQueued = false

local function broadcastAll()
	if broadcastQueued then
		return
	end
	broadcastQueued = true
	task.defer(function()
		broadcastQueued = false
		local snapshot = {}
		for i, lobby in lobbies do
			snapshot[i] = lobby:getPublicState()
		end
		Remotes.LobbyStateUpdate:FireAllClients(snapshot)
	end)
end

function LobbyManager.init()
	arenas = ArenaResolver.resolveAll()
	for i = 1, GameConfig.NumLobbies do
		lobbies[i] = Lobby.new(i, arenas[i], broadcastAll)
	end
	broadcastAll()
end

function LobbyManager.findPlayerLobby(player: Player)
	for _, lobby in lobbies do
		if lobby:isMember(player) then
			return lobby
		end
	end
	return nil
end

function LobbyManager.joinLobby(player: Player, index: number): (boolean, string?)
	if type(index) ~= "number" or index < 1 or index > GameConfig.NumLobbies then
		return false, "Index lobby tidak valid"
	end
	-- Leave current lobby if any
	local existing = LobbyManager.findPlayerLobby(player)
	if existing then
		existing:removePlayer(player)
	end
	local target = lobbies[index]
	if not target then
		return false, "Lobby tidak ditemukan"
	end
	local ok, err = target:addPlayer(player)
	if ok then
		broadcastAll()
	end
	return ok, err
end

function LobbyManager.leaveLobby(player: Player)
	local existing = LobbyManager.findPlayerLobby(player)
	if existing then
		existing:removePlayer(player)
		broadcastAll()
	end
end

function LobbyManager.getSnapshot()
	local snapshot = {}
	for i, lobby in lobbies do
		snapshot[i] = lobby:getPublicState()
	end
	return snapshot
end

function LobbyManager.getLobbyOfPlayer(player: Player)
	return LobbyManager.findPlayerLobby(player)
end

Players.PlayerRemoving:Connect(function(player)
	LobbyManager.leaveLobby(player)
end)

return LobbyManager
