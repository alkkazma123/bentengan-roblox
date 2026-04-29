--!strict
-- Dark minimalist theme tokens used by all UI modules.

local Theme = {}

Theme.Colors = {
	Bg = Color3.fromRGB(15, 17, 22),
	BgAlt = Color3.fromRGB(22, 25, 32),
	Panel = Color3.fromRGB(28, 32, 40),
	PanelAlt = Color3.fromRGB(36, 41, 52),
	Stroke = Color3.fromRGB(58, 64, 78),
	Text = Color3.fromRGB(235, 238, 245),
	TextDim = Color3.fromRGB(150, 158, 172),
	Accent = Color3.fromRGB(120, 170, 255),
	AccentAlt = Color3.fromRGB(90, 220, 180),
	Danger = Color3.fromRGB(230, 90, 90),
	Warning = Color3.fromRGB(240, 190, 90),
	Gold = Color3.fromRGB(250, 205, 100),
	Red = Color3.fromRGB(225, 70, 70),
	Blue = Color3.fromRGB(70, 130, 225),
}

Theme.Font = Enum.Font.Gotham
Theme.FontBold = Enum.Font.GothamBold
Theme.FontMed = Enum.Font.GothamMedium

Theme.Radius = UDim.new(0, 10)
Theme.SmallRadius = UDim.new(0, 6)

function Theme.applyCorner(inst: GuiObject, radius: UDim?): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or Theme.Radius
	c.Parent = inst
	return c
end

function Theme.applyStroke(inst: GuiObject, color: Color3?, thickness: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Colors.Stroke
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

function Theme.applyPadding(inst: GuiObject, px: number): UIPadding
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = inst
	return p
end

-- Attach a UIScale to the ScreenGui that responds to viewport size so UIs
-- shrink gracefully on small screens (tablets, phones) and expand modestly on
-- large monitors. Designed around a 1280px reference width.
function Theme.attachAutoScale(gui: ScreenGui): UIScale
	local scale = gui:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = gui
	end

	local function update()
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local vp = cam.ViewportSize
		if vp.X <= 0 or vp.Y <= 0 then
			return
		end
		local widthScale = vp.X / 1280
		local heightScale = vp.Y / 720
		local s = math.min(widthScale, heightScale)
		-- Clamp to keep UI legible on very small / very large screens.
		s = math.clamp(s, 0.55, 1.25)
		scale.Scale = s
	end

	update()
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local newCam = workspace.CurrentCamera
		if newCam then
			newCam:GetPropertyChangedSignal("ViewportSize"):Connect(update)
		end
		update()
	end)

	return scale
end

return Theme
