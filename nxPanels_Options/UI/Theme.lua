-- nxPanels Options - Copyright (C) 2026 Adna
-- Licensed under the GNU General Public License v3.0 or later. See LICENSE.

local _, O = ...

-- Shared state of the options module
O.core = nxPanels.__ns
O.L = O.core.L

local Theme = {}
O.Theme = Theme

local WHITE = "Interface\\Buttons\\WHITE8X8"
Theme.WHITE = WHITE

Theme.colors = {
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
	accent = { 0.2, 0.8, 1, 1 },
	accentSoft = { 0.2, 0.8, 1, 0.14 },
	danger = { 1, 0.38, 0.38, 1 },
	dangerSoft = { 1, 0.38, 0.38, 0.14 },
	success = { 0.35, 0.9, 0.55, 1 },
}

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
