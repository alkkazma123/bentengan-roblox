--[[
	ShopService
	Handles buying, equipping, and unequipping shop items (trails and auras).
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(Shared:WaitForChild("ShopConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local ShopService = {}

local function findItem(itemId)
	for _, category in ipairs(ShopConfig.Categories) do
		for _, item in ipairs(category.items) do
			if item.id == itemId then
				return item, category.name
			end
		end
	end
	return nil, nil
end

local function applyTrail(player, item)
	if not player.Character then
		return
	end
	ShopService.RemoveTrail(player)

	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	local head = player.Character:FindFirstChild("Head")
	if not hrp or not head then
		return
	end

	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "TrailAttach0"
	attachment0.Parent = hrp

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "TrailAttach1"
	attachment1.Parent = head

	local trail = Instance.new("Trail")
	trail.Name = "SummitTrail"
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Lifetime = 0.5
	trail.MinLength = 0.1
	trail.Color = ColorSequence.new(item.trailColor)
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	trail.Parent = player.Character
end

local function applyAura(player, item)
	if not player.Character then
		return
	end
	ShopService.RemoveAura(player)

	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local particle = Instance.new("ParticleEmitter")
	particle.Name = "SummitAura"
	particle.Color = ColorSequence.new(item.particleColor)
	particle.Size = NumberSequence.new(item.particleSize or 2)
	particle.Rate = 20
	particle.Lifetime = NumberRange.new(0.5, 1.5)
	particle.Speed = NumberRange.new(1, 3)
	particle.SpreadAngle = Vector2.new(180, 180)
	particle.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	particle.Parent = hrp
end

function ShopService.RemoveTrail(player)
	if not player.Character then
		return
	end
	local existing = player.Character:FindFirstChild("SummitTrail")
	if existing then
		existing:Destroy()
	end
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local a = hrp:FindFirstChild("TrailAttach0")
		if a then
			a:Destroy()
		end
	end
	local head = player.Character:FindFirstChild("Head")
	if head then
		local a = head:FindFirstChild("TrailAttach1")
		if a then
			a:Destroy()
		end
	end
end

function ShopService.RemoveAura(player)
	if not player.Character then
		return
	end
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local existing = hrp:FindFirstChild("SummitAura")
		if existing then
			existing:Destroy()
		end
	end
end

function ShopService.Init()
	local Server = ServerScriptService:FindFirstChild("Server")
	local DataService = require(Server:FindFirstChild("DataService"))

	Remotes.BuyItem.OnServerInvoke = function(player, itemId)
		local item, _categoryName = findItem(itemId)
		if not item then
			return false, "Item not found"
		end
		if DataService.HasItem(player, itemId) then
			return false, "Already owned"
		end
		if not DataService.SpendCoins(player, item.price) then
			return false, "Not enough coins"
		end
		DataService.AddToInventory(player, itemId)
		Remotes.UpdateCoins:FireClient(player, DataService.GetCoins(player))
		return true, "Success"
	end

	Remotes.EquipItem.OnServerEvent:Connect(function(player, itemId)
		if not DataService.HasItem(player, itemId) then
			return
		end
		local item, categoryName = findItem(itemId)
		if not item then
			return
		end
		if categoryName == "Trails" then
			DataService.SetEquipped(player, "trail", itemId)
			applyTrail(player, item)
		elseif categoryName == "Auras" then
			DataService.SetEquipped(player, "aura", itemId)
			applyAura(player, item)
		end
	end)

	Remotes.UnequipItem.OnServerEvent:Connect(function(player, slot)
		DataService.SetEquipped(player, slot, nil)
		if slot == "trail" then
			ShopService.RemoveTrail(player)
		elseif slot == "aura" then
			ShopService.RemoveAura(player)
		end
	end)

	Remotes.GetInventory.OnServerInvoke = function(player)
		local data = DataService.GetData(player)
		if not data then
			return {}, {}
		end
		return data.inventory, data.equipped
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(1)
			local equipped = DataService.GetEquipped(player)
			if equipped.trail then
				local item = findItem(equipped.trail)
				if item then
					applyTrail(player, item)
				end
			end
			if equipped.aura then
				local item = findItem(equipped.aura)
				if item then
					applyAura(player, item)
				end
			end
		end)
	end)
end

return ShopService
