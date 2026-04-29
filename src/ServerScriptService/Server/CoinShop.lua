--!strict
-- Robux-paid coin packs.
-- Each developer product grants a fixed amount of in-game coins. We use the
-- standard ProcessReceipt + ReceiptDataStore idempotency pattern so a player
-- never gets double-credited if their purchase webhook fires multiple times.

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)

local CoinShop = {}

-- Map devProductId -> reward in coins. IDs come from the Robux developer
-- products configured by the game owner; if you create new products in the
-- Roblox dashboard, add them here.
local PRODUCTS: { [number]: { Coins: number, RobuxLabel: string } } = {
	[3583241345] = { Coins = 1000, RobuxLabel = "25 Rbx" },
	[3583241516] = { Coins = 2500, RobuxLabel = "50 Rbx" },
	[3583241515] = { Coins = 10000, RobuxLabel = "150 Rbx" },
}

-- Lay-up of products in the order we want the UI to render them.
local ORDER = { 3583241345, 3583241516, 3583241515 }

local receiptStore: DataStore? = nil
local ok, storeOrErr = pcall(function()
	return DataStoreService:GetDataStore("BentenganCoinReceipts_v1")
end)
if ok then
	receiptStore = storeOrErr
else
	warn("[CoinShop] receipt DataStore unavailable:", storeOrErr)
end

function CoinShop.getCatalog(): { { Id: number, Coins: number, RobuxLabel: string } }
	local list = {}
	for _, id in ORDER do
		local entry = PRODUCTS[id]
		if entry then
			table.insert(list, {
				Id = id,
				Coins = entry.Coins,
				RobuxLabel = entry.RobuxLabel,
			})
		end
	end
	return list
end

local function alreadyProcessed(receiptKey: string): boolean
	if not receiptStore then
		return false
	end
	local s, r = pcall(function()
		return receiptStore:GetAsync(receiptKey)
	end)
	if s and r == true then
		return true
	end
	return false
end

local function markProcessed(receiptKey: string)
	if not receiptStore then
		return
	end
	pcall(function()
		receiptStore:SetAsync(receiptKey, true)
	end)
end

-- Wired up via MarketplaceService.ProcessReceipt in init.server.lua.
function CoinShop.processReceipt(info)
	local product = PRODUCTS[info.ProductId]
	if not product then
		-- Unknown product: tell Roblox to retry later (developer fix needed).
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local receiptKey = string.format("%d:%s", info.PlayerId, info.PurchaseId)
	if alreadyProcessed(receiptKey) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		-- Player left mid-purchase. Defer; Roblox retries after they return.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Grant coins through the canonical path so leaderstats/CoinsUpdate fire.
	DataService.addCoins(player, product.Coins)
	-- Persist immediately so a crash doesn't lose the purchase.
	pcall(function()
		DataService.save(player)
	end)

	markProcessed(receiptKey)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function CoinShop.promptPurchase(player: Player, productId: number): boolean
	if not PRODUCTS[productId] then
		return false
	end
	local s, err = pcall(function()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)
	if not s then
		warn("[CoinShop] PromptProductPurchase failed:", err)
		return false
	end
	return true
end

return CoinShop
