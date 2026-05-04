--[[
	CheckpointConfig
	Configure the number of checkpoints in the obby.
	Change TotalCheckpoints to add/remove checkpoints.
]]

local CheckpointConfig = {}

-- Total number of checkpoints (excluding Start and Finish)
CheckpointConfig.TotalCheckpoints = 8

-- Names displayed in notification (auto-generated if nil)
CheckpointConfig.Names = nil -- e.g. {"Base Camp","Ridge",...}

-- Shake intensity when hitting a checkpoint (0 to disable)
CheckpointConfig.ShakeIntensity = 8

-- Shake duration in seconds
CheckpointConfig.ShakeDuration = 0.3

-- Notification display duration
CheckpointConfig.NotificationDuration = 2.5

-- Checkpoint sound ID (plays when reaching a checkpoint)
CheckpointConfig.SoundId = "rbxassetid://128062463831151"

return CheckpointConfig
