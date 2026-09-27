local _, O = ...
local T, W = O.Theme, O.Widgets
local C = T.colors
local L = O.L
local core = O.core

-- Main window: sidebar navigation, page header, content, footer
local Options = {}
O.Options = Options
core.Options = Options

local WIDTH, HEIGHT, SIDEBAR = 1060, 680, 230
local CONTENT_PAD = 28
Options.pages = {}
Options.order = {}

---------------------------------------------------------------------------
-- Pages
-- def = { key, title, subtitle, build(page, width), refresh(page), onShow(page), action (no page) }
---------------------------------------------------------------------------
function Options:RegisterPage(def)
	self.pages[def.key] = def
	self.order[#self.order + 1] = def.key
end

-- Width available for the content of a page
Options.contentWidth = WIDTH - SIDEBAR - 2 * CONTENT_PAD

---------------------------------------------------------------------------
-- Dialogs
---------------------------------------------------------------------------
StaticPopupDialogs["NXPANELS_CONFIRM"] = {
	text = "%s",
	button1 = YES,
	button2 = NO,
	OnAccept = function(_, data) data() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	showAlert = true,
}
-- Recent clients use dialog:GetEditBox(), older ones a field
local function dialogEditBox(dialog)
	return dialog.GetEditBox and dialog:GetEditBox() or dialog.editBox or dialog.EditBox
end

StaticPopupDialogs["NXPANELS_PROMPT"] = {
	text = "%s",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	editBoxWidth = 260,
	OnShow = function(self, data)
		local edit = dialogEditBox(self)
		edit:SetText(data.default or "")
		edit:HighlightText()
		edit:SetFocus()
	end,
	OnAccept = function(self, data)
		local edit = dialogEditBox(self)
		data.onAccept(edit:GetText())
	end,
	EditBoxOnEnterPressed = function(self, data)
		local parent = self:GetParent()
		data.onAccept(self:GetText())
		parent:Hide()
	end,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
}

function Options:Confirm(text, onAccept)
	StaticPopup_Show("NXPANELS_CONFIRM", text, nil, onAccept)
end

function Options:Prompt(text, default, onAccept)
	StaticPopup_Show("NXPANELS_PROMPT", text, nil, { default = default, onAccept = onAccept })
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local function navButton(parent, def)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(SIDEBAR - 16, 36)
	b.bg = T:Fill(b, { 0, 0, 0, 0 })
	b.bar = b:CreateTexture(nil, "ARTWORK")
	b.bar:SetTexture(T.WHITE)
	b.bar:SetVertexColor(unpack(C.accent))
	b.bar:SetWidth(3)
	b.bar:SetPoint("TOPLEFT")
	b.bar:SetPoint("BOTTOMLEFT")
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetSize(18, 18)
	b.icon:SetPoint("LEFT", 16, 0)
	if def.atlas then b.icon:SetAtlas(def.atlas) else b.icon:SetTexture(def.icon) end
	b.icon:SetDesaturated(true)
	b.label = T:Text(b, T.fonts.nav, C.textDim)
	b.label:SetPoint("LEFT", b.icon, "RIGHT", 12, 0)
	b.label:SetText(def.title)
	b:SetScript("OnEnter", function(self) if Options.current ~= def.key then self.bg:SetVertexColor(unpack(C.cardHover)) end end)
	b:SetScript("OnLeave", function(self) if Options.current ~= def.key then self.bg:SetVertexColor(0, 0, 0, 0) end end)
	b:SetScript("OnClick", function() Options:Show(def.key) end)
	function b:SetSelected(on)
		self.bar:SetShown(on)
		if on and T.ornate then
			-- Accent fading to the right, like a brush stroke
			T:Gradient(self.bg, C.accentHover, { C.accent[1], C.accent[2], C.accent[3], 0 })
		else
			self.bg:SetVertexColor(unpack(on and C.accentSoft or { 0, 0, 0, 0 }))
		end
		self.label:SetTextColor(unpack(on and C.text or C.textDim))
		self.icon:SetDesaturated(not on)
	end
	b:SetSelected(false)
	return b
end

function Options:Create()
	if self.frame then return end
	local f = CreateFrame("Frame", "nxPanelsOptionsFrame", UIParent)
	f:SetSize(WIDTH, HEIGHT)
	f:SetPoint("CENTER")
	f:SetFrameStrata("HIGH")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetScale(core.db.global.optionsScale or 1)
	T:Fill(f, C.window)
	T:Border(f, C.lineStrong)
	tinsert(UISpecialFrames, "nxPanelsOptionsFrame")
	self.frame = f

	-- Sidebar
	local side = CreateFrame("Frame", nil, f)
	side:SetPoint("TOPLEFT")
	side:SetPoint("BOTTOMLEFT")
	side:SetWidth(SIDEBAR)
	T:Fill(side, C.sidebar)
	local sideLine = side:CreateTexture(nil, "BORDER")
	sideLine:SetTexture(T.WHITE)
	sideLine:SetVertexColor(unpack(C.line))
	sideLine:SetWidth(1)
	sideLine:SetPoint("TOPRIGHT")
	sideLine:SetPoint("BOTTOMRIGHT")

	local logo = CreateFrame("Frame", nil, side)
	logo:SetSize(34, 34)
	logo:SetPoint("TOPLEFT", 22, -24)
	local logoText
	if T.ornate then
		-- Solid block of color, dark letters
		T:Fill(logo, C.accent)
		logoText = T:Text(logo, T.fonts.header, C.sidebar, "CENTER")
	else
		T:Fill(logo, C.accentSoft)
		T:Border(logo, C.accent)
		logoText = T:Text(logo, T.fonts.header, C.accent, "CENTER")
	end
	logoText:SetPoint("CENTER")
	logoText:SetText("nx")
	local title = T:Text(side, T.fonts.logo, C.text)
	title:SetPoint("LEFT", logo, "RIGHT", 12, 0)
	title:SetText("nx" .. T.accentCode .. "Panels|r")

	self.nav = {}
	local y = -86
	for _, key in ipairs(self.order) do
		local def = self.pages[key]
		local b = navButton(side, def)
		b:SetPoint("TOPLEFT", 8, y)
		y = y - 38
		self.nav[key] = b
	end

	local version = T:Text(side, T.fonts.small, C.textMuted)
	version:SetPoint("BOTTOMLEFT", 22, 16)
	version:SetText("v" .. core.version)
	-- Own line above the version: both are too wide to share one line
	self.stats = T:Text(side, T.fonts.small, C.textMuted)
	self.stats:SetPoint("BOTTOMLEFT", version, "TOPLEFT", 0, 6)

	-- Header
	self.title = T:Text(f, T.fonts.title, C.text)
	self.title:SetPoint("TOPLEFT", SIDEBAR + CONTENT_PAD, -26)
	self.subtitle = T:Text(f, T.fonts.normal, C.textDim)
	self.subtitle:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, -6)
	if T.ornate then
		-- Short stroke of the accent under the title
		local stroke = f:CreateTexture(nil, "ARTWORK")
		stroke:SetTexture(T.WHITE)
		stroke:SetSize(180, 2)
		stroke:SetPoint("BOTTOMLEFT", self.title, "BOTTOMLEFT", 0, -3)
		T:Gradient(stroke, C.accent, { C.accent[1], C.accent[2], C.accent[3], 0 })
		self.subtitle:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, -10)
	end

	local close = CreateFrame("Button", nil, f)
	close:SetSize(30, 30)
	close:SetPoint("TOPRIGHT", -14, -14)
	local closeBg = T:Fill(close, { 0, 0, 0, 0 })
	T:Border(close, C.lineStrong)
	local x = T:Text(close, T.fonts.header, C.textDim, "CENTER")
	x:SetPoint("CENTER", 0, 1)
	x:SetText("X")
	close:SetScript("OnEnter", function() closeBg:SetVertexColor(unpack(C.dangerSoft)) x:SetTextColor(unpack(C.danger)) end)
	close:SetScript("OnLeave", function() closeBg:SetVertexColor(0, 0, 0, 0) x:SetTextColor(unpack(C.textDim)) end)
	close:SetScript("OnClick", function() f:Hide() end)

	-- Footer
	local footer = CreateFrame("Frame", nil, f)
	footer:SetPoint("BOTTOMLEFT", SIDEBAR, 0)
	footer:SetPoint("BOTTOMRIGHT")
	footer:SetHeight(56)
	local footerLine = T:Line(footer)
	footerLine:SetPoint("TOPLEFT")
	footerLine:SetPoint("TOPRIGHT")
	local closeButton = W.Button(footer, CLOSE, 130, "primary", function() f:Hide() end)
	closeButton:SetPoint("RIGHT", -CONTENT_PAD, 0)
	local reload = W.Button(footer, L["RELOAD_UI"], 160, "default", function() ReloadUI() end)
	reload:SetPoint("LEFT", CONTENT_PAD, 0)
	local edit = W.Button(footer, L["EDIT_MODE"], 160, "default", function() O.EditMode:Start() end)
	edit:SetPoint("LEFT", reload, "RIGHT", 8, 0)

	-- Content area
	local content = CreateFrame("Frame", nil, f)
	content:SetPoint("TOPLEFT", SIDEBAR + CONTENT_PAD, -92)
	content:SetPoint("BOTTOMRIGHT", -CONTENT_PAD, 68)
	self.content = content

	f:SetScript("OnShow", function() Options:Refresh() end)
	f:SetScript("OnHide", function() O.Dropdown:Close() end)
end

-- Shows a page (and the window)
function Options:Show(key)
	self:Create()
	key = key or self.current or self.order[1]
	local def = self.pages[key]
	if not def then return end
	if def.action then
		def.action()
		return
	end
	if self.current and self.current ~= key and self.pages[self.current].frame then
		self.pages[self.current].frame:Hide()
	end
	self.current = key
	for k, b in pairs(self.nav) do b:SetSelected(k == key) end
	self.title:SetText(def.title)
	self.subtitle:SetText(def.subtitle or "")
	if not def.frame then
		def.frame = CreateFrame("Frame", nil, self.content)
		def.frame:SetAllPoints(self.content)
		def.build(def.frame, self.contentWidth)
	end
	def.frame:Show()
	self.frame:Show()
	self:Refresh()
end

function Options:Toggle(key)
	if key == "editmode" then
		O.EditMode:Start()
		return
	end
	if self.frame and self.frame:IsShown() and (not key or key == self.current) then
		self.frame:Hide()
	else
		self:Show(key)
	end
end

-- Reads every value again (after any change)
function Options:Refresh()
	if not (self.frame and self.frame:IsShown()) then return end
	local def = self.pages[self.current]
	if def and def.refresh then def.refresh(def.frame) end
	local shown, waiting = core.Layouts:CountShown()
	self.stats:SetText(L["STATS"]:format(shown, waiting))
end

---------------------------------------------------------------------------
-- Helpers shared by the pages
---------------------------------------------------------------------------
function Options:ActiveLayout()
	local id = core.Database:GetActiveLayoutId()
	return id, core.Database:GetLayout(id)
end

-- Page with a scrolling form; returns scroll, form
function Options:ScrollForm(page, width, top)
	local scroll = W.Scroll(page)
	scroll:SetPoint("TOPLEFT", 0, -(top or 0))
	scroll:SetPoint("BOTTOMRIGHT", 0, 0)
	scroll.content:SetWidth(width)
	local form = W.Form(scroll.content, width - 12)
	return scroll, form
end

-- Dropdown items from a list of neutral keys: the text is L[prefix .. key]
function Options:Choices(keys, prefix)
	local items = {}
	for i, key in ipairs(keys) do
		items[i] = { value = key, text = L[prefix .. (key == "" and "NONE" or key:upper())] }
	end
	return items
end

-- Names drawn with their own font only when they are plain latin text
-- (a latin font cannot draw a Chinese name)
local function isLatin(text)
	return not text:find("[\128-\255]")
end

--[[
Dropdown items of the LibSharedMedia lists.
kind = "background" | "border": "none" is false, like in the data
kind = "font": the language default font is nil
]]
function Options:MediaItems(kind)
	local LSM = core.Media.LSM
	local items = {}
	if kind == "font" then
		items[1] = { value = nil, text = L["DEFAULT_FONT"], font = core.Media:DefaultFont() }
	else
		items[1] = { value = false, text = L["NONE"] }
	end
	local paths = LSM:HashTable(kind)
	for _, name in ipairs(LSM:List(kind)) do
		local path = paths[name]
		if name ~= "None" and path and path ~= "" then
			local item = { value = name, text = name }
			if kind == "font" then
				item.font = isLatin(name) and path or nil
			elseif kind == "border" then
				item.border = path
			else
				item.texture = path
			end
			items[#items + 1] = item
		end
	end
	return items
end
