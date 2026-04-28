--!strict
-- Procedurally generates 4 lobby arenas placed far apart in Workspace.
-- Each arena has: floor, walls, two bases/benteng, two jails, spawn pads, safe zones.

local Workspace = game:GetService("Workspace")
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))

local MapGenerator = {}

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

local ARENA_SPACING = 500 -- studs between arenas
local ARENA_SIZE = Vector3.new(240, 1, 200)

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

local function label(parent: BasePart, text: string, color: Color3)
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 220, 0, 60)
	bg.StudsOffset = Vector3.new(0, 6, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 500
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

function MapGenerator.buildArena(index: number): ArenaData
	local origin = Vector3.new((index - 1) * ARENA_SPACING, 50, 0)

	local model = Instance.new("Model")
	model.Name = "Arena_" .. index
	model.Parent = Workspace

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

	local function makeZone(name: string, pos: Vector3, size: Vector3, color: Color3): BasePart
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

	local redColor = GameConfig.Teams.Red.Color
	local blueColor = GameConfig.Teams.Blue.Color

	-- Bases (benteng): a tall pillar inside each team's side
	local baseSize = Vector3.new(14, 16, 14)
	local redBase = makePart({
		Name = "RedBase",
		Size = baseSize,
		CFrame = CFrame.new(origin + Vector3.new(-halfX + 20, baseSize.Y / 2 + 0.5, 0)),
		Color = redColor,
		Material = Enum.Material.Neon,
		Transparency = 0.2,
	})
	redBase.Parent = model
	label(redBase, "RED BASE", redColor)

	local blueBase = makePart({
		Name = "BlueBase",
		Size = baseSize,
		CFrame = CFrame.new(origin + Vector3.new(halfX - 20, baseSize.Y / 2 + 0.5, 0)),
		Color = blueColor,
		Material = Enum.Material.Neon,
		Transparency = 0.2,
	})
	blueBase.Parent = model
	label(blueBase, "BLUE BASE", blueColor)

	-- Safe zones around each base (larger footprint, floating plate)
	local redSafe = makeZone("RedSafeZone", Vector3.new(-halfX + 20, 0.6, 0), Vector3.new(40, 1, 40), redColor)
	local blueSafe = makeZone("BlueSafeZone", Vector3.new(halfX - 20, 0.6, 0), Vector3.new(40, 1, 40), blueColor)

	-- Jails (penjara) - opposite side of base for each team
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
		Color = redColor,
		Material = Enum.Material.Neon,
	})
	redSpawn.Parent = model
	local blueSpawn = makePart({
		Name = "BlueSpawn",
		Size = Vector3.new(8, 1, 8),
		CFrame = CFrame.new(origin + Vector3.new(halfX - 20, 1.1, 20)),
		Color = blueColor,
		Material = Enum.Material.Neon,
	})
	blueSpawn.Parent = model

	-- Lobby spawn (where players wait before match)
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

	return {
		Model = model,
		RedSpawn = redSpawn,
		BlueSpawn = blueSpawn,
		RedBase = redBase,
		BlueBase = blueBase,
		RedJail = redJail,
		BlueJail = blueJail,
		RedSafeZone = redSafe,
		BlueSafeZone = blueSafe,
		LobbySpawn = lobbySpawn,
	}
end

function MapGenerator.buildAll(): { ArenaData }
	local arenas = {}
	for i = 1, GameConfig.NumLobbies do
		arenas[i] = MapGenerator.buildArena(i)
	end
	return arenas
end

return MapGenerator
