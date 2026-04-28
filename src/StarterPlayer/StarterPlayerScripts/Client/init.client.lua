--!strict
-- Client bootstrap. Orchestrates: Loading -> Rules -> Lobby UI, and routes all
-- remote events to the appropriate UI module.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local LoadingUI = require(script:WaitForChild("LoadingUI"))
local RulesUI = require(script:WaitForChild("RulesUI"))
local LobbyUI = require(script:WaitForChild("LobbyUI"))
local ShopUI = require(script:WaitForChild("ShopUI"))
local HUD = require(script:WaitForChild("HUD"))
local AbilityController = require(script:WaitForChild("AbilityController"))

local player = Players.LocalPlayer

-- Disable default core topbar stuff where it gets in the way
pcall(function()
	StarterGui:SetCore("ResetButtonCallback", true)
end)

local gui = Instance.new("ScreenGui")
gui.Name = "BentenganUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

-- Create UI controllers (they start hidden where needed)
local lobbyUI = LobbyUI.new(gui)
local shopUI = ShopUI.new(gui)
local hud = HUD.new(gui)
local abilityController = AbilityController.new()

lobbyUI:setVisible(false)
hud:setVisible(false)

-- Loading flow: wait for first LobbyStateUpdate from server as a real sync step.
local firstStateReceived = false
local conn
conn = Remotes.LobbyStateUpdate.OnClientEvent:Connect(function()
	firstStateReceived = true
	if conn then
		conn:Disconnect()
		conn = nil
	end
end)

-- Kick off client-ready handshake
Remotes.ClientReady:FireServer()

LoadingUI.run(gui, {
	function()
		local start = os.clock()
		while not firstStateReceived and os.clock() - start < 10 do
			task.wait(0.1)
		end
	end,
})

-- Show rules overlay, then lobby UI.
RulesUI.show(gui)
lobbyUI:setVisible(true)

-- Hook buttons on the top bar
lobbyUI.shopBtn.MouseButton1Click:Connect(function()
	shopUI:setVisible(not shopUI:isVisible())
end)
lobbyUI.rulesBtn.MouseButton1Click:Connect(function()
	RulesUI.show(gui)
end)

-- ========== Routing remotes ==========

local myLobbyIndex: number? = nil
local latestSnapshot: any = nil

local function renderLobbies()
	if latestSnapshot then
		lobbyUI:updateLobbies(latestSnapshot, myLobbyIndex)
	end
end

Remotes.LobbyStateUpdate.OnClientEvent:Connect(function(snapshot)
	latestSnapshot = snapshot
	-- We don't get told directly which lobby we're in; infer from membership
	-- via GetLobbyState-less approach: the server will also fire MatchCountdown/
	-- TeamAssigned which we use to lock state. Also, join success means the
	-- server echoes state where our lobby is updated; detect via a lightweight
	-- check: we've set myLobbyIndex locally in join success path.
	renderLobbies()
end)

-- Continuously tick lobby UI so countdown/time displays refresh
task.spawn(function()
	while true do
		task.wait(1)
		renderLobbies()
	end
end)

Remotes.CoinsUpdate.OnClientEvent:Connect(function(amount: number)
	lobbyUI:updateCoins(amount)
	shopUI:updateCoins(amount)
	hud:updateCoins(amount)
end)

Remotes.InventoryUpdate.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	shopUI:updateInventory(payload.Owned or {}, payload.Equipped or {})
	hud:updateEquipped(payload.Equipped or {})
	abilityController:setEquipped(payload.Equipped or {})
end)

Remotes.MatchCountdown.OnClientEvent:Connect(function(seconds: number)
	if seconds < 0 then
		hud:showToast("Countdown dibatalkan", Color3.fromRGB(240, 190, 90))
	elseif seconds <= 5 then
		hud:showToast("Mulai dalam " .. seconds, Color3.fromRGB(250, 205, 100))
	end
end)

Remotes.TeamAssigned.OnClientEvent:Connect(function(info)
	myLobbyIndex = info.LobbyIndex
	abilityController:setTeam(info.Team)
end)

Remotes.MatchStart.OnClientEvent:Connect(function(info)
	myLobbyIndex = info.LobbyIndex
	abilityController:setTeam(info.Team)
	lobbyUI:setVisible(false)
	shopUI:setVisible(false)
	hud:onMatchStart(info)
end)

Remotes.MatchEnd.OnClientEvent:Connect(function(info)
	hud:onMatchEnd(info)
	abilityController:clearTeam()
	-- Return to lobby UI after a short delay
	task.delay(5, function()
		hud:setVisible(false)
		lobbyUI:setVisible(true)
	end)
end)

Remotes.JailUpdate.OnClientEvent:Connect(function(payload)
	if payload.Player == player.UserId then
		hud:setJailed(payload.Jailed)
	end
end)

Remotes.TagEvent.OnClientEvent:Connect(function(payload)
	if payload.Tagger == player.UserId then
		hud:showToast("Kamu menangkap musuh (+10 ★)", Color3.fromRGB(120, 255, 170))
	elseif payload.Victim == player.UserId then
		hud:showToast("Kamu tertangkap!", Color3.fromRGB(255, 120, 120))
	end
end)

Remotes.AbilityFeedback.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" then
		return
	end
	if info.Type == "FlyStart" then
		hud:onFlyStart(info.EndsAt)
		abilityController:onFlyStart(info.EndsAt, info.Speed or 60)
		hud:showToast("Fly aktif!", Color3.fromRGB(120, 170, 255))
	elseif info.Type == "FlyEnd" then
		hud:onFlyEnd(info.Cooldown or 30)
		abilityController:onFlyEnd()
		hud:showToast("Fly berakhir", Color3.fromRGB(150, 158, 172))
	elseif info.Type == "ShopError" or info.Type == "Error" or info.Type == "AbilityError" then
		shopUI:showMessage(info.Message or "Error")
		hud:showToast(info.Message or "Error", Color3.fromRGB(255, 120, 120))
	end
end)

-- Optimistically update myLobbyIndex when the user clicks Join/Leave.
-- TeamAssigned / MatchStart events overwrite this with authoritative values.
lobbyUI.onJoinClicked = function(index: number)
	myLobbyIndex = index
	renderLobbies()
end
lobbyUI.onLeaveClicked = function()
	myLobbyIndex = nil
	renderLobbies()
end

print("[Bentengan] Client initialized.")
