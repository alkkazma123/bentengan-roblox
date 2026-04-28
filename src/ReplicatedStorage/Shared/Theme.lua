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

return Theme
