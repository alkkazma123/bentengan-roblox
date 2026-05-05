--[[
	MusicList
	ISI LAGU DI SINI:
	{ id = "rbxassetid://ID", title = "Judul", artist = "Artis" },

	ATAU taruh Sound object ke folder ReplicatedStorage > Music
]]

local MusicList = {}

MusicList.Songs = {
	{ id = "rbxassetid://136298946425465", title = "Kicau Mania", artist = "Unknown" },
	{ id = "rbxassetid://104478870890745", title = "Nikmati Hidup Ini", artist = "Unknown" },
	{ id = "rbxassetid://117487437387749", title = "Berlyn Mix", artist = "Unknown" },
	{ id = "rbxassetid://73838561287165", title = "Pahina", artist = "Unknown", speed = 0.5 },
}

MusicList.DefaultVolume = 0.5
MusicList.DefaultShuffle = false
MusicList.DefaultLoop = true

return MusicList
