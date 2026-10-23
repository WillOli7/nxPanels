local _, ns = ...
local L = ns.L

--[[
What's new window: shown once, at the first start of a new version.
	global.newsSeen   last version announced (or skipped)
	global.showNews   false: never shown at startup (still available in the settings)
Not shown to a new player (nothing changed for them), nor right after an import
(the welcome window explains it); after another window, it waits for it to close.
]]
local News = {}
ns.News = News

-- Versions with notes: text of the window
News.NOTES = {
	["1.1.0"] = "NEWS_1_1_0",
}

local WIDTH, HEIGHT = 560, 470

local function create()
	local f = ns.Splash:Create("nxPanelsNews", WIDTH, HEIGHT)
	f.body:SetJustifyH("LEFT")
	f.body:SetSpacing(6)
	f.body:SetPoint("BOTTOM", 0, 96)

	-- Startup option, also in the settings
	f.dontShow = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
	f.dontShow:SetSize(24, 24)
	f.dontShow:SetPoint("BOTTOMLEFT", 26, 60)
	f.dontShow:SetScript("OnClick", function(self)
		ns.db.global.showNews = not self:GetChecked()
	end)
	f.dontShowLabel = f:CreateFontString(nil, "OVERLAY")
	f.dontShowLabel:SetFont(STANDARD_TEXT_FONT, 13, "")
	f.dontShowLabel:SetTextColor(0.75, 0.72, 0.66)
	f.dontShowLabel:SetPoint("LEFT", f.dontShow, "RIGHT", 4, 0)
	f.dontShowLabel:SetText(L["NEWS_DONT_SHOW"])
	return f
end

-- Opens the window of a version (the current one by default); false when it has no notes
function News:Show(version)
	version = version or ns.version
	local key = self.NOTES[version]
	if not key or not ns.db then return false end
	local f = self.frame or create()
	self.frame = f
	f.title:SetText(L["NEWS_TITLE"]:format(version))
	f.body:SetText(L[key])
	f.dontShow:SetChecked(ns.db.global.showNews == false)
	f:Show()
	return true
end

-- At login (a moment later, so the welcome window of an import is already open)
function News:Check()
	local g = ns.db.global
	local seen, version = g.newsSeen, ns.version
	if seen == version then return end
	g.newsSeen = version
	-- New player, or an import made in this session: the welcome window is enough
	local newPlayer = seen == nil and not g.migration and not next(g.layouts)
	local importedNow = type(g.migration) == "table" and (g.migration.date or 0) >= (ns.startTime or 0)
	if newPlayer or importedNow or g.showNews == false or not self.NOTES[version] then return end
	ns.Splash:Queue(function() News:Show(version) end)
end

function News:Init()
	ns:RegisterEvent("PLAYER_LOGIN", function()
		C_Timer.After(2, function() News:Check() end)
	end)
end
