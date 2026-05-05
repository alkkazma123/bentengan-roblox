--[[
	SkyService - Changes sky for individual players
	Sky options:
	  - Galaxy Sky (default in Lighting)
	  - Purple Galaxy (in ReplicatedStorage)
	  - Sky (in ReplicatedStorage)
]]

local SkyService = {}

function SkyService.Init(remotes)
	remotes.ChangeSky.OnServerEvent:Connect(function(player, skyName)
		if not player or not skyName then
			return
		end
		-- Validate sky name
		local valid = { "Galaxy Sky", "Purple Galaxy", "Sky", "Default" }
		local isValid = false
		for _, name in ipairs(valid) do
			if name == skyName then
				isValid = true
				break
			end
		end
		if not isValid then
			return
		end

		print("[SkyService] " .. player.Name .. " changed sky to: " .. skyName)
		remotes.ChangeSky:FireClient(player, skyName)
	end)

	print("[SkyService] Ready. Sky options: Galaxy Sky, Purple Galaxy, Sky, Default")
end

return SkyService
