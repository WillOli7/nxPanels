-- nxPanels Options - Copyright (C) 2026 Adna
-- All rights reserved. See LICENSE.

local _, O = ...

-- Shared state of the options module
O.core = nxPanels.__ns
O.L = O.core.L

local Theme = {}
O.Theme = Theme

local WHITE = "Interface\\Buttons\\WHITE8X8"
Theme.WHITE = WHITE

---------------------------------------------------------------------------
-- Styles and accent colors (Settings > Appearance, applied on reload)
---------------------------------------------------------------------------
Theme.STYLES = {
	-- Warm charcoal, like an artist's workshop
	atelier = {
		window = { 0.071, 0.064, 0.058, 0.97 },
		sidebar = { 0.052, 0.047, 0.043, 1 },
		card = { 0.102, 0.093, 0.084, 1 },
		cardHover = { 0.133, 0.121, 0.108, 1 },
		input = { 0.04, 0.036, 0.033, 1 },
		line = { 1, 0.9, 0.75, 0.08 },
		lineStrong = { 1, 0.9, 0.75, 0.18 },
		text = { 0.96, 0.93, 0.87, 1 },
		textDim = { 0.73, 0.68, 0.61, 1 },
		textMuted = { 0.52, 0.48, 0.43, 1 },
	},
	-- Deep ink, violet tint
	ink = {
		window = { 0.055, 0.05, 0.078, 0.97 },
		sidebar = { 0.04, 0.036, 0.058, 1 },
		card = { 0.082, 0.075, 0.112, 1 },
		cardHover = { 0.11, 0.1, 0.148, 1 },
		input = { 0.03, 0.027, 0.045, 1 },
		line = { 0.85, 0.8, 1, 0.08 },
		lineStrong = { 0.85, 0.8, 1, 0.18 },
		text = { 0.94, 0.92, 0.98, 1 },
		textDim = { 0.68, 0.65, 0.78, 1 },
		textMuted = { 0.48, 0.45, 0.58, 1 },
	},
	-- Cool blue-grey
	night = {
		window = { 0.043, 0.055, 0.067, 0.97 },
		sidebar = { 0.031, 0.039, 0.05, 1 },
		card = { 0.071, 0.086, 0.106, 1 },
		cardHover = { 0.094, 0.114, 0.137, 1 },
		input = { 0.027, 0.034, 0.043, 1 },
		line = { 1, 1, 1, 0.07 },
		lineStrong = { 1, 1, 1, 0.16 },
		text = { 0.93, 0.95, 0.97, 1 },
		textDim = { 0.63, 0.68, 0.73, 1 },
		textMuted = { 0.43, 0.47, 0.52, 1 },
	},
}
Theme.STYLE_ORDER = { "atelier", "ink", "night" }

Theme.ACCENTS = {
	gold = { 1, 0.76, 0.33 },
	cyan = { 0.2, 0.8, 1 },
	violet = { 0.7, 0.54, 1 },
	jade = { 0.36, 0.86, 0.62 },
	rose = { 1, 0.5, 0.6 },
}
Theme.ACCENT_ORDER = { "gold", "cyan", "violet", "jade", "rose", "class" }

local function classColor()
	local _, classFile = UnitClass("player")
	local c = C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(classFile)
		or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile])
	if c then return { c.r, c.g, c.b } end
end

local settings = O.core.db.global.optionsTheme
Theme.style = Theme.STYLES[settings.style] and settings.style or "atelier"
-- Ornate styles: accent logo, brush strokes, colored section titles
Theme.ornate = Theme.style ~= "night"
local accent = settings.accent == "class" and classColor() or Theme.ACCENTS[settings.accent] or Theme.ACCENTS.gold
local r, g, b = unpack(accent)

local C = {}
for key, color in pairs(Theme.STYLES[Theme.style]) do C[key] = color end
C.accent = { r, g, b, 1 }
C.accentSoft = { r, g, b, 0.14 }
C.accentHover = { r, g, b, 0.28 }
-- Section titles: accent in the workshop style, discreet otherwise
C.section = Theme.ornate and { r, g, b, 0.85 } or C.textMuted
C.danger = { 1, 0.38, 0.38, 1 }
C.dangerSoft = { 1, 0.38, 0.38, 0.14 }
C.success = { 0.35, 0.9, 0.55, 1 }
Theme.colors = C
-- For |c...|r codes in texts
Theme.accentCode = ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255)

---------------------------------------------------------------------------
-- Fonts: always the client language font (readable in Chinese and Korean)
---------------------------------------------------------------------------
local function font(name, size, flags)
	local f = CreateFont(name)
	f:SetFont(STANDARD_TEXT_FONT, size, flags or "")
	f:SetTextColor(unpack(Theme.colors.text))
	return f
end
Theme.fonts = {
	title = font("nxPanelsOptFontTitle", 24),
	header = font("nxPanelsOptFontHeader", 15),
	normal = font("nxPanelsOptFontNormal", 13),
	small = font("nxPanelsOptFontSmall", 11),
	nav = font("nxPanelsOptFontNav", 13),
	logo = font("nxPanelsOptFontLogo", 20),
}

---------------------------------------------------------------------------
-- Drawing helpers
---------------------------------------------------------------------------
function Theme:Fill(frame, color, layer)
	local tex = frame:CreateTexture(nil, layer or "BACKGROUND")
	tex:SetTexture(WHITE)
	tex:SetAllPoints(frame)
	tex:SetVertexColor(unpack(color))
	return tex
end

local function pixel(tex, horizontal)
	if PixelUtil then
		if horizontal then PixelUtil.SetHeight(tex, 1) else PixelUtil.SetWidth(tex, 1) end
	elseif horizontal then
		tex:SetHeight(1)
	else
		tex:SetWidth(1)
	end
end

-- 1 pixel border; returns the 4 textures (to recolor them)
function Theme:Border(frame, color)
	local edges = {}
	for i, points in ipairs({
		{ "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true },
		{ "TOPLEFT", "BOTTOMLEFT", false }, { "TOPRIGHT", "BOTTOMRIGHT", false },
	}) do
		local tex = frame:CreateTexture(nil, "BORDER")
		tex:SetTexture(WHITE)
		tex:SetVertexColor(unpack(color or self.colors.line))
		tex:SetPoint(points[1])
		tex:SetPoint(points[2])
		pixel(tex, points[3])
		edges[i] = tex
	end
	return edges
end

function Theme:SetBorderColor(edges, color)
	for _, tex in ipairs(edges) do
		tex:SetVertexColor(unpack(color))
	end
end

-- Gradient between two { r, g, b, a } colors (SetVertexColor removes it)
function Theme:Gradient(tex, from, to, orientation)
	tex:SetGradient(orientation or "HORIZONTAL", CreateColor(unpack(from)), CreateColor(unpack(to)))
end

-- Horizontal separator line
function Theme:Line(parent, color)
	local tex = parent:CreateTexture(nil, "ARTWORK")
	tex:SetTexture(WHITE)
	tex:SetVertexColor(unpack(color or self.colors.line))
	pixel(tex, true)
	return tex
end

function Theme:Text(parent, fontObject, color, justify)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFontObject(fontObject or self.fonts.normal)
	fs:SetTextColor(unpack(color or self.colors.text))
	fs:SetJustifyH(justify or "LEFT")
	fs:SetWordWrap(false)
	return fs
end

-- Simple tooltip on any frame
function Theme:Tooltip(frame, title, text)
	frame:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(title, 1, 1, 1)
		if text then GameTooltip:AddLine(text, nil, nil, nil, true) end
		GameTooltip:Show()
	end)
	frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end
