--!strict
-- Player profile data: wins, coins, kills (tags), deaths, owned + equipped abilities.
-- Uses DataStoreService in live games; falls back to in-memory in Studio (no HTTP / auto-save issues).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local DataService = {}

export type Profile = {
	Wins: number,
	Coins: number,
	Kills: number,
	Deaths: number,
	OwnedAbilities: { [string]: boolean },
	EquippedAbilities: { string },
}

local PROFILE_STORE_NAME = "BentenganProfile_v1"
local store: DataStore? = nil

local ok, storeOrErr = pcall(function()
	return DataStoreService:GetDataStore(PROFILE_STORE_NAME)
end)
if ok then
	store = storeOrErr
else
	warn("[DataService] DataStore unavailable:", storeOrErr)
end

local profiles: { [Player]: Profile } = {}

local function defaultProfile(): Profile
	return {
		Wins = 0,
		Coins = GameConfig.StartingCoins,
		Kills = 0,
		Deaths = 0,
		OwnedAbilities = {},
		EquippedAbilities = {},
	}
end

local function key(player: Player): string
	return "p_" .. tostring(player.UserId)
end

function DataService.getProfile(player: Player): Profile
	local p = profiles[player]
	if p then
		return p
	end
	return defaultProfile()
end

function DataService.load(player: Player)
	if profiles[player] then
		return
	end
	local data: Profile? = nil
	if store then
		local s, r = pcall(function()
			return store:GetAsync(key(player))
		end)
		if s and type(r) == "table" then
			data = r
		elseif not s then
			warn("[DataService] GetAsync failed:", r)
		end
	end
	local profile = data or defaultProfile()
	-- Fill missing fields (forward-compat)
	local def = defaultProfile()
	for k, v in def do
		if profile[k] == nil then
			profile[k] = v
		end
	end
	profiles[player] = profile
	return profile
end

function DataService.save(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	if not store then
		return
	end
	if RunService:IsStudio() then
		return -- avoid spamming datastores during tests
	end
	local ok2, err = pcall(function()
		store:SetAsync(key(player), profile)
	end)
	if not ok2 then
		warn("[DataService] SetAsync failed for", player.Name, err)
	end
end

function DataService.unload(player: Player)
	DataService.save(player)
	profiles[player] = nil
end

function DataService.addCoins(player: Player, amount: number)
	local p = profiles[player]
	if not p then
		return
	end
	p.Coins = math.max(0, p.Coins + amount)
end

function DataService.spendCoins(player: Player, amount: number): boolean
	local p = profiles[player]
	if not p then
		return false
	end
	if p.Coins < amount then
		return false
	end
	p.Coins -= amount
	return true
end

function DataService.recordWin(player: Player)
	local p = profiles[player]
	if p then
		p.Wins += 1
	end
end

function DataService.recordKill(player: Player)
	local p = profiles[player]
	if p then
		p.Kills += 1
	end
end

function DataService.recordDeath(player: Player)
	local p = profiles[player]
	if p then
		p.Deaths += 1
	end
end

function DataService.grantAbility(player: Player, abilityId: string): boolean
	local p = profiles[player]
	if not p then
		return false
	end
	if p.OwnedAbilities[abilityId] then
		return false
	end
	p.OwnedAbilities[abilityId] = true
	return true
end

function DataService.isOwned(player: Player, abilityId: string): boolean
	local p = profiles[player]
	if not p then
		return false
	end
	return p.OwnedAbilities[abilityId] == true
end

function DataService.setEquipped(player: Player, equipped: { string })
	local p = profiles[player]
	if p then
		p.EquippedAbilities = equipped
	end
end

-- Periodic autosave every 2 minutes
task.spawn(function()
	while true do
		task.wait(120)
		for _, player in ipairs(Players:GetPlayers()) do
			DataService.save(player)
		end
	end
end)

return DataService
