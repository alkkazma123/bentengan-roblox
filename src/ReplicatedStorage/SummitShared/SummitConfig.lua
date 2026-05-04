--[[
	SummitConfig
	Configure summit rewards and event settings.
	Adjust SummitsPerFinish to change how many summits a player earns
	when they touch the Finish/Summit part.
]]

local SummitConfig = {}

-- How many summits the player earns each time they reach the top
SummitConfig.SummitsPerFinish = 1

-- Cooldown in seconds before same player can earn again
SummitConfig.Cooldown = 5

-- Whether to teleport player back to start after summit
SummitConfig.TeleportToStartAfterSummit = true

-- Delay before teleport (seconds)
SummitConfig.TeleportDelay = 3

-- Celebration message shown on summit
SummitConfig.CelebrationMessage = "SUMMIT REACHED!"

return SummitConfig
