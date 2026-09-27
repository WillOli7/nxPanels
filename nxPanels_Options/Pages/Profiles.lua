local _, O = ...
local T, W, Options = O.Theme, O.Widgets, O.Options
local L = O.L
local core = O.core

--[[
Profiles (AceDB): a profile chooses the active layout and whether the panels
are shown. Layouts themselves are shared by every profile.
]]
local LibDualSpec = LibStub("LibDualSpec-1.0", true)

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

local function layoutItems()
	local items = { { value = false, text = L["LAYOUT_NONE_ITEM"] } }
	for _, entry in ipairs(core.Database:SortedLayouts()) do
		items[#items + 1] = { value = entry.id, text = entry.layout.name }
	end
	return items
end

-- Specializations: named specs on Retail, primary / secondary talents on WoW Forever
local function specList()
	local specs = {}
	if core.isForever or not (GetNumSpecializations and GetSpecializationInfo) then
		specs[1] = TALENT_SPEC_PRIMARY or "1"
		specs[2] = TALENT_SPEC_SECONDARY or "2"
	else
		for i = 1, GetNumSpecializations() do
			local _, name = GetSpecializationInfo(i)
			specs[i] = name or tostring(i)
		end
	end
	return specs
end

local function hasDualSpec()
	return LibDualSpec and db().IsDualSpecEnabled ~= nil
end

local function specUnlocked()
	return LibDualSpec and (LibDualSpec.currentSpec or 0) > 0
end

local function build(page, width)
	local scroll, form = Options:ScrollForm(page, width)
	page.scroll, page.form = scroll, form

	form:Section(L["SECTION_CURRENT_PROFILE"])
	W.DropdownRow(form, L["PROFILE"], function() return profileItems(false) end,
		function() return db():GetCurrentProfile() end,
		function(name) db():SetProfile(name) Options:Refresh() end)
	W.ButtonsRow(form, {
		{ text = L["NEW_PROFILE"], style = "primary", width = 150, onClick = function()
			Options:Prompt(L["PROMPT_NEW_PROFILE"], "", function(text)
				text = strtrim(text or "")
				if text ~= "" then
					db():SetProfile(text)
					Options:Refresh()
				end
			end)
		end },
		{ text = L["RESET_PROFILE"], style = "danger", width = 150, onClick = function()
			Options:Confirm(L["CONFIRM_RESET_PROFILE"]:format(db():GetCurrentProfile()), function()
				db():ResetProfile()
				Options:Refresh()
			end)
		end },
	})

	form:Section(L["SECTION_PROFILE_CONTENT"])
	W.DropdownRow(form, L["PROFILE_LAYOUT"], layoutItems,
		function() return core.Database:GetActiveLayoutId() or false end,
		function(id)
			if id then
				core.Layouts:Activate(id)
			else
				core.Database:SetActiveLayoutId(nil)
				core.Layouts:ApplyActive()
			end
			Options:Refresh()
		end, { width = 220 })
	W.ToggleRow(form, L["SHOW_PANELS"], function() return db().profile.enabled end,
		function(on) core.Layouts:SetEnabled(on) Options:Refresh() end)

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
	W.TextRow(form, L["PROFILES_HELP"], 56)

	if hasDualSpec() then
		form:Section(L["SECTION_SPECS"])
		local enable = W.ToggleRow(form, L["SPEC_PROFILES"], function() return db():IsDualSpecEnabled() end,
			function(on) db():SetDualSpecEnabled(on) Options:Refresh() end, L["SPEC_PROFILES_DESC"])
		enable.isShown = specUnlocked
		W.TextRow(form, L["SPEC_LOCKED"], 40).isShown = function() return not specUnlocked() end
		for i, name in ipairs(specList()) do
			local row = W.DropdownRow(form, name, function() return profileItems(false) end,
				function() return db():GetDualSpecProfile(i) end,
				function(profile) db():SetDualSpecProfile(profile, i) Options:Refresh() end)
			row.isShown = function() return specUnlocked() and db():IsDualSpecEnabled() end
			local refresh = row.Refresh
			function row:Refresh()
				refresh(self)
				local active = LibDualSpec.currentSpec == i
				self.label:SetText(active and L["SPEC_ACTIVE"]:format(name) or name)
			end
		end
	end
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
