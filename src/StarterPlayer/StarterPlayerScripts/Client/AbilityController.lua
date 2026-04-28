--!strict
-- Client side:
--   * Renders ESP outlines for enemies when HackerESP is equipped.
--   * Reads WASD/space/shift to drive the BodyVelocity that the server created
--     for Fly during its 10 second window.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local AbilityController = {}
AbilityController.__index = AbilityController

function AbilityController.new()
	local self = setmetatable({}, AbilityController)
	self.player = Players.LocalPlayer
	self.equipped = {} :: { string }
	self.team = nil :: string?
	self.flyActiveUntil = 0
	self.flySpeed = GameConfig.Abilities.Fly.Params.FlySpeed
	self.highlights = {} :: { [Player]: Highlight }
	self:_startEspLoop()
	self:_startFlyLoop()
	return self
end

function AbilityController:_hasEquipped(id: string): boolean
	return table.find(self.equipped, id) ~= nil
end

function AbilityController:_startEspLoop()
	task.spawn(function()
		while true do
			task.wait(0.5)
			local espOn = self:_hasEquipped("HackerESP")
			if not espOn then
				for _, hl in self.highlights do
					hl:Destroy()
				end
				self.highlights = {}
			else
				for _, other in ipairs(Players:GetPlayers()) do
					if other == self.player then
						continue
					end
					local char = other.Character
					if not char then
						continue
					end
					local hl = self.highlights[other]
					-- Determine enemy: we need the server-assigned team. We track our own via TeamAssigned.
					local otherTeam = other:GetAttribute("BentenganTeam")
					local isEnemy = self.team ~= nil and otherTeam ~= nil and otherTeam ~= self.team
					if isEnemy then
						if not hl or hl.Parent ~= char then
							if hl then
								hl:Destroy()
							end
							hl = Instance.new("Highlight")
							hl.FillTransparency = 0.6
							hl.OutlineColor = if otherTeam == "Red"
								then Color3.fromRGB(255, 90, 90)
								else Color3.fromRGB(100, 150, 255)
							hl.FillColor = hl.OutlineColor
							hl.Adornee = char
							hl.Parent = char
							self.highlights[other] = hl
						end
					else
						if hl then
							hl:Destroy()
							self.highlights[other] = nil
						end
					end
				end
			end
		end
	end)
end

function AbilityController:_getFlyVelocity(): Vector3
	local camera = workspace.CurrentCamera
	if not camera then
		return Vector3.new()
	end
	local moveDir = Vector3.new()
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		moveDir += Vector3.new(0, 0, -1)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		moveDir += Vector3.new(0, 0, 1)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		moveDir += Vector3.new(-1, 0, 0)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		moveDir += Vector3.new(1, 0, 0)
	end
	if moveDir.Magnitude > 0 then
		moveDir = moveDir.Unit
	end

	local lookCF = CFrame.lookAt(Vector3.zero, camera.CFrame.LookVector * Vector3.new(1, 0, 1))
	local worldDir = (lookCF:VectorToWorldSpace(moveDir)) :: Vector3

	local up = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		up += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		up -= 1
	end
	return (worldDir + Vector3.new(0, up, 0)) * self.flySpeed
end

function AbilityController:_startFlyLoop()
	RunService.Heartbeat:Connect(function()
		if self.flyActiveUntil <= os.clock() then
			return
		end
		local char = self.player.Character
		if not char then
			return
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp or not hrp:IsA("BasePart") then
			return
		end
		local bv = hrp:FindFirstChild("BentenganFlyGravity")
		if bv and bv:IsA("BodyVelocity") then
			bv.Velocity = self:_getFlyVelocity()
		end
	end)
end

function AbilityController:setEquipped(equipped: { string })
	self.equipped = equipped
end

function AbilityController:setTeam(team: string)
	self.team = team
end

function AbilityController:clearTeam()
	self.team = nil
end

function AbilityController:onFlyStart(endsAt: number, speed: number)
	self.flyActiveUntil = endsAt
	self.flySpeed = speed
end

function AbilityController:onFlyEnd()
	self.flyActiveUntil = 0
end

return AbilityController
