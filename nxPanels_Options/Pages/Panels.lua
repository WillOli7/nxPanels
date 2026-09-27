local _, O = ...
local T, W, Options = O.Theme, O.Widgets, O.Options
local C = T.colors
local L = O.L
local core = O.core

--[[
Panels of the active layout: list by folders on the left, editor on the right
(General / Background / Border / Text / Scripts). Every change is saved and
drawn at once.
]]
local Panels = {}
O.PanelsPage = Panels

local LIST_WIDTH, GAP, ROW = 250, 16, 26
local POINTS = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
local STRATA = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }
local HOOKS = { "LOAD", "EVENT", "UPDATE", "SHOW", "HIDE", "ENTER", "LEAVE", "CLICK", "RESIZE", "DROP" }
local SECTIONS = { "TOP", "BOT", "LEFT", "RIGHT", "TOPLEFTCORNER", "TOPRIGHTCORNER", "BOTLEFTCORNER", "BOTRIGHTCORNER" }

Panels.collapsed = {}   -- [folder] = true
Panels.tab = "general"
Panels.hook = "LOAD"
Panels.drafts = {}      -- [panelId .. hook] = unsaved script text
Panels.filter = ""

---------------------------------------------------------------------------
-- Current panel
---------------------------------------------------------------------------
local function current()
	local layoutId, layout = Options:ActiveLayout()
	local id = Panels.selected
	return layout and id and layout.panels[id], id, layout, layoutId
end

local function P() return (current()) end

-- Called by every setter: redraws the panel and reads the editor again
local function changed(what)
	if what and Panels.selected then
		core.Layouts:PanelChanged(Panels.selected, what)
	end
	Panels:RefreshEditor()
end

-- Text boxes commit on focus lost: commit them before the selection changes
local function clearFocus()
	local focus = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
	if focus then focus:ClearFocus() end
end

local function sortedPanels(layout)
	local list = {}
	for id, panel in pairs(layout.panels) do
		list[#list + 1] = { id = id, panel = panel }
	end
	table.sort(list, function(a, b)
		local na, nb = a.panel.name:lower(), b.panel.name:lower()
		if na == nb then return a.id < b.id end
		return na < nb
	end)
	return list
end

local function folderItems()
	local _, _, layout = current()
	local items = { { value = "", text = L["NO_FOLDER"] } }
	for _, folder in ipairs(layout and layout.folders or {}) do
		items[#items + 1] = { value = folder, text = folder }
	end
	return items
end

-- Frames a panel can be attached to: the screen, the other panels, any frame by name
local function frameItems()
	local _, id, layout = current()
	local items = { { value = "UIParent", text = L["SCREEN"] } }
	if layout then
		for _, entry in ipairs(sortedPanels(layout)) do
			if entry.id ~= id then
				items[#items + 1] = { value = "panel:" .. entry.id, text = L["PANEL_REF"]:format(entry.panel.name) }
			end
		end
	end
	items[#items + 1] = { value = "__custom", text = L["OTHER_FRAME"] }
	return items
end

local function frameRef(ref)
	return (ref == nil or ref == "") and "UIParent" or ref
end

-- Setter of a parent / anchor reference; "__custom" asks for a frame name
local function setFrameRef(apply)
	return function(value)
		if value ~= "__custom" then
			apply(value)
			changed("anchors")
			return
		end
		Options:Prompt(L["PROMPT_FRAME_NAME"], "", function(text)
			text = strtrim(text or "")
			apply(text == "" and "UIParent" or text)
			changed("anchors")
		end)
	end
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------
function Panels:Select(id)
	clearFocus()
	self.selected = id
	Options:Refresh()
end

function Panels:NewPanel(folder)
	local layoutId = Options:ActiveLayout()
	if not layoutId then return end
	Options:Prompt(L["PROMPT_NEW_PANEL"], L["NEW_PANEL_NAME"], function(text)
		text = strtrim(text or "")
		if text == "" then return end
		local id = core.Database:CreatePanel(layoutId, text, folder)
		core.Layouts:PanelChanged(id, "added")
		if folder then self.collapsed[folder] = nil end
		self:Select(id)
	end)
end

function Panels:Duplicate(id)
	local layoutId = Options:ActiveLayout()
	local newId = core.Database:DuplicatePanel(layoutId, id)
	if newId then
		core.Layouts:PanelChanged(newId, "added")
		self:Select(newId)
	end
end

function Panels:Delete(id)
	local layoutId, layout = Options:ActiveLayout()
	local panel = layout and layout.panels[id]
	if not panel then return end
	Options:Confirm(L["CONFIRM_DELETE_PANEL"]:format(panel.name), function()
		clearFocus()
		core.Database:DeletePanel(layoutId, id)
		core.Layouts:PanelChanged(id, "removed")
		if self.selected == id then self.selected = nil end
		Options:Refresh()
	end)
end

function Panels:Rename(id)
	local layoutId, layout = Options:ActiveLayout()
	local panel = layout and layout.panels[id]
	if not panel then return end
	Options:Prompt(L["PROMPT_RENAME_PANEL"], panel.name, function(text)
		core.Database:RenamePanel(layoutId, id, text)
		Options:Refresh()
	end)
end

function Panels:MoveToFolder(id, owner)
	local _, layout = Options:ActiveLayout()
	local panel = layout and layout.panels[id]
	if not panel then return end
	O.Dropdown:Open(owner, folderItems(), panel.folder or "", function(value)
		panel.folder = value ~= "" and value or nil
		Options:Refresh()
	end)
end

function Panels:NewFolder()
	local layoutId = Options:ActiveLayout()
	if not layoutId then return end
	Options:Prompt(L["PROMPT_NEW_FOLDER"], L["NEW_FOLDER_NAME"], function(text)
		core.Database:AddFolder(layoutId, text)
		Options:Refresh()
	end)
end

function Panels:RenameFolder(name)
	local layoutId = Options:ActiveLayout()
	Options:Prompt(L["PROMPT_RENAME_FOLDER"], name, function(text)
		local new = core.Database:RenameFolder(layoutId, name, text)
		if new and self.collapsed[name] then
			self.collapsed[name] = nil
			self.collapsed[new] = true
		end
		Options:Refresh()
	end)
end

function Panels:DeleteFolder(name)
	local layoutId = Options:ActiveLayout()
	Options:Confirm(L["CONFIRM_DELETE_FOLDER"]:format(name), function()
		core.Database:DeleteFolder(layoutId, name)
		self.collapsed[name] = nil
		Options:Refresh()
	end)
end

local function panelMenu(owner, id)
	O.Dropdown:Open(owner, {
		{ value = "edit", text = L["EDIT"] },
		{ value = "rename", text = L["RENAME"] },
		{ value = "duplicate", text = L["DUPLICATE"] },
		{ value = "move", text = L["MOVE_TO_FOLDER"] },
		{ value = "delete", text = L["DELETE"] },
	}, nil, function(action)
		if action == "edit" then Panels:Select(id)
		elseif action == "rename" then Panels:Rename(id)
		elseif action == "duplicate" then Panels:Duplicate(id)
		elseif action == "move" then Panels:MoveToFolder(id, owner)
		elseif action == "delete" then Panels:Delete(id)
		end
	end)
end

local function folderMenu(owner, name)
	O.Dropdown:Open(owner, {
		{ value = "new", text = L["NEW_PANEL_HERE"] },
		{ value = "rename", text = L["RENAME"] },
		{ value = "delete", text = L["DELETE"] },
	}, nil, function(action)
		if action == "new" then Panels:NewPanel(name)
		elseif action == "rename" then Panels:RenameFolder(name)
		elseif action == "delete" then Panels:DeleteFolder(name)
		end
	end)
end

---------------------------------------------------------------------------
-- List by folders
---------------------------------------------------------------------------
local listRows = {}

local function listRow(parent, i)
	local r = listRows[i]
	if r then return r end
	r = CreateFrame("Button", nil, parent)
	r:SetHeight(ROW)
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	r.bg = T:Fill(r, { 0, 0, 0, 0 })
	r.bar = r:CreateTexture(nil, "ARTWORK")
	r.bar:SetTexture(T.WHITE)
	r.bar:SetVertexColor(unpack(C.accent))
	r.bar:SetWidth(2)
	r.bar:SetPoint("TOPLEFT")
	r.bar:SetPoint("BOTTOMLEFT")
	r.sign = T:Text(r, T.fonts.normal, C.textDim, "CENTER")
	r.sign:SetWidth(14)
	r.label = T:Text(r, T.fonts.normal, C.text)
	r.count = T:Text(r, T.fonts.small, C.textMuted, "RIGHT")
	r.count:SetPoint("RIGHT", -8, 0)
	r:SetScript("OnEnter", function(self)
		if not self.selected then self.bg:SetVertexColor(unpack(C.cardHover)) end
	end)
	r:SetScript("OnLeave", function(self)
		if not self.selected then self.bg:SetVertexColor(0, 0, 0, 0) end
	end)
	r:SetScript("OnClick", function(self, button)
		local e = self.entry
		if e.kind == "folder" then
			if button == "RightButton" then
				folderMenu(self, e.name)
			else
				Panels.collapsed[e.name] = not Panels.collapsed[e.name] or nil
				Panels:RefreshList()
			end
		elseif button == "RightButton" then
			panelMenu(self, e.id)
		else
			Panels:Select(e.id)
		end
	end)
	listRows[i] = r
	return r
end

function Panels:RefreshList()
	local page = self.page
	local _, _, layout = current()
	local entries = {}
	if layout then
		local filter = self.filter
		local byFolder, root = {}, {}
		local known = {}
		for _, folder in ipairs(layout.folders) do
			known[folder] = true
			byFolder[folder] = {}
		end
		for _, entry in ipairs(sortedPanels(layout)) do
			if filter == "" or entry.panel.name:lower():find(filter, 1, true) then
				local folder = entry.panel.folder
				if folder and known[folder] then
					table.insert(byFolder[folder], entry)
				else
					root[#root + 1] = entry
				end
			end
		end
		for _, folder in ipairs(layout.folders) do
			local list = byFolder[folder]
			if filter == "" or #list > 0 then
				local open = filter ~= "" or not self.collapsed[folder]
				entries[#entries + 1] = { kind = "folder", name = folder, count = #list, open = open }
				if open then
					for _, entry in ipairs(list) do
						entries[#entries + 1] = { kind = "panel", id = entry.id, panel = entry.panel, indent = true }
					end
				end
			end
		end
		for _, entry in ipairs(root) do
			entries[#entries + 1] = { kind = "panel", id = entry.id, panel = entry.panel }
		end
	end

	local content = page.list.scroll.content
	local width = LIST_WIDTH - 14
	local waiting = core.Layouts.waiting
	for i, e in ipairs(entries) do
		local r = listRow(content, i)
		r.entry = e
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW)
		r:SetWidth(width)
		r:Show()
		r.sign:ClearAllPoints()
		r.label:ClearAllPoints()
		if e.kind == "folder" then
			r.selected = false
			r.sign:SetPoint("LEFT", 8, 0)
			r.sign:SetText(e.open and "-" or "+")
			r.sign:Show()
			r.label:SetPoint("LEFT", r.sign, "RIGHT", 6, 0)
			r.label:SetPoint("RIGHT", r.count, "LEFT", -6, 0)
			r.label:SetText(e.name)
			r.label:SetTextColor(unpack(C.textDim))
			r.count:SetText(e.count)
			r.count:Show()
		else
			r.selected = e.id == self.selected
			r.sign:Hide()
			r.count:Hide()
			r.label:SetPoint("LEFT", e.indent and 28 or 10, 0)
			r.label:SetPoint("RIGHT", -8, 0)
			r.label:SetText(e.panel.name)
			local dim = waiting[e.id] or not core.Layouts.frames[e.id]
			r.label:SetTextColor(unpack(r.selected and C.accent or dim and C.textMuted or C.text))
		end
		r.bar:SetShown(r.selected)
		r.bg:SetVertexColor(unpack(r.selected and C.accentSoft or { 0, 0, 0, 0 }))
	end
	for i = #entries + 1, #listRows do listRows[i]:Hide() end
	page.list.empty:SetShown(#entries == 0)
	page.list.scroll:SetContentHeight(#entries * ROW)
end

---------------------------------------------------------------------------
-- Editor tabs
---------------------------------------------------------------------------
local function colorGetSet(path, key, what)
	return function() return path()[key] end,
		function(c) path()[key] = { r = c.r, g = c.g, b = c.b, a = c.a } changed(what or "look") end
end

local function buildGeneral(form)
	form:Section(L["SECTION_PANEL"])
	W.InputRow(form, L["NAME"], function() return P().name end, function(text)
		local _, id, _, layoutId = current()
		if core.Database:RenamePanel(layoutId, id, text) then Panels:RefreshList() end
		Panels.page.editor.name:SetText(P().name)
	end, { width = 220 })
	W.DropdownRow(form, L["FOLDER"], folderItems, function() return P().folder or "" end, function(value)
		P().folder = value ~= "" and value or nil
		Panels:RefreshList()
	end)

	form:Section(L["SECTION_SIZE"])
	local units = { { value = "px", text = L["UNIT_PX"] }, { value = "%", text = L["UNIT_PERCENT"] } }
	local function maxSize(key) return function() return P()[key] == "%" and 100 or 2000 end end
	W.SliderRow(form, L["WIDTH"], 0, maxSize("widthUnit"), 1, function() return P().width end,
		function(v) P().width = v changed("look") end, { free = true })
	W.DropdownRow(form, L["WIDTH_UNIT"], units, function() return P().widthUnit end,
		function(v) P().widthUnit = v changed("look") end)
	W.SliderRow(form, L["HEIGHT"], 0, maxSize("heightUnit"), 1, function() return P().height end,
		function(v) P().height = v changed("look") end, { free = true })
	W.DropdownRow(form, L["HEIGHT_UNIT"], units, function() return P().heightUnit end,
		function(v) P().heightUnit = v changed("look") end)
	W.SliderRow(form, L["SCALE"], 0.1, 3, 0.01, function() return P().scale end,
		function(v) P().scale = math.max(0.01, v) changed("look") end, { free = true })

	form:Section(L["SECTION_POSITION"])
	local points = Options:Choices(POINTS, "POINT_")
	W.DropdownRow(form, L["POINT"], points, function() return P().anchor.point end,
		function(v) P().anchor.point = v changed("look") end)
	W.DropdownRow(form, L["ANCHORED_TO"], frameItems, function() return frameRef(P().anchor.relativeTo) end,
		setFrameRef(function(v) P().anchor.relativeTo = v end), { width = 220 })
	W.DropdownRow(form, L["RELATIVE_POINT"], points, function() return P().anchor.relativePoint end,
		function(v) P().anchor.relativePoint = v changed("look") end)
	W.SliderRow(form, L["OFFSET_X"], -1500, 1500, 1, function() return P().anchor.x end,
		function(v) P().anchor.x = v changed("geometry") end, { free = true })
	W.SliderRow(form, L["OFFSET_Y"], -1000, 1000, 1, function() return P().anchor.y end,
		function(v) P().anchor.y = v changed("geometry") end, { free = true })
	W.DropdownRow(form, L["PARENT"], frameItems, function() return frameRef(P().parent) end,
		setFrameRef(function(v) P().parent = v end), { width = 220 })
	local status = W.TextRow(form, "", 44)
	status.text:SetTextColor(unpack(C.danger))
	status.isShown = function()
		local id = Panels.selected
		return core.Layouts.waiting[id] or core.Layouts.cyclic[id]
	end
	function status:Refresh()
		local id = Panels.selected
		if core.Layouts.cyclic[id] then
			self:SetText(L["STATUS_CYCLE"])
		else
			self:SetText(L["STATUS_WAITING"])
		end
	end

	form:Section(L["SECTION_DISPLAY"])
	W.DropdownRow(form, L["STRATA"], Options:Choices(STRATA, "STRATA_"), function() return P().strata end,
		function(v) P().strata = v changed("look") end)
	W.SliderRow(form, L["LEVEL"], 0, 100, 1, function() return P().level end,
		function(v) P().level = math.max(0, math.floor(v)) changed("look") end, { free = true })
	W.ToggleRow(form, L["MOUSE"], function() return P().mouse end,
		function(v) P().mouse = v changed("look") end, L["MOUSE_DESC"])
end

local function buildBackground(form)
	local function bg() return P().background end
	form:Section(L["SECTION_TEXTURE"])
	W.DropdownRow(form, L["TEXTURE"], function() return Options:MediaItems("background") end,
		function() return bg().texture end, function(v) bg().texture = v changed("look") end,
		{ preview = "texture", width = 240 })
	W.DropdownRow(form, L["STYLE"], Options:Choices({ "SOLID", "GRADIENT", "NONE" }, "STYLE_"),
		function() return bg().style end, function(v) bg().style = v changed("look") end)
	local get, set = colorGetSet(bg, "color")
	W.ColorRow(form, L["COLOR"], get, set, true)
	local isGradient = function() return bg().style == "GRADIENT" end
	get, set = colorGetSet(bg, "color2")
	W.ColorRow(form, L["COLOR_END"], get, set, true).isShown = isGradient
	W.DropdownRow(form, L["ORIENTATION"], Options:Choices({ "HORIZONTAL", "VERTICAL" }, "ORIENT_"),
		function() return bg().orientation end, function(v) bg().orientation = v changed("look") end).isShown = isGradient
	W.SliderRow(form, L["OPACITY"], 0, 1, 0.01, function() return bg().alpha end,
		function(v) bg().alpha = v changed("look") end)
	W.DropdownRow(form, L["BLEND"], Options:Choices({ "BLEND", "ADD", "MOD", "ALPHAKEY", "DISABLE" }, "BLEND_"),
		function() return bg().blend end, function(v) bg().blend = v changed("look") end)

	form:Section(L["SECTION_TRANSFORM"])
	local custom = function() return bg().texCoord ~= nil end
	W.SliderRow(form, L["ROTATION"], 0, 359, 1, function() return bg().rotation end,
		function(v) bg().rotation = math.floor(v) % 360 changed("look") end).isShown = function() return not custom() end
	W.ButtonsRow(form, { { text = L["RESET_COORDS"], width = 180, onClick = function()
		bg().texCoord = nil
		changed("look")
	end } }, L["CUSTOM_COORDS"]).isShown = custom
	W.ToggleRow(form, L["FLIP_H"], function() return bg().flipH end, function(v) bg().flipH = v changed("look") end)
	W.ToggleRow(form, L["FLIP_V"], function() return bg().flipV end, function(v) bg().flipV = v changed("look") end)
	W.ToggleRow(form, L["TILE"], function() return bg().tile end, function(v) bg().tile = v changed("look") end, L["TILE_DESC"])
	W.SliderRow(form, L["TILE_SIZE"], 0, 512, 1, function() return bg().tileSize end,
		function(v) bg().tileSize = math.max(0, v) changed("look") end, { free = true }).isShown = function() return bg().tile end
	W.SliderRow(form, L["SUBLEVEL"], -8, 7, 1, function() return bg().subLevel end,
		function(v) bg().subLevel = math.floor(v) changed("look") end)

	form:Section(L["SECTION_INSETS"])
	for _, side in ipairs({ "left", "right", "top", "bottom" }) do
		W.SliderRow(form, L["INSET_" .. side:upper()], -64, 64, 1, function() return bg().insets[side] end,
			function(v) bg().insets[side] = v changed("look") end, { free = true })
	end
end

local function buildBorder(form)
	local function border() return P().border end
	form:Section(L["SECTION_BORDER"])
	W.DropdownRow(form, L["TEXTURE"], function() return Options:MediaItems("border") end,
		function() return border().texture end, function(v) border().texture = v changed("look") end,
		{ preview = "border", width = 240 })
	local get, set = colorGetSet(border, "color")
	W.ColorRow(form, L["COLOR"], get, set, true)
	W.SliderRow(form, L["BORDER_SIZE"], 1, 64, 1, function() return border().size end,
		function(v) border().size = math.max(1, v) changed("look") end, { free = true })

	form:Section(L["SECTION_BORDER_PARTS"])
	for _, section in ipairs(SECTIONS) do
		W.ToggleRow(form, L["PART_" .. section], function() return not border().hidden[section] end, function(on)
			border().hidden[section] = not on or nil
			changed("look")
		end)
	end
end

local function buildText(form)
	local function text() return P().text end
	form:Section(L["SECTION_TEXT"])
	W.TextAreaRow(form, nil, function() return text().value end,
		function(v) text().value = v changed("look") end, { height = 80, live = true })
	W.TextRow(form, L["TEXT_HELP"], 40)

	form:Section(L["SECTION_FONT"])
	W.DropdownRow(form, L["FONT"], function() return Options:MediaItems("font") end,
		function() return text().font end, function(v) text().font = v changed("look") end,
		{ preview = "font", width = 240 })
	W.SliderRow(form, L["FONT_SIZE"], 4, 72, 1, function() return text().size end,
		function(v) text().size = math.max(1, v) changed("look") end, { free = true })
	W.DropdownRow(form, L["OUTLINE"], Options:Choices({ "", "OUTLINE", "THICKOUTLINE" }, "OUTLINE_"),
		function() return text().outline end, function(v) text().outline = v changed("look") end)
	local get, set = colorGetSet(text, "color")
	W.ColorRow(form, L["COLOR"], get, set, true)

	form:Section(L["SECTION_TEXT_POSITION"])
	W.DropdownRow(form, L["JUSTIFY_H"], Options:Choices({ "LEFT", "CENTER", "RIGHT" }, "JUSTIFY_"),
		function() return text().justifyH end, function(v) text().justifyH = v changed("look") end)
	W.DropdownRow(form, L["JUSTIFY_V"], Options:Choices({ "TOP", "MIDDLE", "BOTTOM" }, "JUSTIFY_"),
		function() return text().justifyV end, function(v) text().justifyV = v changed("look") end)
	W.SliderRow(form, L["OFFSET_X"], -500, 500, 1, function() return text().x end,
		function(v) text().x = v changed("look") end, { free = true })
	W.SliderRow(form, L["OFFSET_Y"], -500, 500, 1, function() return text().y end,
		function(v) text().y = v changed("look") end, { free = true })
end

-- Scripts are edited as drafts and applied with the Save button
local function draftKey() return tostring(Panels.selected) .. Panels.hook end
local function savedScript() return P().scripts[Panels.hook] or "" end

local function buildScripts(form)
	form:Section(L["SECTION_SCRIPTS"])
	local function hookItems()
		local panel = P()
		local items = {}
		for i, hook in ipairs(HOOKS) do
			local text = L["HOOK_" .. hook]
			local code = panel and panel.scripts[hook]
			if Panels.drafts[tostring(Panels.selected) .. hook] then
				text = text .. "  |cffffd100" .. L["MODIFIED"] .. "|r"
			elseif code and code:find("%S") then
				text = text .. "  |cff33ccff*|r"
			end
			items[i] = { value = hook, text = text }
		end
		return items
	end
	W.DropdownRow(form, L["SCRIPT"], hookItems, function() return Panels.hook end, function(v)
		clearFocus()
		Panels.hook = v
		Panels:RefreshEditor()
	end, { width = 240 })

	local code = W.TextAreaRow(form, nil, function()
		return Panels.drafts[draftKey()] or savedScript()
	end, function() end, { height = 220 })
	code.area.edit:HookScript("OnTextChanged", function(self, userInput)
		if not userInput then return end
		local text = self:GetText()
		Panels.drafts[draftKey()] = text ~= savedScript() and text or nil
	end)

	W.ButtonsRow(form, {
		{ text = L["REVERT"], onClick = function()
			Panels.drafts[draftKey()] = nil
			clearFocus()
			code.area:SetText(savedScript())
			Panels:RefreshEditor()
		end },
		{ text = L["SAVE_RUN"], style = "primary", width = 160, onClick = function()
			local text = code.area:GetText() or ""
			Panels.drafts[draftKey()] = nil
			P().scripts[Panels.hook] = text:find("%S") and text or nil
			clearFocus()
			changed("scripts")
		end },
	})
	W.TextRow(form, L["SCRIPTS_HELP"], 124)

	form:Section(L["SECTION_SCRIPT_OPTIONS"])
	W.InputRow(form, L["SCRIPT_DEPENDENCY"], function() return P().scriptDependency or "" end, function(text)
		text = strtrim(text or "")
		local value = text ~= "" and text or nil
		if value ~= P().scriptDependency then
			P().scriptDependency = value
			changed("scripts")
		end
	end, { width = 200 })
	W.TextRow(form, L["SCRIPT_DEPENDENCY_DESC"], 40)
end

local TABS = {
	{ key = "general", text = L["TAB_GENERAL"], build = buildGeneral },
	{ key = "background", text = L["TAB_BACKGROUND"], build = buildBackground },
	{ key = "border", text = L["TAB_BORDER"], build = buildBorder },
	{ key = "text", text = L["TAB_TEXT"], build = buildText },
	{ key = "scripts", text = L["TAB_SCRIPTS"], build = buildScripts },
}

---------------------------------------------------------------------------
-- Editor
---------------------------------------------------------------------------
function Panels:RefreshEditor()
	local editor = self.page.editor
	local panel = P()
	if not panel then
		editor:Hide()
		self.page.hint:SetShown(Options:ActiveLayout() ~= nil)
		return
	end
	self.page.hint:Hide()
	editor:Show()
	editor.name:SetText(panel.name)
	for key, tab in pairs(editor.tabs) do
		tab.scroll:SetShown(key == self.tab)
	end
	local tab = editor.tabs[self.tab]
	tab.scroll:SetContentHeight(tab.form:Refresh())
end

local function buildEditor(page, x, width)
	local editor = CreateFrame("Frame", nil, page)
	editor:SetPoint("TOPLEFT", x, 0)
	editor:SetPoint("BOTTOMRIGHT")
	page.editor = editor

	local delete = W.Button(editor, L["DELETE"], 100, "danger", function() Panels:Delete(Panels.selected) end)
	delete:SetPoint("TOPRIGHT", 0, 0)
	local duplicate = W.Button(editor, L["DUPLICATE"], 110, "default", function() Panels:Duplicate(Panels.selected) end)
	duplicate:SetPoint("RIGHT", delete, "LEFT", -6, 0)
	local move = W.Button(editor, L["EDIT_MODE"], 110, "default", function() O.EditMode:Start(Panels.selected) end)
	move:SetPoint("RIGHT", duplicate, "LEFT", -6, 0)
	editor.name = T:Text(editor, T.fonts.header, C.text)
	editor.name:SetPoint("LEFT", editor, "TOPLEFT", 0, -14)
	editor.name:SetPoint("RIGHT", move, "LEFT", -10, 0)

	editor.tabs = {}
	local bar = W.Tabs(editor, TABS, function(key)
		clearFocus()
		Panels.tab = key
		if Panels.page.hint then Panels:RefreshEditor() end
	end)
	bar:SetPoint("TOPLEFT", 0, -38)
	bar:SetPoint("TOPRIGHT", 0, -38)
	editor.bar = bar

	for _, def in ipairs(TABS) do
		local scroll = W.Scroll(editor)
		scroll:SetPoint("TOPLEFT", 0, -84)
		scroll:SetPoint("BOTTOMRIGHT")
		scroll.content:SetWidth(width)
		local form = W.Form(scroll.content, width - 12, 1)
		def.build(form)
		scroll:Hide()
		editor.tabs[def.key] = { scroll = scroll, form = form }
	end
end

---------------------------------------------------------------------------
-- Page
---------------------------------------------------------------------------
local function layoutItems()
	local items = {}
	for _, entry in ipairs(core.Database:SortedLayouts()) do
		items[#items + 1] = { value = entry.id, text = entry.layout.name }
	end
	return items
end

Options:RegisterPage({
	key = "panels",
	title = L["PAGE_PANELS"],
	subtitle = L["PAGE_PANELS_DESC"],
	icon = "Interface\\Icons\\INV_Misc_Note_02",
	build = function(page, width)
		Panels.page = page

		-- Left column: layout, actions, search, list
		local layoutButton = W.DropdownButton(page, LIST_WIDTH, layoutItems,
			function() return (Options:ActiveLayout()) end,
			function(id)
				clearFocus()
				Panels.selected = nil
				core.Layouts:Activate(id)
				Options:Refresh()
			end)
		layoutButton:SetHeight(28)
		layoutButton:SetPoint("TOPLEFT", 0, 0)
		page.layoutButton = layoutButton

		local newPanel = W.Button(page, L["NEW_PANEL"], (LIST_WIDTH - 6) / 2, "primary", function()
			local panel = P()
			Panels:NewPanel(panel and panel.folder)
		end)
		newPanel:SetPoint("TOPLEFT", 0, -36)
		local newFolder = W.Button(page, L["NEW_FOLDER"], (LIST_WIDTH - 6) / 2, "default", function() Panels:NewFolder() end)
		newFolder:SetPoint("LEFT", newPanel, "RIGHT", 6, 0)

		local search = W.EditBox(page, LIST_WIDTH, 24)
		search:SetPoint("TOPLEFT", 0, -72)
		local placeholder = T:Text(search, T.fonts.normal, C.textMuted)
		placeholder:SetPoint("LEFT", 8, 0)
		placeholder:SetText(L["SEARCH"])
		search.edit:SetScript("OnTextChanged", function(self)
			local text = strtrim(self:GetText() or "")
			placeholder:SetShown(text == "")
			Panels.filter = text:lower()
			Panels:RefreshList()
		end)
		page.search = search

		local list = CreateFrame("Frame", nil, page)
		list:SetPoint("TOPLEFT", 0, -104)
		list:SetPoint("BOTTOMLEFT")
		list:SetWidth(LIST_WIDTH)
		T:Fill(list, C.card)
		T:Border(list, C.line)
		list.scroll = W.Scroll(list)
		list.scroll:SetPoint("TOPLEFT", 4, -4)
		list.scroll:SetPoint("BOTTOMRIGHT", -4, 4)
		list.empty = T:Text(list, T.fonts.normal, C.textMuted)
		list.empty:SetPoint("TOPLEFT", 12, -12)
		list.empty:SetPoint("RIGHT", -12, 0)
		list.empty:SetWordWrap(true)
		list.empty:SetText(L["NO_PANELS"])
		page.list = list

		-- Right column: editor, or a hint
		local x = LIST_WIDTH + GAP
		buildEditor(page, x, width - x)
		page.hint = T:Text(page, T.fonts.normal, C.textDim)
		page.hint:SetPoint("TOPLEFT", x, -8)
		page.hint:SetPoint("RIGHT", 0, 0)
		page.hint:SetWordWrap(true)
		page.hint:SetText(L["SELECT_PANEL"])

		-- No active layout
		local none = CreateFrame("Frame", nil, page)
		none:SetAllPoints(page)
		none:SetFrameLevel(page:GetFrameLevel() + 20)
		T:Fill(none, C.window)
		local noneText = T:Text(none, T.fonts.header, C.textDim)
		noneText:SetPoint("TOPLEFT", 0, -8)
		noneText:SetText(L["NO_ACTIVE_LAYOUT"])
		local go = W.Button(none, L["PAGE_LAYOUTS"], 160, "primary", function() Options:Show("layouts") end)
		go:SetPoint("TOPLEFT", noneText, "BOTTOMLEFT", 0, -14)
		none:EnableMouse(true)
		page.noLayout = none
		page.editor.bar:Select(Panels.tab)
	end,
	refresh = function(page)
		local layoutId, layout = Options:ActiveLayout()
		page.noLayout:SetShown(not layoutId)
		page.layoutButton:Refresh()
		if Panels.selected and not (layout and layout.panels[Panels.selected]) then
			Panels.selected = nil
		end
		Panels:RefreshList()
		Panels:RefreshEditor()
	end,
})

-- Opens the editor on a panel (edit mode, other modules)
function Options:EditPanel(panelId)
	Options:Show("panels")
	Panels:Select(panelId)
end
