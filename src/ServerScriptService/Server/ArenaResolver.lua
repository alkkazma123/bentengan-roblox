--!strict
-- Reads the 4 arena layouts from workspace.Arenas.Arena_X. These parts are
-- created via tools/SetupArenas.lua (one-time Command Bar script) so the
-- level designer can move / restyle them freely in Studio without them being
-- regenerated at runtime.
--
-- Each Arena_X Model must contain direct children named:
--   RedSpawn, BlueSpawn, RedBase, BlueBase, RedJail, BlueJail,
--   RedSafeZone, BlueSafeZone, LobbySpawn
-- All as BaseParts.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local ArenaResolver = {}

export type ArenaData = {
	Model: Model,
	RedSpawn: BasePart,
	BlueSpawn: BasePart,
	RedBase: BasePart,
	BlueBase: BasePart,
	RedJail: BasePart,
	BlueJail: BasePart,
	RedSafeZone: BasePart,
	BlueSafeZone: BasePart,
	LobbySpawn: BasePart,
}

local REQUIRED_PARTS = {
	"RedSpawn",
	"BlueSpawn",
	"RedBase",
	"BlueBase",
	"RedJail",
	"BlueJail",
	"RedSafeZone",
	"BlueSafeZone",
	"LobbySpawn",
}

local function resolveArena(index: number): ArenaData?
	local folder = Workspace:FindFirstChild("Arenas")
	if not folder then
		return nil
	end
	local arena = folder:FindFirstChild("Arena_" .. index)
	if not arena or not arena:IsA("Model") then
		return nil
	end
	local data: { [string]: any } = { Model = arena }
	for _, name in REQUIRED_PARTS do
		local inst = arena:FindFirstChild(name)
		if not inst or not inst:IsA("BasePart") then
			warn(
				string.format(
					"[ArenaResolver] Arena_%d missing required BasePart '%s'. Run tools/SetupArenas.lua.",
					index,
					name
				)
			)
			return nil
		end
		data[name] = inst
	end
	return data :: ArenaData
end

function ArenaResolver.resolveAll(): { ArenaData }
	local arenas: { ArenaData } = {}
	for i = 1, GameConfig.NumLobbies do
		local a = resolveArena(i)
		if not a then
			error(
				string.format(
					"[ArenaResolver] Arena_%d tidak ditemukan di workspace.Arenas.\n"
						.. "==> Jalankan tools/SetupArenas.lua sekali di Command Bar Studio (edit mode) "
						.. "dan simpan place file.",
					i
				)
			)
		end
		arenas[i] = a
	end
	return arenas
end

function ArenaResolver.isReady(): boolean
	for i = 1, GameConfig.NumLobbies do
		if not resolveArena(i) then
			return false
		end
	end
	return true
end

return ArenaResolver
