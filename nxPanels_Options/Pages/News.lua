local _, O = ...
local Options = O.Options
local L = O.L
local core = O.core

-- Sidebar entry: opens the what's new window of the current version
Options:RegisterPage({
	key = "news",
	title = L["PAGE_NEWS"],
	icon = "Interface\\Icons\\INV_Misc_Note_01",
	action = function() core.News:Show() end,
})
