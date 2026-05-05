--[[
	AvatarService - Applies full avatar (HumanoidDescription) to player
	Keeps overhead intact after avatar change.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local AvatarService = {}

function AvatarService.Init(remotes)
	remotes.ApplyAvatar.OnServerEvent:Connect(function(player, userId)
		if not player.Character then
			return
		end
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end

		local ok, description = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(userId)
		end)

		if not ok or not description then
			warn("[AvatarService] Failed to get description for userId: " .. tostring(userId))
			return
		end

		-- Save overhead reference
		local head = player.Character:FindFirstChild("Head")
		local overheadData = nil
		if head then
			local bb = head:FindFirstChild("SummitOverhead")
			if bb then
				overheadData = bb:Clone()
			end
		end

		-- Apply avatar
		local applyOk, applyErr = pcall(function()
			humanoid:ApplyDescription(description)
		end)

		if not applyOk then
			warn("[AvatarService] Failed to apply avatar: " .. tostring(applyErr))
			return
		end

		-- Restore overhead
		task.wait(0.5)
		if overheadData then
			local newHead = player.Character:FindFirstChild("Head")
			if newHead then
				local existing = newHead:FindFirstChild("SummitOverhead")
				if existing then
					existing:Destroy()
				end
				overheadData.Parent = newHead
			end
		end

		-- Re-apply shop items (trail/aura)
		local Server = ServerScriptService:WaitForChild("Server")
		local DataService = require(Server:WaitForChild("DataService"))
		local ShopConfig =
			require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ShopConfig"))
		local equipped = DataService.GetEquipped(player)

		if equipped.trail and equipped.trail ~= "" then
			local item = ShopConfig.FindItem(equipped.trail)
			if item and player.Character then
				-- Trail will be re-applied by ShopService on CharacterAdded
				remotes.EquipItem:FireClient(player, equipped.trail)
			end
		end

		print("[AvatarService] Applied avatar " .. tostring(userId) .. " to " .. player.Name)
	end)

	remotes.ResetAvatar.OnServerEvent:Connect(function(player)
		if not player.Character then
			return
		end
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end

		-- Save overhead
		local head = player.Character:FindFirstChild("Head")
		local overheadData = nil
		if head then
			local bb = head:FindFirstChild("SummitOverhead")
			if bb then
				overheadData = bb:Clone()
			end
		end

		-- Reset to player's own avatar
		local ok, description = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(player.UserId)
		end)

		if ok and description then
			pcall(function()
				humanoid:ApplyDescription(description)
			end)
		end

		-- Restore overhead
		task.wait(0.5)
		if overheadData then
			local newHead = player.Character:FindFirstChild("Head")
			if newHead then
				local existing = newHead:FindFirstChild("SummitOverhead")
				if existing then
					existing:Destroy()
				end
				overheadData.Parent = newHead
			end
		end

		print("[AvatarService] Reset avatar for " .. player.Name)
	end)
end

return AvatarService
