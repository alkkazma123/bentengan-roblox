--!strict
-- Per-match tag/touch tracking. One instance is created per active Match.
-- Tracks who is currently inside their safe zone and when they last left it,
-- then resolves player-vs-player tags using the classic bentengan rule:
-- "whoever left their safe zone MORE RECENTLY can tag the other player".

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local TagSystem = {}
TagSystem.__index = TagSystem

export type Arena = {
	RedSafeZone: BasePart,
	BlueSafeZone: BasePart,
	RedJail: BasePart,
	BlueJail: BasePart,
	RedBase: BasePart,
	BlueBase: BasePart,
}

export type PlayerState = {
	Team: string, -- "Red" | "Blue"
	LastLeftSafeAt: number, -- os.clock() when they last left their own safe zone
	InOwnSafe: boolean,
	InJail: boolean,
	LastTagAt: number,
	Alive: boolean,
}

function TagSystem.new(
	arena: Arena,
	onTag: (tagger: Player, victim: Player) -> (),
	onFree: (freer: Player, freed: Player) -> (),
	onBaseTouch: (player: Player, winningTeam: string) -> ()
)
	local self = setmetatable({}, TagSystem)
	self.arena = arena
	self.states = {} :: { [Player]: PlayerState }
	self.onTag = onTag
	self.onFree = onFree
	self.onBaseTouch = onBaseTouch
	self.connections = {} :: { RBXScriptConnection }
	self.active = true
	self:_wireZoneTouches()
	self:_startPollingLoop()
	return self
end

function TagSystem:registerPlayer(player: Player, team: string)
	self.states[player] = {
		Team = team,
		LastLeftSafeAt = 0,
		InOwnSafe = true,
		InJail = false,
		LastTagAt = 0,
		Alive = true,
	}
	self:_attachCharacter(player)
	local charConn
	charConn = player.CharacterAdded:Connect(function()
		if self.active then
			self:_attachCharacter(player)
		else
			charConn:Disconnect()
		end
	end)
	table.insert(self.connections, charConn)
end

function TagSystem:unregisterPlayer(player: Player)
	self.states[player] = nil
end

function TagSystem:setJailed(player: Player, jailed: boolean)
	local st = self.states[player]
	if st then
		st.InJail = jailed
	end
end

function TagSystem:isJailed(player: Player): boolean
	local st = self.states[player]
	return st ~= nil and st.InJail
end

function TagSystem:getState(player: Player): PlayerState?
	return self.states[player]
end

function TagSystem:destroy()
	self.active = false
	for _, c in self.connections do
		c:Disconnect()
	end
	self.connections = {}
	self.states = {}
end

-- ========== internal ==========

function TagSystem:_ownSafeZone(team: string): BasePart
	return if team == "Red" then self.arena.RedSafeZone else self.arena.BlueSafeZone
end

function TagSystem:_enemyBase(team: string): BasePart
	return if team == "Red" then self.arena.BlueBase else self.arena.RedBase
end

function TagSystem:_enemyJail(team: string): BasePart
	return if team == "Red" then self.arena.BlueJail else self.arena.RedJail
end

function TagSystem:_attachCharacter(player: Player)
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart", 5)
	if not hrp or not hrp:IsA("BasePart") then
		return
	end
	local conn
	conn = hrp.Touched:Connect(function(hit)
		if not self.active then
			return
		end
		self:_onTouch(player, hit)
	end)
	table.insert(self.connections, conn)
end

function TagSystem:_wireZoneTouches()
	-- Base touches award win
	local function wireBase(basePart: BasePart, owningTeam: string)
		local conn = basePart.Touched:Connect(function(hit)
			if not self.active then
				return
			end
			local char = hit:FindFirstAncestorOfClass("Model")
			if not char then
				return
			end
			local player = Players:GetPlayerFromCharacter(char)
			if not player then
				return
			end
			local st = self.states[player]
			if not st or st.InJail then
				return
			end
			-- An enemy touching this base wins for their team
			if st.Team ~= owningTeam then
				self.onBaseTouch(player, st.Team)
			end
		end)
		table.insert(self.connections, conn)
	end
	wireBase(self.arena.RedBase, "Red")
	wireBase(self.arena.BlueBase, "Blue")
end

function TagSystem:_startPollingLoop()
	-- Poll to maintain InOwnSafe / LastLeftSafeAt via magnitude check; simpler
	-- than Region3/OverlapParams shenanigans for small arenas.
	local conn = RunService.Heartbeat:Connect(function()
		if not self.active then
			return
		end
		local now = os.clock()
		for player, state in self.states do
			if state.InJail then
				continue
			end
			local char = player.Character
			if not char then
				continue
			end
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				continue
			end
			local safeZone = self:_ownSafeZone(state.Team)
			local halfSize = safeZone.Size * 0.5
			local localPos = safeZone.CFrame:PointToObjectSpace(hrp.Position)
			local inside = math.abs(localPos.X) <= halfSize.X
				and math.abs(localPos.Z) <= halfSize.Z
				and math.abs(localPos.Y) <= halfSize.Y + 8
			if inside and not state.InOwnSafe then
				state.InOwnSafe = true
			elseif not inside and state.InOwnSafe then
				state.InOwnSafe = false
				state.LastLeftSafeAt = now
			end
		end
	end)
	table.insert(self.connections, conn)
end

function TagSystem:_onTouch(toucher: Player, hit: BasePart)
	local st = self.states[toucher]
	if not st or st.InJail or not st.Alive then
		return
	end
	local hitChar = hit:FindFirstAncestorOfClass("Model")
	if not hitChar then
		return
	end
	local other = Players:GetPlayerFromCharacter(hitChar)
	if not other or other == toucher then
		return
	end
	local otherState = self.states[other]
	if not otherState or not otherState.Alive then
		return
	end

	-- Cooldown
	local now = os.clock()
	if now - st.LastTagAt < GameConfig.TagCooldownSeconds then
		return
	end

	-- Same team: if the other is jailed in enemy jail, free them on touch
	if otherState.Team == st.Team then
		if otherState.InJail then
			-- Must be near teammate's (enemy) jail? Allow any teammate touch
			st.LastTagAt = now
			self.onFree(toucher, other)
		end
		return
	end

	-- Enemy team: determine who can tag whom.
	-- Rule: whoever left their own safe zone MORE RECENTLY wins.
	-- If either is currently inside their own safe zone, they cannot be tagged,
	-- but can still tag enemies outside safe (they act like "fresh").
	if otherState.InJail then
		return
	end

	local toucherSafeTime = st.InOwnSafe and now or st.LastLeftSafeAt
	local otherSafeTime = otherState.InOwnSafe and now or otherState.LastLeftSafeAt

	-- Tie-break: if equal, no-op
	if math.abs(toucherSafeTime - otherSafeTime) < 0.05 then
		return
	end

	if toucherSafeTime > otherSafeTime then
		-- toucher tags other
		st.LastTagAt = now
		otherState.LastTagAt = now
		self.onTag(toucher, other)
	else
		-- other tags toucher (reverse tag)
		st.LastTagAt = now
		otherState.LastTagAt = now
		self.onTag(other, toucher)
	end

	-- Broadcast tag visual
	Remotes.TagEvent:FireAllClients({
		Tagger = toucher.UserId,
		Victim = other.UserId,
	})
end

return TagSystem
