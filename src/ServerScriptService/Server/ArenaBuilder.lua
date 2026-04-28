--!strict
-- Procedural builder for a single bentengan arena. Shared by:
--   * ArenaResolver.lua - runtime fallback when workspace.Arenas is missing
--   * tools/SetupArenas.lua - one-time Command Bar script that materialises
--     these parts as persistent, hand-editable Studio instances.
--
-- Arena layout (local coordinates relative to origin):
--   +X  -> Blue side
--   -X  -> Red side
--   +Z  -> jail axis (walls left/right)
-- Each arena is centered on origin and uses ARENA_SIZE for its floor.

local ArenaBuilder = {}

local ARENA_SIZE = Vector3.new(240, 1, 200)
local ARENA_SPACING = 500

local RED_COLOR = Color3.fromRGB(225, 70, 70)
local BLUE_COLOR = Color3.fromRGB(70, 130, 225)

local function makePart(props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

local function addLabel(parent: Instance, text: string, color: Color3)
	local bg = Instance.new("BillboardGui")
	bg.Name = "NameLabel"
	bg.Size = UDim2.new(0, 220, 0, 60)
	bg.StudsOffset = Vector3.new(0, 6, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 60
	bg.Parent = parent
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.TextColor3 = color
	tl.TextStrokeTransparency = 0.2
	tl.Font = Enum.Font.GothamBold
	tl.TextScaled = true
	tl.Text = text
	tl.Parent = bg
end

function ArenaBuilder.originFor(index: number): Vector3
	return Vector3.new((index - 1) * ARENA_SPACING, 50, 0)
end

-- Neutral waiting area where players spawn before they pick a lobby. Placed
-- away from the arenas so neither lobby nor match traffic interferes.
function ArenaBuilder.buildWorldSpawn(parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "WorldSpawn"

	local origin = Vector3.new(0, 80, -320)

	local floor = makePart({
		Name = "Floor",
		Size = Vector3.new(80, 2, 80),
		CFrame = CFrame.new(origin),
		Color = Color3.fromRGB(46, 52, 68),
		Material = Enum.Material.SmoothPlastic,
	})
	floor.Parent = model

	local rim = makePart({
		Name = "Rim",
		Size = Vector3.new(82, 1, 82),
		CFrame = CFrame.new(origin + Vector3.new(0, -1, 0)),
		Color = Color3.fromRGB(120, 170, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.5,
	})
	rim.Parent = model

	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "SpawnLocation"
	spawnLoc.Size = Vector3.new(12, 1, 12)
	spawnLoc.CFrame = CFrame.new(origin + Vector3.new(0, 1.5, 0))
	spawnLoc.Anchored = true
	spawnLoc.CanCollide = true
	spawnLoc.Color = Color3.fromRGB(120, 170, 255)
	spawnLoc.Material = Enum.Material.Neon
	spawnLoc.TopSurface = Enum.SurfaceType.Smooth
	spawnLoc.BottomSurface = Enum.SurfaceType.Smooth
	spawnLoc.AllowTeamChangeOnTouch = false
	spawnLoc.Neutral = true
	spawnLoc.Parent = model

	addLabel(spawnLoc, "BENTENGAN LOBBY", Color3.fromRGB(255, 255, 255))

	model.Parent = parent
	return model
end

function ArenaBuilder.build(index: number, parent: Instance): Model
	local origin = ArenaBuilder.originFor(index)
	local model = Instance.new("Model")
	model.Name = "Arena_" .. index

	local floor = makePart({
		Name = "Floor",
		Size = ARENA_SIZE,
		CFrame = CFrame.new(origin),
		Color = Color3.fromRGB(55, 60, 72),
		Material = Enum.Material.Slate,
	})
	floor.Parent = model

	local mid = makePart({
		Name = "MidLine",
		Size = Vector3.new(2, 2, ARENA_SIZE.Z),
		CFrame = CFrame.new(origin + Vector3.new(0, 1.5, 0)),
		Color = Color3.fromRGB(230, 230, 230),
		Transparency = 0.3,
		CanCollide = false,
	})
	mid.Parent = model

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
	for i, w in walls do
		local wall = makePart({
			Name = "Wall_" .. i,
			Size = w.size,
			CFrame = CFrame.new(origin + w.pos),
			Color = Color3.fromRGB(40, 44, 54),
			Transparency = 0.35,
		})
		wall.Parent = model
	end

	local function zone(name: string, pos: Vector3, size: Vector3, color: Color3)
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
	end

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
	addLabel(redBase, "RED BASE", RED_COLOR)

	local blueBase = makePart({
		Name = "BlueBase",
		Size = baseSize,
		CFrame = CFrame.new(origin + Vector3.new(halfX - 20, baseSize.Y / 2 + 0.5, 0)),
		Color = BLUE_COLOR,
		Material = Enum.Material.Neon,
		Transparency = 0.2,
	})
	blueBase.Parent = model
	addLabel(blueBase, "BLUE BASE", BLUE_COLOR)

	zone("RedSafeZone", Vector3.new(-halfX + 20, 0.6, 0), Vector3.new(40, 1, 40), RED_COLOR)
	zone("BlueSafeZone", Vector3.new(halfX - 20, 0.6, 0), Vector3.new(40, 1, 40), BLUE_COLOR)

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
	addLabel(redJail, "RED JAIL", Color3.fromRGB(230, 230, 230))

	local blueJail = makePart({
		Name = "BlueJail",
		Size = jailSize,
		CFrame = CFrame.new(origin + Vector3.new(halfX - 20, jailSize.Y / 2 + 0.5, -halfZ + 20)),
		Color = Color3.fromRGB(90, 95, 110),
		Transparency = 0.5,
		Material = Enum.Material.ForceField,
	})
	blueJail.Parent = model
	addLabel(blueJail, "BLUE JAIL", Color3.fromRGB(230, 230, 230))

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

	local lobbySpawn = makePart({
		Name = "LobbySpawn",
		Size = Vector3.new(24, 1, 24),
		CFrame = CFrame.new(origin + Vector3.new(0, 30, -halfZ - 40)),
		Color = Color3.fromRGB(80, 85, 100),
		Material = Enum.Material.Neon,
		Transparency = 0.2,
	})
	lobbySpawn.Parent = model
	addLabel(lobbySpawn, "LOBBY " .. index, Color3.fromRGB(255, 255, 255))

	model.Parent = parent
	return model
end

return ArenaBuilder
