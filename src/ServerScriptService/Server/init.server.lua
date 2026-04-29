--!strict
-- Server bootstrap. Wires together every service and routes remote events.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local DataService = require(script.DataService)
local ShopService = require(script.ShopService)
local LobbyManager = require(script.LobbyManager)
local AbilityService = require(script.AbilityService)
local AntiExploit = require(script.AntiExploit)
local Leaderstats = require(script.Leaderstats)
local ArenaResolver = require(script.ArenaResolver)
local OverheadGui = require(script.OverheadGui)
local LeaderboardBoard = require(script.LeaderboardBoard)
local DashService = require(script.DashService)

-- Build arenas + lobbies
LobbyManager.init()

-- Make sure a neutral world SpawnLocation exists; Roblox will use it as the
-- default spawn for new characters. Players only get teleported to a lobby's
-- pad after they click Join, and get teleported back here when they Leave.
ArenaResolver.ensureWorldSpawn()
LeaderboardBoard.init(workspace:WaitForChild("Arenas"))
OverheadGui.init()

Players.CharacterAutoLoads = true

local function sendFullSync(player: Player)
	Remotes.LobbyStateUpdate:FireClient(player, LobbyManager.getSnapshot())
	ShopService.pushUpdate(player)
end

local function onPlayerAdded(player: Player)
	DataService.load(player)
	Leaderstats.attach(player)
	ShopService.pushUpdate(player)

	-- Roblox auto-spawns the character at the neutral WorldSpawn. If the
	-- player dies while in a match, the match logic teleports them to a team
	-- or jail spawn; otherwise they respawn at WorldSpawn, which is what we
	-- want.
end

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	DataService.unload(player)
end)
game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		DataService.save(p)
	end
end)

-- ========== Remote handlers ==========

Remotes.RequestJoinLobby.OnServerEvent:Connect(function(player, index)
	if not AntiExploit.allow(player, "JoinLobby") then
		return
	end
	if type(index) ~= "number" then
		return
	end
	local ok, err = LobbyManager.joinLobby(player, index)
	if not ok then
		Remotes.AbilityFeedback:FireClient(player, { Type = "Error", Message = err or "Gagal join" })
	end
end)

Remotes.RequestLeaveLobby.OnServerEvent:Connect(function(player)
	if not AntiExploit.allow(player, "LeaveLobby") then
		return
	end
	LobbyManager.leaveLobby(player)
end)

Remotes.RequestBuyAbility.OnServerEvent:Connect(function(player, abilityId)
	if not AntiExploit.allow(player, "BuyAbility", { 4, 2 }) then
		return
	end
	if type(abilityId) ~= "string" then
		return
	end
	local ok, err = ShopService.buy(player, abilityId)
	if not ok then
		Remotes.AbilityFeedback:FireClient(player, { Type = "ShopError", Message = err or "Gagal beli" })
	end
end)

Remotes.RequestEquipAbility.OnServerEvent:Connect(function(player, abilityId)
	if not AntiExploit.allow(player, "EquipAbility") then
		return
	end
	if type(abilityId) ~= "string" then
		return
	end
	local ok, err = ShopService.equip(player, abilityId)
	if not ok then
		Remotes.AbilityFeedback:FireClient(player, { Type = "ShopError", Message = err or "Gagal equip" })
	end
end)

Remotes.RequestUnequipAbility.OnServerEvent:Connect(function(player, abilityId)
	if not AntiExploit.allow(player, "UnequipAbility") then
		return
	end
	if type(abilityId) ~= "string" then
		return
	end
	local ok, err = ShopService.unequip(player, abilityId)
	if not ok then
		Remotes.AbilityFeedback:FireClient(player, { Type = "ShopError", Message = err or "Gagal unequip" })
	end
end)

Remotes.AbilityActivate.OnServerEvent:Connect(function(player, abilityId)
	if not AntiExploit.allow(player, "AbilityActivate", { 6, 2 }) then
		return
	end
	if abilityId == "Fly" then
		local lobby = LobbyManager.getLobbyOfPlayer(player)
		if not lobby or lobby.state ~= "InMatch" then
			Remotes.AbilityFeedback:FireClient(player, { Type = "Error", Message = "Harus dalam match" })
			return
		end
		local ok, err = AbilityService.activateFly(player, lobby.matchId)
		if not ok then
			Remotes.AbilityFeedback:FireClient(player, { Type = "AbilityError", Message = err or "Gagal aktifkan" })
		end
	end
end)

Remotes.RequestDash.OnServerEvent:Connect(function(player)
	if not AntiExploit.allow(player, "Dash", { 3, 1 }) then
		return
	end
	local ok, err = DashService.requestDash(player)
	if not ok then
		Remotes.DashFeedback:FireClient(player, { Type = "DashError", Message = err or "Gagal dash" })
	end
end)

Remotes.ClientReady.OnServerEvent:Connect(function(player)
	sendFullSync(player)
end)

Remotes.GetProfile.OnServerInvoke = function(player)
	return DataService.getProfile(player)
end

Remotes.GetLobbyState.OnServerInvoke = function(_player)
	return LobbyManager.getSnapshot()
end

print("[Bentengan] Server initialized with", require(Shared:WaitForChild("GameConfig")).NumLobbies, "lobbies.")
