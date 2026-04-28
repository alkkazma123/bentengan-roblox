-- ======================================================================
-- SetupArenas.lua
-- ======================================================================
-- Run this script ONCE in Roblox Studio's Command Bar (View -> Command Bar)
-- while in EDIT MODE (not play mode). It will create four arenas under
-- workspace.Arenas as PERSISTENT instances - after you save the place file
-- these parts stay forever and you can move / resize / restyle them freely
-- in Studio (they are not regenerated at runtime).
--
-- Instructions:
--   1. Make sure you are NOT running the game (F5 is not active).
--   2. Open the Command Bar: View menu -> Command Bar.
--   3. Copy the ENTIRE contents of this file and paste into the Command Bar.
--   4. Press Enter.
--   5. A folder "Arenas" with Arena_1..Arena_4 appears in Workspace.
--   6. Press Ctrl+S to save the place.
--
-- To rebuild from scratch: delete workspace.Arenas and run this script again.
-- ======================================================================

local Workspace = game:GetService("Workspace")

local NUM_ARENAS = 4
local ARENA_SPACING = 500
local ARENA_SIZE = Vector3.new(240, 1, 200)

local RED_COLOR = Color3.fromRGB(225, 70, 70)
local BLUE_COLOR = Color3.fromRGB(70, 130, 225)

if Workspace:FindFirstChild("Arenas") then
	warn("[SetupArenas] workspace.Arenas already exists - delete it first if you want to rebuild.")
	return
end

local arenasFolder = Instance.new("Folder")
arenasFolder.Name = "Arenas"
arenasFolder.Parent = Workspace

local function makePart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end

local function label(parent, text, color)
	local bg = Instance.new("BillboardGui")
	bg.Name = "NameLabel"
	bg.Size = UDim2.new(0, 220, 0, 60)
	bg.StudsOffset = Vector3.new(0, 6, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 60 -- only visible when close
	bg.Parent = parent
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.TextColor3 = color
	tl.TextStrokeTransparency = 0.2
	tl.Font = Enum.Font.GothamBold
	tl.TextScaled = true
	tl.Text = text
	tl.Parent = bg
end

local function buildArena(index)
	local origin = Vector3.new((index - 1) * ARENA_SPACING, 50, 0)

	local model = Instance.new("Model")
	model.Name = "Arena_" .. index
	model.Parent = arenasFolder

	-- Floor
	local floor = makePart({
		Name = "Floor",
		Size = ARENA_SIZE,
		CFrame = CFrame.new(origin),
		Color = Color3.fromRGB(55, 60, 72),
		Material = Enum.Material.Slate,
	})
	floor.Parent = model

	-- Mid line
	local mid = makePart({
		Name = "MidLine",
		Size = Vector3.new(2, 2, ARENA_SIZE.Z),
		CFrame = CFrame.new(origin + Vector3.new(0, 1.5, 0)),
		Color = Color3.fromRGB(230, 230, 230),
		Transparency = 0.3,
		CanCollide = false,
	})
	mid.Parent = model

	-- Outer walls
	local wallHeight = 14
	local wallThickness = 2
	local halfX = ARENA_SIZE.X / 2
	local halfZ = ARENA_SIZE.Z / 2
	local walls = {
		{ pos = Vector3.new(0, wallHeight / 2, halfZ), size = Vector3.new(ARENA_SIZE.X, wallHeight, wallThickness) },
		{ pos = Vector3.new(0, wallHeight / 2, -halfZ), size = Vector3.new(ARENA_SIZE.X, wallHeight, wallThickness) },
		{ pos = Vector3.new(halfX, wallHeight / 2, 0), size = Vector3.new(wallThickness, wallHeight, ARENA_SIZE.Z) },
		{ pos = Vector3.new(-halfX, wallHeight / 2, 0), size = Vector3.new(wallThickness, wallHeight, ARENA_SIZE.Z) },
	}
	for i, w in ipairs(walls) do
		local wall = makePart({
			Name = "Wall_" .. i,
			Size = w.size,
			CFrame = CFrame.new(origin + w.pos),
			Color = Color3.fromRGB(40, 44, 54),
			Transparency = 0.35,
		})
		wall.Parent = model
	end

	local function makeZone(name, pos, size, color)
		local z = makePart({
			Name = name,
			Size = size,
			CFrame = CFrame.new(origin + pos),
			Color = color,
			Transparency = 0.7,
			CanCollide = false,
			Material = Enum.Material.Neon,
		})
		z.Parent = model
		return z
	end

	-- Bases (benteng)
	local baseSize = Vector3.new(14, 16, 14)
	local redBase = makePart({
		Name = "RedBase",
		Size = baseSize,
		CFrame = CFrame.new(origin + Vector3.new(-halfX + 20, baseSize.Y / 2 + 0.5, 0)),
		Color = RED_COLOR,
		Material = Enum.Material.Neon,
		Transparency = 0.2,
	})
	redBase.Parent = model
	label(redBase, "RED BASE", RED_COLOR)

	local blueBase = makePart({
		Name = "BlueBase",
		Size = baseSize,
		CFrame = CFrame.new(origin + Vector3.new(halfX - 20, baseSize.Y / 2 + 0.5, 0)),
		Color = BLUE_COLOR,
		Material = Enum.Material.Neon,
		Transparency = 0.2,
	})
	blueBase.Parent = model
	label(blueBase, "BLUE BASE", BLUE_COLOR)

	-- Safe zones
	makeZone("RedSafeZone", Vector3.new(-halfX + 20, 0.6, 0), Vector3.new(40, 1, 40), RED_COLOR)
	makeZone("BlueSafeZone", Vector3.new(halfX - 20, 0.6, 0), Vector3.new(40, 1, 40), BLUE_COLOR)

	-- Jails
	local jailSize = Vector3.new(16, 10, 16)
	local redJail = makePart({
		Name = "RedJail",
		Size = jailSize,
		CFrame = CFrame.new(origin + Vector3.new(-halfX + 20, jailSize.Y / 2 + 0.5, halfZ - 20)),
		Color = Color3.fromRGB(90, 95, 110),
		Transparency = 0.5,
		Material = Enum.Material.ForceField,
	})
	redJail.Parent = model
	label(redJail, "RED JAIL", Color3.fromRGB(230, 230, 230))

	local blueJail = makePart({
		Name = "BlueJail",
		Size = jailSize,
		CFrame = CFrame.new(origin + Vector3.new(halfX - 20, jailSize.Y / 2 + 0.5, -halfZ + 20)),
		Color = Color3.fromRGB(90, 95, 110),
		Transparency = 0.5,
		Material = Enum.Material.ForceField,
	})
	blueJail.Parent = model
	label(blueJail, "BLUE JAIL", Color3.fromRGB(230, 230, 230))

	-- Spawn pads
	local redSpawn = makePart({
		Name = "RedSpawn",
		Size = Vector3.new(8, 1, 8),
		CFrame = CFrame.new(origin + Vector3.new(-halfX + 20, 1.1, -20)),
		Color = RED_COLOR,
		Material = Enum.Material.Neon,
	})
	redSpawn.Parent = model

	local blueSpawn = makePart({
		Name = "BlueSpawn",
		Size = Vector3.new(8, 1, 8),
		CFrame = CFrame.new(origin + Vector3.new(halfX - 20, 1.1, 20)),
		Color = BLUE_COLOR,
		Material = Enum.Material.Neon,
	})
	blueSpawn.Parent = model

	-- Lobby spawn pad (where players wait before match)
	local lobbySpawn = makePart({
		Name = "LobbySpawn",
		Size = Vector3.new(24, 1, 24),
		CFrame = CFrame.new(origin + Vector3.new(0, 30, -halfZ - 40)),
		Color = Color3.fromRGB(80, 85, 100),
		Material = Enum.Material.Neon,
		Transparency = 0.2,
	})
	lobbySpawn.Parent = model
	label(lobbySpawn, "LOBBY " .. index, Color3.fromRGB(255, 255, 255))

	print(string.format("[SetupArenas] Built Arena_%d at %s", index, tostring(origin)))
end

for i = 1, NUM_ARENAS do
	buildArena(i)
end

print(string.format("[SetupArenas] Done! Created %d arenas in workspace.Arenas. Press Ctrl+S to save.", NUM_ARENAS))
