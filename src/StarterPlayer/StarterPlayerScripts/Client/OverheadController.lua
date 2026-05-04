--[[
	OverheadController
	Listens for overhead updates and refreshes BillboardGui on other players.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TitleConfig = require(Shared:WaitForChild("TitleConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local OverheadController = {}

function OverheadController.Init()
	Remotes.UpdateOverhead.OnClientEvent:Connect(function(targetPlayer, summitCount)
		if not targetPlayer or not targetPlayer.Character then
			return
		end
		local head = targetPlayer.Character:FindFirstChild("Head")
		if not head then
			return
		end

		local billboard = head:FindFirstChild("SummitOverhead")
		if not billboard then
			return
		end

		local title, titleColor = TitleConfig.GetTitle(summitCount)

		local summitLabel = billboard:FindFirstChild("Summits")
		if summitLabel then
			summitLabel.Text = summitCount .. " Summits"
		end

		local titleLabel = billboard:FindFirstChild("Title")
		if titleLabel then
			titleLabel.Text = title
			titleLabel.TextColor3 = titleColor
		end
	end)
end

return OverheadController
