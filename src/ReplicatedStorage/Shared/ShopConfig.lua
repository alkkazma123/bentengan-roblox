--[[
	ShopConfig
	Tambah/hapus item di sini.
]]

local ShopConfig = {}

ShopConfig.Categories = {
	{
		name = "Trails",
		items = {
			{ id = "trail_white", name = "White Trail", price = 50, color = Color3.fromRGB(255, 255, 255) },
			{ id = "trail_red", name = "Fire Trail", price = 100, color = Color3.fromRGB(255, 50, 0) },
			{ id = "trail_blue", name = "Ice Trail", price = 100, color = Color3.fromRGB(0, 150, 255) },
			{ id = "trail_rainbow", name = "Rainbow Trail", price = 300, color = Color3.fromRGB(255, 255, 255) },
			{ id = "trail_gold", name = "Gold Trail", price = 500, color = Color3.fromRGB(255, 215, 0) },
		},
	},
	{
		name = "Auras",
		items = {
			{ id = "aura_flame", name = "Flame Aura", price = 150, color = Color3.fromRGB(255, 100, 0) },
			{ id = "aura_ice", name = "Ice Aura", price = 150, color = Color3.fromRGB(100, 200, 255) },
			{ id = "aura_shadow", name = "Shadow Aura", price = 250, color = Color3.fromRGB(50, 0, 80) },
			{ id = "aura_divine", name = "Divine Aura", price = 500, color = Color3.fromRGB(255, 255, 200) },
		},
	},
}

function ShopConfig.FindItem(itemId)
	for _, category in ipairs(ShopConfig.Categories) do
		for _, item in ipairs(category.items) do
			if item.id == itemId then
				return item, category.name
			end
		end
	end
	return nil, nil
end

return ShopConfig
