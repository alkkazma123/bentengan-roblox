--[[
	TitleConfig
	Defines titles based on total summit count.
	Titles are checked top-down; first matching threshold wins.
]]

local TitleConfig = {}

-- Ordered from highest to lowest threshold
TitleConfig.Titles = {
	{ threshold = 1000, title = "Summit God", color = Color3.fromRGB(255, 215, 0) },
	{ threshold = 500, title = "Summit Legend", color = Color3.fromRGB(255, 100, 255) },
	{ threshold = 200, title = "Summit Master", color = Color3.fromRGB(0, 255, 200) },
	{ threshold = 100, title = "Summit Expert", color = Color3.fromRGB(0, 200, 255) },
	{ threshold = 50, title = "Summit Pro", color = Color3.fromRGB(100, 200, 100) },
	{ threshold = 25, title = "Adventurer", color = Color3.fromRGB(200, 200, 100) },
	{ threshold = 10, title = "Climber", color = Color3.fromRGB(200, 200, 200) },
	{ threshold = 1, title = "Rookie", color = Color3.fromRGB(180, 180, 180) },
}

-- Default title for 0 summits
TitleConfig.DefaultTitle = "Newbie"
TitleConfig.DefaultColor = Color3.fromRGB(150, 150, 150)

function TitleConfig.GetTitle(summitCount)
	for _, entry in ipairs(TitleConfig.Titles) do
		if summitCount >= entry.threshold then
			return entry.title, entry.color
		end
	end
	return TitleConfig.DefaultTitle, TitleConfig.DefaultColor
end

return TitleConfig
