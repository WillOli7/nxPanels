local _, O = ...
local T, W = O.Theme, O.Widgets
local C = T.colors
local L = O.L

--[[
Dropdown with search and previews.
items = { { value = ..., text = "...", font = path?, texture = path?, border = path? }, ... }
opts.preview = "font" | "texture" | "border": draws each item with its media
]]
local Dropdown = {}
O.Dropdown = Dropdown

local MAX_ROWS = 12
local popup

local function createPopup()
	local catcher = CreateFrame("Button", nil, UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata("FULLSCREEN_DIALOG")
	catcher:Hide()
	catcher:SetScript("OnClick", function() Dropdown:Close() end)

	popup = CreateFrame("Frame", nil, catcher)
	popup:SetFrameStrata("FULLSCREEN_DIALOG")
	popup:SetFrameLevel(catcher:GetFrameLevel() + 10)
	popup:EnableMouse(true)
	T:Fill(popup, C.sidebar)
	T:Border(popup, C.accent)
	popup.catcher = catcher

	popup.search = W.EditBox(popup, 100, 24)
	popup.search:SetPoint("TOPLEFT", 6, -6)
	popup.search:SetPoint("TOPRIGHT", -6, -6)
	popup.search.edit:SetScript("OnTextChanged", function() Dropdown:Fill() end)
	popup.search.placeholder = T:Text(popup.search, T.fonts.normal, C.textMuted)
	popup.search.placeholder:SetPoint("LEFT", 8, 0)
	popup.search.placeholder:SetText(L["SEARCH"])

	popup.scroll = W.Scroll(popup)
	popup.buttons = {}
	Dropdown.popup = popup
end

-- Chooses an item of the open list (keyboard-free selection, used by the tests)
function Dropdown:Choose(value)
	if not (popup and popup.catcher:IsShown()) then return false end
	for _, b in ipairs(popup.buttons) do
		if b:IsShown() and b.item and b.item.value == value then
			b:GetScript("OnClick")(b, "LeftButton")
			return true
		end
	end
	return false
end

local function rowButton(i)
	local b = popup.buttons[i]
	if b then return b end
	b = CreateFrame("Button", nil, popup.scroll.content)
	b.highlight = T:Fill(b, C.accentSoft, "ARTWORK")
	b.highlight:Hide()
	b.text = T:Text(b, T.fonts.normal, C.text)
	b.check = b:CreateTexture(nil, "OVERLAY")
	b.check:SetTexture(T.WHITE)
	b.check:SetVertexColor(unpack(C.accent))
	b.check:SetSize(3, 14)
	b.check:SetPoint("LEFT", 2, 0)
	b.tex = b:CreateTexture(nil, "ARTWORK")
	b.preview = CreateFrame("Frame", nil, b)
	O.core.Border:Create(b.preview)
	b:SetScript("OnEnter", function(self)
		self.highlight:Show()
		-- item.tooltip: description shown next to the list
		if self.item.tooltip then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.item.text, 1, 1, 1)
			GameTooltip:AddLine(self.item.tooltip, nil, nil, nil, true)
			GameTooltip:Show()
		end
	end)
	b:SetScript("OnLeave", function(self)
		self.highlight:Hide()
		GameTooltip:Hide()
	end)
	b:SetScript("OnClick", function(self)
		local onSelect = popup.onSelect
		Dropdown:Close()
		if onSelect then onSelect(self.item.value) end
	end)
	popup.buttons[i] = b
	return b
end

function Dropdown:Fill()
	local filter = strtrim(popup.search.edit:GetText() or ""):lower()
	popup.search.placeholder:SetShown(filter == "")
	local preview = popup.opts.preview
	local rowHeight = (preview == "texture" or preview == "border") and 38 or 24
	local width = popup:GetWidth() - 12

	local shown = 0
	for _, item in ipairs(popup.items) do
		if filter == "" or tostring(item.text):lower():find(filter, 1, true) then
			shown = shown + 1
			local b = rowButton(shown)
			b.item = item
			b:Show()
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", 0, -(shown - 1) * rowHeight)
			b:SetSize(width - 6, rowHeight)
			b.check:SetShown(item.value == popup.current)
			b.text:ClearAllPoints()
			b.tex:Hide()
			b.preview:Hide()
			if preview == "texture" or preview == "border" then
				local box = preview == "texture" and b.tex or b.preview
				box:ClearAllPoints()
				box:SetPoint("LEFT", 10, 0)
				box:SetSize(64, 30)
				if preview == "texture" and item.texture then
					b.tex:SetTexture(item.texture)
					b.tex:SetTexCoord(0, 1, 0, 1)
					b.tex:Show()
				elseif preview == "border" and item.border then
					O.core.Border:Apply(b.preview, item.border, 10, { r = 1, g = 1, b = 1, a = 1 })
					b.preview:Show()
				end
				b.text:SetPoint("LEFT", 84, 0)
			else
				b.text:SetPoint("LEFT", 12, 0)
			end
			b.text:SetPoint("RIGHT", -6, 0)
			if preview == "font" and item.font then
				b.text:SetFont(item.font, 13, "")
			else
				b.text:SetFontObject(T.fonts.normal)
			end
			b.text:SetText(item.text)
		end
	end
	for i = shown + 1, #popup.buttons do popup.buttons[i]:Hide() end

	local visibleRows = math.min(MAX_ROWS, math.max(shown, 1))
	local searchHeight = popup.search:IsShown() and 34 or 6
	popup:SetHeight(searchHeight + visibleRows * rowHeight + 8)
	popup.scroll:ClearAllPoints()
	popup.scroll:SetPoint("TOPLEFT", 6, -searchHeight)
	popup.scroll:SetPoint("BOTTOMRIGHT", -4, 6)
	popup.scroll:SetContentHeight(shown * rowHeight)
end

function Dropdown:Open(owner, items, current, onSelect, opts)
	if not popup then createPopup() end
	popup.items, popup.current, popup.onSelect, popup.opts = items, current, onSelect, opts or {}
	popup:ClearAllPoints()
	popup:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
	-- opts.minWidth: wider list for long texts
	popup:SetWidth(math.max(owner:GetWidth(), popup.opts.minWidth or (popup.opts.preview and 280 or 200)))
	popup.search.edit:SetText("")
	popup.search:SetShown(#items > MAX_ROWS)
	popup.scroll:SetVerticalScroll(0)
	popup.catcher:Show()
	self:Fill()
end

function Dropdown:Close()
	if popup then popup.catcher:Hide() end
end

---------------------------------------------------------------------------
-- Dropdown button; button:Refresh() shows the current value
-- items: table or function returning the items
---------------------------------------------------------------------------
function W.DropdownButton(parent, width, items, get, set, opts)
	opts = opts or {}
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(width or 190, 24)
	T:Fill(button, C.input)
	local edges = T:Border(button, C.lineStrong)
	button.text = T:Text(button, T.fonts.normal, C.text)
	button.text:SetPoint("LEFT", 8, 0)
	button.text:SetPoint("RIGHT", -20, 0)
	button.arrow = T:Text(button, T.fonts.small, C.textDim, "CENTER")
	button.arrow:SetPoint("RIGHT", -6, 0)
	button.arrow:SetText("v")
	button:SetScript("OnEnter", function() T:SetBorderColor(edges, C.accent) end)
	button:SetScript("OnLeave", function() T:SetBorderColor(edges, C.lineStrong) end)

	local function list()
		return type(items) == "function" and items() or items
	end
	button:SetScript("OnClick", function()
		local function choose(value)
			set(value)
			button:Refresh()
		end
		-- opts.browse(current, choose): another chooser (texture browser)
		if opts.browse then
			opts.browse(get(), choose)
		else
			Dropdown:Open(button, list(), get(), choose, opts)
		end
	end)

	function button:Refresh()
		local current, text, font = get(), nil, nil
		for _, item in ipairs(list()) do
			if item.value == current then
				text, font = item.text, item.font
				break
			end
		end
		-- Values missing from the list: opts.format, or the value itself
		if not text and current ~= nil then
			text = opts.format and opts.format(current) or tostring(current)
		end
		self.text:SetText(text or "")
		if opts.preview == "font" and font then
			self.text:SetFont(font, 13, "")
		else
			self.text:SetFontObject(T.fonts.normal)
		end
	end
	return button
end

---------------------------------------------------------------------------
-- Setting row with a dropdown
---------------------------------------------------------------------------
function W.DropdownRow(form, label, items, get, set, opts)
	opts = opts or {}
	local row = CreateFrame("Frame")
	row.label = T:Text(row, T.fonts.normal, C.text)
	row.label:SetPoint("LEFT", 16, 0)
	row.label:SetText(label)

	local button = W.DropdownButton(row, opts.width, items, get, function(value)
		set(value)
		row:Refresh()
	end, opts)
	button:SetPoint("RIGHT", -16, 0)
	row.label:SetPoint("RIGHT", button, "LEFT", -8, 0)

	function row:Refresh() button:Refresh() end
	row.button = button
	return form:Add(row, opts.full)
end
