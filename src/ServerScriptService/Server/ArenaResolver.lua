--!strict
-- Reads (or auto-builds) the 4 arena layouts at workspace.Arenas.Arena_X.
--
-- If the level designer has already materialised the arenas as persistent
-- Studio instances (via tools/SetupArenas.lua run once in edit mode), we use
-- those - they are fully hand-editable in Studio.
-- Otherwise we fall back to building them at server start via ArenaBuilder so
-- the game works out of the box without any manual setup step.
--
-- Each Arena_X Model must contain direct children named:
--   RedSpawn, BlueSpawn, RedBase, BlueBase, RedJail, BlueJail,
--   RedSafeZone, BlueSafeZone, LobbySpawn
-- All as BaseParts.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local ArenaBuilder = require(script.Parent:WaitForChild("ArenaBuilder"))

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

local function ensureFolder(): Folder
	local existing = Workspace:FindFirstChild("Arenas")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Arenas"
	folder.Parent = Workspace
	return folder
end

function ArenaResolver.resolveAll(): { ArenaData }
	local folder = ensureFolder()
	local arenas: { ArenaData } = {}
	local builtCount = 0
	for i = 1, GameConfig.NumLobbies do
		local a = resolveArena(i)
		if not a then
			-- Replace any partial arena and auto-build a fresh one.
			local existing = folder:FindFirstChild("Arena_" .. i)
			if existing then
				existing:Destroy()
			end
			ArenaBuilder.build(i, folder)
			builtCount += 1
			a = resolveArena(i)
			if not a then
				error(string.format("[ArenaResolver] Failed to build Arena_%d.", i))
			end
		end
		arenas[i] = a
	end
	if builtCount > 0 then
		print(
			string.format(
				"[ArenaResolver] Auto-generated %d arena(s). Run tools/SetupArenas.lua in Studio's "
					.. "Command Bar (edit mode) to make them persistent and hand-editable.",
				builtCount
			)
		)
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

-- Ensure a neutral world spawn exists. Returns the SpawnLocation basepart
-- players respawn at when not in a match.
function ArenaResolver.ensureWorldSpawn(): BasePart
	local folder = ensureFolder()
	local model = folder:FindFirstChild("WorldSpawn")
	if not model then
		-- Also sweep any stray top-level SpawnLocations that Roblox auto-creates
		-- for new places; we want the neutral lobby pad to be the only one.
		for _, inst in Workspace:GetChildren() do
			if inst:IsA("SpawnLocation") then
				inst:Destroy()
			end
		end
		model = ArenaBuilder.buildWorldSpawn(folder)
	end
	local spawnLoc = (model :: Instance):FindFirstChild("SpawnLocation")
	if not spawnLoc or not spawnLoc:IsA("BasePart") then
		error("[ArenaResolver] WorldSpawn is missing its SpawnLocation BasePart.")
	end
	return spawnLoc
end

return ArenaResolver
