local _, O = ...
local T, W, Options = O.Theme, O.Widgets, O.Options
local C = T.colors
local L = O.L
local core = O.core

-- Import and export of layouts as text strings
local Share = { tab = "import", activate = true }
O.SharePage = Share

-- Opens the export tab on a layout
function Share:ShowExport(layoutId)
	self.exportPanels = nil
	self.exportId = layoutId
	self.tab = "export"
	Options:Show("share")
	if self.page then self.page.tabs:Select("export") end
end

-- Opens the export tab on some panels of a layout (a panel, a folder)
function Share:ShowExportPanels(layoutId, ids, label)
	self.exportPanels = { layoutId = layoutId, ids = ids, label = label }
	self.exportId = layoutId
	self.tab = "export"
	Options:Show("share")
	if self.page then self.page.tabs:Select("export") end
end

function Share:ShowImport()
	self.tab = "import"
	Options:Show("share")
	if self.page then self.page.tabs:Select("import") end
end

---------------------------------------------------------------------------
-- Import
---------------------------------------------------------------------------
function Share:Decode()
	local page = self.page
	local text = page.importArea:GetText() or ""
	if text == self.lastText then return end
	self.lastText = text
	local decoded, err
	if strtrim(text) ~= "" then
		decoded, err = core.Share:Decode(text)
	end
	self.decoded = decoded
	page.placeholder:SetShown(text == "")
	local partial = decoded and decoded.kind == "panels"
	page.nameLabel:SetShown(not partial)
	page.nameBox:SetShown(not partial)
	page.activate:SetShown(not partial)
	page.activateLabel:SetShown(not partial)
	if decoded then
		page.info:SetTextColor(unpack(C.text))
		if partial then
			local _, layout = Options:ActiveLayout()
			page.info:SetText(L["IMPORT_INFO_PANELS"]:format(decoded.count, layout and layout.name or L["IMPORTED_LAYOUT"]))
		else
			page.info:SetText(L["IMPORT_INFO"]:format(decoded.format, decoded.count))
		end
		page.nameBox.edit:SetText(decoded.name or L["IMPORTED_LAYOUT"])
		if #decoded.scripted > 0 then
			page.warning:SetText(L["IMPORT_SCRIPTS"]:format(#decoded.scripted, table.concat(decoded.scripted, ", ")))
		else
			page.warning:SetText("")
		end
	else
		page.info:SetTextColor(unpack(err and C.danger or C.textDim))
		page.info:SetText(err or L["IMPORT_HINT"])
		page.warning:SetText("")
	end
	self:RefreshButtons()
end

function Share:RefreshButtons()
	local page = self.page
	local decoded = self.decoded
	page.importButton:SetEnabledState(decoded ~= nil)
	page.noScripts:SetShown(decoded ~= nil and #decoded.scripted > 0)
end

function Share:Import(withScripts)
	local decoded = self.decoded
	if not decoded then return end
	local page = self.page
	local function run()
		local activeId, active = Options:ActiveLayout()
		if decoded.kind == "panels" and decoded.addTo and activeId then
			local ids = decoded.addTo(activeId)
			for _, panelId in ipairs(ids) do
				if not withScripts then
					wipe(active.panels[panelId].scripts)
					active.panels[panelId].scriptDependency = nil
				end
				core.Layouts:PanelChanged(panelId, "added")
			end
			core:Print(L["IMPORT_PANELS_DONE"], #ids, active.name)
			page.importArea:SetText("")
			self.lastText = nil
			self:Decode()
			Options:Refresh()
			return
		end
		local id = core.Share:Import(decoded, page.nameBox.edit:GetText())
		local layout = id and core.Database:GetLayout(id)
		if not layout then return end
		if not withScripts then
			for _, panel in pairs(layout.panels) do
				wipe(panel.scripts)
				panel.scriptDependency = nil
			end
		end
		if self.activate then
			core.Layouts:Activate(id)
		end
		core:Print(L["IMPORT_DONE"], layout.name)
		page.importArea:SetText("")
		self.lastText = nil
		self:Decode()
		Options:Refresh()
	end
	if withScripts and #decoded.scripted > 0 then
		Options:Confirm(L["CONFIRM_IMPORT_SCRIPTS"]:format(table.concat(decoded.scripted, ", ")), run)
	else
		run()
	end
end

local function buildImport(parent, width)
	local page = Share.page
	local f = CreateFrame("Frame", nil, parent)
	f:SetAllPoints(parent)

	page.importArea = W.TextArea(f, width, 190)
	page.importArea:SetPoint("TOPLEFT")
	page.placeholder = T:Text(page.importArea, T.fonts.normal, C.textMuted)
	page.placeholder:SetPoint("TOPLEFT", 10, -10)
	page.placeholder:SetText(L["IMPORT_PASTE"])
	page.importArea.edit:HookScript("OnTextChanged", function() Share:Decode() end)

	local card = CreateFrame("Frame", nil, f)
	card:SetPoint("TOPLEFT", page.importArea, "BOTTOMLEFT", 0, -12)
	card:SetSize(width, 120)
	T:Fill(card, C.card)
	T:Border(card, C.line)
	page.info = T:Text(card, T.fonts.normal, C.textDim)
	page.info:SetPoint("TOPLEFT", 16, -12)
	page.info:SetPoint("RIGHT", -16, 0)
	page.warning = T:Text(card, T.fonts.small, C.danger)
	page.warning:SetPoint("TOPLEFT", page.info, "BOTTOMLEFT", 0, -6)
	page.warning:SetPoint("RIGHT", -16, 0)
	page.warning:SetWordWrap(true)

	page.nameLabel = T:Text(card, T.fonts.normal, C.text)
	page.nameLabel:SetPoint("BOTTOMLEFT", 16, 18)
	page.nameLabel:SetText(L["IMPORT_NAME"])
	page.nameBox = W.EditBox(card, 240, 26)
	page.nameBox:SetPoint("LEFT", page.nameLabel, "RIGHT", 10, 0)

	page.activate = W.Switch(card, function(on) Share.activate = on end)
	page.activate:SetChecked(Share.activate)
	page.activate:SetPoint("BOTTOMRIGHT", -16, 21)
	page.activateLabel = T:Text(card, T.fonts.normal, C.text, "RIGHT")
	page.activateLabel:SetPoint("RIGHT", page.activate, "LEFT", -8, 0)
	page.activateLabel:SetText(L["IMPORT_ACTIVATE"])

	page.importButton = W.Button(f, L["IMPORT"], 150, "primary", function() Share:Import(true) end)
	page.importButton:SetPoint("TOPRIGHT", card, "BOTTOMRIGHT", 0, -12)
	page.noScripts = W.Button(f, L["IMPORT_NO_SCRIPTS"], 200, "default", function() Share:Import(false) end)
	page.noScripts:SetPoint("RIGHT", page.importButton, "LEFT", -8, 0)
	local clear = W.Button(f, L["CLEAR"], 110, "ghost", function()
		page.importArea:SetText("")
		Share:Decode()
	end)
	clear:SetPoint("TOPLEFT", card, "BOTTOMLEFT", 0, -12)
	return f
end

---------------------------------------------------------------------------
-- Export
---------------------------------------------------------------------------
function Share:RefreshExport()
	local page = self.page
	local id = self.exportId
	if not (id and core.Database:GetLayout(id)) then
		id = core.Database:GetActiveLayoutId()
		if not id then
			local first = core.Database:SortedLayouts()[1]
			id = first and first.id
		end
		self.exportId = id
	end
	page.exportLayout:Refresh()
	local panels = self.exportPanels
	if panels then
		self.exportText = core.Share:ExportPanels(panels.layoutId, panels.ids) or ""
		page.exportArea:SetText(self.exportText)
		page.exportInfo:SetText(L["EXPORT_PANELS_INFO"]:format(panels.label, #panels.ids, #self.exportText))
		return
	end
	self.exportText = id and core.Share:Export(id) or ""
	page.exportArea:SetText(self.exportText)
	page.exportInfo:SetText(id and L["EXPORT_INFO"]:format(#self.exportText) or L["NO_LAYOUTS"])
end

local function buildExport(parent, width)
	local page = Share.page
	local f = CreateFrame("Frame", nil, parent)
	f:SetAllPoints(parent)

	local label = T:Text(f, T.fonts.normal, C.text)
	label:SetPoint("TOPLEFT", 0, -6)
	label:SetText(L["EXPORT_LAYOUT"])
	page.exportLayout = W.DropdownButton(f, 260, function()
		local items = {}
		for _, entry in ipairs(core.Database:SortedLayouts()) do
			items[#items + 1] = { value = entry.id, text = entry.layout.name }
		end
		return items
	end, function() return Share.exportId end, function(id)
		Share.exportPanels = nil
		Share.exportId = id
		Share:RefreshExport()
	end)
	page.exportLayout:SetPoint("LEFT", label, "RIGHT", 12, 0)

	local select = W.Button(f, L["SELECT_ALL"], 150, "primary", function()
		page.exportArea.edit:SetFocus()
		page.exportArea.edit:HighlightText()
	end)
	select:SetPoint("TOPRIGHT", 0, 0)

	page.exportArea = W.TextArea(f, width, 330)
	page.exportArea:SetPoint("TOPLEFT", 0, -40)
	-- Read only: typing restores the string
	page.exportArea.edit:HookScript("OnTextChanged", function(self, userInput)
		if userInput then
			self:SetText(Share.exportText or "")
			self:HighlightText()
		end
	end)
	page.exportArea.edit:HookScript("OnEditFocusGained", function(self) self:HighlightText() end)
	page.exportInfo = T:Text(f, T.fonts.small, C.textDim)
	page.exportInfo:SetPoint("TOPLEFT", page.exportArea, "BOTTOMLEFT", 0, -10)
	return f
end

---------------------------------------------------------------------------
-- Gallery of templates
---------------------------------------------------------------------------
-- Adds a template to the active layout, or to a new layout
function Share:AddTemplate(template, newLayout)
	local payload = O.TemplatePayload(template)
	local layoutId = not newLayout and Options:ActiveLayout()
	if not layoutId then
		layoutId = core.Database:CreateLayout(payload.layout.name)
		core.Layouts:Activate(layoutId)
	end
	local ids = core.Share.AddPanels(payload, layoutId)
	for _, panelId in ipairs(ids) do core.Layouts:PanelChanged(panelId, "added") end
	core:Print(L["IMPORT_PANELS_DONE"], #ids, core.Database:GetLayout(layoutId).name)
	Options:Refresh()
	return layoutId, ids
end

local function buildGallery(parent, width)
	local f = CreateFrame("Frame", nil, parent)
	f:SetAllPoints(parent)
	local scroll = W.Scroll(f)
	scroll:SetPoint("TOPLEFT")
	scroll:SetPoint("BOTTOMRIGHT")
	local ROW = 74
	for i, template in ipairs(O.Templates) do
		local card = CreateFrame("Frame", nil, scroll.content)
		card:SetSize(width - 12, ROW - 8)
		card:SetPoint("TOPLEFT", 0, -(i - 1) * ROW)
		T:Fill(card, C.card)
		T:Border(card, C.line)
		local title = T:Text(card, T.fonts.header, C.text)
		title:SetPoint("TOPLEFT", 16, -12)
		title:SetText(L["TPL_" .. template.key])
		local add = W.Button(card, L["TPL_ADD"], 150, "primary", function() Share:AddTemplate(template, false) end)
		add:SetPoint("RIGHT", -12, 0)
		local new = W.Button(card, L["TPL_NEW_LAYOUT"], 150, "default", function() Share:AddTemplate(template, true) end)
		new:SetPoint("RIGHT", add, "LEFT", -8, 0)
		local desc = T:Text(card, T.fonts.small, C.textDim)
		desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
		desc:SetPoint("RIGHT", new, "LEFT", -12, 0)
		desc:SetWordWrap(true)
		desc:SetText(L["TPL_" .. template.key .. "_DESC"])
	end
	scroll:SetContentHeight(#O.Templates * ROW)
	return f
end

---------------------------------------------------------------------------
-- Page
---------------------------------------------------------------------------
Options:RegisterPage({
	key = "share",
	title = L["PAGE_SHARE"],
	subtitle = L["PAGE_SHARE_DESC"],
	icon = "Interface\\Icons\\INV_Letter_15",
	build = function(page, width)
		Share.page = page
		local body = CreateFrame("Frame", nil, page)
		body:SetPoint("TOPLEFT", 0, -48)
		body:SetPoint("BOTTOMRIGHT")
		page.import = buildImport(body, width)
		page.export = buildExport(body, width)
		page.gallery = buildGallery(body, width)
		page.tabs = W.Tabs(page, {
			{ key = "import", text = L["IMPORT"] },
			{ key = "export", text = L["EXPORT"] },
			{ key = "gallery", text = L["GALLERY"] },
		}, function(key)
			Share.tab = key
			page.import:SetShown(key == "import")
			page.export:SetShown(key == "export")
			page.gallery:SetShown(key == "gallery")
			if key == "export" then Share:RefreshExport() end
		end)
		page.tabs:SetPoint("TOPLEFT")
		page.tabs:SetPoint("TOPRIGHT")
		page.tabs:Select(Share.tab)
		Share:Decode()
	end,
	refresh = function(page)
		if Share.tab == "export" then
			page.exportLayout:Refresh()
		end
		Share:RefreshButtons()
	end,
})
