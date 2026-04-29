--!strict
-- Custom player titles. Each player can set a title that appears above their
-- head; they're allowed exactly one change per 24 hours (UTC). All text is
-- run through Chat:FilterStringForBroadcast so the chat moderation system
-- decides what's safe to display.

local Chat = game:GetService("Chat")
local TextService = game:GetService("TextService")

local DataService = require(script.Parent.DataService)
local OverheadGui = require(script.Parent.OverheadGui)

local TitleService = {}

local COOLDOWN = 24 * 60 * 60 -- 24 hours
local MAX_LENGTH = 14
local MIN_LENGTH = 2

-- Curated free presets (always allowed without filtering surprises).
local PRESETS: { string } = {
	"Newbie",
	"Veteran",
	"Pemberani",
	"Ninja",
	"Striker",
	"Defender",
	"Wardian",
	"MVP",
	"Sang Petarung",
	"Cepat Kilat",
	"Bayangan",
	"Penjaga",
}

export type TitleState = {
	Current: string,
	NextAvailableAt: number, -- 0 if available now
	Available: boolean,
	Cooldown: number,
	MaxLength: number,
	Presets: { string },
}

local function trim(s: string): string
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function TitleService.getState(player: Player): TitleState
	local profile = DataService.getProfile(player)
	local now = os.time()
	local last = profile.LastTitleChangeAt or 0
	local nextAt = last == 0 and 0 or (last + COOLDOWN)
	return {
		Current = profile.Title or "",
		NextAvailableAt = nextAt,
		Available = now >= nextAt,
		Cooldown = COOLDOWN,
		MaxLength = MAX_LENGTH,
		Presets = PRESETS,
	}
end

local function isPreset(text: string): boolean
	for _, p in PRESETS do
		if p == text then
			return true
		end
	end
	return false
end

local function filterTitle(rawText: string, fromPlayer: Player): (boolean, string)
	-- TextService:FilterStringAsync is the modern recommended path; fall back
	-- to legacy Chat filter if needed.
	local ok, filtered = pcall(function()
		local res = TextService:FilterStringAsync(rawText, fromPlayer.UserId)
		return res:GetNonChatStringForBroadcastAsync()
	end)
	if ok and type(filtered) == "string" and filtered ~= "" then
		return true, filtered
	end
	-- Fallback: Chat filter (deprecated but still works on most places).
	local ok2, filtered2 = pcall(function()
		return Chat:FilterStringForBroadcast(rawText, fromPlayer)
	end)
	if ok2 and type(filtered2) == "string" and filtered2 ~= "" then
		return true, filtered2
	end
	return false, "Filter teks gagal, coba lagi."
end

export type SetTitleResult = {
	Success: boolean,
	Title: string?,
	Message: string?,
	State: TitleState,
}

function TitleService.setTitle(player: Player, requestedRaw: any): SetTitleResult
	local state = TitleService.getState(player)
	if not DataService.isLoaded(player) then
		return { Success = false, Message = "Data belum siap.", State = state }
	end
	if type(requestedRaw) ~= "string" then
		return { Success = false, Message = "Teks tidak valid.", State = state }
	end

	local requested = trim(requestedRaw)
	if utf8.len(requested) == nil then
		return { Success = false, Message = "Teks tidak valid.", State = state }
	end

	local len = utf8.len(requested) or 0
	if len < MIN_LENGTH then
		return { Success = false, Message = "Minimal 2 karakter.", State = state }
	end
	if len > MAX_LENGTH then
		return { Success = false, Message = "Maksimal 14 karakter.", State = state }
	end

	-- Cooldown check.
	if not state.Available then
		return {
			Success = false,
			Message = "Tunggu sampai cooldown 24 jam selesai.",
			State = state,
		}
	end

	local finalText: string
	if isPreset(requested) then
		-- Presets are pre-vetted; skip filter to avoid false-positives.
		finalText = requested
	else
		local ok, filtered = filterTitle(requested, player)
		if not ok then
			return { Success = false, Message = filtered, State = state }
		end
		finalText = filtered
	end

	-- Reject titles that became all-tag after filtering (e.g. "####").
	if not finalText:find("[%w]") then
		return {
			Success = false,
			Message = "Teks tidak diizinkan.",
			State = state,
		}
	end

	local profile = DataService.getProfile(player)
	profile.Title = finalText
	profile.LastTitleChangeAt = os.time()

	-- Push immediately to overhead UI.
	OverheadGui.setTitle(player, finalText)

	return {
		Success = true,
		Title = finalText,
		State = TitleService.getState(player),
	}
end

function TitleService.getPresets(): { string }
	return PRESETS
end

return TitleService
