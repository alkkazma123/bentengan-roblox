--[[
	CoinConfig
	Configure coin rewards and collection settings.
]]

local CoinConfig = {}

-- Coins earned per summit
CoinConfig.CoinsPerSummit = 10

-- Coins earned per checkpoint reached (first time per life)
CoinConfig.CoinsPerCheckpoint = 2

-- Starting coins for new players
CoinConfig.StartingCoins = 0

return CoinConfig
