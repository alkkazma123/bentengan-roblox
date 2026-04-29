--!strict
-- Server-authoritative dash. A player can dash forward for a short burst; the
-- server validates cooldown and applies a LinearVelocity so exploiters cannot
-- teleport further than intended.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local DashService = {}

local COOLDOWN = 4.0 -- seconds
local DURATION = 0.28 -- seconds
local SPEED = 80 -- studs / sec
local UPWARD = 6 -- small hop so you skim ground

local lastDashAt: { [Player]: number } = {}

local function cleanupPlayer(player: Player)
	lastDashAt[player] = nil
end

Players.PlayerRemoving:Connect(cleanupPlayer)

local function applyDash(player: Player)
	local char = player.Character
	if not char then
		return false
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	if not (hrp and hrp:IsA("BasePart")) then
		return false
	end
	-- Don't allow dashing while jailed (WalkSpeed = 0 is the marker we set).
	if humanoid.WalkSpeed <= 0.01 then
		return false
	end
	-- Refuse if the character is in a state that shouldn't move (ragdoll,
	-- seated, climbing, swimming, dead). LinearVelocity on a seated humanoid
	-- can launch them weirdly; better to just no-op.
	local state = humanoid:GetState()
	if
		state == Enum.HumanoidStateType.Dead
		or state == Enum.HumanoidStateType.Seated
		or state == Enum.HumanoidStateType.PlatformStanding
		or state == Enum.HumanoidStateType.Ragdoll
	then
		return false
	end

	local lookVec = hrp.CFrame.LookVector
	local direction = Vector3.new(lookVec.X, 0, lookVec.Z)
	if direction.Magnitude < 0.01 then
		direction = Vector3.new(0, 0, -1)
	else
		direction = direction.Unit
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "DashAttachment"
	attachment.Parent = hrp

	local lv = Instance.new("LinearVelocity")
	lv.Name = "DashVelocity"
	lv.Attachment0 = attachment
	lv.MaxForce = math.huge
	lv.VectorVelocity = direction * SPEED + Vector3.new(0, UPWARD, 0)
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Parent = hrp

	task.delay(DURATION, function()
		if lv and lv.Parent then
			lv:Destroy()
		end
		if attachment and attachment.Parent then
			attachment:Destroy()
		end
	end)

	return true
end

function DashService.requestDash(player: Player): (boolean, string?)
	local now = os.clock()
	local last = lastDashAt[player] or 0
	local remaining = (last + COOLDOWN) - now
	if remaining > 0 then
		return false, string.format("Cooldown %.1fs", remaining)
	end
	if not applyDash(player) then
		return false, "Tidak bisa dash sekarang"
	end
	lastDashAt[player] = now
	Remotes.DashFeedback:FireClient(player, {
		Type = "DashStart",
		CooldownEndsAt = now + COOLDOWN,
		Duration = DURATION,
	})
	return true
end

function DashService.getConfig()
	return {
		Cooldown = COOLDOWN,
		Duration = DURATION,
		Speed = SPEED,
	}
end

return DashService
