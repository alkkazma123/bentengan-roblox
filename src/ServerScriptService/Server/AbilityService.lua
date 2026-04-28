--!strict
-- Server-authoritative ability effects. Applied when match starts,
-- stripped when match ends or player dies.

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent.DataService)

local AbilityService = {}

local BASE_WALK_SPEED = 16
local BASE_JUMP_POWER = 50

-- Track fly state per player to enforce per-match quota & cooldown on the server.
local flyState: { [Player]: { Remaining: number, LastUsedAt: number, Active: boolean, MatchId: number } } = {}

local function humanoidOf(player: Player): Humanoid?
	local char = player.Character
	if not char then
		return nil
	end
	return char:FindFirstChildOfClass("Humanoid")
end

function AbilityService.onMatchStart(player: Player, matchId: number)
	local profile = DataService.getProfile(player)
	local hum = humanoidOf(player)
	if not hum then
		return
	end
	local walk = BASE_WALK_SPEED
	local jump = BASE_JUMP_POWER
	for _, id in profile.EquippedAbilities do
		local def = GameConfig.Abilities[id]
		if not def then
			continue
		end
		if def.Id == "SpeedBoost" then
			walk = BASE_WALK_SPEED * def.Params.WalkSpeedMultiplier
		elseif def.Id == "JumpBoost" then
			jump = BASE_JUMP_POWER * def.Params.JumpPowerMultiplier
		end
	end
	hum.WalkSpeed = walk
	hum.JumpPower = jump
	hum.UseJumpPower = true

	-- Reset fly quota
	local flyDef = GameConfig.Abilities.Fly
	flyState[player] = {
		Remaining = flyDef.Params.Duration,
		LastUsedAt = 0,
		Active = false,
		MatchId = matchId,
	}

	-- Client-side ESP handled via InventoryUpdate; here we just (re)push it.
	Remotes.InventoryUpdate:FireClient(player, {
		Owned = profile.OwnedAbilities,
		Equipped = profile.EquippedAbilities,
	})
end

function AbilityService.onMatchEnd(player: Player)
	local hum = humanoidOf(player)
	if hum then
		hum.WalkSpeed = BASE_WALK_SPEED
		hum.JumpPower = BASE_JUMP_POWER
	end
	flyState[player] = nil
end

function AbilityService.onPlayerLeaving(player: Player)
	flyState[player] = nil
end

local function hasEquipped(player: Player, abilityId: string): boolean
	local profile = DataService.getProfile(player)
	for _, id in profile.EquippedAbilities do
		if id == abilityId then
			return true
		end
	end
	return false
end

local function stopFly(player: Player)
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		local existing = hrp:FindFirstChild("BentenganFlyVelocity")
		if existing then
			existing:Destroy()
		end
		local g = hrp:FindFirstChild("BentenganFlyGravity")
		if g then
			g:Destroy()
		end
	end
	local st = flyState[player]
	if st then
		st.Active = false
		st.LastUsedAt = os.clock()
	end
end

function AbilityService.activateFly(player: Player, matchId: number): (boolean, string?)
	if not hasEquipped(player, "Fly") then
		return false, "Fly tidak di-equip"
	end
	local st = flyState[player]
	if not st or st.MatchId ~= matchId then
		return false, "Tidak dalam match"
	end
	if st.Active then
		return false, "Fly sedang aktif"
	end
	local flyDef = GameConfig.Abilities.Fly
	local now = os.clock()
	if st.LastUsedAt > 0 and (now - st.LastUsedAt) < flyDef.Params.Cooldown then
		local remaining = math.ceil(flyDef.Params.Cooldown - (now - st.LastUsedAt))
		return false, "Cooldown " .. remaining .. "s"
	end
	if st.Remaining <= 0 then
		return false, "Durasi Fly habis untuk match ini"
	end

	local char = player.Character
	if not char then
		return false, "No character"
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return false, "No HRP"
	end

	-- Anti-gravity + user-controlled velocity (body forces work but LinearVelocity/BodyGyro simpler).
	local grav = Instance.new("BodyVelocity")
	grav.Name = "BentenganFlyGravity"
	grav.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	grav.Velocity = Vector3.new(0, 0, 0)
	grav.Parent = hrp

	st.Active = true
	local duration = math.min(flyDef.Params.Duration, st.Remaining)
	local endAt = now + duration

	-- Tell client to drive velocity via WASD / space / shift
	Remotes.AbilityFeedback:FireClient(player, {
		Type = "FlyStart",
		EndsAt = endAt,
		Speed = flyDef.Params.FlySpeed,
	})

	task.spawn(function()
		while st.Active and os.clock() < endAt do
			task.wait(0.1)
			local currentSt = flyState[player]
			if not currentSt or currentSt ~= st then
				break
			end
		end
		if flyState[player] == st then
			local used = math.min(duration, os.clock() - (endAt - duration))
			st.Remaining = math.max(0, st.Remaining - used)
			stopFly(player)
			Remotes.AbilityFeedback:FireClient(player, {
				Type = "FlyEnd",
				Remaining = st.Remaining,
				Cooldown = flyDef.Params.Cooldown,
			})
		end
	end)

	return true
end

Players.PlayerRemoving:Connect(function(player)
	AbilityService.onPlayerLeaving(player)
end)

return AbilityService
