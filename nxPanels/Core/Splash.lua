local _, ns = ...
local L = ns.L

--[[
Announcement windows (welcome after an import, what's new): the banner of
nxPanels, a gold frame, a title, a text and two buttons (open nxPanels, OK).
Built without the options module, which is only loaded on demand.
	local f = ns.Splash:Create("nxPanelsNews", width, height)
	f.title, f.body, f.open, f.close
]]
local Splash = {}
ns.Splash = Splash

local WHITE = "Interface\\Buttons\\WHITE8X8"
local BANNER = "Interface\\AddOns\\nxPanels\\Media\\banner"
local GOLD = { 1, 0.76, 0.33 }

local frames = {}

local function fill(parent, layer, r, g, b)
	local tex = parent:CreateTexture(nil, layer)
	tex:SetTexture(WHITE)
	tex:SetVertexColor(r, g, b, 1)
	return tex
end

local function button(parent, text, onClick)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(170, 28)
	b:SetText(text)
	b:SetScript("OnClick", onClick)
	return b
end

function Splash:Create(name, width, height)
	local f = CreateFrame("Frame", name, UIParent)
	f:SetSize(width, height)
	f:SetPoint("CENTER", 0, 60)
	f:SetFrameStrata("DIALOG")
	f:SetClampedToScreen(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	tinsert(UISpecialFrames, name)
	frames[#frames + 1] = f

	-- Same dark background as the banner, gold frame
	fill(f, "BACKGROUND", 0.07, 0.063, 0.059):SetAllPoints()
	for _, side in ipairs({ { "TOPLEFT", "TOPRIGHT", 0, 2 }, { "BOTTOMLEFT", "BOTTOMRIGHT", 0, 2 },
		{ "TOPLEFT", "BOTTOMLEFT", 2, 0 }, { "TOPRIGHT", "BOTTOMRIGHT", 2, 0 } }) do
		local edge = fill(f, "BORDER", unpack(GOLD))
		edge:SetPoint(side[1])
		edge:SetPoint(side[2])
		if side[3] > 0 then edge:SetWidth(side[3]) else edge:SetHeight(side[4]) end
	end

	-- Banner: 512x128 texture, logo and name
	local banner = f:CreateTexture(nil, "ARTWORK")
	banner:SetTexture(BANNER)
	banner:SetSize(480, 120)
	banner:SetPoint("TOP", 0, -14)

	f.title = f:CreateFontString(nil, "OVERLAY")
	f.title:SetFont(STANDARD_TEXT_FONT, 20, "")
	f.title:SetTextColor(unpack(GOLD))
	f.title:SetPoint("TOP", banner, "BOTTOM", 0, -14)
	f.title:SetWidth(width - 60)

	f.body = f:CreateFontString(nil, "OVERLAY")
	f.body:SetFont(STANDARD_TEXT_FONT, 15, "")
	f.body:SetTextColor(0.96, 0.93, 0.87)
	f.body:SetJustifyH("CENTER")
	f.body:SetJustifyV("TOP")
	f.body:SetSpacing(4)
	f.body:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -16)
	f.body:SetPoint("TOPRIGHT", f.title, "BOTTOMRIGHT", 0, -16)
	f.body:SetPoint("BOTTOM", 0, 64)

	f.open = button(f, L["OPEN_OPTIONS"], function()
		f:Hide()
		ns.Commands:OpenOptions(nil, true)
	end)
	f.open:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -8, 22)
	f.close = button(f, L["OK"], function() f:Hide() end)
	f.close:SetPoint("BOTTOMLEFT", f, "BOTTOM", 8, 22)

	-- When a window closes, the next waiting one can show (what's new after the welcome)
	f:SetScript("OnHide", function() Splash:ShowNext() end)
	return f
end

-- One of the windows is on screen
function Splash:AnyShown()
	for _, f in ipairs(frames) do
		if f:IsShown() then return true end
	end
	return false
end

-- Shows `show()` now, or once the window on screen is closed
function Splash:Queue(show)
	if self:AnyShown() then
		self.waiting = show
	else
		show()
	end
end

function Splash:ShowNext()
	local show = self.waiting
	if show and not self:AnyShown() then
		self.waiting = nil
		show()
	end
end
