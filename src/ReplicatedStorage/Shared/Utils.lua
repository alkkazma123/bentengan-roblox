--!strict
local Utils = {}

function Utils.safeCall(fn: (...any) -> ...any, ...): (boolean, ...any)
	return pcall(fn, ...)
end

function Utils.formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

function Utils.clamp(v: number, min: number, max: number): number
	if v < min then
		return min
	end
	if v > max then
		return max
	end
	return v
end

function Utils.shuffle<T>(tbl: { T }): { T }
	local out = table.clone(tbl)
	for i = #out, 2, -1 do
		local j = math.random(1, i)
		out[i], out[j] = out[j], out[i]
	end
	return out
end

-- Find the first HRP+Humanoid pair in a character, or nil.
function Utils.getCharacterParts(char: Model?): (BasePart?, Humanoid?)
	if not char then
		return nil, nil
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hrp and hrp:IsA("BasePart") then
		return hrp, hum
	end
	return nil, hum
end

return Utils
