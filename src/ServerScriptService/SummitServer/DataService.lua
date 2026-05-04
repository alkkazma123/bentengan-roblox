--[[
	DataService
	Handles player data persistence (summits, coins, inventory, settings).
]]

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local DataService = {}

local DATA_KEY = "SummitData_v1"
local playerData = {}

local dataStore = nil
if not RunService:IsStudio() then
	dataStore = DataStoreService:GetDataStore("SummitGameStore")
end

local DEFAULT_DATA = {
	summits = 0,
	coins = 0,
	inventory = {},
	equipped = { trail = nil, aura = nil },
	settings = { hidePlayers = false, hideAura = false, hideTrail = false },
}

function DataService.Init() end

function DataService.LoadPlayer(player)
	local data = nil
	if dataStore then
		local success, result = pcall(function()
			return dataStore:GetAsync(DATA_KEY .. "_" .. player.UserId)
		end)
		if success and result then
			data = result
		end
	end

	if not data then
		data = {}
		for k, v in pairs(DEFAULT_DATA) do
			if type(v) == "table" then
				data[k] = {}
				for k2, v2 in pairs(v) do
					data[k][k2] = v2
				end
			else
				data[k] = v
			end
		end
	end

	-- Ensure all fields exist
	for k, v in pairs(DEFAULT_DATA) do
		if data[k] == nil then
			if type(v) == "table" then
				data[k] = {}
				for k2, v2 in pairs(v) do
					data[k][k2] = v2
				end
			else
				data[k] = v
			end
		end
	end

	playerData[player.UserId] = data

	-- Setup leaderstats
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
		pcall(function()
			dataStore:SetAsync(DATA_KEY .. "_" .. player.UserId, data)
		end)
	end

	playerData[player.UserId] = nil
end

function DataService.GetData(player)
	return playerData[player.UserId]
end

function DataService.AddSummits(player, amount)
	local data = playerData[player.UserId]
	if not data then
		return
	end
	data.summits = data.summits + amount
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local val = leaderstats:FindFirstChild("Summits")
		if val then
			val.Value = data.summits
		end
	end
end

function DataService.AddCoins(player, amount)
	local data = playerData[player.UserId]
	if not data then
		return
	end
	data.coins = data.coins + amount
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local val = leaderstats:FindFirstChild("Coins")
		if val then
			val.Value = data.coins
		end
	end
end

function DataService.GetCoins(player)
	local data = playerData[player.UserId]
	if not data then
		return 0
	end
	return data.coins
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
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local val = leaderstats:FindFirstChild("Coins")
		if val then
			val.Value = data.coins
		end
	end
	return true
end

function DataService.AddToInventory(player, itemId)
	local data = playerData[player.UserId]
	if not data then
		return
	end
	table.insert(data.inventory, itemId)
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
		return {}
	end
	return data.equipped
end

function DataService.SetSetting(player, key, value)
	local data = playerData[player.UserId]
	if not data then
		return
	end
	if data.settings[key] ~= nil then
		data.settings[key] = value
	end
end

function DataService.GetSettings(player)
	local data = playerData[player.UserId]
	if not data then
		return DEFAULT_DATA.settings
	end
	return data.settings
end

return DataService
