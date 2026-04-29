--!strict
-- Daily login bonus + once-per-day spin wheel.
-- Server is authoritative: the client just renders state and sends requests;
-- all timing / RNG / coin grants happen here.

local DataService = require(script.Parent.DataService)

local DailyRewards = {}

-- Login streak rewards (1-indexed by day in streak).
local STREAK_REWARDS = { 50, 75, 100, 150, 200, 300, 500 }
local function streakReward(streak: number): number
	if streak < 1 then
		streak = 1
	end
	if streak > #STREAK_REWARDS then
		return STREAK_REWARDS[#STREAK_REWARDS]
	end
	return STREAK_REWARDS[streak]
end

-- Spin wheel segments. Each segment represents an equally-sized slice; the
-- amount is the coin payout for that slice.
local SPIN_SEGMENTS = {
	25,
	50,
	75,
	100,
	150,
	200,
	300,
	500,
}

local SPIN_COOLDOWN = 24 * 60 * 60 -- 24 hours

local DAY_SECONDS = 24 * 60 * 60

-- Returns absolute "day index" since the unix epoch in UTC.
local function dayIndex(t: number): number
	return math.floor(t / DAY_SECONDS)
end

export type LoginInfo = {
	Streak: number,
	Reward: number,
	AlreadyClaimedToday: boolean,
}

export type SpinInfo = {
	Available: boolean,
	NextAvailableAt: number,
	Segments: { number },
}

-- Pure read: figure out what claim state the player is in WITHOUT mutating
-- the profile. Decides what reward they would get if they pressed Claim now,
-- and whether they've already claimed today. We base "today" on the
-- LastLoginAt timestamp, which is only ever written by claimLogin().
function DailyRewards.evaluateLogin(player: Player): LoginInfo
	local profile = DataService.getProfile(player)
	local now = os.time()
	local last = profile.LastLoginAt or 0
	local lastDay = dayIndex(last)
	local nowDay = dayIndex(now)

	if last ~= 0 and nowDay == lastDay then
		-- Already claimed today; show their current streak unchanged.
		return {
			Streak = math.max(1, profile.LoginStreak),
			Reward = streakReward(math.max(1, profile.LoginStreak)),
			AlreadyClaimedToday = true,
		}
	end

	-- Predict what the streak will be if they claim now.
	local nextStreak: number
	if last == 0 or (nowDay - lastDay) > 1 then
		nextStreak = 1
	else
		nextStreak = math.max(1, profile.LoginStreak) + 1
	end

	return {
		Streak = nextStreak,
		Reward = streakReward(nextStreak),
		AlreadyClaimedToday = false,
	}
end

-- Pay out the current day's login bonus and write the new state. Idempotent
-- within the same UTC day (subsequent calls return false).
function DailyRewards.claimLogin(player: Player): (boolean, LoginInfo)
	local info = DailyRewards.evaluateLogin(player)
	if info.AlreadyClaimedToday then
		return false, info
	end
	local profile = DataService.getProfile(player)
	profile.LoginStreak = info.Streak
	profile.LastLoginAt = os.time()
	DataService.addCoins(player, info.Reward)
	return true, {
		Streak = info.Streak,
		Reward = info.Reward,
		AlreadyClaimedToday = true,
	}
end

-- Returns whether the player can spin right now and when the next spin opens.
function DailyRewards.spinState(player: Player): SpinInfo
	local profile = DataService.getProfile(player)
	local now = os.time()
	local last = profile.LastSpinAt or 0
	local available = (now - last) >= SPIN_COOLDOWN
	return {
		Available = available,
		NextAvailableAt = last + SPIN_COOLDOWN,
		Segments = SPIN_SEGMENTS,
	}
end

export type SpinResult = {
	Success: boolean,
	Reward: number,
	SegmentIndex: number,
	NextAvailableAt: number,
	Message: string?,
}

-- Pick a segment, credit coins, mark cooldown.
function DailyRewards.spin(player: Player): SpinResult
	local profile = DataService.getProfile(player)
	local now = os.time()
	local last = profile.LastSpinAt or 0
	if (now - last) < SPIN_COOLDOWN then
		return {
			Success = false,
			Reward = 0,
			SegmentIndex = 0,
			NextAvailableAt = last + SPIN_COOLDOWN,
			Message = "Spin sudah dipakai hari ini.",
		}
	end
	local idx = math.random(1, #SPIN_SEGMENTS)
	local reward = SPIN_SEGMENTS[idx]
	DataService.addCoins(player, reward)
	profile.LastSpinAt = now
	return {
		Success = true,
		Reward = reward,
		SegmentIndex = idx,
		NextAvailableAt = now + SPIN_COOLDOWN,
	}
end

function DailyRewards.getConfig()
	return {
		StreakRewards = STREAK_REWARDS,
		SpinSegments = SPIN_SEGMENTS,
		SpinCooldown = SPIN_COOLDOWN,
	}
end

return DailyRewards
