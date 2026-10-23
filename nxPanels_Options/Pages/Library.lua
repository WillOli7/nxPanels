local _, O = ...
local T, W, Options = O.Theme, O.Widgets, O.Options
local C = T.colors
local L = O.L
local core = O.core

-- User library: backgrounds and borders added by path (saved, shared with LibSharedMedia)
local Library = { kind = "background" }
O.LibraryPage = Library

local ROW = 52
local rows = {}
local WHITE_COLOR = { r = 1, g = 1, b = 1, a = 1 }

-- "Interface/AddOns/x.tga" -> "Interface\AddOns\x.tga"; a number is a file id.
-- A full Windows path (C:\...\_retail_\Interface\AddOns\x.tga) keeps its game part,
-- "AddOns\x.tga" gets its "Interface\".
local function normalizePath(text)
	text = strtrim((text or ""):gsub("[\"']", "") or "")
	if text == "" then return nil end
	if tonumber(text) then return tonumber(text) end
	text = text:gsub("/", "\\"):gsub("\\+", "\\")
	local start = ("\\" .. text:lower()):find("\\interface\\", 1, true)
	if start then
		text = text:sub(start)
	elseif text:lower():find("^addons\\") then
		text = "Interface\\" .. text
	end
	return text
end
Library.NormalizePath = normalizePath

-- Draws a media in a preview frame (texture or border)
local function drawPreview(box, kind, path)
	if kind == "border" then
		box.tex:Hide()
		if path then
			core.Border:Apply(box, path, 12, WHITE_COLOR)
		else
			core.Border:Hide(box)
		end
	else
		core.Border:Hide(box)
		box.tex:SetShown(path ~= nil)
		if path then box.tex:SetTexture(path) end
	end
end

local function previewBox(parent, width, height)
	local box = CreateFrame("Frame", nil, parent)
	box:SetSize(width, height)
	T:Fill(box, C.input)
	box.tex = box:CreateTexture(nil, "ARTWORK")
	box.tex:SetPoint("TOPLEFT", 2, -2)
	box.tex:SetPoint("BOTTOMRIGHT", -2, 2)
	core.Border:Create(box)
	return box
end

local function libraryRow(parent, width)
	local r = CreateFrame("Frame", nil, parent)
	r:SetSize(width, ROW - 6)
	T:Fill(r, C.card)
	T:Border(r, C.line)
	r.preview = previewBox(r, 72, 34)
	r.preview:SetPoint("LEFT", 8, 0)
	r.name = T:Text(r, T.fonts.normal, C.text)
	r.name:SetPoint("TOPLEFT", r.preview, "TOPRIGHT", 12, -2)
	r.path = T:Text(r, T.fonts.small, C.textDim)
	r.path:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -4)
	r.delete = W.Button(r, L["DELETE"], 90, "danger", function()
		Options:Confirm(L["CONFIRM_DELETE_MEDIA"]:format(r.key), function()
			core.Media:RemoveFromLibrary(Library.kind, r.key)
			Options:Refresh()
		end)
	end)
	r.delete:SetPoint("RIGHT", -10, 0)
	r.name:SetPoint("RIGHT", r.delete, "LEFT", -10, 0)
	r.path:SetPoint("RIGHT", r.delete, "LEFT", -10, 0)
	return r
end

function Library:Add()
	local page = self.page
	local name = strtrim(page.nameBox.edit:GetText() or "")
	local path = normalizePath(page.pathBox.edit:GetText())
	local function say(text, color)
		page.message:SetText(text)
		page.message:SetTextColor(unpack(color))
	end
	if name == "" or not path then
		say(L["MEDIA_MISSING_FIELDS"], C.danger)
		return
	end
	if core.Media.LSM:IsValid(self.kind, name) and not core.db.global.media[self.kind][name] then
		say(L["MEDIA_NAME_TAKEN"]:format(name), C.danger)
		return
	end
	-- The game only reads files of its Interface folder
	if type(path) == "string" and not path:lower():find("^interface\\") then
		say(L["MEDIA_BAD_PATH"], C.danger)
		return
	end
	local known = core.Media:AddToLibrary(self.kind, name, path)
	page.nameBox.edit:SetText("")
	page.pathBox.edit:SetText("")
	if known then
		say(L["MEDIA_ADDED"]:format(name), C.success)
	else
		say(L["MEDIA_ADDED_NOT_FOUND"]:format(name), C.warning)
	end
	-- Panels waiting for this name can be drawn now
	core.Layouts:RefreshAll()
	Options:Refresh()
end

---------------------------------------------------------------------------
-- Several files at once: paths pasted from the file explorer ("Copy as path"),
-- one per line. Each name comes from its file name.
---------------------------------------------------------------------------
-- Free name: "art", then "art (2)"... (names used by other addons are taken too)
local function freeName(kind, name)
	local library = core.db.global.media[kind]
	local function taken(n) return library[n] ~= nil or core.Media.LSM:IsValid(kind, n) end
	local candidate, n = name, 1
	while taken(candidate) do
		n = n + 1
		candidate = ("%s (%d)"):format(name, n)
	end
	return candidate
end

--[[
Adds every path of the text to the library of `kind`. Returns a summary:
{ added = { names }, existing = n, outside = { paths }, notFound = { names } }
]]
function Library:AddMany(kind, text)
	local library = core.db.global.media[kind]
	local known = {}
	for _, path in pairs(library) do known[tostring(path):lower()] = true end
	local result = { added = {}, existing = 0, outside = {}, notFound = {} }
	for line in (text or ""):gmatch("[^\r\n]+") do
		local path = normalizePath(line)
		if type(path) == "string" then
			local file = path:match("([^\\]+)$") or path
			local name = strtrim((file:gsub("%.[^%.]*$", "")))
			if not path:lower():find("^interface\\") then
				result.outside[#result.outside + 1] = file
			elseif known[path:lower()] then
				result.existing = result.existing + 1
			elseif name ~= "" then
				name = freeName(kind, name)
				known[path:lower()] = true
				result.added[#result.added + 1] = name
				if not core.Media:AddToLibrary(kind, name, path) then
					result.notFound[#result.notFound + 1] = name
				end
			end
		end
	end
	if #result.added > 0 then
		core.Layouts:RefreshAll()
		Options:Refresh()
	end
	return result
end

-- Text of a summary, and whether everything went well
local function summary(result)
	local lines = {}
	if #result.added == 0 and result.existing == 0 and #result.outside == 0 then
		return L["MANY_EMPTY"], false
	end
	lines[#lines + 1] = L["MANY_ADDED"]:format(#result.added)
	if result.existing > 0 then lines[#lines + 1] = L["MANY_EXISTING"]:format(result.existing) end
	if #result.outside > 0 then
		lines[#lines + 1] = L["MANY_OUTSIDE"]:format(#result.outside, table.concat(result.outside, ", "))
	end
	if #result.notFound > 0 then
		lines[#lines + 1] = L["MANY_NOT_FOUND"]:format(#result.notFound, table.concat(result.notFound, ", "))
	end
	return table.concat(lines, "\n"), #result.outside == 0 and #result.notFound == 0
end

local function createManyWindow()
	local f = CreateFrame("Frame", "nxPanelsAddMany", UIParent)
	f:SetSize(640, 650)
	f:SetPoint("CENTER")
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetClampedToScreen(true)
	T:Fill(f, C.window)
	T:Border(f, C.accent)
	tinsert(UISpecialFrames, "nxPanelsAddMany")

	f.title = T:Text(f, T.fonts.header, C.text)
	f.title:SetPoint("TOPLEFT", 20, -18)
	local close = W.Button(f, "X", 28, "ghost", function() f:Hide() end)
	close:SetPoint("TOPRIGHT", -12, -12)

	-- Which kind of files this window adds: fonds and bordures must not be mixed
	-- Spaced lines: long explanations stay easy to read
	f.kindText = T:Text(f, T.fonts.normal, C.warning)
	f.kindText:SetPoint("TOPLEFT", 20, -52)
	f.kindText:SetPoint("RIGHT", -20, 0)
	f.kindText:SetWordWrap(true)
	f.kindText:SetSpacing(4)
	-- One text per paragraph of the help, so the steps 1, 2, 3 are spaced out
	local previous, gap = f.kindText, 16
	for paragraph in (L["MANY_HELP"] .. "\n"):gmatch("(.-)\n") do
		if paragraph == "" then
			gap = 16
		else
			local text = T:Text(f, T.fonts.small, C.textDim)
			text:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -gap)
			text:SetPoint("RIGHT", -20, 0)
			text:SetWordWrap(true)
			text:SetSpacing(5)
			text:SetText(paragraph)
			previous, gap = text, 10
		end
	end

	f.area = W.TextArea(f, 600, 150)
	f.area:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -18)
	f.placeholder = T:Text(f.area, T.fonts.normal, C.textMuted)
	f.placeholder:SetPoint("TOPLEFT", 10, -10)
	f.placeholder:SetText(L["MANY_PASTE"])
	f.area.edit:HookScript("OnTextChanged", function(self)
		f.placeholder:SetShown((self:GetText() or "") == "")
	end)

	f.result = T:Text(f, T.fonts.small, C.textDim)
	f.result:SetPoint("TOPLEFT", f.area, "BOTTOMLEFT", 0, -12)
	f.result:SetPoint("RIGHT", -20, 0)
	f.result:SetWordWrap(true)
	f.result:SetSpacing(4)

	local done = W.Button(f, L["DONE"], 120, nil, function() f:Hide() end)
	done:SetPoint("BOTTOMRIGHT", -20, 16)
	f.addAll = W.Button(f, L["MANY_ADD"], 160, "primary", function()
		local result = Library:AddMany(f.kind, f.area:GetText())
		local text, clean = summary(result)
		f.result:SetText(text)
		f.result:SetTextColor(unpack(clean and C.success or C.warning))
		if clean and #result.added > 0 then f.area:SetText("") end
	end)
	f.addAll:SetPoint("RIGHT", done, "LEFT", -8, 0)
	return f
end

-- Opens the window for the current tab (backgrounds or borders)
function Library:OpenMany()
	local f = self.manyWindow or createManyWindow()
	self.manyWindow = f
	f.kind = self.kind
	local border = self.kind == "border"
	f.title:SetText(border and L["MANY_TITLE_BORDER"] or L["MANY_TITLE_BACKGROUND"])
	f.kindText:SetText(border and L["MANY_KIND_BORDER"] or L["MANY_KIND_BACKGROUND"])
	f.area:SetText("")
	f.placeholder:Show()
	f.result:SetText("")
	f:Show()
end

Options:RegisterPage({
	key = "library",
	title = L["PAGE_LIBRARY"],
	subtitle = L["PAGE_LIBRARY_DESC"],
	icon = "Interface\\Icons\\INV_Misc_Book_09",
	build = function(page, width)
		Library.page = page
		local tabs = W.Tabs(page, {
			{ key = "background", text = L["BACKGROUNDS"] },
			{ key = "border", text = L["BORDERS"] },
		}, function(key)
			Library.kind = key
			if page.list then Options:Refresh() end
		end)
		tabs:SetPoint("TOPLEFT")
		tabs:SetPoint("TOPRIGHT")

		-- Add form
		local card = CreateFrame("Frame", nil, page)
		card:SetPoint("TOPLEFT", 0, -46)
		card:SetSize(width, 124)
		T:Fill(card, C.card)
		T:Border(card, C.line)

		local nameLabel = T:Text(card, T.fonts.small, C.textDim)
		nameLabel:SetPoint("TOPLEFT", 16, -12)
		nameLabel:SetText(L["MEDIA_NAME"])
		page.nameBox = W.EditBox(card, 180, 26)
		page.nameBox:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -6)

		local pathLabel = T:Text(card, T.fonts.small, C.textDim)
		pathLabel:SetPoint("LEFT", nameLabel, "LEFT", 196, 0)
		pathLabel:SetText(L["MEDIA_PATH"])
		-- Between the name box (ends at 212) and the preview (starts at width - 222)
		page.pathBox = W.EditBox(card, width - 212 - 222 - 12, 26)
		page.pathBox:SetPoint("TOPLEFT", pathLabel, "BOTTOMLEFT", 0, -6)

		page.preview = previewBox(card, 96, 48)
		page.preview:SetPoint("TOPRIGHT", -126, -12)
		local add = W.Button(card, L["ADD"], 100, "primary", function() Library:Add() end)
		add:SetPoint("TOPRIGHT", -16, -12)

		page.pathBox.edit:SetScript("OnTextChanged", function(self)
			drawPreview(page.preview, Library.kind, normalizePath(self:GetText()))
		end)
		page.pathBox.edit:SetScript("OnEnterPressed", function() Library:Add() end)
		page.nameBox.edit:SetScript("OnTabPressed", function() page.pathBox.edit:SetFocus() end)
		page.nameBox.edit:SetScript("OnEnterPressed", function() page.pathBox.edit:SetFocus() end)

		local help = T:Text(card, T.fonts.small, C.textMuted)
		help:SetPoint("TOPLEFT", page.nameBox, "BOTTOMLEFT", 0, -10)
		help:SetPoint("RIGHT", page.preview, "LEFT", -12, 0)
		help:SetWordWrap(true)
		help:SetText(L["MEDIA_HELP"])
		-- Several files: under the preview and the add button
		page.addMany = W.Button(card, L["ADD_MANY"], 206, nil, function() Library:OpenMany() end)
		page.addMany:SetPoint("BOTTOMRIGHT", -16, 12)
		page.message = T:Text(card, T.fonts.small, C.textDim)
		page.message:SetPoint("TOPLEFT", help, "BOTTOMLEFT", 0, -6)
		page.message:SetPoint("RIGHT", page.addMany, "LEFT", -12, 0)

		-- List
		page.list = W.Scroll(page)
		page.list:SetPoint("TOPLEFT", 0, -184)
		page.list:SetPoint("BOTTOMRIGHT")
		page.empty = T:Text(page.list.content, T.fonts.normal, C.textDim)
		page.empty:SetPoint("TOPLEFT", 4, -8)
		page.empty:SetPoint("RIGHT", -8, 0)
		page.empty:SetWordWrap(true)
		page.width = width
		tabs:Select(Library.kind)
	end,
	refresh = function(page)
		local kind = Library.kind
		local library = core.db.global.media[kind]
		local names = {}
		for name in pairs(library) do names[#names + 1] = name end
		table.sort(names, function(a, b) return a:lower() < b:lower() end)
		for i, name in ipairs(names) do
			local r = rows[i] or libraryRow(page.list.content, page.width - 12)
			rows[i] = r
			r.key = name
			r:ClearAllPoints()
			r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW)
			r:Show()
			r.name:SetText(name)
			r.path:SetText(tostring(library[name]))
			-- A file the game does not find shows in warning color
			r.path:SetTextColor(unpack(core.Media:IsKnownFile(library[name]) and C.textDim or C.warning))
			drawPreview(r.preview, kind, library[name])
		end
		for i = #names + 1, #rows do rows[i]:Hide() end
		local others = 0
		for _, name in ipairs(core.Media.LSM:List(kind)) do
			if name ~= "None" and not library[name] then others = others + 1 end
		end
		page.empty:SetShown(#names == 0)
		page.empty:SetText(L["MEDIA_EMPTY"])
		page.list:SetContentHeight(math.max(#names * ROW, 40))
		drawPreview(page.preview, kind, normalizePath(page.pathBox.edit:GetText()))
		Options.subtitle:SetText(L["PAGE_LIBRARY_DESC"] .. " " .. L["MEDIA_OTHERS"]:format(others))
	end,
})
