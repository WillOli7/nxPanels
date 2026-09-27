local _, O = ...
local T, W, Options = O.Theme, O.Widgets, O.Options
local C = T.colors
local L = O.L
local core = O.core

-- Layouts: list, activate, create, rename, duplicate, export, delete
local ROW = 58
local rows = {}

local function afterChange()
	core.Layouts:ApplyActive()
	Options:Refresh()
end

local function layoutRow(parent, width)
	local r = CreateFrame("Frame", nil, parent)
	r:SetSize(width, ROW - 8)
	r.bg = T:Fill(r, C.card)
	r.edges = T:Border(r, C.line)
	r.name = T:Text(r, T.fonts.header, C.text)
	r.name:SetPoint("TOPLEFT", 16, -10)
	r.info = T:Text(r, T.fonts.small, C.textDim)
	r.info:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -4)
	r.badge = T:Text(r, T.fonts.small, C.accent)
	r.badge:SetPoint("LEFT", r.name, "RIGHT", 10, 0)
	r.badge:SetText(L["ACTIVE"])

	local x = -12
	local function action(text, style, width, fn)
		local b = W.Button(r, text, width, style, function() fn(r.layoutId, r.layout) end)
		b:SetPoint("RIGHT", x, 0)
		x = x - width - 6
		return b
	end
	action(DELETE, "danger", 90, function(id, layout)
		Options:Confirm(L["CONFIRM_DELETE_LAYOUT"]:format(layout.name), function()
			core.Database:DeleteLayout(id)
			afterChange()
		end)
	end)
	action(L["EXPORT"], "default", 90, function(id)
		O.SharePage:ShowExport(id)
	end)
	action(L["DUPLICATE"], "default", 100, function(id)
		core.Database:DuplicateLayout(id)
		Options:Refresh()
	end)
	action(L["RENAME"], "default", 100, function(id, layout)
		Options:Prompt(L["PROMPT_RENAME_LAYOUT"], layout.name, function(text)
			core.Database:RenameLayout(id, text)
			Options:Refresh()
		end)
	end)
	r.activate = action(L["ACTIVATE"], "primary", 100, function(id)
		core.Layouts:Activate(id)
		Options:Refresh()
	end)
	return r
end

Options:RegisterPage({
	key = "layouts",
	title = L["PAGE_LAYOUTS"],
	subtitle = L["PAGE_LAYOUTS_DESC"],
	icon = "Interface\\Icons\\INV_Misc_Map_01",
	build = function(page, width)
		local new = W.Button(page, L["NEW_LAYOUT"], 160, "primary", function()
			Options:Prompt(L["PROMPT_NEW_LAYOUT"], L["NEW_LAYOUT_NAME"], function(text)
				if strtrim(text) == "" then return end
				local id = core.Database:CreateLayout(strtrim(text))
				core.Layouts:Activate(id)
				Options:Refresh()
			end)
		end)
		new:SetPoint("TOPLEFT", 0, 0)
		local import = W.Button(page, L["IMPORT"], 130, "default", function() O.SharePage:ShowImport() end)
		import:SetPoint("LEFT", new, "RIGHT", 8, 0)

		page.scroll = W.Scroll(page)
		page.scroll:SetPoint("TOPLEFT", 0, -44)
		page.scroll:SetPoint("BOTTOMRIGHT")
		page.width = width
		page.empty = T:Text(page.scroll.content, T.fonts.normal, C.textDim)
		page.empty:SetPoint("TOPLEFT", 4, -8)
		page.empty:SetText(L["NO_LAYOUTS"])
	end,
	refresh = function(page)
		local list = core.Database:SortedLayouts()
		local active = core.Database:GetActiveLayoutId()
		page.empty:SetShown(#list == 0)
		for i, entry in ipairs(list) do
			local r = rows[i] or layoutRow(page.scroll.content, page.width - 12)
			rows[i] = r
			r.layoutId, r.layout = entry.id, entry.layout
			r:ClearAllPoints()
			r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW)
			r:Show()
			r.name:SetText(entry.layout.name)
			r.info:SetText(L["LAYOUT_INFO"]:format(core.Database:CountPanels(entry.layout), #entry.layout.folders))
			local isActive = entry.id == active
			r.badge:SetShown(isActive)
			r.activate:SetEnabledState(not isActive)
			T:SetBorderColor(r.edges, isActive and C.accent or C.line)
		end
		for i = #list + 1, #rows do rows[i]:Hide() end
		page.scroll:SetContentHeight(#list * ROW)
	end,
})
