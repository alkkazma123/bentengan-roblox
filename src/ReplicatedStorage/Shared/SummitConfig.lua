--[[
	SummitConfig
	Ubah SummitsPerFinish untuk jumlah summit per finish.
	Setelah summit, player tetap di summit.
	Saat respawn, balik ke Start (checkpoint di-reset).
]]

local SummitConfig = {}

SummitConfig.SummitsPerFinish = 1
SummitConfig.Cooldown = 5
SummitConfig.CelebrationMessage = "SUMMIT REACHED!"

return SummitConfig
