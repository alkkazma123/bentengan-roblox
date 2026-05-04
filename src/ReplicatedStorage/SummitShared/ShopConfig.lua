--[[
	ShopConfig
	Define shop items: trails and auras.
	Add new items here and they'll appear in the shop automatically.
]]

local ShopConfig = {}

ShopConfig.Categories = {
	{
		name = "Trails",
		icon = "rbxassetid://6031071057",
		items = {
			{
				id = "trail_white",
				name = "White Trail",
				price = 50,
				trailColor = Color3.fromRGB(255, 255, 255),
			},
			{
				id = "trail_red",
				name = "Fire Trail",
				price = 100,
				trailColor = Color3.fromRGB(255, 50, 0),
			},
			{
				id = "trail_blue",
				name = "Ice Trail",
				price = 100,
				trailColor = Color3.fromRGB(0, 150, 255),
			},
			{
				id = "trail_rainbow",
				name = "Rainbow Trail",
				price = 300,
				trailColor = Color3.fromRGB(255, 255, 255),
				isRainbow = true,
			},
			{
				id = "trail_gold",
				name = "Gold Trail",
				price = 500,
				trailColor = Color3.fromRGB(255, 215, 0),
			},
		},
	},
	{
		name = "Auras",
		icon = "rbxassetid://6031071057",
		items = {
			{
				id = "aura_flame",
				name = "Flame Aura",
				price = 150,
				particleColor = Color3.fromRGB(255, 100, 0),
				particleSize = 2,
			},
			{
				id = "aura_ice",
				name = "Ice Aura",
				price = 150,
				particleColor = Color3.fromRGB(100, 200, 255),
				particleSize = 1.5,
			},
			{
				id = "aura_shadow",
				name = "Shadow Aura",
				price = 250,
				particleColor = Color3.fromRGB(50, 0, 80),
				particleSize = 2.5,
			},
			{
				id = "aura_divine",
				name = "Divine Aura",
				price = 500,
				particleColor = Color3.fromRGB(255, 255, 200),
				particleSize = 3,
			},
		},
	},
}

return ShopConfig
