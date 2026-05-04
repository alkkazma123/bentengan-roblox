--[[
	MusicList
	Configure the playlist for the music player.
	Add/remove entries to change available songs.
	The player will also scan ReplicatedStorage.Music folder for Sound objects.
]]

local MusicList = {}

MusicList.Songs = {
	{ id = "rbxassetid://1837849285", title = "Mountain Breeze", artist = "Nature" },
	{ id = "rbxassetid://1839245717", title = "Summit Theme", artist = "Adventure" },
	{ id = "rbxassetid://1836114388", title = "Chill Climb", artist = "LoFi" },
	{ id = "rbxassetid://1844207353", title = "Peak View", artist = "Ambient" },
	{ id = "rbxassetid://1837916552", title = "Rocky Path", artist = "Indie" },
}

-- Default volume (0-1)
MusicList.DefaultVolume = 0.5

-- Whether to shuffle by default
MusicList.DefaultShuffle = false

-- Whether to loop playlist
MusicList.DefaultLoop = true

return MusicList
