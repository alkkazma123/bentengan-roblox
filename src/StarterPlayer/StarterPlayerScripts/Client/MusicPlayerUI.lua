--[[
	MusicPlayerUI - Spotify-like music player
]]

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MusicList = require(Shared:WaitForChild("MusicList"))

local MusicPlayerUI = {}

local playlist = {}
local currentIndex = 0
local sound = nil
local isPlaying = false
local isShuffling = MusicList.DefaultShuffle
local isLooping = MusicList.DefaultLoop
local volume = MusicList.DefaultVolume

local titleLabel = nil
local artistLabel = nil
local playBtn = nil
local progressFill = nil

local function loadPlaylist()
	playlist = {}
	for _, song in ipairs(MusicList.Songs) do
		table.insert(playlist, song)
	end
	local folder = ReplicatedStorage:FindFirstChild("Music")
	if folder then
		for _, s in ipairs(folder:GetChildren()) do
			if s:IsA("Sound") then
				table.insert(playlist, {
					id = s.SoundId,
					title = s.Name,
					artist = "Unknown",
				})
			end
		end
	end
end

local function updateUI()
	if #playlist == 0 then
		if titleLabel then
			titleLabel.Text = "No songs"
		end
		if artistLabel then
			artistLabel.Text = "Add songs to MusicList or Music folder"
		end
		return
	end
	local song = playlist[currentIndex]
	if titleLabel then
		titleLabel.Text = song and song.title or ""
	end
	if artistLabel then
		artistLabel.Text = song and song.artist or ""
	end
	if playBtn then
		playBtn.Text = if isPlaying then "||" else ">"
	end
end

local function playSong(index)
	if #playlist == 0 then
		return
	end
	if index < 1 then
		index = #playlist
	end
	if index > #playlist then
		index = 1
	end
	currentIndex = index

	if sound then
		sound:Stop()
		sound:Destroy()
	end

	sound = Instance.new("Sound")
	sound.SoundId = playlist[currentIndex].id
	sound.Volume = volume
	sound.PlaybackSpeed = playlist[currentIndex].speed or 1
	sound.Parent = SoundService
	sound:Play()
	isPlaying = true

	sound.Ended:Connect(function()
		if isLooping then
			if isShuffling then
				playSong(math.random(1, #playlist))
			else
				playSong(currentIndex + 1)
			end
		else
			isPlaying = false
			updateUI()
		end
	end)

	updateUI()
end

function MusicPlayerUI.Init(frame)
	loadPlaylist()

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 25)
	title.BackgroundTransparency = 1
	title.Text = "MUSIC"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	title.ZIndex = 6

	-- Now playing area
	titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 20)
	titleLabel.Position = UDim2.new(0, 10, 0, 35)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = ""
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 13
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.Parent = frame
	titleLabel.ZIndex = 6

	artistLabel = Instance.new("TextLabel")
	artistLabel.Size = UDim2.new(1, -20, 0, 16)
	artistLabel.Position = UDim2.new(0, 10, 0, 55)
	artistLabel.BackgroundTransparency = 1
	artistLabel.Text = ""
	artistLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	artistLabel.TextSize = 11
	artistLabel.Font = Enum.Font.Gotham
	artistLabel.TextXAlignment = Enum.TextXAlignment.Left
	artistLabel.TextTruncate = Enum.TextTruncate.AtEnd
	artistLabel.Parent = frame
	artistLabel.ZIndex = 6

	-- Progress bar
	local progressBg = Instance.new("Frame")
	progressBg.Size = UDim2.new(1, -20, 0, 4)
	progressBg.Position = UDim2.new(0, 10, 0, 78)
	progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	progressBg.Parent = frame
	progressBg.ZIndex = 6

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(1, 0)
	progressCorner.Parent = progressBg

	progressFill = Instance.new("Frame")
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	progressFill.Parent = progressBg
	progressFill.ZIndex = 7

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = progressFill

	-- Controls
	local controlY = 92
	local btnSize = 36

	local prevBtn = Instance.new("TextButton")
	prevBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
	prevBtn.Position = UDim2.new(0.5, -60, 0, controlY)
	prevBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	prevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	prevBtn.Text = "<<"
	prevBtn.TextSize = 14
	prevBtn.Font = Enum.Font.GothamBold
	prevBtn.Parent = frame
	prevBtn.ZIndex = 6
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(1, 0)
	pc.Parent = prevBtn

	playBtn = Instance.new("TextButton")
	playBtn.Size = UDim2.new(0, btnSize + 8, 0, btnSize + 8)
	playBtn.Position = UDim2.new(0.5, -(btnSize + 8) / 2, 0, controlY - 4)
	playBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
	playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	playBtn.Text = ">"
	playBtn.TextSize = 18
	playBtn.Font = Enum.Font.GothamBold
	playBtn.Parent = frame
	playBtn.ZIndex = 6
	local plc = Instance.new("UICorner")
	plc.CornerRadius = UDim.new(1, 0)
	plc.Parent = playBtn

	local nextBtn = Instance.new("TextButton")
	nextBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
	nextBtn.Position = UDim2.new(0.5, 24, 0, controlY)
	nextBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	nextBtn.Text = ">>"
	nextBtn.TextSize = 14
	nextBtn.Font = Enum.Font.GothamBold
	nextBtn.Parent = frame
	nextBtn.ZIndex = 6
	local nc = Instance.new("UICorner")
	nc.CornerRadius = UDim.new(1, 0)
	nc.Parent = nextBtn

	-- Shuffle / Loop
	local shuffleBtn = Instance.new("TextButton")
	shuffleBtn.Size = UDim2.new(0, 30, 0, 30)
	shuffleBtn.Position = UDim2.new(0.5, -100, 0, controlY + 3)
	shuffleBtn.BackgroundTransparency = 1
	shuffleBtn.TextColor3 = if isShuffling then Color3.fromRGB(0, 200, 100) else Color3.fromRGB(120, 120, 120)
	shuffleBtn.Text = "SH"
	shuffleBtn.TextSize = 10
	shuffleBtn.Font = Enum.Font.GothamBold
	shuffleBtn.Parent = frame
	shuffleBtn.ZIndex = 6

	local loopBtn = Instance.new("TextButton")
	loopBtn.Size = UDim2.new(0, 30, 0, 30)
	loopBtn.Position = UDim2.new(0.5, 70, 0, controlY + 3)
	loopBtn.BackgroundTransparency = 1
	loopBtn.TextColor3 = if isLooping then Color3.fromRGB(0, 200, 100) else Color3.fromRGB(120, 120, 120)
	loopBtn.Text = "LP"
	loopBtn.TextSize = 10
	loopBtn.Font = Enum.Font.GothamBold
	loopBtn.Parent = frame
	loopBtn.ZIndex = 6

	-- Volume
	local volBg = Instance.new("Frame")
	volBg.Size = UDim2.new(0.6, 0, 0, 6)
	volBg.Position = UDim2.new(0.2, 0, 0, 140)
	volBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	volBg.Parent = frame
	volBg.ZIndex = 6

	local volCorner = Instance.new("UICorner")
	volCorner.CornerRadius = UDim.new(1, 0)
	volCorner.Parent = volBg

	local volFill = Instance.new("Frame")
	volFill.Size = UDim2.new(volume, 0, 1, 0)
	volFill.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
	volFill.Parent = volBg
	volFill.ZIndex = 7

	local volFillCorner = Instance.new("UICorner")
	volFillCorner.CornerRadius = UDim.new(1, 0)
	volFillCorner.Parent = volFill

	local volLabel = Instance.new("TextLabel")
	volLabel.Size = UDim2.new(0.2, 0, 0, 14)
	volLabel.Position = UDim2.new(0, 0, 0, 137)
	volLabel.BackgroundTransparency = 1
	volLabel.Text = "VOL"
	volLabel.TextSize = 9
	volLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	volLabel.Font = Enum.Font.Gotham
	volLabel.Parent = frame
	volLabel.ZIndex = 6

	volBg.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local relX = (input.Position.X - volBg.AbsolutePosition.X) / volBg.AbsoluteSize.X
			volume = math.clamp(relX, 0, 1)
			volFill.Size = UDim2.new(volume, 0, 1, 0)
			if sound then
				sound.Volume = volume
			end
		end
	end)

	-- Song queue list
	local queueScroll = Instance.new("ScrollingFrame")
	queueScroll.Size = UDim2.new(1, -10, 1, -160)
	queueScroll.Position = UDim2.new(0, 5, 0, 155)
	queueScroll.BackgroundTransparency = 1
	queueScroll.ScrollBarThickness = 3
	queueScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	queueScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	queueScroll.Parent = frame
	queueScroll.ZIndex = 6

	local queueLayout = Instance.new("UIListLayout")
	queueLayout.Padding = UDim.new(0, 3)
	queueLayout.Parent = queueScroll

	for i, song in ipairs(playlist) do
		local songBtn = Instance.new("TextButton")
		songBtn.Size = UDim2.new(1, 0, 0, 28)
		songBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
		songBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
		songBtn.Text = "  " .. song.title .. " - " .. song.artist
		songBtn.TextSize = 10
		songBtn.Font = Enum.Font.Gotham
		songBtn.TextXAlignment = Enum.TextXAlignment.Left
		songBtn.TextTruncate = Enum.TextTruncate.AtEnd
		songBtn.Parent = queueScroll
		songBtn.ZIndex = 7

		local sc = Instance.new("UICorner")
		sc.CornerRadius = UDim.new(0, 6)
		sc.Parent = songBtn

		local idx = i
		songBtn.MouseButton1Click:Connect(function()
			playSong(idx)
		end)
	end

	-- Button actions
	playBtn.MouseButton1Click:Connect(function()
		if #playlist == 0 then
			return
		end
		if isPlaying then
			if sound then
				sound:Pause()
			end
			isPlaying = false
		else
			if currentIndex == 0 then
				playSong(1)
				return
			end
			if sound then
				sound:Resume()
			end
			isPlaying = true
		end
		updateUI()
	end)

	prevBtn.MouseButton1Click:Connect(function()
		if #playlist == 0 then
			return
		end
		playSong(currentIndex - 1)
	end)

	nextBtn.MouseButton1Click:Connect(function()
		if #playlist == 0 then
			return
		end
		if isShuffling then
			playSong(math.random(1, #playlist))
		else
			playSong(currentIndex + 1)
		end
	end)

	shuffleBtn.MouseButton1Click:Connect(function()
		isShuffling = not isShuffling
		shuffleBtn.TextColor3 = if isShuffling then Color3.fromRGB(0, 200, 100) else Color3.fromRGB(120, 120, 120)
	end)

	loopBtn.MouseButton1Click:Connect(function()
		isLooping = not isLooping
		loopBtn.TextColor3 = if isLooping then Color3.fromRGB(0, 200, 100) else Color3.fromRGB(120, 120, 120)
	end)

	-- Progress updater
	task.spawn(function()
		while true do
			task.wait(0.5)
			if sound and isPlaying and sound.TimeLength > 0 then
				local pct = sound.TimePosition / sound.TimeLength
				if progressFill then
					progressFill.Size = UDim2.new(pct, 0, 1, 0)
				end
			end
		end
	end)

	updateUI()
end

return MusicPlayerUI
