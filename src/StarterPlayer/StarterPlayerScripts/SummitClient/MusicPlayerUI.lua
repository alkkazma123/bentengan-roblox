--[[
	MusicPlayerUI
	Spotify-like music player inside the phone menu.
	Supports play/pause, next, previous, shuffle, loop, volume, and song list.
	Reads from MusicList module and/or ReplicatedStorage.Music folder.
]]

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SummitShared = ReplicatedStorage:WaitForChild("SummitShared")
local MusicList = require(SummitShared:WaitForChild("MusicList"))

local MusicPlayerUI = {}

local sound = nil
local playlist = {}
local currentIndex = 1
local isPlaying = false
local isShuffle = MusicList.DefaultShuffle
local isLoop = MusicList.DefaultLoop
local volume = MusicList.DefaultVolume

-- UI refs
local titleLabel = nil
local artistLabel = nil
local playBtn = nil
local progressBar = nil
local progressFill = nil
local shuffleBtn = nil
local loopBtn = nil

local function loadPlaylist()
	playlist = {}
	-- From module
	for _, song in ipairs(MusicList.Songs) do
		table.insert(playlist, song)
	end
	-- From folder
	local musicFolder = ReplicatedStorage:FindFirstChild("Music")
	if musicFolder then
		for _, obj in ipairs(musicFolder:GetChildren()) do
			if obj:IsA("Sound") then
				table.insert(playlist, {
					id = obj.SoundId,
					title = obj.Name,
					artist = obj:GetAttribute("Artist") or "Unknown",
				})
			end
		end
	end
end

local function createSound()
	if sound then
		sound:Destroy()
	end
	sound = Instance.new("Sound")
	sound.Name = "SummitMusic"
	sound.Volume = volume
	sound.Parent = SoundService

	sound.Ended:Connect(function()
		if isLoop then
			MusicPlayerUI.Next()
		else
			isPlaying = false
			if playBtn then
				playBtn.Text = "▶"
			end
		end
	end)
end

local function updateNowPlaying()
	if #playlist == 0 then
		return
	end
	local song = playlist[currentIndex]
	if titleLabel then
		titleLabel.Text = song.title
	end
	if artistLabel then
		artistLabel.Text = song.artist
	end
end

local function updateProgress()
	if not sound or not progressFill then
		return
	end
	task.spawn(function()
		while sound and isPlaying do
			if sound.TimeLength > 0 then
				local progress = sound.TimePosition / sound.TimeLength
				progressFill.Size = UDim2.new(math.clamp(progress, 0, 1), 0, 1, 0)
			end
			task.wait(0.1)
		end
	end)
end

function MusicPlayerUI.Play()
	if #playlist == 0 then
		return
	end
	local song = playlist[currentIndex]
	if not sound then
		createSound()
	end
	sound.SoundId = song.id
	sound.Volume = volume
	sound:Play()
	isPlaying = true
	if playBtn then
		playBtn.Text = "⏸"
	end
	updateNowPlaying()
	updateProgress()
end

function MusicPlayerUI.Pause()
	if sound then
		sound:Pause()
	end
	isPlaying = false
	if playBtn then
		playBtn.Text = "▶"
	end
end

function MusicPlayerUI.TogglePlay()
	if isPlaying then
		MusicPlayerUI.Pause()
	else
		MusicPlayerUI.Play()
	end
end

function MusicPlayerUI.Next()
	if #playlist == 0 then
		return
	end
	if isShuffle then
		currentIndex = math.random(1, #playlist)
	else
		currentIndex = currentIndex + 1
		if currentIndex > #playlist then
			currentIndex = 1
		end
	end
	if isPlaying then
		MusicPlayerUI.Play()
	else
		updateNowPlaying()
	end
end

function MusicPlayerUI.Previous()
	if #playlist == 0 then
		return
	end
	currentIndex = currentIndex - 1
	if currentIndex < 1 then
		currentIndex = #playlist
	end
	if isPlaying then
		MusicPlayerUI.Play()
	else
		updateNowPlaying()
	end
end

function MusicPlayerUI.SetVolume(val)
	volume = math.clamp(val, 0, 1)
	if sound then
		sound.Volume = volume
	end
end

function MusicPlayerUI.Init(frame)
	loadPlaylist()
	createSound()

	-- Title
	local pageTitle = Instance.new("TextLabel")
	pageTitle.Name = "MusicTitle"
	pageTitle.Size = UDim2.new(1, 0, 0, 25)
	pageTitle.Position = UDim2.new(0, 0, 0, 5)
	pageTitle.BackgroundTransparency = 1
	pageTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	pageTitle.Text = "MUSIC"
	pageTitle.TextSize = 18
	pageTitle.Font = Enum.Font.GothamBold
	pageTitle.Parent = frame
	pageTitle.ZIndex = 6

	-- Album art placeholder
	local artFrame = Instance.new("Frame")
	artFrame.Name = "AlbumArt"
	artFrame.Size = UDim2.new(0, 150, 0, 150)
	artFrame.Position = UDim2.new(0.5, -75, 0, 40)
	artFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	artFrame.Parent = frame
	artFrame.ZIndex = 6

	local artCorner = Instance.new("UICorner")
	artCorner.CornerRadius = UDim.new(0, 12)
	artCorner.Parent = artFrame

	local artIcon = Instance.new("TextLabel")
	artIcon.Size = UDim2.new(1, 0, 1, 0)
	artIcon.BackgroundTransparency = 1
	artIcon.Text = "🎵"
	artIcon.TextSize = 48
	artIcon.Parent = artFrame
	artIcon.ZIndex = 7

	-- Song title
	titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "SongTitle"
	titleLabel.Size = UDim2.new(1, -20, 0, 22)
	titleLabel.Position = UDim2.new(0, 10, 0, 200)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Text = if #playlist > 0 then playlist[1].title else "No Songs"
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.Parent = frame
	titleLabel.ZIndex = 6

	-- Artist
	artistLabel = Instance.new("TextLabel")
	artistLabel.Name = "Artist"
	artistLabel.Size = UDim2.new(1, -20, 0, 18)
	artistLabel.Position = UDim2.new(0, 10, 0, 222)
	artistLabel.BackgroundTransparency = 1
	artistLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	artistLabel.Text = if #playlist > 0 then playlist[1].artist else ""
	artistLabel.TextSize = 13
	artistLabel.Font = Enum.Font.Gotham
	artistLabel.TextXAlignment = Enum.TextXAlignment.Center
	artistLabel.Parent = frame
	artistLabel.ZIndex = 6

	-- Progress bar
	progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(0.8, 0, 0, 4)
	progressBar.Position = UDim2.new(0.1, 0, 0, 250)
	progressBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = frame
	progressBar.ZIndex = 6

	local pbCorner = Instance.new("UICorner")
	pbCorner.CornerRadius = UDim.new(0.5, 0)
	pbCorner.Parent = progressBar

	progressFill = Instance.new("Frame")
	progressFill.Name = "Fill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = Color3.fromRGB(30, 215, 96)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBar
	progressFill.ZIndex = 7

	local pfCorner = Instance.new("UICorner")
	pfCorner.CornerRadius = UDim.new(0.5, 0)
	pfCorner.Parent = progressFill

	-- Controls
	local controlsFrame = Instance.new("Frame")
	controlsFrame.Name = "Controls"
	controlsFrame.Size = UDim2.new(0.8, 0, 0, 40)
	controlsFrame.Position = UDim2.new(0.1, 0, 0, 265)
	controlsFrame.BackgroundTransparency = 1
	controlsFrame.Parent = frame
	controlsFrame.ZIndex = 6

	-- Shuffle button
	shuffleBtn = Instance.new("TextButton")
	shuffleBtn.Name = "Shuffle"
	shuffleBtn.Size = UDim2.new(0, 35, 0, 35)
	shuffleBtn.Position = UDim2.new(0, 0, 0.5, -17)
	shuffleBtn.BackgroundTransparency = 1
	shuffleBtn.TextColor3 = if isShuffle then Color3.fromRGB(30, 215, 96) else Color3.fromRGB(150, 150, 150)
	shuffleBtn.Text = "🔀"
	shuffleBtn.TextSize = 18
	shuffleBtn.Parent = controlsFrame
	shuffleBtn.ZIndex = 7

	shuffleBtn.MouseButton1Click:Connect(function()
		isShuffle = not isShuffle
		shuffleBtn.TextColor3 = if isShuffle then Color3.fromRGB(30, 215, 96) else Color3.fromRGB(150, 150, 150)
	end)

	-- Previous button
	local prevBtn = Instance.new("TextButton")
	prevBtn.Name = "Prev"
	prevBtn.Size = UDim2.new(0, 35, 0, 35)
	prevBtn.Position = UDim2.new(0.2, 0, 0.5, -17)
	prevBtn.BackgroundTransparency = 1
	prevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	prevBtn.Text = "⏮"
	prevBtn.TextSize = 22
	prevBtn.Parent = controlsFrame
	prevBtn.ZIndex = 7

	prevBtn.MouseButton1Click:Connect(function()
		MusicPlayerUI.Previous()
	end)

	-- Play/Pause button
	playBtn = Instance.new("TextButton")
	playBtn.Name = "PlayPause"
	playBtn.Size = UDim2.new(0, 45, 0, 45)
	playBtn.Position = UDim2.new(0.5, -22, 0.5, -22)
	playBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	playBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	playBtn.Text = "▶"
	playBtn.TextSize = 22
	playBtn.Font = Enum.Font.GothamBold
	playBtn.Parent = controlsFrame
	playBtn.ZIndex = 7

	local playCorner = Instance.new("UICorner")
	playCorner.CornerRadius = UDim.new(0.5, 0)
	playCorner.Parent = playBtn

	playBtn.MouseButton1Click:Connect(function()
		MusicPlayerUI.TogglePlay()
	end)

	-- Next button
	local nextBtn = Instance.new("TextButton")
	nextBtn.Name = "Next"
	nextBtn.Size = UDim2.new(0, 35, 0, 35)
	nextBtn.Position = UDim2.new(0.75, 0, 0.5, -17)
	nextBtn.BackgroundTransparency = 1
	nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	nextBtn.Text = "⏭"
	nextBtn.TextSize = 22
	nextBtn.Parent = controlsFrame
	nextBtn.ZIndex = 7

	nextBtn.MouseButton1Click:Connect(function()
		MusicPlayerUI.Next()
	end)

	-- Loop button
	loopBtn = Instance.new("TextButton")
	loopBtn.Name = "Loop"
	loopBtn.Size = UDim2.new(0, 35, 0, 35)
	loopBtn.Position = UDim2.new(1, -35, 0.5, -17)
	loopBtn.BackgroundTransparency = 1
	loopBtn.TextColor3 = if isLoop then Color3.fromRGB(30, 215, 96) else Color3.fromRGB(150, 150, 150)
	loopBtn.Text = "🔁"
	loopBtn.TextSize = 18
	loopBtn.Parent = controlsFrame
	loopBtn.ZIndex = 7

	loopBtn.MouseButton1Click:Connect(function()
		isLoop = not isLoop
		loopBtn.TextColor3 = if isLoop then Color3.fromRGB(30, 215, 96) else Color3.fromRGB(150, 150, 150)
	end)

	-- Volume slider
	local volumeFrame = Instance.new("Frame")
	volumeFrame.Name = "VolumeFrame"
	volumeFrame.Size = UDim2.new(0.7, 0, 0, 20)
	volumeFrame.Position = UDim2.new(0.15, 0, 0, 320)
	volumeFrame.BackgroundTransparency = 1
	volumeFrame.Parent = frame
	volumeFrame.ZIndex = 6

	local volLabel = Instance.new("TextLabel")
	volLabel.Size = UDim2.new(0, 20, 1, 0)
	volLabel.BackgroundTransparency = 1
	volLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	volLabel.Text = "🔊"
	volLabel.TextSize = 14
	volLabel.Parent = volumeFrame
	volLabel.ZIndex = 7

	local volBar = Instance.new("Frame")
	volBar.Name = "VolBar"
	volBar.Size = UDim2.new(1, -30, 0, 4)
	volBar.Position = UDim2.new(0, 25, 0.5, -2)
	volBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	volBar.BorderSizePixel = 0
	volBar.Parent = volumeFrame
	volBar.ZIndex = 7

	local volBarCorner = Instance.new("UICorner")
	volBarCorner.CornerRadius = UDim.new(0.5, 0)
	volBarCorner.Parent = volBar

	local volFill = Instance.new("Frame")
	volFill.Name = "VolFill"
	volFill.Size = UDim2.new(volume, 0, 1, 0)
	volFill.BackgroundColor3 = Color3.fromRGB(30, 215, 96)
	volFill.BorderSizePixel = 0
	volFill.Parent = volBar
	volFill.ZIndex = 8

	local volFillCorner = Instance.new("UICorner")
	volFillCorner.CornerRadius = UDim.new(0.5, 0)
	volFillCorner.Parent = volFill

	-- Volume click handler
	local volBtn = Instance.new("TextButton")
	volBtn.Name = "VolBtn"
	volBtn.Size = UDim2.new(1, 0, 1, 10)
	volBtn.Position = UDim2.new(0, 0, 0, -5)
	volBtn.BackgroundTransparency = 1
	volBtn.Text = ""
	volBtn.Parent = volBar
	volBtn.ZIndex = 9

	volBtn.MouseButton1Click:Connect(function()
		-- Simple toggle between mute and previous volume
		if volume > 0 then
			MusicPlayerUI.SetVolume(0)
			volFill.Size = UDim2.new(0, 0, 1, 0)
		else
			MusicPlayerUI.SetVolume(MusicList.DefaultVolume)
			volFill.Size = UDim2.new(MusicList.DefaultVolume, 0, 1, 0)
		end
	end)

	-- Song list (scrollable)
	local songListLabel = Instance.new("TextLabel")
	songListLabel.Name = "SongListLabel"
	songListLabel.Size = UDim2.new(1, 0, 0, 20)
	songListLabel.Position = UDim2.new(0, 0, 0, 350)
	songListLabel.BackgroundTransparency = 1
	songListLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	songListLabel.Text = "Queue"
	songListLabel.TextSize = 12
	songListLabel.Font = Enum.Font.Gotham
	songListLabel.Parent = frame
	songListLabel.ZIndex = 6

	local songScroll = Instance.new("ScrollingFrame")
	songScroll.Name = "SongList"
	songScroll.Size = UDim2.new(1, -10, 0, 100)
	songScroll.Position = UDim2.new(0, 5, 0, 372)
	songScroll.BackgroundTransparency = 1
	songScroll.ScrollBarThickness = 3
	songScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	songScroll.Parent = frame
	songScroll.ZIndex = 6

	local songLayout = Instance.new("UIListLayout")
	songLayout.SortOrder = Enum.SortOrder.LayoutOrder
	songLayout.Padding = UDim.new(0, 4)
	songLayout.Parent = songScroll

	for i, song in ipairs(playlist) do
		local songBtn = Instance.new("TextButton")
		songBtn.Name = "Song_" .. i
		songBtn.Size = UDim2.new(1, -8, 0, 30)
		songBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
		songBtn.BackgroundTransparency = 0.5
		songBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
		songBtn.Text = "  " .. song.title .. " - " .. song.artist
		songBtn.TextSize = 11
		songBtn.TextXAlignment = Enum.TextXAlignment.Left
		songBtn.Font = Enum.Font.Gotham
		songBtn.BorderSizePixel = 0
		songBtn.LayoutOrder = i
		songBtn.Parent = songScroll
		songBtn.ZIndex = 7

		local songCorner = Instance.new("UICorner")
		songCorner.CornerRadius = UDim.new(0, 6)
		songCorner.Parent = songBtn

		local idx = i
		songBtn.MouseButton1Click:Connect(function()
			currentIndex = idx
			MusicPlayerUI.Play()
		end)
	end

	songLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		songScroll.CanvasSize = UDim2.new(0, 0, 0, songLayout.AbsoluteContentSize.Y + 5)
	end)
end

return MusicPlayerUI
