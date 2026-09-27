local _, O = ...
local T = O.Theme
local C = T.colors

-- Controls of the options window. Row controls ("setting rows") share one API:
-- row:Refresh() reads the value again, row.isShown() (optional) hides the row.
local W = {}
O.Widgets = W

local ROW_HEIGHT = 40
local PAD = 16
W.ROW_HEIGHT = ROW_HEIGHT

---------------------------------------------------------------------------
-- Basic controls
---------------------------------------------------------------------------
local BUTTON_STYLES = {
	default = { bg = C.card, hover = C.cardHover, border = C.lineStrong, text = C.text },
	primary = { bg = { 0.2, 0.8, 1, 0.16 }, hover = { 0.2, 0.8, 1, 0.28 }, border = C.accent, text = C.accent },
	danger = { bg = C.dangerSoft, hover = { 1, 0.38, 0.38, 0.26 }, border = C.danger, text = C.danger },
	ghost = { bg = { 0, 0, 0, 0 }, hover = C.cardHover, border = { 0, 0, 0, 0 }, text = C.textDim },
}

function W.Button(parent, text, width, style, onClick)
	local s = BUTTON_STYLES[style or "default"]
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(width or 120, 28)
	b.bg = T:Fill(b, s.bg)
	b.edges = T:Border(b, s.border)
	b.label = T:Text(b, T.fonts.normal, s.text, "CENTER")
	b.label:SetPoint("CENTER")
	b.label:SetText(text)
	b:SetScript("OnEnter", function() b.bg:SetVertexColor(unpack(s.hover)) end)
	b:SetScript("OnLeave", function() b.bg:SetVertexColor(unpack(s.bg)) end)
	b:SetScript("OnClick", function(self, button) if onClick then onClick(self, button) end end)
	-- Long translations: smaller font rather than text over the border
	function b:SetText(t)
		self.label:SetFontObject(T.fonts.normal)
		self.label:SetText(t)
		if self.label:GetStringWidth() > self:GetWidth() - 12 then
			self.label:SetFontObject(T.fonts.small)
		end
	end
	b:SetText(text)
	function b:SetEnabledState(enabled)
		self:SetEnabled(enabled)
		self:SetAlpha(enabled and 1 or 0.4)
	end
	return b
end

function W.EditBox(parent, width, height, multiLine)
	local box = CreateFrame("Frame", nil, parent)
	box:SetSize(width or 160, height or 26)
	T:Fill(box, C.input)
	box.edges = T:Border(box, C.lineStrong)
	local e = CreateFrame("EditBox", nil, box)
	e:SetFontObject(T.fonts.normal)
	e:SetTextColor(unpack(C.text))
	e:SetAutoFocus(false)
	e:SetMultiLine(multiLine and true or false)
	e:SetTextInsets(8, 8, 0, 0)
	e:SetAllPoints(box)
	e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	e:SetScript("OnEditFocusGained", function() T:SetBorderColor(box.edges, C.accent) end)
	e:SetScript("OnEditFocusLost", function() T:SetBorderColor(box.edges, C.lineStrong) end)
	box.edit = e
	return box
end

-- On/off switch
function W.Switch(parent, onChange)
	local s = CreateFrame("Button", nil, parent)
	s:SetSize(38, 20)
	s.track = T:Fill(s, C.input)
	s.edges = T:Border(s, C.lineStrong)
	s.knob = s:CreateTexture(nil, "ARTWORK")
	s.knob:SetTexture(T.WHITE)
	s.knob:SetSize(14, 14)
	function s:SetChecked(on)
		self.checked = on and true or false
		self.knob:ClearAllPoints()
		if self.checked then
			self.knob:SetPoint("RIGHT", -3, 0)
			self.knob:SetVertexColor(unpack(C.accent))
			self.track:SetVertexColor(unpack(C.accentSoft))
			T:SetBorderColor(self.edges, C.accent)
		else
			self.knob:SetPoint("LEFT", 3, 0)
			self.knob:SetVertexColor(unpack(C.textMuted))
			self.track:SetVertexColor(unpack(C.input))
			T:SetBorderColor(self.edges, C.lineStrong)
		end
	end
	s:SetScript("OnClick", function(self)
		self:SetChecked(not self.checked)
		if onChange then onChange(self.checked) end
	end)
	s:SetChecked(false)
	return s
end

-- Scroll area with a slim scrollbar; put the content in scroll.content
function W.Scroll(parent)
	local scroll = CreateFrame("ScrollFrame", nil, parent)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	scroll.content = content

	local bar = CreateFrame("Frame", nil, scroll)
	bar:SetPoint("TOPRIGHT", 0, 0)
	bar:SetPoint("BOTTOMRIGHT", 0, 0)
	bar:SetWidth(4)
	T:Fill(bar, C.line)
	local thumb = bar:CreateTexture(nil, "ARTWORK")
	thumb:SetTexture(T.WHITE)
	thumb:SetVertexColor(unpack(C.textMuted))
	thumb:SetWidth(4)

	function scroll:UpdateBar()
		local visible, total = self:GetHeight(), content:GetHeight()
		if total <= visible + 1 or visible <= 0 then
			bar:Hide()
			self:SetVerticalScroll(0)
			return
		end
		bar:Show()
		local h = math.max(24, visible * visible / total)
		local maxScroll = total - visible
		local offset = (self:GetVerticalScroll() / maxScroll) * (visible - h)
		thumb:SetHeight(h)
		thumb:ClearAllPoints()
		thumb:SetPoint("TOP", bar, "TOP", 0, -offset)
	end

	function scroll:SetContentHeight(height)
		content:SetHeight(math.max(height, 1))
		local maxScroll = math.max(0, height - self:GetHeight())
		if self:GetVerticalScroll() > maxScroll then self:SetVerticalScroll(maxScroll) end
		self:UpdateBar()
	end

	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local maxScroll = math.max(0, content:GetHeight() - self:GetHeight())
		self:SetVerticalScroll(math.min(maxScroll, math.max(0, self:GetVerticalScroll() - delta * 48)))
		self:UpdateBar()
	end)
	scroll:SetScript("OnSizeChanged", function(self, width)
		content:SetWidth(width)
		self:UpdateBar()
	end)
	return scroll
end

-- Tab bar: tabs = { { key = "...", text = "..." }, ... }
function W.Tabs(parent, tabs, onSelect)
	local bar = CreateFrame("Frame", nil, parent)
	bar:SetHeight(34)
	local line = T:Line(bar)
	line:SetPoint("BOTTOMLEFT")
	line:SetPoint("BOTTOMRIGHT")
	bar.buttons = {}
	local x = 0
	for _, tab in ipairs(tabs) do
		local b = CreateFrame("Button", nil, bar)
		b.key = tab.key
		b.label = T:Text(b, T.fonts.header, C.textDim, "CENTER")
		b.label:SetPoint("CENTER", 0, 2)
		b.label:SetText(tab.text)
		b:SetSize(b.label:GetStringWidth() + 28, 34)
		b:SetPoint("BOTTOMLEFT", x, 0)
		x = x + b:GetWidth()
		b.underline = b:CreateTexture(nil, "ARTWORK")
		b.underline:SetTexture(T.WHITE)
		b.underline:SetVertexColor(unpack(C.accent))
		b.underline:SetHeight(2)
		b.underline:SetPoint("BOTTOMLEFT", 8, 0)
		b.underline:SetPoint("BOTTOMRIGHT", -8, 0)
		b:SetScript("OnClick", function() bar:Select(tab.key) end)
		b:SetScript("OnEnter", function() if bar.selected ~= tab.key then b.label:SetTextColor(unpack(C.text)) end end)
		b:SetScript("OnLeave", function() if bar.selected ~= tab.key then b.label:SetTextColor(unpack(C.textDim)) end end)
		bar.buttons[#bar.buttons + 1] = b
	end
	function bar:Select(key)
		self.selected = key
		for _, b in ipairs(self.buttons) do
			local on = b.key == key
			b.label:SetTextColor(unpack(on and C.text or C.textDim))
			b.underline:SetShown(on)
		end
		if onSelect then onSelect(key) end
	end
	return bar
end

---------------------------------------------------------------------------
-- Form: setting rows laid out in two columns inside cards, like
-- EllesmereUI. Rows added with full = true take the whole width.
---------------------------------------------------------------------------
local Form = {}
Form.__index = Form

-- columns: 2 (default) or 1 (every row takes the whole width)
function W.Form(parent, width, columns)
	local form = setmetatable({ parent = parent, width = width, columns = columns or 2, items = {}, rows = {}, cards = {} }, Form)
	return form
end

function Form:Section(title)
	local header = T:Text(self.parent, T.fonts.small, C.textMuted)
	-- No upper(): it would break accented and non-latin letters
	header:SetText(title or "")
	self.items[#self.items + 1] = { kind = "section", header = header }
end

function Form:Add(row, full)
	row:SetParent(self.parent)
	self.items[#self.items + 1] = { kind = "row", row = row, full = full }
	self.rows[#self.rows + 1] = row
	return row
end

local function newCard(form)
	local card = CreateFrame("Frame", nil, form.parent)
	card:SetFrameLevel(math.max(0, form.parent:GetFrameLevel()))
	T:Fill(card, C.card)
	T:Border(card, C.line)
	card.divider = card:CreateTexture(nil, "ARTWORK")
	card.divider:SetTexture(T.WHITE)
	card.divider:SetVertexColor(unpack(C.line))
	card.divider:SetWidth(1)
	card.divider:SetPoint("TOP", 0, -8)
	card.divider:SetPoint("BOTTOM", 0, 8)
	form.cards[#form.cards + 1] = card
	return card
end

-- Places every visible row; returns the total height
function Form:Layout()
	local colWidth = math.floor(self.width / 2)
	-- Starts at 4: room for the first header, clipped by the scroll frame otherwise
	local y, col, cardIndex, card, cardTop, hasHalf = 4, 0, 0, nil, 4, false

	local function closeCard()
		if not card then return end
		if col == 1 then y = y + ROW_HEIGHT; col = 0 end
		card:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, -cardTop)
		card:SetSize(self.width, math.max(1, y - cardTop))
		card:SetShown(y > cardTop)
		card.divider:SetShown(hasHalf)
		card = nil
	end

	for _, item in ipairs(self.items) do
		if item.kind == "section" then
			closeCard()
			if y > 4 then y = y + 18 end
			item.header:ClearAllPoints()
			item.header:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 2, -y)
			y = y + 20
			cardIndex = cardIndex + 1
			card = self.cards[cardIndex] or newCard(self)
			cardTop, col, hasHalf = y, 0, false
		else
			local row = item.row
			if row.isShown and not row.isShown() then
				row:Hide()
			else
				if not card then
					cardIndex = cardIndex + 1
					card = self.cards[cardIndex] or newCard(self)
					cardTop, col, hasHalf = y, 0, false
				end
				row:Show()
				row:ClearAllPoints()
				local h = row.fixedHeight or ROW_HEIGHT
				if item.full or self.columns == 1 then
					if col == 1 then y = y + ROW_HEIGHT; col = 0 end
					row:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 0, -y)
					row:SetSize(self.width, h)
					y = y + h
				else
					hasHalf = true
					row:SetPoint("TOPLEFT", self.parent, "TOPLEFT", col * colWidth, -y)
					row:SetSize(colWidth, ROW_HEIGHT)
					if col == 1 then y = y + ROW_HEIGHT; col = 0 else col = 1 end
				end
			end
		end
	end
	closeCard()
	for i = cardIndex + 1, #self.cards do self.cards[i]:Hide() end
	self.height = y
	return y
end

function Form:Refresh()
	for _, row in ipairs(self.rows) do
		if row.Refresh then row:Refresh() end
	end
	return self:Layout()
end

---------------------------------------------------------------------------
-- Setting rows
---------------------------------------------------------------------------
local function baseRow(label)
	local row = CreateFrame("Frame")
	row.label = T:Text(row, T.fonts.normal, C.text)
	row.label:SetPoint("LEFT", PAD, 0)
	row.label:SetText(label or "")
	return row
end

function W.ToggleRow(form, label, get, set, tooltip)
	local row = baseRow(label)
	row.switch = W.Switch(row, function(on) set(on) end)
	row.switch:SetPoint("RIGHT", -PAD, 0)
	row.label:SetPoint("RIGHT", row.switch, "LEFT", -8, 0)
	if tooltip then T:Tooltip(row.switch, label, tooltip) end
	function row:Refresh() self.switch:SetChecked(get()) end
	return form:Add(row)
end

local function formatValue(value, step)
	if step and step < 1 then
		local text = ("%.2f"):format(value):gsub("0+$", ""):gsub("%.$", "")
		return text
	end
	return tostring(math.floor(value + 0.5))
end

-- min and max can be functions (range depending on another setting).
-- opts.free: the input box accepts values outside the slider range.
function W.SliderRow(form, label, min, max, step, get, set, opts)
	opts = opts or {}
	local row = baseRow(label)
	local function range()
		return type(min) == "function" and min() or min, type(max) == "function" and max() or max
	end
	local valueBox = W.EditBox(row, 52, 22)
	valueBox:SetPoint("RIGHT", -PAD, 0)
	valueBox.edit:SetJustifyH("CENTER")
	valueBox.edit:SetTextInsets(2, 2, 0, 0)

	local slider = CreateFrame("Slider", nil, row)
	slider:SetOrientation("HORIZONTAL")
	slider:SetSize(130, 16)
	slider:SetPoint("RIGHT", valueBox, "LEFT", -10, 0)
	-- The range is set by Refresh (it can depend on the edited panel)
	slider:SetValueStep(step)
	slider:SetObeyStepOnDrag(true)
	local track = slider:CreateTexture(nil, "BACKGROUND")
	track:SetTexture(T.WHITE)
	track:SetVertexColor(unpack(C.lineStrong))
	track:SetHeight(3)
	track:SetPoint("LEFT")
	track:SetPoint("RIGHT")
	local fill = slider:CreateTexture(nil, "ARTWORK")
	fill:SetTexture(T.WHITE)
	fill:SetVertexColor(unpack(C.accent))
	fill:SetHeight(3)
	fill:SetPoint("LEFT")
	slider:SetThumbTexture(T.WHITE)
	local thumb = slider:GetThumbTexture()
	thumb:SetSize(10, 14)
	thumb:SetVertexColor(unpack(C.accent))
	fill:SetPoint("RIGHT", thumb, "CENTER")
	row.label:SetPoint("RIGHT", slider, "LEFT", -8, 0)

	local updating = false
	slider:SetScript("OnValueChanged", function(_, value, userInput)
		valueBox.edit:SetText(formatValue(value, step))
		if userInput and not updating then set(value) end
	end)
	-- opts.onRelease: called when the slider is released
	slider:SetScript("OnMouseUp", function() if opts.onRelease then opts.onRelease() end end)
	valueBox.edit:SetScript("OnEnterPressed", function(self)
		local v = tonumber(self:GetText())
		if v then
			local lo, hi = range()
			if not opts.free then v = math.min(hi, math.max(lo, v)) end
			set(v)
			if opts.onRelease then opts.onRelease() end
		end
		self:ClearFocus()
		row:Refresh()
	end)
	valueBox.edit:SetScript("OnEditFocusLost", function(self)
		T:SetBorderColor(valueBox.edges, C.lineStrong)
		row:Refresh()
	end)
	function row:Refresh()
		updating = true
		local lo, hi = range()
		slider:SetMinMaxValues(lo, hi)
		local v = get() or lo
		slider:SetValue(math.min(hi, math.max(lo, v)))
		valueBox.edit:SetText(formatValue(v, step))
		updating = false
	end
	row.slider, row.valueBox = slider, valueBox
	return form:Add(row)
end

-- opts.numeric: number input; opts.width: box width; opts.full: whole row
function W.InputRow(form, label, get, set, opts)
	opts = opts or {}
	local row = baseRow(label)
	local box = W.EditBox(row, opts.width or 170, 24)
	box:SetPoint("RIGHT", -PAD, 0)
	row.label:SetPoint("RIGHT", box, "LEFT", -8, 0)
	local function commit(self)
		local text = self:GetText()
		if opts.numeric then
			local v = tonumber(text)
			if v then set(v) end
		else
			set(text)
		end
		row:Refresh()
	end
	box.edit:SetScript("OnEnterPressed", function(self) commit(self) self:ClearFocus() end)
	box.edit:HookScript("OnEditFocusLost", function(self) commit(self) end)
	function row:Refresh()
		if not box.edit:HasFocus() then
			local v = get()
			box.edit:SetText(v ~= nil and tostring(v) or "")
			box.edit:SetCursorPosition(0)
		end
	end
	row.box = box
	return form:Add(row, opts.full)
end

function W.ColorRow(form, label, get, set, hasAlpha)
	local row = baseRow(label)
	local swatch = CreateFrame("Button", nil, row)
	swatch:SetSize(44, 22)
	swatch:SetPoint("RIGHT", -PAD, 0)
	local checker = T:Fill(swatch, { 0.3, 0.3, 0.3, 1 })
	checker:SetDrawLayer("BACKGROUND", 0)
	local color = swatch:CreateTexture(nil, "ARTWORK")
	color:SetTexture(T.WHITE)
	color:SetPoint("TOPLEFT", 1, -1)
	color:SetPoint("BOTTOMRIGHT", -1, 1)
	T:Border(swatch, C.lineStrong)
	row.label:SetPoint("RIGHT", swatch, "LEFT", -8, 0)

	swatch:SetScript("OnClick", function()
		local c = get()
		local previous = { r = c.r, g = c.g, b = c.b, a = c.a }
		local picker = ColorPickerFrame
		local function alpha()
			if picker.GetColorAlpha then return picker:GetColorAlpha() end
			-- Older picker: the slider holds the transparency
			return OpacitySliderFrame and 1 - OpacitySliderFrame:GetValue() or previous.a
		end
		local function apply()
			local r, g, b = picker:GetColorRGB()
			set({ r = r, g = g, b = b, a = hasAlpha and alpha() or previous.a })
			row:Refresh()
		end
		local function cancel() set(previous) row:Refresh() end
		if picker.SetupColorPickerAndShow then
			picker:SetupColorPickerAndShow({
				r = c.r, g = c.g, b = c.b,
				opacity = c.a,
				hasOpacity = hasAlpha,
				swatchFunc = apply,
				opacityFunc = apply,
				cancelFunc = cancel,
			})
		else
			picker:Hide()
			picker.func, picker.opacityFunc, picker.cancelFunc = apply, apply, cancel
			picker.hasOpacity, picker.opacity = hasAlpha, 1 - (c.a or 1)
			picker:SetColorRGB(c.r, c.g, c.b)
			ShowUIPanel(picker)
		end
	end)
	function row:Refresh()
		local c = get()
		color:SetVertexColor(c.r, c.g, c.b, c.a or 1)
	end
	return form:Add(row)
end

-- buttons = { { text = "...", style = "...", width = n, onClick = fn }, ... }
function W.ButtonsRow(form, buttons, label)
	local row = baseRow(label)
	row.buttons = {}
	local previous
	for i = #buttons, 1, -1 do
		local def = buttons[i]
		local b = W.Button(row, def.text, def.width or 130, def.style, def.onClick)
		row.buttons[i] = b
		if previous then
			b:SetPoint("RIGHT", previous, "LEFT", -8, 0)
		else
			b:SetPoint("RIGHT", -PAD, 0)
		end
		previous = b
		def.button = b
	end
	return form:Add(row, true)
end

-- Paragraph of text on the whole width
function W.TextRow(form, text, height)
	local row = CreateFrame("Frame")
	row.fixedHeight = height or 48
	row.text = T:Text(row, T.fonts.normal, C.textDim)
	row.text:SetPoint("TOPLEFT", PAD, -12)
	row.text:SetPoint("BOTTOMRIGHT", -PAD, 8)
	row.text:SetWordWrap(true)
	row.text:SetJustifyV("TOP")
	function row:SetText(t) self.text:SetText(t) end
	row:SetText(text)
	return form:Add(row, true)
end

---------------------------------------------------------------------------
-- Multi-line text area with a scrollbar (text of a panel, scripts, strings)
-- area.edit is the EditBox; area:SetText / area:GetText
---------------------------------------------------------------------------
function W.TextArea(parent, width, height)
	local area = CreateFrame("Frame", nil, parent)
	area:SetSize(width, height)
	T:Fill(area, C.input)
	area.edges = T:Border(area, C.lineStrong)

	local scroll = W.Scroll(area)
	scroll:SetPoint("TOPLEFT", 8, -6)
	scroll:SetPoint("BOTTOMRIGHT", -4, 6)
	area.scroll = scroll

	local e = CreateFrame("EditBox", nil, scroll.content)
	e:SetMultiLine(true)
	e:SetAutoFocus(false)
	e:SetMaxLetters(0)
	e:SetFontObject(T.fonts.normal)
	e:SetTextColor(unpack(C.text))
	e:SetPoint("TOPLEFT")
	e:SetPoint("TOPRIGHT", -10, 0)
	e:SetHeight(20)
	area.edit = e

	local function fit()
		scroll:SetContentHeight(math.max(e:GetHeight(), 20))
	end
	e:SetScript("OnSizeChanged", fit)
	e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	e:SetScript("OnEditFocusGained", function() T:SetBorderColor(area.edges, C.accent) end)
	e:SetScript("OnEditFocusLost", function() T:SetBorderColor(area.edges, C.lineStrong) end)
	-- Tab inserts spaces instead of leaving the box
	e:SetScript("OnTabPressed", function(self) self:Insert("    ") end)
	-- Keeps the cursor visible
	e:SetScript("OnCursorChanged", function(_, _, y, _, h)
		local top, visible = -y, scroll:GetHeight()
		local offset = scroll:GetVerticalScroll()
		if top < offset then
			scroll:SetVerticalScroll(top)
		elseif top + h > offset + visible then
			scroll:SetVerticalScroll(top + h - visible)
		end
		scroll:UpdateBar()
	end)
	-- A click anywhere in the area focuses the text
	area:EnableMouse(true)
	area:SetScript("OnMouseDown", function()
		e:SetFocus()
		e:SetCursorPosition(#(e:GetText() or ""))
	end)

	function area:SetText(text)
		e:SetText(text or "")
		e:SetCursorPosition(0)
		scroll:SetVerticalScroll(0)
		fit()
	end
	function area:GetText() return e:GetText() end
	return area
end

-- Setting row holding a text area; commits with the returned row.commit()
-- opts.height, opts.live (set on every change instead of on focus lost)
function W.TextAreaRow(form, label, get, set, opts)
	opts = opts or {}
	local row = CreateFrame("Frame")
	local height = opts.height or 120
	row.fixedHeight = height + (label and 36 or 20)
	row.label = T:Text(row, T.fonts.normal, C.text)
	row.label:SetPoint("TOPLEFT", PAD, -10)
	row.label:SetText(label or "")
	local area = W.TextArea(row, 100, height)
	area:SetPoint("TOPLEFT", PAD, label and -30 or -10)
	area:SetPoint("TOPRIGHT", -PAD, label and -30 or -10)
	row.area = area

	local function commit() set(area:GetText()) end
	row.commit = commit
	area.edit:HookScript("OnTextChanged", function(_, userInput)
		if userInput and opts.live then commit() end
	end)
	area.edit:HookScript("OnEditFocusLost", function() if not opts.live then commit() end end)
	function row:Refresh()
		if not area.edit:HasFocus() then area:SetText(get()) end
	end
	return form:Add(row, true)
end
