--!strict
-- A single lobby (1 of 4 per server). Handles joined players, countdown,
-- team assignment, match lifecycle, and win conditions.

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Utils = require(Shared:WaitForChild("Utils"))

local TagSystem = require(script.Parent.TagSystem)
local AbilityService = require(script.Parent.AbilityService)
local DataService = require(script.Parent.DataService)

local Lobby = {}
Lobby.__index = Lobby

export type LobbyState = "Idle" | "Countdown" | "InMatch" | "Ending"

local matchIdCounter = 0

function Lobby.new(index: number, arena: any, onStateChanged: () -> ())
	local self = setmetatable({}, Lobby)
	self.index = index
	self.arena = arena
	self.onStateChanged = onStateChanged
	self.state = "Idle" :: LobbyState
	self.members = {} :: { [Player]: boolean }
	self.teams = {} :: { [Player]: string } -- "Red" | "Blue"
	self.countdownTask = nil :: thread?
	self.countdownEndsAt = 0
	self.matchEndsAt = 0
	self.tagSystem = nil :: any?
	self.matchId = 0
	self.ended = false
	return self
end

function Lobby:getMemberList(): { Player }
	local list = {}
	for p in self.members do
		table.insert(list, p)
	end
	return list
end

function Lobby:count(): number
	local n = 0
	for _ in self.members do
		n += 1
	end
	return n
end

function Lobby:isMember(player: Player): boolean
	return self.members[player] == true
end

function Lobby:broadcastState()
	self.onStateChanged()
end

function Lobby:teleportToLobbyPad(player: Player)
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if hrp and hrp:IsA("BasePart") then
		hrp.CFrame = self.arena.LobbySpawn.CFrame + Vector3.new(math.random(-6, 6), 5, math.random(-6, 6))
	end
end

function Lobby:teleportToWorldSpawn(player: Player)
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not (hrp and hrp:IsA("BasePart")) then
		return
	end
	local arenasFolder = workspace:FindFirstChild("Arenas")
	local worldSpawnModel = arenasFolder and arenasFolder:FindFirstChild("WorldSpawn")
	local spawnLoc = worldSpawnModel and worldSpawnModel:FindFirstChild("SpawnLocation")
	if spawnLoc and spawnLoc:IsA("BasePart") then
		hrp.CFrame = spawnLoc.CFrame + Vector3.new(math.random(-3, 3), 4, math.random(-3, 3))
	end
end

function Lobby:addPlayer(player: Player): (boolean, string?)
	if self.members[player] then
		return false, "Sudah di lobby ini"
	end
	if self:count() >= GameConfig.MaxPlayersPerLobby then
		return false, "Lobby penuh"
	end
	if self.state == "InMatch" or self.state == "Ending" then
		return false, "Match sudah berjalan"
	end
	self.members[player] = true
	self:teleportToLobbyPad(player)
	self:broadcastState()
	self:_maybeStartCountdown()
	return true
end

function Lobby:removePlayer(player: Player)
	if not self.members[player] then
		return
	end
	self.members[player] = nil
	self.teams[player] = nil
	if self.tagSystem then
		self.tagSystem:unregisterPlayer(player)
	end
	if self.state == "Countdown" and self:count() < GameConfig.MinPlayersPerLobby then
		self:_cancelCountdown()
	end
	if self.state == "InMatch" then
		self:_checkWinCondition()
	end
	self:teleportToWorldSpawn(player)
	self:broadcastState()
end

function Lobby:_maybeStartCountdown()
	if self.state ~= "Idle" then
		return
	end
	if self:count() < GameConfig.MinPlayersPerLobby then
		return
	end
	self.state = "Countdown"
	self.countdownEndsAt = os.clock() + GameConfig.CountdownSeconds
	self:broadcastState()
	self.countdownTask = task.spawn(function()
		local seconds = GameConfig.CountdownSeconds
		while seconds > 0 do
			for p in self.members do
				Remotes.MatchCountdown:FireClient(p, seconds)
			end
			task.wait(1)
			seconds -= 1
			if self:count() < GameConfig.MinPlayersPerLobby then
				self:_cancelCountdown()
				return
			end
		end
		if self.state == "Countdown" then
			self:_startMatch()
		end
	end)
end

function Lobby:_cancelCountdown()
	if self.countdownTask then
		task.cancel(self.countdownTask)
		self.countdownTask = nil
	end
	if self.state == "Countdown" then
		self.state = "Idle"
		for p in self.members do
			Remotes.MatchCountdown:FireClient(p, -1) -- -1 = cancelled
		end
		self:broadcastState()
	end
end

function Lobby:_assignTeams()
	-- Shuffle members and alternate red/blue. Set attribute so every client can
	-- determine team (used by ESP ability).
	self.teams = {}
	local list = Utils.shuffle(self:getMemberList())
	for i, p in list do
		local team = if i % 2 == 0 then "Blue" else "Red"
		self.teams[p] = team
		p:SetAttribute("BentenganTeam", team)
	end
end

function Lobby:_clearTeams()
	for p in self.teams do
		p:SetAttribute("BentenganTeam", nil)
	end
	self.teams = {}
end

function Lobby:_teleportToSpawn(player: Player)
	local team = self.teams[player]
	local spawnPart = if team == "Red" then self.arena.RedSpawn else self.arena.BlueSpawn
	local char = player.Character
	if not char then
		player:LoadCharacter()
		task.wait(0.1)
		char = player.Character
	end
	if not char then
		return
	end
	local hrp = char:WaitForChild("HumanoidRootPart", 3)
	if hrp and hrp:IsA("BasePart") then
		hrp.CFrame = spawnPart.CFrame + Vector3.new(math.random(-3, 3), 4, math.random(-3, 3))
	end
end

function Lobby:_setJailLock(player: Player, locked: boolean)
	local char = player.Character
	if not char then
		return
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if locked then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		humanoid.AutoRotate = false
	else
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.JumpHeight = 7.2
		humanoid.AutoRotate = true
	end
end

function Lobby:_teleportToJail(player: Player)
	local team = self.teams[player]
	-- Jailed in the ENEMY jail
	local jail = if team == "Red" then self.arena.BlueJail else self.arena.RedJail
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		hrp.CFrame = jail.CFrame + Vector3.new(math.random(-4, 4), 3, math.random(-4, 4))
	end
	self:_setJailLock(player, true)
end

function Lobby:_startMatch()
	matchIdCounter += 1
	self.matchId = matchIdCounter
	self.state = "InMatch"
	self.ended = false
	self.matchEndsAt = os.clock() + GameConfig.MatchDurationSeconds
	self:_assignTeams()

	for p, team in self.teams do
		Remotes.TeamAssigned:FireClient(p, {
			Team = team,
			MatchId = self.matchId,
			EndsAt = self.matchEndsAt,
			LobbyIndex = self.index,
		})
	end

	self.tagSystem = TagSystem.new(self.arena, function(tagger, victim)
		self:_onTag(tagger, victim)
	end, function(freer, freed)
		self:_onFree(freer, freed)
	end, function(player, winningTeam)
		self:_onBaseTouch(player, winningTeam)
	end)

	for p in self.teams do
		p:LoadCharacter()
	end
	task.wait(0.5)
	for p, team in self.teams do
		local _ = team
		self:_teleportToSpawn(p)
		self.tagSystem:registerPlayer(p, team)
		AbilityService.onMatchStart(p, self.matchId)
		Remotes.MatchStart:FireClient(p, {
			MatchId = self.matchId,
			EndsAt = self.matchEndsAt,
			LobbyIndex = self.index,
			Team = team,
		})
	end

	self:broadcastState()

	-- Match timer watchdog
	task.spawn(function()
		while self.state == "InMatch" and not self.ended do
			task.wait(1)
			if os.clock() >= self.matchEndsAt then
				self:_endByTimeout()
				return
			end
		end
	end)
end

function Lobby:_countAliveFree(team: string): number
	local n = 0
	for p, t in self.teams do
		if t == team and not self.tagSystem:isJailed(p) and p:IsDescendantOf(Players) then
			n += 1
		end
	end
	return n
end

function Lobby:_onTag(tagger: Player, victim: Player)
	if self.ended then
		return
	end
	DataService.recordKill(tagger)
	DataService.recordDeath(victim)
	DataService.addCoins(tagger, GameConfig.Rewards.PerTagCoins)
	Remotes.CoinsUpdate:FireClient(tagger, DataService.getProfile(tagger).Coins)
	self.tagSystem:setJailed(victim, true)
	self:_teleportToJail(victim)
	Remotes.JailUpdate:FireAllClients({
		LobbyIndex = self.index,
		Player = victim.UserId,
		Jailed = true,
	})
	self:_checkWinCondition()
end

function Lobby:_onFree(_freer: Player, freed: Player)
	if self.ended then
		return
	end
	self.tagSystem:setJailed(freed, false)
	local team = self.teams[freed]
	local spawnPart = if team == "Red" then self.arena.RedSpawn else self.arena.BlueSpawn
	local char = freed.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 4, 0)
		end
	end
	self:_setJailLock(freed, false)
	Remotes.JailUpdate:FireAllClients({
		LobbyIndex = self.index,
		Player = freed.UserId,
		Jailed = false,
	})
end

function Lobby:_onBaseTouch(player: Player, winningTeam: string)
	if self.ended then
		return
	end
	DataService.addCoins(player, GameConfig.Rewards.BaseTouchCoins)
	self:_endMatch(winningTeam, "BaseTouch")
end

function Lobby:_checkWinCondition()
	if self.ended or not self.tagSystem then
		return
	end
	local redAlive = self:_countAliveFree("Red")
	local blueAlive = self:_countAliveFree("Blue")
	if redAlive == 0 and blueAlive == 0 then
		self:_endMatch("Draw", "AllCaptured")
	elseif redAlive == 0 then
		self:_endMatch("Blue", "AllCaptured")
	elseif blueAlive == 0 then
		self:_endMatch("Red", "AllCaptured")
	end
end

function Lobby:_endByTimeout()
	if self.ended then
		return
	end
	local redAlive = self:_countAliveFree("Red")
	local blueAlive = self:_countAliveFree("Blue")
	local winner = if redAlive > blueAlive then "Red" elseif blueAlive > redAlive then "Blue" else "Draw"
	self:_endMatch(winner, "Timeout")
end

function Lobby:_endMatch(winner: string, reason: string)
	if self.ended then
		return
	end
	self.ended = true
	self.state = "Ending"

	for p, team in self.teams do
		local won = (team == winner)
		if won then
			DataService.recordWin(p)
			DataService.addCoins(p, GameConfig.Rewards.WinCoins)
		else
			DataService.addCoins(p, GameConfig.Rewards.LoseCoins)
		end
		AbilityService.onMatchEnd(p)
		Remotes.CoinsUpdate:FireClient(p, DataService.getProfile(p).Coins)
		Remotes.MatchEnd:FireClient(p, {
			Winner = winner,
			Reason = reason,
			MatchId = self.matchId,
		})
	end

	if self.tagSystem then
		self.tagSystem:destroy()
		self.tagSystem = nil
	end

	-- Return players to lobby pad after a short delay
	task.delay(5, function()
		for p in self.members do
			p:LoadCharacter()
		end
		task.wait(1)
		for p in self.members do
			self:teleportToLobbyPad(p)
		end
		self:_clearTeams()
		self.state = "Idle"
		self:broadcastState()
		self:_maybeStartCountdown()
	end)

	self:broadcastState()
end

function Lobby:getPublicState()
	return {
		Index = self.index,
		State = self.state,
		Count = self:count(),
		Min = GameConfig.MinPlayersPerLobby,
		Max = GameConfig.MaxPlayersPerLobby,
		CountdownEndsAt = self.countdownEndsAt,
		MatchEndsAt = self.matchEndsAt,
	}
end

return Lobby
