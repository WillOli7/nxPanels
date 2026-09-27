local _, O = ...
local W, Options = O.Widgets, O.Options
local L = O.L
local core = O.core

--[[
Profiles (AceDB): a profile chooses the default layout, a layout per
specialization, and whether the panels are shown. Layouts themselves are shared
by every profile, so a profile can be used by a whole class or faction.
]]
local function db() return core.db end

local function profileItems(exceptCurrent)
	local items = {}
	local list = db():GetProfiles({})
	table.sort(list, function(a, b) return a:lower() < b:lower() end)
	local currentName = db():GetCurrentProfile()
	for _, name in ipairs(list) do
		if not (exceptCurrent and name == currentName) then
			items[#items + 1] = { value = name, text = name }
		end
	end
	return items
end

-- firstText: text of the "false" item (no layout, or the default layout)
local function layoutItems(firstText)
	local items = { { value = false, text = firstText } }
	for _, entry in ipairs(core.Database:SortedLayouts()) do
		items[#items + 1] = { value = entry.id, text = entry.layout.name }
	end
	return items
end

-- Shows the layout that must be shown now, only when it changed
local function applyIfChanged()
	if core.Layouts.activeId ~= core.Database:GetActiveLayoutId() then
		core.Layouts:ApplyActive()
	end
	Options:Refresh()
end

local function className() return (UnitClass("player")) end
local function factionName() return select(2, UnitFactionGroup("player")) end

local function useProfile(name)
	if name and name ~= db():GetCurrentProfile() then
		db():SetProfile(name)
	end
	Options:Refresh()
end

local function build(page, width)
	local scroll, form = Options:ScrollForm(page, width)
	page.scroll, page.form = scroll, form

	form:Section(L["SECTION_CURRENT_PROFILE"])
	W.DropdownRow(form, L["PROFILE"], function() return profileItems(false) end,
		function() return db():GetCurrentProfile() end, useProfile)
	W.ButtonsRow(form, {
		{ text = L["NEW_PROFILE"], style = "primary", width = 150, onClick = function()
			Options:Prompt(L["PROMPT_NEW_PROFILE"], "", function(text)
				text = strtrim(text or "")
				if text ~= "" then useProfile(text) end
			end)
		end },
		{ text = L["RESET_PROFILE"], style = "danger", width = 150, onClick = function()
			Options:Confirm(L["CONFIRM_RESET_PROFILE"]:format(db():GetCurrentProfile()), function()
				db():ResetProfile()
				Options:Refresh()
			end)
		end },
	}, nil, true)
	W.DropdownRow(form, L["NEW_CHARACTERS"], {
		{ value = "default", text = L["NEW_CHARACTERS_DEFAULT"] },
		{ value = "class", text = L["NEW_CHARACTERS_CLASS"] },
		{ value = "faction", text = L["NEW_CHARACTERS_FACTION"] },
	},
		function() return db().global.newCharacters end,
		function(v) db().global.newCharacters = v end)
	local shared = W.ButtonsRow(form, {
		{ text = "", width = 150, onClick = function() useProfile(className()) end },
		{ text = "", width = 150, onClick = function() useProfile(factionName()) end },
	}, nil, true)
	function shared:Refresh()
		self.buttons[1]:SetText(L["PROFILE_OF_CLASS"]:format(className() or "?"))
		self.buttons[2]:SetText(L["PROFILE_OF_FACTION"]:format(factionName() or "?"))
		self.buttons[2]:SetEnabledState(factionName() ~= nil)
	end
	W.TextRow(form, L["PROFILES_HELP"], 56)

	form:Section(L["SECTION_PROFILE_CONTENT"])
	W.DropdownRow(form, L["DEFAULT_LAYOUT"], function() return layoutItems(L["LAYOUT_NONE_ITEM"]) end,
		function() return core.Database:GetDefaultLayoutId() or false end,
		function(id)
			core.Database:SetDefaultLayoutId(id or nil)
			applyIfChanged()
		end, { width = 200 })
	W.ToggleRow(form, L["SHOW_PANELS"], function() return db().profile.enabled end,
		function(on) core.Layouts:SetEnabled(on) Options:Refresh() end)

	form:Section(L["SECTION_SPECS"])
	for _, spec in ipairs(core.Specs:List()) do
		local row = W.DropdownRow(form, spec.name, function() return layoutItems(L["SPEC_DEFAULT_LAYOUT"]) end,
			function() return core.Database:GetSpecLayoutId(spec.key) or false end,
			function(id)
				core.Database:SetSpecLayoutId(spec.key, id or nil)
				applyIfChanged()
			end, { width = 180 })
		local refresh = row.Refresh
		function row:Refresh()
			refresh(self)
			local active = core.Specs:Current() == spec.key
			-- The current specialization is shown in the accent color
			self.label:SetTextColor(unpack(active and O.Theme.colors.accent or O.Theme.colors.text))
		end
	end
	W.TextRow(form, L["SPEC_LAYOUTS_HELP"], 56)

	form:Section(L["SECTION_OTHER_PROFILES"])
	W.DropdownRow(form, L["COPY_FROM"], function() return profileItems(true) end, function() return nil end,
		function(name)
			Options:Confirm(L["CONFIRM_COPY_PROFILE"]:format(name, db():GetCurrentProfile()), function()
				db():CopyProfile(name)
				Options:Refresh()
			end)
		end)
	W.DropdownRow(form, L["DELETE_PROFILE"], function() return profileItems(true) end, function() return nil end,
		function(name)
			Options:Confirm(L["CONFIRM_DELETE_PROFILE"]:format(name), function()
				db():DeleteProfile(name)
				Options:Refresh()
			end)
		end)
end

Options:RegisterPage({
	key = "profiles",
	title = L["PAGE_PROFILES"],
	subtitle = L["PAGE_PROFILES_DESC"],
	icon = "Interface\\Icons\\INV_Misc_GroupNeedMore",
	build = build,
	refresh = function(page)
		page.scroll:SetContentHeight(page.form:Refresh())
	end,
})
