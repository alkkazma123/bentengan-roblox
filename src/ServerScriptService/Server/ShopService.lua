--[[
	ShopService - Buy/equip/unequip shop items
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(Shared:WaitForChild("ShopConfig"))

local ShopService = {}

local function applyTrail(character, item)
	-- Remove old
	local oldTrail = character:FindFirstChild("SummitTrail")
	if oldTrail then
		oldTrail:Destroy()
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local a0 = hrp:FindFirstChild("TrailA0")
		if a0 then
			a0:Destroy()
		end
	end
	local head = character:FindFirstChild("Head")
	if head then
		local a1 = head:FindFirstChild("TrailA1")
		if a1 then
			a1:Destroy()
		end
	end

	if not item then
		return
	end
	hrp = character:FindFirstChild("HumanoidRootPart")
	head = character:FindFirstChild("Head")
	if not hrp or not head then
		return
	end

	local a0 = Instance.new("Attachment")
	a0.Name = "TrailA0"
	a0.Parent = hrp

	local a1 = Instance.new("Attachment")
	a1.Name = "TrailA1"
	a1.Parent = head

	local trail = Instance.new("Trail")
	trail.Name = "SummitTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.5
	trail.MinLength = 0.1
	trail.Color = ColorSequence.new(item.color)
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	trail.Parent = character
end

local function applyAura(character, item)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local old = hrp:FindFirstChild("SummitAura")
		if old then
			old:Destroy()
		end
	end

	if not item then
		return
	end
	hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local p = Instance.new("ParticleEmitter")
	p.Name = "SummitAura"
	p.Color = ColorSequence.new(item.color)
	p.Size = NumberSequence.new(2)
	p.Rate = 20
	p.Lifetime = NumberRange.new(0.5, 1.5)
	p.Speed = NumberRange.new(1, 3)
	p.SpreadAngle = Vector2.new(180, 180)
	p.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	p.Parent = hrp
end

function ShopService.Init(remotes)
	local Server = ServerScriptService:WaitForChild("Server")
	local DataService = require(Server:WaitForChild("DataService"))

	-- Buy
	remotes.BuyItem.OnServerInvoke = function(player, itemId)
		local item = ShopConfig.FindItem(itemId)
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
		remotes.UpdateCoins:FireClient(player, DataService.GetCoins(player))
		return true, "Success"
	end

	-- Equip
	remotes.EquipItem.OnServerEvent:Connect(function(player, itemId)
		if not DataService.HasItem(player, itemId) then
			return
		end
		local item, categoryName = ShopConfig.FindItem(itemId)
		if not item or not player.Character then
			return
		end
		if categoryName == "Trails" then
			DataService.SetEquipped(player, "trail", itemId)
			applyTrail(player.Character, item)
		elseif categoryName == "Auras" then
			DataService.SetEquipped(player, "aura", itemId)
			applyAura(player.Character, item)
		end
	end)

	-- Unequip
	remotes.UnequipItem.OnServerEvent:Connect(function(player, slot)
		DataService.SetEquipped(player, slot, "")
		if player.Character then
			if slot == "trail" then
				applyTrail(player.Character, nil)
			elseif slot == "aura" then
				applyAura(player.Character, nil)
			end
		end
	end)

	-- GetInventory
	remotes.GetInventory.OnServerInvoke = function(player)
		local data = DataService.GetData(player)
		if not data then
			return {}, {}
		end
		return data.inventory, data.equipped
	end

	-- Re-apply on respawn
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			task.wait(1)
			local equipped = DataService.GetEquipped(player)
			if equipped.trail and equipped.trail ~= "" then
				local item = ShopConfig.FindItem(equipped.trail)
				if item then
					applyTrail(character, item)
				end
			end
			if equipped.aura and equipped.aura ~= "" then
				local item = ShopConfig.FindItem(equipped.aura)
				if item then
					applyAura(character, item)
				end
			end
		end)
	end)
end

return ShopService
