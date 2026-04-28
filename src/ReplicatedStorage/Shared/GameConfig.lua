--!strict
-- Central configuration for the Bentengan game.
-- Tweak these values to rebalance the match experience.

local GameConfig = {}

GameConfig.MinPlayersPerLobby = 2
GameConfig.MaxPlayersPerLobby = 12
GameConfig.NumLobbies = 4
GameConfig.CountdownSeconds = 12 -- 10-15s
GameConfig.MatchDurationSeconds = 180
GameConfig.RespawnDelaySeconds = 3
GameConfig.JailReleaseOnTouchByTeammate = true
GameConfig.TagCooldownSeconds = 1.0

GameConfig.Rewards = {
	WinCoins = 100,
	LoseCoins = 25,
	PerTagCoins = 10,
	BaseTouchCoins = 50,
}

GameConfig.Teams = {
	Red = { Name = "Red", Color = Color3.fromRGB(225, 70, 70) },
	Blue = { Name = "Blue", Color = Color3.fromRGB(70, 130, 225) },
}

-- Ability types: only 1 of each type can be equipped, max 3 abilities total.
GameConfig.AbilityTypes = {
	Movement = "Movement", -- Speed, Jump, Fly all share Movement? no, see below
	Speed = "Speed",
	Jump = "Jump",
	Vision = "Vision",
	Fly = "Fly",
}

GameConfig.Abilities = {
	SpeedBoost = {
		Id = "SpeedBoost",
		Name = "Speed Boost",
		Type = "Speed",
		Price = 250,
		Description = "Meningkatkan kecepatan lari +35% selama pertandingan.",
		Icon = "rbxassetid://6031075929",
		Params = { WalkSpeedMultiplier = 1.35 },
	},
	JumpBoost = {
		Id = "JumpBoost",
		Name = "Jump Boost",
		Type = "Jump",
		Price = 250,
		Description = "Meningkatkan tinggi lompat +40%.",
		Icon = "rbxassetid://6031075931",
		Params = { JumpPowerMultiplier = 1.4 },
	},
	HackerESP = {
		Id = "HackerESP",
		Name = "Hacker (ESP)",
		Type = "Vision",
		Price = 500,
		Description = "Menampilkan outline musuh lewat tembok.",
		Icon = "rbxassetid://6031068426",
		Params = {},
	},
	Fly = {
		Id = "Fly",
		Name = "Fly (10s)",
		Type = "Fly",
		Price = 800,
		Description = "Terbang selama 10 detik per match dengan cooldown 30 detik.",
		Icon = "rbxassetid://6031068433",
		Params = { Duration = 10, Cooldown = 30, FlySpeed = 60 },
	},
}

GameConfig.MaxEquippedAbilities = 3

-- Starting coins for a new player (first-time bonus)
GameConfig.StartingCoins = 200

return GameConfig
