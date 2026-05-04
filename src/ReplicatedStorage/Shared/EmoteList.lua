--[[
	EmoteList
	Configure available emotes.

	CARA MENGISI:
	1. Tambahkan entry ke tabel Emotes di bawah:
	   { id = "rbxassetid://ANIMATION_ID", name = "NamaEmote", icon = "rbxassetid://ICON_ID" },

	2. ATAU taruh Animation object langsung ke folder ReplicatedStorage > Emotes
	   (buat folder "Emotes" di ReplicatedStorage, isi dengan Animation objects)

	Kedua cara bisa dipakai bersamaan.
]]

local EmoteList = {}

-- Isi emote di sini (kosong = tidak ada default, isi sendiri)
EmoteList.Emotes = {}

return EmoteList
