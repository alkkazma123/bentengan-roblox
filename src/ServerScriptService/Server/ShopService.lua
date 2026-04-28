--!strict
-- Handles buy / equip / unequip with strict server-side validation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local DataService = require(script.Parent.DataService)

local ShopService = {}

local function getAbilityDef(id: string)
	return GameConfig.Abilities[id]
end

function ShopService.pushUpdate(player: Player)
	local profile = DataService.getProfile(player)
	Remotes.InventoryUpdate:FireClient(player, {
		Owned = profile.OwnedAbilities,
		Equipped = profile.EquippedAbilities,
	})
	Remotes.CoinsUpdate:FireClient(player, profile.Coins)
end

function ShopService.buy(player: Player, abilityId: string): (boolean, string?)
	local def = getAbilityDef(abilityId)
	if not def then
		return false, "Ability tidak dikenal"
	end
	if DataService.isOwned(player, abilityId) then
		return false, "Sudah dimiliki"
	end
	if not DataService.spendCoins(player, def.Price) then
		return false, "Coin tidak cukup"
	end
	DataService.grantAbility(player, abilityId)
	ShopService.pushUpdate(player)
	return true
end

local function typeAlreadyEquipped(equipped: { string }, targetType: string, ignoreId: string?): boolean
	for _, id in equipped do
		if id == ignoreId then
			continue
		end
		local def = getAbilityDef(id)
		if def and def.Type == targetType then
			return true
		end
	end
	return false
end

function ShopService.equip(player: Player, abilityId: string): (boolean, string?)
	local def = getAbilityDef(abilityId)
	if not def then
		return false, "Ability tidak dikenal"
	end
	if not DataService.isOwned(player, abilityId) then
		return false, "Belum dibeli"
	end
	local profile = DataService.getProfile(player)
	local equipped = table.clone(profile.EquippedAbilities)
	-- Already equipped?
	for _, id in equipped do
		if id == abilityId then
			return false, "Sudah ter-equip"
		end
	end
	if #equipped >= GameConfig.MaxEquippedAbilities then
		return false, string.format("Maksimal %d ability bisa di-equip", GameConfig.MaxEquippedAbilities)
	end
	if typeAlreadyEquipped(equipped, def.Type, nil) then
		return false, "Tipe ability ini sudah di-equip"
	end
	table.insert(equipped, abilityId)
	DataService.setEquipped(player, equipped)
	ShopService.pushUpdate(player)
	return true
end

function ShopService.unequip(player: Player, abilityId: string): (boolean, string?)
	local profile = DataService.getProfile(player)
	local equipped = table.clone(profile.EquippedAbilities)
	for i, id in equipped do
		if id == abilityId then
			table.remove(equipped, i)
			DataService.setEquipped(player, equipped)
			ShopService.pushUpdate(player)
			return true
		end
	end
	return false, "Tidak ter-equip"
end

return ShopService
