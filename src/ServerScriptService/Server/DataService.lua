--[[
	DataService - Player data persistence
	Saves: summits, coins, inventory, equipped, settings, lastCheckpoint
]]

local DataStoreService = game:GetService("DataStoreService")

local DataService = {}

local playerData = {}
local dataStore = nil

-- DataStore works in published game always.
-- In Studio: enable "Enable Studio Access to API Services" in Game Settings > Security.
local ok, store = pcall(function()
	return DataStoreService:GetDataStore("SummitKit_v2")
end)
if ok and store then
	dataStore = store
	print("[DataService] DataStore connected.")
else
	warn("[DataService] DataStore not available (Studio without API access). Data will NOT persist!")
end

local DEFAULT = {
	summits = 0,
	coins = 0,
	inventory = {},
	equipped = { trail = "", aura = "" },
	settings = { hidePlayers = false, hideAura = false, hideTrail = false },
	lastCheckpoint = 0,
}

local function deepCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

function DataService.Init() end

function DataService.LoadPlayer(player)
	local data = nil

	if dataStore then
		local loadOk, result = pcall(function()
			return dataStore:GetAsync("player_" .. player.UserId)
		end)
		if loadOk and result then
			data = result
			print("[DataService] Loaded data for " .. player.Name)
		else
			print("[DataService] No saved data for " .. player.Name .. ", using defaults")
		end
	end

	if not data then
		data = deepCopy(DEFAULT)
	end

	-- Fill missing keys
	for k, v in pairs(DEFAULT) do
		if data[k] == nil then
			if type(v) == "table" then
				data[k] = deepCopy(v)
			else
				data[k] = v
			end
		end
	end

	playerData[player.UserId] = data

	-- Leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local summitsVal = Instance.new("IntValue")
	summitsVal.Name = "Summits"
	summitsVal.Value = data.summits
	summitsVal.Parent = leaderstats

	local coinsVal = Instance.new("IntValue")
	coinsVal.Name = "Coins"
	coinsVal.Value = data.coins
	coinsVal.Parent = leaderstats
end

function DataService.SavePlayer(player)
	local data = playerData[player.UserId]
	if not data then
		return
	end
	if dataStore then
		local saveOk, saveErr = pcall(function()
			dataStore:SetAsync("player_" .. player.UserId, data)
		end)
		if saveOk then
			print("[DataService] Saved data for " .. player.Name)
		else
			warn("[DataService] Failed to save data for " .. player.Name .. ": " .. tostring(saveErr))
		end
	end
	playerData[player.UserId] = nil
end

function DataService.GetData(player)
	return playerData[player.UserId]
end

function DataService.GetCoins(player)
	local data = playerData[player.UserId]
	return data and data.coins or 0
end

function DataService.GetLastCheckpoint(player)
	local data = playerData[player.UserId]
	return data and data.lastCheckpoint or 0
end

function DataService.SetLastCheckpoint(player, index)
	local data = playerData[player.UserId]
	if data then
		data.lastCheckpoint = index
	end
end

function DataService.AddSummits(player, amount)
	local data = playerData[player.UserId]
	if not data then
		return
	end
	data.summits = data.summits + amount
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local v = ls:FindFirstChild("Summits")
		if v then
			v.Value = data.summits
		end
	end
end

function DataService.AddCoins(player, amount)
	local data = playerData[player.UserId]
	if not data then
		return
	end
	data.coins = data.coins + amount
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local v = ls:FindFirstChild("Coins")
		if v then
			v.Value = data.coins
		end
	end
end

function DataService.SpendCoins(player, amount)
	local data = playerData[player.UserId]
	if not data then
		return false
	end
	if data.coins < amount then
		return false
	end
	data.coins = data.coins - amount
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local v = ls:FindFirstChild("Coins")
		if v then
			v.Value = data.coins
		end
	end
	return true
end

function DataService.HasItem(player, itemId)
	local data = playerData[player.UserId]
	if not data then
		return false
	end
	for _, id in ipairs(data.inventory) do
		if id == itemId then
			return true
		end
	end
	return false
end

function DataService.AddToInventory(player, itemId)
	local data = playerData[player.UserId]
	if not data then
		return
	end
	table.insert(data.inventory, itemId)
end

function DataService.SetEquipped(player, slot, itemId)
	local data = playerData[player.UserId]
	if not data then
		return
	end
	data.equipped[slot] = itemId
end

function DataService.GetEquipped(player)
	local data = playerData[player.UserId]
	if not data then
		return { trail = "", aura = "" }
	end
	return data.equipped
end

return DataService
