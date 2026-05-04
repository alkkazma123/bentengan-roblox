--[[
	Remotes
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

Remotes.CheckpointReached = getOrCreate("RemoteEvent", "CheckpointReached")
Remotes.SummitReached = getOrCreate("RemoteEvent", "SummitReached")
Remotes.PlayerDied = getOrCreate("RemoteEvent", "PlayerDied")
Remotes.UpdateOverhead = getOrCreate("RemoteEvent", "UpdateOverhead")
Remotes.UpdateCoins = getOrCreate("RemoteEvent", "UpdateCoins")
Remotes.BuyItem = getOrCreate("RemoteFunction", "BuyItem")
Remotes.EquipItem = getOrCreate("RemoteEvent", "EquipItem")
Remotes.UnequipItem = getOrCreate("RemoteEvent", "UnequipItem")
Remotes.GetInventory = getOrCreate("RemoteFunction", "GetInventory")
Remotes.UpdateSetting = getOrCreate("RemoteEvent", "UpdateSetting")
Remotes.PlayEmote = getOrCreate("RemoteEvent", "PlayEmote")

return Remotes
