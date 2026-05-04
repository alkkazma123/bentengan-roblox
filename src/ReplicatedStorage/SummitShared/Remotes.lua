--[[
	Remotes (Summit)
	Creates all RemoteEvents/RemoteFunctions used by the summit kit.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("SummitRemotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "SummitRemotes"
	folder.Parent = ReplicatedStorage
end

local function getOrCreate(className, name)
	local obj = folder:FindFirstChild(name)
	if not obj then
		obj = Instance.new(className)
		obj.Name = name
		obj.Parent = folder
	end
	return obj
end

local Remotes = {}

-- Checkpoint
Remotes.CheckpointReached = getOrCreate("RemoteEvent", "CheckpointReached")

-- Summit
Remotes.SummitReached = getOrCreate("RemoteEvent", "SummitReached")

-- Kill / respawn
Remotes.PlayerDied = getOrCreate("RemoteEvent", "PlayerDied")

-- Overhead update
Remotes.UpdateOverhead = getOrCreate("RemoteEvent", "UpdateOverhead")

-- Coins
Remotes.UpdateCoins = getOrCreate("RemoteEvent", "UpdateCoins")

-- Shop
Remotes.BuyItem = getOrCreate("RemoteFunction", "BuyItem")
Remotes.EquipItem = getOrCreate("RemoteEvent", "EquipItem")
Remotes.UnequipItem = getOrCreate("RemoteEvent", "UnequipItem")
Remotes.GetInventory = getOrCreate("RemoteFunction", "GetInventory")

-- Settings
Remotes.UpdateSetting = getOrCreate("RemoteEvent", "UpdateSetting")

-- Emote
Remotes.PlayEmote = getOrCreate("RemoteEvent", "PlayEmote")

return Remotes
