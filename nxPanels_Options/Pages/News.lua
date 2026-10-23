local _, O = ...
local W, Options = O.Widgets, O.Options
local T = O.Theme
local C = T.colors
local L = O.L
local core = O.core

-- What's new: the notes of every version, the most recent first (the same
-- notes as the window shown once at startup), and the option of that window
local BANNER = "Interface\\AddOns\\nxPanels\\Media\\banner"
local LINE_HEIGHT = 22

local function build(page, width)
	local banner = page:CreateTexture(nil, "ARTWORK")
	banner:SetTexture(BANNER)
	banner:SetSize(400, 100)
	banner:SetPoint("TOP", 0, -2)

	local scroll, form = Options:ScrollForm(page, width, 112)
	page.scroll, page.form = scroll, form
	W.ToggleRow(form, L["NEWS_SHOW_SETTING"], function() return core.db.global.showNews ~= false end,
		function(on) core.db.global.showNews = on end)
	for _, version in ipairs(core.News:Versions()) do
		form:Section(L["NEWS_TITLE"]:format(version))
		local notes = L[core.News.NOTES[version]]
		local lines = select(2, notes:gsub("\n", "")) + 1
		local row = W.TextRow(form, notes, lines * LINE_HEIGHT + 24)
		row.text:SetSpacing(6)
		row.text:SetTextColor(unpack(C.text))
	end
end

Options:RegisterPage({
	key = "news",
	title = L["PAGE_NEWS"],
	subtitle = L["PAGE_NEWS_DESC"],
	icon = "Interface\\Icons\\INV_Misc_Note_01",
	build = build,
	refresh = function(page)
		page.scroll:SetContentHeight(page.form:Refresh())
	end,
})
