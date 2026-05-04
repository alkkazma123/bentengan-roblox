--[[
	OverheadController - Updates overhead when summit count changes
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TitleConfig = require(Shared:WaitForChild("TitleConfig"))

local remoteFolder = ReplicatedStorage:WaitForChild("SummitRemotes")
local UpdateOverhead = remoteFolder:WaitForChild("UpdateOverhead")

local OverheadController = {}

function OverheadController.Init()
	UpdateOverhead.OnClientEvent:Connect(function(targetPlayer, summits)
		if not targetPlayer or not targetPlayer.Character then
			return
		end
		local head = targetPlayer.Character:FindFirstChild("Head")
		if not head then
			return
		end
		local bb = head:FindFirstChild("SummitOverhead")
		if not bb then
			return
		end
		local summitLabel = bb:FindFirstChild("Summits")
		if summitLabel then
			summitLabel.Text = summits .. " Summits"
		end
		local titleLabel = bb:FindFirstChild("Title")
		if titleLabel then
			local title, color = TitleConfig.GetTitle(summits)
			titleLabel.Text = title
			titleLabel.TextColor3 = color
		end
	end)
end

return OverheadController
