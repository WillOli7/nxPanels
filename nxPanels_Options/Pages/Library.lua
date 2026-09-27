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

-- "Interface/AddOns/x.tga" -> "Interface\AddOns\x.tga"; a number is a file id
local function normalizePath(text)
	text = strtrim((text or ""):gsub("[\"']", "") or "")
	if text == "" then return nil end
	if tonumber(text) then return tonumber(text) end
	text = text:gsub("/", "\\"):gsub("\\+", "\\")
	return text
end

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
	core.Media:AddToLibrary(self.kind, name, path)
	page.nameBox.edit:SetText("")
	page.pathBox.edit:SetText("")
	say(L["MEDIA_ADDED"]:format(name), C.success)
	-- Panels waiting for this name can be drawn now
	core.Layouts:RefreshAll()
	Options:Refresh()
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
		page.message = T:Text(card, T.fonts.small, C.textDim)
		page.message:SetPoint("TOPLEFT", help, "BOTTOMLEFT", 0, -6)
		page.message:SetPoint("RIGHT", -16, 0)

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
