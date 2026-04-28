--!strict
-- Mirrors profile data into the player's leaderstats so it shows up in the
-- default Roblox leaderboard (Wins / Coins / Kills / Deaths).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent.DataService)

local Leaderstats = {}

local function ensureStats(player: Player)
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "leaderstats"
		folder.Parent = player
	end
	local function stat(name: string): IntValue
		local v = folder:FindFirstChild(name)
		if not v then
			v = Instance.new("IntValue")
			v.Name = name
			v.Parent = folder
		end
		return v :: IntValue
	end
	return {
		Wins = stat("Wins"),
		Coins = stat("Coins"),
		Tags = stat("Tags"),
		Deaths = stat("Deaths"),
	}
end

function Leaderstats.attach(player: Player)
	local stats = ensureStats(player)
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not player:IsDescendantOf(Players) then
			conn:Disconnect()
			return
		end
		local profile = DataService.getProfile(player)
		stats.Wins.Value = profile.Wins
		stats.Coins.Value = profile.Coins
		stats.Tags.Value = profile.Kills
		stats.Deaths.Value = profile.Deaths
	end)
end

return Leaderstats
