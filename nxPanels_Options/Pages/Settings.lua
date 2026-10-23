local _, O = ...
local W, Options = O.Widgets, O.Options
local L = O.L
local core = O.core

-- General settings, edit mode settings, information
local function edit() return core.db.global.editMode end

-- Where players report a problem
local SUPPORT_URL = "github.com/WillOli7/nxPanels/issues"


local function build(page, width)
	local scroll, form = Options:ScrollForm(page, width)
	page.scroll, page.form = scroll, form

	-- The window is drawn with these colors: a reload applies a change
	local T = O.Theme
	local theme = core.db.global.optionsTheme
	local function askReload()
		Options:Confirm(L["THEME_RELOAD"], function() ReloadUI() end)
	end
	form:Section(L["SECTION_APPEARANCE"])
	W.DropdownRow(form, L["THEME_STYLE"], Options:Choices(T.STYLE_ORDER, "STYLE_THEME_"),
		function() return theme.style end,
		function(v) if v ~= theme.style then theme.style = v askReload() end end)
	W.DropdownRow(form, L["THEME_ACCENT"], Options:Choices(T.ACCENT_ORDER, "ACCENT_"),
		function() return theme.accent end,
		function(v) if v ~= theme.accent then theme.accent = v askReload() end end)

	form:Section(L["SECTION_GENERAL"])
	W.ToggleRow(form, L["SHOW_PANELS"], function() return core.db.profile.enabled end,
		function(on) core.Layouts:SetEnabled(on) Options:Refresh() end)
	W.ToggleRow(form, L["MINIMAP_BUTTON"], function() return not core.db.profile.minimap.hide end,
		function(on)
			if on == core.db.profile.minimap.hide then core.Commands:ToggleMinimap() end
		end)
	W.SliderRow(form, L["WINDOW_SCALE"], 0.6, 1.5, 0.05, function() return core.db.global.optionsScale end,
		function(v) core.db.global.optionsScale = v end,
		-- Applied when the slider is released, so the window does not move under the mouse
		{ onRelease = function() Options.frame:SetScale(core.db.global.optionsScale) end })
	W.ButtonsRow(form, {
		{ text = L["RESET_WINDOW"], width = 190, onClick = function()
			core.db.global.optionsScale = 1
			Options.frame:SetScale(1)
			Options.frame:ClearAllPoints()
			Options.frame:SetPoint("CENTER")
			Options:Refresh()
		end },
	}, nil, true)

	form:Section(L["SECTION_EDIT_MODE"])
	W.ToggleRow(form, L["SHOW_GRID"], function() return edit().showGrid end,
		function(on) edit().showGrid = on end)
	W.SliderRow(form, L["GRID_SIZE"], 4, 128, 1, function() return edit().gridSize end,
		function(v) edit().gridSize = math.floor(v) end)
	W.ToggleRow(form, L["SNAP_GRID"], function() return edit().snapGrid end,
		function(on) edit().snapGrid = on end)
	W.ToggleRow(form, L["SNAP_PANELS"], function() return edit().snapPanels end,
		function(on) edit().snapPanels = on end, L["SNAP_PANELS_DESC"])
	W.SliderRow(form, L["SNAP_DISTANCE"], 2, 32, 1, function() return edit().snapDistance end,
		function(v) edit().snapDistance = math.floor(v) end)
	W.SliderRow(form, L["BIG_STEP"], 2, 100, 1, function() return edit().bigStep end,
		function(v) edit().bigStep = math.floor(v) end)
	W.ButtonsRow(form, {
		{ text = L["EDIT_MODE"], style = "primary", width = 190, onClick = function() O.EditMode:Start() end },
	}, L["EDIT_MODE_HELP_SHORT"])

	-- Useful for the troubleshooting (screenshots of players)
	form:Section(L["SECTION_ABOUT"])
	W.InfoRow(form, L["ABOUT_VERSION"], function() return core.version end)
	W.InfoRow(form, L["ABOUT_CLIENT"], function() return core:ClientName() .. " " .. core:GameVersion() end)
	W.InfoRow(form, L["ABOUT_LANGUAGE"], function() return GetLocale() end)
	W.InfoRow(form, L["ABOUT_FONT"], function()
		local font = tostring(core.Media:DefaultFont())
		return font:match("([^\\/]+)$") or font
	end)
	W.InfoRow(form, L["ABOUT_COMMANDS"], function() return "/nxp help" end)
	W.InfoRow(form, L["ABOUT_SUPPORT"], function() return SUPPORT_URL end)
end

Options:RegisterPage({
	key = "settings",
	title = L["PAGE_SETTINGS"],
	subtitle = L["PAGE_SETTINGS_DESC"],
	icon = "Interface\\Icons\\INV_Misc_Gear_01",
	build = build,
	refresh = function(page)
		page.scroll:SetContentHeight(page.form:Refresh())
	end,
})
