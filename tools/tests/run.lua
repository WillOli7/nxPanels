-- Offline tests of nxPanels, run with LuaJIT from the repository root:
--   luajit tools/tests/run.lua <scenario>
-- Scenarios: migrate, original, handinstall, empty, nolibs, notloaded, forever, tbc, zhcn, options, real (NXP_REAL_SV=path/to/kgPanels_Reloaded.lua)

local scenario = arg[1] or "migrate"
local M = dofile("tools/tests/wowmock.lua")

-- WoW's string.format supports positional arguments (%2$s), LuaJIT's does not
do
	local rawformat = string.format
	string.format = function(fmt, ...)
		if type(fmt) == "string" and fmt:find("%%%d+%$") then
			local args, order = { ... }, {}
			fmt = fmt:gsub("%%(%d+)%$", function(n) order[#order + 1] = tonumber(n) return "%" end)
			local ordered = {}
			for i, n in ipairs(order) do ordered[i] = args[n] end
			return rawformat(fmt, unpack(ordered, 1, #order))
		end
		return rawformat(fmt, ...)
	end
	getmetatable("").__index.format = string.format
end

local failures, checks = 0, 0
local function check(cond, label)
	checks = checks + 1
	if not cond then
		failures = failures + 1
		print("  FAIL " .. label)
	end
end
local function printed(pattern)
	for _, line in ipairs(M.printed) do
		if line:find(pattern) then return true end
	end
	return false
end
local function count(t) local n = 0 for _ in pairs(t or {}) do n = n + 1 end return n end
local function deepEqual(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for k, v in pairs(a) do if not deepEqual(v, b[k]) then return false end end
	for k in pairs(b) do if a[k] == nil then return false end end
	return true
end

---------------------------------------------------------------------------
-- Environment of the scenario
---------------------------------------------------------------------------
local function fixture()
	local env = setmetatable({}, { __index = _G })
	setfenv(assert(loadfile("tools/tests/fixtures/legacy_kgpanels.lua")), env)()
	return env.kgPanelsDB
end

local realSV = os.getenv("NXP_REAL_SV")
local function realData()
	local env = {}
	setfenv(assert(loadfile(realSV)), env)()
	return env.kgPanelsDB
end

if scenario == "forever" then
	M.build = { "1.60.1", "70009", "Sep 20 2026", 16001 }
elseif scenario == "tbc" then
	-- TBC Anniversary: classic project, 2.5.x build, no specializations nor pet battles
	WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5
	WOW_PROJECT_ID = 5
	M.build = { "2.5.6", "68001", "Jul 14 2026", 20506 }
	M.unknownEvents = { PLAYER_SPECIALIZATION_CHANGED = true, PET_BATTLE_OPENING_START = true, PET_BATTLE_CLOSE = true }
elseif scenario == "zhcn" then
	M.locale = "zhCN"
	STANDARD_TEXT_FONT = "Fonts\\ARKai_T.ttf"
end
-- Optional client language: luajit tools/tests/run.lua options zhTW
if arg[2] then
	M.locale = arg[2]
	if arg[2]:find("^zh") then STANDARD_TEXT_FONT = "Fonts\\ARKai_T.ttf" end
end

local legacySource = scenario == "real" and realData or fixture
if scenario == "original" then
	kgPanelsDB = fixture()
	M.addons = {
		{ name = "kgPanels", loaded = true },
		{ name = "kgPanels_Reloaded", lod = true, onLoad = function() kgPanelsDB = { global = { layouts = { Wrong = {} } } } end },
		{ name = "nxPanels", loaded = true },
	}
elseif scenario == "handinstall" then
	-- The old kgPanels Reloaded (full addon, not the bridge) installed by hand next to nxPanels
	kgPanelsDB = fixture()
	M.addons = {
		{ name = "kgPanelsConfig_Reloaded", loaded = true },
		{ name = "kgPanels_Reloaded", loaded = true },
		{ name = "nxPanels", loaded = true },
	}
elseif scenario == "notloaded" then
	-- kgPanels copied from BCC Anniversary to WoW Forever: the client does not load it,
	-- the bridge has no saved file yet
	ADDON_INTERFACE_VERSION = "Out of date"
	M.addons = {
		{ name = "kgPanels", reason = "INTERFACE_VERSION" },
		{ name = "kgPanels_Reloaded", lod = true },
		{ name = "nxPanels", loaded = true },
	}
elseif scenario ~= "empty" then
	M.addons = {
		{ name = "kgPanelsConfig_Reloaded", lod = true },
		{ name = "kgPanels_Reloaded", lod = true, onLoad = function() kgPanelsDB = legacySource() end },
		{ name = "nxPanels", loaded = true },
		{ name = "Details" },
	}
else
	M.addons = { { name = "nxPanels", loaded = true } }
end

---------------------------------------------------------------------------
-- Load the addon like the client does (TOC order)
---------------------------------------------------------------------------
local ns = {}
local ROOT = "nxPanels/"
local function load(path)
	local chunk = assert(loadfile(ROOT .. path))
	chunk("nxPanels", ns)
end
for _, lib in ipairs({
	"Libs/LibStub/LibStub.lua", "Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua", "Libs/AceDB-3.0/AceDB-3.0.lua",
	"Libs/AceLocale-3.0/AceLocale-3.0.lua", "Libs/AceSerializer-3.0/AceSerializer-3.0.lua",
	"Libs/LibSharedMedia-3.0/LibSharedMedia-3.0.lua", "Libs/LibSerialize/LibSerialize.lua",
	"Libs/LibDeflate/LibDeflate.lua", "Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua",
}) do
	load(lib)
end
-- LibDBIcon needs the real minimap: replaced by a stub (left out to test a missing library)
if scenario ~= "nolibs" then
	local icon = LibStub:NewLibrary("LibDBIcon-1.0", 9999)
	function icon:Register(name, obj, db) self.registered = { name = name, obj = obj, db = db } end
	function icon:Show() end
	function icon:Hide() end
end

for line in io.lines(ROOT .. "nxPanels.toc") do
	line = line:gsub("\r", "")
	if line:match("%.lua$") then load((line:gsub("\\", "/"))) end
end

M.Fire("ADDON_LOADED", "nxPanels")

-- Import module (loaded after nxPanels, like RequiredDeps does)
local I = {}
for line in io.lines("nxPanels_Import/nxPanels_Import.toc") do
	line = line:gsub("\r", "")
	if line:match("%.lua$") then assert(loadfile("nxPanels_Import/" .. line))("nxPanels_Import", I) end
end
M.Fire("ADDON_LOADED", "nxPanels_Import")
local loginOK, loginError = pcall(M.Fire, "PLAYER_LOGIN")
if not loginOK and scenario ~= "nolibs" then error(loginError, 0) end

local db = nxPanelsDB
local L = ns.L
print(("[%s] client: retail=%s forever=%s tbc=%s, locale %s"):format(scenario, tostring(ns.isRetail), tostring(ns.isForever), tostring(ns.isAnniversary), M.locale))

---------------------------------------------------------------------------
-- Checks
---------------------------------------------------------------------------
local function layoutByName(name)
	for id, layout in pairs(db.global.layouts) do
		if layout.name == name then return id, layout end
	end
end
-- Loads the options module like C_AddOns.LoadAddOn does
local function loadOptions()
	M.addons[#M.addons + 1] = { name = "nxPanels_Options", loaded = true }
	local O = {}
	for line in io.lines("nxPanels_Options/nxPanels_Options.toc") do
		line = line:gsub("\r", "")
		if line:match("%.lua$") then assert(loadfile("nxPanels_Options/" .. line:gsub("\\", "/")))("nxPanels_Options", O) end
	end
	return O
end

local function frameOf(layout, name)
	local id = ns.Database:FindPanel(layout, name)
	return id and ns.Layouts.frames[id], id
end

if scenario == "migrate" or scenario == "forever" or scenario == "tbc" or scenario == "zhcn" then
	local talentGroups = scenario == "forever" or scenario == "tbc"
	check(ns.isForever == (scenario == "forever") and ns.isAnniversary == (scenario == "tbc") and ns.isRetail == not talentGroups, "client detection")
	check(ns.usesTalentGroups == talentGroups, "talent groups instead of specializations")
	check(M.loadCalls[1] == "kgPanels_Reloaded", "bridge addon loaded")
	check(count(db.global.layouts) == 2, "2 layouts imported, empty translated 'None' layout skipped")
	local mainId, main = layoutByName("Main UI")
	local secondId, second = layoutByName("Second")
	check(main and count(main.panels) == 6 and count(second.panels) == 2, "panels imported")
	check(main.folders[1] == "Bars" and #main.folders == 1, "folders imported")
	check(db.global.media.background["My Art"] and db.global.media.border["My Border"], "custom art imported")
	check(not db.global.media.background["Solid"] and not db.global.media.border["Bulle d'aide de Blizzard"], "built-in art not duplicated")
	check(db.global.migration and db.global.migration.source == "kgPanels_Reloaded", "migration recorded")
	check(db.profileKeys["Muse - Hyjal"] == "Default" and db.profileKeys["Alt - Hyjal"] == "Alt", "profile keys kept")
	check(db.profiles.Default.layout == mainId and db.profiles.Alt.layout == secondId, "profile layouts mapped to ids")
	check(db.profiles.Alt.enabled == false and db.profiles.Empty.layout == nil, "profile flags")
	local specs = ns.Specs:List()
	local specKeys = talentGroups and "G1G2" or "S62S63S64"
	local joined = ""
	for _, spec in ipairs(specs) do joined = joined .. spec.key end
	check(joined == specKeys, "specializations of the client: " .. joined)
	local specLayouts = db.profiles.Default.specLayouts or {}
	check(specLayouts[specs[1].key] == mainId and specLayouts[specs[2].key] == secondId, "profiles per spec became layouts per spec")
	check(not (db.namespaces and db.namespaces["LibDualSpec-1.0"]), "LibDualSpec settings not copied")
	check(db.global.schema == ns.SCHEMA, "schema saved")
	check(deepEqual(kgPanelsDB, fixture()), "legacy data left untouched")
	check(M.disabled.kgPanels_Reloaded and M.disabled.kgPanelsConfig_Reloaded, "legacy addons disabled")
	local welcome = nxPanelsWelcome
	check(#M.popups == 0, "no reload popup when only the bridge was used")
	check(welcome and welcome:IsShown(), "welcome window shown")
	check(welcome.title:GetText() == L["WELCOME_TITLE"]:format("kgPanels Reloaded"), "welcome title")
	check(welcome.body:GetText():find(L["WELCOME_COUNT"]:format(2, 8), 1, true), "welcome counts")
	check(db.global.migration.welcomed == true, "welcome recorded")
	welcome.close:GetScript("OnClick")(welcome.close)
	check(not welcome:IsShown(), "OK closes the welcome window")
	I.Import:Finish()
	check(not welcome:IsShown(), "welcome shown only once")
	db.global.migration.welcomed = nil
	I.Import:Finish()
	check(welcome:IsShown(), "welcome for players who imported before it existed")
	-- Fake options module: the open button shows the window, never toggles it off
	local optionsCalls = {}
	M.addons[#M.addons + 1] = { name = "nxPanels_Options", lod = true }
	ns.Options = {
		Show = function() optionsCalls[#optionsCalls + 1] = "Show" end,
		Toggle = function() optionsCalls[#optionsCalls + 1] = "Toggle" end,
	}
	welcome.open:GetScript("OnClick")(welcome.open)
	check(not welcome:IsShown() and C_AddOns.IsAddOnLoaded("nxPanels_Options") and optionsCalls[1] == "Show", "open button closes and opens nxPanels")
	db.global.migration.welcomed = nil
	I.Import:Finish()
	welcome.open:GetScript("OnClick")(welcome.open)
	check(optionsCalls[2] == "Show", "open button keeps the options window open")
	ns.Options = nil
	table.remove(M.addons)
	-- Nothing imported: no count in the welcome
	local migration = db.global.migration
	local imported = { migration.layouts, migration.panels }
	migration.welcomed, migration.layouts, migration.panels = nil, 0, 0
	I.Import:Finish()
	check(welcome:IsShown() and welcome.body:GetText() == L["WELCOME_BODY"], "no count when nothing was imported")
	welcome.close:GetScript("OnClick")(welcome.close)
	migration.layouts, migration.panels = imported[1], imported[2]

	-- What's new: not right after an import (the welcome window is enough)
	for _, fn in ipairs(M.timers or {}) do fn() end
	M.timers = {}
	local News = ns.News
	check(not nxPanelsNews and db.global.newsSeen == ns.version, "no news right after an import, version recorded")
	-- A player updating from 1.0.0 (imported earlier): shown once, after the welcome window
	local version = ns.version
	ns.version = "1.1.0"
	db.global.newsSeen, migration.date, migration.welcomed = "1.0.0", 1, nil
	I.Import:Finish()
	check(welcome:IsShown(), "welcome window of an older import")
	News:Check()
	check(not nxPanelsNews or not nxPanelsNews:IsShown(), "news waits for the welcome window")
	welcome.close:GetScript("OnClick")(welcome.close)
	local news = nxPanelsNews
	check(news and news:IsShown() and news.title:GetText() == L["NEWS_TITLE"]:format("1.1.0") and news.body:GetText() == L["NEWS_1_1_0"], "news shown once the welcome window is closed")
	check(db.global.newsSeen == "1.1.0", "news recorded")
	news.close:GetScript("OnClick")(news.close)
	News:Check()
	check(not news:IsShown(), "news shown only once")
	-- Turned off from the window: not shown for the next version, still available by hand
	News:Show()
	news.dontShow:SetChecked(true)
	news.dontShow:GetScript("OnClick")(news.dontShow)
	news:Hide()
	check(db.global.showNews == false, "news turned off from the window")
	db.global.newsSeen = "1.0.0"
	News:Check()
	check(not news:IsShown() and db.global.newsSeen == "1.1.0", "turned off: not shown at startup")
	check(News:Show() and news:IsShown() and news.dontShow:GetChecked(), "turned off: still opened by hand, box checked")
	news:Hide()
	db.global.showNews = true
	check(not News:Show("0.9.0"), "no window for a version without notes")
	-- New player: nothing to announce
	local savedMigration, savedLayouts = db.global.migration, db.global.layouts
	db.global.migration, db.global.layouts, db.global.newsSeen = nil, {}, nil
	News:Check()
	check(not news:IsShown() and db.global.newsSeen == "1.1.0", "new player: no news")
	db.global.migration, db.global.layouts = savedMigration, savedLayouts
	ns.version = version
	check(printed(L["MIGRATED"]:format(2, 8, "kgPanels_Reloaded"):gsub("%p", "%%%0")), "migration message")

	-- A game frame wins over a panel of the same name, a panel never references itself
	CreateFrame("Frame", "Minimap", UIParent)
	local g = { layouts = {}, media = { background = {}, border = {} } }
	I.Convert.Layouts({ layouts = { Map = {
		Minimap = { parent = "Minimap", anchor = "Minimap" },
		Ring = { parent = "Minimap", anchor = "Minimap" },
		Label = { anchor = "Ring" },
		Self = { anchor = "Self" },
	} } }, g)
	local _, mapLayout = next(g.layouts)
	local byName = {}
	for id, panel in pairs(mapLayout.panels) do byName[panel.name] = panel byName[panel.name].id = id end
	check(byName.Minimap.parent == "Minimap" and byName.Minimap.anchor.relativeTo == "Minimap", "panel named like the frame it follows keeps the frame")
	check(byName.Ring.parent == "Minimap" and byName.Ring.anchor.relativeTo == "Minimap", "game frame wins over a panel of the same name")
	check(byName.Label.anchor.relativeTo == "panel:" .. byName.Ring.id, "reference to another panel")
	check(byName.Self.anchor.relativeTo == "Self", "never anchored to itself")
	local _, cyclic = ns.Anchors:Order(mapLayout.panels)
	check(next(cyclic) == nil, "no anchoring loop")

	-- Layouts imported by 1.0.0: the panel anchored to itself is repaired at startup
	local activeLayout = ns.Database:GetLayout(ns.Layouts.activeId)
	local mapId = ns.Database:CreatePanel(ns.Layouts.activeId, "Minimap")
	local mapPanel = activeLayout.panels[mapId]
	mapPanel.parent, mapPanel.anchor.relativeTo = "panel:" .. mapId, "panel:" .. mapId
	ns.Layouts:ApplyActive()
	check(ns.Layouts.cyclic[mapId], "1.0.0 import: anchoring loop")
	check(I.Import:RepairSelfReferences() == 2 and mapPanel.parent == "Minimap" and mapPanel.anchor.relativeTo == "Minimap", "self references repaired")
	check(I.Import:RepairSelfReferences() == 0, "repair done once")
	ns.Layouts:ApplyActive()
	check(not ns.Layouts.cyclic[mapId] and ns.Layouts.frames[mapId].points[1][2] == _G.Minimap, "repaired panel follows the minimap")
	ns.Database:DeletePanel(ns.Layouts.activeId, mapId)
	ns.Layouts:ApplyActive()
	_G.Minimap = nil

	-- A script hiding its panel keeps it hidden (issue #16: one icon per class)
	local iconId = ns.Database:CreatePanel(ns.Layouts.activeId, "Class icon")
	activeLayout.panels[iconId].scripts = {
		LOAD = 'self:RegisterEvent("PLAYER_ENTERING_WORLD")',
		EVENT = 'if select(2, UnitClass("player")) == "NOCLASS" then self:Show() else self:Hide() end',
	}
	ns.Layouts:PanelChanged(iconId, "added")
	local icon = ns.Layouts.frames[iconId]
	check(icon and icon.shown, "new panel shown")
	M.Fire("PLAYER_ENTERING_WORLD")
	check(not icon.shown, "hidden by its script")
	for _, event in ipairs({ "MODIFIER_STATE_CHANGED", "PLAYER_TARGET_CHANGED", "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
		M.Fire(event)
	end
	check(not icon.shown, "display events leave a panel without conditions to its script")
	ns.Layouts:PanelChanged(iconId, "anchors")
	ns.Layouts:RefreshAll()
	check(not icon.shown, "placing the panels again keeps it hidden")
	ns.Visibility:SetForceShow(true)
	check(icon.shown, "edit mode shows it")
	ns.Visibility:SetForceShow(false)
	check(not icon.shown, "hidden again after the edit mode")
	activeLayout.panels[iconId].display.combat = "IN"
	ns.Layouts:PanelChanged(iconId, "display")
	activeLayout.panels[iconId].display.combat = "ANY"
	ns.Layouts:PanelChanged(iconId, "display")
	check(icon.shown, "conditions removed: shown, then its script decides")
	ns.Database:DeletePanel(ns.Layouts.activeId, iconId)
	ns.Layouts:ApplyActive()

	-- Active layout of the Default profile
	check(ns.Layouts.activeId == mainId, "active layout")
	local bar = frameOf(main, "Bottom Bar")
	check(bar and bar.shown and bar.w == 1920 and bar.h == 32, "percent width, string height")
	check(bar.points[1][5] == -520, "string offset converted")
	check(not bar.border.textures.TOP.shown, "translated 'None' border = no border")

	local chat = frameOf(main, "Chat BG")
	check(chat.points[1][2] == bar and chat.points[1][1] == "BOTTOMLEFT", "panel anchored to another panel")
	check(chat.border.textures.LEFT.texture == "Interface\\Tooltips\\UI-Tooltip-Border", "translated border name resolved")
	check(chat.bg.texture == "Interface\\AddOns\\MyMedia\\art.tga", "custom background resolved")
	check(chat.text.font[1] == STANDARD_TEXT_FONT and chat.text.font[2] == 12, "language default font, size 0 -> 12")
	check(chat.text.textValue == "|cffff0000Chat|r", "escaped color codes")
	check(chat.bg.points[1][4] == 4 and chat.bg.points[1][5] == -4 and chat.bg.points[2][4] == -4 and chat.bg.points[2][5] == 4, "background insets")

	local loopA = frameOf(main, "Loop A")
	local loopB = frameOf(main, "Loop B")
	check(loopA.points[1][2] == UIParent and loopB.points[1][2] == UIParent, "anchoring loop broken")
	check(printed("Loop A") and printed("Loop B"), "anchoring loop reported")

	local waiting, waitingId = frameOf(main, "Waiting")
	check(waiting and not waiting.shown and ns.Layouts.waiting[waitingId], "panel waiting for a missing frame")
	local target = CreateFrame("Frame", "SomeAddonFrame", UIParent)
	target.w, target.h = 300, 200
	M.ticker.fn()
	check(waiting.shown and waiting.parent == target and not ns.Layouts.waiting[waitingId], "panel shown once its frame exists")
	check(M.ticker.cancelled, "retry timer stopped")

	-- Scripts wait for their dependency
	local s = frameOf(main, "Scripted")
	check(s.level == 0, "negative frame level clamped")
	check(s.loaded == nil and s.scripts.OnEvent == nil, "scripts wait for their addon")
	M.addons[4].loaded = true
	M.Fire("ADDON_LOADED", "Details")
	check(s.loaded == 1, "LOAD script ran once")
	check(ns.Scripts.env.LoadedBy == ns.API and rawget(_G, "LoadedBy") == nil, "script variables isolated from the game globals")
	s.scripts.OnEvent(s, "PLAYER_TARGET_CHANGED", "unit1")
	check(s.lastArg == "unit1", "EVENT script with legacy arg1")
	check(s.found == bar, "old kgPanels:FetchFrame call rewritten to nxPanels")
	s.scripts.OnMouseDown(s, "LeftButton")
	s.scripts.OnMouseUp(s, "RightButton")
	check(s.down == "LeftButton" and s.up == "RightButton", "CLICK script pressed / released")
	check(s.scripts.OnShow ~= nil, "script ending with a comment compiles")
	check(s.scripts.OnHide == nil, "empty script ignored")
	local before = #M.printed
	s.scripts.OnUpdate(s, 0.1)
	check(s.scripts.OnUpdate == nil, "failing script switched off")
	check(#M.printed == before + 1 and M.printed[#M.printed]:find("boom"), "script error reported once")

	-- Second layout: gradient, rotation, flips, tiling, hidden border sides
	SlashCmdList.NXPANELS("layout second")
	check(ns.Layouts.activeId == secondId and ns.db.profile.layout == secondId, "layout switched by name (case-insensitive)")
	check(not s.shown or s.panelId ~= nil, "previous frames released")
	local art = frameOf(second, "Art")
	check(art.bg.gradient and art.bg.gradient[3].a == 0.5, "gradient with string alpha")
	check(art.bg.subLevel == 7, "sublevel clamped")
	check(#art.bg.texCoord == 8, "rotation + flip coordinates")
	check(not art.border.textures.TOP.shown and art.border.textures.BOT.shown, "hidden border sides")
	check(art.border.textures.TOP.texCoord and #art.border.textures.TOP.texCoord == 8, "rotated border side")
	-- Same coordinates as Blizzard's BackdropTemplate (issue #16: borders 1 px off)
	do
		local b = art.border
		local size, width, height = b.size, art:GetWidth(), art:GetHeight()
		local scale = art:GetEffectiveScale()
		local rx = math.max(0, width / size * scale - 2 - 0.0625)
		local ry = math.max(0, height / size * scale - 2 - 0.0625)
		check(deepEqual(b.textures.TOP.texCoord, { 0.2578125, rx, 0.3671875, rx, 0.2578125, 0.0625, 0.3671875, 0.0625 }), "top side like the backdrop")
		check(deepEqual(b.textures.LEFT.texCoord, { 0.0078125, 0.0625, 0.0078125, ry, 0.1171875, 0.0625, 0.1171875, ry }), "left side like the backdrop")
		check(deepEqual(b.textures.TOPLEFTCORNER.texCoord, { 0.5078125, 0.6171875, 0.0625, 0.9375 }), "corner like the backdrop")
		check(deepEqual(b.textures.BOTRIGHTCORNER.texCoord, { 0.8828125, 0.9921875, 0.0625, 0.9375 }), "last corner like the backdrop")
	end
	local tiled = frameOf(second, "Tiled")
	tiled.bg.w, tiled.bg.h = 192, 92
	tiled.sizer.scripts.OnSizeChanged(tiled.sizer)
	check(tiled.bg.wrapH == "REPEAT" and tiled.bg.texCoord[2] == 6, "tiled background")

	-- Commands
	for _, cmd in ipairs({ "", "layouts", "status", "toggle", "toggle", "minimap", "config", "layout nope" }) do
		local ok, err = pcall(SlashCmdList.NXPANELS, cmd)
		check(ok, "command '" .. cmd .. "': " .. tostring(err))
	end
	check(printed(L["LAYOUT_NOT_FOUND"]:format("nope")), "unknown layout message")

	-- Next start: no second migration
	I.Import:Auto()
	check(count(db.global.layouts) == 2, "no migration on the next start")

	-- Manual import adds copies with unique names
	SlashCmdList.NXPANELS("import")
	check(count(db.global.layouts) == 4 and layoutByName("Main UI (2)"), "manual import with unique names")
	for _, lyt in pairs(db.global.layouts) do
		for _, p in pairs(lyt.panels) do
			for _, code in pairs(p.scripts) do
				check(not code:find("kgPanels"), "no kgPanels left in converted scripts")
			end
		end
	end

	-- Export / import of a layout
	local mainIdNow = layoutByName("Main UI")
	local text = ns.Share:Export(mainIdNow)
	check(text and text:sub(1, 6) == "!NXP1!", "export string")
	local decoded = ns.Share:Decode(text)
	check(decoded and decoded.count == 6 and decoded.scripted[1] == "Scripted", "export decoded, scripts listed")
	local newId = ns.Share:Import(decoded, "Copy")
	local copy = ns.Database:GetLayout(newId)
	local chatId, chatPanel = ns.Database:FindPanel(copy, "Chat BG")
	local barId = ns.Database:FindPanel(copy, "Bottom Bar")
	check(copy and copy.name == "Copy" and chatPanel.anchor.relativeTo == "panel:" .. barId, "imported copy keeps its anchors")
	local bad, err = ns.Share:Decode("hello")
	check(not bad and err == L["IMPORT_INVALID"], "invalid string rejected")
	local legacyString = LibStub("AceSerializer-3.0"):Serialize(fixture().global.layouts["Second"])
	local old = ns.Share:Decode(legacyString)
	check(old and old.count == 2 and old.format == L["FORMAT_LEGACY"], "old kgPanels string decoded by the import module")
	local oldId = ns.Share:Import(old, "From old")
	check(ns.Database:GetLayout(oldId) and ns.Database:CountPanels(ns.Database:GetLayout(oldId)) == 2, "old kgPanels string imported")

	-- Display conditions, opacity and fades
	ns.Layouts:Activate(mainId)
	local chatId, barId
	chat, chatId = frameOf(main, "Chat BG")
	barId = select(2, frameOf(main, "Bottom Bar"))
	local chatP = main.panels[chatId]
	local d = chatP.display
	local driver = ns.Visibility.driver
	local function redraw() ns.Layouts:PanelChanged(chatId, "display") end
	d.combat = "IN"
	redraw()
	check(not chat.shown and chat.nxManaged, "hidden out of combat")
	M.Fire("PLAYER_REGEN_DISABLED")
	check(chat.shown and chat.alpha == 1, "shown in combat")
	M.Fire("PLAYER_REGEN_ENABLED")
	check(not chat.shown, "hidden again after combat")
	d.fade = 1
	M.Fire("PLAYER_REGEN_DISABLED")
	check(chat.shown and chat.alpha == 0, "fade starts transparent")
	driver.scripts.OnUpdate(driver, 0.5)
	check(math.abs(chat.alpha - 0.5) < 0.01, "fading in")
	driver.scripts.OnUpdate(driver, 0.6)
	check(chat.alpha == 1, "fade finished")
	M.Fire("PLAYER_REGEN_ENABLED")
	driver.scripts.OnUpdate(driver, 2)
	check(not chat.shown and chat.alpha == 0, "faded out, then hidden")
	d.combat, d.fade = "ANY", 0
	d.alpha, d.hoverAlpha = 0.3, 1
	redraw()
	check(chat.shown and chat.alpha == 0.3, "base opacity")
	M.state.hover[chat] = true
	driver.scripts.OnUpdate(driver, 0.2)
	check(chat.alpha == 1, "mouse-over opacity")
	M.state.hover[chat] = nil
	d.alpha, d.hoverAlpha = 1, 1
	d.macro = "[combat] show; hide"
	redraw()
	check(not chat.shown, "macro condition hides")
	d.macro = ""
	d.group = "RAID"
	redraw()
	check(not chat.shown, "raid only: hidden solo")
	M.state.raid = true
	M.Fire("GROUP_ROSTER_UPDATE")
	check(chat.shown, "shown in a raid")
	M.state.raid = false
	M.Fire("GROUP_ROSTER_UPDATE")
	ns.Visibility:SetForceShow(true)
	check(chat.shown and chat.alpha == 1, "edit mode shows hidden panels")
	ns.Visibility:SetForceShow(false)
	check(not chat.shown, "hidden again after the edit mode")
	d.group = "ANY"
	redraw()
	check(chat.shown and chat.alpha == 1 and not chat.nxManaged, "default settings: panel left to its scripts")

	-- Automatic colors
	chatP.background.style, chatP.background.texture = "SOLID", "Solid"
	chatP.background.colorMode = "CLASS"
	ns.Layouts:PanelChanged(chatId, "look")
	check(chat.bg.vertexColor[1] == 0.25 and chat.bg.vertexColor[4] == math.min(chatP.background.color.a, chatP.background.alpha), "class color, own opacity")
	chatP.background.colorMode = "REACTION"
	ns.Layouts:PanelChanged(chatId, "look")
	check(chat.bg.vertexColor[1] == chatP.background.color.r, "no target: custom color")
	M.state.target = "hostile"
	M.Fire("PLAYER_TARGET_CHANGED")
	check(chat.bg.vertexColor[1] == 0.86, "hostile target: red")
	M.state.target = nil
	chatP.border.texture, chatP.border.colorMode = "Blizzard Tooltip", "FACTION"
	ns.Layouts:PanelChanged(chatId, "look")
	check(chat.border.textures.TOP.vertexColor[1] == 0.18, "faction color on the border")
	chatP.background.colorMode, chatP.border.colorMode = "CUSTOM", "CUSTOM"

	-- Blizzard atlas
	chatP.background.texture = "atlas:test-atlas"
	ns.Layouts:PanelChanged(chatId, "look")
	local tc = chat.bg.texCoord
	check(chat.bg.texture == 12345 and chat.bg.shown and tc[1] == 0.5 and tc[2] == 0 and tc[7] == 1 and tc[8] == 0.25, "atlas drawn from its sheet")
	chatP.background.texture = "atlas:missing"
	ns.Layouts:PanelChanged(chatId, "look")
	check(not chat.bg.shown, "unknown atlas: no background")
	chatP.background.texture = "Solid"

	-- Text variables
	chatP.text.value = "{zone} {fps} {unknown}"
	ns.Layouts:PanelChanged(chatId, "look")
	check(chat.text.textValue == "Valdrakken 60 {unknown}" and chat.textTemplate, "text variables replaced")
	local textTicker = M.ticker
	chatP.text.value = "plain"
	ns.Layouts:PanelChanged(chatId, "look")
	check(chat.text.textValue == "plain" and textTicker.cancelled, "no variables: timer stopped")

	-- A recycled frame does not keep what the scripts stored on it
	local recycled = ns.Panel:Acquire("PX")
	recycled.done = true
	ns.Panel:Release(recycled)
	check(recycled.done == nil and recycled.bg and recycled.sizer and recycled.border, "script values cleared when a frame is recycled")

	-- Script check, panel export, media packs
	local scriptErr = ns.Scripts:Check("LOAD", "local x =")
	check(scriptErr and scriptErr:find("LOAD:1") and not ns.Scripts:Check("EVENT", "print(event, arg1)"), "script syntax check with line number")
	local panelsText = ns.Share:ExportPanels(mainId, { chatId, barId })
	local partial = ns.Share:Decode(panelsText)
	check(partial and partial.kind == "panels" and partial.count == 2, "panels exported")
	local added = partial.addTo(mainId)
	local copyChatId, copyChat = ns.Database:FindPanel(main, "Chat BG (2)")
	local copyBarId = ns.Database:FindPanel(main, "Bottom Bar (2)")
	check(#added == 2 and copyChat and copyChat.anchor.relativeTo == "panel:" .. copyBarId, "panels added to a layout, anchors kept")
	check(nxPanels.RegisterMedia("background", "Pack Stone", "Interface\\AddOns\\Pack\\stone.tga") and ns.Media.LSM:Fetch("background", "Pack Stone"), "media pack API")
	-- LibSerialize patched for WoW Forever (no division by zero): values still round-trip
	local LS = LibStub("LibSerialize")
	local okZero, zeros = LS:Deserialize(LS:Serialize({ 0, -0.0, 1.5, 0 / 0 }))
	check(okZero and zeros[1] == 0 and tostring(zeros[2]) == "-0" and zeros[3] == 1.5 and zeros[4] ~= zeros[4], "zero, negative zero and NaN serialized without dividing by zero")

	-- Layout per specialization
	local function setSpec(n)
		if talentGroups then M.specGroup = n else M.spec = n end
		M.Fire(talentGroups and "ACTIVE_TALENT_GROUP_CHANGED" or "PLAYER_SPECIALIZATION_CHANGED", "player")
	end
	ns.Layouts:Activate(mainId)
	setSpec(2)
	check(ns.Layouts.activeId == secondId, "layout of the specialization shown")
	ns.Layouts:Activate(mainId)
	check(db.profiles.Default.specLayouts[specs[2].key] == mainId and ns.Layouts.activeId == mainId, "activating by hand changes the layout of the spec")
	ns.Database:SetSpecLayoutId(specs[2].key, secondId)
	ns.Database:DeleteLayout(secondId)
	check(db.profiles.Default.specLayouts[specs[2].key] == nil, "deleted layout removed from the specs")
	setSpec(nil)

	if scenario == "tbc" then
		SlashCmdList.NXPANELS("status")
		check(printed(L["CLIENT_ANNIVERSARY"]), "client named in /nxp status")
	end
	if scenario == "zhcn" then
		check(chat.text.font[1] == "Fonts\\ARKai_T.ttf", "Chinese font used by default")
		check(printed("已从 kgPanels_Reloaded 导入 2 个布局和 8 个面板"), "Chinese messages")
	end

elseif scenario == "options" then
	local O = loadOptions()
	local Options, P = ns.Options, O.PanelsPage
	local mainId, main = layoutByName("Main UI")
	local barId = ns.Database:FindPanel(main, "Bottom Bar")
	local chatId = ns.Database:FindPanel(main, "Chat BG")
	local waitingId = ns.Database:FindPanel(main, "Waiting")

	local function findRow(form, label)
		for _, r in ipairs(form.rows) do
			if r.label and r.label.textValue == label then return r end
		end
		error("row not found: " .. tostring(label))
	end
	local function setSlider(r, value)
		r.valueBox.edit:SetText(tostring(value))
		r.valueBox.edit.scripts.OnEnterPressed(r.valueBox.edit)
	end
	local function choose(r, value)
		r.button.scripts.OnClick(r.button)
		return O.Dropdown:Choose(value)
	end
	local function click(b) b.scripts.OnClick(b, "LeftButton") end
	local function typeIn(edit, text)
		edit:SetText(text)
		edit.scripts.OnTextChanged(edit, true)
	end

	-- Window and pages
	local ok, err = pcall(SlashCmdList.NXPANELS, "")
	check(ok and Options.frame and Options.frame.shown, "window opened: " .. tostring(err))
	for _, key in ipairs(Options.order) do
		-- Entries that run an action instead of showing a page (edit mode, what's new)
		if not Options.pages[key].action then
			ok, err = pcall(Options.Show, Options, key)
			check(ok and Options.current == key, "page " .. key .. ": " .. tostring(err))
		end
	end
	-- Settings, About: one row per information, the font without its folder
	Options:Show("settings")
	local about, links = {}, {}
	for _, f in ipairs(M.frames) do
		if f.label and f.value and f.label.textValue then about[f.label.textValue] = f.value.textValue end
		if f.label and f.box and f.label.textValue then links[f.label.textValue] = f.box.edit end
	end
	-- Addresses: copyable, read-only
	local support = links[L["ABOUT_SUPPORT"]]
	check(support and support:GetText():find("curseforge", 1, true) and links[L["ABOUT_DETAILS"]]:GetText():find("issues", 1, true), "help: addresses in copyable fields")
	local address = support:GetText()
	support:SetText("typed")
	support.scripts.OnTextChanged(support, true)
	check(support:GetText() == address, "help: address cannot be changed")
	about[L["ABOUT_SUPPORT"]], about[L["ABOUT_DETAILS"]] = address, links[L["ABOUT_DETAILS"]]:GetText()
	check(about[L["ABOUT_VERSION"]] == ns.version and about[L["ABOUT_CLIENT"]] == L["CLIENT_RETAIL"] .. " 12.1.0.69933"
		and about[L["ABOUT_LANGUAGE"]] == M.locale and about[L["ABOUT_COMMANDS"]] == "/nxp help", "about: version, client, language, commands")
	check(about[L["ABOUT_FONT"]] and not about[L["ABOUT_FONT"]]:find("\\", 1, true) and about[L["ABOUT_SUPPORT"]]:find("curseforge", 1, true) and about[L["ABOUT_DETAILS"]]:find("issues", 1, true), "about: font file name, where to report a problem")

	-- What's new: a page of the window (the pop-up is only for the startup)
	check(Options.order[#Options.order] == "news" and Options.order[#Options.order - 1] == "editmode", "what's new entry after the edit mode")
	Options:Show("news")
	check(Options.current == "news" and not (nxPanelsNews and nxPanelsNews:IsShown()), "what's new is a page, no pop-up")
	local newsPage, notesShown = Options.pages.news.frame, false
	for _, f in ipairs(M.frames) do
		if f.text and f.text.textValue == L["NEWS_1_1_0"] and f.parent == newsPage.scroll.content then notesShown = true end
	end
	check(notesShown, "notes of 1.1.0 on the page")
	local NOTES = ns.News.NOTES
	ns.News.NOTES = { ["1.9.2"] = "x", ["1.10.0"] = "x", ["1.1.0"] = "x", ["2.0"] = "x" }
	check(table.concat(ns.News:Versions(), " ") == "2.0 1.10.0 1.9.2 1.1.0", "versions sorted, the most recent first")
	ns.News.NOTES = NOTES

	check(Options.game.textValue == L["CLIENT_RETAIL"] .. " 12.1.0.69933", "client and build of the game in the sidebar")

	-- Panels page: list by folders
	Options:Show("panels")
	local list = P.page.list.scroll.content
	check(list.h == 7 * 26, "list: folder, its panel and the root panels")
	P.collapsed.Bars = true
	P:RefreshList()
	check(list.h == 6 * 26, "folder collapsed")
	P.collapsed.Bars = nil
	P.page.search.edit:SetText("loop")
	check(list.h == 2 * 26, "search filter")
	P.page.search.edit:SetText("")

	-- Editor: every change is drawn at once
	P:Select(chatId)
	local editor = P.page.editor
	local chat, chatPanel = ns.Layouts.frames[chatId], main.panels[chatId]
	check(editor.shown and editor.name.textValue == "Chat BG", "panel selected in the editor")
	local general = editor.tabs.general.form
	setSlider(findRow(general, L["WIDTH"]), 321)
	check(chatPanel.width == 321 and chat.w == 321, "width applied live")
	setSlider(findRow(general, L["OFFSET_X"]), 2500)
	check(chatPanel.anchor.x == 2500, "offset accepts values outside the slider range")
	check(choose(findRow(general, L["WIDTH_UNIT"]), "%") and chatPanel.widthUnit == "%", "unit dropdown")
	choose(findRow(general, L["WIDTH_UNIT"]), "px")
	choose(findRow(general, L["ANCHORED_TO"]), "__custom")
	M.lastPopup.data.onAccept("MissingFrame")
	check(chatPanel.anchor.relativeTo == "MissingFrame" and ns.Layouts.waiting[chatId] and not chat.shown, "anchored to a frame by name")
	check(findRow(general, L["ANCHORED_TO"]).button.text.textValue == "MissingFrame", "custom frame name shown")
	choose(findRow(general, L["ANCHORED_TO"]), "panel:" .. barId)
	check(chatPanel.anchor.relativeTo == "panel:" .. barId and chat.shown and chat.points[1][2] == ns.Layouts.frames[barId], "anchored back to a panel")

	-- Texture rows open the browser
	local function browse(r, value)
		r.button.scripts.OnClick(r.button)
		local shown = O.Browser.frame.shown
		O.Browser:Choose(value)
		return shown
	end
	check(browse(findRow(editor.tabs.background.form, L["TEXTURE"]), "Solid") and chat.bg.texture == "Interface\\Buttons\\WHITE8X8", "background texture from the browser")
	local bgRow = findRow(editor.tabs.background.form, L["TEXTURE"])
	bgRow.button.scripts.OnClick(bgRow.button)
	O.Browser.frame.tabs:Select("atlas")
	check(O.Browser.frame.count.textValue == L["ATLAS_COUNT"]:format(1), "atlas tab: only the atlases of this client")
	O.Browser:Choose("atlas:test-atlas")
	check(chatPanel.background.texture == "atlas:test-atlas" and chat.bg.texture == 12345, "Blizzard atlas chosen")
	check(bgRow.button.text.textValue == L["ATLAS_ITEM"]:format("test-atlas"), "atlas name shown")
	browse(bgRow, "Solid")
	choose(findRow(editor.tabs.background.form, L["STYLE"]), "GRADIENT")
	check(chat.bg.gradient ~= nil and findRow(editor.tabs.background.form, L["COLOR_END"]).shown, "gradient shows its second color")
	check(browse(findRow(editor.tabs.border.form, L["TEXTURE"]), false) and chatPanel.border.texture == false and not chat.border.textures.TOP.shown, "no border (false)")
	local fontRow = findRow(editor.tabs.text.form, L["FONT"])
	check(choose(fontRow, nil) and chatPanel.text.font == nil and chat.text.font[1] == STANDARD_TEXT_FONT, "language default font")
	typeIn(editor.tabs.text.form.rows[1].area.edit, "Hello ||cffff0000red||r")
	check(chatPanel.text.value == "Hello ||cffff0000red||r" and chat.text.textValue == "Hello |cffff0000red|r", "text typed live")

	-- Scripts: edited as drafts, applied with Save
	local scripts = editor.tabs.scripts.form
	local code = scripts.rows[2].area.edit
	typeIn(code, "self.testLoaded = (self.testLoaded or 0) + 1")
	check(chatPanel.scripts.LOAD == nil and P.drafts[chatId .. "LOAD"], "script draft not saved yet")
	click(scripts.rows[3].buttons[3])
	check(chatPanel.scripts.LOAD and chat.testLoaded == 1 and not P.drafts[chatId .. "LOAD"], "script saved and run")
	editor.bar:Select("scripts")
	typeIn(code, "local x =")
	click(scripts.rows[3].buttons[2])
	check(scripts.rows[4].shown and scripts.rows[4].text.textValue:find("LOAD:1"), "syntax check shows the line")
	click(scripts.rows[3].buttons[1])
	editor.bar:Select("general")

	-- Display tab
	local display = editor.tabs.display.form
	choose(findRow(display, L["COND_COMBAT"]), "IN")
	check(chatPanel.display.combat == "IN" and not chat.shown, "display condition applied at once")
	choose(findRow(display, L["COND_COMBAT"]), "ANY")
	check(chat.shown, "shown again")
	setSlider(findRow(display, L["ALPHA_BASE"]), 0.5)
	check(chatPanel.display.combatAlpha == 0.5 and chatPanel.display.hoverAlpha == 0.5 and chat.alpha == 0.5, "opacity: combat and mouse-over follow")
	setSlider(findRow(display, L["ALPHA_BASE"]), 1)
	check(chat.alpha == 1 and not chat.nxManaged, "back to defaults")

	-- Automatic color, text variables
	choose(findRow(editor.tabs.background.form, L["STYLE"]), "SOLID")
	choose(findRow(editor.tabs.background.form, L["COLOR_MODE"]), "CLASS")
	check(chatPanel.background.colorMode == "CLASS" and chat.bg.vertexColor[1] == 0.25, "class color chosen")
	choose(findRow(editor.tabs.background.form, L["COLOR_MODE"]), "CUSTOM")
	chatPanel.text.value = "Zone:"
	choose(findRow(editor.tabs.text.form, L["INSERT_VARIABLE"]), "zone")
	check(chatPanel.text.value == "Zone: {zone}" and chat.text.textValue == "Zone: Valdrakken", "variable inserted")
	choose(findRow(editor.tabs.text.form, L["INSERT_ICON"]), "Interface\\MoneyFrame\\UI-GoldIcon")
	check(chat.text.textValue == "Zone: Valdrakken |TInterface\\MoneyFrame\\UI-GoldIcon:0|t", "icon inserted as a texture code")
	-- Every icon of the game: only the visible cells are drawn
	chatPanel.text.value = ""
	choose(findRow(editor.tabs.text.form, L["INSERT_ICON"]), "__all")
	local browser = O.Browser.frame
	browser.scroll.w, browser.scroll.h = 720, 440
	O.Browser:FillIcons()
	check(browser.count.textValue == L["ICON_COUNT"]:format(500) and browser.scroll.content.h == math.ceil(500 / 16) * 44, "500 icons in the grid")
	browser.scroll:SetVerticalScroll(44 * 20)
	browser.scroll.scripts.OnMouseWheel(browser.scroll, 0)
	O.Browser:Choose(100000 + 16 * 20 + 1)
	check(chatPanel.text.value == "||T100321:0||t", "icon of the game inserted")
	-- Currencies and items
	chatPanel.text.value = ""
	choose(findRow(editor.tabs.text.form, L["INSERT_CURRENCY"]), 3008)
	chatPanel.text.value = chatPanel.text.value .. " {item:6948}"
	ns.Layouts:PanelChanged(chatId, "look")
	check(chat.text.textValue == "|T5868902:0|t 12345 |T134400:0|t 7", "currency and item amounts with their icons")
	chatPanel.text.value = "Zone: {zone}"
	-- A list row used by the font list goes back to the normal font
	local fontRow = findRow(editor.tabs.text.form, L["FONT"])
	fontRow.button.scripts.OnClick(fontRow.button)
	O.Dropdown:Close()
	local iconRow = findRow(editor.tabs.text.form, L["INSERT_ICON"])
	iconRow.button.scripts.OnClick(iconRow.button)
	local rows = O.Dropdown.popup.buttons
	check(rows[2].text.font[1] == STANDARD_TEXT_FONT and rows[2].text.font[2] == 13 and rows[2].h == 28, "list rows: normal font, square icons")
	O.Dropdown:Close()

	-- Export of one panel, pasted back: added to the active layout
	P:Export({ chatId }, "Chat BG")
	local one = O.SharePage.exportText
	check(O.SharePage.page.exportInfo.textValue:find("Chat BG"), "panel export")
	O.SharePage:ShowImport()
	O.SharePage.page.importArea.edit:SetText(one)
	check(O.SharePage.decoded.kind == "panels" and not O.SharePage.page.nameBox.shown, "pasted panels: no layout name asked")
	O.SharePage:Import(false)
	local pastedId = ns.Database:FindPanel(main, "Chat BG (2)")
	check(pastedId and ns.Layouts.frames[pastedId] and ns.Database:GetLayout(ns.Layouts.activeId) == main, "panel added to the active layout")
	ns.Database:DeletePanel(mainId, pastedId)
	ns.Layouts:PanelChanged(pastedId, "removed")

	-- Gallery
	local before = count(main.panels)
	P.page.newPanel.scripts.OnClick(P.page.newPanel)
	check(O.Dropdown:Choose(1), "template chosen from the New panel menu")
	local barTplId, barTpl = ns.Database:FindPanel(main, L["TPL_INFO_BAR"])
	local lineId, line = ns.Database:FindPanel(main, L["TPL_INFO_BAR_LINE"])
	check(count(main.panels) == before + 2 and line and line.parent == "panel:" .. barTplId and line.background.colorMode == "CLASS", "template added, its panels linked")
	check(ns.Layouts.frames[barTplId].text.textValue:find("Valdrakken"), "template text variables")
	local glowLayout = O.AddTemplate(O.Templates[4], true)
	local glowId = next(ns.Database:GetLayout(glowLayout).panels)
	check(ns.Layouts.activeId == glowLayout and not ns.Layouts.frames[glowId].shown, "combat glow template hidden out of combat")
	ns.Layouts:Activate(mainId)
	for _, id in ipairs({ barTplId, lineId }) do
		ns.Database:DeletePanel(mainId, id)
		ns.Layouts:PanelChanged(id, "removed")
	end

	-- Panels and folders (frames were recycled by the layout switches above)
	chat = ns.Layouts.frames[chatId]
	local loadedBefore = chat.testLoaded
	P:NewPanel(nil)
	M.lastPopup.data.onAccept("Test panel")
	local testId, test = ns.Database:FindPanel(main, "Test panel")
	check(test and ns.Layouts.frames[testId] and ns.Layouts.frames[testId].shown and P.selected == testId, "panel created, drawn and selected")
	check(loadedBefore and chat.testLoaded == loadedBefore, "other panels keep running when a panel is added")
	P:Duplicate(testId)
	local dupId = ns.Database:FindPanel(main, "Test panel (2)")
	check(dupId and ns.Layouts.frames[dupId] and P.selected == dupId, "panel duplicated")
	check(deepEqual(main.panels[dupId].anchor, test.anchor) and main.panels[dupId].anchor ~= test.anchor, "duplicate keeps the exact position (own copy)")
	-- Names shown in the panel list (the page must be shown to refresh)
	Options:Show("panels")
	local function listed(name)
		for _, f in ipairs(M.frames) do
			if f.parent == list and f.shown and f.entry and f.entry.kind == "panel" and f.label.textValue == name then return true end
		end
		return false
	end
	check(listed("Test panel (2)"), "duplicate listed")
	P:Delete(dupId)
	M.lastPopup.data()
	check(not main.panels[dupId] and not ns.Layouts.frames[dupId] and P.selected == nil, "panel deleted, frame released")
	check(not listed("Test panel (2)"), "deleted panel left the list at once")
	P:Rename(testId)
	M.lastPopup.data.onAccept("Renamed panel")
	check(listed("Renamed panel") and not listed("Test panel"), "renamed panel listed once, with its new name")
	P:Rename(testId)
	M.lastPopup.data.onAccept("Test panel")
	check(listed("Test panel") and not listed("Renamed panel"), "name restored")
	P:NewFolder()
	M.lastPopup.data.onAccept("Art")
	P:MoveToFolder(testId, editor)
	check(O.Dropdown:Choose("Art") and test.folder == "Art", "panel moved to a folder")
	P:RenameFolder("Art")
	M.lastPopup.data.onAccept("Deco")
	check(test.folder == "Deco" and main.folders[2] == "Deco", "folder renamed")
	P:DeleteFolder("Deco")
	M.lastPopup.data()
	check(test.folder == nil and #main.folders == 1, "folder deleted, panel kept")

	-- Library
	Options:Show("library")
	local lib = O.LibraryPage.page
	lib.nameBox.edit:SetText("Solid")
	lib.pathBox.edit:SetText("x")
	O.LibraryPage:Add()
	check(db.global.media.background.Solid == nil and lib.message.textValue == L["MEDIA_NAME_TAKEN"]:format("Solid"), "name used by another addon refused")
	lib.nameBox.edit:SetText("My Test")
	lib.pathBox.edit:SetText(" Interface/AddOns/Test//art.tga ")
	O.LibraryPage:Add()
	check(db.global.media.background["My Test"] == "Interface\\AddOns\\Test\\art.tga" and ns.Media.LSM:Fetch("background", "My Test", true), "media added with a clean path")
	ns.Media:RemoveFromLibrary("background", "My Test")
	check(db.global.media.background["My Test"] == nil, "media removed from the library")

	-- Paths as players type them (comment on CurseForge: added textures found nowhere)
	local norm = O.LibraryPage.NormalizePath
	check(norm([[C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\Art\bg.tga]]) == "Interface\\AddOns\\Art\\bg.tga", "full Windows path reduced to the game path")
	check(norm("AddOns/Art/bg.tga") == "Interface\\AddOns\\Art\\bg.tga" and norm("interface\\addons\\x.tga") == "interface\\addons\\x.tga", "AddOns path completed, case kept")
	lib.nameBox.edit:SetText("Outside")
	lib.pathBox.edit:SetText("D:/Images/bg.tga")
	O.LibraryPage:Add()
	check(db.global.media.background.Outside == nil and lib.message.textValue == L["MEDIA_BAD_PATH"], "path outside the Interface folder refused")
	-- A file the game does not know: LibSharedMedia ignores it, the library keeps it
	M.unknownFiles = { ["Interface\\AddOns\\Art\\new.tga"] = true }
	lib.nameBox.edit:SetText("New Art")
	lib.pathBox.edit:SetText("Interface\\AddOns\\Art\\new.tga")
	O.LibraryPage:Add()
	check(lib.message.textValue == L["MEDIA_ADDED_NOT_FOUND"]:format("New Art"), "warning when the game does not find the file")
	check(not ns.Media.LSM:Fetch("background", "New Art", true) and ns.Media:Fetch("background", "New Art") == "Interface\\AddOns\\Art\\new.tga", "drawn from the library even when LibSharedMedia ignored it")
	-- Several files at once, pasted from the file explorer ("Copy as path")
	local LP = O.LibraryPage
	LP.kind = "background"
	LP:OpenMany()
	local many = LP.manyWindow
	check(many.shown and many.title.textValue == L["MANY_TITLE_BACKGROUND"] and many.kindText.textValue == L["MANY_KIND_BACKGROUND"], "add-many window says it adds backgrounds")
	M.unknownFiles = { ["Interface\\AddOns\\Art\\Fonds\\fresh.tga"] = true }
	many.area:SetText(table.concat({
		[["C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\Art\Fonds\stone.tga"]],
		[["C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\Art\Fonds\wood.blp"]],
		[[/Applications/World of Warcraft/_retail_/Interface/AddOns/Art/Fonds/Solid.tga]],
		[["D:\Images\photo.tga"]],
		[["C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\Art\Fonds\stone.tga"]],
		[[Interface\AddOns\Art\Fonds\fresh.tga]],
		"",
	}, "\r\n"))
	-- Recent LibSharedMedia versions raise a Lua error for an unknown file: never sent there
	local LSM = ns.Media.LSM
	local register, sentUnknown = LSM.Register, false
	LSM.Register = function(lib, kind, name, path, ...)
		if M.unknownFiles and M.unknownFiles[path] then sentUnknown = true end
		return register(lib, kind, name, path, ...)
	end
	many.addAll.scripts.OnClick(many.addAll)
	check(not sentUnknown, "unknown file not sent to LibSharedMedia")
	check(ns.API.RegisterMedia("background", "Pack: fresh", "Interface\\AddOns\\Art\\Fonds\\fresh.tga") == false and not sentUnknown, "API: unknown file refused without error")
	LSM.Register = register
	local bg = db.global.media.background
	check(bg.stone == "Interface\\AddOns\\Art\\Fonds\\stone.tga" and bg.wood == "Interface\\AddOns\\Art\\Fonds\\wood.blp", "names from the file names, Windows paths reduced")
	check(bg["Solid (2)"] == "Interface\\AddOns\\Art\\Fonds\\Solid.tga", "Mac path, name used by another addon gets a number")
	check(not bg.photo and bg.fresh, "path outside the game refused, unknown file kept")
	local text = many.result.textValue
	check(text:find(L["MANY_ADDED"]:format(4), 1, true) and text:find(L["MANY_OUTSIDE"]:format(1, "photo.tga"), 1, true)
		and text:find(L["MANY_EXISTING"]:format(1), 1, true) and text:find(L["MANY_NOT_FOUND"]:format(1, "fresh"), 1, true), "summary of the add")
	check(many.area:GetText() ~= "", "pasted text kept when something went wrong")
	many.area:SetText([[Interface\AddOns\Art\Fonds\stone.tga]])
	many.addAll.scripts.OnClick(many.addAll)
	check(many.result.textValue == L["MANY_ADDED"]:format(0) .. "\n" .. L["MANY_EXISTING"]:format(1), "pasting the same files again adds nothing")
	many.area:SetText("")
	many.addAll.scripts.OnClick(many.addAll)
	check(many.result.textValue == L["MANY_EMPTY"], "nothing pasted")
	for _, name in ipairs({ "stone", "wood", "Solid (2)", "fresh" }) do ns.Media:RemoveFromLibrary("background", name) end
	M.unknownFiles = nil
	LP.kind = "border"
	LP:OpenMany()
	check(many.title.textValue == L["MANY_TITLE_BORDER"] and many.kindText.textValue == L["MANY_KIND_BORDER"] and many.result.textValue == "", "add-many window for borders")
	many:Hide()
	LP.kind = "background"

	-- Texture browser: the library in its own tab, the shared media in another
	local function values(list)
		local set = {}
		for _, item in ipairs(list) do set[tostring(item.value)] = true end
		return set
	end
	local own, shared, all = values(Options:MediaItems("background", "library")), values(Options:MediaItems("background", "shared")), values(Options:MediaItems("background"))
	check(own["New Art"] and not own.Solid and not own["false"], "library tab: only the user files")
	check(shared.Solid and shared["false"] and not shared["New Art"], "shared tab: game and addons media, and None")
	check(all["New Art"] and all.Solid, "dropdown: everything")
	O.Browser:Open("background", "New Art", function() end)
	check(O.Browser.tab == "library" and O.Browser.frame.tabs.buttons[3].shown, "browser opens on the library tab of the current texture")
	O.Browser:Open("border", "Blizzard Tooltip", function() end)
	check(O.Browser.tab == "media" and not O.Browser.frame.tabs.buttons[3].shown, "borders: no atlas tab, shared tab")
	local borders = db.global.media.border
	db.global.media.border = {}
	O.Browser.frame.tabs:Select("library")
	check(O.Browser.frame.empty.shown and O.Browser.frame.empty.textValue == L["BROWSER_LIBRARY_EMPTY"], "empty library tab explained")
	db.global.media.border = borders
	O.Browser:Close()
	ns.Media:RemoveFromLibrary("background", "New Art")
	M.unknownFiles = nil

	-- Import / export
	O.SharePage:ShowExport(mainId)
	local exported = O.SharePage.exportText
	check(exported and exported:sub(1, 6) == "!NXP1!" and O.SharePage.page.export.shown, "export tab")
	O.SharePage:ShowImport()
	local share = O.SharePage.page
	share.importArea.edit:SetText(exported)
	check(O.SharePage.decoded and O.SharePage.decoded.count == 7 and share.nameBox.edit.textValue == "Main UI", "pasted string decoded")
	check(share.noScripts.shown, "import without scripts offered")
	O.SharePage:Import(true)
	check(M.lastPopup.name == "NXPANELS_CONFIRM", "scripts need a confirmation")
	share.nameBox.edit:SetText("Imported copy")
	O.SharePage:Import(false)
	local copyId, copy = layoutByName("Imported copy")
	local scriptsLeft = 0
	for _, p in pairs(copy and copy.panels or {}) do scriptsLeft = scriptsLeft + count(p.scripts) end
	check(copy and ns.Layouts.activeId == copyId and scriptsLeft == 0, "imported without scripts and activated")

	-- Profiles
	Options:Show("profiles")
	local profiles = Options.pages.profiles.frame.form
	click(profiles.rows[2].buttons[1])
	M.lastPopup.data.onAccept("Test")
	check(ns.db:GetCurrentProfile() == "Test" and not ns.Layouts.activeId, "new empty profile")
	choose(findRow(profiles, L["DEFAULT_LAYOUT"]), mainId)
	check(ns.db.profile.layout == mainId and ns.Layouts.activeId == mainId, "layout chosen for the profile")
	choose(findRow(profiles, L["PROFILE"]), "Default")
	check(ns.db:GetCurrentProfile() == "Default", "profile switched")
	choose(findRow(profiles, L["DELETE_PROFILE"]), "Test")
	M.lastPopup.data()
	check(not ns.db.profiles.Test, "profile deleted")
	-- Layout per specialization, from the Profiles page
	M.spec = 2
	check(choose(findRow(profiles, "Spec2"), copyId) and ns.Layouts.activeId == copyId, "layout chosen for the current spec is shown")
	check(findRow(profiles, "Spec2").label.textColor[1] == O.Theme.colors.accent[1], "current spec highlighted")
	choose(findRow(profiles, "Spec2"), false)
	check(ns.db.profile.specLayouts.S63 == nil and ns.Layouts.activeId == ns.db.profile.layout, "spec back to the default layout")
	M.spec = nil
	-- Shared profile per class / faction
	local shared = profiles.rows[4]
	check(shared.buttons[1].label.textValue == L["PROFILE_OF_CLASS"]:format("Mage"), "class profile button")
	click(shared.buttons[2])
	check(ns.db:GetCurrentProfile() == "Alliance", "faction profile used")
	choose(findRow(profiles, L["PROFILE"]), "Default")
	choose(findRow(profiles, L["NEW_CHARACTERS"]), "class")
	check(ns.db.global.newCharacters == "class", "profile of new characters")

	-- Settings
	Options:Show("settings")
	local settings = Options.pages.settings.frame.form
	local minimap = findRow(settings, L["MINIMAP_BUTTON"])
	minimap.switch.scripts.OnClick(minimap.switch)
	check(ns.db.profile.minimap.hide == true, "minimap button hidden")
	setSlider(findRow(settings, L["GRID_SIZE"]), 16)
	choose(findRow(settings, L["THEME_STYLE"]), "night")
	check(ns.db.global.optionsTheme.style == "night" and M.lastPopup.name == "NXPANELS_CONFIRM", "style changed, reload asked")
	M.lastPopup.data()
	check(M.reloaded, "interface reloaded")
	check(findRow(settings, L["THEME_ACCENT"]).button.text.textValue == L["ACCENT_GOLD"], "accent shown")

	-- Edit mode
	ns.Layouts:Activate(mainId)
	local EM = O.EditMode
	Options:Show("panels")
	EM:Start()
	check(EM.active and not Options.frame.shown, "edit mode started, window hidden")
	check(EM.movers[testId] and EM.movers[chatId] and not EM.movers[waitingId], "movers for the shown panels only")
	local s = ns.db.global.editMode
	local testFrame = ns.Layouts.frames[testId]
	local m = EM.movers[testId]
	local function dragMover(target, fromX, toX, handle)
		testFrame.rect = { 860, 490, 200, 100 }
		M.cursor = { fromX, 500 }
		target.scripts.OnMouseDown(target, "LeftButton")
		M.cursor = { toX, 500 }
		EM.frame.scripts.OnUpdate(EM.frame, 0.01)
		local guide = EM.frame.vGuide.shown
		target.scripts.OnMouseUp(target, "LeftButton")
		return guide
	end
	s.snapPanels, s.snapGrid = false, true
	dragMover(m, 1000, 1005)
	check(test.anchor.x == 4 and test.anchor.y == 2 and EM.selected == testId, "moved and snapped to the grid")
	test.anchor.x, test.anchor.y = 0, 0
	dragMover(m, 1000, 1010)
	check(test.anchor.x == 10 and test.anchor.y == 2, "far from a grid line: free move (smooth), not steps")
	EM:Undo()
	M.ctrl = true
	EM.frame.scripts.OnKeyDown(EM.frame, "Z")
	M.ctrl = false
	check(test.anchor.x == 0 and test.anchor.y == 0, "Ctrl+Z undoes the move")
	EM.frame.scripts.OnKeyDown(EM.frame, "RIGHT")
	M.shift = true
	EM.frame.scripts.OnKeyDown(EM.frame, "UP")
	M.shift = false
	check(test.anchor.x == 1 and test.anchor.y == 10, "arrow keys, Shift for a bigger step")
	test.anchor.x, test.anchor.y = 0, 0
	s.snapPanels, s.snapGrid = true, false
	local guide = dragMover(m, 1000, 1005)
	check(test.anchor.x == 0 and guide, "snapped to the screen center, guide shown")
	M.shift = true
	dragMover(m, 1000, 1005)
	M.shift = false
	check(test.anchor.x == 5, "Shift: no snapping")
	test.anchor.x = 0
	s.snapPanels = false
	dragMover(m.handles[6], 1060, 1090)
	check(test.width == 230 and test.anchor.x == 15, "resized by the right edge, centered panel follows")
	ns.Layouts:ApplyActive()
	check(EM.movers[testId] and EM.movers[testId].target == ns.Layouts.frames[testId], "movers rebuilt with the layout")
	-- Several panels: Ctrl+click, alignment, moved together
	testFrame = ns.Layouts.frames[testId]
	local chatFrame = ns.Layouts.frames[chatId]
	test.anchor.x, test.anchor.y = 0, 0
	testFrame.rect = { 860, 490, 200, 100 }
	chatFrame.rect = { 100, 60, 321, 150 }
	EM:Select(testId)
	M.ctrl = true
	EM.movers[chatId].scripts.OnMouseDown(EM.movers[chatId], "LeftButton")
	M.ctrl = false
	check(EM.selection[testId] and EM.selection[chatId] and EM.selected == chatId and EM.frame.bar.align.shown, "Ctrl+click adds to the selection")
	EM:Align("LEFT")
	check(test.anchor.x == -760, "aligned on the main panel")
	EM:Undo()
	check(test.anchor.x == 0, "alignment undone")
	local chatX = chatPanel.anchor.x
	M.cursor = { 900, 520 }
	EM.movers[testId].scripts.OnMouseDown(EM.movers[testId], "LeftButton")
	M.cursor = { 930, 520 }
	M.shift = true
	EM.frame.scripts.OnUpdate(EM.frame, 0.01)
	M.shift = false
	EM.movers[testId].scripts.OnMouseUp(EM.movers[testId], "LeftButton")
	check(test.anchor.x == 30 and chatPanel.anchor.x == chatX + 30, "the selection moves together")
	EM:Undo()
	check(test.anchor.x == 0 and chatPanel.anchor.x == chatX, "group move undone")
	EM:Select(testId)
	EM.frame.scripts.OnKeyDown(EM.frame, "ESCAPE")
	check(EM.active and EM.selected == nil, "Escape deselects")
	EM.frame.scripts.OnKeyDown(EM.frame, "ESCAPE")
	check(not EM.active and Options.frame.shown, "Escape leaves, the window comes back")
	EM:Start()
	M.Fire("PLAYER_REGEN_DISABLED")
	check(not EM.active, "edit mode left when a fight starts")
	M.combat = true
	EM:Start()
	check(not EM.active, "no edit mode in combat")
	M.combat = false
	EM:Start(testId)
	local mover = EM.movers[testId]
	mover.scripts.OnClick(mover, "RightButton")
	check(not EM.active and Options.current == "panels" and P.selected == testId, "right-click opens the panel settings")

	-- Every language has the same texts
	local LOCALES = { "enUS", "frFR", "zhCN", "zhTW", "deDE", "esES", "itIT", "koKR", "ptBR", "ruRU" }
	local keys = {}
	for _, locale in ipairs(LOCALES) do
		local set, n = {}, 0
		for line in io.lines("nxPanels/Locales/" .. locale .. ".lua") do
			local key = line:match('^L%["([%w_]+)"%]')
			if key then set[key] = true n = n + 1 end
		end
		keys[locale] = set
		check(n == count(keys.enUS), "same number of texts in " .. locale)
	end
	for key in pairs(keys.enUS) do
		for _, locale in ipairs(LOCALES) do
			check(keys[locale][key], "text " .. key .. " translated in " .. locale)
		end
	end
	-- The same %s / %d as the English text, in the same order (unless numbered: %2$s)
	local function specifiers(locale)
		local list = {}
		for line in io.lines("nxPanels/Locales/" .. locale .. ".lua") do
			local key, value = line:match('^L%["([%w_]+)"%]%s*=%s*"(.*)"%s*$')
			if key and key ~= "TIME_FORMAT" and key ~= "DATE_FORMAT" then
				local found, numbered = {}, false
				for pos, kind in value:gsub("%%%%", ""):gmatch("%%(%d*%$?)([sd])") do
					if pos ~= "" then numbered = true end
					found[#found + 1] = kind
				end
				if numbered then table.sort(found) end
				list[key] = { kinds = table.concat(found), numbered = numbered }
			end
		end
		return list
	end
	local english = specifiers("enUS")
	for _, locale in ipairs(LOCALES) do
		for key, spec in pairs(specifiers(locale)) do
			local expected = english[key] and english[key].kinds or ""
			if spec.numbered then
				local sorted = {}
				for c in expected:gmatch(".") do sorted[#sorted + 1] = c end
				table.sort(sorted)
				expected = table.concat(sorted)
			end
			check(spec.kinds == expected, ("%s %s: %%%s expected, %%%s found"):format(locale, key, expected, spec.kinds))
		end
	end
	-- Texts of the import module: one block per language, the same keys in each
	local blocks, current = {}, nil
	for line in io.lines("nxPanels_Import/Locales.lua") do
		local locale = line:match('NewLocale%("nxPanels", "(%a+)"')
		if locale then current = {} blocks[locale] = current end
		local key = current and line:match('^%s*L%["([%w_]+)"%]')
		if key then current[key] = true end
	end
	for _, locale in ipairs(LOCALES) do
		local block = blocks[locale]
		check(block and count(block) == count(blocks.enUS), "import texts in " .. locale)
		for key in pairs(blocks.enUS) do
			check(block and block[key], "import text " .. key .. " translated in " .. locale)
		end
	end

elseif scenario == "original" then
	check(#M.loadCalls == 0, "bridge not loaded when the original kgPanels is present")
	check(db.global.migration.source == "kgPanels", "imported from the original kgPanels")
	check(count(db.global.layouts) == 2, "layouts imported")
	check(M.disabled.kgPanels, "original addon disabled")
	check(M.popups[1] == "NXPANELS_MIGRATED" and not nxPanelsWelcome, "reload popup shown, welcome waits")
	I.Import:Finish()
	check(nxPanelsWelcome and nxPanelsWelcome:IsShown() and nxPanelsWelcome.title:GetText() == L["WELCOME_TITLE"]:format("kgPanels"), "welcome after the reload, original name")

elseif scenario == "handinstall" then
	check(#M.loadCalls == 0, "running legacy addon read without loading anything")
	check(db.global.migration.source == "kgPanels_Reloaded", "imported from the running kgPanels Reloaded")
	check(count(db.global.layouts) == 2, "layouts imported")
	check(deepEqual(kgPanelsDB, fixture()), "legacy data left untouched")
	check(M.disabled.kgPanels_Reloaded and M.disabled.kgPanelsConfig_Reloaded, "legacy addons disabled")
	check(M.popups[1] == "NXPANELS_MIGRATED" and not nxPanelsWelcome, "reload popup shown, welcome waits")
	I.Import:Finish()
	check(nxPanelsWelcome and nxPanelsWelcome:IsShown(), "welcome after the reload")

elseif scenario == "notloaded" then
	local hint = L["LEGACY_NOT_LOADED"]:format("Out of date"):gsub("%p", "%%%0")
	check(count(db.global.layouts) == 0 and not db.global.migration, "nothing imported")
	check(printed(hint), "kgPanels not loaded by the game: explained after login")
	M.printed = {}
	SlashCmdList.NXPANELS("import")
	check(printed(hint), "explained again by /nxp import")
	-- The player copies kgPanels.lua as kgPanels_Reloaded.lua: the bridge reads it
	M.addons[2].loaded = false
	M.addons[2].onLoad = function() kgPanelsDB = fixture() end
	SlashCmdList.NXPANELS("import")
	check(count(db.global.layouts) == 2 and deepEqual(kgPanelsDB, fixture()), "imported through the bridge, data untouched")

elseif scenario == "nolibs" then
	check(not ns.libsOK and not ns.db and not db, "missing library detected, no database")
	check(loginOK, "login without error: " .. tostring(loginError))
	check(not nxPanelsWelcome and #M.loadCalls == 0, "no import, no welcome")

elseif scenario == "empty" then
	check(count(db.global.layouts) == 0 and not db.global.migration, "nothing imported")
	check(#M.popups == 0 and not nxPanelsWelcome, "no welcome without import")
	local ok = pcall(SlashCmdList.NXPANELS, "status")
	check(ok and printed((": " .. L["LAYOUT_NONE_ITEM"] .. ". "):gsub("%p", "%%%0")) and not printed("%.%."), "status without layout, a single period")
	SlashCmdList.NXPANELS("import")
	check(printed(L["MIGRATE_NOTHING"]), "import without legacy data")

elseif scenario == "real" then
	local panels = 0
	for _, layout in pairs(db.global.layouts) do panels = panels + count(layout.panels) end
	print(("  imported %d layouts, %d panels"):format(count(db.global.layouts), panels))
	for _, entry in ipairs(ns.Database:SortedLayouts()) do
		print(("   - %s: %d panels, folders: %s"):format(entry.layout.name, count(entry.layout.panels), table.concat(entry.layout.folders, ", ")))
	end
	for name, profile in pairs(db.profiles) do
		local layout = ns.Database:GetLayout(profile.layout)
		print(("   profile %s -> %s"):format(name, layout and layout.name or "-"))
	end
	local shown, waiting = ns.Layouts:CountShown()
	print(("  active layout: %s, %d shown, %d waiting"):format(tostring(ns.API.GetActiveLayout()), shown, waiting))
	check(panels > 0 and shown > 0, "real data rendered")
	check(deepEqual(kgPanelsDB, realData()), "legacy data left untouched")

	-- The editor opens every real panel on every tab, the edit mode every layout
	local O = loadOptions()
	local P = O.PanelsPage
	local activeBefore = ns.Layouts.activeId
	ns.Options:Show("panels")
	local opened, failed = 0, 0
	for _, entry in ipairs(ns.Database:SortedLayouts()) do
		ns.Layouts:Activate(entry.id)
		for panelId in pairs(entry.layout.panels) do
			for _, tab in ipairs({ "general", "background", "border", "text", "display", "scripts" }) do
				P.tab = tab
				local ok, err = pcall(P.Select, P, panelId)
				opened = opened + 1
				if not ok then
					failed = failed + 1
					if failed <= 5 then print("  editor error: " .. tostring(err)) end
				end
			end
		end
		local ok, err = pcall(O.EditMode.Start, O.EditMode)
		check(ok and O.EditMode.active, "edit mode on " .. entry.layout.name .. ": " .. tostring(err))
		O.EditMode:Stop()
	end
	print(("  editor opened %d times"):format(opened))
	check(failed == 0, "editor works on every real panel")
	ns.Layouts:Activate(activeBefore)
end

for _, line in ipairs(M.printed) do
	if line:find("rror") then print("  chat: " .. line) end
end
print(("  %d checks, %d failed"):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
