--[[
	EmoteService
	Handles playing emote animations on the server.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EmoteList = require(Shared:WaitForChild("EmoteList"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local EmoteService = {}

local activeEmotes = {}

local function getEmoteId(emoteName)
	for _, emote in ipairs(EmoteList.Emotes) do
		if emote.name == emoteName then
			return emote.id
		end
	end
	local emotesFolder = ReplicatedStorage:FindFirstChild("Emotes")
	if emotesFolder then
		local anim = emotesFolder:FindFirstChild(emoteName)
		if anim and anim:IsA("Animation") then
			return anim.AnimationId
		end
	end
	return nil
end

function EmoteService.Init()
	Remotes.PlayEmote.OnServerEvent:Connect(function(player, emoteName)
		if not player.Character then
			return
		end
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if not humanoid then
			return
		end

		if activeEmotes[player.UserId] then
			activeEmotes[player.UserId]:Stop()
			activeEmotes[player.UserId] = nil
		end

		if not emoteName then
			return
		end

		local animId = getEmoteId(emoteName)
		if not animId then
			return
		end

		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end

		local animation = Instance.new("Animation")
		animation.AnimationId = animId

		local track = animator:LoadAnimation(animation)
		track:Play()
		activeEmotes[player.UserId] = track

		local connection
		connection = humanoid.Running:Connect(function(speed)
			if speed > 0.5 then
				if activeEmotes[player.UserId] then
					activeEmotes[player.UserId]:Stop()
					activeEmotes[player.UserId] = nil
				end
				connection:Disconnect()
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		activeEmotes[player.UserId] = nil
	end)
end

return EmoteService
