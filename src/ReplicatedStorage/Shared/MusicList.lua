--[[
	MusicList
	Configure the playlist for the music player.

	CARA MENGISI:
	1. Tambahkan entry ke tabel Songs di bawah:
	   { id = "rbxassetid://ID_DISINI", title = "Judul", artist = "Artis" },

	2. ATAU taruh Sound object langsung ke folder ReplicatedStorage > Music
	   (buat folder "Music" di ReplicatedStorage, isi dengan Sound objects)

	Kedua cara bisa dipakai bersamaan.
]]

local MusicList = {}

-- Isi lagu di sini (kosong = tidak ada default, isi sendiri)
MusicList.Songs = {}

-- Default volume (0-1)
MusicList.DefaultVolume = 0.5

-- Whether to shuffle by default
MusicList.DefaultShuffle = false

-- Whether to loop playlist
MusicList.DefaultLoop = true

return MusicList
